import 'package:flutter/services.dart';
import 'dart:async';

class ServiceApi {
  static const _platform = MethodChannel('com.example.healthywear/service');

  static Future<void> sendIdNumber(String refNumber) async {
    print("the idddddddddddd number received in service api from the main with the id ");
    try {
      await _platform.invokeMethod('sendIdNumber', {'refNumber': refNumber});
    } on PlatformException catch (e) {
      print("Failed to send Id ref number: '${e.message}'.");
    }
  }

  static Future<void> sendAppVersion(String appVersion) async {
    await _platform.invokeMethod('sendAppVersion', {'appVersion': appVersion});
  }
}
