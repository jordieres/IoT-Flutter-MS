package com.upm.healthywear;

import android.os.Handler;
import android.os.Looper;
import android.os.IBinder;
import android.util.Log;
import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.ComponentName;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.location.Location;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.widget.Toast;




import android.app.Notification;
import android.app.NotificationManager;
import android.app.NotificationChannel;
import android.os.Build;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodChannel;


import java.io.File;
import java.io.IOException;
import java.io.FileWriter;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.util.Set;
import java.util.Map;
import java.util.List;
import java.util.Queue;
import java.util.Locale;
import java.util.HashMap;
import java.util.HashSet;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.zip.GZIPOutputStream;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.CopyOnWriteArrayList;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import okhttp3.*;
import org.json.JSONObject;
import org.json.JSONException;
import org.json.JSONArray;

import com.google.gson.Gson;//optional can be removed
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.FusedLocationProviderClient;



import com.mbientlab.metawear.Route;
import com.mbientlab.metawear.AsyncDataProducer;
import com.mbientlab.metawear.Subscriber;
import com.mbientlab.metawear.DataProducer;
import com.mbientlab.metawear.MetaWearBoard;
import com.mbientlab.metawear.android.BtleService;
import com.mbientlab.metawear.builder.RouteBuilder;
import com.mbientlab.metawear.builder.RouteComponent;
import com.mbientlab.metawear.Data;
import com.mbientlab.metawear.data.Acceleration;
import com.mbientlab.metawear.data.AngularVelocity;
import com.mbientlab.metawear.data.MagneticField;
import com.mbientlab.metawear.data.Quaternion;
import com.mbientlab.metawear.data.EulerAngles;
import com.mbientlab.metawear.module.Led;
import com.mbientlab.metawear.module.Accelerometer;
import com.mbientlab.metawear.module.AccelerometerBmi270;
import com.mbientlab.metawear.module.AccelerometerBmi160;
import com.mbientlab.metawear.module.AccelerometerBmi160.StepDetectorDataProducer;

import com.mbientlab.metawear.module.MagnetometerBmm150;
import com.mbientlab.metawear.module.MagnetometerBmm150.ConfigEditor;
import com.mbientlab.metawear.module.MagnetometerBmm150.MagneticFieldDataProducer;
import com.mbientlab.metawear.module.AmbientLightLtr329;
import com.mbientlab.metawear.module.AmbientLightLtr329.Gain;
import com.mbientlab.metawear.module.AmbientLightLtr329.IntegrationTime;
import com.mbientlab.metawear.module.AmbientLightLtr329.MeasurementRate;
import com.mbientlab.metawear.module.BarometerBosch;
import com.mbientlab.metawear.module.Gyro;
import com.mbientlab.metawear.module.GyroBmi160;
import com.mbientlab.metawear.module.Gyro.OutputDataRate;
import com.mbientlab.metawear.module.Gyro.Range;
import com.mbientlab.metawear.module.GyroBmi270;
import com.mbientlab.metawear.module.Logging;
import com.mbientlab.metawear.module.SensorFusionBosch;
import com.mbientlab.metawear.module.SensorFusionBosch.AccRange;
import com.mbientlab.metawear.module.SensorFusionBosch.GyroRange;
import com.mbientlab.metawear.module.SensorFusionBosch.Mode;
import com.mbientlab.metawear.module.Temperature;
import com.mbientlab.metawear.module.SensorFusionBosch;
import com.mbientlab.metawear.module.SensorFusionBosch.*;
import com.mbientlab.metawear.module.SensorFusionBosch.CorrectedAcceleration;

import android.bluetooth.le.ScanRecord;
import android.os.ParcelUuid;
import android.bluetooth.le.ScanSettings;




public class MetaWearHandler {
    private BtleService.LocalBinder serviceBinder;
    private Context context;
    private final String TAG = "MetaWearHandler";

    private MetaWearBoard board1 = null;
    private MetaWearBoard board2 = null;


    private Set<BluetoothDevice> scannedDevices = new HashSet<>();

    private boolean isScanning = false;


    private Queue<Integer> connectionQueue = new LinkedList<>();
    private boolean isConnecting = false;

    private Set<String> connectedDevices = new HashSet<>();


    private String idNumber = "";

    public void setIdNumber(String refNumber) {
        this.idNumber = refNumber;

    }

    private static String appVersion = "";

    public static void setAppVersion(String version) {
        appVersion = version;
    }

    private FusedLocationProviderClient fusedLocationClient;

    private String leftHandDeviceMac = null;
    private String rightHandDeviceMac = null;

    private String leftHandDeviceName = null;
    private String rightHandDeviceName = null;

/////////////////SET language/////////////////
// Method to change the locale
public void setLocale(String languageCode) {
    Locale locale = new Locale(languageCode);
    Locale.setDefault(locale);
    Configuration config = new Configuration(context.getResources().getConfiguration());
    config.setLocale(locale);
    context.getResources().updateConfiguration(config, context.getResources().getDisplayMetrics());

}
//---------------------------

    ///StatusCheker/////////

    private Handler statusCheckHandler = new Handler(Looper.getMainLooper());
    private Runnable statusCheckRunnable;


