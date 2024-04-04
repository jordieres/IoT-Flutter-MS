import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veepoo_sdk/model/ecg_data.dart';
import 'package:veepoo_sdk/model/hr_data.dart';
import 'package:veepoo_sdk/model/origin_v3_data.dart';
import 'package:veepoo_sdk/model/search_result.dart';
import 'package:veepoo_sdk/model/sleep_data.dart';
import 'package:veepoo_sdk/model/spo2h_data.dart';
import 'package:veepoo_sdk/model/spo2h_origin_data.dart';
import 'package:veepoo_sdk/veepoo_sdk.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<SearchResult> listDevice = [];
  bool isScanning = false;
  int connectStatus = 0;

  String _hrValue = "HR: N/a";
  String _spo2Value = "SPO2: N/a";
  String _process = "Loading: --";

  @override
  void initState() {
    super.initState();

    VeepooSdk.eventChannel().receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  void _onEvent(dynamic event) {
    Map<String, dynamic> e = json.decode(event);

    String? action = e["action"];

    if (action == "onSpO2HADataChange") {
      String rawJson = e["payload"];
      Spo2hData spo2hData = Spo2hData.fromJson(json.decode(rawJson));

      setState(() {
        _spo2Value = "SPO2: ${spo2hData.value}";
      });
    }
    if (action == "onHrDataChange") {
      String rawJson = e["payload"];
      HrData hrData = HrData.fromJson(json.decode(rawJson));

      setState(() {
        _hrValue = "HR: ${hrData.data}";
      });
    }
    if (action == "onReadOriginProgress") {
      String? raw = e["payload"];

      setState(() {
        _process = "Process: $raw";
      });
    }
  }

  void _onError(dynamic error) {
    print(error);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Veepoo SDK example'),
        ),
        body: Column(
          children: <Widget>[
            buildConnectStatus(context),
            buildButtonRow('ReScan', _onRefresh, 'QConnect', _quickConnect),
            buildButtonRow('Disconnect', _disconnect, 'Auth', _bind),
            buildButtonRow('HR start', _startDetectHeart, 'HR stop', _stopDetectHeart),
            buildButtonRow('SPO2 start', _startDetectSPO2H, 'SPO2 stop', _stopDetectSPO2H),
            buildButtonRow('Set info', _syncPersonInfo, 'TEST', _sdkTest),
            buildButtonRow('readOriginData', _readOriginData, 'readSleepData', _readSleepData),
            buildButtonRow('readSpo2hOrigin', _readSpo2hOrigin, 't', _dummyTest),
            buildDataDisplay(),
            buildDeviceList(context),
          ],
        ),
      ),
    );
  }

  Widget buildConnectStatus(BuildContext context) {
    String statusText;
    switch (connectStatus) {
      case 0:
        statusText = "Disconnected";
        break;
      case 1:
        statusText = "Connected";
        break;
      default:
        statusText = "Connecting";
    }
    return Text(statusText);
  }

  Widget buildButtonRow(
      String text1, VoidCallback onPressed1, String text2, VoidCallback onPressed2) {
    return Row(
      children: <Widget>[
        ElevatedButton(
          child: Text(text1),
          onPressed: onPressed1,
        ),
        ElevatedButton(
          child: Text(text2),
          onPressed: onPressed2,
        ),
      ],
    );
  }

  Widget buildDataDisplay() {
    return Column(
      children: <Widget>[
        Text('Health data'),
        Text(_hrValue),
        Text(_spo2Value),
        Text(_process),
        Text('Device list'),
      ],
    );
  }

  Widget buildDeviceList(BuildContext context) {
    if (isScanning) {
      return ListTile(title: Text('Scanning device...'));
    }

    if (listDevice.isEmpty) {
      return ListTile(title: Text('No device found'));
    }

    return Expanded(
      child: ListView.builder(
        itemCount: listDevice.length,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            children: <Widget>[
              ListTile(
                title: Text(
                    "${listDevice[index].name} - ${listDevice[index].mac} - ${listDevice[index].rssi}"),
                onTap: () => onTapped(index),
              ),
              Divider(height: 2.0),
            ],
          );
        },
      ),
    );
  }

  Future<List<SearchResult>> startScanDevice() async {
    try {
      List<SearchResult> result = await VeepooSdk.scanDevice();
      setState(() {
        listDevice.addAll(result);
      });
    } on PlatformException {}
    setState(() {
      isScanning = false;
    });
    return listDevice;
  }

  void _onRefresh() {
    if (isScanning) {
      return;
    }
    setState(() {
      isScanning = true;
      listDevice.clear();
    });
    startScanDevice();
  }

  void onTapped(int index) async {
    setState(() {
      connectStatus = 2;
    });
    bool isConnected = (await VeepooSdk.connect(listDevice[index].mac))!;
    if (!isConnected) {
      setState(() {
        connectStatus = 0;
      });
      return;
    }
    _bind();
    setState(() {
      connectStatus = 1;
    });
  }

  void _quickConnect() async {
    String macAddress = 'F8:58:E7:56:7A:97'; // Example MAC address
    bool status = (await VeepooSdk.connect(macAddress))!;
    if (status) {
      _bind();
    }
  }

  void _disconnect() async {
    await VeepooSdk.disconnect();
    setState(() {
      connectStatus = 0;
    });
  }

  void _bind() {
    VeepooSdk.bind('0000', true);
  }

  void _startDetectHeart() {
    VeepooSdk.startDetectHeart();
  }

  void _stopDetectHeart() {
    VeepooSdk.stopDetectHeart();
  }

  void _startDetectSPO2H() {
    VeepooSdk.startDetectSPO2H();
  }

  void _stopDetectSPO2H() {
    VeepooSdk.stopDetectSPO2H();
  }

  void _syncPersonInfo() {
    VeepooSdk.syncPersonInfo(true, 170, 60, 24, 5000);
  }

  void _readOriginData() async {
    OriginV3Data originV3Data = await VeepooSdk.readOrigin3Data();
    print('OriginV3Data: ${originV3Data.toJson()}');
  }

  void _readSpo2hOrigin() async {
    List<Spo2hOriginData> data = await VeepooSdk.readSpo2hOrigin();
    data.forEach((element) {
      print('Spo2hOriginData: ${element.toJson()}');
    });
  }

  void _readSleepData() async {
    List<SleepData> sleepData = await VeepooSdk.readSleepData();
    sleepData.forEach((data) {
      print('SleepData: ${data.toJson()}');
    });
  }

  void _sdkTest() {
    VeepooSdk.sdkTest();
  }

  void _dummyTest() async {
    List<EcgDetectResult> list = await VeepooSdk.readECGData();
    list.forEach((data) {
      print('EcgDetectResult: ${data.toJson()}');
    });
  }
}
