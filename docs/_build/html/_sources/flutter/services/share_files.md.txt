## share_files.dart

```{contents}
:depth: 2
:local:
```

### Purpose

This file implements a Flutter UI screen that allows users to view and share `.gz` compressed data files collected by the HealthyWear app. The feature supports multi-file selection and is localized for both English and Spanish.

---

### Dependencies

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
```

- `path_provider`: Locates app storage directory.
- `share_plus`: Shares files via platform-native interfaces.
- `cross_file`: Converts files to `XFile` format.
- `dart:io`: File access and directory traversal.

---

### ShareFilesPage Widget

```dart
class ShareFilesPage extends StatefulWidget {
  final Locale locale;
}
```

- Accepts a `Locale` to determine language-specific messages.
- Defines a stateful widget to manage file loading and UI interaction.

---

### Internal State

```dart
List<File> _allFiles = [];
Set<File> _selected = {};
bool _selectAll = false;
```

- `_allFiles`: All discovered `.gz` files.
- `_selected`: Set of files selected by the user.
- `_selectAll`: Boolean toggle for selecting all files at once.

---

### Lifecycle

#### `initState()`

```dart
@override
void initState() {
  super.initState();
  _loadFiles();
}
```

Initializes file loading when widget is created.

---

### Load Files

```dart
Future<void> _loadFiles()
```

- Gets platform-specific storage directory.
- Lists and filters `.gz` files.
- Updates UI state accordingly.

---

### Select All

```dart
void _toggleSelectAll(bool? v)
```

Allows user to select or deselect all files with a single tap.

---

### Sharing Functionality

```dart
Future<void> _share() async
```

- Converts selected files to `XFile` instances.
- Uses localized message based on `Locale`.
- Triggers native share dialog.

---

### Example Message

- English: `"Here are my pending data files."`
- Spanish: `"Aquí están mis archivos de datos pendientes."`

---

### UI Considerations

Though not visible in this preview:
- The widget likely includes checkboxes or toggles for file selection.
- A share button triggers `_share()`.
- UI is built to reflect `_allFiles`, `_selected`, and `_selectAll` states.

---

### Platform Notes

- Compatible with Android and iOS.
- Access paths and permission policies should be considered during deployment (especially for Android 10+).

