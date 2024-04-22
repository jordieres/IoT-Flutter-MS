struct StatusUpdateMetaWearData {
        var lastDataTimestampSensorFusion = [Int?](repeating: nil, count: 3)
        var lastDataTimestampTemperature = [Int?](repeating: nil, count: 3)
        var lastDataTimestampAmbientLight = [Int?](repeating: nil, count: 3)
        var lastMetaWearWriteToFileTimestamps: Int?

    func toJson(deviceIndex: Int) -> String {
        print("Generating JSON for deviceIndex: \(deviceIndex)")

        var statusMap: [String: Any] = [
            "lastDataTimestampSensorFusion": lastDataTimestampSensorFusion[deviceIndex] ?? "N/A",
                       "lastDataTimestampTemperature": lastDataTimestampTemperature[deviceIndex] ?? "N/A",
                       "lastDataTimestampAmbientLight": lastDataTimestampAmbientLight[deviceIndex] ?? "N/A",
                       "lastDataWriteToTimestamp": lastMetaWearWriteToFileTimestamps.map(String.init) ?? "N/A"
                   ]
        return StatusUpdateManager.serializeToJson(statusMap)
    }
}



struct StatusUpdatSensoriaData {
    var lastDataTimestampCore = [Int?](repeating: nil, count: 3)
    var lastSensoriaWriteToFileTimestamps: Int?

    
    func toJson(deviceIndex: Int) -> String {
        var statusMap: [String: Any] = [
            "lastDataTimestampSensoriaCore": lastDataTimestampCore[deviceIndex] ?? "N/A",
            "lastDataWriteTimestampSensoria": lastSensoriaWriteToFileTimestamps.map(String.init) ?? "N/A"

        ]
        return StatusUpdateManager.serializeToJson(statusMap)
    }
}








//struct StatusUpdateMetaWearData {
//    
//    var lastDataTimestampAmbientLightDevice1: Int?
//    var lastDataTimestampAmbientLightDevice2: Int?
//    var lastDataTimestampSensorFusionDevice1: Int?
//    var lastDataTimestampSensorFusionDevice2: Int?
//    var lastDataTimestampTemperatureDevice1: Int?
//    var lastDataTimestampTemperatureDevice2: Int?
//    var lastDataWriteFileTimestamps: Int?
//
//    func getStatusJson() -> String {
//        var statusMap: [String: Any] = [
//           
//            "lastDataTimestampSensorFusionDevice1": lastDataTimestampSensorFusionDevice1.map(String.init) ?? "N/A",
//            "lastDataTimestampSensorFusionDevice2": lastDataTimestampSensorFusionDevice2.map(String.init) ?? "N/A",
//            "lastDataTimestampAmbientLightDevice1": lastDataTimestampAmbientLightDevice1.map(String.init) ?? "N/A",
//            "lastDataTimestampAmbientLightDevice2": lastDataTimestampAmbientLightDevice2.map(String.init) ?? "N/A",
//            "lastDataTimestampTemperatureDevice1": lastDataTimestampTemperatureDevice1.map(String.init) ?? "N/A",
//            "lastDataTimestampTemperatureDevice2": lastDataTimestampTemperatureDevice2.map(String.init) ?? "N/A",
//            "lastDataWriteFileTimestamps": lastDataWriteFileTimestamps .map(String.init) ?? "N/A"
//        ]
//        
//        return serializeToJson(statusMap)
//    }
//
//    private func serializeToJson(_ statusMap: [String: Any]) -> String {
//        do {
//            let data = try JSONSerialization.data(withJSONObject: statusMap, options: [])
//            return String(data: data, encoding: .utf8) ?? "{}"
//        } catch {
//            print("Error serializing status map: \(error)")
//            return "{}"
//        }
//    }
//}
//
//
