import Foundation
import CoreBluetooth
import SensoriaiOS
import BoltsSwift

class SensoriaHandlerRight: NSObject, SADeviceBluetoothDelegate {
    
    var eventSink: FlutterEventSink?
    var coreIndex: Int = 1 
    
    var lastBatteryLevel: UInt8 = 0  // Default or initial battery level
    
    var scanTimer: Timer?

    var currentLanguageCode: String = "es"  



    
    var sacore: SACore!
    var centralBuffer: CentralBufferManager

    init(centralBuffer: CentralBufferManager) {
        
        self.centralBuffer = centralBuffer
        self.sacore = SACore()
        super.init()
        sacore.multiDelegate.add(delegate: self)
    }
    
    
    
    func updateConnectionStatus(status: String) {
        let statusUpdate: [String: Any] = ["coreIndex": coreIndex, "status": status]
        DispatchQueue.main.async {
            EventManager.shared.dispatchEvent(statusUpdate)
        }
    }

    
    
    
    func didBatteryRead(_ batteryValue: UInt8) {
            lastBatteryLevel = batteryValue
            print("Right device battery level: \(batteryValue)")
        }

        func getBatteryLevel() -> UInt8 {
            return lastBatteryLevel
        }
    
    

    
    func setLocale(languageCode: String) {
           currentLanguageCode = languageCode // Save the current language code
       }
    

    func startScan() {
        print("Starting scan for right device.")
        sacore.startScan()
        scanTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(stopScan), userInfo: nil, repeats: false)

    }
    
    

    
    
    @objc func stopScan() {
            sacore.stopScan()
            if (sacore.deviceName ?? "").isEmpty {
                var message: String
                switch currentLanguageCode {
                case "es":
                    message = "No se encontró el calcetín derecho."
                default:
                    message = "No right sock device found."
                }

                if let viewController = UIApplication.shared.keyWindow?.rootViewController {
                    ToastManager.shared.showToast(message: message, in: viewController)
                }
                self.updateConnectionStatus(status: "disconnected")
            }
            scanTimer?.invalidate()
            scanTimer = nil
        }

    

    func didScan(_ deviceName: String, peripheral: CBPeripheral, device: SADevice) {
        print("Left device scanned: \(deviceName) \(peripheral) \(device)")
        
        
        if !deviceName.isEmpty {
            sacore.deviceName = deviceName
            sacore.connect()
            // Device found, we can cancel the timer
            scanTimer?.invalidate()
            scanTimer = nil
            print("Device found and attempting to connect: \(deviceName)")
        }
    }
    




    func didConnect (_ device: SADevice, peripheral: CBPeripheral) {
        print("Right device connected.")
        
        if sacore.connected{
            self.updateConnectionStatus(status: "connected")
        }
        
        let uuid = peripheral.identifier.uuidString

        
        let deviceInfo = DeviceInfo(type: .footRight, macAddress: uuid, name: device.deviceName! ,side: "Right")
        DeviceRegistry.shared.registerDevice(info: deviceInfo)
        
        

        sacore.resumeStreaming()
    }
    
    

    func didUpdateData() {
        
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)

        let data = SensorData(
            s0: sacore.s0,
            s1: sacore.s1,
            s2: sacore.s2,
            accX: sacore.accX,
            accY: sacore.accY,
            accZ: sacore.accZ,
            magX: sacore.magX,
            magY: sacore.magY,
            magZ: sacore.magZ,
            gyroX: sacore.gyroX,
            gyroY: sacore.gyroY,
            gyroZ: sacore.gyroZ,
            timestamp: timestamp,
            footIndicator: "Right"
        )
        

        let formattedData = "\(data.s0),\(data.s1),\(data.s2),\(data.accX),\(data.accY),\(data.accZ),\(data.magX),\(data.magY),\(data.magZ),\(data.gyroX),\(data.gyroY),\(data.gyroZ),\(timestamp),\(data.footIndicator)"
        
        
        if !formattedData.isEmpty {
            let timestampInMilliseconds = Int(Date().timeIntervalSince1970 * 1000)
            
            StatusUpdateManager.shared.sensoriaData.lastDataTimestampCore[1] = timestampInMilliseconds
        }
        // Assuming centralBuffer accepts SensorData struct
        centralBuffer.addData(data: formattedData)
    }


    func didError(_ message: String) {
        print("Error from right device: \(message)")
    }
    
     func disconnect(){
        sacore.disconnect()

    }
    
    func didDisconnect(_ message: String) {
        print("the device disconnected \(message)")
        self.updateConnectionStatus(status: "disconnected")

    }
    
   
    

}
