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
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart'; //just to check the bluetooth is available or not
import 'package:collection/collection.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; //for language
import 'AppLocal.dart'; //for the langauges
import 'StatusChecker.dart';

import 'enums/device_connection_status.dart';

class SpO2Data {
  final int spo2Value;
  final int progress;

  SpO2Data({required this.spo2Value, required this.progress});

  factory SpO2Data.fromJson(Map<String, dynamic> json) {
    return SpO2Data(
      spo2Value: json['spo2Value'],
      progress: json['progress'],
    );
  }

  Map<String, dynamic> toJson() => {
        'spo2Value': spo2Value,
        'progress': progress,
      };
}

class SmartBandApi {
  //////conection status///////
  static Function(DeviceConnectionStatus)? onConnectionStatusChange;

  static void updateConnectionStatus(DeviceConnectionStatus status) {
    onConnectionStatusChange?.call(status);
  }
  /////////////

  static List<List<dynamic>> heartRateBuffer = [];
  static List<List<dynamic>> spo2Buffer = [];
  static List<List<dynamic>> BPBuffer = [];
  static List<List<dynamic>> ecgDataBuffer = [];

  static String? _idNumber;
  static String? _selectedDeviceMac;
  static String? _selectedDeviceName;

  static double? _lastKnownLatitude;
  static double? _lastKnownLongitude;

  static bool isBPMeasuring = false;
  static bool isConnected = false;

  static Timer? _fetchStepDataTimer;

  static final _ble = FlutterReactiveBle();

  static String? _appVersion;

  ////set language/////////

  static String languageCode = "en";

  static void setLocale(String code) {
    languageCode = code;
  }
  //////////

  static void setAppVersion(String version) {
    _appVersion = version;
  }

  ////////status checker/////

  static DateTime? lastDataHRTimestamp;
  static DateTime? lastDataBPTimestamp;
  static DateTime? lastDataStepTimestamp;
  static DateTime? lastDataWriteFileTimestamp;

  static void updateConnectionStatusForChecker(DeviceConnectionStatus status) {
    StatusChecker.updateSmartBandStatus(status);
  }

  static Map<String, dynamic> getCurrentStatus() {
    print("the request from status cheker is receive--------------------");

    return {
      "isConnected": isConnected,
      "lastDataHRTimestamp": lastDataHRTimestamp?.toIso8601String() ?? "0",
      "lastDataBPTimestamp": lastDataBPTimestamp?.toIso8601String() ?? "0",
      "lastDataStepTimestamp": lastDataStepTimestamp?.toIso8601String() ?? "0",
      "lastDataWriteFileTimestamp": lastDataWriteFileTimestamp?.toIso8601String() ?? "0",
    };
  }
  ///////////

/////----------permission and services check

  static Future<bool> checkAndRequestPermissions() async {
    List<Permission> permissions = [
      // Permission.storage,
      Permission.notification,
      Permission.location,
      // Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ];

    bool allGranted = true;
    for (Permission permission in permissions) {
      var status = await permission.status;
      if (!status.isGranted) {
        var result = await permission.request();
        allGranted = result.isGranted && allGranted;
      }
    }
    return allGranted;
  }

  static Future<bool> isBluetoothAndLocationEnabled() async {
    bool isBluetoothEnabled = await isBluetoothServiceEnabled();

    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isBluetoothEnabled) {
      updateConnectionStatus(DeviceConnectionStatus.disconnected);
      isConnected = false;
      Fluttertoast.showToast(
        msg: languageCode == "en"
            ? "Bluetooth is not enabled. Please enable Bluetooth to use this feature."
            : "El Bluetooth no está activado. Por favor, active el Bluetooth para utilizar esta función.",
        toastLength: Toast.LENGTH_LONG,
      );
    }

    if (!isLocationEnabled) {
      updateConnectionStatus(DeviceConnectionStatus.disconnected);
      isConnected = false;
      Fluttertoast.showToast(
        msg: languageCode == "en"
            ? "Location services are not enabled. Please enable Location to use this feature."
            : "Los servicios de ubicación no están activados. Por favor, active la ubicación para utilizar esta función.",
        toastLength: Toast.LENGTH_LONG,
      );
    }

    return isBluetoothEnabled && isLocationEnabled;
  }

