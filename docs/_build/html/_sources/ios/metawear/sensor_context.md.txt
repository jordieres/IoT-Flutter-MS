## SensorContext.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`SensorContext.swift` defines a simple container for managing the relationship between a `MetaWear` sensor device and its corresponding manager. This facilitates coordination between the sensor and control logic within the sensor fusion subsystem of the HealthyWear app.

---

### Imports

```swift
import Foundation
import MetaWear
```

- `Foundation`: Required for class structures and memory management.
- `MetaWear`: Core SDK used for BLE device representation and communication.

---

### Class: SensorContext

```swift
class SensorContext {
    weak var manager: SensorFusionManager?
    var device: MetaWear

    init(manager: SensorFusionManager, device: MetaWear) {
        self.manager = manager
        self.device = device
    }
}
```

#### Properties

- **manager** (`SensorFusionManager?`): A weak reference to the controller managing sensor fusion operations. The weak qualifier avoids retain cycles.
- **device** (`MetaWear`): The BLE-connected wearable device instance.

#### Initializer

The initializer binds the MetaWear device with the SensorFusionManager:
```swift
init(manager: SensorFusionManager, device: MetaWear)
```

---

### Comments on the Commented Block

```swift
// let handler: MetaWearHandler
// let hand: String
```

This appears to be a previously used or alternate design that stored additional metadata (`hand`) and used a broader `MetaWearHandler` instead of a specialized `SensorFusionManager`.

---

### Usage

`SensorContext` objects are expected to be used:
- In sensor lifecycle tracking.
- To associate multiple `MetaWear` devices with their managers.
- During sensor fusion session setup or teardown.


