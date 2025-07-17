## SmartBandApi.dart

```{contents}
:depth: 2
:local:
```

### Purpose

This file manages communication between the Flutter app and smart bands using the `veepoo_sdk`. It controls connection handling, data collection (e.g., heart rate, SpO2, blood pressure), and interaction with native device features.

---

### Imports

```dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:veepoo_sdk/veepoo_sdk.dart';
import 'package:veepoo_sdk/model/search_result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:veepoo_sdk/model/bp_data.dart';
import 'package:veepoo_sdk/model/spo2h_data.dart';
import 'package:veepoo_sdk/model/origin_data.dart';
import 'package:veepoo_sdk/model/origin_v3_data.dart';
import 'package:veepoo_sdk/model/spo2h_origin_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:collection/collection.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../Service/AppLocal.dart';
import '../Service/StatusChecker.dart';
```

- Uses `veepoo_sdk` to interface with smart band hardware.
- Uses `permission_handler`, `geolocator`, `fluttertoast`, and I/O libraries.
- Supports localization and BLE checks.

---

### Band Discovery and Connection

The SDK supports BLE scanning and connection. The following components are involved:

#### BLE Device Scanning

Smart bands are scanned using the `veepoo_sdk` methods.

#### Connect to Band

Connects to a selected smart band using `SearchResult` or a device ID.

---

### Data Collection

Data types supported via the SDK:

- **Heart Rate (HR)**
- **SpO2 (Oxygen Saturation)**
- **Blood Pressure (BP)**
- **Step/Activity Data**
- **Sleep Data**
- **Original Raw Data (v3, SpO2H, etc.)**

SDK models used:

```dart
BpData, Spo2hData, OriginData, OriginV3Data, Spo2hOriginData
```

These classes are parsed and stored using file I/O or memory.

---

### Permissions

```dart
Permission.location
Permission.bluetooth
Permission.storage
```

Proper permissions must be requested and handled before BLE scanning or saving files.

---

### Localization Support

```dart
AppLocal.getText(context, 'some_key')
```

Localization is integrated using custom `AppLocal` service and `flutter_localizations`.

---

### File Storage

Uses `path_provider` and `dart:io` to persist collected data.

```dart
final directory = await getApplicationDocumentsDirectory();
final file = File('${directory.path}/smartband_data.json');
await file.writeAsString(json.encode(data));
```

Collected biometric data can be saved for later upload or analysis.

---

### Dependencies

- `veepoo_sdk`: Core SDK for smart band communication
- `geolocator`, `permission_handler`, `fluttertoast`: for runtime environment setup
- `AppLocal`: For localized UI messages
- Native Bluetooth and BLE permission support

