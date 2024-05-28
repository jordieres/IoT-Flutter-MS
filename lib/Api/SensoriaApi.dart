import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import '../enums/device_connection_status.dart';
import 'dart:io';

class SensoriaApi {
  static const MethodChannel _platform = MethodChannel('com.example.healthywear/sensoria');

//connection Evenet listener----------------
  static const _connectionStatusChannel =
      EventChannel('com.example.healthywear/sensoria_connection_status');

  static bool _alreadyListening = false;
  static String _languageCode = '';

  //callback for status checker////
  static Function(String, int, DeviceConnectionStatus)? onConnectionStatusChanged;

  static void setConnectionStatusListener(Function(String, int, DeviceConnectionStatus) callback) {
    onConnectionStatusChanged = callback;
  }
  ////////////////////////////

  static void handleConnectionUpdate(dynamic event) {
    final Map<dynamic, dynamic> statusUpdate = Map<String, dynamic>.from(event);
    final int coreIndex = statusUpdate["coreIndex"];
    final String status = statusUpdate["status"];

    if (status == "connected") {
      if (coreIndex == 1) {
        updateRightFootConnectionStatus(DeviceConnectionStatus.connected);
        onConnectionStatusChanged?.call("Sensoria", 1, DeviceConnectionStatus.connected);
      } else if (coreIndex == 2) {
        updateLeftFootConnectionStatus(DeviceConnectionStatus.connected);
        onConnectionStatusChanged?.call("Sensoria", 2, DeviceConnectionStatus.connected);
      }
    } else if (status == "disconnected") {
      if (coreIndex == 1) {
        updateRightFootConnectionStatus(DeviceConnectionStatus.disconnected);
        onConnectionStatusChanged?.call("Sensoria", 1, DeviceConnectionStatus.disconnected);
      } else if (coreIndex == 2) {
        updateLeftFootConnectionStatus(DeviceConnectionStatus.disconnected);
        onConnectionStatusChanged?.call("Sensoria", 2, DeviceConnectionStatus.disconnected);
      }
    } else if (status == "reconnecting") {
      if (coreIndex == 1) {
        updateRightFootConnectionStatus(DeviceConnectionStatus.reconnecting);
      } else if (coreIndex == 2) {
        updateLeftFootConnectionStatus(DeviceConnectionStatus.reconnecting);
      }
    }
  }

  ///////////----------Send connection status
  static Function(DeviceConnectionStatus)? onRightFootConnectionStatusChange;

  static void updateRightFootConnectionStatus(DeviceConnectionStatus status) {
    onRightFootConnectionStatusChange?.call(status);
  }

  static Function(DeviceConnectionStatus)? onLeftFootConnectionStatusChange;

  static void updateLeftFootConnectionStatus(DeviceConnectionStatus status) {
    onLeftFootConnectionStatusChange?.call(status);
  }

  ////////////////////------------

  ///////check permissions and services-------------------------

  static final _ble = FlutterReactiveBle();

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
    // Improved Bluetooth check
    bool isBluetoothEnabled = await isBluetoothServiceEnabled();

