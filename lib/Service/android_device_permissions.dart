import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AndroidDevicePermissions {
  static const _service = MethodChannel('com.example.healthywear/service');
  static Future<bool>? _pending;

  static Future<bool> hasAccess() async =>
      await _service.invokeMethod<bool>('hasWearablePermissions') ?? false;

  static Future<bool> requestAccess() async {
    final request = _pending ??= _requestAccess();
    try {
      return await request;
    } finally {
      if (identical(_pending, request)) _pending = null;
    }
  }

  static Future<bool> _requestAccess() async {
    if (!await hasAccess()) {
      final sdk = await _service.invokeMethod<int>('getAndroidSdkInt');
      if (sdk == null) throw StateError('Android version unavailable');
      await [
        // The bundled Sensoria SDK requires precise location on every Android
        // version. permission_handler requests coarse and fine together.
        Permission.locationWhenInUse,
        if (sdk >= 31) ...[
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ],
      ].request();
    }
    // Check the actual Android grants. Approximate location alone cannot
    // initialize this Sensoria SDK.
    final granted = await hasAccess();
    if (granted) await _service.invokeMethod<void>('refreshPermissions');
    return granted;
  }

  static Future<void> requestNotifications() async {
    final sdk = await _service.invokeMethod<int>('getAndroidSdkInt');
    if (sdk != null && sdk >= 33) await Permission.notification.request();
  }
}
