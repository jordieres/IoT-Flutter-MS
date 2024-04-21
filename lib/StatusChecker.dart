import 'dart:async';
// import 'dart:html';
import 'package:flutter/services.dart';
import 'enums/device_connection_status.dart';
import 'dart:convert';
import 'SmartBandApi.dart';
import 'Uploader.dart';
import 'NotificationHandler.dart';
import 'MetaWearApi.dart';
import 'SensoriaApi.dart';
import 'package:battery_plus/battery_plus.dart';

class StatusChecker {
  MethodChannel metaWearChannel = MethodChannel('com.example.healthywear/metawear');
  MethodChannel sensoriaChannel = MethodChannel('com.example.healthywear/sensoria');

  final notificationHandler = NotificationHandler();

  Battery _battery = Battery();

  Map<int, DeviceConnectionStatus> metaWearStatuses = {};
  Map<int, DeviceConnectionStatus> sensoriaStatuses = {};
  Map<int, DeviceConnectionStatus> smartbandstatuse = {};

  static Map<int, DateTime> deviceConnectedTime = {};

  static bool isSmartBandConnected = false;
  static bool isMetaWearError = false;

  static const int uploaderDeviceIndex = 0;

  ////////MetaWear times////////////////////////

  int Allowed_initialDelayMinutes_MMR_SensorFusion = 10;
  int Allowed_updateIntervalMinutes_MMR_SensorFusion = 15;

  int Allowed_initialDelayMinutes_MMR_Temperature = 25;
  int Allowed_updateIntervalMinutes_MMR_Temperature = 30;

  int Allowed_initialDelayMinutes_MMR_AmbientLight = 25;
  int Allowed_updateIntervalMinutes_MMR_AmbientLight = 30;

  int Allowed_initialDelayMinutes_MMR_WriteFile = 20;
  int Allowed_updateIntervalMinutes_MMR_WriteFile = 35;

  ////////Sensoria times////////////////////////
  int Allowed_initialDelayMinutes_Sensoria = 15;
  int Allowed_updateIntervalMinutes_Sensoria = 20;

  int Allowed_initialDelayMinutes_Sensoria_WriteFile = 20;
  int Allowed_updateIntervalMinutes_Sensoria_WriteFile = 30;

  ////////SmartBand times////////////////////////
  int Allowed_initialDelayMinutes_SmartBand_HR = 20;
  int Allowed_updateIntervalMinutes_SmartBand_HR = 30;

  int Allowed_initialDelayMinutes_SmartBand_BP = 20;
  int Allowed_updateIntervalMinutes_SmartBand_BP = 30;

  int Allowed_initialDelayMinutes_SmartBand_Step = 130;
  int Allowed_updateIntervalMinutes_SmartBand_Step = 130;

  int Allowed_initialDelayMinutes_SmartBand_WriteFile = 20;
  int Allowed_updateIntervalMinutes_SmartBand_WriteFile = 30;

  ////////Uploader times////////////////////////
  int Allowed_initialDelayMinutes_Upload = 20;
  int Allowed_updateIntervalMinutes_Upload = 30;

  StatusChecker() {
    Timer.periodic(Duration(minutes: 1), (Timer t) => requestStatusUpdates());
    initializeUploader();
  }

//////////////////Uploader////////////
  void initializeUploader() {
    deviceConnectedTime[uploaderDeviceIndex] = DateTime.now();
  }

