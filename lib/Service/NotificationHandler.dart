import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'StatusChecker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// BACKGROUND TAP HANDLER (must be top-level for v19)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Runs in a background isolate when the app is terminated/backgrounded
  // TODO: handle deep links, route navigation, analytics, etc.
}

class NotificationInfo {
  String deviceName;
  int deviceIndex;
  String activityName;
  DateTime lastNotificationTime;

  NotificationInfo({
    required this.deviceName,
    required this.deviceIndex,
    required this.activityName,
    required this.lastNotificationTime,
  });
}

class NotificationHandler {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<NotificationInfo> sentNotifications = [];

  ////////MetaWear times////////////////////////
  int notification_IntervalMinutes_MMR_SensorFusion = 20;
  int notification_IntervalMinutes_MMR_Temperature = 180;
  int notification_IntervalMinutes_MMR_AmbientLight = 120;
  int notification_IntervalMinutes_MMR_WriteFile = 30;
  int notification_IntervalMinutes_MMR_Battery = 25;
  ////////Sensoria times////////////////////////
  int notification_IntervalMinutes_Sensoria = 20;
  int notification_IntervalMinutes_Sensoria_WriteFile = 30;
  int notification_IntervalMinutes_Sensoria_Battery = 25;
  ////////SmartBand times////////////////////////
  int notification_IntervalMinutes_SmartBand_HR = 100;
  int notification_IntervalMinutes_SmartBand_BP = 130;
  int notification_IntervalMinutes_SmartBand_Step = 120;
  int notification_IntervalMinutes_SmartBand_WriteFile = 40;
  int notification_IntervalMinutes_SmartBand_Battery = 20;

  ////////Uploader times////////////////////////
  int notification_IntervalMinutes_Upload = 120;

  ////////  interval for Mobile Device
  int notification_IntervalMinutes_MobileDevice_Battery = 30;

  static String locale = "en";

  static void setLocale(String code) {
    locale = code;
  }

  NotificationHandler() {
    _initializeNotifications();
  }

