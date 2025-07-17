## BackgroundHandling.dart

```{contents}
:depth: 2
:local:
```

### Purpose

This file manages background tasks using the `workmanager` plugin. It schedules, configures, and executes background uploads and notification handling for data collected by the app.

---

### Key Imports

```dart
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
```

- `workmanager`: Schedules background tasks
- `flutter_local_notifications`: Manages Android local notifications
- `shared_preferences`: Stores the current app language
- `path_provider`: Used for file system access

---

### Callback Dispatcher

```dart
void callbackDispatcher()
```

Main entry point for `Workmanager` to execute background jobs. Inside it:

- Initializes local notification plugin
- Creates Android notification channel
- Reads preferred language from shared preferences
- Calls `checkUploadStatus` task handler

```dart
final prefs = await SharedPreferences.getInstance();
String languageCode = prefs.getString('languageCode') ?? 'es';
```

---

### Notification Setup

Creates Android-specific channel for upload notifications:

```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'upload_channel',
  'Data Upload Notifications',
  importance: Importance.high,
);
```

This ensures the OS can show relevant notifications even when the app is inactive.

---

### Integration with Other Services

This file relies on:

- `NotificationHandler.dart`: For managing localized and platform-specific notifications
- `Uploader.dart`: To check and perform data uploads

These services are invoked when `Workmanager` executes the task.

---

### Tasks

```dart
switch (task) {
  case 'checkUploadStatus':
    return await checkUploadStatus(flutterLocalNotificationsPlugin, languageCode);
}
```

The `checkUploadStatus` function is assumed to check whether data needs to be uploaded, trigger an upload, and notify the user.

---

### Platform Notes

- Currently Android-only behavior is implemented.
- iOS implementation would require background fetch via different plugins or native code.

---

### Integration in `main.dart`

Ensure this is included when initializing the app:

```dart
Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
```

