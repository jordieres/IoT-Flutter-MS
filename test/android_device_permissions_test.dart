import 'dart:async';

import 'package:HealthyWear/Service/android_device_permissions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = MethodChannel('com.example.healthywear/service');
  const permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(service, null);
    messenger.setMockMethodCallHandler(permissions, null);
  });

  for (final sdk in [24, 30, 31, 36]) {
    test('Android $sdk requests the permissions supported on that phone',
        () async {
      var granted = false;
      final requests = <List<int>>[];
      var refreshes = 0;
      messenger.setMockMethodCallHandler(service, (call) async {
        switch (call.method) {
          case 'getAndroidSdkInt':
            return sdk;
          case 'hasWearablePermissions':
            return granted;
          case 'refreshPermissions':
            refreshes++;
            return null;
        }
        return null;
      });
      messenger.setMockMethodCallHandler(permissions, (call) async {
        if (call.method == 'requestPermissions') {
          final requested = List<int>.from(call.arguments as List);
          requests.add(requested);
          granted = true;
          return {for (final permission in requested) permission: 1};
        }
        return 1;
      });
      expect(await AndroidDevicePermissions.requestAccess(), isTrue);
      expect(requests, [
        sdk >= 31 ? [5, 28, 30] : [5]
      ]);
      expect(refreshes, 1);
    });
  }

  test('two sock taps share a single permission request', () async {
    var granted = false;
    var requests = 0;
    final reply = Completer<Map<int, int>>();
    messenger.setMockMethodCallHandler(service, (call) async {
      if (call.method == 'getAndroidSdkInt') return 36;
      if (call.method == 'hasWearablePermissions') return granted;
      return null;
    });
    messenger.setMockMethodCallHandler(permissions, (call) async {
      if (call.method == 'requestPermissions') {
        requests++;
        final result = await reply.future;
        granted = true;
        return result;
      }
      return 0;
    });

    final left = AndroidDevicePermissions.requestAccess();
    final right = AndroidDevicePermissions.requestAccess();
    reply.complete({5: 1, 28: 1, 30: 1});
    expect(await left, isTrue);
    expect(await right, isTrue);
    expect(requests, 1);
  });

  test('approximate access does not pass the SDK precise location check',
      () async {
    var refreshes = 0;
    messenger.setMockMethodCallHandler(service, (call) async {
      if (call.method == 'getAndroidSdkInt') return 36;
      if (call.method == 'hasWearablePermissions') return false;
      if (call.method == 'refreshPermissions') refreshes++;
      return null;
    });
    messenger.setMockMethodCallHandler(permissions, (call) async {
      if (call.method == 'requestPermissions') {
        return {5: 1, 28: 1, 30: 1};
      }
      return 1;
    });
    expect(await AndroidDevicePermissions.requestAccess(), isFalse);
    expect(refreshes, 0);
  });

  test('denying notifications does not block device access', () async {
    messenger.setMockMethodCallHandler(service, (call) async {
      if (call.method == 'getAndroidSdkInt') return 36;
      if (call.method == 'hasWearablePermissions') return true;
      return null;
    });
    messenger.setMockMethodCallHandler(permissions, (call) async {
      expect(call.method, 'requestPermissions');
      expect(call.arguments, [17]);
      return {17: 0};
    });
    await AndroidDevicePermissions.requestNotifications();
    expect(await AndroidDevicePermissions.requestAccess(), isTrue);
  });
}
