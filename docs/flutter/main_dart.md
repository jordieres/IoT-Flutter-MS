## main.dart

```{contents}
:depth: 2
:local:
```

### Purpose

`main.dart` is the **entry point** of the Flutter application. It initializes platform services, loads localization, and renders the first widget (`SplashScreen`). It also handles theming and prepares the app to interface with background services and sensor modules.

---

### Imports

```dart
import 'package:flutter/material.dart';
import 'Service/StatusChecker.dart';
import 'Api/SmartBandApi.dart';
import 'Api/MetaWearApi.dart';
import 'Api/SensoriaApi.dart';
import 'Api/ServiceApi.dart';
import 'Service/Uploader.dart';
import 'Service/AppLocal.dart';
import 'Service/NotificationHandler.dart';
import 'Service/BackgroundHandling.dart';
import 'splash_screen.dart';
import 'Service/share_files.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
```

- **Custom Modules**: APIs for wearable sensors and services (Uploader, Notification, etc.)
- **Localization & Fonts**: `intl`, `google_fonts`, `flutter_localizations`
- **Native APIs**: `package_info_plus`, file handling, background tasks

---

### Entry Point

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}
```

- `WidgetsFlutterBinding.ensureInitialized()` is required before calling platform channels or initializing async services.
- `runApp(MyApp())` starts the widget tree with the root `MyApp`.

---

### `MyApp` Widget

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}
```

A `StatefulWidget` is used here to dynamically handle localization and startup logic.

---

### `_MyAppState` Class

Controls the app's internal startup routine, theming, and locale handling.

#### Fields

```dart
Locale? _locale;
bool isReady = false;
```

- `_locale`: stores the user's current locale (used in internationalization).
- `isReady`: flag to delay rendering the main screen until initialization finishes.

---

#### `initState()`

```dart
@override
void initState() {
  super.initState();
  initialize();
}
```

Triggers `initialize()` once the widget is mounted. This prepares localization and preferences.

---

#### `initialize()`

```dart
Future<void> initialize() async {
  await AppLocal.init();
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _locale = AppLocal.getLocaleFromPrefs(prefs);
    isReady = true;
  });
}
```

- Initializes app language system using a helper (`AppLocal`)
- Retrieves `SharedPreferences` for persistent locale
- Once complete, updates the widget state to show the interface

---

#### `build()`

```dart
@override
Widget build(BuildContext context) {
  if (!isReady) {
    return Center(child: CircularProgressIndicator());
  }

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: _locale,
    supportedLocales: AppLocal.supportedLocales,
    localizationsDelegates: [
      AppLocal.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(...),
    home: SplashScreen(),
  );
}
```

- Waits until `isReady` before showing the main interface.
- Configures localization via delegates.
- Loads the first screen (`SplashScreen`) after setting locale.

---

### UI Theming

A `ThemeData` block is applied, likely styled elsewhere. It can include:

- `primaryColor`
- `scaffoldBackgroundColor`
- `textTheme`
- `appBarTheme`

These themes apply globally across the app.

---

### Localization

The app supports multiple locales via:

- `AppLocal` (custom handler)
- `flutter_localizations`
- `intl`

It uses `SharedPreferences` to persist user locale settings across app restarts.

---

### Background Services Initialization

These are imported but not explicitly initialized in `main.dart`:

- `Uploader`: Handles telemetry aggregation
- `StatusChecker`: Checks BLE connectivity
- `BackgroundHandling`: Keeps services alive in background
- `NotificationHandler`: Likely initializes foreground and background push notifications

Initialization might happen elsewhere (e.g., in `SplashScreen`, or background isolates).
