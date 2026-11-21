package com.upm.healthywear;



import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.content.pm.PackageManager;
import android.Manifest;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.ScanResult;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.NotificationChannel;
import android.os.Build;



import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.Set;
import java.io.File;
import java.io.IOException;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;


import okhttp3.*;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

//metawear service binding
import com.mbientlab.metawear.android.BtleService;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import androidx.core.app.NotificationCompat;


import com.sensoria.sensorialibrary.SensoriaSdk;

import static android.util.Log.DEBUG;
import static android.util.Log.VERBOSE;
import static android.util.Log.WARN;



public class MainActivity extends FlutterActivity {

    private static final int REQUEST_CODE_PERMISSIONS = 101;

    private MetaWearHandler metaWearHandler;
    private SensoriaHandler sensoriaHandler;
    private static final String TAG = "MainActivity";
    private String idNumber; //field to store the Id number
    private ExecutorService executorService = Executors.newSingleThreadExecutor();

    private static boolean isSensoriaInitialized = false;



    private ServiceConnection serviceConnection = new ServiceConnection() {

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            BtleService.LocalBinder serviceBinder = (BtleService.LocalBinder) service;
            metaWearHandler = new MetaWearHandler(MainActivity.this, serviceBinder);
            Log.d(TAG, "MetaWear Service connected----------------");

        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            metaWearHandler = null;
            Log.d(TAG, "Service disconnected");
        }
    };

    private boolean activityResumed;
    private boolean sensorServiceStarted;

    private boolean hasWearablePermissions() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) return false;
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN)
                        == PackageManager.PERMISSION_GRANTED &&
                 ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
                        == PackageManager.PERMISSION_GRANTED);
    }

    private void refreshSensorService() {
        if (!hasWearablePermissions()) {
            if (sensorServiceStarted) stopSensorService();
            return;
        }
        if (activityResumed && !sensorServiceStarted) startSensorService();
    }

    @Override
    protected void onResume() {
        super.onResume();
        activityResumed = true;
        refreshSensorService();
    }

    @Override
    protected void onPause() {
        activityResumed = false;
        super.onPause();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        createNotificationChannel();

        // Flutter requests access after the home route is ready. The
        // foreground service starts once those permissions are granted.

        //MetaWear btle Service binding
        Intent bindIntent = new Intent(this, BtleService.class);
        bindService(bindIntent, serviceConnection, Context.BIND_AUTO_CREATE);

        Log.d(TAG, "Initializing SensoriaSdk");
        if (!isSensoriaInitialized) {
            SensoriaSdk.initialize(false, true, VERBOSE, true);
            isSensoriaInitialized = true;
            Log.d(TAG, "SensoriaSdk initialized successfully");
        } else {
            Log.d(TAG, "SensoriaSdk already initialized, skipping...");
        }

        sensoriaHandler = new SensoriaHandler(this);

    }




    @Override
    protected void onDestroy() {
        if (sensoriaHandler != null) sensoriaHandler.close();
        super.onDestroy();
        //metawear service unbinding
        if (serviceConnection != null) {
            unbindService(serviceConnection);
        }
        stopSensorService();
        executorService.shutdownNow();
    }



    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // channel for foreground service
            CharSequence serviceName = getString(R.string.service_channel_name);
            String serviceDescription = getString(R.string.service_channel_description);
            int serviceImportance = NotificationManager.IMPORTANCE_DEFAULT;
            NotificationChannel serviceChannel = new NotificationChannel("sensor_service_channel", serviceName, serviceImportance);
            serviceChannel.setDescription(serviceDescription);

            // New channel for reconnect failed notifications
            CharSequence reconnectName = getString(R.string.fail_channel_name);
            String reconnectDescription = getString(R.string.fail_channel_description);
            int reconnectImportance = NotificationManager.IMPORTANCE_HIGH;
            NotificationChannel reconnectChannel = new NotificationChannel("fail_channel", reconnectName, reconnectImportance);
            reconnectChannel.setDescription(reconnectDescription);

            // Register both channels with the system
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            if (notificationManager != null) {
                notificationManager.createNotificationChannel(serviceChannel);
                notificationManager.createNotificationChannel(reconnectChannel);
            }
        }
    }





    // Added methods to start and stop the sensor service
    private void startSensorService() {
        Intent serviceIntent = new Intent(this, SensorService.class);
        ContextCompat.startForegroundService(this, serviceIntent);
        sensorServiceStarted = true;
    }

    private void updateServiceLocale(String languageCode) {
        if (!hasWearablePermissions() || !activityResumed) return;
        Intent serviceIntent = new Intent(this, SensorService.class);
        serviceIntent.putExtra("LANGUAGE_CODE", languageCode);

        ContextCompat.startForegroundService(this, serviceIntent);
        sensorServiceStarted = true;
    }

    private void stopSensorService() {
        Intent serviceIntent = new Intent(this, SensorService.class);
        stopService(serviceIntent);
        sensorServiceStarted = false;
    }


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {

        super.configureFlutterEngine(flutterEngine);


        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),
                "com.example.healthywear/service")
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "getAndroidSdkInt":
                            result.success(Build.VERSION.SDK_INT);
                            break;
                        case "hasWearablePermissions":
                            result.success(hasWearablePermissions());
                            break;
                        case "refreshPermissions":
                            refreshSensorService();
                            result.success(null);
                            break;
                        case "sendAppVersion": {
                            String version = call.argument("appVersion");
                            SensoriaHandler.setAppVersion(version);
                            MetaWearHandler.setAppVersion(version);
                            result.success(null);
                            break;
                        }
                        case "sendIdNumber": {
                            String reference = call.argument("refNumber");
                            if (sensoriaHandler != null) sensoriaHandler.setIdNumber(reference);
                            if (metaWearHandler != null) metaWearHandler.setIdNumber(reference);
                            result.success(null);
                            break;
                        }
                        default:
                            result.notImplemented();
                    }
                });

        ///---------------MetaWear Channel---------------//
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.healthywear/metawear")
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "startScan":{
                            metaWearHandler.startScanning();
                            result.success(null);
                            break;}
                        case "stopScan":{
                            metaWearHandler.stopScanning();
                            result.success(null);
                            break;}
                        case "connectToDeviceIndex": {
                            Integer deviceIndex = call.argument("deviceIndex");
                            if (deviceIndex != null) {
                                metaWearHandler.connectToDevice(deviceIndex);
                            } else {
                                result.error("INVALID_ARGUMENT", "deviceIndex is required", null);
                            }
                            break;
                        }
                        case "disconnectDevice": {
                            Integer deviceIndex = call.argument("deviceIndex");
                            metaWearHandler.disconnectDevice(deviceIndex);
                            result.success(null);
                            break;
                        }
                        case "sendIdNumber": {
                            String refNumber = call.argument("refNumber");
                            metaWearHandler.setIdNumber(refNumber);
                            result.success(null);
                            break;
                        }
                        case "getBatteryLevel": {
                            Integer deviceIndex = call.argument("deviceIndex");
                            metaWearHandler.getBatteryLevel(deviceIndex, result);
                            break;
                        }
                        case "setLocale": {
                            String languageCode = call.argument("languageCode");
                            metaWearHandler.setLocale(languageCode);
                            updateServiceLocale(languageCode);
                            result.success(null);
                            break;
                        }
                        case "blinkLed": {
                            String color = call.argument("color");
                            int deviceIndex=call.argument("deviceIndex");
                            int blinkCount=call.argument("blinkCount");

                            metaWearHandler.Led(deviceIndex,blinkCount,color);
                            result.success(null);
                            break;
                        }

                        case "sendAppVersion": {
                            String appVersion = call.argument("appVersion");
                            MetaWearHandler.setAppVersion(appVersion);
                            result.success(null);
                            break;
                        }
                        case "requestStatusUpdate": {
                            int deviceIndex = call.argument("deviceIndex");
                            String status = metaWearHandler.getCurrentStatus(deviceIndex);
                            result.success(status);
                            break;
                        }

