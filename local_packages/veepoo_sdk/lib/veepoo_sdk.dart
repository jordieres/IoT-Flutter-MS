import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:veepoo_sdk/model/ecg_data.dart';
import 'package:veepoo_sdk/model/hrv_origin_data.dart';
import 'package:veepoo_sdk/model/origin_v0_data.dart';
import 'package:veepoo_sdk/model/origin_v3_data.dart';
import 'package:veepoo_sdk/model/search_result.dart';
import 'package:veepoo_sdk/model/sleep_data.dart';
import 'package:veepoo_sdk/model/spo2h_origin_data.dart';

enum VeepooSdkEvent {
  REALTIME_HR_MEASUREMENT,
  REALTIME_SPO2_MEASUREMENT,
}

class VeepooSdk {
  static const MethodChannel _channel = const MethodChannel('veepoo/command');
  static const EventChannel _event_channel = const EventChannel('veepoo/event');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static EventChannel eventChannel() {
    return _event_channel;
  }

  // ----------------------------------------------------------------------------------------------
  // Scan device

  /// Start scan Veepoo BLE device in 6s
  /// Return list mac address of devices
  // static Future<List<SearchResult>> scanDevice() async {
  //   final List<dynamic> devices =
  //       await (_channel.invokeMethod('scanDevice') as FutureOr<List<dynamic>>);
  //
  //   List<SearchResult> deviceList = <SearchResult>[]; // Updated
  //
  //   devices.forEach((element) {
  //     String? name = element["name"];
  //     String? mac = element["mac"];
  //     int? rssi = element["rssi"];
  //
  //     SearchResult searchResult =
  //         SearchResult(name, mac, rssi); // Removed 'new'
  //
  //     deviceList.add(searchResult);
  //   });
  //
  //   return deviceList;
  // }

  static Future<List<SearchResult>> scanDevice() async {
    final result = await _channel.invokeMethod('scanDevice');
    print('Raw scan result: $result'); // Debug: print raw result

    List<dynamic> devices;
    if (result is List<dynamic>) {
      devices = result;
    } else {
      print('Unexpected type for scan result: ${result.runtimeType}');
      return [];
    }

    print('Devices: $devices'); // Debug: print devices list

    return devices.map((deviceJson) {
      // Manually cast each map item
      Map<String, dynamic> castedMap =
          Map<String, dynamic>.from(deviceJson as Map);
      return SearchResult.fromJson(castedMap);
    }).toList();
  }

  /// Stop scan Veepoo BLE device
  static Future<Null> stopScanDevice() async {
    await _channel.invokeMethod('stopScanDevice');
  }

  /// Stop scan Veepoo BLE device
  static Future<Null> requestPermission() async {
    await _channel.invokeMethod('requestPermission');
  }

  // ----------------------------------------------------------------------------------------------
  // Connect to device
  static Future<bool?> connect(String? macAddress) async {
    return await _channel.invokeMethod('connect', {'macAddress': macAddress});
  }

  // Check connect status
  static Future<bool?> isConnected() async {
    return await _channel.invokeMethod('isConnected');
  }

  // Disconnect to device
  static Future<void> disconnect() async {
    await _channel.invokeMethod('disconnect');
  }

  // Authenticate with device
  static Future<bool?> bind(String password, bool is24h) async {
    return await _channel.invokeMethod(
        'confirmDevicePwd', {'password': password, 'is24h': is24h});
  }

  // Clear the device data
  static Future<int?> clearDeviceData() async {
    return await _channel.invokeMethod('clearDeviceData');
  }

  // Modify device password
  static Future<int?> modifyDevicePwd() async {
    return await _channel.invokeMethod('modifyDevicePwd');
  }

  // Read the device electricity
  static Future<int?> readBattery() async {
    return await _channel.invokeMethod('readBattery');
  }

  // Get device count_origin_protocol_version 0 or 3
  static Future<int?> getCountVersion() async {
    return await _channel.invokeMethod('getCountVersion');
  }

