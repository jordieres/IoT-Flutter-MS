import Foundation
import MetaWear
import MetaWearCpp

class BarometerManager {
    static let shared = BarometerManager()

    private init() {}

    func startBarometer(device: MetaWear) {
        guard let board = device.board else {
            print("Device setup failed or board not found.")
            return
        }

        mbl_mw_baro_bosch_set_oversampling(board, MBL_MW_BARO_BOSCH_OVERSAMPLING_ULTRA_LOW_POWER)
        mbl_mw_baro_bosch_set_iir_filter(board, MBL_MW_BARO_BOSCH_IIR_FILTER_OFF)
        mbl_mw_baro_bosch_set_standby_time(board, 0.5)
        mbl_mw_baro_bosch_write_config(board)

        let context = UnsafeMutableRawPointer(Unmanaged.passRetained(device).toOpaque())

        if let pressureSignal = mbl_mw_baro_bosch_get_pressure_data_signal(board) {
            mbl_mw_datasignal_subscribe(pressureSignal, context, BarometerManager.pressureDataCallback)
        }

        if let altitudeSignal = mbl_mw_baro_bosch_get_altitude_data_signal(board) {
            mbl_mw_datasignal_subscribe(altitudeSignal, context, BarometerManager.altitudeDataCallback)
        }

        mbl_mw_baro_bosch_start(board)
    }

    static let pressureDataCallback: MblMwFnData = { (context, dataPointer) in
        guard let data = dataPointer?.pointee else { return }
        let pressure: Float = data.valueAs()
        SensorFusionManager.shared.currentFusionDataSample.pressure = pressure
//        MetaWearHandler.shared.checkAndProcessFusionData()
    }

    static let altitudeDataCallback: MblMwFnData = { (context, dataPointer) in
        guard let data = dataPointer?.pointee else { return }
        let altitude: Float = data.valueAs()
        SensorFusionManager.shared.currentFusionDataSample.altitude = altitude
//        MetaWearHandler.shared.checkAndProcessFusionData()
    }

    func stopBarometer(device: MetaWear) {
        guard let board = device.board else {
            print("Failed to get barometer data signal or board is not available.")
            return
        }

        if let pressureSignal = mbl_mw_baro_bosch_get_pressure_data_signal(board) {
            mbl_mw_datasignal_unsubscribe(pressureSignal)
        }
        if let altitudeSignal = mbl_mw_baro_bosch_get_altitude_data_signal(board) {
            mbl_mw_datasignal_unsubscribe(altitudeSignal)
        }
        mbl_mw_baro_bosch_stop(board)

        Unmanaged<MetaWear>.passUnretained(device).release() // Release the retained device
    }
}


