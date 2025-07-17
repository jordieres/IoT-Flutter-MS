## SensoriaApi.dart

```{contents}
:depth: 2
:local:
```

### Purpose

`SensoriaApi.dart` acts as a communication interface between the Flutter app and the native platform layer for Sensoria wearable BLE devices. It manages sensor connection, disconnection, data monitoring, and listens for connection status updates.

---

### Imports

```dart
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import '../enums/device_connection_status.dart';
import 'dart:io';
```

- Platform communication: `flutter/services`
- BLE: `flutter_reactive_ble`
- Location: `geolocator`
- Permissions: `permission_handler`
- App-defined enum: `device_connection_status`

---

### Platform Channels

```dart
static const MethodChannel _platform = MethodChannel('com.example.healthywear/sensoria');
static const _connectionStatusChannel = EventChannel('com.example.healthywear/sensoria_connection_status');
```

- `MethodChannel`: Communicates with native methods.
- `EventChannel`: Receives connection status broadcasts from native side.

---

### Internal State & Callbacks

```dart
static bool _alreadyListening = false;
static String _languageCode = '';
static Function(String, int, DeviceConnectionStatus)? onConnectionStatusChanged;
```

- Tracks if BLE event listener is already attached.
- Stores language code for context-specific messages.
- Holds reference to the event status callback.

---

### Setting the Connection Listener

```dart
static void setConnectionStatusListener(Function(String, int, DeviceConnectionStatus) callback) {
  onConnectionStatusChanged = callback;
}
```

External components can register a callback for connection status updates.

---

### Event Stream Listener

```dart
if (!_alreadyListening) {
  _connectionStatusChannel.receiveBroadcastStream().listen((event) {
    final decoded = json.decode(event);
    final deviceId = decoded['deviceId'];
    final index = decoded['index'];
    final status = DeviceConnectionStatus.values[decoded['status']];
    onConnectionStatusChanged?.call(deviceId, index, status);
  });
  _alreadyListening = true;
}
```

Listens for native broadcast events, parses them, and calls the connection status callback.

---

### Native Method Wrappers

Each method below delegates its work to native code via the `MethodChannel`.

#### `connectToDevice`

```dart
await _platform.invokeMethod('connect', {
  'id': id,
  'index': index,
  'languageCode': languageCode,
});
```

Establishes a BLE connection with the specified Sensoria device.

---

#### `disconnectFromDevice`

```dart
await _platform.invokeMethod('disconnect', {'id': id});
```

Disconnects the BLE connection.

---

#### `vibrate`

```dart
await _platform.invokeMethod('vibrate', {
  'id': id,
  'intensity': intensity,
});
```

Triggers haptic feedback on the device.

---

#### `startMonitoring` and `stopMonitoring`

```dart
await _platform.invokeMethod('startMonitoring', {'id': id});
await _platform.invokeMethod('stopMonitoring', {'id': id});
```

Controls data streaming from the device.

---

### Dependencies

- Native platform implementations for:
  - `connect`, `disconnect`, `vibrate`, `startMonitoring`, `stopMonitoring`
- Correct permissions for Bluetooth, location, and background execution
- `DeviceConnectionStatus` enum for application-wide BLE state tracking

