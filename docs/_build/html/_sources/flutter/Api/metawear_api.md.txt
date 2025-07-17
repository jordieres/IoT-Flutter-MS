## MetaWearApi.dart

```{contents}
:depth: 2
:local:
```

### Purpose

`MetaWearApi.dart` provides a bridge between the Flutter app and native platform code to manage communication with MetaWear BLE sensors. It handles sensor connections, status streaming, and invokes native methods through Flutter platform channels.

---

### Imports

```dart
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import '../enums/device_connection_status.dart';
```

- BLE communication: `flutter_reactive_ble`
- Location handling: `geolocator`
- Toast messaging: `fluttertoast`
- Permissions: `permission_handler`
- Native communication: `platform channels`
- App-specific status enums

---

### Platform Channels

```dart
static const _platform = MethodChannel('com.example.healthywear/metawear');
static const _connectionStatusChannel = EventChannel('com.example.healthywear/metawear_connection_status');
```

- `MethodChannel`: Used to invoke native functions like `connect`, `vibrate`, `startMonitoring`.
- `EventChannel`: Listens for asynchronous status updates from native code.

---

### Internal State & Callbacks

```dart
static bool _alreadyListening = false;
static String _languageCode = '';
static Function(String, int, DeviceConnectionStatus)? onConnectionStatusChanged;
```

- `_alreadyListening`: Ensures only one listener is attached to the event channel.
- `_languageCode`: Language used for localized communication or feedback.
- `onConnectionStatusChanged`: Callback for BLE connection updates.

---

### Set Connection Listener

```dart
static void setConnectionStatusListener(Function(String, int, DeviceConnectionStatus) callback) {
  onConnectionStatusChanged = callback;
}
```

Assigns a user-defined function to handle connection events, usually in a service or UI layer.

---

### Event Stream Processing

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

- Listens to `EventChannel` for BLE device status.
- Parses device ID, index, and status.
- Calls the assigned listener if available.

---

### Native Method Wrappers

Each method sends a command to the native layer via the platform channel.

#### `connectToDevice`

```dart
await _platform.invokeMethod('connect', {
  'id': id,
  'index': index,
  'languageCode': languageCode,
});
```

Initiates BLE connection on the native side.

---

#### `disconnectFromDevice`

```dart
await _platform.invokeMethod('disconnect', {'id': id});
```

Disconnects from a specific MetaWear device.

---

#### `vibrate`

```dart
await _platform.invokeMethod('vibrate', {
  'id': id,
  'intensity': intensity,
});
```

Triggers a vibration command on the sensor.

---

#### `startMonitoring` and `stopMonitoring`

Used to start or stop telemetry capture or sensor event tracking.

```dart
await _platform.invokeMethod('startMonitoring', {'id': id});
await _platform.invokeMethod('stopMonitoring', {'id': id});
```

---

### Dependencies

This API relies on native method handlers (Android/iOS) for:

- `connect`, `disconnect`, `vibrate`, `startMonitoring`, etc.
- Event broadcasting via `EventChannel`

Also relies on:

- A shared enum `DeviceConnectionStatus`
- Proper permissions for BLE, location, vibration, etc.

