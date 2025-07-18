## FileHandler.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`FileHandler.swift` is a centralized utility class in the iOS native layer that manages file creation, metadata attachment, and compression for sensor data collected by the HealthyWear app.

---

### Design Pattern

This class uses the **Singleton pattern**:

```swift
static let shared = FileHandler()
```

Ensures only one instance exists to handle all file-related tasks across the app.

---

### Core Responsibilities

- Save structured sensor data to local files.
- Attach metadata including location, app version, and device information.
- Compress files into `.gz` format using zlib.
- Manage cleanup (deleting old/uncompressed files).

---

### Key Methods

#### `setIdNumber(_:)` and `setAppVersion(_:)`

Set optional metadata headers such as:
- User/Session identifier
- Application version string

#### `saveDataToFile(...)`

Creates and writes structured sensor data:
- Builds file name using timestamp and `dataType`
- Saves initial JSON metadata
- Appends sensor data from `dataBuffer`
- Compresses `.txt` into `.gz` using `gzipCompressed()`
- Deletes original file

```swift
let fileName = "\(dataType)_\(timestamp).txt"
```

#### `deleteFile(at:)`

Deletes specified file safely:
```swift
try FileManager.default.removeItem(at: url)
```

Used after successful `.gz` compression.

---

### Metadata Construction

Dynamically builds structured headers:

```swift
metadata: [
  ("Id", idNumber),
  ("Type", type),
  ("Structure", structure),
  ("Lat", latitude),
  ("Long", longitude),
  ("AppVersion", appVersion)
]
```

Also uses helper functions:
- `getStructureForDataType(...)`
- `getTypeForDataType(...)`
- `updateMetadataWithDeviceInfo(...)`

---

### Compression Logic

Implemented in a `Data` extension:

```swift
func gzipCompressed() -> Data?
```

- Uses zlib for GZIP compression
- Allocates 4KB buffer and processes in blocks
- Returns compressed `Data?` object

---

### Integration

Used by:
- Sensor streaming handlers (e.g. `MetaWearHandler`, `SensoriaHandler`)
- Data upload services in background

---

### Summary

`FileHandler.swift` handles the full lifecycle of data persistence: from saving and structuring raw telemetry, to safely compressing and cleaning up. It promotes modularity and ensures data is stored in a standard, readable, and transferable format.