  static Future<int?> syncPersonInfo(
      bool isMale, int height, int weight, int age, int targetStep) async {
    return await _channel.invokeMethod('syncPersonInfo', {
      'isMale': isMale,
      'height': height,
      'weight': weight,
      'age': age,
      'targetStep': targetStep
    });
  }

  // ----------------------------------------------------------------------------------------------
  // Manual measurement

  static Future startDetectBP() async {
    await _channel.invokeMethod('startDetectBP');
  }

  static Future stopDetectBP() async {
    await _channel.invokeMethod('stopDetectBP');
  }

  static Future startDetectECG() async {
    return await _channel.invokeMethod('startDetectECG');
  }

  static Future stopDetectECG() async {
    await _channel.invokeMethod('stopDetectECG');
  }

  static Future startDetectHeart() async {
    await _channel.invokeMethod('startDetectHeart');
  }

  static Future stopDetectHeart() async {
    await _channel.invokeMethod('stopDetectHeart');
  }

  static Future startDetectSPO2H() async {
    await _channel.invokeMethod('startDetectSPO2H');
  }

  static Future stopDetectSPO2H() async {
    await _channel.invokeMethod('stopDetectSPO2H');
  }

  // ----------------------------------------------------------------------------------------------
  // Read data

  /// Read blood pressure setting data
  static Future readDetectBP() async {
    await _channel.invokeMethod('readDetectBP');
  }

  /// Read all HRV data
  static Future<List<HRVOriginData>> readHRVOrigin() async {
    String rawJson =
        await (_channel.invokeMethod('readHRVOrigin') as FutureOr<String>);
    List<dynamic> raw = jsonDecode(rawJson);

    List<HRVOriginData> data = <HRVOriginData>[]; // Updated

    raw.forEach((element) {
      data.add(HRVOriginData.fromJson(element));
    });

    return data;
  }

  /// If the data stored in the watch is 3 days,
  /// the original data is read, one every 5 minutes.
  /// The data includes step counting, heart rate, blood pressure, and exercise volume.
  static Future<OriginV0Data> readOriginData() async {
    String rawJson =
        await (_channel.invokeMethod('readOriginData') as FutureOr<String>);
    return OriginV0Data.fromJson(json.decode(rawJson));
  }

  static Future<OriginV3Data> readOrigin3Data() async {
    String rawJson =
        await (_channel.invokeMethod('readOrigin3Data') as FutureOr<String>);
    return OriginV3Data.fromJson(json.decode(rawJson));
  }

  /// Read apnea data
  static Future<int?> readSBBR() async {
    return await _channel.invokeMethod('readSBBR');
  }

  /// Get ECG data stored in the device
  static Future<List<EcgDetectResult>> readECGData() async {
    String rawJson =
        await (_channel.invokeMethod('readECGData') as FutureOr<String>);
    List<dynamic> raw = json.decode(rawJson);

    List<EcgDetectResult> data = <EcgDetectResult>[]; // Updated

    raw.forEach((element) {
      data.add(EcgDetectResult.fromJson(element));
    });

    return data;
  }

  /// Read all blood oxygen data
  static Future<List<Spo2hOriginData>> readSpo2hOrigin() async {
    String rawJson =
        await (_channel.invokeMethod('readSpo2hOrigin') as FutureOr<String>);
    List<dynamic> raw = json.decode(rawJson);

    List<Spo2hOriginData> data = <Spo2hOriginData>[]; // Updated

    raw.forEach((element) {
      data.add(Spo2hOriginData.fromJson(element));
    });

    return data;
  }

  /// Read sleep data
  static Future<List<SleepData>> readSleepData() async {
    String rawJson =
        await (_channel.invokeMethod('readSleepData') as FutureOr<String>);
    List<dynamic> raw = json.decode(rawJson);

    List<SleepData> data = <SleepData>[]; // Updated

    raw.forEach((element) {
      data.add(SleepData.fromJson(element));
    });

    return data;
  }

  /// Read all blood oxygen data
  static Future<Null> sdkTest() async {
    return await _channel.invokeMethod('sdkTest');
  }

  static Future<Null> dummyTest() async {
    return await _channel.invokeMethod('dummyTest');
  }
}
