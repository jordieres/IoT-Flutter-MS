import Foundation
import MetaWear
import MetaWearCpp

class TemperatureManager {
    static let shared = TemperatureManager()

    private var temperatureBuffer: [String] = []
    
    private init() {}

    func startTemperature(device: MetaWear) {
        guard let board = device.board else {
            print("Device setup failed or board not found.")
            return
        }

        let context = UnsafeMutableRawPointer(Unmanaged.passRetained(device).toOpaque())
        
        if let signal = mbl_mw_multi_chnl_temp_get_temperature_data_signal(board, UInt8(MBL_MW_TEMPERATURE_SOURCE_NRF_DIE.rawValue)) {
            mbl_mw_datasignal_subscribe(signal, context, TemperatureManager.dataCallback)
            
            // Read the temperature every minute using a timer
            let timer = Timer(timeInterval: 600, repeats: true) { _ in
                mbl_mw_datasignal_read(signal)
            }
            RunLoop.main.add(timer, forMode: .common)
        } else {
            print("Failed to get temperature data signal.")
            Unmanaged<MetaWear>.fromOpaque(context).release() // Release if not subscribing
        }
    }

    static let dataCallback: MblMwFnData = { (context, dataPointer) in
        guard let context = context, let data = dataPointer?.pointee else { return }
        let device = Unmanaged<MetaWear>.fromOpaque(context).takeUnretainedValue()

        let temperature: Float = data.valueAs()
        let timestamp = Date().timeIntervalSince1970

        if let macAddress = device.mac, let deviceInfo = DeviceRegistry.shared.getDeviceInfo(macAddress: macAddress) {

            let hand = deviceInfo.side
            let temperatureData = TemperatureData(temperature: temperature, timestamp: timestamp, hand: hand)
            let dataString = temperatureData.toString()
            
            if !dataString.isEmpty {
                let timestampInMilliseconds = Int(Date().timeIntervalSince1970 * 1000)
                if hand == "Right" {
                    StatusUpdateManager.shared.metaWearData.lastDataTimestampTemperature[1] = timestampInMilliseconds
                } else {
                    StatusUpdateManager.shared.metaWearData.lastDataTimestampTemperature[2] = timestampInMilliseconds
                }
            }
            TemperatureManager.shared.temperatureBuffer.append(dataString)
            TemperatureManager.shared.checkBufferAndSave()
        }
    }

    private func checkBufferAndSave() {
        if temperatureBuffer.count >= 10 {
            sendTemperatureData()
        }
    }

    private func sendTemperatureData() {
        print("received the temp data \(temperatureBuffer)")
        let dataType = "MT"
        
        LocationDataManager.shared.fetchLocationAndSaveData(dataType: dataType, dataBuffer: self.temperatureBuffer) { success in
            if success {
                self.temperatureBuffer.removeAll()
            } else {
                print("Failed to save data. Retrying or keeping data for later.")
            }
        }
    }

    func stopTemperature(device: MetaWear) {
        guard let board = device.board, let signal = mbl_mw_multi_chnl_temp_get_temperature_data_signal(board, UInt8(MBL_MW_TEMPERATURE_SOURCE_NRF_DIE.rawValue)) else {
            print("Failed to get temperature data signal or board is not available.")
            return
        }

        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(device).toOpaque())
        mbl_mw_datasignal_unsubscribe(signal)
        Unmanaged<MetaWear>.fromOpaque(context).release() // Release the retained device
    }
}
