import 'package:flutter/material.dart';
import 'SmartBandApi.dart';
import 'MetaWearApi.dart';
import 'SensoriaApi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isPanelExpanded1 = false; //  for expansion Panel 1
  bool isPanelExpanded2 = false;
  bool isPanelExpanded3 = false;
  bool isBandConnected = false; // boolean variable to manage the switch state
  bool isRightHandConnected = false;
  bool isLeftHandConnected = false;
  bool isRightFootConnected = false;
  bool isLeftFootConnected = false;

  final TextEditingController _prescriptionController = TextEditingController();
  bool _isPrescriptionEditable = true; // to enable or disable the input field

// metawear Devices
  Set<String> _connectedDevices = Set<String>();

  // metawear Devices
  Set<String> _sensoriaconnectedDevices = Set<String>();

  @override
  void initState() {
    super.initState();
    SmartBandApi.requestStoragePermission();
    _loadPrescriptionRefNumber();
  }

  @override
  void dispose() {
    MetaWearApi.disposeTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Healthy Wear'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _prescriptionController,
                        decoration: InputDecoration(
                          labelText: 'Prescription Reference Number',
                          border: OutlineInputBorder(),
                          suffixIcon: _isPrescriptionEditable
                              ? IconButton(
                                  icon: Icon(Icons.check),
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setString(
                                        'prescriptionRefNumber', _prescriptionController.text);
                                    //load again the PRN as it changed by the user
                                    _loadPrescriptionRefNumber();
                                    setState(() {
                                      _isPrescriptionEditable = false;
                                    });
                                  },
                                )
                              : IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    setState(() {
                                      _isPrescriptionEditable = true;
                                    });
                                  },
                                ),
                        ),
                        readOnly: !_isPrescriptionEditable,
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                ExpansionPanelList(
                  expansionCallback: (int index, bool isExpanded) {
                    setState(() {
                      if (index == 0) {
                        isPanelExpanded1 = !isPanelExpanded1;
                      } else if (index == 1) {
                        isPanelExpanded2 = !isPanelExpanded2;
                      } else if (index == 2) {
                        isPanelExpanded3 = !isPanelExpanded3;
                      }
                    });
                  },
                  children: [
                    _buildExpansionPanel(
                        'Smart Band',
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isBandConnected,
                              onChanged: (value) {
                                setState(() {
                                  isBandConnected = value;
                                  if (value) {
                                    SmartBandApi.scanConnectBind();
                                  } else {
                                    //todo logic to stop connection here must
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        isPanelExpanded1),
                    _buildExpansionPanel(
                        'MMR',
                        Column(
                          children: [
                            Switch(
                              value: isRightHandConnected,
                              onChanged: (value) async {
                                setState(() {
                                  isRightHandConnected = value;
                                });
                                if (value) {
                                  //  to connect to the right hand MetaWear device
                                  await MetaWearApi.scanAndConnect(
                                      0, _connectedDevices, _onDeviceConnected);
                                } else {
                                  // todo: Code to disconnect the right hand MetaWear device
                                  // await MetaWearApi.disconnectDevice('right');
                                }
                              },
                            ),
                            Switch(
                              value: isLeftHandConnected,
                              onChanged: (value) async {
                                setState(() {
                                  isLeftHandConnected = value;
                                });
                                if (value) {
                                  //  to connect to the right hand MetaWear device
                                  await MetaWearApi.scanAndConnect(
                                      1, _connectedDevices, _onDeviceConnected);
                                } else {
                                  // todo: Code to disconnect the right hand MetaWear device
                                  // await MetaWearApi.disconnectDevice('right');
                                }
                              },
                            ),
                          ],
                        ),
                        isPanelExpanded2),
                    _buildExpansionPanel(
                        'Socks',
                        Column(
                          children: [
                            Switch(
                              value: isRightFootConnected,
                              onChanged: (value) async {
                                setState(() {
                                  isRightFootConnected = value;
                                });
                                if (value) {
                                  //  scan and connection for sacore1
                                  await SensoriaApi.scanAndConnectWithCore(1);

                                  print("the connect to firstdevice trigger in main.dart");
                                } else {
                                  // await MetaWearApi.disconnectDevice('right');
                                }
                              },
                            ),
                            Switch(
                              value: isLeftFootConnected,
                              onChanged: (value) async {
                                setState(() {
                                  isLeftFootConnected = value;
                                });
                                if (value) {
                                  //  scan and connection for sacore2
                                  await SensoriaApi.scanAndConnectWithCore(2);
                                } else {
                                  // await MetaWearApi.disconnectDevice('right');
                                }
                              },
                            ),
                          ],
                        ),
                        isPanelExpanded3),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ExpansionPanel _buildExpansionPanel(String title, Widget child, bool isExpanded) {
    return ExpansionPanel(
      headerBuilder: (BuildContext context, bool isExpanded) {
        return ListTile(title: Text(title));
      },
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: child,
      ),
      isExpanded: isExpanded,
    );
  }

  void _onDeviceConnected(String macAddress, String hand) {
    setState(() {});
  }

  void _onSensoriaDeviceConnected(String macAddress, String foot) {
    setState(() {
      if (foot == "right") {
        isRightFootConnected = true;
        // Only update the Sensoria connected devices set
        _sensoriaconnectedDevices.add(macAddress);
      } else if (foot == "left") {
        isLeftFootConnected = true;
        _sensoriaconnectedDevices.add(macAddress);
      }
    });
  }

  Future<void> _loadPrescriptionRefNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final refNumber = prefs.getString('prescriptionRefNumber') ?? '';
    setState(() {
      _prescriptionController.text = refNumber;
      // if the refNumber is not empty, so lock the field.
      _isPrescriptionEditable = refNumber.isEmpty;
    });
    SmartBandApi.setPrescriptionRefNumber(refNumber);
    SensoriaApi.sendPrescriptionRefNumber(refNumber);

    // sending  the prescription ref number to the native side right after loading it
    MetaWearApi.sendPrescriptionRefNumber(refNumber).then((_) {
      print("Prescription reference number sent on app start.");
    }).catchError((error) {
      print("Error sending prescription reference number on app start: $error");
    });
  }
}

//todo :do we need the network security file xml now and in the manifest,check if not necessary i delete them
