## CentralBufferManager.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`CentralBufferManager.swift` is responsible for aggregating and managing streaming data received from wearable sensors, and handling the logic for flushing this data to a persistent backend or storage. It is used specifically for buffering data strings before export.

---

### Class: CentralBufferManager

```swift
class CentralBufferManager {
    var dataBuffer: [String] = []
    let bufferLock = DispatchQueue(label: "com.sensoriahandler.bufferLock")

    func addData(data: String)
    private func processBuffer()
    private func sendDataToServer(_ data: [String])
}
```

---

### Properties

- **dataBuffer**: An array of raw string data representing encoded telemetry readings (such as CSV-style lines).
- **bufferLock**: A `DispatchQueue` used to synchronize access to the buffer (though the locking logic is currently commented out).

---

### Method: `addData(data:)`

```swift
func addData(data: String)
```

- Appends a new data string to the `dataBuffer`.
- If the buffer exceeds a certain threshold (currently 1000 entries), it triggers `processBuffer()`.

*Note*: Locking logic using `bufferLock.async` is commented out and could be re-enabled for thread safety.

---

### Method: `processBuffer()`

```swift
private func processBuffer()
```

- Optionally sorts the buffer (sorting is commented out).
- Sends the buffered data to the server using `sendDataToServer(...)`.

---

### Method: `sendDataToServer(_:)`

```swift
private func sendDataToServer(_ data: [String])
```

- Sets a data type (`"S"` likely stands for Sensoria).
- Delegates to `LocationDataManager.shared.fetchLocationAndSaveData(...)`, which presumably attaches GPS metadata before saving.
- Clears the buffer only upon successful transmission.

---

### Integration

`CentralBufferManager` plays a key role in ensuring:
- No data loss during high-frequency sampling.
- Buffered, batch-style transmission for performance and power efficiency.
- Potential location-aware export (if GPS is enabled in `LocationDataManager`).

---

### Suggestions for Improvement

- Re-enable `bufferLock.async` to protect buffer from concurrent modification.
- Parameterize the threshold (currently hardcoded at 1000).
- Optionally add retry logic if the data fails to send multiple times.


