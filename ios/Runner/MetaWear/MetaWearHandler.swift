import Foundation
import MetaWear
import MetaWearCpp
import BoltsSwift







class MetaWearHandler: NSObject {
    
    static let shared = MetaWearHandler()
    
    


    private var scannedDevices = [MetaWear]()
    private var connectedDevices = Set<String>()
    
    
    private var deviceRssiMap = [MetaWear: Int]()
    private var connectionQueue = [Int]()
    private var isScanning = false
    private var isConnecting = false
    var lastScanTimestamp: TimeInterval = 0
    
    private let scanPeriod = 10.0
    
    var streamingCleanup: [OpaquePointer: () -> Void] = [:]
    private var dataBuffer: [String] = []
     var currentFusionDataSample = SensorFusionDataSample()
    private var allSensorData: [SensorFusionDataSample] = []
    
    
    var lastDataTimestampSensorFusionBoard1: TimeInterval = 0
    var lastDataTimestampSensorFusionBoard2: TimeInterval = 0
    var lastDataTimestampTemperatureBoard1: TimeInterval = 0
    var lastDataTimestampTemperatureBoard2: TimeInterval = 0
    var lastDataTimestampAmbientLightBoard1: TimeInterval = 0
    var lastDataTimestampAmbientLightBoard2: TimeInterval = 0
    var lastDataWriteFileTimestamps: TimeInterval = 0
    
    var currentLanguageCode: String = "es"


    
    private var currentHand: String?
    
    var currentDevice: MetaWear?

    var currentDataType: String?
    private let bufferLock = NSLock()


    
    var illuminanceBuffer: [UInt32] = []
    let bufferCapacity: Int = 5 // For example, save data after 100 measurements
    var illuminance: Double?  // Property to store the latest illuminance value
    
    
    
    
    var device1: MetaWear?
    var device2: MetaWear?
    
    var pendingResult: FlutterResult?
    
    
    var ambientLightBuffer: [String] = []
    
    
    
    let scanValidityPeriod: TimeInterval = 60000 //60 seconds
    
    
    //MARK: -Init
    override init() {
        super.init()


    }
    
    

   //MARK: Connection status event listenet
//    
//    var connectionStatusEventSink: FlutterEventSink? = { _ in }  // Default to a dummy closure
//    
//    // Method to set the event sink from AppDelegate or any other caller
//    func setConnectionStatusEventSink(eventSink: @escaping FlutterEventSink) {
//        self.connectionStatusEventSink = eventSink
//    }
//    
//    func clearConnectionStatusEventSink() {
//        self.connectionStatusEventSink = { _ in }
//    }
//    
//    // Method to update connection status
//    func updateConnectionStatus(deviceIndex: Int, status: String) {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            let statusUpdate: [String: Any] = ["deviceIndex": deviceIndex, "status": status]
//            print("status in metawearhandler",status,statusUpdate)
//            self.connectionStatusEventSink?(statusUpdate)
//        }
//    }
    
//    func updateConnectionStatus(deviceIndex: Int ,status: String) {
//            let statusUpdate: [String: Any] = ["deviceIndex": deviceIndex, "status": status]
//            EventManager.shared.dispatchEvent(statusUpdate)
//        }
    
    func updateConnectionStatus(deviceIndex: Int ,status: String) {
        let statusUpdate: [String: Any] = ["deviceIndex": deviceIndex, "status": status]
        DispatchQueue.main.async {
            EventManager.shared.dispatchEvent(statusUpdate)
            print("in metawearhanlder the update issssss \(statusUpdate)")
        }
    }

    
//MARK: Set language
    func setLocale(languageCode: String) {
           currentLanguageCode = languageCode // Save the current language code
       }
    
    
    
    // MARK: - Connect To Device
    
    func connectToDevice(index: Int) {
//        self.updateConnectionStatus(deviceIndex: index, status: "connecting")
        connectionQueue.append(index)
        if !isScanning && !isConnecting {
            processNextConnection()
        } else {
            print("Connection or scan in progress, device index queued: \(index)")
        }
    }
    
    // MARK: - processNextConnection
    
