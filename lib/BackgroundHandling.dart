import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'NotificationHandler.dart';
import 'Uploader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString('languageCode') ?? 'es';

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Initialize notification
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create a notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'upload_channel', // id
      'Data Upload Notifications', // title
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    switch (task) {
      case 'checkUploadStatus':
        return await checkUploadStatus(flutterLocalNotificationsPlugin, languageCode);
      case 'uploadFiles':
        return await handleUploadFiles();
      default:
        print("Task not handled:-AMIR $task");
        return Future.value(false);
    }
  });
}

Future<bool> checkUploadStatus(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin, String languageCode) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int lastUploadTime = prefs.getInt('lastUploadTimestamp') ?? 0;
  int currentTime = DateTime.now().millisecondsSinceEpoch;

  if ((currentTime - lastUploadTime) > 300000) {
    // 1800000 milliseconds = 30 minutes
    final directory = await getExternalStorageDirectory();
    final files = directory!.listSync().where((item) => item.path.endsWith('.gz'));
    int fileCount = files.length;

    if (files.isNotEmpty) {
      print("Notification checker: There are $fileCount files pending upload-AMIR.");
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: AndroidNotificationDetails(
          'upload_channel',
          'Uploads',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: false,
        ),
      );

      String title = (languageCode == "es")
          ? "Fallo en la Entrega de datos al Servidor"
          : "Failure in Data Delivery to the Server";
      String message = (languageCode == "es")
          ? "Hay $fileCount ficheros pendientes de entrega al servidor. Compruebe su acceso a Internet."
          : "There are $fileCount files pending delivery to the server. Check your Internet access.";

      await flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        title, // Title
        message, // Body
        platformChannelSpecifics,
      );
    }
  }
  return true;
}

Future<bool> handleUploadFiles() async {
  try {
    await Uploader.loadConfig();
    await Uploader.startUploading();
    print("Upload started after configuration is loaded.AMIR");
    return Future.value(true);
  } catch (e) {
    print("Error during -AMIR upload: $e");
    return Future.value(false);
  }
}

void initializeBackgroundTask() {
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  Workmanager().registerPeriodicTask("1", "checkUploadStatus", frequency: Duration(minutes: 16));
  Workmanager().registerPeriodicTask("2", "uploadFiles", frequency: Duration(minutes: 17));
  // Workmanager().registerOneOffTask("3", "uploadFilesTest");
  // Workmanager().registerOneOffTask("4", "checkUploadStatusTest");
}
