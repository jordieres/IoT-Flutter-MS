import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'NotificationHandler.dart';
import 'Uploader.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    NotificationHandler notificationHandler = NotificationHandler();

    switch (task) {
      case 'checkUploadStatus':
        return await checkUploadStatus(notificationHandler);
      case 'uploadFiles':
        return await handleUploadFiles();
      default:
        print("Task not handled:-AMIR $task");
        return Future.value(false);
    }
  });
}

Future<bool> checkUploadStatus(NotificationHandler notificationHandler) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int lastUploadTime = prefs.getInt('lastUploadTimestamp') ?? 0;
  int currentTime = DateTime.now().millisecondsSinceEpoch;

  if ((currentTime - lastUploadTime) > 300000) {
    // 1800000 milliseconds = 30 minutes
    final directory = await getExternalStorageDirectory();
    final files = directory!.listSync().where((item) => item.path.endsWith('.gz'));

    if (files.isNotEmpty) {
      print("notifi checker-------AMIR");
      notificationHandler.checkAndSendNotification("Uploader", 0, "Uploading");
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
