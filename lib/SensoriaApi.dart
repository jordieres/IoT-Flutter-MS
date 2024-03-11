import 'package:flutter/services.dart';

class SensoriaApi {
  static const MethodChannel _platform = MethodChannel('com.example.healthywear/sensoria');

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
      await _platform.invokeMethod('scanAndConnectToSensoriaDevice', {'coreIndex': coreIndex});
    } catch (e) {
      print("Failed to initiate scan and connect with core $coreIndex: $e");
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

///////////////////////
}
