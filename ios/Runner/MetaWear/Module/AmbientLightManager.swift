import Foundation
import MetaWear
import MetaWearCpp



class AmbientLightManager {
    static let shared = AmbientLightManager()
        
        private var ambientLightBuffer: [String] = []
    
    var currentDevice: MetaWear?


        private init() {}
    
    
    
    
    func startAmbientLight(device: MetaWear) {
        guard let board = device.board else {
            print("Device setup failed or board not found.")
            return
        }

        let context = UnsafeMutableRawPointer(Unmanaged.passRetained(device).toOpaque())
        
        //         Configure the Ambient Light sensor
              mbl_mw_als_ltr329_set_integration_time(board, MBL_MW_ALS_LTR329_TIME_350ms)
              mbl_mw_als_ltr329_set_measurement_rate(board, MBL_MW_ALS_LTR329_RATE_2000ms)
              mbl_mw_als_ltr329_write_config(board)
        
        if let signal = mbl_mw_als_ltr329_get_illuminance_data_signal(board) {
            mbl_mw_datasignal_subscribe(signal, context, AmbientLightManager.dataCallback)
            mbl_mw_als_ltr329_start(board)
        } else {
            print("Failed to get illuminance data signal.")
            Unmanaged<MetaWear>.fromOpaque(context).release() // Release if not subscribing
        }
    }
    
    
    static let dataCallback: MblMwFnData = { (context, dataPointer) in
        guard let context = context, let data = dataPointer?.pointee else { return }
        let device = Unmanaged<MetaWear>.fromOpaque(context).takeUnretainedValue()

        let illuminance: UInt32 = data.valueAs()
        let timestamp = Date().timeIntervalSince1970

        if let macAddress = device.mac, let deviceInfo = DeviceRegistry.shared.getDeviceInfo(macAddress: macAddress) {

            let hand = deviceInfo.side
            let ambientData = AmbientLightData(ambientLight: illuminance, timestamp: timestamp, hand: hand)
            let dataString = ambientData.toString()
            
            if !dataString.isEmpty {
                let timestampInMilliseconds = Int(Date().timeIntervalSince1970 * 1000)
                if hand == "Right" {
                    StatusUpdateManager.shared.metaWearData.lastDataTimestampAmbientLight[1] = timestampInMilliseconds
                } else {
                    StatusUpdateManager.shared.metaWearData.lastDataTimestampAmbientLight[2] = timestampInMilliseconds
                }
            }

            
            AmbientLightManager.shared.ambientLightBuffer.append(dataString)
            AmbientLightManager.shared.checkBufferAndSave()
        }
    }

      

        private func checkBufferAndSave() {
            if ambientLightBuffer.count >= 50 {
                sendAmbientLightData()
//                ambientLightBuffer.removeAll() //TODO:  i have to check when start to place to buffer again is it cleared or not
            }
        }
    
  
    private func sendAmbientLightData(){
                
        let dataType = "MI"
        
        LocationDataManager.shared.fetchLocationAndSaveData(dataType: dataType,
                                                            dataBuffer: self.ambientLightBuffer){ success in
            
            
            if success {
                self.ambientLightBuffer.removeAll()
            } else {
                print("Failed to save data. Retrying or keeping data for later.")
            }
        }
    
    }
    
    

    
    func stopAmbientLight(device: MetaWear) {
        guard let board = device.board, let signal = mbl_mw_als_ltr329_get_illuminance_data_signal(board) else {
            print("Failed to get illuminance data signal or board is not available.")
            return
        }

        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(device).toOpaque())
        mbl_mw_datasignal_unsubscribe(signal)
        mbl_mw_als_ltr329_stop(board)
        Unmanaged<MetaWear>.fromOpaque(context).release() // Release the retained device
    }
    
    
    
}


