import CoreBluetooth
import Foundation
import SensoriaiOS

/// Owns one foot slot. The raw Control Point preflight runs before the SDK
/// reads configuration, so malformed channel settings never reach its parser.
final class SensoriaHandler: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, SADeviceBluetoothDelegate {
    private struct Candidate {
        let id: UUID
        let name: String
        let rssi: Int
        let seen: TimeInterval
    }

    private enum Phase {
        case idle, scanning, checking, calibrating, handoff, starting, ready, streaming
    }

    private static let service = CBUUID(string: "1CAC0001-656E-696C-4B5F-5F6E6167654E")
    private static let rx = CBUUID(string: "1CAC0002-656E-696C-4B5F-5F6E6167654E")
    private static let tx = CBUUID(string: "1CAC0003-656E-696C-4B5F-5F6E6167654E")
    private static var candidates: [UUID: Candidate] = [:]
    private static var reserved = Set<UUID>()

    private let index: Int
    private let buffer: CentralBufferManager
    private lazy var central = CBCentralManager(delegate: self, queue: .main)
    private var phase = Phase.idle
    private var timer: DispatchWorkItem?
    private var target: Candidate?
    private var peripheral: CBPeripheral?
    private var transmitter: CBCharacteristic?
    private var core: SACore?
    private var targets: [Int] = []
    private var ranges: [Int] = []
    private var targetRates: [Int] = []
    private var actualRates: [Int: Int] = [:]
    private var targetPeriod = 0
    private var trialCounterBits = 24
    private var packetPeriodMs = 32
    private var magneticOffsets: [Int]?
    private var commands: [[UInt8]] = []
    private var pending: [UInt8]?
    private var retriedRead = false
    private var retriedVerification = false
    private var verifyingWrites = false
    private var triedCachedDevice = false
    private var lastBatteryLevel: UInt8 = 0
    private var calibrationCompletion: ((String) -> Void)?
    private var calibrationReadingOffsets = false
    private var calibrationOutcome = "unavailable"
    private var lastRecordingSample: TimeInterval = -.infinity
    private var streamRequested = false
    private var captureStartedAt: TimeInterval = .infinity
    private var lastCaptureSample: TimeInterval = -.infinity
    private var collectingTrial = false
    private var trialSamples: [[Any]] = []

    init(index: Int, buffer: CentralBufferManager) {
        self.index = index
        self.buffer = buffer
        super.init()
    }

    func start(ranges: [Int], rates: [Int], period: Int) {
        guard phase == .idle else { return }
        targets = ranges
        targetRates = rates
        targetPeriod = period
        verifyingWrites = false
        retriedVerification = false
        triedCachedDevice = false
        phase = .scanning
        if central.state == .poweredOn {
            beginScan(allowCache: true)
        } else {
            arm(6) { $0.finish("notFound") }
        }
    }

    var isReady: Bool { phase == .ready || phase == .streaming }
    var isStreaming: Bool { phase == .streaming && streamRequested }
    var isCollectingTrial: Bool { collectingTrial }
    var isCalibrating: Bool { calibrationCompletion != nil }

    func getBatteryLevel() -> UInt8 { lastBatteryLevel }
    func disconnect() { finish(nil) }

    var hasRecordingData: Bool {
        buffer.isRecording && isStreaming &&
            lastRecordingSample >= buffer.recordingStartedAt &&
            ProcessInfo.processInfo.systemUptime - lastRecordingSample < 2
    }

    func calibrateMagnetometer(completion: @escaping (String) -> Void) {
        guard isReady, !buffer.isRecording, !collectingTrial, calibrationCompletion == nil,
              peripheral != nil else { completion("unavailable"); return }
        calibrationCompletion = completion
        calibrationReadingOffsets = false
        calibrationOutcome = "unavailable"
        phase = .calibrating
        guard let core = core else { finish("stream"); return }
        core.disconnect()
        arm(10) { $0.finish("stream") }
    }

