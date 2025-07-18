## SensorFusionDataSample.swift

```{contents}
:depth: 2
:local:
```

### Purpose

This file defines data structures for aggregating, formatting, and outputting telemetry from wearable sensors (e.g., MetaWear) in the HealthyWear iOS app. These include sensor fusion output, ambient light, and temperature readings.

---

### Struct: SensorFusionDataSample

```swift
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
}
```

#### Purpose

Holds synchronized motion and environmental data from the MetaWear's onboard IMU, magnetometer, barometer, and fusion processor.

#### Method: `isComplete()`

Returns `true` if all motion and fusion data fields are non-nil:
- Ensures integrity before string serialization.

#### Method: `toString()`

Formats the sensor fusion data as a single CSV row:
- Includes all fields (quaternion, acceleration, gyro, magnetometer, euler, etc.)
- Timestamp is formatted in milliseconds
- Returns `"Incomplete Data"` if required fields are missing

Example Output:
```
0.71, 0.0, 0.0, 0.71, 0.01, 0.2, 9.8, ..., 20250717184500, Right
```

---

### Struct: AmbientLightData

```swift
struct AmbientLightData {
    var ambientLight: UInt32
    var timestamp: TimeInterval
    var hand: String
}
```

#### Method: `toString()`

Converts the ambient light reading to a CSV-compatible format:
- Scales light from raw integer to `lux` using division
- Formats timestamp in milliseconds
- Appends hand descriptor

Example:
```
123.40, 1625483945000, Right
```

---

### Struct: TemperatureData

```swift
struct TemperatureData {
    var temperature: Float
    var timestamp: TimeInterval
    var hand: String  
}
```

#### Method: `toString()`

- Formats temperature to 1 decimal place
- Formats timestamp in milliseconds

Example:
```
36.7, 1625483945000, Right
```

---

### Integration

These structs are typically used:
- In the iOS layer after receiving BLE sensor packets.
- Before writing to disk via `FileHandler.swift`.
- When displaying recent sensor metrics in debugging or UI.