    private long lastDataTimestampSensorFusionBoard1 = 0;
    private long lastDataTimestampSensorFusionBoard2 = 0;

    private long lastDataTimestampBarometerBoard1 = 0;
    private long lastDataTimestampBarometerBoard2 = 0;

    private long lastDataTimestampTemperatureBoard1 = 0;
    private long lastDataTimestampTemperatureBoard2 = 0;


    private long lastDataTimestampAmbientLightBoard1 = 0;
    private long lastDataTimestampAmbientLightBoard2 = 0;


    private long lastDataWriteTimestamp = 0;

    /////



//    private List<String> dataBuffer = new ArrayList<>();
    private List<String> dataBuffer = new CopyOnWriteArrayList<>();


    private static final int BUFFER_MAX_SIZE = 1000;


    private List<String> ambientLightBuffer = new ArrayList<>();

    private List<String> temperatureBuffer = new ArrayList<>();

    private static final String METAWEAR_SERVICE_UUID = "326a9000-85cb-9195-d9dd-464cfbbae75a";


    private BluetoothAdapter bluetoothAdapter;
    private final Handler handler = new Handler();

    private static final long SCAN_PERIOD = 10000;



    private long lastScanTimestamp = 0;
    private final long SCAN_VALIDITY_PERIOD = 3000;

    private int pendingDeviceIndex = -1;

    private Map<BluetoothDevice, Integer> deviceRssiMap = new HashMap<>();

    ////////////notification//////////////////
    private static final String NOTIFICATION_CHANNEL_ID = "fail_channel";

    private void sendReconnectFailedNotification(int deviceIndex) {
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        Notification.Builder builder = new Notification.Builder(context, NOTIFICATION_CHANNEL_ID)
                .setContentTitle(context.getString(R.string.fail_notification_title))
                .setContentText(context.getString(R.string.fail_notification_content) + " " + deviceIndex)
                .setSmallIcon(R.mipmap.ic_notification)
                .setAutoCancel(true);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setChannelId(NOTIFICATION_CHANNEL_ID);
        }

