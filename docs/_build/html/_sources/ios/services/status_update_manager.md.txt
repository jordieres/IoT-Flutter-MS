## StatusUpdateManager.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`StatusUpdateManager.swift` is a centralized singleton manager that tracks and serializes runtime sensor status for MetaWear and Sensoria devices. It serves as a bridge between native sensor handlers and Flutter, helping present real-time device status.

---

### Singleton Pattern

```swift
static let shared = StatusUpdateManager()
```

Used app-wide to access live status data from any part of the iOS native layer.

---

### Key Properties

```swift
var metaWearData = StatusUpdateMetaWearData()
var sensoriaData = StatusUpdatSensoriaData()
```

- `metaWearData`: Holds live status fields for MetaWear devices.
- `sensoriaData`: Same for Sensoria smart garments.

---

### Core Methods

#### `getMetaWearCurrentStatus(deviceIndex:)`

```swift
func getMetaWearCurrentStatus(deviceIndex: Int) -> String
```

- Returns a JSON string representing the device's current runtime state.
- Delegates JSON building to `StatusUpdateMetaWearData`.

#### `getSensoriaCurrentStatus(deviceIndex:)`

```swift
func getSensoriaCurrentStatus(deviceIndex: Int) -> String
```

- Mirrors the MetaWear version for Sensoria garments.

---

### JSON Utility

```swift
static func serializeToJson(_ statusMap: [String: Any]) -> String
```

- Converts a key-value `statusMap` into a well-formed JSON string.
- Logs serialized output for debugging.
- Returns a JSON string or error message if serialization fails.

Example:
```json
{
  "battery": 92,
  "streaming": true,
  "lastUpdate": "2025-07-17T18:00:00Z"
}
```

---

### Integration

- Sensor handlers populate `metaWearData` and `sensoriaData` fields.
- When Flutter queries for status, these methods provide serialized snapshots.
- Ensures real-time visibility and fault tracing for BLE sensors.

---

### Summary

`StatusUpdateManager.swift` encapsulates runtime metadata for each sensor family and exposes it in Flutter-friendly JSON. Its single responsibility and clear interface make it easy to integrate and maintain in cross-platform BLE systems.
