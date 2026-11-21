import '../Service/android_device_permissions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../enums/device_connection_status.dart';
import 'dart:io';
import 'SensoriaSettings.dart';

enum SensoriaCalibrationStatus { available, suspect, unavailable }

class SensoriaApi {
  static const MethodChannel _platform =
      MethodChannel('com.example.healthywear/sensoria');

  static Future<bool> setRecording(bool enabled) async =>
      await _platform
          .invokeMethod<bool>('setRecording', {'enabled': enabled}) ??
      false;

  static bool isRecording = false;
  static DateTime? recordingStartedAt;

  static Future<String> calibrateMagnetometer(int slot) async =>
      await _platform
          .invokeMethod<String>('calibrateMagnetometer', {'coreIndex': slot}) ??
      'unavailable';

  static Future<bool> hasRecordingData(int slot) async =>
      await _platform
          .invokeMethod<bool>('hasRecordingData', {'coreIndex': slot}) ??
      false;

  static Future<void> setTrialCapture(bool enabled) =>
      _platform.invokeMethod<void>('setTrialCapture', {'enabled': enabled});

  static Future<List<dynamic>> drainTrialSamples() async =>
      await _platform.invokeListMethod<dynamic>('drainTrialSamples') ?? [];

//connection Evenet listener----------------
  static const _connectionStatusChannel =
      EventChannel('com.example.healthywear/sensoria_connection_status');

  static bool _alreadyListening = false;
  static String _languageCode = '';
  static final _connectedSettings =
      ValueNotifier<Map<int, Map<String, int>>>({});
  static ValueListenable<Map<int, Map<String, int>>> get connectedSettings =>
      _connectedSettings;

  static final _calibrationStatuses = <int, SensoriaCalibrationStatus>{};

  static SensoriaCalibrationStatus calibrationStatus(int slot) =>
      _calibrationStatuses[slot] ?? SensoriaCalibrationStatus.unavailable;

  static SensoriaCalibrationStatus evaluateOffsets(
      Object? offsets, Object? range) {
    if (offsets case [int x, int y, int z]) {
      if (range is! int || range <= 0)
        return SensoriaCalibrationStatus.unavailable;
      // The vendor control-point UI reports signed offsets in milligauss.
      // An offset outside the selected range merits review on that sock.
      final limit = range * 1000;
      if (x.abs() >= limit || y.abs() >= limit || z.abs() >= limit) {
        return SensoriaCalibrationStatus.suspect;
      }
      return SensoriaCalibrationStatus.available;
    }
    return SensoriaCalibrationStatus.unavailable;
  }

  //callback for status checker////
  static Function(String, int, DeviceConnectionStatus)?
      onConnectionStatusChanged;

  static void setConnectionStatusListener(
      Function(String, int, DeviceConnectionStatus) callback) {
    onConnectionStatusChanged = callback;
  }
  ////////////////////////////

  static void handleConnectionUpdate(dynamic event) {
    final Map<dynamic, dynamic> statusUpdate = Map<String, dynamic>.from(event);
    final int coreIndex = statusUpdate["coreIndex"];
    if (statusUpdate['error'] case final String error) {
      final sock = _languageCode == 'es'
          ? (coreIndex == 1 ? 'derecho' : 'izquierdo')
          : (coreIndex == 1 ? 'right' : 'left');
      final message = switch (error) {
        'notFound' => _languageCode == 'es'
            ? 'No se encontró el sensor. Muévelo e inténtalo de nuevo.'
            : 'Sensor not found. Move it and try again.',
        'gyroscopeRange' => _languageCode == 'es'
            ? 'El calcetín $sock no pudo aplicar el rango del giroscopio. Avisa al equipo del estudio.'
            : 'The $sock sock could not apply its gyroscope range. Contact the study team.',
        'configuration' => _languageCode == 'es'
            ? 'No se pudo verificar el calcetín $sock. Pulsa su botón para reintentar.'
            : 'Could not verify the $sock sock. Tap its button to retry.',
        _ => _languageCode == 'es'
            ? 'El sensor no envió datos. Inténtalo de nuevo.'
            : 'The sensor did not send data. Try again.',
      };
      Fluttertoast.showToast(msg: message);
    }
    final status = switch (statusUpdate['status']) {
      'connected' => DeviceConnectionStatus.connected,
      'disconnected' => DeviceConnectionStatus.disconnected,
      'reconnecting' => DeviceConnectionStatus.reconnecting,
      'checking' => DeviceConnectionStatus.checkingSettings,
      'starting' => DeviceConnectionStatus.startingStream,
      _ => null,
    };
    if (status == null) return;
    if (status == DeviceConnectionStatus.connected) {
      _calibrationStatuses[coreIndex] = evaluateOffsets(
        statusUpdate['magneticOffsets'],
        statusUpdate['magnetometerGauss'],
      );
    } else {
      _calibrationStatuses.remove(coreIndex);
    }
    if (coreIndex == 1 || coreIndex == 2) {
      final connected = {..._connectedSettings.value};
      if (status == DeviceConnectionStatus.connected) {
        final settings = statusUpdate['settings'];
        connected[coreIndex] = Map.unmodifiable({
          if (settings is Map)
            for (final entry in settings.entries)
              if (entry.key is String && entry.value is int)
                entry.key as String: entry.value as int,
        });
      } else {
        connected.remove(coreIndex);
      }
      _connectedSettings.value = Map.unmodifiable(connected);
    }
    if (coreIndex == 1) {
      updateRightFootConnectionStatus(status);
    } else if (coreIndex == 2) {
      updateLeftFootConnectionStatus(status);
    } else {
      return;
    }
    if (status == DeviceConnectionStatus.connected ||
        status == DeviceConnectionStatus.disconnected) {
      onConnectionStatusChanged?.call('Sensoria', coreIndex, status);
    }
  }

