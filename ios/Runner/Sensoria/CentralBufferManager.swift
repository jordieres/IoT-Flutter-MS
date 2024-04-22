class CentralBufferManager {
//    var dataBuffer: [SensorData] = []
    var dataBuffer: [String] = []


    let bufferLock = DispatchQueue(label: "com.sensoriahandler.bufferLock")

    func addData(data: String) {
//        bufferLock.async {
            self.dataBuffer.append(data)
            if self.dataBuffer.count >= 1000 { // Example threshold
                self.processBuffer()
            }
//        }
    }

    private func processBuffer() {
        // Sort data by timestamp if necessary
//        dataBuffer.sort {  $0 < $1 }

        // Process the sorted data
        sendDataToServer(dataBuffer)
//        dataBuffer.removeAll() // Clear buffer after processing
    }

    private func sendDataToServer(_ data: [String]) {
//        print("Sending data to server: \(data)")
        
        let dataType = "S"
        
        LocationDataManager.shared.fetchLocationAndSaveData(dataType: dataType, dataBuffer: self.dataBuffer) { success in
            if success {
                self.dataBuffer.removeAll()
            } else {
                print("Failed to save data. Retrying or keeping data for later.")
            }
        }
    }
    }

