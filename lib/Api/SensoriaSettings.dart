import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SensoriaSettings {
  static const endpoint = String.fromEnvironment(
    'SENSORIA_SETTINGS_URL',
    defaultValue:
        'https://apiict03.etsii.upm.es/healthywear/sensoria-settings.json',
  );
  static const _cacheKey = 'sensoria.settings.v1';
  static Future<Map<String, int>>? _pending;
  static const defaults = {
    'schemaVersion': 1,
    'revision': 1,
    'accelerometerG': 8,
    'gyroscopeDps': 1000,
    'magnetometerGauss': 4,
  };

  // Zero means the study profile leaves the device's setting alone.
  static const optionalChoices = {
    'accelerometerHz': {0, 13, 26, 52, 104, 208, 416, 833, 1660},
    'gyroscopeHz': {0, 13, 26, 52, 104, 208, 416, 833, 1660},
    'magnetometerHz': {0, 5, 10, 20, 40, 80},
    'streamPeriodMs': {0, 10, 20, 25, 32, 40, 50, 100, 200},
  };

  static Map<String, int> parse(String body) {
    final data = jsonDecode(body);
    if (data is! Map<String, dynamic> ||
        data['schemaVersion'] is! int ||
        data['schemaVersion'] != 1 ||
        data['revision'] is! int ||
        (data['revision'] as int) < 1 ||
        data['accelerometerG'] is! int ||
        !{2, 4, 8, 16}.contains(data['accelerometerG']) ||
        data['gyroscopeDps'] is! int ||
        !{245, 500, 1000, 2000}.contains(data['gyroscopeDps']) ||
        data['magnetometerGauss'] is! int ||
        !{4, 8, 12, 16}.contains(data['magnetometerGauss'])) {
      throw const FormatException('Invalid Sensoria settings');
    }
    final settings = {for (final key in defaults.keys) key: data[key] as int};
    for (final entry in optionalChoices.entries) {
      if (!data.containsKey(entry.key)) continue;
      final value = data[entry.key];
      if (value is! int || !entry.value.contains(value)) {
        throw FormatException('Invalid Sensoria setting: ${entry.key}');
      }
      settings[entry.key] = value;
    }
    return settings;
  }

  static Future<Map<String, int>> load() async {
    final request = _pending ??= _load();
    try {
      return await request;
    } finally {
      if (identical(_pending, request)) _pending = null;
    }
  }

  static Future<Map<String, int>> _load() async {
    final preferences = await SharedPreferences.getInstance();
    var fallback = defaults;
    try {
      final cached = preferences.getString(_cacheKey);
      if (cached != null) fallback = parse(cached);
    } on FormatException {
      // Ignore a malformed cache and use the documented default.
    }
    final client = http.Client();
    try {
      final uri = Uri.parse(endpoint);
      if (uri.scheme != 'https' || uri.host.isEmpty) return fallback;
      final request = http.Request('GET', uri)..followRedirects = false;
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final settings = parse(response.body);
        await preferences.setString(_cacheKey, jsonEncode(settings));
        return settings;
      }
    } on Exception {
      // Bluetooth setup can continue with the last valid target while offline.
    } finally {
      client.close();
    }
    return fallback;
  }
}