    func processNextConnection() {
        guard !connectionQueue.isEmpty, !isScanning  else { return }//TODO: check if  necessary to place !isConnecting

        
        let currentTime = Double(Date().timeIntervalSince1970 * 1000) // Current time in milliseconds
        
        print("the curent time issssss",currentTime)
        print("the lastscan time time issssss",lastScanTimestamp)

        
        let diffetime=lastScanTimestamp-currentTime
        print("difer timeeeeeeeeeeee isssssss",diffetime)
        
        if   currentTime - lastScanTimestamp > scanValidityPeriod || scannedDevices.isEmpty {
            if let deviceIndex = connectionQueue.first {
                startScanWithConnectionIntent(deviceIndex)
            }
        } else {
            if scannedDevices.count == 1 && connectionQueue.count >= 2 {
                let deviceIndexToConnect = connectionQueue.removeFirst()
                connectToFirstAvailableDevice(deviceIndex: deviceIndexToConnect)
                
                while !connectionQueue.isEmpty {
                    let queuedDeviceIndex = connectionQueue.removeFirst()
                    updateConnectionStatus(deviceIndex:queuedDeviceIndex, status: "disconnected")
                    var message: String
                    switch currentLanguageCode {
                    case "es":
                        message = "No se encontró el MMR."
                    default:
                        message = "No  MMR device found."
                    }

                    if let viewController = UIApplication.shared.keyWindow?.rootViewController {
                        ToastManager.shared.showToast(message: message, in: viewController)
                    }
                }
            } else {
                if let deviceIndex = connectionQueue.first {
                    connectionQueue.removeFirst()
                    connectToFirstAvailableDevice(deviceIndex: deviceIndex)
                }
            }
        }
    }
    
  
    
    //       private func updateConnectionStatus(_ deviceIndex: Int, status: String) {
    //           // Update the status of the deviceIndex in your app, possibly triggering UI updates
    //           print("Device \(deviceIndex) status updated to \(status)")
    //       }
    
    
    
    func startScanWithConnectionIntent(_ deviceIndex: Int) {
        
        print("startscanwit intention for the device",deviceIndex)
        
        
        startScanning()
        
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + scanPeriod) {
            
            print("the returned scanned device are",self.scannedDevices)
            
            
            if self.scannedDevices.isEmpty {
                self.updateConnectionStatus(deviceIndex:deviceIndex, status: "disconnected")
                
                DispatchQueue.main.async {
                    let handName = deviceIndex == 1 ? "Right" : "Left"
                    var message: String
                    switch self.currentLanguageCode {
                            case "es":
                                message = handName == "Right" ? "No se encontró el dispositivo para la mano derecha." : "No se encontró el dispositivo para la mano izquierda."
                            default:
                                message = "No MetaWear device found for \(handName) hand."
                            }

                            // Show the toast with the personalized and localized message
                            if let viewController = UIApplication.shared.keyWindow?.rootViewController {
                                ToastManager.shared.showToast(message: message, in: viewController)
                            }
                   
                    
                    
                    // Update the status of the device in the queue
                    while !self.connectionQueue.isEmpty {
                        let queuedDeviceIndex = self.connectionQueue.removeFirst()
                        self.updateConnectionStatus(deviceIndex:queuedDeviceIndex, status: "disconnected")
                    }
                }
            } else {
                self.processNextConnection()
            }
        }
    }
    
