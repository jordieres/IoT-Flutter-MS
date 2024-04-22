import Foundation
import MetaWear

class StatusUpdateManager {
    static let shared = StatusUpdateManager()
    
    var metaWearData = StatusUpdateMetaWearData()
    var sensoriaData = StatusUpdatSensoriaData()
    
    
    
    
    func getMetaWearCurrentStatus(deviceIndex: Int) -> String {
        
        let jsonOutput = metaWearData.toJson(deviceIndex: deviceIndex)
        print("JSON Output: \(jsonOutput)")
        
        return jsonOutput
    }
    
    func getSensoriaCurrentStatus(deviceIndex: Int) -> String {
        return sensoriaData.toJson(deviceIndex: deviceIndex)
    }
    
    
    static func serializeToJson(_ statusMap: [String: Any]) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: statusMap, options: [])
            let jsonString = String(data: data, encoding: .utf8) ?? "{}"
                    print("Serialized JSON: \(jsonString)")
            return jsonString
        } catch {
            print("Error serializing status map: \(error)")
            return "{\"error\":\"\(error.localizedDescription)\"}"
        }
    }
    
    
}
    
