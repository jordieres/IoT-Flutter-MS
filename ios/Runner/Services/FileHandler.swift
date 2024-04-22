import Foundation
import zlib


class FileHandler {
    static let shared = FileHandler()

    private var idNumber: String?
    
    private var appVersion: String?


    private init() {}
    
    func setIdNumber(_ id: String) {

            self.idNumber = id


        }
    
    func setAppVersion(_ appVer: String){
        self.appVersion = appVer
    }

    func saveDataToFile(dataType: String, dataBuffer: [String], latitude: Double, longitude: Double,completion: @escaping (Bool) -> Void) {

        let fileName = "\(dataType)_\(Int(Date().timeIntervalSince1970 * 1000)).txt"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        let compressedFileURL = fileURL.deletingPathExtension().appendingPathExtension("gz")


        do {
            let structure = getStructureForDataType(dataType: dataType)
            let type = getTypeForDataType(dataType: dataType)

            var metadata: [(String, Any)] = [
                ("Id", idNumber ?? ""),
                ("Type", type),
                ("Structure", structure),
                ("Lat", latitude),
                ("Long", longitude),
                ("AppVersion", appVersion ?? "")
            ]

            updateMetadataWithDeviceInfo(dataType: dataType, metadata: &metadata)

            let jsonData = try encodeToJson(metadata: metadata) + "\n"
            try jsonData.write(to: fileURL, atomically: true, encoding: .utf8)

            let dataString = dataBuffer.joined(separator: "\n") + "\n"
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(dataString.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try dataString.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            
            if dataType == "MF" || dataType == "MT" || dataType == "MI" {
                let timestampInMilliseconds = Int(Date().timeIntervalSince1970 * 1000)
                        StatusUpdateManager.shared.metaWearData.lastMetaWearWriteToFileTimestamps = timestampInMilliseconds
            }else{
                let timestampInMilliseconds = Int(Date().timeIntervalSince1970 * 1000)
                StatusUpdateManager.shared.sensoriaData.lastSensoriaWriteToFileTimestamps = timestampInMilliseconds
            }
            
            // Compression step
            // Compression step
                        if compressFile(sourceUrl: fileURL, destinationUrl: compressedFileURL) {
                            deleteFile(at: fileURL)
                            print("Data successfully compressed and original file deleted.")
                            completion(true)
                        } else {
                            print("Failed to compress data.")
                            completion(false)
                        }
           

                    } catch {
                        print("Failed to write data to file: \(error)")
                        completion(false)
                    }
                }
    
    
    

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    

    private func getStructureForDataType(dataType: String) -> [String] {
        switch dataType {
        case "MI":
            return ["Illumination", "TimeStamp", "Hand"]
        case "MT":
            return ["Degree", "TimeStamp", "Hand"]
        case "MF":
            return [
                "QuaterW", "QuaterX", "QuaterY", "QuaterZ",
                "LinearAccelX", "LinearAccelY", "LinearAccelZ",
                "CorrectedAccelX", "CorrectedAccelY", "CorrectedAccelZ",
                "GravityX", "GravityY", "GravityZ",
                "AngVelocityX", "AngVelocityY", "AngVelocityZ",
                "MagFieldX", "MagFieldY", "MagFieldZ",
                "EuAnglesPitch", "EuAnglesRoll", "EuAnglesYaw",
                "Altitude", "Pressure", "TimeStamp", "Hand"
            ]
        case "S":
            return [
                "S0","S1","S2","AccelX", "AccelY", "AccelZ", "MagX", "MagY", "MagZ", "GyroX", "GyroY", "GyroZ", "TimeStamp", "Foot"
            ]
        default:
            return []
        }
    }
    
    
    private func getTypeForDataType(dataType: String) -> String {
        switch dataType {
        case "MI":
            return "Illumination"
        case "MT":
            return "Temperature"
        case "MF":
            return "MetaWear"  // TODO : needs to be changed to "SensorFusion" later
        case "S":
            return "Sensoria"
        default:
            return "Unknown"
        }
    }

    private func updateMetadataWithDeviceInfo(dataType: String, metadata: inout [(String, Any)]) {
        let deviceInfos = DeviceRegistry.shared.devices

        for (_, deviceInfo) in deviceInfos {
            switch dataType {
            case "MI", "MT", "MF":  // Data types for hand devices
                if deviceInfo.type == .handLeft || deviceInfo.type == .handRight {
                    let prefix = deviceInfo.type == .handRight ? "RH" : "LH"
                    metadata.append(("\(prefix)-DeviceMac", deviceInfo.macAddress))
                    metadata.append(("\(prefix)-DeviceName", deviceInfo.name))
                }
            case "S":  // Data type for foot devices
                if deviceInfo.type == .footLeft || deviceInfo.type == .footRight {
                    let prefix = deviceInfo.type == .footRight ? "RF" : "LF"
                    metadata.append(("\(prefix)-DeviceMac", deviceInfo.macAddress))
                    metadata.append(("\(prefix)-DeviceName", deviceInfo.name))
                }
            case "HR", "HB", "HS":  // Data types for band devices
                metadata.append(("Band-DeviceMac", deviceInfo.macAddress))
                metadata.append(("Band-DeviceName", deviceInfo.name))
            default:
                break
            }
        }
    }

    private func encodeToJson(metadata: [(String, Any)]) throws -> String {
        var jsonString = "{"
        for (index, element) in metadata.enumerated() {
            let value: String
            if let array = element.1 as? [String] {
                value = "[\"\(array.joined(separator: "\",\""))\"]"
            } else if let stringValue = element.1 as? String {
                value = "\"\(stringValue)\""
            } else if let numberValue = element.1 as? Double {
                value = "\(numberValue)"
            } else {
                continue
            }

            jsonString += "\"\(element.0)\": \(value)"
            if index < metadata.count - 1 {
                jsonString += ", "
            }
        }
        jsonString += "}"
        return jsonString
    }
    
    private func compressFile(sourceUrl: URL, destinationUrl: URL) -> Bool {
        guard let inputData = try? Data(contentsOf: sourceUrl) else {
            print("Failed to read data from source file.")
            return false
        }

        guard let compressedData = inputData.gzipCompressed() else {
            print("Failed to compress data.")
            return false
        }

        do {
            try compressedData.write(to: destinationUrl)
            print("Data was successfully compressed and saved to \(destinationUrl.path)")
            return true
        } catch {
            print("Failed to write compressed data to file: \(error)")
            return false
        }
    }

    
    
    private func deleteFile(at url: URL) {
            do {
                try FileManager.default.removeItem(at: url)
                print("Original file deleted.")
            } catch {
                print("Error deleting file: \(error)")
            }
        }

    
   
}


extension Data {
    func gzipCompressed() -> Data? {
        guard !isEmpty else { return nil }

        var stream = z_stream()
        var status: Int32

        self.withUnsafeBytes { rawBufferPointer in
            stream.next_in = UnsafeMutablePointer(mutating: rawBufferPointer.bindMemory(to: UInt8.self).baseAddress!)
            stream.avail_in = uInt(count)
        }

        stream.zalloc = nil
        stream.zfree = nil
        stream.opaque = nil
        status = deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, MAX_WBITS + 16, 8, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        
        if status != Z_OK {
            return nil
        }

        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
            deflateEnd(&stream)
        }

        while status == Z_OK {
            stream.next_out = buffer
            stream.avail_out = uInt(bufferSize)
            status = deflate(&stream, Z_FINISH)
            data.append(buffer, count: bufferSize - Int(stream.avail_out))
        }

        return status == Z_STREAM_END ? data : nil
    }
}
