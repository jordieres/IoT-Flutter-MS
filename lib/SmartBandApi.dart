import 'dart:convert';
import 'dart:async'; // import for Timer
import 'dart:io';

import 'package:veepoo_sdk/veepoo_sdk.dart';
import 'package:veepoo_sdk/model/search_result.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:collection/collection.dart';

import 'package:flutter_localizations/flutter_localizations.dart'; //for language
import 'AppLocal.dart'; //for the langauges

import 'enums/device_connection_status.dart';

class SpO2Data {
  final int spo2Value;
  final int progress;

  SpO2Data({required this.spo2Value, required this.progress});

  factory SpO2Data.fromJson(Map<String, dynamic> json) {
    return SpO2Data(
      spo2Value: json['spo2Value'],
      progress: json['progress'],
    );
  }

  Map<String, dynamic> toJson() => {
        'spo2Value': spo2Value,
        'progress': progress,
      };
}

class SmartBandApi {
  static List<Map<String, dynamic>> heartRateBuffer =
      []; // this is the buffer to store heart rate values and timestamps
  static String? _prescriptionRefNumber;

//scan ,connect ,bind
  static Future<void> scanConnectBind() async {
    try {
      List<SearchResult> devices = await VeepooSdk.scanDevice();
      if (devices.isNotEmpty) {
        SearchResult selectedDevice = devices.first;

        print('Selected device: ${selectedDevice.mac}');

        bool? isConnected = await VeepooSdk.connect(selectedDevice.mac);

        if (isConnected == true) {
          print('Connected to ${selectedDevice.mac}');

          bool? isBound = await VeepooSdk.bind("0000", true);
          if (isBound == true) {
            print('Bound to ${selectedDevice.mac}');

            startHeartRateMeasurement();
          } else {
            print('Failed to bind to ${selectedDevice.mac}');
          }
        } else {
          print('Failed to connect to ${selectedDevice.mac}');
        }
      } else {
        print('No devices found');
      }
    } catch (e) {
      print('Error occurred: $e');
    } finally {}
  }

  //start heart measurement
  static Future<void> startHeartRateMeasurement() async {
    await VeepooSdk.startDetectHeart();

    VeepooSdk.eventChannel().receiveBroadcastStream().listen((event) {
      // print('Received event: $event');//-show all received data of the heart data

      try {
        final Map<String, dynamic> e = event is String ? json.decode(event) : event;

        if (e['action'] == 'onHrDataChange') {
          if (e['payload'] is String) {
            final Map<String, dynamic> payload = json.decode(e['payload']);

            int heartRate = payload['data']; // extract heart rate number
            int timestamp = DateTime.now().millisecondsSinceEpoch; // get current timestamp

            // print("Heart Rate: $heartRate + at + $timestamp");

            // adding heart rate and timestamp to buffer as a Map
            heartRateBuffer.add({'heartRate': heartRate, 'timestamp': timestamp});

            print("buffer is : $heartRateBuffer");

            if (heartRateBuffer.length >= 20) {
              saveDataToFile('HH', heartRateBuffer);

              heartRateBuffer.clear();
            }
          }
        }
      } catch (error) {
        print("Error processing event data: $error");
      }
    }, onError: (error) {
      print("Error receiving heart rate data: $error");
    });
  }

//------get Storage permission
  static Future<void> requestStoragePermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

//-----get local file
  static Future<File> _getLocalFile(String fileName) async {
    final Directory? directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception("External storage directory not found");
    }
    final String path = directory.path;
    return File('$path/$fileName');
  }

  //---receive prescription reference number
  static void setPrescriptionRefNumber(String refNumber) {
    _prescriptionRefNumber = refNumber;
  }

  // ---Unified method to save data from any buffer to files
  static Future<void> saveDataToFile(String dataType, List<Map<String, dynamic>> buffer) async {
    try {
      final String jsonData = jsonEncode(buffer);
      final String fileName = "${dataType}_${DateTime.now().millisecondsSinceEpoch}";
      final String txtFileName = "$fileName.txt";
      final String gzFileName = "$fileName.gz";

      final File file = await _getLocalFile(txtFileName);

      // --add the prescription ref number to the data
      final String dataWithRefNumber = 'codeId: $_prescriptionRefNumber\n$jsonData';

      //-- write data to file
      await file.writeAsString(dataWithRefNumber);

      // --Compress the file
      final File gzFile = await _compressFile(file, gzFileName);

      //- Delete the original file
      await file.delete();

      print('Data is compressed and original file deleted.');
    } catch (e) {
      print('An error occurred while saving data: $e');
    }
  }

  //--compress files
  static Future<File> _compressFile(File file, String gzFileName) async {
    final File gzFile = await _getLocalFile(gzFileName);
    final List<int> bytes = file.readAsBytesSync();
    final List<int> gzippedBytes = gzip.encode(bytes);
    await gzFile.writeAsBytes(gzippedBytes);
    return gzFile;
  }
}
