## MetaWearHandler.java

```{contents}
:depth: 2
:local:
```

### Purpose

The `MetaWearHandler` class in the Android layer manages communication between the HealthyWear Flutter app and MetaWear BLE sensors. It handles device discovery, connection, sensor initialization, data reading, and file writing.

---

### Responsibilities

- Scans for and connects to MetaWear devices (up to 2 devices simultaneously).
- Initializes sensor fusion (IMU), temperature, and ambient light sensors.
- Collects and processes telemetry.
- Compresses and writes data to `.gz` files.
- Sends real-time updates to Flutter via `EventChannel`.

---

### Key Functionalities

#### 1. **Sensor Management**
- `setupSensors`: Initializes all active sensor modules (IMU, temperature, ambient light).
- `startSensorFusion`, `startTemperature`, `startAmbientLight`: Start individual modules with callbacks.
- `stopAllSensors()`: Graceful cleanup and stopping of streams.

#### 2. **Data Collection**
Each reading is stored in buffer queues and written to file periodically:
```java
Queue<String> bufferSensorFusion;
Queue<String> bufferTemperature;
Queue<String> bufferAmbientLight;
```

#### 3. **File Handling**
- Data is compressed using `GZIPOutputStream`.
- Stored using dynamic filenames based on timestamps and device.

#### 4. **Bluetooth Communication**
- Uses Android BLE APIs to scan for `MetaWear` devices.
- Maintains a list of bonded devices.
- Maps device index to status and connection flags.

#### 5. **Status Mapping**
```java
public String getSensorStatus(int deviceIndex)
```
- Returns sensor status as a JSON string.
- Indicates connection, latest reading timestamps, and write-time.

---

### Integration

- Interfaced with Flutter through `MethodChannel` and `EventChannel`.
- Used in `MainActivity.java` for initializing and managing BLE sensor logic.
- Designed to work concurrently with another handler for multi-device support.

---

### Best Practices

- Separates scan logic and sensor management cleanly.
- Ensures decoupled queues per device and sensor.
- Buffered I/O reduces write frequency to storage, improving performance.

---

### Dependencies

- Android BLE
- MetaWear SDK
- Gson for JSON formatting
- Java utility classes for Queues and file management

---

### Additional Notes

- Timestamps for each type of sensor are maintained individually for better diagnostics.
- Code includes checks for `board.isConnected()` to ensure communication reliability.
- Sensor fusion data is time-synchronized across multiple sensors.