  void onConnectionStatusUpdate(String deviceName, int deviceIndex, DeviceConnectionStatus status) {
    print("$deviceName device $deviceIndex status update: $status");

    if (deviceName == "MetaWear") {
      metaWearStatuses[deviceIndex] = status;
      if (deviceIndex == 1 && status == DeviceConnectionStatus.connected) {
        deviceConnectedTime[deviceIndex] = DateTime.now();
        Timer(Duration(minutes: 1), () => requestStatusUpdateForDevice("MetaWear", 1));
        print(
            "the request after 1 min is done for the $deviceIndex and $deviceName ---------------");
      } else {
        if (deviceIndex == 2 && status == DeviceConnectionStatus.connected) {
          deviceConnectedTime[deviceIndex] = DateTime.now();
          Timer(Duration(minutes: 1), () => requestStatusUpdateForDevice("MetaWear", 2));
          print(
              "the request after 1 min is done for the $deviceIndex and $deviceName ---------------");
        }
      }
    } else if (deviceName == "Sensoria") {
      sensoriaStatuses[deviceIndex] = status;
      if (deviceIndex == 1 && status == DeviceConnectionStatus.connected) {
        deviceConnectedTime[deviceIndex] = DateTime.now();
        Timer(Duration(minutes: 1), () => requestStatusUpdateForDevice("Sensoria", 1));
        print(
            "the request after 1 min is done for the $deviceIndex and $deviceName ---------------");
      } else {
        if (deviceIndex == 2 && status == DeviceConnectionStatus.connected) {
          deviceConnectedTime[deviceIndex] = DateTime.now();
          Timer(Duration(minutes: 1), () => requestStatusUpdateForDevice("Sensoria", 2));
          print(
              "the request after 1 min is done for the $deviceIndex and $deviceName ---------------");
        }
      }
    } else {
      //todo i checked no need to remove teh cooncteddevice to set the timer
    }
  }

  static void updateSmartBandStatus(DeviceConnectionStatus status) {
    print("Entered updateSmartBandStatus with status: $status");

    int deviceIndex = 1;
    deviceConnectedTime[deviceIndex] = DateTime.now();
    isSmartBandConnected = (status == DeviceConnectionStatus.connected);
    if (isSmartBandConnected) {
      print("SmartBand Connected. Will check status every minute...");
    } else {
      print("SmartBand Disconnected.");
    }
  }

  void requestStatusUpdates() {
    checkBatteryLevelAndNotify("Mobile Device", 0);

    metaWearStatuses.forEach((index, status) {
      if (status == DeviceConnectionStatus.connected) {
        requestStatusUpdateForDevice("MetaWear", index);
        checkBatteryLevelAndNotify("MetaWear", index);
      }
    });
    sensoriaStatuses.forEach((index, status) {
      if (status == DeviceConnectionStatus.connected) {
        requestStatusUpdateForDevice("Sensoria", index);
        checkBatteryLevelAndNotify("Sensoria", index);
      }
    });

    if (isSmartBandConnected) {
      var status = SmartBandApi.getCurrentStatus();

      processSmartBandStatusUpdate(status);
      checkBatteryLevelAndNotify("SmartBand", 1);
    }
    if (deviceConnectedTime.containsKey(uploaderDeviceIndex)) {
      DateTime? lastUploadTimestamp = Uploader.getLastUploadTimestamp();
      String deviceName = 'Uploader';
      int deviceIndex = 0;
      _checkActivityStatus(deviceName, deviceIndex, "Uploading", lastUploadTimestamp,
          Allowed_initialDelayMinutes_Upload, Allowed_updateIntervalMinutes_Upload);
    }
  }

  void requestStatusUpdateForDevice(String deviceName, int deviceIndex) async {
    try {
      final jsonString = await (deviceName == "MetaWear"
          ? metaWearChannel.invokeMethod('requestStatusUpdate', {'deviceIndex': deviceIndex})
          : sensoriaChannel.invokeMethod('requestStatusUpdate', {'deviceIndex': deviceIndex}));

      if (jsonString == null) {
        print("Received null status update for $deviceName device $deviceIndex");
        return;
      }

      final Map<String, dynamic> status = json.decode(jsonString);
      print('Status update for $deviceName, device $deviceIndex: $status');

      // Process the status update.
      if (deviceName == "MetaWear") {
        processMetaWearStatusUpdate(deviceName, deviceIndex, status);
        isMetaWearError = false;
      } else if (deviceName == "Sensoria") {
        processSensoriaStatusUpdate(deviceName, deviceIndex, status);
      }
    } catch (e) {
      print("Error requesting status update for $deviceName device $deviceIndex: $e");
    }
  }