//    // Implement this method to handle showing messages to the user
//    private func showToast(message: String) {
//        print(message)
//    }
    
    
    
    
    func startScanning() {
//        guard !isScanning, centralManager.state == .poweredOn else { return }
        print("scan is called")
        scannedDevices.removeAll()
        deviceRssiMap.removeAll()
        
        isScanning = true
        
        
        MetaWearScanner.shared.startScan(allowDuplicates: true) { (device) in
            if !self.scannedDevices.contains(device) {
                self.scannedDevices.append(device)
                self.deviceRssiMap[device] = device.rssi
                print("Found MetaWear device: \(device.name) with RSSI: \(device.rssi) with MAC \(String(describing: device.mac))")
               
                print("the device is ",device)
                
                
                
                
            }
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.stopScanning()
        }
    }
    
    func stopScanning() {
        if isScanning {
            MetaWearScanner.shared.stopScan()
            isScanning = false
            lastScanTimestamp = Double(Date().timeIntervalSince1970 * 1000)
            print("Scan complete. Devices found: \(scannedDevices.count)")
            
            if scannedDevices.isEmpty {
                print("No MetaWear devices found.")
            }
            
        }
    }
    
    
    
    

    
    //-------------------------------------------------------------
    private func connectToFirstAvailableDevice(deviceIndex: Int) {
        if scannedDevices.isEmpty {
            print("No devices found. Starting scan.")
            startScanWithConnectionIntent(deviceIndex)
            return
        }
        
        var deviceToConnect: MetaWear?
        var maxRssi = Int.min
        
        for device in scannedDevices {
            if let rssi = deviceRssiMap[device],!connectedDevices.contains(device.peripheral.identifier.uuidString), rssi > maxRssi {
                deviceToConnect = device
                maxRssi = rssi
            }
        }
        
        if let deviceToConnect = deviceToConnect{
            let deviceIdentifier = deviceToConnect.peripheral.identifier.uuidString

            isConnecting = true
            print("Connecting to device with the highest RSSI: \(deviceIdentifier) (RSSI: \(maxRssi))")
            
            deviceToConnect.connectAndSetup().continueWith { [weak self] task in
                guard let self = self else { return }
                if let error = task.error {
                    print("Connection failed: \(error.localizedDescription)")
                    self.updateConnectionStatus(deviceIndex: deviceIndex, status: "disconnected")
                    self.isConnecting = false
                    self.processNextConnection()
                    return
                }
                
                print("Connected to \(deviceIdentifier)")
                self.connectedDevices.insert(deviceIdentifier)
                self.scannedDevices.removeAll { $0 === deviceToConnect }
                
                self.updateConnectionStatus(deviceIndex: deviceIndex, status: "connected")
                
                if deviceIndex == 1 {
                    self.device1 = deviceToConnect
                    self.setupDevice(deviceToConnect, hand: "Right")
                } else if deviceIndex == 2 {
                    self.device2 = deviceToConnect
                    self.setupDevice(deviceToConnect, hand: "Left")
                }
                
                self.isConnecting = false
                self.processNextConnection()
            }
        } else {
            print("No available device found with higher RSSI to connect.")
            isConnecting = false
            updateConnectionStatus(deviceIndex: deviceIndex, status: "disconnected")
            
            // TODO: i have to implement the toast-line 545 android
            
        }
    }
    
    
    //MARK: -Setup Device
    
    private func setupDevice(_ device: MetaWear, hand: String) {
        

        if let macAddress = device.mac {
                let deviceType = (hand == "Right") ? DeviceType.handRight : DeviceType.handLeft
                let deviceInfo = DeviceInfo(type: deviceType, macAddress: macAddress, name: device.name ,side: hand)
                
                DeviceRegistry.shared.registerDevice(info: deviceInfo)
                print("Device \(macAddress) registered as \(hand) hand in DeviceRegistry.")
            
                let ledColor = hand == "Right" ? "green" : "blue"
            startLed(deviceIndex: (hand == "Right" ? 1 : 2), blinkCount: 5, color: ledColor)

                startAmbientLightMeasurement(device: device)
                startTemperatureMeasurement(device: device)
                startBarometerMeasurement(device: device)
                startSensorFusionMeasurement(device: device)

            }
    

    }
    
    
    
    
    // MARK: - LED Control
    
    func startLed(deviceIndex : Int,blinkCount: Int,color: String){
        guard let device = (deviceIndex == 1 ? device1 : device2) else {
                   print("Failed to retrieve device or board for index \(deviceIndex)")
                 return
         }
        LedManager.shared.Led(device: device, blinkCount: blinkCount, color: color)
    }
    
    
    

    
    
    
    // MARK: - Battery Monitoring
    
    static let batteryDataCallback: MblMwFnData = { context, dataPointer in
        guard let context = context, let data = dataPointer?.pointee else { return }
        let handler = Unmanaged<MetaWearHandler>.fromOpaque(context).takeUnretainedValue()
        
        // Extract battery state
        let batteryState: MblMwBatteryState = data.valueAs()
        DispatchQueue.main.async {
            handler.completion?(Int(batteryState.charge), nil)
        }
    }
    
    // Property to hold completion handler
    var completion: ((Int?, Error?) -> Void)?
    
    func getBatteryLevel(deviceIndex: Int, completion: @escaping (Int?, Error?) -> Void) {
        self.completion = completion
        let device = (deviceIndex == 1) ? device1 : device2
        guard let board = device?.board else {
            completion(nil, NSError(domain: "MetaWearHandler", code: 0, userInfo: [NSLocalizedDescriptionKey: "No board connected"]))
            return
        }
        
        guard let batterySignal = mbl_mw_settings_get_battery_state_data_signal(board) else {
            completion(nil, NSError(domain: "MetaWearHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot get battery state data signal"]))
            return
        }
        
        let contextPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        mbl_mw_datasignal_subscribe(batterySignal, contextPointer, MetaWearHandler.batteryDataCallback)
        mbl_mw_datasignal_read(batterySignal)
    }
    
    
    // MARK: - Disconnecting Devices
    
    func disconnectDevice(deviceIndex: Int) {
        
            
        guard let device = (deviceIndex == 1) ? device1 : device2,
                  let macAddress = device.mac,
                  let board = device.board else {
                print("Failed to find device to disconnect at index: \(deviceIndex)")
                return
            }

            print("Disconnect command sent to device index: \(deviceIndex)")

        
        scannedDevices.removeAll()
        connectionQueue.removeAll()
        connectedDevices.remove(macAddress)
        isScanning = false
        lastScanTimestamp = 0
        
        currentFusionDataSample = SensorFusionDataSample()
        dataBuffer.removeAll()
        
        DeviceRegistry.shared.removeDevice(macAddress: macAddress)

        
        stopAmbientLightMeasurement(device: device)
        stopTemperatureMeasurement(device: device)
        stopBarometerMeasurement(device: device)
        stopSensorFusionMeasurement(device: device)

        if deviceIndex == 1 {
            self.device1 = nil
        } else if deviceIndex == 2 {
            self.device2 = nil
        }

        mbl_mw_debug_disconnect(board)
      
    }
    
    