  static Future<bool> isBluetoothServiceEnabled() async {
    final bluetoothStatus = await _ble.statusStream.firstWhere(
      (status) =>
          status == BleStatus.ready ||
          status == BleStatus.unsupported ||
          status == BleStatus.unauthorized ||
          status == BleStatus.poweredOff,
    );
    return bluetoothStatus == BleStatus.ready;
  }

//////////////////////////-----------------------------
  static Future<void> scanConnectBind() async {
    try {
      updateConnectionStatus(DeviceConnectionStatus.connecting);

      bool permissionsOk = await checkAndRequestPermissions();
      bool servicesOk = await isBluetoothAndLocationEnabled();

      if (!permissionsOk) {
        Fluttertoast.showToast(
          msg: SmartBandApi.languageCode == "en"
              ? "Missing permissions. Please grant permissions."
              : "Faltan permisos. Por favor, concede los permisos.",
        );
        return;
      }
      if (!servicesOk) {
        Fluttertoast.showToast(
          msg: SmartBandApi.languageCode == "en"
              ? "Bluetooth or Location is off. Please enable them."
              : "El Bluetooth o la ubicación están apagados. Por favor, actívalos.",
        );

        return;
      }

      SearchResult? selectedDevice;
      // scan Attempt Loop
      int scanAttempts = 3;
      while (scanAttempts > 0 && selectedDevice == null) {
        List<SearchResult> devices = await VeepooSdk.scanDevice();
        if (devices.isNotEmpty) {
          selectedDevice = devices.first;

          _selectedDeviceMac = selectedDevice.mac;
          _selectedDeviceName = selectedDevice.name;
        } else {
          scanAttempts--;
          await Future.delayed(Duration(seconds: 2)); // wait before retrying
        }
      }

      if (selectedDevice == null) {
        Fluttertoast.showToast(
            msg: SmartBandApi.languageCode == "en"
                ? "Failed to find any devices after several attempts."
                : "No se encontraron Pulsera Inteligente.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            // timeInSecForIosWeb: 10,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
        updateConnectionStatus(DeviceConnectionStatus.disconnected);
        isConnected = false;

        return;
      }

      isConnected = false;
      int connectAttempts = 2;
      while (connectAttempts > 0 && !isConnected) {
        isConnected = await VeepooSdk.connect(selectedDevice!.mac) ?? false;
        if (!isConnected) {
          connectAttempts--;

          await Future.delayed(Duration(seconds: 2));
        }
      }

      if (!isConnected) {
        Fluttertoast.showToast(
            msg: SmartBandApi.languageCode == "en"
                ? "Failed to connect to Smartband."
                : "Fallo al conectar con la pulsera inteligente.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 10,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
        updateConnectionStatus(DeviceConnectionStatus.disconnected);

        return;
      }

      // If connected, proceed to bind
      bool? isBound = await VeepooSdk.bind("0000", true);
      if (isBound == true) {
        print('Bound to ${selectedDevice!.mac}');
        SmartBandApi.updateConnectionStatus(DeviceConnectionStatus.connected);
        updateConnectionStatusForChecker(DeviceConnectionStatus.connected); // Notify StatusChecker

        isConnected = true;

        // Proceed with other actions
        updateLocationPeriodically();
        startHeartRateMeasurement();
        startFetchingStepDataPeriodically();
      } else {}
    } catch (e) {}
  }

  static Future<void> disconnectDevice() async {
    await VeepooSdk.disconnect();
    print('device is disconned--------------');
    updateConnectionStatus(DeviceConnectionStatus.disconnected);
    updateConnectionStatusForChecker(DeviceConnectionStatus.disconnected);
  }

//------HeartRate Measurement---------------
  static Future<void> startHeartRateMeasurement() async {
    await VeepooSdk.startDetectHeart();

    VeepooSdk.eventChannel().receiveBroadcastStream().listen((event) {
      try {
        final Map<String, dynamic> e = event is String ? json.decode(event) : event;

        if (e['action'] == 'onHrDataChange') {
          if (e['payload'] is String) {
            final Map<String, dynamic> payload = json.decode(e['payload']);

            int heartRate = payload['data']; // extract heart rate number
            int timestamp = DateTime.now().millisecondsSinceEpoch; // get current timestamp

            // adding heart rate and timestamp to buffer as a map
            if (heartRate > 0) {
              // add the heart rate and timestamp as a list to the buffer
              heartRateBuffer.add([heartRate, timestamp]);
              lastDataHRTimestamp = DateTime.now();
            }
            List<String> heartRateStructure = ["HeartRate", "TimeStamp"];

            if (heartRateBuffer.length == 20) {
              VeepooSdk.stopDetectHeart();
              saveDataToFile('HR', heartRateBuffer, structure: heartRateStructure);
              heartRateBuffer.clear();
              startBPRateMeasurement();
            }
          }
        }
      } catch (error) {
        print("Error processing event data: $error");
      }
    }, onError: (error) {
      print("Error receiving heart rate data: $error");
    });
  }

  //////////BP mesurement//////////////
  static Future<void> startBPRateMeasurement() async {
    await VeepooSdk.startDetectBP();

    VeepooSdk.eventChannel().receiveBroadcastStream().listen((event) {
      final e = json.decode(event);

      if (e['action'] == 'onBPDataChange') {
        if (e['payload'] is String) {
          final payload = e['payload'] is String ? json.decode(e['payload']) : e['payload'];

          if (payload != null && payload is Map<String, dynamic>) {
            BpData bpData = BpData.fromJson(payload);
            print(
                "Blood Pressure High: ${bpData.highPressure}, Low: ${bpData.lowPressure}, Progress: ${bpData.progress}");

            if (bpData.progress == 100) {
              BPBuffer.add(
                  [bpData.highPressure, bpData.lowPressure, DateTime.now().millisecondsSinceEpoch]);
              lastDataBPTimestamp = DateTime.now();

              VeepooSdk.stopDetectBP();
              List<String> bpStructure = ["HighBloodPressure", "LowBloodPressure", "TimeStamp"];

              saveDataToFile('HB', BPBuffer, structure: bpStructure);
              BPBuffer.clear();
              startHeartRateMeasurement();
            }
          }
        }
      }
    }, onError: (error) {
      print("Error receiving heart rate data: $error");
    });
  }
  /////////

  //-------------Battery----------
  static Future<int?> getBatteryLevel() async {
    try {
      final int? batteryLevel = await VeepooSdk.readBattery();
      return batteryLevel;
    } catch (e) {
      print("Failed to read battery level: $e");
      return null;
    }
  }

  //--------------

//Step methods-------------------------------------------

  static void startFetchingStepDataPeriodically() {
    const fiveMinutes = Duration(minutes: 1);
    _fetchStepDataTimer = Timer.periodic(fiveMinutes, (Timer t) {
      fetchAndProcessStepData();
    });
  }

  static Future<void> fetchAndProcessStepData() async {
    try {
      final stepData = await VeepooSdk.readStepData();
      if (stepData != null) {
        final steps = stepData['steps'];
        final distance = stepData['distance'];
        final calories = stepData['calories'];
        if (steps > 0) {
          int timestamp = DateTime.now().millisecondsSinceEpoch;

          final List<List<dynamic>> buffer = [
            [steps, distance, calories, timestamp]
          ];

          lastDataStepTimestamp = DateTime.now();

          List<String> stepStructure = ["Steps", "Distance", "Calories", "TimeStamp"];

          saveDataToFile('HS', buffer, structure: stepStructure);
        } else {
          print('No steps recorded');
        }
      } else {
        print('No step data received');
      }
    } catch (e) {
      print('Failed to fetch step data: $e');
    }
  }

//-------------------------------------------

  //this method good for getting entire daily report each 5 minutes
  static Future<void> fiveMinutes() async {
    await VeepooSdk.readFiveMinutes();

    VeepooSdk.eventChannel().receiveBroadcastStream().listen((event) {
      final e = json.decode(event);

      if (e['action'] == 'onOriginFiveMinuteDataChange') {
        if (e['payload'] is String) {
          final payload = e['payload'] is String ? json.decode(e['payload']) : e['payload'];

          if (payload != null && payload is Map<String, dynamic>) {
            OriginData originData = OriginData.fromJson(payload);
            print(
                "the 5 min--------------: ${originData.allPackage}, Low: ${originData.packageNumber}, Progress: ${originData.rateValue},Progress: ${originData.sportValue},Progress: ${originData.stepValue},Progress: ${originData.highValue},Progress: ${originData.lowValue},Progress: ${originData.wear},Progress: ${originData.calValue},Progress: ${originData.disValue}");
          }
        }
      }
    }, onError: (error) {
      print("Error receiving heart rate data: $error");
    });
  }
  //--------------------------------------------

//------get Storage permission
  static Future<void> requestStoragePermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      Position position =
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _lastKnownLatitude = position.latitude; // Update with fetched location
      _lastKnownLongitude = position.longitude;
      return position;
    } catch (e) {
      print("Failed to fetch location: $e");
      return null;
    }
  }

//-----get local file
  static Future<File> _getLocalFile(String fileName) async {
    final Directory? directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception("External storage directory not found");
    }
    final String path = directory.path;
    return File('$path/$fileName');
  }

  //---receive Id number
  static void setIdNumber(String refNumber) {
    _idNumber = refNumber;
  }

  static void prepareDataAndSave(
      String dataType, List<List<dynamic>> buffer, List<String> Structure) async {
    double? latitude;
    double? longitude;
    try {
      Position? position = await getCurrentLocation();
      latitude = position?.latitude;
      longitude = position?.longitude;
    } catch (e) {
      print("Failed to fetch location: $e");
    }

    await saveDataToFile(dataType, buffer,
        latitude: latitude, longitude: longitude, structure: Structure);
  }

  static void prepareDataAndSave2(
      String dataType, List<List<dynamic>> buffer, List<String> Structure) async {
    await saveDataToFile(dataType, buffer,
        latitude: _lastKnownLatitude, longitude: _lastKnownLongitude, structure: Structure);
  }

  static void updateLocationPeriodically() {
    Timer.periodic(Duration(seconds: 5), (Timer t) async {
      try {
        Position? position = await getCurrentLocation();
        _lastKnownLatitude = position?.latitude;
        _lastKnownLongitude = position?.longitude;
      } catch (e) {
        print("Failed to fetch location: $e");
      }
    });
  }

  // ---Unified method to save data from any buffer to files
  static Future<void> saveDataToFile(String dataType, List<List<dynamic>> buffer,
      {double? latitude, double? longitude, required List<String> structure}) async {
    try {
      final StringBuffer sb = StringBuffer();

      String type = "";

      switch (dataType) {
        case "HR":
          type = "HeartRate";
          break;
        case "HB":
          type = "BloodPressure";
          break;
        case "HS":
          type = "Steps";
          break;
      }

      Map<String, dynamic> metadata = {
        'Id': _idNumber,
        'Type': type,
        'Structure': structure,
        'Lat': _lastKnownLatitude,
        'Long': _lastKnownLongitude,
        'AppVersion': _appVersion,
        'DeviceMac': _selectedDeviceMac,
        'DeviceName': _selectedDeviceName,
      };

      String metadataJson = jsonEncode(metadata);

      sb.writeln(metadataJson);

      for (List<dynamic> entry in buffer) {
        String entryString = entry.join(', ');
        sb.writeln(entryString);
      }

      final String baseFileName = "${dataType}_${DateTime.now().millisecondsSinceEpoch}";
      final String txtFileName = "$baseFileName.txt";
      final File txtFile = await _getLocalFile(txtFileName);
      await txtFile.writeAsString(sb.toString());

      final String gzFileName = "$baseFileName.gz";

      final File gzFile = await _compressFile(txtFile, gzFileName);

      await txtFile.delete();
      lastDataWriteFileTimestamp = DateTime.now();

      print('Data is compressed and original file deleted.');
    } catch (e) {
      print('An error occurred while saving data: $e');
    }
  }

  //--compress files
  static Future<File> _compressFile(File file, String gzFileName) async {
    final File gzFile = await _getLocalFile(gzFileName);
    final List<int> bytes = file.readAsBytesSync();
    final List<int> gzippedBytes = gzip.encode(bytes);
    await gzFile.writeAsBytes(gzippedBytes);
    return gzFile;
  }
}