  void processMetaWearStatusUpdate(
      String deviceName, int deviceIndex, Map<String, dynamic> status) {
    print("Processing status update for $deviceName device $deviceIndex...");

    DateTime? lastSensorFusionTimestamp = _parseDateTime(status['lastDataTimestampSensorFusion']);
    DateTime? lastTempTimestamp = _parseDateTime(status['lastDataTimestampTemperature']);
    DateTime? lastAmbientLightTimestamp = _parseDateTime(status['lastDataTimestampAmbientLight']);
    DateTime? lastDataWriteTimestamp = _parseDateTime(status['lastDataWriteToTimestamp']);

    _checkActivityStatus(
        deviceName,
        deviceIndex,
        "Sensor Fusion data reception",
        lastSensorFusionTimestamp,
        Allowed_initialDelayMinutes_MMR_SensorFusion,
        Allowed_updateIntervalMinutes_MMR_SensorFusion);

    _checkActivityStatus(deviceName, deviceIndex, "Temperature data reception", lastTempTimestamp,
        Allowed_initialDelayMinutes_MMR_Temperature, Allowed_updateIntervalMinutes_MMR_Temperature);

    _checkActivityStatus(
        deviceName,
        deviceIndex,
        "Ambient light data reception",
        lastAmbientLightTimestamp,
        Allowed_initialDelayMinutes_MMR_AmbientLight,
        Allowed_updateIntervalMinutes_MMR_AmbientLight);

    _checkActivityStatus(deviceName, deviceIndex, "Writing to file", lastDataWriteTimestamp,
        Allowed_initialDelayMinutes_MMR_WriteFile, Allowed_updateIntervalMinutes_MMR_WriteFile);
  }

  void processSensoriaStatusUpdate(
      String deviceName, int deviceIndex, Map<String, dynamic> status) {
    print("Processing status update for $deviceName device $deviceIndex...");

    DateTime? lastCoreDataTimestamp = _parseDateTime(status['lastDataTimestampSensoriaCore']);
    DateTime? lastSensoriaDataWriteTimestamp =
        _parseDateTime(status['lastDataWriteTimestampSensoria']);

    _checkActivityStatus(deviceName, deviceIndex, "Sensoria data reception", lastCoreDataTimestamp,
        Allowed_initialDelayMinutes_Sensoria, Allowed_updateIntervalMinutes_Sensoria);

    _checkActivityStatus(
        deviceName,
        deviceIndex,
        "Sensoria writing to file",
        lastSensoriaDataWriteTimestamp,
        Allowed_initialDelayMinutes_Sensoria_WriteFile,
        Allowed_updateIntervalMinutes_Sensoria_WriteFile);
  }

  void processSmartBandStatusUpdate(Map<String, dynamic> status) {
    String deviceName = "SmartBand";
    int deviceIndex = 1;
    _checkActivityStatus(
        deviceName,
        deviceIndex,
        "HR data reception",
        SmartBandApi.lastDataHRTimestamp,
        Allowed_initialDelayMinutes_SmartBand_HR,
        Allowed_updateIntervalMinutes_SmartBand_HR);
    _checkActivityStatus(
        deviceName,
        deviceIndex,
        "BP data reception",
        SmartBandApi.lastDataBPTimestamp,
        Allowed_initialDelayMinutes_SmartBand_BP,
        Allowed_updateIntervalMinutes_SmartBand_BP);
    _checkActivityStatus(
        deviceName,
        deviceIndex,
        "Step data reception",
        SmartBandApi.lastDataStepTimestamp,
        Allowed_initialDelayMinutes_SmartBand_Step,
        Allowed_updateIntervalMinutes_SmartBand_Step);
    _checkActivityStatus(
        deviceName,
        deviceIndex,
        "Data writing to file",
        SmartBandApi.lastDataWriteFileTimestamp,
        Allowed_initialDelayMinutes_SmartBand_WriteFile,
        Allowed_updateIntervalMinutes_SmartBand_WriteFile);
  }