    private var canUseControlPoint: Bool {
        phase == .checking || phase == .calibrating
    }

    private func completeCalibration(_ outcome: String) {
        let completion = calibrationCompletion
        calibrationCompletion = nil
        completion?(outcome)
    }

    private func restoreAfterCalibration(_ outcome: String) {
        guard phase == .calibrating, let peripheral = peripheral else { return }
        calibrationOutcome = outcome
        phase = .handoff
        central.cancelPeripheralConnection(peripheral)
        arm(8) { $0.finish("stream") }
    }

    private func handleCalibrationReply(_ bytes: [UInt8]) {
        guard bytes.count >= 3, bytes[0] == 3, bytes[1] == 3 else { return }
        if calibrationReadingOffsets {
            if let offsets = Self.decodeOffsets(bytes) {
                magneticOffsets = offsets
                guard let range = ranges.last else {
                    restoreAfterCalibration("unavailable")
                    return
                }
                restoreAfterCalibration(offsets.contains { abs($0) >= range * 1000 } ? "offsetsOutOfRange" : "success")
            } else if [0x09, 0x15].contains(bytes[2]) {
                restoreAfterCalibration("unavailable")
            }
        } else if bytes.starts(with: [3, 3, 0x0e, 0x08, 0x64]) {
            calibrationReadingOffsets = true
            send([3, 3, 6])
        } else if bytes.starts(with: [3, 3, 0x0e, 0x09, 0xfd]) {
            restoreAfterCalibration("retry")
        } else if [0x09, 0x15].contains(bytes[2]) {
            restoreAfterCalibration("commandFailed")
        }
    }

    private static func decodeOffsets(_ bytes: [UInt8]) -> [Int]? {
        guard bytes.count >= 9, [6, 8].contains(bytes[2]) else { return nil }
        return [3, 5, 7].map {
            Int(Int16(bitPattern: UInt16(bytes[$0]) << 8 | UInt16(bytes[$0 + 1])))
        }
    }

    func setTrialCapture(_ enabled: Bool) {
        collectingTrial = enabled
        trialSamples.removeAll()
        updateCapture()
    }

    func updateCapture() {
        guard isReady else { return }
        let enabled = collectingTrial || buffer.isRecording
        guard streamRequested != enabled else { return }
        streamRequested = enabled
        if enabled {
            captureStartedAt = ProcessInfo.processInfo.systemUptime
            NSLog("Sensoria slot %d starting measurements", index)
            core?.resumeStreaming()
            arm(15) {
                if $0.streamRequested && $0.lastCaptureSample < $0.captureStartedAt {
                    $0.finish("stream")
                }
            }
        } else {
            timer?.cancel()
            NSLog("Sensoria slot %d paused; waiting", index)
            core?.pauseStreaming()
        }
    }

    func drainTrialSamples() -> [[Any]] {
        let samples = trialSamples
        trialSamples.removeAll(keepingCapacity: true)
        return samples
    }

