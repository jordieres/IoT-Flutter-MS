import 'package:flutter/material.dart';
import 'Service/StatusChecker.dart';
import 'Api/SmartBandApi.dart';
import 'Api/MetaWearApi.dart';
import 'Api/SensoriaApi.dart';
import 'Api/ServiceApi.dart';
import 'Service/Uploader.dart';
import 'Service/AppLocal.dart';
import 'Service/NotificationHandler.dart';
import 'dart:async';
import 'Service/BackgroundHandling.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'splash_screen.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'Service/share_files.dart';

import 'dart:ui'; //to use ImageFilter.
import 'package:google_fonts/google_fonts.dart';

import 'dart:math';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:shared_preferences/shared_preferences.dart';
// import 'package:package_info/package_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'enums/device_connection_status.dart';

int getChkSum(String strData) {
  int chksum = 0;
  chksum = chksum ^ int.parse("20", radix: 16);
  chksum = chksum ^ int.parse("03", radix: 16);
  for (int i = 0; i < strData.length; i++) {
    chksum = chksum ^ strData.codeUnitAt(i);
  }
  chksum = chksum ^ int.parse("04", radix: 16);
  return chksum;
}

class DeviceStatus {
  String deviceName;
  DeviceConnectionStatus connectionStatus;

  DeviceStatus({required this.deviceName, required this.connectionStatus});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  String languageCode = prefs.getString('languageCode') ?? 'es';

  Locale initialLocale = Locale(languageCode);

  runApp(SplashApp(initialLocale: initialLocale));

  initializeBackgroundTask(); //Backgroundhandling processes

  //to send the app version for the metadata
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String appVersion = packageInfo.version;
  SmartBandApi.setAppVersion(appVersion);
  MetaWearApi.sendAppVersion(appVersion);
  SensoriaApi.sendAppVersion(appVersion);
  ServiceApi.sendAppVersion(appVersion);

  //  update each API with the correct language code
  SmartBandApi.setLocale(languageCode);
  MetaWearApi.setLocale(languageCode);
  SensoriaApi.setLocale(languageCode);
  NotificationHandler.setLocale(languageCode);

  /////status checker/////////
  StatusChecker statusChecker = StatusChecker();
  MetaWearApi.setConnectionStatusListener(statusChecker.onConnectionStatusUpdate);
  SensoriaApi.setConnectionStatusListener(statusChecker.onConnectionStatusUpdate);
  /////////////

  Uploader.startMonitoringAndUploading();
}

class SplashApp extends StatelessWidget {
  final Locale initialLocale;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  SplashApp({required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) {
        // Using a Builder to get the correct context
        Future.delayed(Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Pop current page if possible
          }
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => MyApp(initialLocale: initialLocale)));
        });
        return SplashScreen();
      }),
    );
  }
}

Future<void> requestPermissions(BuildContext context) async {
  if (Platform.isAndroid) {
    // Check and request location permission
    var locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      await showLocationPermissionDisclosure(context);
    }

    // Check and request storage permission
    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }

    // Check and request notification permission/
    var notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      await Permission.notification.request();
    }

    // Check and request Bluetooth permissions
    var bluetoothStatus = await Permission.bluetooth.status;
    if (!bluetoothStatus.isGranted) {
      await Permission.bluetooth.request();
    }

    var bluetoothScanStatus = await Permission.bluetoothScan.status;
    if (!bluetoothScanStatus.isGranted) {
      await Permission.bluetoothScan.request();
    }

    var bluetoothConnectStatus = await Permission.bluetoothConnect.status;
    if (!bluetoothConnectStatus.isGranted) {
      await Permission.bluetoothConnect.request();
    }

    var bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise.status;
    if (!bluetoothAdvertiseStatus.isGranted) {
      await Permission.bluetoothAdvertise.request();
    }
  }
}

Future<void> showLocationPermissionDisclosure(BuildContext context) async {
  Completer<void> completer = Completer<void>();

  showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap a button to dismiss the dialog
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Se necesitan permisos'),
        content: Text(
            'Esta aplicación necesita acceder a su ubicación para mejorar la precisión de los datos de salud recopilados por los dispositivos portátiles. ¿Está de acuerdo con esto??'),
        actions: <Widget>[
          TextButton(
            child: Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(); // Complete the completer when user cancels
            },
          ),
          TextButton(
            child: Text('Sí'),
            onPressed: () async {
              Navigator.of(context).pop();
              var status = await Permission.location.request();
              if (status.isGranted) {
                // Handle the granted scenario
              } else {
                // Handle the denied scenario
              }
              completer
                  .complete(); // Complete the completer when user confirms and permission is processed
            },
          ),
        ],
      );
    },
  );

  return completer.future; // This will make sure the code waits until the completer is completed
}