        notificationManager.notify(deviceIndex, builder.build());
    }




    //--------------------event connection status

    private EventSink connectionStatusEventSink;

    public void setConnectionStatusEventSink(EventSink eventSink) {
        this.connectionStatusEventSink = eventSink;
    }

    private void updateConnectionStatus(int deviceIndex, String status) {
        if (connectionStatusEventSink != null) {
            new Handler(Looper.getMainLooper()).post(() -> {
                Map<String, Object> statusUpdate = new HashMap<>();
                statusUpdate.put("deviceIndex", deviceIndex);
                statusUpdate.put("status", status);

                connectionStatusEventSink.success(statusUpdate);



            });
        }
    }





    //-------------initial connection call back
    public interface ConnectionCallback {
        void onConnectionStateChanged(boolean isConnected);
    }



    //bind the btle Service
    public MetaWearHandler(Context context, BtleService.LocalBinder serviceBinder) {
        this.context = context;
        this.serviceBinder = serviceBinder;
        initialize();
    }

    private void initialize() {
        //Bluetooth Service
        final BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter();

        //Location service
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(context);
    }




    private ScanCallback leScanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            BluetoothDevice device = result.getDevice();
            int rssi = result.getRssi();
            ScanRecord scanRecord = result.getScanRecord();
            if (scanRecord != null && scanRecord.getServiceUuids() != null) {
                for (ParcelUuid uuid : scanRecord.getServiceUuids()) {
                    if (METAWEAR_SERVICE_UUID.equals(uuid.toString())) {
                        scannedDevices.add(device);
                        deviceRssiMap.put(device, rssi);
                        Log.d(TAG, "Found MetaWear device: " + device.getName() + " [" + device.getAddress() + "] with RSSI: " + rssi);
                        break;
                    }
                }
            }
        }

        @Override
        public void onBatchScanResults(List<ScanResult> results) {
            for (ScanResult result : results) {
                onScanResult(ScanSettings.CALLBACK_TYPE_ALL_MATCHES, result);
            }
        }

        @Override
        public void onScanFailed(int errorCode) {
            Log.e(TAG, "BLE Scan Failed with code " + errorCode);
        }
    };


    public void startScanning() {
        if (!isScanning) {
            scannedDevices.clear();
            bluetoothAdapter.getBluetoothLeScanner().startScan(leScanCallback);
            isScanning = true;
            handler.postDelayed(() -> {
                bluetoothAdapter.getBluetoothLeScanner().stopScan(leScanCallback);
                isScanning = false;
                Log.d(TAG, "Scan complete. Devices found: " + scannedDevices.size());
            }, SCAN_PERIOD);
        }
    }
    public void stopScanning() {
        if (isScanning) {
            bluetoothAdapter.getBluetoothLeScanner().stopScan(leScanCallback);
            isScanning = false;
            Log.d(TAG, "Scan manually stopped.");
        }
    }

    public void connectToDevice(int deviceIndex ) {
        connectionQueue.offer(deviceIndex);
        if (!isScanning && !isConnecting) {
            processNextConnection();

        } else {
            Log.d(TAG, "Connection or scan in progress, device index queued: " + deviceIndex);
        }
    }


    private void startScanWithConnectionIntent(final int deviceIndex) {
        scannedDevices.clear();
        bluetoothAdapter.getBluetoothLeScanner().startScan(leScanCallback);
        isScanning = true;
        Log.d(TAG, "Starting BLE scan...");

        handler.postDelayed(() -> {
            bluetoothAdapter.getBluetoothLeScanner().stopScan(leScanCallback);
            isScanning = false;
            lastScanTimestamp = System.currentTimeMillis();
            Log.d(TAG, "BLE scan stopped. Devices found: " + scannedDevices.size());



                if (scannedDevices.isEmpty()) {

                    Handler mainHandler = new Handler(Looper.getMainLooper());
                    String handName = (deviceIndex == 1) ? context.getString(R.string.right) : context.getString(R.string.left); // Using resource strings for "Right" and "Left"
                    String toastMessage = String.format(context.getString(R.string.no_metawear_device_found), handName);
                    mainHandler.post(() -> Toast.makeText(context, toastMessage, Toast.LENGTH_SHORT).show());


                    //change status of the device in the queue
                    while (!connectionQueue.isEmpty()) {
                        Integer queuedDeviceIndex = connectionQueue.poll(); // Retrieve and remove the head of the queue
                        updateConnectionStatus(queuedDeviceIndex, "disconnected");
                    }


                }else{processNextConnection();}



        }, SCAN_PERIOD);
    }



    private void processNextConnection() {
        if (!connectionQueue.isEmpty() && !isScanning) {
            long currentTime = System.currentTimeMillis();
            if ((currentTime - lastScanTimestamp) > SCAN_VALIDITY_PERIOD || scannedDevices.isEmpty()) {
                Integer deviceIndex = connectionQueue.peek();
                if (deviceIndex != null) {
                    startScanWithConnectionIntent(deviceIndex);
                }
            } else {
                if (scannedDevices.size() == 1 && connectionQueue.size() >= 2) {
                    Integer deviceIndexToConnect = connectionQueue.poll();
                    connectToFirstAvailableDevice(deviceIndexToConnect);

                    while (!connectionQueue.isEmpty()) {
                        Integer queuedDeviceIndex = connectionQueue.poll();
                        updateConnectionStatus(queuedDeviceIndex, "disconnected");

                        Handler mainHandler = new Handler(Looper.getMainLooper());
                        String handName = (queuedDeviceIndex == 1) ? context.getString(R.string.right) : context.getString(R.string.left); // Using resource strings for "Right" and "Left"
                        String toastMessage = String.format(context.getString(R.string.no_additional_metawear_device_found), handName);
                        mainHandler.post(() -> Toast.makeText(context, toastMessage, Toast.LENGTH_SHORT).show());


                    }
                } else {
                    Integer deviceIndex = connectionQueue.poll();
                    if (deviceIndex != null) {
                        connectToFirstAvailableDevice(deviceIndex);
                    }
                }
            }
        }
    }



    private void connectToFirstAvailableDevice(int deviceIndex ) {
        if (scannedDevices.isEmpty()) {
            Log.d(TAG, "No devices found. Starting scan.");
            startScanWithConnectionIntent(deviceIndex);
            return;
        }

        BluetoothDevice deviceToConnect = null;
        int maxRssi = Integer.MIN_VALUE;

        for (Map.Entry<BluetoothDevice, Integer> entry : deviceRssiMap.entrySet()) {
            BluetoothDevice device = entry.getKey();
            int rssi = entry.getValue();

            if (!connectedDevices.contains(device.getAddress()) && rssi > maxRssi) {
                deviceToConnect = device;
                maxRssi = rssi;
            }
        }

        if (deviceToConnect != null) {
            isConnecting = true;
            final BluetoothDevice finalDeviceToConnect = deviceToConnect;
            final int finalMaxRssi = maxRssi;

            Log.d(TAG, "Connecting to device with the highest RSSI: " + finalDeviceToConnect.getAddress() + " (RSSI: " + finalMaxRssi + ")");

            MetaWearBoard board = serviceBinder.getMetaWearBoard(finalDeviceToConnect);
            board.connectAsync().onSuccessTask(task -> {
                Log.d(TAG, "Connected to-------------------- " + finalDeviceToConnect.getAddress());
                connectedDevices.add(finalDeviceToConnect.getAddress());

                boolean isConnected = true;

                android.util.Log.d(TAG, "is connected ---------------------- "+isConnected);
                if(deviceIndex==1){
                    startStatusCheckerForBoard1();
                }else{
                    startStatusCheckerForBoard2();

                }

                if(isConnected) {
                    updateConnectionStatus(deviceIndex, "connected");
                } else {
                    updateConnectionStatus(deviceIndex, "disconnected");
                }





                if (deviceIndex == 1) {
                    board1 = board;
                    Led(1, 5,"green");
                    setupBarometer(board1,  "Right");
                    setupSensorFusion(board1,  "Right");
                    setupAmbientL(board1,  "Right");
                    setupTemperatureSensors(board1,  "Right");
                    rightHandDeviceMac = finalDeviceToConnect.getAddress();
                    rightHandDeviceName = finalDeviceToConnect.getName();

                    setupUnexpectedDisconnectHandler(board, deviceIndex);


                } else if (deviceIndex == 2) {
                    board2 = board;
                    Led(2, 5,"blue");
                    setupBarometer(board2,  "Left");
                    setupSensorFusion(board2,  "Left");
                    setupAmbientL(board2,  "Left");
                    setupTemperatureSensors(board2, "Left");

                    leftHandDeviceMac = finalDeviceToConnect.getAddress();
                    leftHandDeviceName = finalDeviceToConnect.getName();

                    setupUnexpectedDisconnectHandler(board, deviceIndex);

                }
                isConnecting = false;
                processNextConnection();
                return null;
            }).continueWithTask(task -> {
                if (task.isFaulted()) {
                    Log.e(TAG, "Connection failed: ", task.getError());
                    isConnecting = false;
                    processNextConnection();
                }
                return null;
            });
        } else {
            Log.d(TAG, "No available device found with higher RSSI to connect.");
            isConnecting = false;
            updateConnectionStatus(deviceIndex, "disconnected");
            Handler mainHandler = new Handler(Looper.getMainLooper());
            String handName = (deviceIndex == 1) ? "Right" : "Left";
            mainHandler.post(() -> Toast.makeText(context, "No MetaWear device found for " + handName + " hand.", Toast.LENGTH_SHORT).show());



        }
    }






    public void disconnectDevice(int deviceIndex) {
        scannedDevices.clear();
        isScanning = false;
        connectionQueue.clear();
        lastScanTimestamp = 0;




        MetaWearBoard boardToDisconnect = null;

        if (deviceIndex == 1) {
            boardToDisconnect = board1;
        } else if (deviceIndex == 2) {
            boardToDisconnect = board2;
        }

        if (boardToDisconnect != null) {
            final String macAddress = boardToDisconnect.getMacAddress();

            boardToDisconnect.disconnectAsync().continueWith(task -> {
                if (!task.isFaulted()) {
                    Log.i("MetaWearHandler", "Successfully disconnected from device index: " + deviceIndex);
                    connectedDevices.remove(macAddress);

                    if (deviceIndex == 1) {
                        board1 = null;
                    } else if (deviceIndex == 2) {
                        board2 = null;
                    }
                } else {
                    Log.e("MetaWearHandler", "Failed to disconnect from device index: " + deviceIndex);
                }
                return null;
            });
        } else {
            Log.d("MetaWearHandler", "No board found to disconnect for device index: " + deviceIndex);
        }
    }


    private void setupUnexpectedDisconnectHandler(MetaWearBoard board, int deviceIndex) {
        board.onUnexpectedDisconnect(status -> {
            Log.d(TAG, "Unexpected disconnect on device index: " + deviceIndex + " with status: " + status);
            updateConnectionStatus(deviceIndex, "reconnecting");

            attemptReconnect(deviceIndex, 1);

        });
    }

    private void attemptReconnect(int deviceIndex, int attempt) {
        if (attempt > 2) {
            Log.d(TAG, "Max reconnection attempts reached for device index: " + deviceIndex);
            updateConnectionStatus(deviceIndex, "disconnected");
            return;
        }

        handler.postDelayed(() -> {
            Log.d(TAG, "Attempting to reconnect to device index: " + deviceIndex + ". Attempt " + attempt);
            MetaWearBoard board = (deviceIndex == 1) ? board1 : board2;
            if (board != null) {
                board.connectAsync().onSuccessTask(task -> {
                    Log.d(TAG, "Successfully reconnected to device index: " + deviceIndex);
                    updateConnectionStatus(deviceIndex, "connected");
                    if (deviceIndex == 1) {
                        Led(deviceIndex, 3, "green");
                    } else if (deviceIndex == 2) {
                        Led(deviceIndex, 3, "blue");
                    }


                    return null;
                }).continueWithTask(task -> {
                    if (task.isFaulted()) {
                        Log.d(TAG, "Reconnect attempt " + attempt + " failed for device index: " + deviceIndex);
                        if (attempt == 2) {
                            updateConnectionStatus(deviceIndex, "disconnected");
//                            sendReconnectFailedNotification(deviceIndex); // Send notification here todo:active later

                        } else {
                            attemptReconnect(deviceIndex, attempt + 1);
                        }
                    }
                    return null;
                });
            } else {
                Log.d(TAG, "Board is null for device index: " + deviceIndex + ". Reconnect attempt failed.");
                if (attempt == 2) {
                    updateConnectionStatus(deviceIndex, "disconnected");
//                    sendReconnectFailedNotification(deviceIndex);//todo active later

                }
            }
        }, 30000); // Wait  before attempting to reconnect
    }






    public void Led(int deviceIndex, int blinkCount, String color) {
        MetaWearBoard board = (deviceIndex == 1) ? board1 : board2;
        Led.Color ledColor;

        // Determine the color
        switch (color.toLowerCase()) {
            case "green":
                ledColor = Led.Color.GREEN;
                break;
            case "blue":
                ledColor = Led.Color.BLUE;
                break;
            case "red":
                ledColor = Led.Color.RED;
                break;
            default:
                Log.e(TAG, "Invalid color specified for LED.");
                return;
        }

        if (board != null) {
            Led led = board.getModule(Led.class);
            if (led != null) {
                led.stop(true);
                led.editPattern(ledColor, Led.PatternPreset.BLINK)
                        .repeatCount((byte) blinkCount)
                        .commit();
                led.play();
                Log.d(TAG, "Blinking " + color + " LED for device index: " + deviceIndex + ", blink count: " + blinkCount);

            } else {
                Log.e(TAG, "LED module not available for device index: " + deviceIndex);
            }
        } else {
            Log.e(TAG, "Board not connected or invalid device index: " + deviceIndex);

        }
    }

    public void getBatteryLevel(int deviceIndex, MethodChannel.Result result) {
        MetaWearBoard board = null;

        if (deviceIndex == 1) {
            board = board1;
        } else if (deviceIndex == 2) {
            board = board2;
        }

        if (board != null && board.isConnected()) {
            board.readBatteryLevelAsync().continueWith(task -> {
                if (task.isFaulted()) {
                    Log.e(TAG, "Error reading battery level", task.getError());
                    result.error("BATTERY_READ_ERROR", "Failed to read battery level", null);
                } else {
                    Byte batteryLevel = task.getResult();
                    result.success(batteryLevel.intValue());
                    Log.d(TAG, "getBatteryLevel: "+batteryLevel);
                }
                return null;
            });
        } else {
            result.error("CONNECTION_ERROR", "Board not connected or not found", null);
        }
    }

    //------------sensor Fusion ------------------------
    private void setupSensorFusion(MetaWearBoard board, String hand) {
        SensorFusionBosch sensorFusion = board.getModule(SensorFusionBosch.class);
        if (sensorFusion != null) {
            sensorFusion.configure()
                    .mode(SensorFusionBosch.Mode.NDOF)
                    .accRange(SensorFusionBosch.AccRange.AR_16G)
                    .gyroRange(SensorFusionBosch.GyroRange.GR_2000DPS)
                    .commit();

            subscribeToSensorFusionData(sensorFusion.quaternion(), "Quaternion",hand);

            subscribeToSensorFusionData(sensorFusion.linearAcceleration(), "LinearAcceleration",hand);

            subscribeToSensorFusionData(sensorFusion.correctedAcceleration(), "CorrectedAcceleration",hand);

            subscribeToSensorFusionData(sensorFusion.gravity(), "Gravity",hand);

            subscribeToSensorFusionData(sensorFusion.correctedAngularVelocity(), "AngularVelocity",hand);

            subscribeToSensorFusionData(sensorFusion.correctedMagneticField(), "MagneticField",hand);

            subscribeToSensorFusionData(sensorFusion.eulerAngles(), "EulerAngles",hand);


            sensorFusion.start();
        }
    }


    private class SensorFusionData {
        Quaternion quaternion;
        Acceleration linearAcceleration;
        CorrectedAcceleration correctedAcceleration;
        Acceleration gravity;
        CorrectedAngularVelocity angularVelocity;
        CorrectedMagneticField magneticField;
        EulerAngles eulerAngles;
        Float altitude;
        Float pressure;
        long timestamp;
        String hand;

        boolean isComplete() {
            return quaternion != null && linearAcceleration != null && correctedAcceleration != null
                    && gravity != null && angularVelocity != null && magneticField != null && eulerAngles != null ;
        }

        // convert all data to a single string line
        @Override
        public String toString() {
            return String.format(Locale.US, "%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.4f,%.4f,%d,%s",
                    quaternion.w(), quaternion.x(), quaternion.y(), quaternion.z(), linearAcceleration.x(), linearAcceleration.y(), linearAcceleration.z(),
                    correctedAcceleration.x(), correctedAcceleration.y(), correctedAcceleration.z(), gravity.x(), gravity.y(), gravity.z(), angularVelocity.x(), angularVelocity.y(), angularVelocity.z(),
                    magneticField.x(), magneticField.y(), magneticField.z(), eulerAngles.pitch(), eulerAngles.roll(), eulerAngles.yaw(), altitude,pressure,timestamp, hand);
        }



    }

    private SensorFusionData currentData = new SensorFusionData();
    private final Object dataLock = new Object();

    private void subscribeToSensorFusionData(AsyncDataProducer producer, String dataType,String hand) {
        producer.addRouteAsync(source -> source.stream((data, env) -> {
//            Log.d(TAG, "Data received for " + dataType);

            synchronized (dataLock) {
                currentData.timestamp = System.currentTimeMillis();
                currentData.hand = hand;


                //////checker//////
                // Update the timestamp for sensor fusion data reception
                if ("Right".equals(hand)) {
                    lastDataTimestampSensorFusionBoard1 = System.currentTimeMillis();
                } else if ("Left".equals(hand)) {
                    lastDataTimestampSensorFusionBoard2 = System.currentTimeMillis();
                }

                ////////




                switch (dataType) {

                    case "Altitude":
                        currentData.altitude = data.value(Float.class);
                        break;
                    case "Pressure":
                        currentData.pressure = data.value(Float.class);
                        break;
                    case "Quaternion":
                        currentData.quaternion = data.value(Quaternion.class);

                        break;
                    case "LinearAcceleration":
                        currentData.linearAcceleration = data.value(Acceleration.class);
                        break;
                    case "CorrectedAcceleration":
                        currentData.correctedAcceleration = data.value(CorrectedAcceleration.class);
                        break;
                    case "Gravity":
                        currentData.gravity = data.value(Acceleration.class);
                        break;
                    case "AngularVelocity":
                        currentData.angularVelocity = data.value(CorrectedAngularVelocity.class);
                        break;
                    case "MagneticField":
                        currentData.magneticField = data.value(CorrectedMagneticField.class);
                        break;
                    case "EulerAngles":
                        currentData.eulerAngles = data.value(EulerAngles.class);
                        if (currentData.isComplete()) {

                            writeToBuffer(currentData.toString());
                            currentData = new SensorFusionData();
                        }
                        break;
                    default:
                        break;
                }
            }
        })).continueWith(task -> {
            if (task.isFaulted()) {
                Log.e(TAG, "Failed to configure route for " + dataType, task.getError());
            } else {
                Log.d(TAG, dataType + " route configured successfully");
                producer.start();

            }
            return null;
        });
    }

    private void writeToBuffer(String data) {
        synchronized (dataBuffer) {
            if (data == null || data.isEmpty()) {
                Log.d(TAG, "No data to add to buffer.");
                return;
            }
            dataBuffer.add(data);
            if (dataBuffer.size() >= BUFFER_MAX_SIZE) {
                fetchLocationAndSaveData("MF", dataBuffer);

            }
        }
    }

