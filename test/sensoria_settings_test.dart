import 'dart:convert';
import 'dart:io';

import 'package:HealthyWear/Api/SensoriaSettings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('published seed matches the app fallback', () {
    final seed = File('server/sensoria-settings.json').readAsStringSync();
    expect(SensoriaSettings.parse(seed), SensoriaSettings.defaults);
  });

  test('accepts a new revision with supported ranges', () {
    final next = {
      ...SensoriaSettings.defaults,
      'revision': 2,
      'accelerometerG': 16,
      'gyroscopeDps': 500,
      'magnetometerGauss': 8,
    };
    expect(SensoriaSettings.parse(jsonEncode(next)), next);
  });

  test('accepts supported rates and a stream period independently', () {
    final settings = {
      ...SensoriaSettings.defaults,
      'accelerometerHz': 104,
      'gyroscopeHz': 104,
      'magnetometerHz': 40,
      'streamPeriodMs': 20,
    };
    expect(SensoriaSettings.parse(jsonEncode(settings)), settings);
  });

  test('rejects values that must never reach a sensor write', () {
    for (final invalid in <Map<String, Object>>[
      {'schemaVersion': 2},
      {'schemaVersion': 1.0},
      {'revision': 0},
      {'accelerometerG': 3},
      {'gyroscopeDps': '1000'},
      {'magnetometerGauss': 4.0},
      {'magnetometerHz': 104},
      {'accelerometerHz': '104'},
      {'streamPeriodMs': 1},
    ]) {
      final body = jsonEncode({...SensoriaSettings.defaults, ...invalid});
      expect(() => SensoriaSettings.parse(body), throwsFormatException);
    }
  });
}
