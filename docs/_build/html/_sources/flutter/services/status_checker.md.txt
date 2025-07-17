## StatusChecker.dart

```{contents}
:depth: 2
:local:
```

### Purpose

`StatusChecker.dart` monitors device connection status and data reporting intervals for all sensor types (MetaWear, Sensoria, SmartBand). It also checks battery state and raises notifications when delays or failures are detected.

---

### Dependencies

```dart
import 'package:flutter/services.dart';
import '../enums/device_connection_status.dart';
import '../Api/SmartBandApi.dart';
import 'Uploader.dart';
import 'NotificationHandler.dart';
import '../Api/MetaWearApi.dart';
import '../Api/SensoriaApi.dart';
import 'package:battery_plus/battery_plus.dart';
```

Uses platform channels, BLE APIs, custom logic modules (Uploader, NotificationHandler), and battery info.

---

### Key Fields

#### Platform Channels

```dart
MethodChannel metaWearChannel = MethodChannel('com.example.healthywear/metawear');
MethodChannel sensoriaChannel = MethodChannel('com.example.healthywear/sensoria');
```

Enables communication with native platform code for each device family.

#### Notification Handler

```dart
final notificationHandler = NotificationHandler();
```

Handles user alerts based on connection issues or data delays.

#### Battery Monitoring

```dart
Battery _battery = Battery();
```

Reads the current battery level from the device.

---

### Device Connection Status Maps

```dart
Map<int, DeviceConnectionStatus> metaWearStatuses = {};
Map<int, DeviceConnectionStatus> sensoriaStatuses = {};
Map<int, DeviceConnectionStatus> smartbandstatuse = {};
```

Tracks BLE connection state by device index.

---

### Delay Threshold Configuration

Delay parameters define initial tolerance and expected update intervals for:

- **MetaWear**: SensorFusion, Temperature, AmbientLight, WriteFile, Battery
- **Sensoria**: Motion, Battery, File
- **SmartBand**: HR, BP, SpO2, Steps, Sleep

Each type has its own:
```dart
int Allowed_initialDelayMinutes_*
int Allowed_updateIntervalMinutes_*
```

These values are used to assess if data streams are timely or delayed.

---

### Static Flags and Variables

```dart
static Map<int, DateTime> deviceConnectedTime = {};
static bool isSmartBandConnected = false;
static bool isMetaWearError = false;
```

Used globally to record device states and health metrics.

---

### Responsibilities

- Collect time series connection states.
- Monitor for missed data uploads or sensor failures.
- Notify the user of failures using `NotificationHandler`.
- Interface with native platform code using `MethodChannel`.

---

### Usage

Typically invoked periodically (e.g. in background task) to assess system health and take remedial actions.

This module is tightly integrated with:
- `BackgroundHandling.dart`
- `Uploader.dart`
- `NotificationHandler.dart`

