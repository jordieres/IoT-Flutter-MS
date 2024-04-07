import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import 'enums/device_connection_status.dart';

class MetaWearApi {
  static const _platform = MethodChannel('com.example.healthywear/metawear');

  //connection Evenet listener----------------
  static const _connectionStatusChannel =
      EventChannel('com.example.healthywear/metawear_connection_status');

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
    final int deviceIndex = statusUpdate["deviceIndex"];
    final String status = statusUpdate["status"];

    if (status == "connected") {
      if (deviceIndex == 1) {
        updateRightHandConnectionStatus(DeviceConnectionStatus.connected);
        onConnectionStatusChanged?.call("MetaWear", 1, DeviceConnectionStatus.connected);
      } else if (deviceIndex == 2) {
        updateLeftHandConnectionStatus(DeviceConnectionStatus.connected);
        onConnectionStatusChanged?.call("MetaWear", 2, DeviceConnectionStatus.connected);
      }
    } else if (status == "disconnected") {
      if (deviceIndex == 1) {
        updateRightHandConnectionStatus(DeviceConnectionStatus.disconnected);
        onConnectionStatusChanged?.call("MetaWear", 1, DeviceConnectionStatus.disconnected);
      } else if (deviceIndex == 2) {
        updateLeftHandConnectionStatus(DeviceConnectionStatus.disconnected);
        onConnectionStatusChanged?.call("MetaWear", 2, DeviceConnectionStatus.disconnected);
      }
    } else if (status == "reconnecting") {
      if (deviceIndex == 1) {
        updateRightHandConnectionStatus(DeviceConnectionStatus.reconnecting);
      } else if (deviceIndex == 2) {
        updateLeftHandConnectionStatus(DeviceConnectionStatus.reconnecting);
      }
    }
  }

//----------Send connection status----------
  static Function(DeviceConnectionStatus)? onRightHandConnectionStatusChange;

  static void updateRightHandConnectionStatus(DeviceConnectionStatus status) {
    onRightHandConnectionStatusChange?.call(status);
  }

  static Function(DeviceConnectionStatus)? onLeftHandConnectionStatusChange;

  static void updateLeftHandConnectionStatus(DeviceConnectionStatus status) {
    onLeftHandConnectionStatusChange?.call(status);
  }

  //-------------

  static final Map<String, Timer> _deviceTimers = {};

  //-----------------Permissions and device service check

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
    bool isBluetoothEnabled = await isBluetoothServiceEnabled();

    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isBluetoothEnabled) {
      updateRightHandConnectionStatus(DeviceConnectionStatus.disconnected);
      updateLeftHandConnectionStatus(DeviceConnectionStatus.disconnected);

      Fluttertoast.showToast(
        msg: _languageCode == "en"
            ? "Bluetooth service is not enabled. Please enable it."
            : "El servicio de Bluetooth no está activado. Por favor, actívelo.",
        toastLength: Toast.LENGTH_LONG,
      );
    }

    if (!isLocationEnabled) {
      updateRightHandConnectionStatus(DeviceConnectionStatus.disconnected);
      updateLeftHandConnectionStatus(DeviceConnectionStatus.disconnected);
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

  //////////-------SET language-------------------------

  static Future<void> setLocale(String languageCode) async {
    try {
      await _platform.invokeMethod('setLocale', {'languageCode': languageCode});
      _languageCode = languageCode;
    } on PlatformException catch (e) {
      print("Failed to set locale on Android side: '${e.message}'.");
    }
  }

  ////-------------------------------------
//NOT USED
  static Future<void> startScan() async {
    await _platform.invokeMethod('startScan');
  }

//NOTUSED
  static Future<void> stopScan() async {
    await _platform.invokeMethod('stopScan');
  }

  static Future<void> connectDevice(int deviceIndex) async {
    try {
      if (!_alreadyListening) {
        _connectionStatusChannel.receiveBroadcastStream().listen(handleConnectionUpdate,
            onError: (error) {
          print("Connection status update error: $error");
        });
        _alreadyListening = true;
      }

      if (deviceIndex == 1) {
        updateRightHandConnectionStatus(DeviceConnectionStatus.connecting);
      } else {
        updateLeftHandConnectionStatus(DeviceConnectionStatus.connecting);
      }

      bool permissionsOk = await checkAndRequestPermissions();
      bool servicesOk = await isBluetoothAndLocationEnabled();

      if (!permissionsOk) {
        print("Missing permissions");
        return;
      }
      if (!servicesOk) {
        print("Bluetooth or Location is off");
        return;
      }

      await _platform.invokeMethod('connectToDeviceIndex', {'deviceIndex': deviceIndex});
    } on PlatformException catch (e) {
      print("Failed to connect to device: ${e.message}");
      if (deviceIndex == 1) {
        updateRightHandConnectionStatus(DeviceConnectionStatus.disconnected);
      } else {
        updateLeftHandConnectionStatus(DeviceConnectionStatus.disconnected);
      }
    }
  }

  static Future<void> disconnectDevice(int deviceIndex) async {
    try {
      await _platform.invokeMethod('disconnectDevice', {'deviceIndex': deviceIndex});
      print("Disconnect request sent for device: $deviceIndex");
      if (deviceIndex == 1) {
        updateRightHandConnectionStatus(DeviceConnectionStatus.disconnected);
        onConnectionStatusChanged?.call("MetaWear", 1, DeviceConnectionStatus.disconnected);
      } else {
        updateLeftHandConnectionStatus(DeviceConnectionStatus.disconnected);
        onConnectionStatusChanged?.call("MetaWear", 2, DeviceConnectionStatus.disconnected);
      }
    } on PlatformException catch (e) {
      print("Error disconnecting device: ${e.message}");
    }
  }

  static Future<int> getBatteryLevelForDevice(int deviceIndex) async {
    try {
      final int batteryLevel =
          await _platform.invokeMethod('getBatteryLevel', {'deviceIndex': deviceIndex});
      return batteryLevel;
    } on PlatformException catch (e) {
      print("Failed to get battery level: ${e.message}");
      return -1;
    }
  }

  static Future<void> sendAppVersion(String appVersion) async {
    await _platform.invokeMethod('sendAppVersion', {'appVersion': appVersion});
  }

  static Future<void> sendIdNumber(String refNumber) async {
    try {
      print("-------------the ref number is ${refNumber}");
      await _platform.invokeMethod('sendIdNumber', {'refNumber': refNumber});
    } on PlatformException catch (e) {
      print("Failed to send Id ref number: '${e.message}'.");
    }
  }

  static void disposeTimers() {
    _deviceTimers.values.forEach((timer) => timer.cancel());
  }

  static void _showErrorNotification(String message) {
    // todo:Implement  the notification to the user can be simple dialog, a snackbar, or...
  }

  static void handleError(Object error, Function(dynamic) onError) {
    onError("Error: ${error.toString()}");
  }
}