    private func arm(_ seconds: TimeInterval, _ action: @escaping (SensoriaHandler) -> Void) {
        timer?.cancel()
        let timer = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            action(self)
        }
        self.timer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: timer)
    }

    private func report(_ status: String, error: String? = nil) {
        var event: [String: Any] = ["coreIndex": index, "status": status]
        if let error = error { event["error"] = error }
        if status == "connected" {
            event["magnetometerGauss"] = ranges.last
            if ranges.count == 3 {
                var settings = ["accelerometerG": ranges[0], "gyroscopeDps": ranges[1],
                                "magnetometerGauss": ranges[2], "streamPeriodMs": packetPeriodMs]
                for (index, key) in ["accelerometerHz", "gyroscopeHz", "magnetometerHz"].enumerated() {
                    settings[key] = actualRates[index]
                }
                event["settings"] = settings
            }
            if let offsets = magneticOffsets { event["magneticOffsets"] = offsets }
        }
        EventManager.shared.dispatchEvent(event)
    }

    private func available(since: TimeInterval) -> Candidate? {
        Self.candidates.values
            .filter { $0.seen >= since && !Self.reserved.contains($0.id) }
            .max { $0.rssi < $1.rssi }
    }

    private func beginScan(allowCache: Bool) {
        phase = .scanning
        let start = ProcessInfo.processInfo.systemUptime
        Self.candidates = Self.candidates.filter { start - $0.value.seen <= 15 }
        if allowCache, !Self.reserved.isEmpty, let candidate = available(since: start - 15), select(candidate) {
            triedCachedDevice = true
            return
        }
        central.scanForPeripherals(withServices: nil,
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        arm(5) { handler in
            handler.central.stopScan()
            guard let candidate = handler.available(since: start), handler.select(candidate) else {
                handler.finish("notFound")
                return
            }
        }
    }

    private func select(_ candidate: Candidate) -> Bool {
        guard let selected = central.retrievePeripherals(withIdentifiers: [candidate.id]).first else {
            return false
        }
        central.stopScan()
        Self.reserved.insert(candidate.id)
        target = candidate
        peripheral = selected
        connectForCheck(selected)
        return true
    }

    private func connectForCheck(_ selected: CBPeripheral) {
        phase = .checking
        central.connect(selected)
        arm(9) { $0.checkLinkFailed() }
    }

    private func checkLinkFailed() {
        if triedCachedDevice {
            triedCachedDevice = false
            if let target = target {
                Self.candidates.removeValue(forKey: target.id)
                Self.reserved.remove(target.id)
            }
            let old = peripheral
            peripheral = nil
            target = nil
            if let old = old { central.cancelPeripheralConnection(old) }
            beginScan(allowCache: false)
        } else {
            finish("stream")
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && phase == .scanning && !central.isScanning {
            beginScan(allowCache: true)
        } else if phase != .idle && [.poweredOff, .unauthorized, .unsupported].contains(central.state) {
            finish("notFound")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard phase == .scanning, RSSI.intValue != 127,
              let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name,
              ["Sensoria-C1-", "Sensoria-C2-", "Sensoria-C3-"].contains(where: { name.hasPrefix($0) })
        else { return }
        Self.candidates[peripheral.identifier] = Candidate(
            id: peripheral.identifier, name: name, rssi: RSSI.intValue,
            seen: ProcessInfo.processInfo.systemUptime
        )
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard self.peripheral === peripheral, canUseControlPoint else { return }
        if phase == .checking { report("checking") }
        peripheral.delegate = self
        peripheral.discoverServices([Self.service])
        arm(8) { $0.controlPointFailed() }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard self.peripheral === peripheral else { return }
        if phase == .calibrating { startSDK() }
        else if phase == .checking { checkLinkFailed() }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard self.peripheral === peripheral else { return }
        transmitter = nil
        pending = nil
        switch phase {
        case .handoff, .calibrating:
            startSDK()
        case .checking:
            finish("configuration")
        default:
            break
        }
    }

    private func controlPointFailed() {
        if phase == .calibrating { restoreAfterCalibration("unavailable") }
        else { finish("configuration") }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard self.peripheral === peripheral, canUseControlPoint else { return }
        guard error == nil, let service = peripheral.services?.first(where: { $0.uuid == Self.service }) else {
            controlPointFailed()
            return
        }
        peripheral.discoverCharacteristics([Self.rx, Self.tx], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard self.peripheral === peripheral, canUseControlPoint else { return }
        guard error == nil, let rx = service.characteristics?.first(where: { $0.uuid == Self.rx }),
              let tx = service.characteristics?.first(where: { $0.uuid == Self.tx }),
              rx.properties.contains(.notify),
              tx.properties.contains(.writeWithoutResponse) || tx.properties.contains(.write)
        else {
            controlPointFailed()
            return
        }
        transmitter = tx
        peripheral.setNotifyValue(true, for: rx)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard self.peripheral === peripheral, canUseControlPoint, characteristic.uuid == Self.rx else { return }
        guard error == nil, characteristic.isNotifying else { controlPointFailed(); return }
        if phase == .calibrating { send([3, 3, 8]) }
        else { readSettings() }
    }

    private func readSettings() {
        ranges.removeAll()
        actualRates.removeAll()
        magneticOffsets = nil
        commands = [[3, 1, 3], [3, 2, 3], [3, 3, 3]]
        for offset in targetRates.indices {
            commands.append([3, UInt8(offset + 1), 1])
        }
        commands.append([3, 3, 6])
        commands.append([4, 1, 1])
        sendNext()
    }

    private func isOptionalRead(_ bytes: [UInt8]) -> Bool {
        bytes == [3, 3, 6] || (bytes.count == 3 && bytes[0] == 3 && bytes[2] == 1 &&
            (1...3).contains(bytes[1]) && targetRates[Int(bytes[1]) - 1] == 0)
    }

    private func send(_ bytes: [UInt8]) {
        guard let peripheral = peripheral, let tx = transmitter else { finish("configuration"); return }
        let writeType: CBCharacteristicWriteType = tx.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(Data(bytes), for: tx, type: writeType)
        if phase == .calibrating {
            arm(bytes == [3, 3, 8] ? 45 : 8) { $0.restoreAfterCalibration("unavailable") }
            return
        }
        arm(isOptionalRead(bytes) ? 2 : 4) { $0.controlPointTimedOut(bytes) }
    }

    private func isRead(_ command: [UInt8]) -> Bool {
        command.count == 3
    }

    private func controlPointTimedOut(_ command: [UInt8]) {
        guard pending == command, phase == .checking else { return }
        if isOptionalRead(command) {
            sendNext()
        } else if !isRead(command) {
            // The BLE write may have reached the Core even if the Control Point
            // acknowledgement was lost. The final readback is mandatory.
            NSLog("Sensoria slot %d: missing write acknowledgement %@", index, command.description)
            sendNext()
        } else if !retriedRead {
            retriedRead = true
            send(command)
        } else {
            configurationFailed("read timed out: \(command)")
        }
    }

    private func configurationFailed(_ detail: String, reason: String = "configuration") {
        NSLog("Sensoria slot %d configuration failed: %@", index, detail)
        finish(reason)
    }

    private func sendNext() {
        if commands.isEmpty {
            pending = nil
            verifyingWrites = true
            readSettings()
            return
        }
        let command = commands.removeFirst()
        pending = command
        retriedRead = false
        send(command)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if self.peripheral === peripheral && error != nil && canUseControlPoint {
            if phase == .calibrating { restoreAfterCalibration("unavailable"); return }
            if let pending = pending { controlPointTimedOut(pending) }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard self.peripheral === peripheral, canUseControlPoint,
              characteristic.uuid == Self.rx else { return }
        guard error == nil, let value = characteristic.value else { controlPointFailed(); return }
        let bytes = [UInt8](value)
        if phase == .calibrating { handleCalibrationReply(bytes); return }
        guard let command = pending else { return }
        guard bytes.count >= 3, bytes[0] == command[0], bytes[1] == command[1] else { return }
        if command == [3, 3, 6] {
            if let offsets = Self.decodeOffsets(bytes) {
                magneticOffsets = offsets
                sendNext()
            } else if [0x09, 0x15].contains(bytes[2]) {
                sendNext()
            }
            return
        }
        if bytes[2] != 8 {
            if isOptionalRead(command) { sendNext(); return }
            // A reply rejecting channel 0 can be repaired after the three
            // range reads succeeded. An absent reply still times out.
            if command == [4, 1, 1], [0x09, 0x15].contains(bytes[2]) {
                prepareWrites(channel: [])
            } else {
                let reason = command.starts(with: [3, 2, 4]) ? "gyroscopeRange" : "configuration"
                configurationFailed("Core rejected \(command): \(bytes)", reason: reason)
            }
            return
        }

        // Replies address the sensor, not its field. A late write ACK is
        // shorter than a read reply and must not be interpreted as its value.
        guard isRead(command) ? bytes.count >= 5 : bytes.count == 3 else { return }
        if command[0] == 3 && (command[2] == 3 || command[2] == 1) {
            let value = Int(bytes[3]) * 256 + Int(bytes[4])
            if command[2] == 3 { ranges.append(value) }
            else { actualRates[Int(command[1]) - 1] = value }
            sendNext()
        } else if command[0] == 4 && command[2] == 1 {
            prepareWrites(channel: Array(bytes.dropFirst(3)))
        } else {
            sendNext()
        }
    }

    private func prepareWrites(channel: [UInt8]) {
        guard ranges.count == 3 else { finish("configuration"); return }
        let validChannel = channel.count >= 3 && channel[0] >= 5 &&
            [0x0F, 0x02, 0x03, 0x04].contains(channel[1]) && channel[2] & 0x09 == 0x09
        let rateChanges = targetRates.indices.filter {
            targetRates[$0] != 0 && targetRates[$0] != actualRates[$0]
        }
        let updateChannel = !validChannel || (targetPeriod != 0 && targetPeriod != Int(channel[0]))
        if !updateChannel && ranges == targets && rateChanges.isEmpty {
            trialCounterBits = [0x02, 0x03].contains(channel[1]) ? 18 : 24
            packetPeriodMs = Int(channel[0])
            NSLog("Sensoria slot %d settings verified: ranges %@, rates %@, packet period %d ms",
                  index, ranges.description, actualRates.description, packetPeriodMs)
            pending = nil
            phase = .handoff
            if let peripheral = peripheral { central.cancelPeripheralConnection(peripheral) }
            arm(6) { $0.finish("configuration") }
            return
        }
        if verifyingWrites {
            guard !retriedVerification else {
                let reason = ranges[1] != targets[1] ? "gyroscopeRange" : "configuration"
                configurationFailed("readback ranges \(ranges), rates \(actualRates), channel \(channel); requested \(targets), \(targetRates), \(targetPeriod) ms", reason: reason)
                return
            }
            retriedVerification = true
            pending = nil
            arm(0.35) { $0.readSettings() }
            return
        }
        if !validChannel {
            let period = targetPeriod != 0 ? UInt8(targetPeriod) : (channel.first.flatMap { (5...200).contains($0) ? $0 : nil } ?? 32)
            let flags = (channel.count >= 3 ? channel[2] & 0x04 : 0) | 0x09
            commands.append([4, 1, 2, period, 0x0F, flags])
        } else if updateChannel {
            commands.append([4, 1, 5, UInt8(targetPeriod)])
        }
        for offset in rateChanges {
            let rate = targetRates[offset]
            commands.append([3, UInt8(offset + 1), 2, UInt8(rate >> 8), UInt8(rate & 0xFF)])
        }
        for (offset, range) in targets.enumerated() where ranges[offset] != range {
            commands.append([3, UInt8(offset + 1), 4, UInt8(range >> 8), UInt8(range & 0xFF)])
        }
        sendNext()
    }

    private func startSDK() {
        guard let target = target else { finish("stream"); return }
        let core = SACore()
        self.core = core
        phase = .starting
        if calibrationCompletion == nil { report("starting") }
        core.multiDelegate.add(delegate: self)
        core.deviceName = target.name
        core.connect(autoReconnect: false, immediateStreaming: false)
        arm(15) { $0.finish("stream") }
    }

    func didConnect(_ device: SADevice, peripheral: CBPeripheral) {
        guard device === core else { return }
        if peripheral.identifier != target?.id { finish("stream") }
    }

    func didDeviceReady(_ device: SADevice, peripheral: CBPeripheral) {
        guard device === core, peripheral.identifier == target?.id, phase == .starting else { return }
        timer?.cancel()
        core?.readBatteryLevel()
        guard let target = target else { finish("stream"); return }
        DeviceRegistry.shared.registerDevice(info: DeviceInfo(
            type: index == 1 ? .footRight : .footLeft,
            macAddress: target.id.uuidString, name: target.name, side: index == 1 ? "Right" : "Left"
        ))
        phase = .ready
        streamRequested = false
        buffer.connected(index)
        NSLog("Sensoria slot %d connected, waiting for trial or recording", index)
        report("connected")
        completeCalibration(calibrationOutcome)
        updateCapture()
    }

    // Notification changes are asynchronous. Reconcile a late start/stop
    // callback with the latest request, including quickly leaving the trial.
    func didStartStreaming(_ device: SADevice, peripheral: CBPeripheral) {
        guard device === core, peripheral.identifier == target?.id, isReady else { return }
        if !streamRequested { core?.pauseStreaming() }
    }

    func didPauseStreaming(_ device: SADevice, peripheral: CBPeripheral) {
        guard device === core, peripheral.identifier == target?.id, isReady else { return }
        if streamRequested { core?.resumeStreaming() }
    }

    func didBatteryRead(_ batteryValue: UInt8, device: SADevice, peripheral: CBPeripheral) {
        if device === core && peripheral.identifier == target?.id { lastBatteryLevel = batteryValue }
    }

    func didUpdateData(_ data: SAData, device: SADevice, peripheral: CBPeripheral) {
        guard device === core, let target = target, peripheral.identifier == target.id,
              isReady, streamRequested else { return }
        lastCaptureSample = ProcessInfo.processInfo.systemUptime
        timer?.cancel()
        let side = index == 1 ? "Right" : "Left"
        if phase == .ready {
            phase = .streaming
            NSLog("Sensoria slot %d received its first data packet", index)
        }
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        StatusUpdateManager.shared.sensoriaData.lastDataTimestampCore[index] = timestamp
        let row = "\(data.s0),\(data.s1),\(data.s2),\(data.accX),\(data.accY),\(data.accZ),\(data.magX),\(data.magY),\(data.magZ),\(data.gyroX),\(data.gyroY),\(data.gyroZ),\(timestamp)"
        if collectingTrial && trialSamples.count < 1000 {
            trialSamples.append([index, Int(data.tick), trialCounterBits, ranges[0], ranges[2], packetPeriodMs, row])
        }
        if buffer.isRecording { lastRecordingSample = ProcessInfo.processInfo.systemUptime }
        buffer.addData(data: "\(row),\(side)")
    }

    func didDisconnect(_ message: String, device: SADevice, peripheral: CBPeripheral?) {
        guard device === core else { return }
        if phase == .calibrating, let peripheral = self.peripheral {
            core = nil
            central.connect(peripheral)
            arm(10) { $0.finish("stream") }
        } else {
            finish(isReady ? nil : "stream")
        }
    }

    func didSignalLost(_ message: String, device: SADevice, peripheral: CBPeripheral?) {
        if device === core { finish("stream") }
    }

    private func finish(_ error: String?) {
        guard phase != .idle else { return }
        if isReady { buffer.flush() }
        streamRequested = false
        collectingTrial = false
        trialSamples.removeAll()
        buffer.disconnected(index)
        phase = .idle
        timer?.cancel()
        central.stopScan()
        let oldCore = core
        core = nil
        oldCore?.disconnect()
        let oldPeripheral = peripheral
        peripheral = nil
        if let oldPeripheral = oldPeripheral, oldPeripheral.state != .disconnected {
            central.cancelPeripheralConnection(oldPeripheral)
        }
        if let target = target {
            DeviceRegistry.shared.removeDevice(macAddress: target.id.uuidString)
            Self.reserved.remove(target.id)
            Self.candidates.removeValue(forKey: target.id)
        }
        target = nil
        transmitter = nil
        pending = nil
        commands.removeAll()
        lastBatteryLevel = 0
        report("disconnected", error: error)
        completeCalibration("unavailable")
    }
}