//

                        default:
                            result.notImplemented();
                            break;
                    }
                });




        ////------------------Sensoria Channel----------------//
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.healthywear/sensoria")
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {

                        case "scanAndConnectToSensoriaDevice": {
                            if (!hasWearablePermissions()) {
                                result.error("PERMISSION_REQUIRED",
                                        "Precise location and Nearby devices are required by the Sensoria SDK", null);
                                break;
                            }
                            Integer index = call.argument("coreIndex");
                            java.util.Map<String, Integer> settings = call.argument("settings");
                            if (index == null || index < 1 || index > 2 || settings == null) {
                                result.error("INVALID_ARGUMENT", "Invalid Sensoria request", null);
                                break;
                            }
                            Integer accel = settings.get("accelerometerG");
                            Integer gyro = settings.get("gyroscopeDps");
                            Integer mag = settings.get("magnetometerGauss");
                            if (!java.util.Arrays.asList(2, 4, 8, 16).contains(accel) ||
                                    !java.util.Arrays.asList(245, 500, 1000, 2000).contains(gyro) ||
                                    !java.util.Arrays.asList(4, 8, 12, 16).contains(mag)) {
                                result.error("INVALID_ARGUMENT", "Invalid Sensoria ranges", null);
                                break;
                            }
                            int accelHz = settings.getOrDefault("accelerometerHz", 0);
                            int gyroHz = settings.getOrDefault("gyroscopeHz", 0);
                            int magHz = settings.getOrDefault("magnetometerHz", 0);
                            int period = settings.getOrDefault("streamPeriodMs", 0);
                            java.util.List<Integer> motionRates = java.util.Arrays.asList(0, 13, 26, 52, 104, 208, 416, 833, 1660);
                            if (!motionRates.contains(accelHz) || !motionRates.contains(gyroHz) ||
                                    !java.util.Arrays.asList(0, 5, 10, 20, 40, 80).contains(magHz) ||
                                    !java.util.Arrays.asList(0, 10, 20, 25, 32, 40, 50, 100, 200).contains(period)) {
                                result.error("INVALID_ARGUMENT", "Invalid Sensoria sampling settings", null);
                                break;
                            }
                            sensoriaHandler.enqueueScanAndConnectRequest(index, accel.shortValue(),
                                    gyro.shortValue(), mag.shortValue(), new short[]{
                                        (short) accelHz, (short) gyroHz, (short) magHz, (short) period
                                    });
                            result.success(null);
                            break;
                        }
                        case "sendIdNumber": {
                            String refNumber = call.argument("refNumber");
                            sensoriaHandler.setIdNumber(refNumber);
                            result.success(null);
                            break;
                        }
                        case "sendAppVersion": {
                            String appVersion = call.argument("appVersion");
                            SensoriaHandler.setAppVersion(appVersion);
                            result.success(null);
                            break;
                        }
                        case "calibrateMagnetometer":
                        case "hasRecordingData": {
                            Integer slot = call.argument("coreIndex");
                            if (slot == null || slot < 1 || slot > 2) {
                                result.error("INVALID_ARGUMENT", "Invalid Sensoria slot", null);
                            } else if (call.method.equals("hasRecordingData")) {
                                result.success(sensoriaHandler.hasRecordingData(slot));
                            } else {
                                sensoriaHandler.calibrateMagnetometer(slot, result);
                            }
                            break;
                        }
                        case "setRecording": {
                            result.success(sensoriaHandler.setRecording(Boolean.TRUE.equals(call.argument("enabled"))));
                            break;
                        }
                        case "setTrialCapture": {
                            if (sensoriaHandler.setTrialCapture(Boolean.TRUE.equals(call.argument("enabled")))) {
                                result.success(null);
                            } else {
                                result.error("CAPTURE_UNAVAILABLE", "Sensoria trial is not available", null);
                            }
                            break;
                        }
                        case "drainTrialSamples": {
                            result.success(sensoriaHandler.drainTrialSamples());
                            break;
                        }
                        case "getBatteryLevel": {
                            Integer coreIndexBattery = call.argument("coreIndex");
                            sensoriaHandler.readBatteryLevelForCore(coreIndexBattery, result);

                            break;
                        }
                        case "setLocale": {
                            String languageCode = call.argument("languageCode");
                            sensoriaHandler.setLocale(languageCode);
                            result.success(null);
                            break;
                        }
                        case "disconnectDevice": {
                            Integer coreindexdc = call.argument("coreIndex");
                            if (coreindexdc == null || coreindexdc < 1 || coreindexdc > 2) {
                                result.error("INVALID_ARGUMENT", "Invalid Sensoria slot", null);
                            } else {
                                sensoriaHandler.disconnectDevice(coreindexdc);
                                result.success(null);
                            }
                            break;
                        }
                        case "requestStatusUpdate": {
                            int deviceIndex = call.argument("deviceIndex");
                            String status = sensoriaHandler.getCurrentStatus(deviceIndex);
                            result.success(status);
                            break;
                        }

//
                        default:
                            result.notImplemented();
                            break;
                    }
                });


        ///-----------------Metawear connection status event listener--------------

        // Setup the EventChannel for connection status updates
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.healthywear/metawear_connection_status")
                .setStreamHandler(new StreamHandler() {
                    @Override
                    public void onListen(Object arguments, EventSink events) {
                        metaWearHandler.setConnectionStatusEventSink(events);
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        metaWearHandler.setConnectionStatusEventSink(null);
                    }
                });


        ///-----------------Sensoria connection status event listener--------------

        // Setup the EventChannel for connection status updates
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.healthywear/sensoria_connection_status")
                .setStreamHandler(new StreamHandler() {
                    @Override
                    public void onListen(Object arguments, EventSink events) {
                        sensoriaHandler.setConnectionStatusEventSink(events);
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        sensoriaHandler.setConnectionStatusEventSink(null);
                    }
                });



    }

}
