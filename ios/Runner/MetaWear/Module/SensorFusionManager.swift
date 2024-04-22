import Foundation
import MetaWear
import MetaWearCpp




class SensorFusionManager {
    
    static let shared = SensorFusionManager()
   
    var dataBuffer: [String] = []
    var currentFusionDataSample = SensorFusionDataSample()
    var streamingCleanup: [OpaquePointer: () -> Void] = [:]
    private var sensorContextPtr: UnsafeMutableRawPointer?

    // MARK: - Init
    
    init() {}

    // MARK: - Sensor Fusion Start
    
    func startSensorFusion(device: MetaWear) {
            guard let board = device.board else {
                print("Failed to retrieve device or board")
                return
            }

        let sensorContext = SensorContext(manager: self, device: device)
               sensorContextPtr = Unmanaged.passRetained(sensorContext).toOpaque()

        configureSensorFusion(board: board)
        subscribeToSensorSignals(device: device)
        mbl_mw_sensor_fusion_start(board)
    }

    // MARK: - Sensor Fusion Configuration
    
    private func configureSensorFusion(board: OpaquePointer) {
        mbl_mw_sensor_fusion_clear_enabled_mask(board)
        mbl_mw_sensor_fusion_set_mode(board, MBL_MW_SENSOR_FUSION_MODE_NDOF)
        mbl_mw_sensor_fusion_set_acc_range(board, MBL_MW_SENSOR_FUSION_ACC_RANGE_4G)
        mbl_mw_sensor_fusion_set_gyro_range(board, MBL_MW_SENSOR_FUSION_GYRO_RANGE_500DPS)
        mbl_mw_sensor_fusion_write_config(board)
    }
    
    
    // MARK: - Sensor Signal Subscription
    
    func subscribeToSensorSignals(device: MetaWear) {
        guard let board = device.board else { return }
        
        let sensorContext = SensorContext(manager: self, device: device)
        let contextPtr = Unmanaged.passRetained(sensorContext).toOpaque()
        
        let signals = [
            (MBL_MW_SENSOR_FUSION_DATA_QUATERNION, SensorFusionManager.onQuaternionData),
            (MBL_MW_SENSOR_FUSION_DATA_LINEAR_ACC, SensorFusionManager.onLinearAccData),
            (MBL_MW_SENSOR_FUSION_DATA_EULER_ANGLE, SensorFusionManager.onEulerAnglesData),
            (MBL_MW_SENSOR_FUSION_DATA_GRAVITY_VECTOR, SensorFusionManager.onGravityData),
            (MBL_MW_SENSOR_FUSION_DATA_CORRECTED_MAG, SensorFusionManager.onCorrectedMagData),
            (MBL_MW_SENSOR_FUSION_DATA_CORRECTED_GYRO, SensorFusionManager.onCorrectedGyroData),
            (MBL_MW_SENSOR_FUSION_DATA_CORRECTED_ACC, SensorFusionManager.onCorrectedAccData)
         ]

         for (dataType, callback) in signals {
             if let signal = mbl_mw_sensor_fusion_get_data_signal(board, dataType) {
                 mbl_mw_datasignal_subscribe(signal, contextPtr, callback)
                 mbl_mw_sensor_fusion_enable_data(board, dataType)
             }
         }
     }


    
    // MARK: - Static Callback Methods
    
    static let onQuaternionData: MblMwFnData = { (context, dataPointer) in
        guard let context = context, let dataPointer = dataPointer else { return }
        let sensorContext = Unmanaged<SensorContext>.fromOpaque(context).takeUnretainedValue()
        
        let quaternion = dataPointer.pointee.valueAs() as MblMwQuaternion
        
        sensorContext.manager?.processQuaternionData(quaternion, device: sensorContext.device)

    }

    static let onLinearAccData: MblMwFnData = { (context, dataPointer) in
        guard let context = context, let dataPointer = dataPointer else { return }
        let sensorContext = Unmanaged<SensorContext>.fromOpaque(context).takeUnretainedValue()
        guard let manager = sensorContext.manager else { return }
        
        let dataValue = dataPointer.pointee.valueAs() as MblMwCartesianFloat
        manager.processLinearAccData(dataValue)
        if manager.currentFusionDataSample.isComplete() {
            manager.processSensorData()
        }
    }

    static let onGravityData: MblMwFnData = { (context, dataPointer) in
        guard let context = context, let dataPointer = dataPointer else { return }
        let sensorContext = Unmanaged<SensorContext>.fromOpaque(context).takeUnretainedValue()
        guard let manager = sensorContext.manager else { return }
        
        let dataValue = dataPointer.pointee.valueAs() as MblMwCartesianFloat
        manager.processGravityVectorData(dataValue)
        if manager.currentFusionDataSample.isComplete() {
            manager.processSensorData()
        }
    }

    static let onEulerAnglesData: MblMwFnData = { (context, dataPointer) in
        guard let context = context, let dataPointer = dataPointer else { return }
        let sensorContext = Unmanaged<SensorContext>.fromOpaque(context).takeUnretainedValue()
        guard let manager = sensorContext.manager else { return }
        
        let dataValue = dataPointer.pointee.valueAs() as MblMwEulerAngles
        manager.processEulerAnglesData(dataValue)
        if manager.currentFusionDataSample.isComplete() {
            manager.processSensorData()
        }
    }

