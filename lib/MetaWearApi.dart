import 'package:flutter/services.dart';
import 'dart:async'; //  import for Timer
import 'dart:convert';

class MetaWearApi {
  static const _platform = MethodChannel('com.example.healthywear/metawear');
  static const _eventChannel = EventChannel('com.example.healthywear/accelerometerStream');
  static final Map<String, Timer> _deviceTimers = {};

  static Future<void> startScan() async {
    await _platform.invokeMethod('startScan');
  }

  static Future<void> stopScan() async {
    await _platform.invokeMethod('stopScan');
  }

  static Future<void> scanAndConnect(int deviceIndex, Set<String> connectedDevices,
      Function(String, String) onDeviceConnected) async {
    await startScan();
    await Future.delayed(Duration(seconds: 5));
    await stopScan();

    List<String> devices = await getScannedDevices();
    List<String> modifiableDevices = List<String>.from(devices);

    if (deviceIndex == 1 && connectedDevices.isNotEmpty) {
      modifiableDevices.remove(connectedDevices.first);
    } else {
      modifiableDevices
          .removeWhere((device) => connectedDevices.contains(device.split(' - ').first));
    }

    if (modifiableDevices.length > deviceIndex) {
      String selectedDevice = modifiableDevices[deviceIndex].split(' - ').first;
      String handIdentifier = deviceIndex == 0 ? "left" : "right";

      if (!connectedDevices.contains(selectedDevice)) {
        await connectToBoard(selectedDevice, handIdentifier);
        connectedDevices.add(selectedDevice);

        await Future.delayed(Duration(seconds: 5));
        await setupAccelerometer(selectedDevice, handIdentifier);

        onDeviceConnected(selectedDevice, handIdentifier);
        startDeviceTimer(selectedDevice, handIdentifier);
      }
    }
  }

  static void startDeviceTimer(String macAddress, String hand) {
    _deviceTimers[macAddress] = Timer.periodic(Duration(seconds: 5), (_) async {
      bool isConnected = await checkConnection(macAddress);
      if (isConnected) {
        int batteryLevel = await getBatteryLevel(macAddress);
        print("$hand hand device ($macAddress) - Battery Level: $batteryLevel%");
        await blinkLed(macAddress, hand, 2);
      } else {
        print("$hand hand device ($macAddress) is not connected.");
      }
    })
  }

  static void disposeTimers() {
    _deviceTimers.values.forEach((timer) => timer.cancel());
  }

  static Future<List<String>> getScannedDevices() async {
    final List<dynamic> devices = await _platform.invokeMethod('getScannedDevices');
    return devices.cast<String>();
  }

  static Future<void> connectToBoard(String macAddress, String hand) async {
    await _platform.invokeMethod('connectToBoard', {'macAddress': macAddress, 'hand': hand});
    // Adding a delay after connection
    // await Future.delayed(Duration(seconds: 10));
    // Now after delay set up the accelerometer
    // await setupAccelerometer(macAddress);
  }

  static Future<bool> checkConnection(String macAddress) async {
    return await _platform.invokeMethod('checkConnection', {'macAddress': macAddress});
  }

  static Future<void> blinkLed(String macAddress, String hand, int blinkCount) async {
    print("api: receive request to blink LED for $hand hand, $blinkCount times");
    await _platform.invokeMethod(
        'blinkLed', {'macAddress': macAddress, 'hand': hand, 'blinkCount': blinkCount});
    print("api: sent blink LED request");
  }

  static Future<void> setupAccelerometer(String macAddress, String hand) async {
    try {
      await _platform.invokeMethod('setupAccelerometer', {'macAddress': macAddress, 'hand': hand});
    } on PlatformException catch (e) {
      print("Error setting up accelerometer: ${e.message}");
    }
  }

  static Future<void> checkAndBlinkLed(String macAddress, String hand) async {
    try {
      final bool isStreaming =
          await _platform.invokeMethod('checkDataStreaming', {'macAddress': macAddress});
      if (isStreaming) {
        await blinkLed(macAddress, hand, 1);
      } else {
        _showErrorNotification("Data streaming error for device $macAddress.");
      }
    } catch (e) {
      _showErrorNotification("Connection error for device $macAddress: $e");
    }
  }

  static Future<int> getBatteryLevel(String macAddress) async {
    try {
      final int batteryLevel =
          await _platform.invokeMethod('getBatteryLevel', {'macAddress': macAddress});
      return batteryLevel;
    } on PlatformException catch (e) {
      print("Error getting battery level: ${e.message}");
      return -1; // indicates an error
    }
  }

  static void _showErrorNotification(String message) {
    // todo:Implement  the notification to the user can be simple dialog, a snackbar, or...
  }

  static Future<void> sendDataToServer() async {
    try {
      await _platform.invokeMethod('sendDataToServer');
      print("Data send request initiated");
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
    }
  }

  static Stream<dynamic> get accelerometerStream => _eventChannel.receiveBroadcastStream();

  static void updateAccelerometerData(dynamic data, Function(dynamic) onDataChanged) {
    onDataChanged(data.toString());
  }

  static void handleError(Object error, Function(dynamic) onError) {
    onError("Error: ${error.toString()}");
  }

  static Future<void> disconnectDevice(String macAddress) async {
    try {
      await _platform.invokeMethod('disconnectDevice', {'macAddress': macAddress});
      print("Disconnect request sent for device: $macAddress");
    } on PlatformException catch (e) {
      print("Error disconnecting device: ${e.message}");
    }
  }

  static Future<void> sendPrescriptionRefNumber(String refNumber) async {
    try {
      print("-------------the ref number is ${refNumber}");
      await _platform.invokeMethod('sendPrescriptionRefNumber', {'refNumber': refNumber});
    } on PlatformException catch (e) {
      print("Failed to send prescription ref number: '${e.message}'.");
    }
  }
}
