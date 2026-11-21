import 'package:HealthyWear/Api/SensoriaApi.dart';
import 'package:HealthyWear/enums/device_connection_status.dart';
import 'package:HealthyWear/main.dart';
import 'package:HealthyWear/sensoria_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const startupService = MethodChannel('com.example.healthywear/service');
  const startupPermissions =
      MethodChannel('flutter.baseflow.com/permissions/methods');
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(startupService, (call) async {
      if (call.method == 'getAndroidSdkInt') return 36;
      if (call.method == 'hasWearablePermissions') return true;
      return null;
    });
    messenger.setMockMethodCallHandler(startupPermissions, (call) async {
      if (call.method == 'requestPermissions') {
        return {for (final permission in call.arguments as List) permission: 1};
      }
      return 1;
    });
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(startupService, null);
    messenger.setMockMethodCallHandler(startupPermissions, null);
  });

  testWidgets('HealthyWear opens Sensoria settings from the home screen',
      (tester) async {
    await tester.pumpWidget(MyApp(initialLocale: const Locale('en')));

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Sensoria socks'), findsOneWidget);
  });

  testWidgets('device cards fit large Spanish text with the keyboard open',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(MyApp(initialLocale: const Locale('es')));
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(TextField).first);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(find.text('Calcetín dcho'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Spanish trial button fits Vamos on one line',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(
      home: SensoriaSetupScreen(
        locale: const Locale('es'),
        connectedSlots: () => {1},
      ),
    ));
    final label = tester.widget<Text>(find.text('Vamos'));
    expect(label.maxLines, 1);
    expect(label.softWrap, isFalse);
    expect(
        find.ancestor(
          of: find.text('Vamos'),
          matching: find.byType(ElevatedButton),
        ),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the splash shows the UPM credit before the home screen',
      (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'HealthyWear',
      packageName: 'com.upm.healthywear',
      version: '3.0.0',
      buildNumber: '29',
      buildSignature: '',
    );
    await tester.pumpWidget(const SplashApp(initialLocale: Locale('es')));
    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('Wear'), findsOneWidget);
    expect(find.text('Designed by:'), findsOneWidget);
    expect(find.bySemanticsLabel('Universidad Politécnica de Madrid'),
        findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('Iniciar opens the walking trial with both socks connected',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const sensoria = MethodChannel('com.example.healthywear/sensoria');
    const metawear = MethodChannel('com.example.healthywear/metawear');
    final captureRequests = <bool>[];
    messenger.setMockMethodCallHandler(sensoria, (call) async {
      if (call.method == 'getBatteryLevel') return 100;
      if (call.method == 'setTrialCapture') {
        captureRequests.add(call.arguments['enabled'] as bool);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(metawear, (_) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(sensoria, null));
    addTearDown(() => messenger.setMockMethodCallHandler(metawear, null));

    await tester.pumpWidget(const SplashApp(initialLocale: Locale('es')));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    const reference = 'TRIAL';
    await tester.enterText(find.byType(TextField).at(0), reference);
    await tester.enterText(
        find.byType(TextField).at(1), getChkSum(reference).toString());
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    SensoriaApi.updateLeftFootConnectionStatus(
        DeviceConnectionStatus.connected);
    SensoriaApi.updateRightFootConnectionStatus(
        DeviceConnectionStatus.connected);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Conectado'), findsNWidgets(2));

    await tester.ensureVisible(find.text('Iniciar'));
    await tester.tap(find.text('Iniciar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final trial =
        tester.widget<SensoriaSetupScreen>(find.byType(SensoriaSetupScreen));
    expect(trial.connectedSlots(), {1, 2});
    expect(captureRequests, isEmpty);

    await tester.ensureVisible(find.text('Vamos'));
    await tester.tap(find.text('Vamos'));
    await tester.pump();
    expect(captureRequests, [true]);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(captureRequests, [true, false]);
  });

  testWidgets('Android asks for access after the localized home route is ready',
      (tester) async {
    var granted = false;
    final requests = <List<int>>[];
    const service = MethodChannel('com.example.healthywear/service');
    const permissions =
        MethodChannel('flutter.baseflow.com/permissions/methods');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(service, (call) async {
      switch (call.method) {
        case 'getAndroidSdkInt':
          return 36;
        case 'hasWearablePermissions':
          return granted;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(permissions, (call) async {
      if (call.method == 'requestPermissions') {
        final requested = List<int>.from(call.arguments as List);
        requests.add(requested);
        if (requested.contains(5)) granted = true;
        return {for (final permission in requested) permission: 1};
      }
      return 1;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(service, null));
    addTearDown(() => messenger.setMockMethodCallHandler(permissions, null));

    await tester.pumpWidget(const SplashApp(initialLocale: Locale('es')));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Se necesitan permisos'), findsOneWidget);
    expect(requests, isEmpty);
    await tester.tap(find.text('Sí'));
    await tester.pumpAndSettle();

    expect(requests, [
      [5, 28, 30],
      [17],
    ]);
    expect(find.text('Activa los permisos'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Android offers Settings when the required access stays denied',
      (tester) async {
    const service = MethodChannel('com.example.healthywear/service');
    const permissions =
        MethodChannel('flutter.baseflow.com/permissions/methods');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final requests = <List<int>>[];
    messenger.setMockMethodCallHandler(service, (call) async {
      if (call.method == 'getAndroidSdkInt') return 36;
      if (call.method == 'hasWearablePermissions') return false;
      return null;
    });
    messenger.setMockMethodCallHandler(permissions, (call) async {
      if (call.method == 'requestPermissions') {
        final requested = List<int>.from(call.arguments as List);
        requests.add(requested);
        return {for (final permission in requested) permission: 4};
      }
      return 0;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(service, null));
    addTearDown(() => messenger.setMockMethodCallHandler(permissions, null));

    await tester.pumpWidget(MyApp(initialLocale: const Locale('es')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí'));
    await tester.pumpAndSettle();

    expect(requests, [
      [5, 28, 30]
    ]);
    expect(find.text('Abrir ajustes'), findsOneWidget);
    expect(find.text('Activa los permisos'), findsOneWidget);
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
