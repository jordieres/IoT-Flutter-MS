import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepoo_sdk/veepoo_sdk.dart';

void main() {
  const MethodChannel channel = MethodChannel('veepoo_sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Directly pass the channel to setMockMethodCallHandler
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    // Directly pass the channel to setMockMethodCallHandler and set it to null for teardown
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await VeepooSdk.platformVersion, '42');
  });
}
