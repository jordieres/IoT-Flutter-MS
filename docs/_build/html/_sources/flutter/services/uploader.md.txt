## Uploader.dart

```{contents}
:depth: 2
:local:
```

### Purpose

`Uploader.dart` manages periodic uploads of sensor data files (`.gz`) to a remote server. It supports configurable upload URLs, runs background uploads on a timer, and manages device storage access across platforms.

---

### Key Imports

```dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

Used for:
- Asynchronous execution and timers
- File I/O
- HTTP file uploads
- Local file system path access
- Configuration and preferences

---

### Configuration

```dart
static Future<void> loadConfig() async {
  final config = await rootBundle.loadString('assets/config.txt');
  serverUrl = config.trim();
}
```

- Loads the server URL from a local asset file (`assets/config.txt`).
- Allows dynamic changes to upload endpoints without recompiling the app.

---

### Upload Scheduler

```dart
static void startMonitoringAndUploading() {
  Timer.periodic(uploadInterval, (Timer t) => startUploading());
}
```

- Starts periodic upload every 60 seconds (`uploadInterval`).
- Calls `startUploading()` automatically on schedule.

---

### File Upload Function

```dart
static Future<void> startUploading() async
```

- Gets the external storage directory (platform-aware).
- Filters `.gz` files.
- Uploads each using `uploadFile()` method.

Example upload logic:
```dart
var request = http.MultipartRequest('POST', Uri.parse(serverUrl));
request.files.add(await http.MultipartFile.fromPath('file', file.path));
await request.send();
```

---

### Upload State

```dart
static DateTime? lastUploadTimestamp;
```

- Records the last successful upload time.
- Could be used for failure tracking or UI status indicators.

---

### Preferences

Preferences could be used for:
- Upload logs
- Retry counts
- User ID or app version tracking

---

### Integration

Used in:
- `BackgroundHandling.dart`: Invokes `Uploader.startUploading()` periodically.
- `StatusChecker.dart`: Can verify file counts or trigger uploads if needed.

---

### Platform Considerations

- Uses `getExternalStorageDirectory()` for Android.
- Handles differences for iOS using platform checks.