    // Direct check for Location services
    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isBluetoothEnabled) {
      updateRightFootConnectionStatus(DeviceConnectionStatus.disconnected);
      updateLeftFootConnectionStatus(DeviceConnectionStatus.disconnected);

      Fluttertoast.showToast(
        msg: _languageCode == "en"
            ? "Bluetooth service is not enabled. Please enable it."
            : "El servicio de Bluetooth no está activado. Por favor, actívelo.",
        toastLength: Toast.LENGTH_LONG,
      );
    }

    if (!isLocationEnabled) {
      updateRightFootConnectionStatus(DeviceConnectionStatus.disconnected);
      updateLeftFootConnectionStatus(DeviceConnectionStatus.disconnected);
      Fluttertoast.showToast(
        msg: _languageCode == "en"
            ? "Location service is not enabled. Please enable it."
            : "El servicio de ubicación no está activado. Por favor, actívelo.",
        toastLength: Toast.LENGTH_LONG,
      );
    }

    return isBluetoothEnabled && isLocationEnabled;
  }

  static Future<bool> isBluetoothServiceEnabled() async {
    // Listen for the first relevant status update rather than just taking the first emitted value
    final bluetoothStatus = await _ble.statusStream.firstWhere(
      (status) =>
          status == BleStatus.ready ||
          status == BleStatus.unsupported ||
          status == BleStatus.unauthorized ||
          status == BleStatus.poweredOff,
    );
    return bluetoothStatus == BleStatus.ready;
  }
  //////-------------------------------------

  static Future<void> scanAndConnect(int footIndex, Set<String> connectedDevices,
      Function(String, String) onDeviceConnected) async {
    await _platform.invokeMethod('startScanSensoria');
    await Future.delayed(Duration(seconds: 5)); // delay to allow for device discovery
    await _platform.invokeMethod('stopScanSensoria');

    List<dynamic> devices = await _platform.invokeMethod('getScannedSensoriaDevices');
    List<String> filteredDevices = devices
        .where((device) {
          var parts = device.split(' - ');
          return parts.length > 1 && !connectedDevices.contains(parts.last);
        })
        .toList()
        .cast<String>();

    if (filteredDevices.isNotEmpty && filteredDevices.length > footIndex) {
      String selectedDevice = filteredDevices[footIndex];
      String selectedDeviceMacAddress = selectedDevice.split(' - ').last;
      String foot = footIndex == 0 ? "right" : "left";

      if (!connectedDevices.contains(selectedDeviceMacAddress)) {
        bool isConnected = (await _platform.invokeMethod(
                'connectToSensoriaDevice', {'macAddress': selectedDeviceMacAddress})) ??
            false;

        if (isConnected) {
          onDeviceConnected(selectedDeviceMacAddress, foot);
        } else {
          print("Failed to connect to Sensoria device for the $foot foot.");
        }
      }
    } else {
      print("No Sensoria devices discovered or not enough devices to select the $footIndex index.");
    }
  }

  ////-----------------------------the 2 core test//////
  static Future<void> scanAndConnectWithCore(int coreIndex) async {
    try {
      if (!_alreadyListening) {
        _connectionStatusChannel.receiveBroadcastStream().listen(handleConnectionUpdate,
            onError: (error) {
          print("Connection status update error: $error");
        });
        _alreadyListening = true;
      }
      if (coreIndex == 1) {
        updateRightFootConnectionStatus(DeviceConnectionStatus.connecting);
      } else {
        updateLeftFootConnectionStatus(DeviceConnectionStatus.connecting);
      }
      if (Platform.isAndroid) {
        bool permissionsOk = await checkAndRequestPermissions();
        if (!permissionsOk) {
          print("Missing permissions");
          return;
        }
      }
      bool servicesOk = await isBluetoothAndLocationEnabled();
      if (!servicesOk) {
        print("Bluetooth or Location is off");
        return;
      }
//-------------------------------------
      await _platform.invokeMethod('scanAndConnectToSensoriaDevice', {'coreIndex': coreIndex});
    } catch (e) {
      print("Failed to initiate scan and connect with core $coreIndex: $e");
      if (coreIndex == 1) {
        updateRightFootConnectionStatus(DeviceConnectionStatus.disconnected);
      } else {
        updateLeftFootConnectionStatus(DeviceConnectionStatus.disconnected);
      }
    }
  }

  static Future<void> sendIdNumber(String refNumber) async {
    try {
      await _platform.invokeMethod('sendIdNumber', {'refNumber': refNumber});
    } on PlatformException catch (e) {
      print("Failed to send Id number: '${e.message}'.");
    }
  }

  static Future<void> sendAppVersion(String appVersion) async {
    await _platform.invokeMethod('sendAppVersion', {'appVersion': appVersion});
  }

  static Future<int> getBatteryLevelForDevice(int coreIndex) async {
    try {
      await Future.delayed(Duration(seconds: 1));

      final int batteryLevel =
          await _platform.invokeMethod('getBatteryLevel', {'coreIndex': coreIndex});
      print("sensoriaAPI-----Battery level----------------$batteryLevel");
      return batteryLevel;
    } on PlatformException catch (e) {
      print("Failed to get battery level: ${e.message}");
      return -1;
    }
  }

  //////////-------SET language-------------------------

  static Future<void> setLocale(String languageCode) async {
    try {
      await _platform.invokeMethod('setLocale', {'languageCode': languageCode});
      _languageCode = languageCode;
    } on PlatformException catch (e) {
      print("Failed to set locale on Android side: '${e.message}'.");
    }
  }

  ////////////////

  static Future<void> disconnectDevice(int coreIndex) async {
    try {
      await _platform.invokeMethod('disconnectDevice', {'coreIndex': coreIndex});
    } catch (e) {
      print("Failed to disconnect  with core $coreIndex: $e");
    }
  }

///////////////////////
}
