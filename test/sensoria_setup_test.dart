import 'package:HealthyWear/sensoria_setup_screen.dart';
import 'package:HealthyWear/Api/SensoriaApi.dart';
import 'package:HealthyWear/healthywear_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'settings show the selected Core readings and calibrate that sock',
      (tester) async {
    void report(int slot, String status, [Map<String, int>? settings]) {
      SensoriaApi.handleConnectionUpdate({
        'coreIndex': slot,
        'status': status,
        'settings': settings,
      });
    }

    report(2, 'connected', {
      'accelerometerG': 8,
      'accelerometerHz': 104,
      'gyroscopeDps': 1000,
      'magnetometerGauss': 4,
      'magnetometerHz': 40,
    });
    addTearDown(() => report(2, 'disconnected'));
    const channel = MethodChannel('com.example.healthywear/sensoria');
    final calls = <int>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'calibrateMagnetometer');
      calls.add(call.arguments['coreIndex'] as int);
      return 'success';
    });
    Future<void> tap(String label) async {
      final action = find.text(label);
      await tester.ensureVisible(action);
      await tester.pump();
      await tester.tap(action);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pumpWidget(const MaterialApp(
      home: HealthyWearSettingsScreen(locale: Locale('en')),
    ));
    await tap('Sensoria socks');
    expect(
        tester.widgetList<ListTile>(find.byType(ListTile)).last.enabled, false);
    await tap('Left sock');
    expect(find.text('±8 g'), findsOneWidget);
    expect(find.text('104 Hz'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    await tap('Calibrate this sock');
    await tester.scrollUntilVisible(find.text('Start calibration'), 130,
        scrollable: find.byType(Scrollable).last);
    await tap('Start calibration');
    expect(find.text('Calibration successful'), findsOneWidget);
    expect(find.text('Start test'), findsNothing);
    expect(calls, [2]);
    await tap('Done');
    expect(find.text('±8 g'), findsOneWidget);
    report(2, 'disconnected');
    await tester.pump();
    expect(find.text('±8 g'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('calibration offsets use signed milligauss and the range of that Core',
      () {
    expect(SensoriaApi.evaluateOffsets([-12150, -5300, 5200], 4),
        SensoriaCalibrationStatus.suspect);
    expect(SensoriaApi.evaluateOffsets([100, -80, 250], 4),
        SensoriaCalibrationStatus.available);
    expect(SensoriaApi.evaluateOffsets(null, 4),
        SensoriaCalibrationStatus.unavailable);
    expect(SensoriaApi.evaluateOffsets([0, 0, 0], 4),
        SensoriaCalibrationStatus.available);
  });

  testWidgets('walking trial shows only progress and can be interrupted',
      (tester) async {
    const channel = MethodChannel('com.example.healthywear/sensoria');
    final captures = <bool>[];
    var sent = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setTrialCapture') {
        captures.add(call.arguments['enabled'] as bool);
        return null;
      }
      if (sent) return [];
      sent = true;
      return [
        [1, 262143, 18, 8, 4, '500,500,500,0,0,1,0,0,0,0,0,0,0'],
        [1, 1, 18, 8, 4, '460,500,500,0.2,0,1,0,0,0,0,0,0,0'],
        [2, 5, 24, 8, 4, '500,500,500,0,0,1,0,0,0,0,0,0,0'],
      ];
    });

    await tester.pumpWidget(MaterialApp(
      home: SensoriaSetupScreen(
        locale: const Locale('en'),
        connectedSlots: () => {1, 2},
      ),
    ));
    expect(find.text('Start'), findsNothing);
    expect(captures, isEmpty, reason: 'Opening instructions must leave the socks idle');
    await tester.ensureVisible(find.text('Go'));
    await tester.tap(find.text('Go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('readings'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(captures, [true, false]);
    expect(find.textContaining('Keep HealthyWear open'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final (label, motion, magnetic, expected) in [
    ('both socks pass', true, true, 'Start'),
    ('no pressure signal', false, true, 'Repeat trial'),
    ('slow gentle walk', true, true, 'Start'),
    ('gentle walk at ±16 g and 10 ms', true, true, 'Start'),
    ('gentle walk at ±2 g and 50 ms', true, true, 'Start'),
    ('clipping at ±2 g', true, true, 'Repeat trial'),
    ('light pressure below the contact threshold', true, true, 'Repeat trial'),
    ('socks on desk', true, true, 'Repeat trial'),
    ('desk noise and a single spike', true, true, 'Repeat trial'),
    (
      'one desk sock has pressure drift and movement',
      true,
      true,
      'Repeat trial'
    ),
    ('pressure changes but sock stays still', true, true, 'Repeat trial'),
    ('sensor issue takes priority', false, false, 'Repeat trial'),
    ('missing magnetic readings', true, false, 'Calibration'),
    ('stored left offset outside range', true, true, 'Calibration'),
  ]) {
    testWidgets(label, (tester) async {
      if (label == 'stored left offset outside range') {
        SensoriaApi.handleConnectionUpdate({
          'status': 'connected',
          'coreIndex': 2,
          'magnetometerGauss': 4,
          'magneticOffsets': [-12150, -5300, 5200],
        });
        addTearDown(() => SensoriaApi.handleConnectionUpdate({
              'status': 'disconnected',
              'coreIndex': 2,
            }));
      }
      const channel = MethodChannel('com.example.healthywear/sensoria');
      var sent = false;
      var calibrationAttempts = 0;
      final captureRequests = <bool>[];
      final calibratedSlots = <int>[];
      final gentle = label.contains('gentle walk');
      final accelRange = label.contains('±16')
          ? 16
          : label.contains('±2')
              ? 2
              : 8;
      final packetPeriod = label.contains('10 ms')
          ? 10
          : label.contains('50 ms')
              ? 50
              : 20;
      final baselinePackets = 100 ~/ packetPeriod;
      int pressureReading(int slot, int tick) {
        if (!motion && slot == 1) return 0;
        if (label == 'socks on desk') return 500;
        if (label == 'light pressure below the contact threshold') {
          return tick < 5 ? 500 : 495;
        }
        if (label == 'desk noise and a single spike') {
          return tick == 8 ? 450 : 500 + tick % 2;
        }
        if (label == 'one desk sock has pressure drift and movement' &&
            slot == 2) {
          return 500 - tick ~/ 7;
        }
        return tick < baselinePackets
            ? 500
            : gentle
                ? 494
                : 460;
      }

      double accelerationReading(int tick) {
        if (label == 'socks on desk' ||
            label == 'pressure changes but sock stays still') {
          return 0;
        }
        if (label == 'desk noise and a single spike') {
          return tick == 8 ? 0.2 : (tick % 2) / 64;
        }
        if (label == 'clipping at ±2 g' && tick > baselinePackets) {
          return 511 * 2 / 512;
        }
        return tick < baselinePackets
            ? 0
            : gentle
                ? 0.03125
                : 0.2;
      }

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'setRecording') {
          fail('A trial or calibration must never start recording');
        }
        if (call.method == 'setTrialCapture') {
          captureRequests.add(call.arguments['enabled'] as bool);
          return null;
        }
        if (call.method == 'calibrateMagnetometer') {
          if (label == 'missing magnetic readings') {
            calibratedSlots.add(call.arguments['coreIndex'] as int);
            return calibratedSlots.length == 2 ? 'retry' : 'success';
          }
          expect(call.arguments['coreIndex'], 2);
          calibrationAttempts++;
          return switch (calibrationAttempts) {
            1 => 'commandFailed',
            2 => 'retry',
            _ => 'success',
          };
        }
        if (sent) return [];
        sent = true;
        final field = magnetic ? '0.4' : '0';
        return [
          for (final slot in [1, 2])
            for (var tick = 0; tick < 40; tick++)
              [
                slot,
                tick,
                24,
                accelRange,
                4,
                packetPeriod,
                '${pressureReading(slot, tick)},500,500,${accelerationReading(tick)},0,1,$field,0,0,0,0,0,0',
              ],
        ];
      });
      await tester.pumpWidget(MaterialApp(
        home: SensoriaSetupScreen(
          locale: const Locale('en'),
          connectedSlots: () => {1, 2},
        ),
      ));
      await tester.ensureVisible(find.text('Go'));
      await tester.tap(find.text('Go'));
      await tester.pump();
      for (var i = 0; i < 19; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(expected), findsNothing);
      for (var i = 0; i < 2; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump();
      await tester.scrollUntilVisible(find.text(expected), 120);
      expect(find.text(expected), findsOneWidget);
      expect(captureRequests, [true, false],
          reason: 'Trial completion must pause Bluetooth before showing the result');
      if (label == 'missing magnetic readings') {
        Future<void> tapAction(String text) async {
          final action = find.text(text);
          await tester.scrollUntilVisible(action, 120);
          await tester.ensureVisible(action);
          await tester.pump();
          await tester.tap(action);
          await tester.pump();
        }

        await tapAction('Calibration');
        await tapAction('Start calibration');
        expect(find.text('Calibration successful'), findsOneWidget);
        expect(find.text('Left sock'), findsOneWidget);
        expect(find.text('Start test'), findsNothing);
        expect(calibratedSlots, [2]);
        await tapAction('Next sock');
        expect(find.text('Right sock'), findsOneWidget);
        expect(calibratedSlots, [2]);
        await tapAction('Start calibration');
        expect(find.text('Calibration failed'), findsOneWidget);
        expect(find.text('Right sock'), findsOneWidget);
        expect(find.text('Next sock'), findsNothing);
        await tapAction('Retry calibration');
        expect(find.text('Calibration successful'), findsOneWidget);
        expect(find.text('Right sock'), findsOneWidget);
        expect(find.text('Start test'), findsOneWidget);
        expect(calibratedSlots, [2, 1, 1]);
      }
      if (label == 'stored left offset outside range') {
        expect(find.textContaining('Left sock needs calibration.'),
            findsOneWidget);
        await tester.tap(find.text('Calibration'));
        await tester.pump();
        await tester.scrollUntilVisible(find.text('Start calibration'), 120);
        await tester.ensureVisible(find.text('Start calibration'));
        await tester.pump();
        await tester.tap(find.text('Start calibration'));
        await tester.pump();
        expect(find.text('The sock couldn’t start calibration. Try again.'),
            findsOneWidget);
        expect(find.text('Try again with wider turns.'), findsNothing);
        await tester.scrollUntilVisible(find.text('Retry calibration'), 120);
        await tester.ensureVisible(find.text('Retry calibration'));
        await tester.pump();
        await tester.tap(find.text('Retry calibration'));
        await tester.pump();
        expect(find.text('Try again with wider turns.'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Retry calibration'), 120);
        await tester.ensureVisible(find.text('Retry calibration'));
        await tester.pump();
        await tester.tap(find.text('Retry calibration'));
        await tester.pump();
        expect(find.text('Calibration successful'), findsOneWidget);
        expect(find.text('Put your socks back on.'), findsOneWidget);
      }
      if (label == 'socks on desk' ||
          label == 'desk noise and a single spike') {
        expect(
            find.textContaining('Left sock. Adjust the sock'), findsOneWidget);
        expect(
            find.textContaining('Right sock. Adjust the sock'), findsOneWidget);
      }
      if (label == 'one desk sock has pressure drift and movement') {
        expect(
            find.textContaining('Left sock. Adjust the sock'), findsOneWidget);
        expect(find.textContaining('Right sock.'), findsNothing);
      }
      if (label == 'pressure changes but sock stays still') {
        expect(
            find.textContaining('Left sock. Take a few steps'), findsOneWidget);
      }
      if (!motion) {
        expect(
            find.textContaining('Right sock. Adjust the sock'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('a native capture error is distinct from a disconnected sock',
      (tester) async {
    const channel = MethodChannel('com.example.healthywear/sensoria');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setTrialCapture' &&
          call.arguments['enabled'] == true) {
        throw MissingPluginException();
      }
      return null;
    });
    await tester.pumpWidget(MaterialApp(
      home: SensoriaSetupScreen(
        locale: const Locale('es'),
        connectedSlots: () => {2},
      ),
    ));
    final start = find.text('Vamos');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    expect(
        find.textContaining('No pudimos leer los calcetines'), findsOneWidget);
    expect(find.textContaining('perdió la conexión'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
