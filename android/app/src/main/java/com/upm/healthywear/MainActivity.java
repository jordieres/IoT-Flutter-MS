package com.upm.healthywear;



import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.content.pm.PackageManager;
import android.Manifest;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.ScanResult;


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

import com.sensoria.sensorialibrary.SensoriaSdk;

import static android.util.Log.DEBUG;
import static android.util.Log.VERBOSE;
import static android.util.Log.WARN;

//todo must delete after activation of the https checkig
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocketFactory;
//--------------------------------------





public class MainActivity extends FlutterActivity {
    private static final int REQUEST_CODE_PERMISSIONS = 101;


    private MetaWearHandler metaWearHandler;
    private SensoriaHandler sensoriaHandler;

    private static final String TAG = "MainActivity";
    private String prescriptionRefNumber; //field to store the prescription ref number


//    private OkHttpClient client = new OkHttpClient();//todo:uncomment when i want to active https check

    //  OkHttpClient initialization//
    private OkHttpClient client; //todo:delete when i want to active https -this is for bypass

    private String serverUrl = "https://192.168.1.133:3003/upload";
    private Handler uploadHandler = new Handler();
    private static final long UPLOAD_INTERVAL = 15000 ; // must be 1000*60*60 TO BE 1HOUR1 hour in milliseconds
    private ExecutorService executorService = Executors.newSingleThreadExecutor();


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        checkAndRequestPermissions();
        setupUploadTask();

