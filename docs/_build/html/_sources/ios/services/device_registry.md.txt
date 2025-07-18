## DeviceRegistry.swift

```{contents}
:depth: 2
:local:
```

### Purpose

The `DeviceRegistry.swift` class acts as a singleton database of connected or known BLE devices (such as MetaWear or Sensoria) on the iOS platform. It provides a centralized structure for registering, accessing, and managing sensor device metadata during runtime.

---

### Key Features

- Maintains a dictionary of `DeviceInfo` objects, indexed by MAC address.
- Provides lookup, filter, and descriptor utilities for sensor devices.
- Implements the Singleton pattern using `static let shared`.

---

### Singleton Design

```swift
static let shared = DeviceRegistry()
private init() {}
```

Ensures a single shared instance of `DeviceRegistry` is used app-wide.

---

### Properties

```swift
public var devices = [String: DeviceInfo]()
```

- Dictionary where keys are MAC addresses.
- Values are `DeviceInfo` instances containing type, name, etc.

---

### Methods

#### Register Device

```swift
func registerDevice(info: DeviceInfo)
```

Adds or updates the `DeviceInfo` in the registry.

#### Remove Device

```swift
func removeDevice(macAddress: String)
```

Deletes the device entry from the registry.

#### Get Device Info

```swift
func getDeviceInfo(macAddress: String) -> DeviceInfo?
```

Returns the stored `DeviceInfo` for a given MAC address.

#### Get Devices by Type

```swift
func getDevices(byType type: DeviceType) -> [DeviceInfo]
```

Returns all `DeviceInfo` objects matching a specified type (`e.g., smart sock`, `motion sensor`, etc).

#### Get Device Type Descriptor

```swift
func getDeviceTypeDescriptor(macAddress: String) -> String?
```

Returns a formatted string describing:
- Device type
- MAC address
- Device name

Example:
```
SmartSock-DeviceMac:A1:B2:C3:D4:E5, SmartSock-DeviceName:Right Sock
```

---

### Integration

Used by:
- Sensor handlers to track BLE device connections.
- Logic in Flutter method/event channels to tag sensor readings or file names.
- Any centralized logic needing metadata about registered sensor devices.

---

### Extensibility

Future improvements could include:
- Timestamp tracking for last connection.
- Persistent storage using `UserDefaults` or `CoreData`.
- Device health or last-seen flags.


