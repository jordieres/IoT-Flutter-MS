import Foundation
import MetaWear
import MetaWearCpp

struct SensorFusionDataSample {
    var quaternion: MblMwQuaternion?
    var eulerAngle: MblMwEulerAngles?
    var linearAcceleration: MblMwCartesianFloat?
    var gravity: MblMwCartesianFloat?
    var correctedMag: MblMwCorrectedCartesianFloat?
    var correctedGyro: MblMwCorrectedCartesianFloat?
    var correctedAcc: MblMwCorrectedCartesianFloat?
    var pressure: Float?
    var altitude: Float?  

    var timestamp: TimeInterval?
    var hand: String?

    func isComplete() -> Bool {
        return quaternion != nil && eulerAngle != nil && linearAcceleration != nil &&
               gravity != nil && correctedMag != nil && correctedGyro != nil &&
               correctedAcc != nil
    }
    
    func toString() -> String {
        guard isComplete() else { return "Incomplete Data" }

        let quaternionString = quaternion.map { "\($0.w), \($0.x), \($0.y), \($0.z)" } ?? "N/A, N/A, N/A, N/A"
        let linearAccelerationString = linearAcceleration.map { "\($0.x), \($0.y), \($0.z)" } ?? "N/A, N/A, N/A"
        let correctedAccString = correctedAcc.map { "\($0.x), \($0.y), \($0.z)" } ?? "N/A, N/A, N/A"
        let gravityString = gravity.map { "\($0.x), \($0.y), \($0.z)" } ?? "N/A, N/A, N/A"
        let correctedGyroString = correctedGyro.map { "\($0.x), \($0.y), \($0.z)" } ?? "N/A, N/A, N/A"
        let correctedMagString = correctedMag.map { "\($0.x), \($0.y), \($0.z)" } ?? "N/A, N/A, N/A"
        let eulerAngleString = eulerAngle.map { "\($0.pitch), \($0.roll), \($0.yaw)" } ?? "N/A, N/A, N/A"
        let altitudeString = altitude.map { String(format: "%.3f", $0) } ?? "N/A"
        let pressureString = pressure.map { String(format: "%.3f", $0) } ?? "N/A"
        let timestampString = timestamp.map { String(format: "%.0f", $0 * 1000) } ?? "N/A"
        let handString = hand ?? "N/A"

        let components = [quaternionString, linearAccelerationString, correctedAccString, gravityString, correctedGyroString, correctedMagString, eulerAngleString, altitudeString, pressureString, timestampString, handString]
        
        return components.joined(separator: ", ")
    }
}




struct AmbientLightData {
    var ambientLight: UInt32
    var timestamp: TimeInterval
    var hand: String

    func toString() -> String {
            let scaledLight = Float(ambientLight) / 1000.0
            let formattedLight = String(format: "%.2f", scaledLight)
        

        let timeStampMilliseconds = Int(round(timestamp * 1000))
        let formattedTimestamp = String(timeStampMilliseconds)
            return "\(formattedLight), \(formattedTimestamp), \(hand)"
        }
}

struct TemperatureData {
    var temperature: Float
    var timestamp: TimeInterval
    var hand: String  

    func toString() -> String {
        let formattedTemperature = String(format: "%.1f", temperature)
        let timeStampMilliseconds = Int(round(timestamp * 1000))
        let formattedTimestamp = String(timeStampMilliseconds)
        return "\(formattedTemperature), \(formattedTimestamp), \(hand)"
    }
}