Future<void> requestLocationPermission(BuildContext context) async {
  var status = await Permission.location.request();
  if (status.isGranted) {
    // Proceed with location-based functionality
  } else {
    // Handle permission denial
  }
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;
  MyApp({required this.initialLocale});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;
  // Locale _locale = Locale('es', 'ES');

  bool isBandToggled = false;
  bool isRightHandToggled = false;
  bool isLeftHandToggled = false;
  bool isRightFootToggled = false;
  bool isLeftFootToggled = false;

  int? batteryLevelRH = null;
  int? batteryLevelLH = null;
  int? batteryLevelRF = null;
  int? batteryLevelLF = null;
  int? batteryLevelSB = null;

  Map<String, DeviceConnectionStatus> deviceStatuses = {
    'SB': DeviceConnectionStatus.disconnected,
    'RH': DeviceConnectionStatus.disconnected,
    'LH': DeviceConnectionStatus.disconnected,
    'RF': DeviceConnectionStatus.disconnected,
    'LF': DeviceConnectionStatus.disconnected,
  };

  Timer? _idInputTimer; //timer for idnumber

  DeviceConnectionStatus connectionStatus = DeviceConnectionStatus.disconnected;

  final TextEditingController _idController = TextEditingController();
  bool _isIdEditable = true; // to enable or disable the input field
  final TextEditingController _checksumController = TextEditingController();
  bool _isIdCorrect = true; //  variable to track if entered checksum is correct
  bool _devicesEnabled = false; // variable to enable/disable the devices access(lock)

// metawear Devices
  Set<String> _connectedDevices = Set<String>();

  // metawear Devices
  Set<String> _sensoriaconnectedDevices = Set<String>();

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;

    Uploader.loadConfig(); //load config file which include the url

    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestPermissions(context);
    });

/////loader of IdNumber/////todo:if we want to activitate the mechanism to save the idnumber
    // _loadIdNumber().then((_) {
    //   // after loading, if the text field is empty, allow editing.//
    //   if (_idController.text.isEmpty) {
    //     setState(() => _isIdEditable = true);
    //   }
    // });
    // _isIdEditable = false;
