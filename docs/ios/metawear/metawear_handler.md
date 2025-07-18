## MetaWearHandler.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`MetaWearHandler.swift` serves as the central controller for managing MetaWear sensor connections, BLE scanning, data acquisition, and file buffering. It uses the MetaWear SDK to stream motion and environmental data and prepare it for export and visualization in the HealthyWear iOS app.

---

### Key Responsibilities

- Scan for nearby MetaWear devices.
- Connect to multiple boards simultaneously.
- Buffer sensor fusion, temperature, and light data.
- Monitor last-timestamped events.
- Serialize status updates for UI display or diagnostics.
- Coordinate data flushing and cleanup routines.

---

### Design Pattern

```swift
static let shared = MetaWearHandler()
```

Implements the **Singleton** pattern for globally accessible state management of MetaWear operations.

---

### Properties

#### BLE State

- `scannedDevices`: Array of discovered `MetaWear` instances.
- `connectedDevices`: Set of MACs representing connected boards.
- `isScanning` / `isConnecting`: Booleans to track state.
- `deviceRssiMap`: Mapping of RSSI to devices for filtering.
- `connectionQueue`: Integer queue of pending connections.

#### Time Tracking

Timestamps used to evaluate freshness of data for each board:
- `lastDataTimestampSensorFusionBoard1` / `Board2`
- `lastDataTimestampTemperatureBoard1` / `Board2`
- `lastDataTimestampAmbientLightBoard1` / `Board2`
- `lastDataWriteFileTimestamps`: Last time file buffer was flushed.

#### Data Buffers

- `dataBuffer`: Line-buffer for pending data flush.
- `illuminanceBuffer`: Specific to light sensor smoothing.
- `currentFusionDataSample`: Holds the current fusion frame.
- `allSensorData`: Accumulates recent sensor history.

#### Config

- `scanPeriod`: Duration for BLE scanning.
- `bufferCapacity`: Threshold for triggering data export.
- `currentLanguageCode`: Localization fallback.
- `currentHand`: Used for device tagging ("Right", "Left").
- `currentDataType`: Tracks selected sensor stream type.
- `currentDevice`: Currently active `MetaWear` connection.

---

### Methods (Key Functional Blocks)

#### Data Streaming & Parsing

Responsible for subscribing to:
- **Sensor Fusion**: Quaternion, acceleration, gyro, gravity
- **Temperature**: Ambient or internal sensor
- **Ambient Light**: Illuminance values

Each stream updates `currentFusionDataSample` and relevant timestamp.

#### File Handling

- Gathers sensor fusion lines into `dataBuffer`
- Flushes to file every N samples or on demand
- Delegates compression to `FileHandler.swift`

#### Status JSON Export

Method `getStatusMapJson(board:deviceIndex:) -> String` returns a JSON payload for UI or Flutter-side status display:

```json
{
  "lastDataTimestampSensorFusion": 1720493520000,
  "lastDataTimestampTemperature": 1720493520030,
  "lastDataTimestampAmbientLight": 1720493520065,
  "lastDataWriteToTimestamp": 1720493530000
}
```

---

### Summary

`MetaWearHandler.swift` is the orchestrator of all BLE operations for MetaWear devices in HealthyWear. It robustly handles concurrent boards, data buffering, cleanup, and performance logging. It is a core service layer in the native iOS implementation.
