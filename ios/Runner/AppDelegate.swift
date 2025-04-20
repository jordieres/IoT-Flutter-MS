import UIKit
import Flutter
import CoreBluetooth
import MetaWear
import UserNotifications
import workmanager


@UIApplicationMain
class AppDelegate: FlutterAppDelegate, CBCentralManagerDelegate, FlutterStreamHandler {
    var flutterEngine: FlutterEngine!
    var centralManager: CBCentralManager?
    
    private var eventSink: FlutterEventSink?


    // MetaWear and Sensoria handlers
    var metaWearHandler: MetaWearHandler?
    var sensoriaHandler: SensoriaHandler?
    var locationDataManager: LocationDataManager?
    
    var sensoriaHandlerRight: SensoriaHandlerRight?
        var sensoriaHandlerLeft: SensoriaHandlerLeft?
        var centralBufferManager = CentralBufferManager()

    
    


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
        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("rootViewController is not type FlutterViewController")
        }

        // Initialize the central manager for Bluetooth with restoration capabilities
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "com.upm.bluetooth.central"])

        metaWearHandler = MetaWearHandler()
//        sensoriaHandler = SensoriaHandler()
        
        sensoriaHandlerRight = SensoriaHandlerRight(centralBuffer: centralBufferManager)
        sensoriaHandlerLeft = SensoriaHandlerLeft(centralBuffer: centralBufferManager)
        
        let _ = LocationDataManager.shared