  void _checkActivityStatus(String deviceName, int deviceIndex, String activityName,
      DateTime? lastActivityTime, int initialDelayMinutes, int regularUpdateIntervalMinutes) async {
    DateTime now = DateTime.now();

    if (lastActivityTime == null) {
      Duration sinceDeviceConnected = now.difference(deviceConnectedTime[deviceIndex] ?? now);
      if (sinceDeviceConnected.inMinutes <= initialDelayMinutes) {
        print(
            "$deviceName device $deviceIndex ----------- $activityName has not started yet. Initial delay period is $initialDelayMinutes.");
      } else {
        print(
            "ERROR: $deviceName device $deviceIndex $activityName has not started within the expected initial delay period of $initialDelayMinutes minutes.");
        notificationHandler.checkAndSendNotification(deviceName, deviceIndex, activityName);
        if (deviceName == "MetaWear") {
          await metaWearChannel.invokeMethod(
              'blinkLed', {'deviceIndex': deviceIndex, 'blinkCount': 3, 'color': 'Red'});
          isMetaWearError = true;
        }
      }
    } else {
      Duration sinceLastUpdate = now.difference(lastActivityTime);
      if (sinceLastUpdate.inMinutes > regularUpdateIntervalMinutes) {
        print(
            "ERROR: $deviceName device $deviceIndex $activityName - It's been ${sinceLastUpdate.inMinutes} minutes since the last update. Expected every $regularUpdateIntervalMinutes minutes. AMIR");
        notificationHandler.checkAndSendNotification(deviceName, deviceIndex, activityName);
        if (deviceName == "MetaWear") {
          await metaWearChannel.invokeMethod(
              'blinkLed', {'deviceIndex': deviceIndex, 'blinkCount': 3, 'color': 'Red'});
          isMetaWearError = true;
        }
      } else {
        print(
            "$deviceName device $deviceIndex $activityName - Last update was ${sinceLastUpdate.inMinutes} minutes ago. Within the expected interval of $regularUpdateIntervalMinutes minutes.AMIR");
        if (deviceName == "MetaWear" && !isMetaWearError) {
          String color = deviceIndex == 1 ? 'Green' : 'Blue';
          await metaWearChannel.invokeMethod(
              'blinkLed', {'deviceIndex': deviceIndex, 'blinkCount': 1, 'color': color});
        }
      }
    }
  }

  DateTime? _parseDateTime(dynamic timestamp) {
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print("Error parsing date from string: $e");
      }
    }
    return null;
  }

  Future<void> checkBatteryLevelAndNotify(String deviceName, int deviceIndex) async {
    int? batteryLevel;
    try {
      if (deviceName == "Mobile Device") {
        batteryLevel = await _battery.batteryLevel;
      } else {
        switch (deviceName) {
          case "MetaWear":
            batteryLevel = await MetaWearApi.getBatteryLevelForDevice(deviceIndex);
            break;
          case "Sensoria":
            batteryLevel = await SensoriaApi.getBatteryLevelForDevice(deviceIndex);
            break;
          case "SmartBand":
            batteryLevel = await SmartBandApi.getBatteryLevel();
            break;
          default:
            print("Unknown device type: $deviceName");
            return;
        }
      }
    } on PlatformException catch (e) {
      print("Failed to get battery level for $deviceName device $deviceIndex: ${e.message}");
      return;
    }

    if (batteryLevel != null && batteryLevel < 20 || batteryLevel == 1) {
      notificationHandler.checkAndSendNotification(deviceName, deviceIndex, "Battery Warning");
    }
  }
}
