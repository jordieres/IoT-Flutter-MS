## DeviceInfo.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`DeviceInfo.swift` defines a lightweight data structure used to represent individual sensor devices such as smart socks, smart bands, or MetaWear nodes. It includes an `enum` for device type and a struct that encapsulates identifying details about a device.

---

### Enum: DeviceType

```swift
enum DeviceType: String {
    case handLeft = "LH"
    case handRight = "RH"
    case footLeft = "LF"
    case footRight = "RF"
}
```

Defines a set of known device locations or roles:
- **LH**: Left Hand
- **RH**: Right Hand
- **LF**: Left Foot
- **RF**: Right Foot

These identifiers are used to distinguish devices in multi-sensor setups.

---

### Struct: DeviceInfo

```swift
struct DeviceInfo {
    var type: DeviceType
    var macAddress: String
    var name: String
    var side: String
}
```

Fields:
- **type**: Enumerated type of the device (from `DeviceType`).
- **macAddress**: Unique hardware identifier for the BLE device.
- **name**: Human-readable name (e.g., "Right Sock").
- **side**: Custom side descriptor, e.g., "Left", "Right" (more flexible than enum).

---

### Usage

Used extensively throughout the iOS codebase, particularly by:
- `DeviceRegistry.swift` for registering known devices.
- Sensor handlers to identify which data belongs to which device.
- File naming and metadata during data export.