//-------------Setup Barometer------------------

    private void setupBarometer(MetaWearBoard board, String hand) {

        //this Metawear device has BarometerBosch module(not BarometerBme280)
        BarometerBosch barometer = board.getModule(BarometerBosch.class);

        if (barometer != null) {

            //todo: i can remove this manual config as i have already use preset REGULAR
//        magnetometer.configure()
//                .outputDataRate(Gyro.OutputDataRate.ODR_30_HZ)
//                .commit();
            subscribeToSensorFusionData(barometer.altitude(), "Altitude", hand);
            subscribeToSensorFusionData(barometer.pressure(), "Pressure", hand);

            barometer.start();

        } else {
            Log.e(TAG, "This device does not have a Barometer.");
        }
    }

//-------------Setup AmbientLight-----------------

    private void setupAmbientL(MetaWearBoard board, String hand) {

        //this Metawear device has BarometerBosch module(not BarometerBme280)
        AmbientLightLtr329 ambientLight = board.getModule(AmbientLightLtr329.class);


        if (ambientLight != null) {

            //using a preset setting or we can define manually
//        gyro.usePreset(Gyro.Preset.REGULAR);


            //todo: i can remove this manual config as i have already use preset REGULAR
            ambientLight.configure()

                    .measurementRate(AmbientLightLtr329.MeasurementRate.LTR329_RATE_1000MS)

                    .commit();

//        subscribeToSensorFusionData(ambientLight.illuminance(), "AmbienLight", hand);

//                        ambientLight.start();
//                        ambientLight.illuminance().start();



            ambientLight.illuminance().addRouteAsync(source -> source.stream((data, env) -> {


                float Light = data.value(Float.class);

                long timestamp = System.currentTimeMillis();

                String lightDataString = String.format(Locale.US, "%.2f,%d,%s", Light, timestamp, hand);

                android.util.Log.d(TAG, "setupAmbientL:------------------------- "+Light);




                synchronized (ambientLightBuffer) {
                    ambientLightBuffer.add(lightDataString);


                    if (ambientLightBuffer.size() == 50) {

                        fetchLocationAndSaveData("MI", new ArrayList<>(ambientLightBuffer));

                        ambientLightBuffer.clear();
                    }
                }



                // Update last data timestamp
                if ("Right".equals(hand)) {
                    lastDataTimestampAmbientLightBoard1 = System.currentTimeMillis();
                } else if ("Left".equals(hand)) {
                    lastDataTimestampAmbientLightBoard2 = System.currentTimeMillis();
                }

            })).continueWith(task -> {
                if (!task.isFaulted()) {
                    ambientLight.illuminance().start();
//                ambientLight.start();
                } else {
                    Log.e(TAG, "Failed to configure Barometer route", task.getError());
                }
                return null;

            });
        } else {
            Log.e(TAG, "This device does not have a Barometer.");
        }
    }


