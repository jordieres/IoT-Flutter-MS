## SensoriaDataModel.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`SensoriaDataModel.swift` defines the structure of a single data packet received from Sensoria wearable sensors. These data packets contain pressure sensor values and 9-axis IMU readings for each timestamped frame.

---

### Struct: SensorData

```swift
struct SensorData {
    var s0: Int16
    var s1: Int16
    var s2: Int16
    var accX: Float
    var accY: Float
    var accZ: Float
    var magX: Float
    var magY: Float
    var magZ: Float
    var gyroX: Float
    var gyroY: Float
    var gyroZ: Float
    var timestamp: Int
    var footIndicator: String
}
```

---

### Field Breakdown

- **s0, s1, s2**: Raw pressure sensor readings from the wearable insole or sock.
- **accX, accY, accZ**: 3D acceleration vector values (from IMU).
- **magX, magY, magZ**: Magnetometer readings (for orientation and heading).
- **gyroX, gyroY, gyroZ**: Gyroscope data (angular velocity around each axis).
- **timestamp**: Millisecond-based time at which the sample was captured.
- **footIndicator**: Custom label indicating whether the reading is from the left or right foot (e.g., `"Left"`, `"Right"`).

---

### Usage

This structure is used by:
- `SensoriaHandler.swift` for parsing Bluetooth packets.
- File-writing components for exporting logs.
- Visualization tools for foot pressure and gait analysis.

