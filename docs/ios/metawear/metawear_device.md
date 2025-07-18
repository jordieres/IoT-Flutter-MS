## MetaWearDevice.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`MetaWearDevice.swift` defines a foundational wrapper class for MetaWear Bluetooth sensor devices. Though minimal in this version, it sets up the base for managing sensor state and board communication.

---

### Imports

```swift
import Foundation
import MetaWear
import MetaWearCpp
```

- **MetaWear / MetaWearCpp**: Libraries used to interact with MetaWear hardware.
- **Foundation**: Standard Swift framework for system types and utilities.

---

### Class: MetaWearDevice

```swift
class MetaWearDevice {
    var board: OpaquePointer?
    var mac: String?
}
```

- **board**: A pointer to the C-level MetaWear device board structure. Used for invoking native functions from MetaWear C++ SDK.
- **mac**: Optional MAC address (e.g., `"D7:AA:32:1C:44:89"`) identifying the device.

This class is typically extended or composed within handlers to initialize, configure, and manage real-time BLE communication with MetaWear wearables.

---

### Future Expansion

In more advanced versions, this class may include:
- Device configuration (sampling rate, filters)
- Event handlers (e.g., motion triggers)
- Start/stop stream commands
- Battery level or connection status tracking


