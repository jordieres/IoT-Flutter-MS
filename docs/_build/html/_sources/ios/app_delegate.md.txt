## AppDelegate.swift

```{contents}
:depth: 2
:local:
```

### Purpose

The `AppDelegate.swift` file acts as the main entry point for the **HealthyWear iOS app**, responsible for initializing Bluetooth services, connecting native iOS functionality with Flutter using `MethodChannel` and `EventChannel`, and handling system-level behaviors like notifications and background execution.

---

### Key Frameworks Used

```swift
import UIKit
import Flutter
import CoreBluetooth
import MetaWear
import UserNotifications
import workmanager
```

- **UIKit & Flutter**: UI & app lifecycle integration.
- **CoreBluetooth**: Handles BLE device discovery and communication.
- **MetaWear**: Used for wearable sensor API.
- **UserNotifications**: For local push notifications.
- **WorkManager**: Background tasks.

---

### Main Responsibilities

- Sets up Flutter and plugin registration.
- Initializes CoreBluetooth manager.
- Registers MethodChannels and EventChannels.
- Delegates BLE handling to custom classes.
- Handles background restoration of Bluetooth state.
- Requests notification permissions.

---

### BLE Integration

```swift
var centralManager: CBCentralManager?
```

Initializes a central Bluetooth manager and sets the class as its delegate:
```swift
centralManager = CBCentralManager(delegate: self, queue: nil)
```

---

### Flutter Channels

```swift
var sensoriaMethodChannel: FlutterMethodChannel?
var metaWearMethodChannel: FlutterMethodChannel?
var serviceMethodChannel: FlutterMethodChannel?

var metaWearEventChannel: FlutterEventChannel?
var sensoriaEventChannel: FlutterEventChannel?
```

These channels are used for:
- Exchanging BLE sensor data.
- Broadcasting status updates.
- Sending command invocations from Dart.

---

### Sensor Handlers

```swift
var metaWearHandler: MetaWearHandler?
var sensoriaHandler: SensoriaHandler?
var sensoriaHandlerRight: SensoriaHandlerRight?
var sensoriaHandlerLeft: SensoriaHandlerLeft?
```

Handlers for managing individual sensors and communication streams.

---

### Notification Setup

```swift
private func createNotificationChannel()
```

- Requests user permission for notifications.
- Prepares alert and sound-based alerts.
- Handles the result via a closure.

---

### Background BLE Support

```swift
func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any])
```

Ensures restoration of BLE state and reinitializes any pending connections or tasks if needed.

---

### Secondary BluetoothManager Class

```swift
class BluetoothManager: NSObject, CBCentralManagerDelegate
```

Encapsulates background BLE scanning and restoration logic. It provides modular recovery from BLE interruptions and lifecycle resets.

---

### Integration Notes

- `GeneratedPluginRegistrant.register()` integrates all Dart plugins into native runtime.
- BLE and notification functions are cleanly separated from UI logic.
- Sensor handlers like `MetaWearHandler` and `SensoriaHandler` are modular and extensible.

