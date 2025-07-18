## StatusUpdateData.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`StatusUpdateData.swift` defines runtime tracking models used by `StatusUpdateManager.swift` to monitor the latest timestamps for data updates from MetaWear and Sensoria sensors in the HealthyWear iOS system.

---

### Struct: StatusUpdateMetaWearData

Tracks timestamps for:
- Sensor Fusion (IMU & orientation)
- Temperature
- Ambient Light
- File write operations

#### Properties

```swift
var lastDataTimestampSensorFusion = [Int?](repeating: nil, count: 3)
var lastDataTimestampTemperature = [Int?](repeating: nil, count: 3)
var lastDataTimestampAmbientLight = [Int?](repeating: nil, count: 3)
var lastMetaWearWriteToFileTimestamps: Int?
```

Each array holds values per device index, supporting up to 3 MetaWear devices in parallel.

#### Method: `toJson(deviceIndex:)`

```swift
func toJson(deviceIndex: Int) -> String
```

- Retrieves the most recent timestamps for the selected device index.
- Returns a JSON string using `StatusUpdateManager.serializeToJson(...)`.

Example Output:
```json
{
  "lastDataTimestampSensorFusion": 1720493520000,
  "lastDataTimestampTemperature": 1720493520030,
  "lastDataTimestampAmbientLight": 1720493520065,
  "lastDataWriteToTimestamp": "1720493530000"
}
```

---

### Struct: StatusUpdatSensoriaData

Tracks:
- Core sensor data timestamp (pressure + IMU)
- File write timestamp

#### Properties

```swift
var lastDataTimestampCore = [Int?](repeating: nil, count: 3)
var lastSensoriaWriteToFileTimestamps: Int?
```

#### Method: `toJson(deviceIndex:)`

Same JSON serialization logic tailored for Sensoria smart garments:
```json
{
  "lastDataTimestampSensoriaCore": 1720493600000,
  "lastDataWriteTimestampSensoria": "1720493610000"
}
```

---

### Integration

These structs are consumed by:
- `StatusUpdateManager` to serialize current device status for Flutter.
- Background logic that validates whether sensors are still transmitting.
- UI widgets that display "last seen" times or connection health.

---

### Summary

`StatusUpdateData.swift` provides essential runtime metadata containers for healthy and timely operation of sensor data logging. It enables observability and robust error recovery in wearable sensor ecosystems.