  ///////////----------Send connection status
  static Function(DeviceConnectionStatus)? onRightFootConnectionStatusChange;

  static void updateRightFootConnectionStatus(DeviceConnectionStatus status) {
    onRightFootConnectionStatusChange?.call(status);
  }

  static Function(DeviceConnectionStatus)? onLeftFootConnectionStatusChange;

  static void updateLeftFootConnectionStatus(DeviceConnectionStatus status) {
    onLeftFootConnectionStatusChange?.call(status);
  }

  ////////////////////------------

  ///////check permissions and services-------------------------

  static final _ble = FlutterReactiveBle();

  static final Set<int> _pending = {};

  static Future<void> scanAndConnectWithCore(int coreIndex) async {
    if (!_pending.add(coreIndex)) return;
    final update = coreIndex == 1
        ? updateRightFootConnectionStatus
        : updateLeftFootConnectionStatus;
    try {
      if (!_alreadyListening) {
        _connectionStatusChannel.receiveBroadcastStream().listen(
              handleConnectionUpdate,
              onError: (Object error) => print('Sensoria status error: $error'),
            );
        _alreadyListening = true;
      }
      update(DeviceConnectionStatus.connecting);
      if (Platform.isAndroid &&
          !await AndroidDevicePermissions.requestAccess()) {
        throw PlatformException(code: 'PERMISSION_REQUIRED');
      }
      final status = await _ble.statusStream
          .firstWhere(
            (status) => status != BleStatus.unknown &&
                (!Platform.isAndroid || status != BleStatus.unauthorized),
          )
          .timeout(const Duration(seconds: 6));
      if (status != BleStatus.ready) {
        throw StateError('Bluetooth unavailable: $status');
      }
      final settings = await SensoriaSettings.load();
      await _platform.invokeMethod<void>('scanAndConnectToSensoriaDevice', {
        'coreIndex': coreIndex,
        'settings': settings,
      });
    } catch (error) {
      print('Sensoria setup could not start: $error');
      update(DeviceConnectionStatus.disconnected);
      final permissionsMissing =
          error is PlatformException && error.code == 'PERMISSION_REQUIRED';
      Fluttertoast.showToast(
        msg: permissionsMissing
            ? (_languageCode == 'es'
                ? 'Activa Ubicación precisa y Dispositivos cercanos en los ajustes de HealthyWear.'
                : 'Enable Precise location and Nearby devices in HealthyWear settings.')
            : (_languageCode == 'es'
                ? 'No se pudo iniciar la conexión. Comprueba que Bluetooth y Ubicación estén activados.'
                : 'Could not start the connection. Check that Bluetooth and Location are on.'),
      );
    } finally {
      _pending.remove(coreIndex);
    }
  }

  static Future<void> sendIdNumber(String refNumber) async {
    try {
      await _platform.invokeMethod('sendIdNumber', {'refNumber': refNumber});
    } on PlatformException catch (e) {
      print("Failed to send Id number: '${e.message}'.");
    }
  }

  static Future<void> sendAppVersion(String appVersion) async {
    await _platform.invokeMethod('sendAppVersion', {'appVersion': appVersion});
  }

  static Future<int> getBatteryLevelForDevice(int coreIndex) async {
    try {
      await Future.delayed(Duration(seconds: 1));

      final int batteryLevel = await _platform
          .invokeMethod('getBatteryLevel', {'coreIndex': coreIndex});
      print("sensoriaAPI-----Battery level----------------$batteryLevel");
      return batteryLevel;
    } on PlatformException catch (e) {
      print("Failed to get battery level: ${e.message}");
      return -1;
    }
  }

  //////////-------SET language-------------------------

  static Future<void> setLocale(String languageCode) async {
    try {
      await _platform.invokeMethod('setLocale', {'languageCode': languageCode});
      _languageCode = languageCode;
    } on PlatformException catch (e) {
      print("Failed to set locale on Android side: '${e.message}'.");
    }
  }

  ////////////////

  static Future<void> disconnectDevice(int coreIndex) async {
    try {
      await _platform
          .invokeMethod('disconnectDevice', {'coreIndex': coreIndex});
    } catch (e) {
      print("Failed to disconnect  with core $coreIndex: $e");
    }
  }

///////////////////////
}