/////////////////////////////////////////////////////
    _isIdEditable = true;

    SmartBandApi.onConnectionStatusChange = (status) {
      _updateDeviceStatus('SB', status);
    };

    MetaWearApi.onRightHandConnectionStatusChange = (status) {
      _updateDeviceStatus('RH', status);
    };
    MetaWearApi.onLeftHandConnectionStatusChange = (status) {
      _updateDeviceStatus('LH', status);
    };

    SensoriaApi.onRightFootConnectionStatusChange = (status) {
      _updateDeviceStatus('RF', status);
    };
    SensoriaApi.onLeftFootConnectionStatusChange = (status) {
      _updateDeviceStatus('LF', status);
    };
  }

  void _updateDeviceStatus(String deviceName, DeviceConnectionStatus status) {
    setState(() {
      deviceStatuses[deviceName] = status;
      // update switch state based on connection status
      switch (deviceName) {
        case 'SB':
          isBandToggled = status != DeviceConnectionStatus.disconnected;
          if (status == DeviceConnectionStatus.connected) {
            fetchAndUpdateBatteryLevel(deviceName, 0); // fetch immediately upon connection
          } else {
            // stop battery level updates when disconnected
            stopBatteryLevelUpdates(deviceName);
          }
          break;
        case 'RH':
          isRightHandToggled = status != DeviceConnectionStatus.disconnected;
          if (status == DeviceConnectionStatus.connected) {
            // start battery level updates for the right hand device
            fetchAndUpdateBatteryLevel(deviceName, 1);
          } else {
            // stop battery level updates when disconnected
            stopBatteryLevelUpdates(deviceName);
          }
          break;
        case 'LH':
          isLeftHandToggled = status != DeviceConnectionStatus.disconnected;
          if (status == DeviceConnectionStatus.connected) {
            fetchAndUpdateBatteryLevel(deviceName, 2);
          } else {
            stopBatteryLevelUpdates(deviceName);
          }
          break;
        case 'RF':
          isRightFootToggled = status != DeviceConnectionStatus.disconnected;
          if (status == DeviceConnectionStatus.connected) {
            fetchAndUpdateBatteryLevel(deviceName, 1);
          } else {
            stopBatteryLevelUpdates(deviceName);
          }
          break;
        case 'LF':
          isLeftFootToggled = status != DeviceConnectionStatus.disconnected;
          if (status == DeviceConnectionStatus.connected) {
            fetchAndUpdateBatteryLevel(deviceName, 2);
          } else {
            stopBatteryLevelUpdates(deviceName);
          }
          break;
      }
    });

    if (_areAllDevicesDisconnected()) {
      _startOrRestartDisconnectTimer();
    } else {
      // If any device is connected, it ensures the timer is cancelled
      _cancelDisconnectTimer();
    }
  }

  Map<String, Timer> batteryUpdateTimers = {};

  void fetchAndUpdateBatteryLevel(String deviceName, int deviceIndex) async {
    int? batteryLevel;

    if (deviceName == 'SB') {
      batteryLevel = await SmartBandApi.getBatteryLevel();
    } else if (deviceName == 'RH' || deviceName == 'LH') {
      batteryLevel = await MetaWearApi.getBatteryLevelForDevice(deviceIndex);
    } else {
      batteryLevel = await SensoriaApi.getBatteryLevelForDevice(deviceIndex);
    }

    setState(() {
      switch (deviceName) {
        case 'SB':
          batteryLevelSB = batteryLevel;
          break;
        case 'RH':
          batteryLevelRH = batteryLevel;
          break;
        case 'LH':
          batteryLevelLH = batteryLevel;
          break;
        case 'RF':
          batteryLevelRF = batteryLevel;
          break;
        case 'LF':
          batteryLevelLF = batteryLevel;
          break;
      }
    });
  }

  void stopBatteryLevelUpdates(String deviceName) {
    batteryUpdateTimers[deviceName]?.cancel();
  }

  void setLocale(Locale newLocale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);

    String check = prefs.getString('languageCode') ?? 'default';
    if (mounted) {
      setState(() {
        _locale = newLocale;
      });
      MetaWearApi.setLocale(newLocale.languageCode);
      SensoriaApi.setLocale(newLocale.languageCode);
      SmartBandApi.setLocale(newLocale.languageCode);
      NotificationHandler.setLocale(newLocale.languageCode);
    }
  }

  @override
  void dispose() {
    MetaWearApi.disposeTimers();
    _idInputTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: AppBar(
          title: Align(
            alignment: Alignment.centerLeft, // Aligns the container to the left
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              height: 45,
              child: Image.asset('assets/images/SaludMadrid_logo.png', fit: BoxFit.scaleDown),
            ),
          ),
          backgroundColor: Colors.white,
          actions: [
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade700.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.only(right: 10),
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.red.shade400, // Sets dropdown background color

                  popupMenuTheme: PopupMenuThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15.0), // Rounded corners for dropdown menu
                    ),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    icon: Container(), // Removes the dropdown icon
                    items: <String>['en', 'es'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.toUpperCase(), style: TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setLocale(Locale(newValue));
                      }
                    },
                    value: _locale.languageCode,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ——— Share button row ———
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                  child: Row(
                    children: [
                      Spacer(), // pushes the button to the right
                      IconButton(
                        icon: Icon(Icons.share, color: Colors.blue),
                        tooltip: _locale.languageCode == 'en'
                            ? 'Manage pending files'
                            : 'Gestionar archivos pendientes',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ShareFilesPage(locale: _locale)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10), // Match container's border radius
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0), //  blur radius
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600
                                .withOpacity(0.8), // Set the container's background color to blue
                            borderRadius:
                                BorderRadius.circular(10), // Round the corners of the container
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5), // Shadow color
                                spreadRadius: 2,
                                blurRadius: 7,
                                offset: Offset(0, 3), // Position of shadow
                              ),
                            ],
                          ),
                          padding:
                              EdgeInsets.all(12), // padding inside the container for aesthetics
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              // ID Number TextField with explicit size for 12 uppercase characters
                              Container(
                                width: MediaQuery.of(context).size.width *
                                    0.5, // Adjust based on your UI needs
                                child: TextField(
                                  controller: _idController,
                                  readOnly: !_isIdEditable,
                                  style: TextStyle(color: Colors.white), // Text color
                                  decoration: InputDecoration(
                                    labelText:
                                        _locale.languageCode == 'en' ? 'Reference ' : 'Referencia',
                                    labelStyle: TextStyle(color: Colors.white),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  maxLength: 12,
                                  onChanged: (value) {
                                    // force uppercase and limit input length
                                    _idController.value = TextEditingValue(
                                      text: value.toUpperCase().substring(0, min(value.length, 12)),
                                      selection: TextSelection.fromPosition(
                                        TextPosition(offset: min(value.length, 12)),
                                      ),
                                    );
                                    setState(() {
                                      _isIdCorrect = true;
                                    });
                                  },
                                  buildCounter: (BuildContext context,
                                          {required int currentLength,
                                          int? maxLength,
                                          required bool isFocused}) =>
                                      null,
                                  autocorrect: false,
                                  textCapitalization: TextCapitalization.characters,
                                ),
                              ),
                              SizedBox(width: 5),
                              Text('-',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: Colors.white)), // Hyphen "-"
                              // Hyphen"-"
                              // checksum Textfield with explicit size for 3 digits
                              SizedBox(width: 5),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.15,
                                child: TextField(
                                  controller: _checksumController,
                                  readOnly: !_isIdEditable,
                                  style: TextStyle(color: Colors.white), // Text color

                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white)),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 3,
                                  buildCounter: (BuildContext context,
                                          {required int currentLength,
                                          int? maxLength,
                                          required bool isFocused}) =>
                                      null,
                                ),
                              ),
                              IconButton(
                                icon: _isIdEditable
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 30,
                                        shadows: [
                                          // Adding a shadow to make it appear "bolder"
                                          Shadow(
                                            blurRadius: 3.0,
                                            color: Colors.black,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      )
                                    : Icon(
                                        Icons.edit,
                                        color: Colors.grey.shade300,
                                        size: 30,
                                        shadows: [
                                          // Adding a shadow to make it appear "bolder"
                                          Shadow(
                                            blurRadius: 3.0,
                                            color: Colors.black,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                onPressed: _handleCheckOrEdit,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                if (!_isIdCorrect)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      _locale.languageCode == 'en'
                          ? 'The Reference number is not correct, please contact your doctor.'
                          : 'La referencia no es correcta. Por favor verfiquela o contacte al neurólogo',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  height: 20,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10), //  container's border radius
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), //  blur radius
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // Adjust opacity
                        borderRadius:
                            BorderRadius.circular(10), // Round the corners of the container
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5), // Shadow color
                            spreadRadius: 2,
                            blurRadius: 7,
                            offset: Offset(0, 3), // Position of shadow
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDeviceBox(
                                _locale.languageCode == 'en' ? 'Left MMR' : 'MMR izdo',
                                "LH",
                                () => _handleDeviceTap('LH'),
                                batteryLevelLH,
                              ),
                              _buildDeviceBox(
                                _locale.languageCode == 'en' ? 'Right MMR' : 'MMR dcho',
                                "RH",
                                () => _handleDeviceTap('RH'),
                                batteryLevelRH,
                              ),
                            ],
                          ),
                          SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDeviceBox(
                                _locale.languageCode == 'en' ? 'Left Sock' : 'Calcetín izdo',
                                "LF",
                                () => _handleDeviceTap('LF'),
                                batteryLevelLF,
                              ),
                              // SizedBox(width: 2),
                              _buildDeviceBox(
                                _locale.languageCode == 'en' ? ' Right Sock' : 'Calcetín dcho',
                                "RF",
                                () => _handleDeviceTap('RF'),
                                batteryLevelRF,
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          if (Platform
                              .isAndroid) ///////////////Becasue the App stoer doesnt accept the smartband
                            _buildDeviceBox(
                              _locale.languageCode == 'en' ? 'Smart Band' : 'Pulsera Inteligente',
                              "SB",
                              () => _handleDeviceTap('SB'),
                              batteryLevelSB,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        /////////////////////////////////////////////////////////////////////////////////
        ///////  Adding Floating Action Buttons for Test and History
        floatingActionButton: Stack(
          children: [
            // History FAB (unchanged)
            Positioned(
              left: 40,
              bottom: 15,
              child: Opacity(
                opacity: _devicesEnabled ? 1.0 : 0.5,
                child: FloatingActionButton(
                  heroTag: 'history',
                  backgroundColor: _devicesEnabled ? Colors.blueAccent : Colors.grey,
                  onPressed: _devicesEnabled ? _openTestHistory : null,
                  child: _devicesEnabled
                      ? Icon(Icons.history)
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.history, color: Colors.white54),
                            Icon(Icons.lock, color: Colors.red, size: 24),
                          ],
                        ),
                ),
              ),
            ),

            Positioned(
              right: 16,
              bottom: 15,
              child: Opacity(
                // fade it when disconnected:
                opacity: _isSensoriaConnected() ? 1.0 : 0.2,
                child: FloatingActionButton(
                  heroTag: 'test',
                  backgroundColor: Colors.blue,
                  // disable the tap when disconnected:
                  onPressed: _isSensoriaConnected() ? _openTestSelectionSheet : null,
                  child: Icon(Icons.fitness_center),
                ),
              ),
            ),
          ],
        ),

        backgroundColor: Colors.white,
      ),
    );
  }

  ////////////////////////////////////////////////////////////////////////////////
  ///// functions for Test & History functionality

  bool _isSensoriaConnected() {
    return (deviceStatuses['RF'] == DeviceConnectionStatus.connected ||
        deviceStatuses['LF'] == DeviceConnectionStatus.connected);
  }

  // Function to open Test History page.
  void _openTestHistory() {
    final codeID = "${_idController.text.trim()}-${_checksumController.text.trim()}";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestHistoryPage(codeID: codeID, locale: _locale),
      ),
    );
  }

  /////
  /// Somewhere at the top of your file:
  final _availableTests = [
    {
      'value_en': 'Timed Up & Go Test',
      'value_es': 'Prueba de Timed Up & Go',
      'display_en': 'Timed Up & Go',
      'display_es': 'Timed Up & Go',
    },
    {
      'value_en': 'Two Minutes Walking Test',
      'value_es': 'Prueba de Marcha de 2 Minutos',
      'display_en': 'Two Minutes Walking',
      'display_es': 'Marcha de 2 Minutos',
    },
    {
      'value_en': 'Timed 25-Foot Walk Test',
      'value_es': 'Marcha de 25 Pies Cronometrada',
      'display_en': '25‑Foot Walk',
      'display_es': 'Marcha 25 Pies',
    },
    {
      'value_en': 'Six Minute Walking Test',
      'value_es': 'Prueba de Marcha de 6 Minutos',
      'display_en': 'Six Minute Walk',
      'display_es': 'Marcha 6 Minutos',
    },
  ];
  // Function to open bottom sheet for test selection.
  void _openTestSelectionSheet() async {
    final lang = _locale.languageCode;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang == 'en' ? 'Select a Test' : 'Seleccionar Prueba',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              ..._availableTests.map((t) {
                final display = lang == 'en' ? t['display_en']! : t['display_es']!;
                final value = lang == 'en' ? t['value_en']! : t['value_es']!;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      minimumSize: Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(display, style: TextStyle(fontSize: 18, color: Colors.white)),
                    onPressed: () => Navigator.pop(context, value),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );

    if (selected != null) _startTest(selected);
  }

  ////// Function to start a test by recording start time and opening TestInProgressScreen.
  void _startTest(String testType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => TestInstructionScreen(
          locale: _locale,
          testType: testType,
          onStart: () {
            // when “Start Test” tapped → go to in‐progress
            DateTime start = DateTime.now();
            Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TestInProgressScreen(
                  locale: _locale,
                  testType: testType,
                  startTime: start,
                  onEndTest: (end) {
                    _sendTestInfoToEndpoint(testType, start, end);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  //////////////// Function to send the test information to the endpoint.
  Future<void> _sendTestInfoToEndpoint(
      String testType, DateTime startTime, DateTime endTime) async {
    ///// mapping from full name → short code
    const testNameMap = {
      'Timed Up & Go Test': 'TUG',
      'Prueba de Timed Up & Go': 'TUG',
      'Two Minutes Walking Test': '2MWT',
      'Prueba de Marcha de 2 Minutos': '2MWT',
      'Timed 25-Foot Walk Test': 'T25FW',
      'Marcha de 25 Pies Cronometrada': 'T25FW',
      'Six Minute Walking Test': '6MWT',
      'Prueba de Marcha de 6 Minutos': '6MWT',
    };

    final abbreviatedTest =
        testNameMap[testType] ?? (testType.length > 10 ? testType.substring(0, 10) : testType);

    final payload = {
      'codeid': "${_idController.text.trim()}-${_checksumController.text.trim()}",
      'test': abbreviatedTest,
      'datetime_from': startTime.toIso8601String(),
      'datetime_until': endTime.toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('http://138.100.82.181/AppCognit/eventoHW'),
        body: payload,
      );
      if (response.statusCode == 200) {
        print('Test info sent successfully. Server says: ${response.body}');
      } else {
        print('Failed to send test info. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending test info: $e');
    }
  }

  ////////////////////////////////////////////////////////////////////////////////

  Widget _buildDeviceBox(String title, String deviceName, Function onTap, int? batteryLevel) {
    DeviceConnectionStatus status =
        deviceStatuses[deviceName] ?? DeviceConnectionStatus.disconnected;

    String statusMessage = getConnectionStatusMessage(status, _locale);

    List<Widget> widgetList = [
      Text(title),
      Text(
        // status.toString().split('.').last,
        statusMessage,
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
    ];

    IconData? batteryIcon;
    Color iconColor = Colors.green[800]!;

    if (batteryLevel != null) {
      if (batteryLevel >= 75 || batteryLevel == 4) {
        batteryIcon = Icons.battery_full_rounded;
      } else if (batteryLevel >= 50 || batteryLevel == 3) {
        batteryIcon = Icons.battery_5_bar_rounded;
      } else if (batteryLevel >= 25 || batteryLevel == 2) {
        batteryIcon = Icons.battery_3_bar_rounded;
      } else if (batteryLevel > 0 || batteryLevel == 1) {
        batteryIcon = Icons.battery_1_bar_rounded;
        iconColor = Colors.red; // Change color to red for low battery
      } else {
        batteryIcon = Icons.battery_unknown;
      }

      widgetList.add(Icon(batteryIcon, color: Colors.green[800]));
      widgetList.add(Text("$batteryLevel%"));
    }

    double boxWidth = MediaQuery.of(context).size.width / 2 - 15;

    if (deviceName == "SB") {
      boxWidth = MediaQuery.of(context).size.width - 20;
    }

    // Adjusting blur effect and background color based on connection status
    double blurSigma = status == DeviceConnectionStatus.connected ? 0 : 5;
    Color boxColor = status == DeviceConnectionStatus.connected
        ? Colors.green.withOpacity(0.3)
        : Colors.blue.shade700.withOpacity(0.1);
    Color titleColor =
        (status == DeviceConnectionStatus.connected || status == DeviceConnectionStatus.connecting)
            ? Colors.grey.shade700
            : Colors.blue.shade900;
    Color statusColor =
        (status == DeviceConnectionStatus.connected || status == DeviceConnectionStatus.connecting)
            ? Colors.grey.shade700
            : Colors.grey.shade500;

    FontWeight statusFontWeight =
        (status == DeviceConnectionStatus.connected || status == DeviceConnectionStatus.connecting)
            ? FontWeight.bold
            : FontWeight.normal;
    FontWeight statusFontWeightTitle =
        (status == DeviceConnectionStatus.connected || status == DeviceConnectionStatus.connecting)
            ? FontWeight.normal
            : FontWeight.bold;

    return Opacity(
      opacity: _devicesEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: _devicesEnabled ? () => onTap() : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              width: boxWidth,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                        fontSize: 17.5, fontWeight: statusFontWeightTitle, color: titleColor),
                    // TextStyle(fontWeight: statusFontWeightTitle, fontSize: 16, color: titleColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 30), // Spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (status == DeviceConnectionStatus.connected && batteryIcon != null)
                        Transform.rotate(
                          angle: 3.14159 / 2,
                          child: Icon(batteryIcon, color: iconColor),
                        ),
                      SizedBox(width: 4), // Spacing
                      // Connection Status
                      Text(
                        // status.toString().split('.').last,
                        statusMessage,
                        style: TextStyle(
                            fontSize: 16, color: statusColor, fontWeight: statusFontWeight),
                      ),
                      SizedBox(width: 2),
                      if (status == DeviceConnectionStatus.connecting)
                        SpinKitFadingCircle(
                          color: Colors.red.shade500,
                          size: 20.0,
                        ),
                      if (status == DeviceConnectionStatus.connected)
                        SpinKitPumpingHeart(
                          color: Colors.red.shade500,
                          size: 15.0,
                        ),
                    ],
                  ),

                  // Switch Widget or Lock Icon

                  if (!_devicesEnabled) Icon(Icons.lock, color: Colors.red, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDeviceTap(String deviceName) async {
    DeviceConnectionStatus status =
        deviceStatuses[deviceName] ?? DeviceConnectionStatus.disconnected;

    if (status == DeviceConnectionStatus.connected) {
      // Disconnect
      switch (deviceName) {
        case 'SB':
          await SmartBandApi.disconnectDevice();
          break;
        case 'RH':
          await MetaWearApi.disconnectDevice(1);
          break;
        case 'LH':
          await MetaWearApi.disconnectDevice(2);
          break;
        case 'RF':
          await SensoriaApi.disconnectDevice(1);
          break;
        case 'LF':
          await SensoriaApi.disconnectDevice(2);
          break;
      }
    } else {
      // Connect
      switch (deviceName) {
        case 'SB':
          await SmartBandApi.scanConnectBind();
          break;
        case 'RH':
          await MetaWearApi.connectDevice(1);
          // await MetaWearApi.startScan();

          break;
        case 'LH':
          await MetaWearApi.connectDevice(2);
          // await MetaWearApi.startScan();

          break;
        case 'RF':
          await SensoriaApi.scanAndConnectWithCore(1);
          break;
        case 'LF':
          await SensoriaApi.scanAndConnectWithCore(2);
          break;
      }
    }

    _updateDeviceStatus(
        deviceName, deviceStatuses[deviceName] ?? DeviceConnectionStatus.disconnected);
  }

  Widget buildLanguageDropdown() {
    return DropdownButton<Locale>(
      value: _locale,
      onChanged: (Locale? newValue) async {
        if (newValue != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('languageCode', newValue.languageCode);
          setLocale(newValue);
        }
      },
      items: [
        DropdownMenuItem(
          value: Locale('en', ''),
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: Locale('es', ''),
          child: Text('Spanish'),
        ),
      ],
    );
  }

  void _onDeviceConnected(String macAddress, String hand) {
    setState(() {});
  }

  void _onSensoriaDeviceConnected(String macAddress, String foot) {
    setState(() {
      if (foot == "Right") {
        isRightFootToggled = true;

        _sensoriaconnectedDevices.add(macAddress);
      } else if (foot == "Left") {
        isLeftFootToggled = true;
        _sensoriaconnectedDevices.add(macAddress);
      }
    });
  }

  //////////////ID Number///////////////////
  //todo:the _loadIdNumber and _saveIdNumber are related to save the id number

  Future<void> _loadIdNumber() async {
    final prefs = await SharedPreferences.getInstance();

    final idNumber = prefs.getString('idNumber') ?? '';

    final idNumberChecksum = prefs.getString('idNumberChecksum') ?? '';
    final combinedIDChecksum = "$idNumber-$idNumberChecksum";

    setState(() {
      _idController.text = idNumber; // display the raw ID number in the textfield
      _checksumController.text = idNumberChecksum; // also set the checksum TextField
      _devicesEnabled = idNumber.isNotEmpty && idNumberChecksum.isNotEmpty;
    });

    if (idNumber.isNotEmpty && idNumberChecksum.isNotEmpty) {
      ServiceApi.sendIdNumber(combinedIDChecksum);
      SmartBandApi.setIdNumber(combinedIDChecksum);
      SensoriaApi.sendIdNumber(combinedIDChecksum);
      MetaWearApi.sendIdNumber(combinedIDChecksum);

      print("the id number sent from the main with the id $combinedIDChecksum");
    }
  }

  Future<void> _saveIdNumber(String idNumber, int checksum) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idNumber', idNumber);
    await prefs.setString('idNumberChecksum', checksum.toString());
  }

//---------------- Id number check/edit/Reset--------------------------
  void _handleCheckOrEdit() async {
    if (_isIdEditable) {
      String idNumber = _idController.text.trim();
      if (idNumber.isNotEmpty && idNumber.length <= 12) {
        int calculatedChecksum = getChkSum(idNumber);
        int userEnteredChecksum = int.tryParse(_checksumController.text) ?? -1;

        if (calculatedChecksum == userEnteredChecksum) {
          _saveIdNumber(idNumber, userEnteredChecksum);

          final combinedIDChecksum = "$idNumber-$calculatedChecksum";

          SmartBandApi.setIdNumber(combinedIDChecksum);
          MetaWearApi.sendIdNumber(combinedIDChecksum);
          SensoriaApi.sendIdNumber(combinedIDChecksum);
          // _loadIdNumber();
          setState(() {
            _isIdEditable = false;
            _isIdCorrect = true;
            _devicesEnabled = true;
          });
          _startIdInputTimer();
        } else {
          setState(() {
            _isIdCorrect = false;
            _devicesEnabled = false;
          });
        }
      } else {
        setState(() {
          _isIdCorrect = false;
        });
      }
    } else {
      setState(() {
        _isIdEditable = true;
        _devicesEnabled = false;

        // _isIdCorrect = true; // to reset checksum state on edit
      });
    }
  }

  void _startIdInputTimer() {
    _idInputTimer?.cancel();

    _idInputTimer = Timer(Duration(minutes: 3), () {
      if (_areAllDevicesDisconnected()) {
        setState(() {
          _idController.clear();
          _checksumController.clear();
          _isIdEditable = true;
          _devicesEnabled = false;
        });
      }
    });
  }

  bool _areAllDevicesDisconnected() {
    return deviceStatuses.values.every((status) => status == DeviceConnectionStatus.disconnected);
  }

  void _startOrRestartDisconnectTimer() {
    _idInputTimer?.cancel();

    _idInputTimer = Timer(Duration(minutes: 3), () {
      setState(() {
        _idController.clear();
        _checksumController.clear();
        _isIdEditable = true;
        _devicesEnabled = false;
      });
    });
  }

  void _cancelDisconnectTimer() {
    _idInputTimer?.cancel();
  }

  //////////////////////////////////////////////////

  String getConnectionStatusMessage(DeviceConnectionStatus status, Locale locale) {
    Map<DeviceConnectionStatus, String> enMessages = {
      DeviceConnectionStatus.disconnected: "Not connected",
      DeviceConnectionStatus.connecting: "Connecting ",
      DeviceConnectionStatus.connected: "Connected",
      DeviceConnectionStatus.reconnecting: "Reconnecting..."
    };

    Map<DeviceConnectionStatus, String> esMessages = {
      DeviceConnectionStatus.disconnected: "No conectado",
      DeviceConnectionStatus.connecting: "Conectando ",
      DeviceConnectionStatus.connected: "Conectado",
      DeviceConnectionStatus.reconnecting: "Reconectando..."
    };

    Map<DeviceConnectionStatus, String> messages =
        locale.languageCode == "es" ? esMessages : enMessages;

    return messages[status] ?? "Unknown";
  }
}

/////////////////////New pages for Test History, Test In Progress and Thank You screen
// Test History Page
class TestHistoryPage extends StatefulWidget {
  final String codeID;
  final Locale locale;
  TestHistoryPage({required this.codeID, required this.locale});

  @override
  _TestHistoryPageState createState() => _TestHistoryPageState();
}

class _TestHistoryPageState extends State<TestHistoryPage> {
  List<Map<String, String>> testHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTestHistory();
  }

  /////// Formats the raw ISO8601 date string into a user-friendly format.
  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      // Format into "yyyy-MM-dd HH:mm"
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (e) {
      return rawDate; // In case of error, return raw string.
    }
  }

  ////// Fetches test history from the server.
  ////// This function makes a POST request sending the combined codeID.
  Future<void> _fetchTestHistory() async {
    setState(() {
      isLoading = true;
    });
    try {
      ////// Build the URL to the endpoint that returns history data.
      final url = Uri.parse('http://138.100.82.181/AppCognit/listaHWevento');

      // POST the codeID (the combined reference)
      final response = await http.post(
        url,
        body: {
          'codeid': widget.codeID, // example, "AMIR-48"
        },
      );

      if (response.statusCode == 200) {
        // Decode the JSON response.
        final Map<String, dynamic> responseBody = json.decode(response.body);

        // Check that the response status is "ok"
        if (responseBody['status'] == 'ok') {
          final List<dynamic> data = responseBody['message'];

          setState(() {
            // Map each JSON object to a local Map with keys 'test' and 'start'
            testHistory = data.map<Map<String, String>>((item) {
              return {
                'test': item['t_code']?.toString() ?? '',
                'start': item['d_from']?.toString() ?? ''
              };
            }).toList();
            isLoading = false;
          });
        } else {
          print('Response status not ok: ${responseBody['message']}');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('Failed to load test history. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching test history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  //// Builds a single history item using a glass-style container.
  Widget _buildHistoryGlassCard(Map<String, String> record) {
    final formattedDate = _formatDate(record['start'] ?? '');
    final testName = record['test'] ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Test name styled similar to device tiles
                Text(
                  testName,
                  style: GoogleFonts.roboto(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                // Start date/time in a friendly format
                Text(
                  'Start: $formattedDate',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Locale currentLocale = widget.locale;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentLocale.languageCode == 'en' ? 'Test History' : 'Historial de Pruebas'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTestHistory,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: testHistory.length,
                itemBuilder: (context, index) {
                  final record = testHistory[index];
                  return _buildHistoryGlassCard(record);
                },
              ),
      ),
    );
  }
}

// Test In Progress Screen
// -----------------------------------------------------------------------------
class TestInProgressScreen extends StatefulWidget {
  final String testType;
  final DateTime startTime;
  final void Function(DateTime endTime) onEndTest;
  final Locale locale;

  TestInProgressScreen({
    required this.testType,
    required this.startTime,
    required this.onEndTest,
    required this.locale,
  });

  @override
  _TestInProgressScreenState createState() => _TestInProgressScreenState();
}

class _TestInProgressScreenState extends State<TestInProgressScreen> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  // exactly the same auto‑map from the instruction screen
  static const _autoDurations = {
    'Two Minutes Walking Test': Duration(minutes: 2),
    'Prueba de Marcha de 2 Minutos': Duration(minutes: 2),
    'Six Minute Walking Test': Duration(minutes: 6),
    'Prueba de Marcha de 6 Minutos': Duration(minutes: 6),
  };

  @override
  void initState() {
    super.initState();
    final code = widget.testType;
    final autoDur = _autoDurations[code];

    // if auto: tick & finish when reached
    if (autoDur != null) {
      _timer = Timer.periodic(Duration(seconds: 1), (t) {
        setState(() => _elapsed = DateTime.now().difference(widget.startTime));
        if (_elapsed >= autoDur) _finish();
      });
    } else {
      // otherwise just tick display
      _timer = Timer.periodic(Duration(seconds: 1), (_) {
        setState(() => _elapsed = DateTime.now().difference(widget.startTime));
      });
    }
  }

  void _finish() {
    _timer.cancel();
    widget.onEndTest(DateTime.now());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ThankYouScreen(locale: widget.locale),
      ),
    );
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuto = _autoDurations.containsKey(widget.testType);

    return Scaffold(
      appBar: AppBar(title: Text(widget.testType)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // timer display
            Text(
              _format(_elapsed),
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),

            // only show STOP for non‑auto
            if (!isAuto)
              GestureDetector(
                onTap: _finish,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: Center(
                    child: Icon(Icons.stop, size: 36, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Thank You Screen
class ThankYouScreen extends StatelessWidget {
  final Locale locale;
  ThankYouScreen({required this.locale});

  @override
  Widget build(BuildContext context) {
    final lang = locale.languageCode;
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).popUntil((r) => r.isFirst);
    });
    return Scaffold(
      body: Center(
        child: Text(
          lang == 'en' ? 'Thank You!' : '¡Gracias!',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TestInstructionScreen
// -----------------------------------------------------------------------------
class TestInstructionScreen extends StatelessWidget {
  final String testType;
  final Locale locale;
  final VoidCallback onStart;

  TestInstructionScreen({
    required this.testType,
    required this.locale,
    required this.onStart,
  });

  // All instruction texts:
  static const _instructions = {
    'Timed Up & Go Test': {
      'en': 'Press START, rise from a chair, walk 3 m, turn, walk back, sit down. Then press STOP.',
      'es':
          'Presione INICIO, levántese de la silla, camine 3 m, dé la vuelta, regrese y siéntese. Al finalizar, presione DETENER.',
    },
    'Prueba de Timed Up & Go': {
      'en': 'Press START, rise from a chair, walk 3 m, turn, walk back, sit down. Then press STOP.',
      'es':
          'Presione INICIO, levántese de la silla, camine 3 m, dé la vuelta, regrese y siéntese. Al finalizar, presione DETENER.',
    },
    'Two Minutes Walking Test': {
      'en':
          'Press START, walk continuously for 2 min at your comfort pace. The test will finish automatically after 2  min.',
      'es':
          'Presione INICIO, camine durante 2 min a su ritmo. La prueba finalizará automáticamente tras 2 minutos.',
    },
    'Prueba de Marcha de 2 Minutos': {
      'en':
          'Press START, walk continuously for 2 min at your comfort pace. The test will finish automatically after 2  min.',
      'es':
          'Presione INICIO, camine durante 2 min a su ritmo. La prueba finalizará automáticamente tras 2 minutos.',
    },
    'Timed 25-Foot Walk Test': {
      'en':
          'Press START, walk 25 ft (7.62 m) straight as quickly & safely as possible. Then press STOP.',
      'es':
          'Presione INICIO, camine 25 pies (7.62 metros) en línea recta lo más rápido y seguro posible. Al finalizar, presione DETENER.',
    },
    'Marcha de 25 Pies Cronometrada': {
      'en':
          'Press START, walk 25 ft (7.62 m) straight as quickly & safely as possible. Then press STOP.',
      'es':
          'Presione INICIO, camine 25 pies (7.62 metros) en línea recta lo más rápido y seguro posible. Al finalizar, presione DETENER.',
    },
    'Six Minute Walking Test': {
      'en':
          'Press START, walk for 6 min at your pace. The test will finish automatically after 6 min.',
      'es':
          'Presione INICIO, camine durante 6 min a su ritmo. La prueba finalizará automáticamente tras 6 minutos.',
    },
    'Prueba de Marcha de 6 Minutos': {
      'en':
          'Press START, walk for 6 min at your pace. The test will finish automatically after 6 min.',
      'es':
          'Presione INICIO, camine durante 6 min a su ritmo. La prueba finalizará automáticamente tras 6 minutos.',
    },
  };

  // Which tests auto‑finish?
  static const _autoDurations = {
    'Two Minutes Walking Test': Duration(minutes: 2),
    'Prueba de Marcha de 2 Minutos': Duration(minutes: 2),
    'Six Minute Walking Test': Duration(minutes: 6),
    'Prueba de Marcha de 6 Minutos': Duration(minutes: 6),
  };

  @override
  Widget build(BuildContext ctx) {
    final lang = locale.languageCode;
    final instr = _instructions[testType]![lang]!;
    final autoDur = _autoDurations[testType];
    final isAuto = autoDur != null;

    return Scaffold(
      appBar: AppBar(title: Text(testType, style: GoogleFonts.lato(fontSize: 20))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // **Time:** header for auto‑finish tests
            if (isAuto) ...[
              Text(
                lang == 'en'
                    ? 'Time: ${autoDur!.inMinutes} minutes'
                    : 'Tiempo: ${autoDur!.inMinutes} minutos',
                style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
            ],

            // Instruction text
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  instr,
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.openSans(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
                ),
              ),
            ),

            // Big START button
            GestureDetector(
              onTap: onStart,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: Center(
                  child: Text(
                    lang == 'en' ? 'START' : 'INICIO',
                    style: GoogleFonts.lato(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