//--------------Setup Temperature--------------------

private void setupTemperatureSensors(MetaWearBoard board,  String hand) {
    Temperature temperatureModule = board.getModule(Temperature.class);

    if (temperatureModule == null) {
        Log.e(TAG, "This device does not support the Temperature module.");
        return;
    }

    // assume here there is at least one sensor available
    if (temperatureModule.sensors().length > 0) {
        Temperature.Sensor sensor = temperatureModule.sensors()[0];

        // To stream data
        sensor.addRouteAsync(source -> source.stream((data, env) -> {
            float temperature = data.value(Float.class);
            long timestamp = System.currentTimeMillis();
            String temperatureDataString = String.format(Locale.US, "%.2f,%d,%s", temperature, timestamp, hand);

            synchronized (temperatureBuffer) {
                temperatureBuffer.add(temperatureDataString);

                if (temperatureBuffer.size() ==10) {
                    fetchLocationAndSaveData("MT", new ArrayList<>(temperatureBuffer));
                    temperatureBuffer.clear();
                }
            }

            if ("Right".equals(hand)) {
                lastDataTimestampTemperatureBoard1 = System.currentTimeMillis();
            } else if ("Left".equals(hand)) {
                lastDataTimestampTemperatureBoard2 = System.currentTimeMillis();
            }

        })).continueWith(task -> {
            if (task.isFaulted()) {
                Log.e("MetaWear", "Failed to configure temperature data route.", task.getError());
            } else {
                Log.d("MetaWear", "Successfully subscribed to temperature data.");
            }
            return null;
        });

        final Handler handler = new Handler(Looper.getMainLooper());
        final Runnable readTemperatureTask = new Runnable() {
            @Override
            public void run() {
                sensor.read();

                handler.postDelayed(this, 600000);

            }
        };

        handler.post(readTemperatureTask);
    }
}


