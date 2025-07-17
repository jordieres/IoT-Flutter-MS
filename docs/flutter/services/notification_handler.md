## NotificationHandler.dart

```{contents}
:depth: 2
:local:
```

### Purpose

`NotificationHandler.dart` manages the logic for issuing notifications in the background. It uses `flutter_local_notifications` to alert the user when data collection intervals exceed expected limits, device behavior is abnormal, or battery status must be checked.

---

### Imports

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'StatusChecker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
```

Used for:
- Local notifications
- File I/O
- Checking system/device status
- Persisting data

---

### NotificationInfo Class

```dart
class NotificationInfo {
  String deviceName;
  int deviceIndex;
  String activityName;
  DateTime lastNotificationTime;
}
```

- Stores information about each device’s last notification.
- Prevents sending duplicate notifications too frequently.

---

### NotificationHandler Class

```dart
class NotificationHandler {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  List<NotificationInfo> sentNotifications;
}
```

- Manages all notifications using Flutter’s notification plugin.
- Maintains a list of previously sent notifications to avoid redundancy.

---

### Notification Intervals

```dart
int notification_IntervalMinutes_MMR_SensorFusion = 20;
int notification_IntervalMinutes_Sensoria = 20;
int notification_IntervalMinutes_SmartBand_HR = 100;
...
```

These intervals define the minimum time (in minutes) before a similar notification can be sent again for each device and metric.

#### Categorized Intervals:
- **MetaWear**: Sensor Fusion, Temperature, Ambient Light, WriteFile, Battery
- **Sensoria**: Motion/Battery/File
- **SmartBand**: Heart Rate, Blood Pressure, Step Count

---

### Functions (Not fully listed in preview but assumed)

- `sendNotification(...)`: Sends an alert to the user.
- `shouldNotify(...)`: Checks whether a notification should be sent based on time elapsed and previous records.
- `saveToFile(...) / loadFromFile(...)`: Manages persistence of sent notifications.
- `initializePlugin()`: Likely sets up the plugin and notification channel.

---

### Usage Context

Used in:
- `BackgroundHandling.dart` as the default notification manager
- BLE service status monitoring and alerts
- Error reporting for data sensors

---

### Notes

This system helps ensure the user is informed about sensor-related issues, like inactivity or battery drain, without being spammed repeatedly.