        // initialize the OkHttpClient with SSL bypass
        setupUnsafeOkHttpClient();//Todo:delete when i want to active https check-this is for bypass
        SensoriaSdk.initialize(false,true,VERBOSE,true);
//        SensoriaSdk.initialize(false);
        sensoriaHandler = new SensoriaHandler(this);
//        metaWearHandler = new MetaWearHandler(this);



    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {

        super.configureFlutterEngine(flutterEngine);
        metaWearHandler = new MetaWearHandler(this);
//        sensoriaHandler = new SensoriaHandler(this);



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
                        case "getScannedDevices": {
                            Set<BluetoothDevice> devices = metaWearHandler.getScannedDevices();
                            List<String> deviceInfos = new ArrayList<>();
                            for (BluetoothDevice device : devices) {
                                deviceInfos.add(device.getAddress() + " - " + device.getName());
                            }
                            result.success(deviceInfos);
                            break;
                        }
                        case "connectToBoard":{
                            String macAddress = call.argument("macAddress");
                            String hand = call.argument("hand"); //to get the hand identifier

                            metaWearHandler.connectToMetaWearBoard(macAddress, hand);
                            result.success(null);
                            break;}
                        case "setupAccelerometer": {
                            String macAddress = call.argument("macAddress");
                            String hand = call.argument("hand");
                            metaWearHandler.setupDevices(macAddress, hand);
                            result.success(null);
                            break;
                        }
                        case "blinkLed": {
                            String macAddress = call.argument("macAddress");
                            String hand = call.argument("hand");
                            int blinkCount = call.argument("blinkCount");
                            metaWearHandler.blinkLed(macAddress, hand, blinkCount);
                            result.success(null);
                            break;
                        }
                        case "checkDataStreaming": {
                            String macAddress = call.argument("macAddress");
                            try {
                                boolean isStreaming = metaWearHandler.checkDataStreaming(macAddress);
                                result.success(isStreaming);
                            } catch (Exception e) {
                                Log.e(TAG, "Error checking data streaming: " + e.getMessage());
                                result.error("STREAMING_CHECK_ERROR", "Failed to check data streaming", null);
                            }
                            break;
                        }
                        case "checkConnection": {
                            String macAddress = call.argument("macAddress");
                            boolean isConnected = metaWearHandler.isBoardConnected(macAddress);
                            result.success(isConnected);
                            break;
                        }
                        case "getBatteryLevel": {
                            String macAddress = call.argument("macAddress");
                            metaWearHandler.getBatteryLevel(macAddress, result);
                            break;
                        }
                        case "disconnectDevice": {
                            String macAddress = call.argument("macAddress");
                            metaWearHandler.disconnectBoard(macAddress);
                            result.success(null);
                            break;
                        }
                        case "sendPrescriptionRefNumber": {
                            String refNumber = call.argument("refNumber");
                            Log.d(TAG, "Prescription Ref Number received: " + refNumber);
                            metaWearHandler.setPrescriptionRefNumber(refNumber);
                            result.success(null);
                            break;
                        }
                        default:
                            result.notImplemented();
                            break;
                    }
                });




        ////------------------Sensoria Channel----------------//
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.healthywear/sensoria")
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
//                        case "startScanSensoria":
//                            sensoriaHandler.startScanning();
//                            result.success(null);
//                            break;
//                        case "stopScanSensoria":
//                            sensoriaHandler.stopScanning();
//                            result.success(null);
//                            break;
//                        case "getScannedSensoriaDevices":
//                            List<String> devices = sensoriaHandler.getScannedDevicesAsString();
//                            result.success(devices);
//                            break;
//                        case "connectToSensoriaDevice":
//                            String macAddress = call.argument("macAddress");
//                            sensoriaHandler.connectToDevice(macAddress);
//                            result.success(null);
//                            break;
//                        case "connectToSensoriaDevice":
//                            String macAddress = call.argument("macAddress");
//                            String coreIdentifier = call.argument("coreIdentifier");
//                            if ("SACore1".equals(coreIdentifier)) {
//                                sensoriaHandler.connectToDeviceSACore1(macAddress);
//                            } else if ("SACore2".equals(coreIdentifier)) {
//                                sensoriaHandler.connectToDeviceSACore2(macAddress);
//                            }
//                            result.success(null);
//                            break;
                        case "scanAndConnectToSensoriaDevice":

                            Integer coreIndex = call.argument("coreIndex");
                            if (coreIndex != null) {
                                sensoriaHandler.scanAndConnectWithCores(coreIndex);
                                result.success(null);
                            } else {
                                result.error("ERROR", "coreIndex is null or not passed correctly", null);
                            }
                            break;
                        case "sendPrescriptionRefNumber": {
                            String refNumber = call.argument("refNumber");
                            Log.d(TAG, "Prescription Ref Number received: " + refNumber);
                            sensoriaHandler.setPrescriptionRefNumber(refNumber);
                            result.success(null);
                            break;
                        }
                        default:
                            result.notImplemented();
                            break;
                    }
                });


    }


    @Override
    protected void onDestroy() {
        super.onDestroy();
//        metaWearHandler.disconnectBoard();
        uploadHandler.removeCallbacksAndMessages(null);
        executorService.shutdownNow();


    }




    //////////-------------------------------PERMISSION FIRST RUN------------------



    //todo:i have to create in ios native like android to get permission ,not in flutter because mmr is in channel method
    //check bluetooth and location and grant the permission for both
    private void checkAndRequestPermissions() {
        String[] permissions = {
                Manifest.permission
                        .BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,

        };
        List<String> permissionsNeeded = new ArrayList<>();
        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                permissionsNeeded.add(permission);
            }
        }

        if (!permissionsNeeded.isEmpty()) {
            ActivityCompat.requestPermissions(this, permissionsNeeded.toArray(new String[0]), REQUEST_CODE_PERMISSIONS);
        }
    }


    //---------------------------Upload to the server-----------------------------

    private void setupUploadTask() {
        Runnable uploadRunnable = () -> {
            uploadFiles(getExternalFilesDir(null).getAbsolutePath());
            uploadHandler.postDelayed(this::setupUploadTask, UPLOAD_INTERVAL);
        };
        uploadHandler.postDelayed(uploadRunnable, UPLOAD_INTERVAL);
    }

    public void uploadFiles(String directoryPath) {
        File directory = new File(directoryPath);
        File[] files = directory.listFiles((dir, name) -> name.endsWith(".gz"));
        if (files != null) {
            for (File file : files) {
                executorService.execute(() -> uploadFile(file));
            }
        }
    }

    private void uploadFile(File file) {
        RequestBody requestBody = RequestBody.create(file, MediaType.parse("application/gzip"));
        Request request = new Request.Builder()
                .url(serverUrl)
                .post(requestBody)
//                .header("File-ID", fileId)
                .header("X-Original-Filename", file.getName()) //custom header with the original file name

                .build();
        try {
            Response response = client.newCall(request).execute();
            if (response.isSuccessful() && file.delete()) {
                Log.d(TAG, "Successfully uploaded and deleted file: " + file.getName());
            } else {
                Log.e(TAG, "Failed to upload file: " + file.getName());
            }
        } catch (IOException e) {
            Log.e(TAG, "Error uploading file: " + file.getName(), e);
        }
    }


    //todo delete untill end when i want to active https check-this is for bypassing
    // Method to setup OkHttpClient with SSL bypass for development use
    private void setupUnsafeOkHttpClient() {
        try {
            // create a trust manager that does not validate certificate chains
            final TrustManager[] trustAllCerts = new TrustManager[]{
                    new X509TrustManager() {
                        @Override
                        public void checkClientTrusted(java.security.cert.X509Certificate[] chain, String authType) {}

                        @Override
                        public void checkServerTrusted(java.security.cert.X509Certificate[] chain, String authType) {}

                        @Override
                        public java.security.cert.X509Certificate[] getAcceptedIssuers() {
                            return new java.security.cert.X509Certificate[]{};
                        }
                    }
            };

            //installing the all-trusting trust manager
            final SSLContext sslContext = SSLContext.getInstance("SSL");
            sslContext.init(null, trustAllCerts, new java.security.SecureRandom());
            //create a ssl socket factory with our all-trusting manager
            final SSLSocketFactory sslSocketFactory = sslContext.getSocketFactory();

            OkHttpClient.Builder builder = new OkHttpClient.Builder();
            builder.sslSocketFactory(sslSocketFactory, (X509TrustManager) trustAllCerts[0]);
            builder.hostnameVerifier((hostname, session) -> true);

            client = builder.build();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

}