//------------Write to File-------------------------------
private void fetchLocationAndSaveData(String dataType, List<String> dataBuffer) {
    if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
        Log.e(TAG, "Location permission not granted");
        return;
    }

    LocationRequest locationRequest = LocationRequest.create();
    locationRequest.setNumUpdates(1);
    locationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);

    locationRequest.setInterval(10000);
    locationRequest.setFastestInterval(5000);
    locationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);

    LocationCallback locationCallback = new LocationCallback() {
        @Override
        public void onLocationResult(LocationResult locationResult) {
            if (locationResult == null) {
                Log.e(TAG, "Location result is null");
                return;
            }
            Location location = locationResult.getLocations().get(0);
            double latitude = location.getLatitude();
            double longitude = location.getLongitude();

            saveDataToFile(dataType, dataBuffer, latitude, longitude);

            fusedLocationClient.removeLocationUpdates(this);
        }
    };

    fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper());
}


    public void saveDataToFile(String dataType, List<String> dataBuffer,double latitude, double longitude) {
        if (dataBuffer.isEmpty()) {
//            Log.d(TAG, "No data to save for " + dataType + ". Only metadata will be written.");
            return;
        }

        String fileName = dataType + "_" + System.currentTimeMillis() + ".txt";
        File file = new File(context.getExternalFilesDir(null), fileName);

        try (FileOutputStream fos = new FileOutputStream(file);
             OutputStreamWriter writer = new OutputStreamWriter(fos)) {

            lastDataWriteTimestamp = System.currentTimeMillis();


            try{
                String type = "";

                JSONArray structure = new JSONArray();
                switch (dataType) {

                    case "MI":
                        structure.put("Illumination");
                        structure.put("TimeStamp");
                        structure.put("Hand");
                        type = "Illumination";

                        break;
                    case "MT":
                        structure.put("Degree");
                        structure.put("TimeStamp");
                        structure.put("Hand");
                        type = "Temperature";

                        break;
                    case "MF":
                        structure.put("QuaterW");
                        structure.put("QuaterX");
                        structure.put("QuaterY");
                        structure.put("QuaterZ");
                        structure.put("LinearAccelX");
                        structure.put("LinearAccelY");
                        structure.put("LinearAccelZ");
                        structure.put("CorrectedAccelX");
                        structure.put("CorrectedAccelY");
                        structure.put("CorrectedAccelZ");
                        structure.put("GravityX");
                        structure.put("GravityY");
                        structure.put("GravityZ");
                        structure.put("AngVelocityX");
                        structure.put("AngVelocityY");
                        structure.put("AngVelocityZ");
                        structure.put("MagFieldX");
                        structure.put("MagFieldY");
                        structure.put("MagFieldZ");
                        structure.put("EuAnglesPitch");
                        structure.put("EuAnglesRoll");
                        structure.put("EuAnglesYaw");
                        structure.put("Altitude");
                        structure.put("Pressure");
                        structure.put("TimeStamp");
                        structure.put("Hand");
                        type = "MetaWear";
                        break;
                }
                JSONObject metadata = new JSONObject();

                metadata.put("Id", idNumber);
                metadata.put("Type", type);
                metadata.put("Structure", structure);
                metadata.put("Lat", latitude);
                metadata.put("Long", longitude);
                metadata.put("AppVersion", appVersion);

                if (leftHandDeviceMac != null) {
                    metadata.put("LH-DeviceMac", leftHandDeviceMac);
                    metadata.put("LH-DeviceName", leftHandDeviceName);

                }
                if (rightHandDeviceMac != null) {
                    metadata.put("RH-DeviceMac", rightHandDeviceMac);
                    metadata.put("RH-DeviceName", rightHandDeviceName);

                }
                writer.write(metadata.toString() + "\n");

            } catch (JSONException e) {
                Log.e(TAG, "JSONException occurred: " + e.getMessage());
            }

//            writer.write("codeId: "+idRefNumber + "\n");

            for (String data : dataBuffer) {
                writer.write(data + "\n");
            }
//            // todo:if we want the data stored as Json,Convert the buffer to JSON string and write to file
//            String jsonData = new Gson().toJson(dataBuffer);
//            writer.write(jsonData);


        } catch (IOException e) {
            Log.e("MetaWearHandler", "Failed to save data to file", e);
        }

//        compressFile(file);
        dataBuffer.clear();
    }



    private void compressFile(File fileToCompress) {
        String gzipFileName = fileToCompress.getAbsolutePath() + ".gz";

        try (FileInputStream fis = new FileInputStream(fileToCompress);
             FileOutputStream fos = new FileOutputStream(gzipFileName);
             GZIPOutputStream gzipOS = new GZIPOutputStream(fos)) {

            byte[] buffer = new byte[1024];
            int len;
            while((len=fis.read(buffer)) != -1){
                gzipOS.write(buffer, 0, len);
            }

            Log.d(TAG, "File compressed: " + gzipFileName);
        } catch (IOException e) {
            Log.e(TAG, "Error compressing file", e);
        }
        if (fileToCompress.delete()) {
            Log.d(TAG, "Original file deleted: " + fileToCompress.getName());
        } else {
            Log.e(TAG, "Failed to delete the original file: " + fileToCompress.getName());
        }

    }



    //-----------------StatusChecker--------------

    private static final long SENSOR_FUSION_CHECK_INTERVAL = 80000;
    private static final long TEMPERATURE_CHECK_INTERVAL = 120000;
    private static final long AMBIENTL_CHECK_INTERVAL = 130000;
    private static final long FILE_WRITE_CHECK_INTERVAL = 180000;

    private static final long LED_BLINK_CHECK_INTERVAL = 60000;






    private void startStatusCheckerForBoard1() {
        statusCheckHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                boolean issueDetected = false;
                long currentTime = System.currentTimeMillis();

                if (currentTime - lastDataTimestampSensorFusionBoard1 > SENSOR_FUSION_CHECK_INTERVAL) {
                    Log.e(TAG, "Board 1: No new sensor fusion data received in the last minute.");
                    issueDetected = true;
                }

                if (currentTime - lastDataTimestampTemperatureBoard1 > TEMPERATURE_CHECK_INTERVAL) {
                    Log.e(TAG, "Board 1: No new temperature data received in the last minute.");
                    issueDetected = true;
                }

                if (currentTime - lastDataTimestampAmbientLightBoard1 > AMBIENTL_CHECK_INTERVAL) {
                    Log.e(TAG, "Board 1: No new ambient light data received in the last minute.");
                    issueDetected = true;
                }

                if (board1 == null || !board1.isConnected()) {
                    Log.e(TAG, "Board 1: Device is not connected.");
                    issueDetected = true;
                }

                if (currentTime - lastDataWriteTimestamp > FILE_WRITE_CHECK_INTERVAL) {
                    Log.e(TAG, "Board 1: No new data file written in the last minute.");
                    issueDetected = true;
                }

                if (issueDetected) {
                    Led(1, 1,"red");

                    Log.d(TAG, "Board 1: Issues detected. Blinking RED LED.");
                } else {
                    Log.d(TAG, "Board 1: No issues detected. Blinking GREEN LED.");
                    Led(1, 1,"green");
                }

                // Schedule the next check
                statusCheckHandler.postDelayed(this, LED_BLINK_CHECK_INTERVAL);

            }
        }, LED_BLINK_CHECK_INTERVAL);
    }



    private void startStatusCheckerForBoard2() {
        statusCheckHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                boolean issueDetected = false;
                long currentTime = System.currentTimeMillis();

                // Check for sensor fusion data reception
                if (currentTime - lastDataTimestampSensorFusionBoard2 > SENSOR_FUSION_CHECK_INTERVAL) {
                    Log.e(TAG, "Board 2: No new sensor fusion data received in the last minute.");
                    issueDetected = true;
                }

                // Check for temperature data reception
                if (currentTime - lastDataTimestampTemperatureBoard2 > TEMPERATURE_CHECK_INTERVAL) {
                    Log.e(TAG, "Board 2: No new temperature data received in the last minute.");
                    issueDetected = true;
                }

                // Check for ambient light data reception
                if (currentTime - lastDataTimestampAmbientLightBoard2 > AMBIENTL_CHECK_INTERVAL) {
                    Log.e(TAG, "Board 2: No new ambient light data received in the last minute.");
                    issueDetected = true;
                }

                // Check if the device is still connected
                if (board2 == null || !board2.isConnected()) {
                    Log.e(TAG, "Board 2: Device is not connected.");
                    issueDetected = true;
                }

                // Check for file writing interval
                if (currentTime - lastDataWriteTimestamp > FILE_WRITE_CHECK_INTERVAL) {
                    Log.e(TAG, "Board 2: No new data file written in the last minute.");
                    issueDetected = true;
                }

                if (issueDetected) {
                    Led(2, 2,"red");
                    Log.d(TAG, "Board 2: Issues detected. Blinking RED LED.");
                } else {
                    Log.d(TAG, "Board 2: No issues detected. Blinking BLUE LED.");
                    Led(2, 1,"blue");
                }

                statusCheckHandler.postDelayed(this, LED_BLINK_CHECK_INTERVAL);

            }
        }, LED_BLINK_CHECK_INTERVAL);
    }



//////////-------END---------------------

}




