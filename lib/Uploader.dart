import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Uploader {
  static late final String serverUrl;
  static DateTime? lastUploadTimestamp;

  static const Duration uploadInterval = Duration(seconds: 60);

  static Future<void> loadConfig() async {
    final config = await rootBundle.loadString('assets/config.txt');
    serverUrl = config.trim();
  }

  static void startMonitoringAndUploading() {
    Timer.periodic(uploadInterval, (Timer t) => startUploading());
  }

  static Future<void> startUploading() async {
    final directory = await getExternalStorageDirectory(); //  external directory
    final files = directory!.listSync().where((item) => item.path.endsWith('.gz'));

    if (files.isEmpty) {
      print("Checked for files to upload, but none were found.");
      lastUploadTimestamp = DateTime.now();
      return;
    }

    for (var file in files) {
      await uploadFile(file as File);
    }
  }

  static Future<void> uploadFile(File file) async {
    try {
      var uri = Uri.parse(serverUrl);
      var request = http.MultipartRequest('POST', uri)
        ..headers['X-Original-Filename'] = file.path.split('/').last
        ..files.add(http.MultipartFile(
          'file',
          file.openRead(),
          file.lengthSync(),
          filename: file.path.split('/').last,
          contentType: MediaType('application', 'gzip'),
        ));

      var streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final response = await streamedResponse.stream.bytesToString();
        if (response.contains('OK')) {
          await file.delete();
          lastUploadTimestamp = DateTime.now();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('lastUploadTimestamp', lastUploadTimestamp!.millisecondsSinceEpoch);

          print("File uploaded and confirmed by server: ${file.path}");
          if (response.length > 2) {
            print("Additional server response: $response");
          }
        } else {
          print("Server response not as expected: $response");
        }
      } else {
        print("Failed to upload file: ${file.path}, Status: ${streamedResponse.statusCode}");
        streamedResponse.stream.transform(utf8.decoder).listen((value) {
          print(value);
        });
      }
    } catch (e) {
      print("Error uploading file: ${file.path}, $e");
    }
  }

  static DateTime? getLastUploadTimestamp() {
    return lastUploadTimestamp;
  }
}
