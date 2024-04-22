import Foundation
import CoreBluetooth
import SensoriaiOS
import BoltsSwift

class SensoriaHandlerLeft: NSObject, SADeviceBluetoothDelegate {
    var eventSink: FlutterEventSink?
    
    var coreIndex: Int = 2
    
    var lastBatteryLevel: UInt8 = 0
    
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
            print("Left device battery level: \(batteryValue)")
        }

        func getBatteryLevel() -> UInt8 {
            return lastBatteryLevel
        }
    
    
    func setLocale(languageCode: String) {
           currentLanguageCode = languageCode 
       }
    
    
    func startScan() {
        print("Starting scan for Left device.")
        sacore.startScan()
        scanTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(stopScan), userInfo: nil, repeats: false)

    }
    
    
    @objc func stopScan() {
            sacore.stopScan()
            if (sacore.deviceName ?? "").isEmpty {
                var message: String
                switch currentLanguageCode {
                case "es":
                    message = "No se encontró el calcetín izquierdo."
                default:
                    message = "No left sock found."
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
        print("Left device connected.")
        
        let uuid = peripheral.identifier.uuidString

        
        let deviceInfo = DeviceInfo(type: .footLeft, macAddress: uuid, name: device.deviceName! ,side: "Left")
        DeviceRegistry.shared.registerDevice(info: deviceInfo)
        
        self.updateConnectionStatus(status: "connected")

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
            footIndicator: "Left"
        )
        


        let formattedData = "\(data.s0),\(data.s1),\(data.s2),\(data.accX),\(data.accY),\(data.accZ),\(data.magX),\(data.magY),\(data.magZ),\(data.gyroX),\(data.gyroY),\(data.gyroZ),\(timestamp),\(data.footIndicator)"

        if !formattedData.isEmpty {
            let timestampInMilliseconds = Int(Date().timeIntervalSince1970 * 1000)
            
            StatusUpdateManager.shared.sensoriaData.lastDataTimestampCore[2] = timestampInMilliseconds
        }
        
        centralBuffer.addData(data: formattedData)
    }


    func didError(_ message: String) {
        print("Error from Left device: \(message)")
    }
    
     func disconnect(){
        sacore.disconnect()
    }
    
    func didDisconnect(_ message: String) {
        print("the device disconnected \(message)")
        self.updateConnectionStatus(status: "disconnected")

    }
    
   
    
    
}
