## SensoriaHandlerRight.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`SensoriaHandlerRight.swift` is a dedicated BLE communication handler for the **right** Sensoria smart device (e.g., smart sock or insole). It mirrors the functionality of `SensoriaHandlerLeft.swift` but is designed specifically to manage the right-foot sensor.

---

### Imports

```swift
import Foundation
import CoreBluetooth
import SensoriaiOS
import BoltsSwift
```

- **Foundation**: Core Swift library for system types and threading.
- **CoreBluetooth**: BLE communication support.
- **SensoriaiOS**: SDK to interface with Sensoria smart garments.
- **BoltsSwift**: For future async task composition (currently unused).

---

### Class: SensoriaHandlerRight

```swift
class SensoriaHandlerRight: NSObject, SADeviceBluetoothDelegate
```

---

### Properties

```swift
var eventSink: FlutterEventSink?
var coreIndex: Int = 1
var lastBatteryLevel: UInt8 = 0
var scanTimer: Timer?
var currentLanguageCode: String = "es"
var sacore: SACore!
var centralBuffer: CentralBufferManager
```

- **eventSink**: Optional channel for streaming device status to the Flutter frontend.
- **coreIndex**: Value `1` identifies this handler as managing the right-side device.
- **lastBatteryLevel**: Tracks the latest battery percentage read from the device.
- **scanTimer**: Auto-cancels scan after a set time (e.g., 20 seconds).
- **currentLanguageCode**: Localization setting.
- **sacore**: BLE device interface from Sensoria SDK.
- **centralBuffer**: Shared buffering system for uploading formatted sensor data.

---

### Initializer

```swift
init(centralBuffer: CentralBufferManager)
```

- Creates an instance of `SACore`, assigns delegate, and initializes buffer handling.
- This design promotes modularity: each handler works independently but shares a central buffer.

---

### Method: `updateConnectionStatus(status:)`

- Sends a dictionary `{ "coreIndex": 1, "status": status }` via the `EventManager` for Flutter to consume.
- Ensures UI updates or telemetry sync.

---

### Method: `didBatteryRead(_)`

```swift
func didBatteryRead(_ batteryValue: UInt8)
```

- Updates internal state and logs the battery level to console.

---

### Method: `getBatteryLevel()`

Returns the last battery value read.

---

### Method: `setLocale(languageCode:)`

Allows switching the language used for this handler’s feedback.

---

### Method: `startScan()`

- Begins Bluetooth scanning for the right-side Sensoria device.
- Uses a scheduled timer (20 seconds) to timeout scan operation.

---

### Notes

- Implementation is symmetrical with `SensoriaHandlerLeft`.
- Use both classes in tandem for dual-device configurations.


