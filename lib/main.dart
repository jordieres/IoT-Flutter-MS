import 'package:flutter/material.dart';
import 'package:healthywear/StatusChecker.dart';
import 'SmartBandApi.dart';
import 'MetaWearApi.dart';
import 'SensoriaApi.dart';
import 'Uploader.dart';
import 'AppLocal.dart';
import 'NotificationHandler.dart';
import 'dart:async';
import 'BackgroundHandling.dart';

import 'splash_screen.dart';

import 'dart:ui'; //to use ImageFilter.
import 'package:google_fonts/google_fonts.dart';

import 'dart:math';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info/package_info.dart';
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
  await requestPermissions();

  initializeBackgroundTask(); //Backgroundhandling processes

  SharedPreferences prefs = await SharedPreferences.getInstance();

  String languageCode = prefs.getString('languageCode') ?? 'es';

  Locale initialLocale = Locale(languageCode);

  //to send the app version for the metadata
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String appVersion = packageInfo.version;
  SmartBandApi.setAppVersion(appVersion);
  MetaWearApi.sendAppVersion(appVersion);
  SensoriaApi.sendAppVersion(appVersion);

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

  runApp(SplashApp());
//splash screen//////////
  Future.delayed(Duration(seconds: 2), () {
    runApp(MyApp(initialLocale: initialLocale));
  });
  Uploader.startMonitoringAndUploading();
}

class SplashApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

Future<void> requestPermissions() async {
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

  // Check and request location permission
  var locationStatus = await Permission.location.status;
  if (!locationStatus.isGranted) {
    await Permission.location.request();
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
      // If any device is connected, ensure the timer is cancelled
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
    print("Locale in build: $_locale");
    var localization = AppLocalizations.of(context);
    print("Localization: $localization");
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
          title: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            height: 45,
            child: Image.asset('assets/images/SaludMadrid_logo.png', fit: BoxFit.scaleDown),
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
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10), // Match your container's border radius
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 0.0, sigmaY: 0.0), // Adjust blur radius as needed
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
                          padding: EdgeInsets.all(
                              12), // Add some padding inside the container for aesthetics
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
                                      )
                                    : Icon(Icons.edit, color: Colors.grey.shade300),
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
                  borderRadius: BorderRadius.circular(10), // Match your container's border radius
                  child: BackdropFilter(
                    filter:
                        ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Adjust blur radius as needed
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // Adjust opacity as needed
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
        backgroundColor: Colors.white,
      ),
    );
  }

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
        status == DeviceConnectionStatus.connected ? Colors.grey.shade700 : Colors.blue.shade900;
    Color statusColor =
        status == DeviceConnectionStatus.connected ? Colors.grey.shade700 : Colors.grey.shade500;

    FontWeight statusFontWeight =
        status == DeviceConnectionStatus.connected ? FontWeight.bold : FontWeight.normal;
    FontWeight statusFontWeightTitle =
        status == DeviceConnectionStatus.connected ? FontWeight.normal : FontWeight.bold;

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
                  SizedBox(height: 9), // Spacing
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

  void _handleDeviceTap(String deviceName) {
    DeviceConnectionStatus status =
        deviceStatuses[deviceName] ?? DeviceConnectionStatus.disconnected;

    if (status == DeviceConnectionStatus.connected) {
      // Disconnect
      switch (deviceName) {
        case 'SB':
          SmartBandApi.disconnectDevice();
          break;
        case 'RH':
          MetaWearApi.disconnectDevice(1);
          break;
        case 'LH':
          MetaWearApi.disconnectDevice(2);
          break;
        case 'RF':
          SensoriaApi.disconnectDevice(1);
          break;
        case 'LF':
          SensoriaApi.disconnectDevice(2);
          break;
      }
    } else {
      // Connect
      switch (deviceName) {
        case 'SB':
          SmartBandApi.scanConnectBind();
          break;
        case 'RH':
          MetaWearApi.connectDevice(1);
          break;
        case 'LH':
          MetaWearApi.connectDevice(2);
          break;
        case 'RF':
          SensoriaApi.scanAndConnectWithCore(1);
          break;
        case 'LF':
          SensoriaApi.scanAndConnectWithCore(2);
          break;
      }
    }
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
      SmartBandApi.setIdNumber(combinedIDChecksum);
      SensoriaApi.sendIdNumber(combinedIDChecksum);
      MetaWearApi.sendIdNumber(combinedIDChecksum);
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
      DeviceConnectionStatus.connecting: "Connecting...",
      DeviceConnectionStatus.connected: "Connected",
      DeviceConnectionStatus.reconnecting: "Reconnecting..."
    };

    Map<DeviceConnectionStatus, String> esMessages = {
      DeviceConnectionStatus.disconnected: "No conectado",
      DeviceConnectionStatus.connecting: "Conectando...",
      DeviceConnectionStatus.connected: "Conectado",
      DeviceConnectionStatus.reconnecting: "Reconectando..."
    };

    Map<DeviceConnectionStatus, String> messages =
        locale.languageCode == "es" ? esMessages : enMessages;

    return messages[status] ?? "Unknown";
  }
}
