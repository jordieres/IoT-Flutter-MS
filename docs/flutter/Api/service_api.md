## ServiceApi.dart

```{contents}
:depth: 2
:local:
```

### Purpose

`ServiceApi.dart` provides a platform channel interface to communicate reference ID numbers and app version information to the native Android/iOS layers of the HealthyWear application.

---

### Imports

```dart
import 'package:flutter/services.dart';
import 'dart:async';
```

Used to define and invoke asynchronous method channel communication between Flutter and native code.

---

### Platform Channel Definition

```dart
static const _platform = MethodChannel('com.example.healthywear/service');
```

Defines a method channel with the name `com.example.healthywear/service` used to communicate with the platform-specific code.

---

### Methods

#### `sendIdNumber(String refNumber)`

```dart
static Future<void> sendIdNumber(String refNumber) async {
  try {
    await _platform.invokeMethod('sendIdNumber', {'refNumber': refNumber});
  } on PlatformException catch (e) {
    print("Failed to send Id ref number: '${e.message}'.");
  }
}
```

- Sends a reference number (`refNumber`) to the native layer.
- Catches and logs any errors from the platform side.

#### `sendAppVersion(String appVersion)`

```dart
static Future<void> sendAppVersion(String appVersion) async {
  await _platform.invokeMethod('sendAppVersion', {'appVersion': appVersion});
}
```

- Sends the app version string to the native layer for logging or analytics.
- Does not handle exceptions explicitly here.

---

### Notes

- Native implementations must define methods for `sendIdNumber` and `sendAppVersion` under the given channel.
- Typically used during app initialization or user identification flow.