//workmanager
//        // In AppDelegate.application method
//        WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "com.upm.healthywear.checkUploadStatus")
//
//        // Register a periodic task in iOS 13+
//        WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "com.upm.healthywear.checkUploadStatus", frequency: NSNumber(value: 20 * 60))

        // Setup method channels
        setupSensoriaMethodChannel(controller: controller)
        setupMetaWearMethodChannel(controller: controller)
        setupServiceMethodChannel(controller: controller)

        setupMetaWearEventChannel(controller: controller)
        setupSensoriaEventChannel(controller: controller)



        createNotificationChannel()
        
        if #available(iOS 10.0, *) {
                    UNUserNotificationCenter.current().delegate = self
                }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupSensoriaMethodChannel(controller: FlutterViewController) {
        sensoriaMethodChannel = FlutterMethodChannel(name: "com.example.healthywear/sensoria", binaryMessenger: controller.binaryMessenger)
        sensoriaMethodChannel?.setMethodCallHandler { [weak self] (call, result) in
            // Handle Sensoria-specific calls
            switch call.method {
                //MARK: FROM HERE
                //TODO: MUST BE REMOVED
            case "sendIdNumber":
                        if let arguments = call.arguments as? [String: Any],
                           let refNumber = arguments["refNumber"] as? String {
                            // Handle the refNumber as needed, for example:
//                            FileHandler.shared.setIdNumber(refNumber);

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
                

//            case "scanAndConnectToSensoriaDevice":
//                print("received request for connection in appDelegate")
//                if let args = call.arguments as? [String: Any],
//                   let coreIndex = args["coreIndex"] as? Int {
//                    print("received request for connection in appDelegate for coreIndex \(coreIndex)")
//
//                    // Function to start scanning
//                    func startScan(for index: Int) {
//                        if index == 1 {
//                            self?.sensoriaHandlerRight?.startScan()
//                        } else if index == 2 {
//                            self?.sensoriaHandlerLeft?.startScan()
//                        }
//                    }
//
//                    // Introduce a delay for the second device
//                    if coreIndex == 1 {
//                        startScan(for: coreIndex)
//                        // If the first device is coreIndex 1, delay the scan for coreIndex 2
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                            startScan(for: 2)
//                        }
//                    } else if coreIndex == 2 {
//                        startScan(for: coreIndex)
//                        // If the first device is coreIndex 2, delay the scan for coreIndex 1
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                            startScan(for: 1)
//                        }
//                    } else {
//                        result(FlutterError(code: "INVALID_INDEX",
//                                            message: "Invalid coreIndex. Must be 1 or 2.",
//                                            details: nil))
//                        return
//                    }
//                    result(nil)
//                } else {
//                    result(FlutterError(code: "ERROR",
//                                        message: "coreIndex is null or not passed correctly",
//                                        details: nil))
//                }

            case "scanAndConnectToSensoriaDevice":
                guard let args = call.arguments as? [String: Any],
                      let coreIndex = args["coreIndex"] as? Int else {
                    result(FlutterError(
                        code: "ERROR",
                        message: "coreIndex is missing or invalid",
                        details: nil
                    ))
                    return
                }

                switch coreIndex {
                case 1:
                    print("Starting RIGHT‑foot scan")
                    self?.sensoriaHandlerRight?.startScan()
                case 2:
                    print("Starting LEFT‑foot scan")
                    self?.sensoriaHandlerLeft?.startScan()
                default:
                    result(FlutterError(
                        code: "INVALID_INDEX",
                        message: "coreIndex must be 1 or 2",
                        details: nil
                    ))
                    return
                }

                result(nil)
                
                
            case "disconnectDevice":
                print("received request for connection in appdelegate")
                            if let args = call.arguments as? [String: Any],
                               let coreIndex = args["coreIndex"] as? Int {
                                print("2received request for connection in appdelegatec \(coreIndex)")

                                if coreIndex == 1 {
                                           self?.sensoriaHandlerRight?.disconnect()
                                       } else if coreIndex == 2 {
                                           self?.sensoriaHandlerLeft?.disconnect()
                                       } else {
                                           result(FlutterError(code: "INVALID_INDEX",
                                                               message: "Invalid coreIndex. Must be 1 or 2.",
                                                               details: nil))
                                           return
                                       }
                                result(nil)  // Successful invocation without specific return
                            } else {
                                result(FlutterError(code: "ERROR",
                                                    message: "coreIndex is null or not passed correctly",
                                                    details: nil))
                            }
            case "getBatteryLevel":
                if let args = call.arguments as? [String: Any],
                   let coreIndex = args["coreIndex"] as? Int {
                    switch coreIndex {
                    case 1:
                        let batteryLevel = self?.sensoriaHandlerRight?.getBatteryLevel() ?? 0
                        result(Int(batteryLevel))
                    case 2:
                        let batteryLevel = self?.sensoriaHandlerLeft?.getBatteryLevel() ?? 0
                        result(Int(batteryLevel))
                    default:
                        result(FlutterError(code: "INVALID_INDEX", message: "Invalid coreIndex. Must be 1 or 2.", details: nil))
                    }
                } else {
                    result(FlutterError(code: "BAD_ARGS", message: "Missing or invalid arguments", details: nil))
                }
            case "requestStatusUpdate":
                        if let args = call.arguments as? [String: Any], let deviceIndex = args["deviceIndex"] as? Int {
                            let status = StatusUpdateManager.shared.getSensoriaCurrentStatus(deviceIndex: deviceIndex)
                            result(status)
                        } else {
                            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid or missing arguments for device status request", details: nil))
                        }
            case "setLocale":
                if let args = call.arguments as? [String: Any],
                               let languageCode = args["languageCode"] as? String {
                    self?.sensoriaHandlerRight!.setLocale(languageCode: languageCode)
                    self?.sensoriaHandlerLeft!.setLocale(languageCode: languageCode)

                                result(nil)
                            } else {
                                result(FlutterError(code: "BAD_ARGS", message: "Wrong argument type", details: nil))
                            }
                                       
                  
                //MARK: UNTIL  HERE
             
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func setupMetaWearMethodChannel(controller: FlutterViewController) {
        metaWearMethodChannel = FlutterMethodChannel(name: "com.example.healthywear/metawear", binaryMessenger: controller.binaryMessenger)
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
    private func setupServiceMethodChannel(controller: FlutterViewController) {
        sensoriaMethodChannel = FlutterMethodChannel(name: "com.example.healthywear/service", binaryMessenger: controller.binaryMessenger)
        sensoriaMethodChannel?.setMethodCallHandler { [weak self] (call, result) in
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
    private func setupMetaWearEventChannel(controller: FlutterViewController) {
        metaWearEventChannel = FlutterEventChannel(name: "com.example.healthywear/metawear_connection_status", binaryMessenger: controller.binaryMessenger)
        metaWearEventChannel?.setStreamHandler(self)
       }
    
    // AppDelegate
    private func setupSensoriaEventChannel(controller: FlutterViewController) {
        sensoriaEventChannel = FlutterEventChannel(name: "com.example.healthywear/sensoria_connection_status", binaryMessenger: controller.binaryMessenger)
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
            if sensoriaHandler == nil {
                            sensoriaHandler = SensoriaHandler()
                        }
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