    static let onCorrectedMagData: MblMwFnData = { (context, dataPointer) in
        guard let context = context, let dataPointer = dataPointer else { return }
        let sensorContext = Unmanaged<SensorContext>.fromOpaque(context).takeUnretainedValue()
        guard let manager = sensorContext.manager else { return }
        
        let dataValue = dataPointer.pointee.valueAs() as MblMwCorrectedCartesianFloat
        manager.processCorrectedMagData(dataValue)
        if manager.currentFusionDataSample.isComplete() {
            manager.processSensorData()
        }
    }

    static let onCorrectedGyroData: MblMwFnData = { (context, dataPointer) in
        guard let context = context, let dataPointer = dataPointer else { return }
        let sensorContext = Unmanaged<SensorContext>.fromOpaque(context).takeUnretainedValue()
        guard let manager = sensorContext.manager else { return }
        
        let dataValue = dataPointer.pointee.valueAs() as MblMwCorrectedCartesianFloat
        manager.processCorrectedGyroData(dataValue)
        if manager.currentFusionDataSample.isComplete() {
            manager.processSensorData()
        }
    }

    static let onCorrectedAccData: MblMwFnData = { (context, dataPointer) in
        guard let context = context, let dataPointer = dataPointer else { return }
        let sensorContext = Unmanaged<SensorContext>.fromOpaque(context).takeUnretainedValue()
        guard let manager = sensorContext.manager else { return }
        
        let dataValue = dataPointer.pointee.valueAs() as MblMwCorrectedCartesianFloat
        manager.processCorrectedAccData(dataValue)
        if manager.currentFusionDataSample.isComplete() {
            manager.processSensorData()
        }
    }

    // MARK: -  Data Processing Methods
    
    func processQuaternionData(_ data: MblMwQuaternion, device: MetaWear) {
        guard let macAddress = device.mac else {
            print("Device MAC address not found")
            return
        }

        guard let deviceInfo = DeviceRegistry.shared.getDeviceInfo(macAddress: macAddress) else {
            print("No device info found for MAC: \(macAddress)")
            return
        }

        currentFusionDataSample.quaternion = data
        let hand = deviceInfo.side
        currentFusionDataSample.hand = hand
        

        let timestampInMilliseconds = Int(Date().timeIntervalSince1970 * 1000)
        if hand == "Right" {
            StatusUpdateManager.shared.metaWearData.lastDataTimestampSensorFusion[1] = timestampInMilliseconds
        } else {
            StatusUpdateManager.shared.metaWearData.lastDataTimestampSensorFusion[2] = timestampInMilliseconds
        }
        

        if currentFusionDataSample.isComplete() {
                
            processSensorData()
        }
    }

    func processLinearAccData(_ data: MblMwCartesianFloat) {
        currentFusionDataSample.linearAcceleration = data
    }
    
    func processGravityVectorData(_ data: MblMwCartesianFloat) {
        currentFusionDataSample.gravity = data
    }

    func processEulerAnglesData(_ data: MblMwEulerAngles) {
        currentFusionDataSample.eulerAngle = data
    }

    func processCorrectedMagData(_ data: MblMwCorrectedCartesianFloat) {

        currentFusionDataSample.correctedMag = data
    }
    
    func processCorrectedGyroData(_ data: MblMwCorrectedCartesianFloat) {
        currentFusionDataSample.correctedGyro = data
    }

    func processCorrectedAccData(_ data: MblMwCorrectedCartesianFloat) {

        currentFusionDataSample.correctedAcc = data
    }

    
    //MARK: PROCESS final
    //TODO: if need to implement the queue mechanism to dont loss the data
    private func processSensorData() {
        if currentFusionDataSample.isComplete() {
            currentFusionDataSample.timestamp = Date().timeIntervalSince1970
            let dataString = currentFusionDataSample.toString()
            dataBuffer.append(dataString)

            if dataBuffer.count == 1000 {
                let dataType = "MF"
                LocationDataManager.shared.fetchLocationAndSaveData(dataType: dataType, dataBuffer: dataBuffer) { success in
                    if success {
                        self.dataBuffer.removeAll()
                    } else {
                        print("Failed to save data. Retrying or keeping data for later.")
                    }
                }
            }
            currentFusionDataSample = SensorFusionDataSample()
        } else {
            print("Incomplete data sample encountered. Waiting for more data...")
        }
    }

    
    
    //MARK: Stop Sensor Fusion
    
    func stopSensorFusion(device: MetaWear) {
        guard let board = device.board else {
            print("Device setup failed or board not found.")
            return
        }

        // Stop sensor fusion on the device
        mbl_mw_sensor_fusion_stop(board)
        mbl_mw_sensor_fusion_clear_enabled_mask(board)

        // Unsubscribe from all active data signals to prevent further data processing
        streamingCleanup.values.forEach { cleanup in cleanup() }
        streamingCleanup.keys.forEach { signal in
            mbl_mw_datasignal_unsubscribe(signal)
        }
        streamingCleanup.removeAll()

        // Release the context safely
        if let context = sensorContextPtr {
            Unmanaged<SensorContext>.fromOpaque(context).release()
            sensorContextPtr = nil
        }

        if !dataBuffer.isEmpty {
            print("Handling remaining data in buffer before clearing...")
            // Process or save data
            // After processing or saving data:
            dataBuffer.removeAll()
        }

        print("Sensor fusion stopped and resources cleaned up for device.")
    }


}

