import Foundation
import SensoriaiOS
import BoltsSwift

class SensoriaHandler: NSObject, SADeviceBluetoothDelegate {
    static let shared = SensoriaHandler()
    var sacores: [SACore] = [SACore(), SACore()]
    var activeScanningCore: SACore?

    var dataBuffer: [String] = []  // Buffer to store formatted data
    let maxBufferSize = 1000
    let bufferQueue = DispatchQueue(label: "com.sensoriahandler.bufferQueue")  // For thread-safe buffer operations

    override init() {
        super.init()
        sacores.forEach { core in
            core.multiDelegate.add(delegate: self)
        }
        print("SensoriaHandler initialized with two SACore instances.")
    }

    func startConnection(deviceIndex: Int) {
        let core = sacores[deviceIndex - 1]
        activeScanningCore = core
        core.startScan()
    }

    func didScan(_ deviceName: String) {
        guard let scanningCore = activeScanningCore else {
            print("Error: No active scanning core")
            return
        }

        let deviceSide = (scanningCore == sacores[0]) ? "Right" : "Left"
        let deviceType = (deviceSide == "Right") ? DeviceType.footRight : DeviceType.footLeft
        let deviceInfo = DeviceInfo(type: deviceType, macAddress: deviceName, name: deviceName, side: deviceSide)
        DeviceRegistry.shared.registerDevice(info: deviceInfo)

        scanningCore.deviceName = deviceName
        scanningCore.connect()
    }

    func didUpdateData() {
        guard let core = activeScanningCore, let deviceName = core.deviceName, let deviceInfo = DeviceRegistry.shared.getDeviceInfo(macAddress: deviceName) else {
            print("Error: Data update without active core or device name mapping.")
            return
        }

        let footIndicator = deviceInfo.side
        let formattedData = formatData(from: core, footIndicator: footIndicator)

        bufferQueue.async { [weak self] in
            self?.dataBuffer.append(formattedData)
            if self?.dataBuffer.count ?? 0 >= self?.maxBufferSize ?? 0 {
                self?.processAndClearBuffer()
            }
        }
    }

    private func formatData(from core: SACore, footIndicator: String) -> String {
        return "\(core.s0),\(core.s1),\(core.s2),\(core.accX),\(core.accY),\(core.accZ),\(core.magX),\(core.magY),\(core.magZ),\(core.gyroX),\(core.gyroY),\(core.gyroZ),\(core.timestamp),\(footIndicator)"
    }

    private func processAndClearBuffer() {
        print("Processing buffer data\(dataBuffer)")
        dataBuffer.removeAll()
    }

    func didError(_ message: String) {
        print("Error: \(message)")
    }
}
