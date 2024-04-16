import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'StatusChecker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<NotificationInfo> sentNotifications = [];

  ////////MetaWear times////////////////////////
  int notification_IntervalMinutes_MMR_SensorFusion = 20;
  int notification_IntervalMinutes_MMR_Temperature = 180;
  int notification_IntervalMinutes_MMR_AmbientLight = 120;
  int notification_IntervalMinutes_MMR_WriteFile = 30;
  ////////Sensoria times////////////////////////
  int notification_IntervalMinutes_Sensoria = 20;
  int notification_IntervalMinutes_Sensoria_WriteFile = 30;
  ////////SmartBand times////////////////////////
  int notification_IntervalMinutes_SmartBand_HR = 100;
  int notification_IntervalMinutes_SmartBand_BP = 130;
  int notification_IntervalMinutes_SmartBand_Step = 120;
  int notification_IntervalMinutes_SmartBand_WriteFile = 40;
  ////////Uploader times////////////////////////
  int notification_IntervalMinutes_Upload = 120;

  static String locale = "en";

  static void setLocale(String code) {
    locale = code;
  }

  NotificationHandler() {
    _initializeNotifications();
  }

  Future<int> countFilesInUploadDirectory() async {
    final directory = await getExternalStorageDirectory(); // Adjust if your files are elsewhere
    final fileList = directory!.listSync().where((file) => file.path.endsWith('.gz')).toList();
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
        }
        break;
      case "Sensoria":
        switch (activityName) {
          case "Sensoria data reception":
            return Duration(minutes: notification_IntervalMinutes_Sensoria);
          case "Sensoria writing to file":
            return Duration(minutes: notification_IntervalMinutes_Sensoria_WriteFile);
        }
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
        }
        break;
      case "Uploader":
        switch (activityName) {
          case "Uploading":
            return Duration(minutes: notification_IntervalMinutes_Upload);
        }
    }
    return Duration(minutes: 5);
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
    int fileCount = await countFilesInUploadDirectory();
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
          default:
            return "Failure in $activityName for MMR";
        }
      case "Sensoria":
        switch (activityName) {
          case "Sensoria data reception":
            return "Failure in sensor for Sock ${deviceIndex == 1 ? "Right" : "Left"}";
          case "Sensoria writing to file":
            return "Failure in writing to file for Sock ${deviceIndex == 1 ? "Right" : "Left"}";
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
          default:
            return "Failure in $activityName for Smart Band";
        }
      case "Uploader":
        return "There are $fileCount files pending delivery to the server. Check your Internet access.";
      default:
        return "Failure in $activityName for $deviceName";
    }
  }

  Future<String> _generateMessageEs(String deviceName, int deviceIndex, String activityName) async {
    int fileCount = await countFilesInUploadDirectory();
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
          default:
            return "Fallo en $activityName para MMR";
        }
      case "Sensoria":
        switch (activityName) {
          case "Sensoria data reception":
            return "Fallo en el sensor para el Calcetín ${deviceIndex == 1 ? "Derecho" : "Izquierdo"}";
          case "Sensoria writing to file":
            return "Fallo en la escritura al archivo para el Calcetín ${deviceIndex == 1 ? "Derecho" : "Izquierdo"}";
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
          default:
            return "Fallo en $activityName para la Pulsera Inteligente";
        }
      case "Uploader":
        return "Hay $fileCount ficheros pendientes de entrega al servidor. Compruebe su acceso a Internet. ";
      default:
        return "Fallo en $activityName para $deviceName";
    }
  }

  void _initializeNotifications() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _sendNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'fail_channel', 'fail_channel',
        importance: Importance.high, priority: Priority.high, ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }
}