  Future<int> countFilesInUploadDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      // No directory for this platform
      return 0;
    }

    final fileList = directory.listSync().where((file) => file.path.endsWith('.gz')).toList();
    return fileList.length;
  }

  void checkAndSendNotification(String deviceName, int deviceIndex, String activityName) async {
    final now = DateTime.now();
    final Duration specificInterval = _getNotificationInterval(deviceName, activityName);
    final notificationIndex = sentNotifications.indexWhere(
      (n) =>
          n.deviceName == deviceName &&
          n.deviceIndex == deviceIndex &&
          n.activityName == activityName,
    );

    if (notificationIndex == -1 ||
        now.difference(sentNotifications[notificationIndex].lastNotificationTime) >
            specificInterval) {
      String title = _generateTitle(deviceName, activityName);
      String message = await _generateMessage(deviceName, deviceIndex, activityName);

      _sendNotification(title, message);

      if (notificationIndex == -1) {
        sentNotifications.add(NotificationInfo(
          deviceName: deviceName,
          deviceIndex: deviceIndex,
          activityName: activityName,
          lastNotificationTime: now,
        ));
      } else {
        sentNotifications[notificationIndex].lastNotificationTime = now;
      }
    }
  }

  Duration _getNotificationInterval(String deviceName, String activityName) {
    switch (deviceName) {
      case "MetaWear":
        switch (activityName) {
          case "Sensor Fusion data reception":
            return Duration(minutes: notification_IntervalMinutes_MMR_SensorFusion);
          case "Temperature data reception":
            return Duration(minutes: notification_IntervalMinutes_MMR_Temperature);
          case "Ambient light data reception":
            return Duration(minutes: notification_IntervalMinutes_MMR_AmbientLight);
          case "Writing to file":
            return Duration(minutes: notification_IntervalMinutes_MMR_WriteFile);
          case "Battery Warning":
            return Duration(minutes: notification_IntervalMinutes_MMR_Battery);
        }
        break;
      case "Sensoria":
        switch (activityName) {
          case "Sensoria data reception":
            return Duration(minutes: notification_IntervalMinutes_Sensoria);
          case "Sensoria writing to file":
            return Duration(minutes: notification_IntervalMinutes_Sensoria_WriteFile);
          case "Battery Warning":
            return Duration(minutes: notification_IntervalMinutes_Sensoria_Battery);
        }
        break;
      case "SmartBand":
        switch (activityName) {
          case "HR data reception":
            return Duration(minutes: notification_IntervalMinutes_SmartBand_HR);
          case "BP data reception":
            return Duration(minutes: notification_IntervalMinutes_SmartBand_BP);
          case "Step data reception":
            return Duration(minutes: notification_IntervalMinutes_SmartBand_Step);
          case "Data writing to file":
            return Duration(minutes: notification_IntervalMinutes_SmartBand_WriteFile);
          case "Battery Warning":
            return Duration(minutes: notification_IntervalMinutes_SmartBand_Battery);
        }
        break;
      case "Uploader":
        if (activityName == "Uploading") {
          return Duration(minutes: notification_IntervalMinutes_Upload);
        }
        break;
      case "Mobile Device":
        if (activityName == "Battery Warning") {
          return Duration(minutes: notification_IntervalMinutes_MobileDevice_Battery);
        }
        break;
      default:
        return const Duration(minutes: 30);
    }
    return const Duration(minutes: 30);
  }

  String _generateTitle(String deviceName, String activityName) {
    if (locale == "en") {
      switch (deviceName) {
        case "MetaWear":
          return "MMR Alert";
        case "Sensoria":
          return "Socks Alert";
        case "SmartBand":
          return "Smart Band Alert";
        case "Uploader":
          return "Failure in Data Delivery to the Server";
        case "Mobile Device":
          return "Battery Alert";
        default:
          return "$deviceName Alert";
      }
    } else if (locale == "es") {
      switch (deviceName) {
        case "MetaWear":
          return "Alerta de MMR";
        case "Sensoria":
          return "Alerta de Calcetines";
        case "SmartBand":
          return "Alerta de Pulsera Inteligente";
        case "Uploader":
          return "Fallo en la Entrega de datos al Servidor";
        case "Mobile Device":
          return "Alerta de Batería";
        default:
          return "Alerta de $deviceName";
      }
    }
    return "$deviceName Notification";
  }

  Future<String> _generateMessage(String deviceName, int deviceIndex, String activityName) async {
    if (locale == "en") {
      return _generateMessageEn(deviceName, deviceIndex, activityName);
    } else if (locale == "es") {
      return _generateMessageEs(deviceName, deviceIndex, activityName);
    }
    return "Action required for $activityName.";
  }

  Future<String> _generateMessageEn(String deviceName, int deviceIndex, String activityName) async {
    final fileCount = await countFilesInUploadDirectory();
    switch (deviceName) {
      case "MetaWear":
        switch (activityName) {
          case "Sensor Fusion data reception":
            return "Failure in Fusion sensor for MMR ${deviceIndex == 1 ? "Right" : "Left"}";
          case "Temperature data reception":
            return "Failure in Temperature Sensor in MMR ${deviceIndex == 1 ? "Right" : "Left"}";
          case "Ambient light data reception":
            return "Failure in Light sensor for MMR ${deviceIndex == 1 ? "Right" : "Left"}";
          case "Writing to file":
            return "Failure in Writing to file for MMR ${deviceIndex == 1 ? "Right" : "Left"}";
          case "Battery Warning":
            return "Battery is low in MMR  ${deviceIndex == 1 ? "Right" : "Left"}";
          default:
            return "Failure in $activityName for MMR";
        }
      case "Sensoria":
        switch (activityName) {
          case "Sensoria data reception":
            return "Failure in sensor for Sock ${deviceIndex == 1 ? "Right" : "Left"}";
          case "Sensoria writing to file":
            return "Failure in writing to file for Sock ${deviceIndex == 1 ? "Right" : "Left"}";
          case "Battery Warning":
            return "Battery is low in Sock  ${deviceIndex == 1 ? "Right" : "Left"}";
          default:
            return "Failure in $activityName for Sensoria";
        }
      case "SmartBand":
        switch (activityName) {
          case "HR data reception":
            return "Failure in Heart rate sensor for Smart Band";
          case "BP data reception":
            return "Failure in Blood pressure sensor for Smart Band";
          case "Step data reception":
            return "Failure in Steps sensor for Smart Band";
          case "Data writing to file":
            return "Failure in Writing to file for Smart Band";
          case "Battery Warning":
            return "Battery is low in  Smart Band";
          default:
            return "Failure in $activityName for Smart Band";
        }
      case "Uploader":
        return "There are $fileCount files pending delivery to the server. Check your Internet access.";
      case "Mobile Device":
        return "Your phone battery is low ";
      default:
        return "Failure in $activityName for $deviceName";
    }
  }

  Future<String> _generateMessageEs(String deviceName, int deviceIndex, String activityName) async {
    final fileCount = await countFilesInUploadDirectory();
    switch (deviceName) {
      case "MetaWear":
        switch (activityName) {
          case "Sensor Fusion data reception":
            return "Fallo en el sensor de Fusión para MMR ${deviceIndex == 1 ? "Derecho" : "Izquierdo"}";
          case "Temperature data reception":
            return "Fallo en el sensor de Temperatura para MMR ${deviceIndex == 1 ? "Derecho" : "Izquierdo"}";
          case "Ambient light data reception":
            return "Fallo en el sensor de Luz para MMR ${deviceIndex == 1 ? "Derecho" : "Izquierdo"}";
          case "Writing to file":
            return "Fallo en la escritura al archivo para MMR ${deviceIndex == 1 ? "Derecho" : "Izquierdo"}";
          case "Battery Warning":
            return "La batería está baja en MMR  ${deviceIndex == 1 ? "Right" : "Left"}";
          default:
            return "Fallo en $activityName para MMR";
        }
      case "Sensoria":
        switch (activityName) {
          case "Sensoria data reception":
            return "Fallo en el sensor para el Calcetín ${deviceIndex == 1 ? "Derecho" : "Izquierdo"}";
          case "Sensoria writing to file":
            return "Fallo en la escritura al archivo para el Calcetín ${deviceIndex == 1 ? "Derecho" : "Izquierdo"}";
          case "Battery Warning":
            return "La batería está baja en el Calcetín  ${deviceIndex == 1 ? "Right" : "Left"}";
          default:
            return "Fallo en $activityName para Sensoria";
        }
      case "SmartBand":
        switch (activityName) {
          case "HR data reception":
            return "Fallo en el sensor de Ritmo Cardíaco para la Pulsera Inteligente";
          case "BP data reception":
            return "Fallo en el sensor de Presión Arterial para la Pulsera Inteligente";
          case "Step data reception":
            return "Fallo en el sensor de Pasos para la Pulsera Inteligente";
          case "Data writing to file":
            return "Fallo en la escritura al archivo para la Pulsera Inteligente";
          case "Battery Warning":
            return "La batería está baja en la Pulsera Inteligente";
          default:
            return "Fallo en $activityName para la Pulsera Inteligente";
        }
      case "Uploader":
        return "Hay $fileCount ficheros pendientes de entrega al servidor. Compruebe su acceso a Internet. ";
      case "Mobile Device":
        return "La batería de su teléfono está baja ";
      default:
        return "Fallo en $activityName para $deviceName";
    }
  }

  Future<void> _sendNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'fail_channel', // channel id
        'fail_channel', // channel name
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        // iOS uses default presentation unless you set per-notification flags or categories actions
      );

      await flutterLocalNotificationsPlugin.show(0, title, body, details);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to send notification: $e');
    }
  }

  /// v19-compatible initialization
  Future<void> _initializeNotifications() async {
    // ANDROID
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('ic_notification'); // ensure this exists

    // iOS/macOS (Darwin) — NO onDidReceiveLocalNotification in v19
    final DarwinInitializationSettings initDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          'demoCategory',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain('id_1', 'Action 1'),
            DarwinNotificationAction.plain(
              'id_2',
              'Action 2',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
          options: {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
        ),
      ],
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // (Optional) Explicitly ask iOS for permissions
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // (Optional macOS)
    // await flutterLocalNotificationsPlugin
    //     .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
    //     ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _onDidReceiveNotificationResponse(NotificationResponse response) async {
    // Foreground tap handler
    // You can inspect: response.actionId, response.payload, response.notificationResponseType
    // TODO: route user or handle action IDs ('id_1', 'id_2', etc.)
  }
}
