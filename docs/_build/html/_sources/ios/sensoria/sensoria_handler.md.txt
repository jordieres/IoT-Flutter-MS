## SensoriaHandler.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`SensoriaHandler.swift` provides Bluetooth connection management and data handling for Sensoria smart footwear sensors within the HealthyWear iOS system. It connects to Sensoria devices, receives real-time telemetry, buffers the data, and prepares it for storage or transmission.

---

### Imports

```swift
import Foundation
import SensoriaiOS
import BoltsSwift
```

- `SensoriaiOS`: SDK for managing smart textile devices like foot sensors.
- `BoltsSwift`: For potential asynchronous task chaining (not actively used here).
- `Foundation`: Standard Swift utilities.

---

### Class: SensoriaHandler

#### Singleton

```swift
static let shared = SensoriaHandler()
```

Provides a globally accessible instance for device management.

---

### Properties

- **sacores**: Array of two `SACore` instances — each corresponds to one foot (left/right).
- **activeScanningCore**: The currently scanning core.
- **dataBuffer**: Array of formatted sensor strings awaiting upload.
- **maxBufferSize**: Threshold after which the buffer is flushed.
- **bufferQueue**: A `DispatchQueue` used for thread-safe buffer operations.

---

### Initializer

```swift
override init()
```

- Registers the handler as a delegate for both `SACore` instances.
- Ensures real-time callbacks are routed to this class.

---

### Method: `startConnection(deviceIndex:)`

```swift
func startConnection(deviceIndex: Int)
```

- Starts scanning on the corresponding `SACore` (left or right).
- Sets the `activeScanningCore` accordingly.

---

### Method: `didScan(_:)`

Callback triggered when a device is detected.

- Infers device side ("Right" or "Left").
- Registers metadata using `DeviceRegistry`.
- Connects to the detected device.

---

### Method: `didUpdateData()`

Callback when new data is received.

- Constructs a `formattedData` string using all available sensor metrics.
- Appends to `dataBuffer` inside a background queue.
- Flushes the buffer via `processAndClearBuffer()` when full.

---

### Method: `formatData(from:footIndicator:)`

Returns a comma-separated string of:
- Pressure sensors (s0, s1, s2)
- IMU: Accelerometer, Magnetometer, Gyroscope
- Timestamp and foot indicator

```swift
return "\(core.s0),\(core.s1),...(core.timestamp),\(footIndicator)"
```

---

### Method: `processAndClearBuffer()`

Clears the `dataBuffer`. Placeholder for future implementation of upload logic (likely to server or file system).

---

### Method: `didError(_)`

Prints error messages for debugging or telemetry failure.

---

### Summary

`SensoriaHandler.swift` encapsulates BLE device control, data streaming, formatting, and buffering for Sensoria smart socks. It integrates sensor metadata with device identity and prepares structured telemetry for persistent storage or analysis.