//    // MARK: - Sensor Fusion Start
    
    func startSensorFusionMeasurement(device: MetaWear){
        SensorFusionManager.shared.startSensorFusion(device: device)
    }
    func stopSensorFusionMeasurement(device: MetaWear){
        SensorFusionManager.shared.stopSensorFusion(device: device)
    }

    


    //MARK: -Ambient Light
    
    func startAmbientLightMeasurement(device: MetaWear){
        AmbientLightManager.shared.startAmbientLight(device: device)
    }
    
    func stopAmbientLightMeasurement(device: MetaWear){
        AmbientLightManager.shared.stopAmbientLight(device: device)
    }
    

        
        //MARK: -Temperature
    
    func startTemperatureMeasurement(device: MetaWear){
        TemperatureManager.shared.startTemperature(device: device)
    }
    
    func stopTemperatureMeasurement(device: MetaWear){
        TemperatureManager.shared.stopTemperature(device: device)
    }
    
    
    
        //MARK: -Barometer
    
    func startBarometerMeasurement(device: MetaWear){
        BarometerManager.shared.startBarometer(device: device)
    }
    
    func stopBarometerMeasurement(device: MetaWear){
        BarometerManager.shared.stopBarometer(device: device)
    }
        

   

        //MARK: -Status data
        func getCurrentStatus(forDeviceIndex deviceIndex: Int) -> String {
            var statusMap = [String: Any]()
            
            let board = (deviceIndex == 1) ? device1?.board : device2?.board 
            
            if let board = board {
                statusMap["lastDataTimestampSensorFusion"] = Int((deviceIndex == 1 ? lastDataTimestampSensorFusionBoard1 : lastDataTimestampSensorFusionBoard2) * 1000)
                statusMap["lastDataTimestampTemperature"] = Int((deviceIndex == 1 ? lastDataTimestampTemperatureBoard1 : lastDataTimestampTemperatureBoard2) * 1000)
                statusMap["lastDataTimestampAmbientLight"] = Int((deviceIndex == 1 ? lastDataTimestampAmbientLightBoard1 : lastDataTimestampAmbientLightBoard2) * 1000)
                statusMap["lastDataWriteToTimestamp"] = Int(lastDataWriteFileTimestamps * 1000)
                //            statusMap["isConnected"] = board.isConnected //
            } else {
                statusMap["lastDataTimestampSensorFusion"] = "N/A"
                statusMap["lastDataTimestampTemperature"] = "N/A"
                statusMap["lastDataTimestampAmbientLight"] = "N/A"
                statusMap["lastDataWriteToTimestamp"] = "N/A"
                statusMap["isConnected"] = false
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: statusMap, options: [])
                if let jsonString = String(data: data, encoding: .utf8) {
                    return jsonString
                }
            } catch {
                print("Error serializing status map: \(error)")
            }
            return "{}"
        }
        
        
        
        
    }

