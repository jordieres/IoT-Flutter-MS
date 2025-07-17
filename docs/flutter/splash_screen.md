## splash_screen.dart

```{contents}
:depth: 2
:local:
```

### Purpose

This file defines the `SplashScreen` widget, a simple introductory screen shown during app startup. It retrieves the app version and displays the logo and version text.

---

### Imports

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
```

- **Flutter Core**: UI and layout.
- **Google Fonts**: Custom text styling.
- **Package Info Plus**: Fetches the app version dynamically.

---

### `SplashScreen` Widget

```dart
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}
```

A `StatefulWidget` that holds dynamic UI logic, such as retrieving the version at runtime.

---

### `_SplashScreenState` Class

#### Variables

```dart
String _version = '';
```

Stores the version number fetched from the platform.

---

#### `initState()`

```dart
@override
void initState() {
  super.initState();
  _loadVersion();
}
```

Initializes the widget and calls the method to load the app version.

---

#### `_loadVersion()`

```dart
Future<void> _loadVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  setState(() {
    _version = packageInfo.version;
  });
}
```

Uses `PackageInfo.fromPlatform()` to retrieve the version and updates the UI.

---

#### `build()`

```dart
@override
Widget build(BuildContext context) {
  Size size = MediaQuery.of(context).size;
```

The layout is composed of:

- A column with a logo (`Image.asset`)
- Two `Text` widgets: one for app name and one for version
- Uses `GoogleFonts.roboto` for styling

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Image.asset('assets/logo.png', width: size.width * 0.4),
    Text('HealthyWear', style: GoogleFonts.roboto(...)),
    Text('v$_version', style: GoogleFonts.roboto(...)),
  ],
),
```

Ensure `logo.png` is present in `assets/` and listed in `pubspec.yaml`.

---

### Dependencies

- `assets/logo.png` — image must exist in asset bundle.
- Declared in `pubspec.yaml` under `assets:` section.
