import UIKit
import Flutter
import CoreBluetooth
import MetaWear
import UserNotifications


@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CBCentralManagerDelegate, FlutterStreamHandler {
    var centralManager: CBCentralManager?
    
    private var eventSink: FlutterEventSink?


    // MetaWear and Sensoria handlers
    var metaWearHandler: MetaWearHandler?
    var locationDataManager: LocationDataManager?
    private let centralBufferManager = CentralBufferManager()
    private lazy var sensoria = [
        1: SensoriaHandler(index: 1, buffer: centralBufferManager),
        2: SensoriaHandler(index: 2, buffer: centralBufferManager)
    ]

    // Method channels
    var sensoriaMethodChannel: FlutterMethodChannel?
    var metaWearMethodChannel: FlutterMethodChannel?
    var serviceMethodChannel: FlutterMethodChannel?

    var metaWearEventChannel: FlutterEventChannel?
    var sensoriaEventChannel: FlutterEventChannel?


    
//    var devices: [Int: MetaWear] = [:]

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: "com.upm.bluetooth.central"]
        )
        metaWearHandler = MetaWearHandler()
        _ = LocationDataManager.shared
        UNUserNotificationCenter.current().delegate = self
        createNotificationChannel()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        let messenger = engineBridge.applicationRegistrar.messenger()
        setupSensoriaMethodChannel(messenger: messenger)
        setupMetaWearMethodChannel(messenger: messenger)
        setupServiceMethodChannel(messenger: messenger)
        setupMetaWearEventChannel(messenger: messenger)
        setupSensoriaEventChannel(messenger: messenger)
    }

    private func setupSensoriaMethodChannel(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "com.example.healthywear/sensoria",
                                           binaryMessenger: messenger)
        sensoriaMethodChannel = channel
        channel.setMethodCallHandler { [weak self] call, result in
            let args = call.arguments as? [String: Any] ?? [:]
            let index = (args["coreIndex"] ?? args["deviceIndex"]) as? Int
            let handler = index.flatMap { self?.sensoria[$0] }

            func badArguments() {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid Sensoria request", details: nil))
            }

            switch call.method {
            case "sendIdNumber":
                guard let reference = args["refNumber"] as? String else { badArguments(); return }
                self?.centralBufferManager.setRecording(false)
                self?.sensoria.values.forEach { $0.updateCapture() }
                FileHandler.shared.setIdNumber(reference)
                result(nil)
            case "sendAppVersion":
                guard let version = args["appVersion"] as? String else { badArguments(); return }
                FileHandler.shared.setAppVersion(version)
                result(nil)
            case "scanAndConnectToSensoriaDevice":
                guard let handler = handler, let settings = args["settings"] as? [String: Int],
                      let accel = settings["accelerometerG"], [2, 4, 8, 16].contains(accel),
                      let gyro = settings["gyroscopeDps"], [245, 500, 1000, 2000].contains(gyro),
                      let mag = settings["magnetometerGauss"], [4, 8, 12, 16].contains(mag)
                else { badArguments(); return }
                let rates = [settings["accelerometerHz"] ?? 0,
                             settings["gyroscopeHz"] ?? 0,
                             settings["magnetometerHz"] ?? 0]
                let motionRates = [0, 13, 26, 52, 104, 208, 416, 833, 1660]
                let period = settings["streamPeriodMs"] ?? 0
                guard motionRates.contains(rates[0]), motionRates.contains(rates[1]),
                      [0, 5, 10, 20, 40, 80].contains(rates[2]),
                      [0, 10, 20, 25, 32, 40, 50, 100, 200].contains(period)
                else { badArguments(); return }
                handler.start(ranges: [accel, gyro, mag], rates: rates, period: period)
                result(nil)
            case "disconnectDevice":
                guard let handler = handler else { badArguments(); return }
                handler.disconnect()
                result(nil)
            case "getBatteryLevel":
                guard let handler = handler else { badArguments(); return }
                result(Int(handler.getBatteryLevel()))
            case "calibrateMagnetometer":
                guard let handler = handler else { badArguments(); return }
                handler.calibrateMagnetometer { result($0) }
            case "hasRecordingData":
                result(handler?.hasRecordingData ?? false)
            case "setRecording":
                guard let self = self, let enabled = args["enabled"] as? Bool else { badArguments(); return }
                guard !enabled || (self.sensoria.values.contains(where: { $0.isReady }) &&
                    !self.sensoria.values.contains(where: { $0.isCalibrating || $0.isCollectingTrial })) else {
                    result(false)
                    return
                }
                self.centralBufferManager.setRecording(enabled)
                self.sensoria.values.forEach { $0.updateCapture() }
                result(true)
            case "setTrialCapture":
                guard let self = self, let enabled = args["enabled"] as? Bool else { badArguments(); return }
                guard !enabled || (!self.centralBufferManager.isRecording &&
                    self.sensoria.values.contains(where: { $0.isReady }) &&
                    !self.sensoria.values.contains(where: { $0.isCalibrating })) else {
                    result(FlutterError(code: "CAPTURE_UNAVAILABLE", message: "Sensoria trial is not available", details: nil))
                    return
                }
                self.sensoria.values.forEach { $0.setTrialCapture(enabled) }
                result(nil)
            case "drainTrialSamples":
                result(self?.sensoria.values.flatMap { $0.drainTrialSamples() } ?? [])
            case "requestStatusUpdate":
                guard let index = index, handler != nil else { badArguments(); return }
                result(StatusUpdateManager.shared.getSensoriaCurrentStatus(deviceIndex: index))
            case "setLocale":
                // Flutter localizes the status messages for both platforms.
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func setupMetaWearMethodChannel(messenger: FlutterBinaryMessenger) {
        metaWearMethodChannel = FlutterMethodChannel(name: "com.example.healthywear/metawear", binaryMessenger: messenger)
        metaWearMethodChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self, let metaWearHandler = self.metaWearHandler else {
                result(FlutterError(code: "UNAVAILABLE", message: "MetaWearHandler is not initialized", details: nil))
                return
            }

            switch call.method {
            case "startScan":
                metaWearHandler.startScanning()
                result(nil)
                
            case "stopScan":
                metaWearHandler.stopScanning()
                result(nil)

            case "connectToDeviceIndex":
                print("The AppDelegate received connectToDeviceIndex")

                // Extract deviceIndex from the method arguments
                if let args = call.arguments as? [String: Any], let index = args["deviceIndex"] as? Int {
                    print("The AppDelegate triggered for index: \(index)")
                    metaWearHandler.connectToDevice(index: index)
                    result(nil)
                } else {
                    print("Invalid arguments received: \(String(describing: call.arguments))")
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid deviceIndex or device not found", details: nil))
                }
            case "disconnectDevice":
                print("The AppDelegate received disconnect")

                if let args = call.arguments as? [String: Any], let index = args["deviceIndex"] as? Int {
                    print("The AppDelegate triggered for index: \(index)")
                    metaWearHandler.disconnectDevice(deviceIndex: index)
                    result(nil)
                } else {
                    print("Invalid arguments received: \(String(describing: call.arguments))")
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid deviceIndex or device not found", details: nil))
                }
            case "getBatteryLevel":
                if let args = call.arguments as? [String: Any], let index = args["deviceIndex"] as? Int {
                    metaWearHandler.getBatteryLevel(deviceIndex: index) { batteryLevel, error in
                        if let batteryLevel = batteryLevel {
                            result(batteryLevel)
                        } else if let error = error {
                            result(FlutterError(code: "BATTERY_ERROR", message: error.localizedDescription, details: nil))
                        } else {
                            result(FlutterError(code: "UNKNOWN_ERROR", message: "Unknown error occurred", details: nil))
                        }
                    }
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments for getting battery level", details: nil))
                }
                //MARK: FROM HERE
                //TODO: MUST BE REMOVED
            case "sendIdNumber":
                        if let arguments = call.arguments as? [String: Any],
                           let refNumber = arguments["refNumber"] as? String {
                            // Handle the refNumber as needed, for example:
                            FileHandler.shared.setIdNumber(refNumber);//TODO: its temporary active untill the service channel correct

                            result(nil) // Success
                        } else {
                            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid arguments", details: nil))
                        }
            case "sendAppVersion":
                if let arguments = call.arguments as? [String: Any],
                   let appVersion = arguments["appVersion"] as? String {
//                    FileHandler.shared.setAppVersion(appVersion);
                        result(nil);
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid arguments", details: nil))
                }
            case "setLocale":
                if let args = call.arguments as? [String: Any],
                               let languageCode = args["languageCode"] as? String {
                    self.metaWearHandler!.setLocale(languageCode: languageCode)

                                result(nil)
                            } else {
                                result(FlutterError(code: "BAD_ARGS", message: "Wrong argument type", details: nil))
                            }
                                       
                //MARK: UNTIL  HERE
            case "requestStatusUpdate":
                        if let args = call.arguments as? [String: Any], let deviceIndex = args["deviceIndex"] as? Int {
                            let status = StatusUpdateManager.shared.getMetaWearCurrentStatus(deviceIndex: deviceIndex)
                            result(status)
                        } else {
                            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid or missing arguments for device status request", details: nil))
                        }
                //TODO: NEED CHECK WHY LED IS NOT WORKING FOR STATUS CHECK
            case "blinkLed":
                        guard let args = call.arguments as? [String: Any],
                              let color = args["color"] as? String,
                              let deviceIndex = args["deviceIndex"] as? Int,
                              let blinkCount = args["blinkCount"] as? Int else {
                            result(FlutterError(code: "BAD_ARGS", message: "Missing arguments for blinkLed", details: nil))
                            return
                        }
                metaWearHandler.startLed(deviceIndex: deviceIndex, blinkCount: blinkCount, color: color)
                        result(nil)


            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    
    //MARK: - Service Method channel
    private func setupServiceMethodChannel(messenger: FlutterBinaryMessenger) {
        serviceMethodChannel = FlutterMethodChannel(name: "com.example.healthywear/service", binaryMessenger: messenger)
        serviceMethodChannel?.setMethodCallHandler { [weak self] (call, result) in
            // Handle service-specific calls
            switch call.method {
            case "sendIdNumber":
                        if let arguments = call.arguments as? [String: Any],
                           let refNumber = arguments["refNumber"] as? String {
                            print("the id is receive in adelegate \(refNumber)")
//                            FileHandler.shared.setIdNumber(refNumber); TODO: Temproraily i use the metawear to send the id but i have to correct this and remove it from metawear
                            print("the id is snet to filehandler  \(refNumber)")

                            result(nil) // Success
                        } else {
                            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid arguments", details: nil))
                        }
                break;

            case "sendAppVersion":
                if let arguments = call.arguments as? [String: Any],
                   let appVersion = arguments["appVersion"] as? String {
                    FileHandler.shared.setAppVersion(appVersion);
                        result(nil);
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid arguments", details: nil))
                }
                                       
                    break;
                                   
                                   

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    ///////event listerner////////
    private func setupMetaWearEventChannel(messenger: FlutterBinaryMessenger) {
        metaWearEventChannel = FlutterEventChannel(name: "com.example.healthywear/metawear_connection_status", binaryMessenger: messenger)
        metaWearEventChannel?.setStreamHandler(self)
       }
    
    // AppDelegate
    private func setupSensoriaEventChannel(messenger: FlutterBinaryMessenger) {
        sensoriaEventChannel = FlutterEventChannel(name: "com.example.healthywear/sensoria_connection_status", binaryMessenger: messenger)
        sensoriaEventChannel?.setStreamHandler(self)
    }

    @objc func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        EventManager.shared.setEventSink(sink: events)
        // No need to set event sinks on the handlers anymore, just ensure they call EventManager.shared.dispatchEvent
        return nil
    }



    @objc func onCancel(withArguments arguments: Any?) -> FlutterError? {
        EventManager.shared.setEventSink(sink: { _ in })
        return nil
    }


    
    ////////


    ///////////////

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on and ready.")
            metaWearHandler = MetaWearHandler()

        case .poweredOff:
            print("Bluetooth is powered off.")
        case .unauthorized:
            print("Bluetooth access is unauthorized.")
        default:
            print("Unhandled central manager state: \(central.state)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
            // Handle restoration of the central manager state here
            
        }

    private func createNotificationChannel() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else if granted {
                print("Notification permissions granted")
            } else {
                print("Notification permissions denied")
            }
        }
    }
}

class BluetoothManager: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager?

    override init() {
        super.init()
        let options = [CBCentralManagerOptionRestoreIdentifierKey: "com.upm.bluetooth.central"]
        centralManager = CBCentralManager(delegate: self, queue: nil, options: options)
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // Handle restoration of the central manager
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Ready to work with Bluetooth
        }
    }
}
