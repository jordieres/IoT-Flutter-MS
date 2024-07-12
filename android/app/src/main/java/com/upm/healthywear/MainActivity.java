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

    ///////---foreground service permission check

    private final int MAX_RETRIES = 10;
    private int currentRetry = 0;

    private void permissionCheckAndStartService() {
        if (checkAllPermissions()) {
            startSensorService();
        } else {
            if (currentRetry < MAX_RETRIES) {
                currentRetry++; // Increment the retry count
                new Handler().postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        permissionCheckAndStartService(); // Recursively check permissions
                    }
                }, 20000);
            } else {
                Log.d(TAG, "Maximum retries reached. Not starting SensorService.");
            }
        }
    }


private boolean checkAllPermissions() {
    boolean allPermissionsGranted = true;

    if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
        Log.d(TAG, "Permission Denied: ACCESS_FINE_LOCATION");
        allPermissionsGranted = false;
    } else {
        Log.d(TAG, "Permission Granted: ACCESS_FINE_LOCATION");
    }

    if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
        Log.d(TAG, "Permission Denied: ACCESS_COARSE_LOCATION");
        allPermissionsGranted = false;
    } else {
        Log.d(TAG, "Permission Granted: ACCESS_COARSE_LOCATION");
    }

    if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
        Log.d(TAG, "Permission Denied: BLUETOOTH");
        allPermissionsGranted = false;
    } else {
        Log.d(TAG, "Permission Granted: BLUETOOTH");
    }

    return allPermissionsGranted;
}
    ////////////////////


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        createNotificationChannel();

        permissionCheckAndStartService();
        // Start the sensor service
//        startSensorService();

//        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
//            ActivityCompat.requestPermissions(this, new String[] { android.Manifest.permission.ACCESS_FINE_LOCATION }, LOCATION_PERMISSION_REQUEST_CODE);
//        } else {
//            startSensorService();
//        }


        // delayed permission check
//        new Handler().postDelayed(new Runnable() {
//            @Override
//            public void run() {
////                checkAndRequestPermissions();
//                startSensorService();
//            }
//        }, 10000); // Delay of 5000 milliseconds (5 seconds)


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
    }

    private void updateServiceLocale(String languageCode) {
        Intent serviceIntent = new Intent(this, SensorService.class);
        serviceIntent.putExtra("LANGUAGE_CODE", languageCode);

        startService(serviceIntent);
    }

    private void stopSensorService() {
        Intent serviceIntent = new Intent(this, SensorService.class);
        stopService(serviceIntent);
    }


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {

        super.configureFlutterEngine(flutterEngine);


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

                        case "scanAndConnectToSensoriaDevice":
                            Integer coreIndex = call.argument("coreIndex");
                            if (coreIndex != null) {
                                sensoriaHandler.enqueueScanAndConnectRequest(coreIndex);
                                result.success(null);
                            } else {
                                result.error("ERROR", "coreIndex is null or not passed correctly", null);
                            }
                            break;
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
                            sensoriaHandler.disconnectDevice(coreindexdc);

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
