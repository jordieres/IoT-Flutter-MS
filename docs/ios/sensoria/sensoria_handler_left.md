## SensoriaHandlerLeft.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`SensoriaHandlerLeft.swift` defines a custom handler class for managing connection, scanning, and telemetry for the **left** Sensoria smart textile device. It manages battery level, connection status, and stream forwarding using a shared central buffer and communicates events to Flutter.

---

### Imports

```swift
import Foundation
import CoreBluetooth
import SensoriaiOS
import BoltsSwift
```

- **CoreBluetooth**: Required for low-level BLE device control.
- **SensoriaiOS**: Official SDK for Sensoria sensors.
- **BoltsSwift**: Optional async task management (not actively used here).

---

### Class: SensoriaHandlerLeft

A subclass of `NSObject` conforming to `SADeviceBluetoothDelegate`.

---

### Properties

```swift
var eventSink: FlutterEventSink?
var coreIndex: Int = 2
var lastBatteryLevel: UInt8 = 0
var scanTimer: Timer?
var currentLanguageCode: String = "es"
var sacore: SACore!
var centralBuffer: CentralBufferManager
```

- **eventSink**: Optional callback for streaming connection status or telemetry to Flutter.
- **coreIndex**: Identifies this core as `2`, likely used for Flutter-side mapping.
- **lastBatteryLevel**: Tracks last battery value received.
- **scanTimer**: Cancels scanning if no device is found in time.
- **currentLanguageCode**: Language preference for localization purposes.
- **sacore**: Core BLE interface from the Sensoria SDK.
- **centralBuffer**: Shared instance for batching and uploading data.

---

### Initializer

```swift
init(centralBuffer: CentralBufferManager)
```

- Instantiates a new `SACore` and sets this class as a delegate.
- Enables BLE callbacks and prepares scanning logic.

---

### Method: `updateConnectionStatus(status:)`

- Sends a dictionary of `{ coreIndex, status }` to the Flutter event stream via `EventManager`.

---

### Method: `didBatteryRead(_:)`

- Callback when battery value is received.
- Updates `lastBatteryLevel`.

---

### Method: `getBatteryLevel()`

Returns the most recently cached battery level.

---

### Method: `setLocale(languageCode:)`

Changes the language context for the handler, if relevant for UI updates or logs.

---

### Method: `startScan()`

- Starts BLE scan for left-side device using `sacore.startScan()`.
- Auto-stops after 10 seconds using a `Timer`.

---

### Method: `stopScan()`

Stops the BLE scanning process.

---

### Integration Notes

- This class is highly modular: you can define additional handler classes for the right foot, hand, or other sensors.
- Designed to interface natively with Flutter using `FlutterEventSink`.

