package com.upm.healthywear;



import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.app.Activity;
import android.util.Log;
import android.widget.Toast;
import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.DialogInterface;
import android.location.Location;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.content.res.Configuration;


import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodChannel;


import com.sensoria.sensorialibrary.*;
import com.sensoria.sensorialibrary.SACore;
import com.sensoria.sensorialibrary.SADevice;
import com.sensoria.sensorialibrary.SADeviceInterface;
import com.sensoria.sensorialibrary.SAErrors;
import com.sensoria.sensorialibrary.SAPermissionsCallbackInterface;
import com.sensoria.sensorialibrary.SAServiceInterface;
import com.sensoria.sensorialibrary.SASensoriaStreamingService;
import com.sensoria.sensorialibrary.SAServiceStreamingServiceInterface;
import com.sensoria.sensorialibrary.CSBatteryService;
import com.sensoria.sensorialibrary.CSBatteryServiceInterface;
import com.sensoria.sensorialibrary.SASensoriaControlPointService;
import com.sensoria.sensorialibrary.SADataPoint;
import com.sensoria.sensorialibrary.SensoriaSdk;
import static com.sensoria.sensorialibrary.SensoriaSdk.SdkLog;
//import com.sensoria.sensorialibrary.SAProcessedDataLogger;



import java.util.Queue;
import java.util.LinkedList;
import java.util.Arrays;
import java.util.UUID;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;
import java.util.Date;
import java.util.zip.GZIPOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.text.SimpleDateFormat;



import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.gson.Gson;//optional can be removed

import org.json.JSONObject;
import org.json.JSONArray;











public class SensoriaHandler implements SADeviceInterface,SAServiceStreamingServiceInterface,SAServiceInterface,CSBatteryServiceInterface {
    private Context context;
    private SACore sacore1, sacore2;
    private SACore activeCore = null;
    private final String TAG = "SensoriaHandler";



    private SASensoriaControlPointService sensoriaControlPointService;

    private SADevice device1, device2;


    private FusedLocationProviderClient fusedLocationClient;


    private String idNumber = "";

    public void setIdNumber(String refNumber) {
        this.idNumber = refNumber;
    }

    private static String appVersion = "";

    public static void setAppVersion(String version) {
        appVersion = version;
    }


    /////////////////SET language/////////////////
// Method to change the locale
    public void setLocale(String languageCode) {
        Locale locale = new Locale(languageCode);
        Locale.setDefault(locale);
        Configuration config = new Configuration(context.getResources().getConfiguration());
        config.setLocale(locale);
        context.getResources().updateConfiguration(config, context.getResources().getDisplayMetrics());

    }
    /////////////





    private static final int REQUEST_CODE = 1;

    private SAStreamingService sensoriaStreamingService1;
    private SAStreamingService sensoriaStreamingService2;

    private CSBatteryService batteryService1;
    private CSBatteryService batteryService2;

    private ArrayList<String> dataBuffer1 = new ArrayList<>();
    private ArrayList<String> dataBuffer2 = new ArrayList<>();

<<<<<<< HEAD
    private final int BUFFER_SIZE_THRESHOLD = 1500;
=======
    private final int BUFFER_SIZE_THRESHOLD = 3000;
>>>>>>> ver_2

    private final Object bufferLock = new Object();

    private volatile double lastKnownLatitude = 0.0;
    private volatile double lastKnownLongitude = 0.0;


    private List<SADevice> connectedDevices = new ArrayList<>();






    public SensoriaHandler(Context context) {
        this.context = context;
        sacore1 = new SACore(this, context);
        sacore2 = new SACore(this, context);
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(context);
        startLocationUpdates();



    }

    //--------------------event connection status

    private EventSink connectionStatusEventSink;

    public void setConnectionStatusEventSink(EventSink eventSink) {
        this.connectionStatusEventSink = eventSink;
    }

    private void updateConnectionStatus(int coreIndex, String status) {
        if (connectionStatusEventSink != null) {
            new Handler(Looper.getMainLooper()).post(() -> {
                Map<String, Object> statusUpdate = new HashMap<>();
                statusUpdate.put("coreIndex", coreIndex);
                statusUpdate.put("status", status);

                connectionStatusEventSink.success(statusUpdate);

            });
        }
    }
////------------------------



    private void startLocationUpdates() {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "Location permission not granted");
            return;
        }
        LocationRequest locationRequest = LocationRequest.create();

        locationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);
        locationRequest.setInterval(10000);
        locationRequest.setFastestInterval(5000);

        LocationCallback locationCallback = new LocationCallback() {
            @Override
            public void onLocationResult(LocationResult locationResult) {
                if (locationResult != null && locationResult.getLastLocation() != null) {
                    Location location = locationResult.getLastLocation();

                    lastKnownLatitude = locationResult.getLastLocation().getLatitude();
                    lastKnownLongitude = locationResult.getLastLocation().getLongitude();
                }
            }
        };

        fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper());

    }


//--------------------------------Device Interface Callbacks------------------------------

    @Override
    public void didInitialized(SACore saCore) {
        android.util.Log.d(TAG, "the core is initializedddddddddddddddddddddd");
    }

    class ScanConnectRequest {
        int coreIndex;

        ScanConnectRequest(int coreIndex) {
            this.coreIndex = coreIndex;
        }

        void process() {
            scanAndConnectWithCores(coreIndex);
        }
    }

    Queue<ScanConnectRequest> requestQueue = new LinkedList<>();
    boolean isProcessing = false;

    // Enqueue scan and connect requests instead of directly starting them
    public void enqueueScanAndConnectRequest(int coreIndex) {
        ScanConnectRequest request = new ScanConnectRequest(coreIndex);
        requestQueue.add(request);
        processNextRequest();
    }

    // Process the next request in the queue if not currently processing another request
    private void processNextRequest() {
        if (!isProcessing && !requestQueue.isEmpty()) {
            isProcessing = true;
            ScanConnectRequest nextRequest = requestQueue.poll(); // Retrieves and removes the head of the queue
            nextRequest.process();
        }
    }



    // start scanning with the specified core.
    public void scanAndConnectWithCores(int coreIndex) {
        android.util.Log.d(TAG, "request for the connectin is receiveddddddddd+++++++++++++ for the core "+coreIndex);
        activeCore = (coreIndex == 1) ? sacore1 : sacore2;
        if (!activeCore.isConnected()){
            if (activeCore != null) {
            Log.d(TAG, "Starting scan with SACore --------------------------" + coreIndex);
            activeCore.startScan(3000); // 5 seconds scan can be changed
             }else{
                android.util.Log.d(TAG, "active core is null: ");
                }
        }
        else {
            startAgainServices(activeCore);

        }
        }


    public void startAgainServices(SACore saCore){



        if (saCore == sacore1) {
            try {
                batteryService1.start(this, context);
                batteryService1.resume();
                sensoriaStreamingService1.start(SensoriaHandler.this, context);
                sensoriaStreamingService1.resume();


                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    updateConnectionStatus(1, "connected");
                }, 5000);


            } catch (InterruptedException e) {
                Log.e(TAG, "Error starting services: " + e.getMessage());
                updateConnectionStatus(2, "disconnected");

            }
        } else if (saCore == sacore2 ){
            try {
                batteryService2.start(this, context);
                batteryService2.resume();
                sensoriaStreamingService2.start(SensoriaHandler.this, context);
                sensoriaStreamingService2.resume();
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    updateConnectionStatus(2, "connected");
                }, 5000);

            } catch (InterruptedException e) {
                Log.e(TAG, "Error starting services: " + e.getMessage());
                updateConnectionStatus(2, "disconnected");

            }
        }else{
            Log.e(TAG, "Battery or Control Point Service is not available.");
        }



        isProcessing = false;
        processNextRequest();
    }

    private List<SADevice> discoveredDevices = new ArrayList<>();


    @Override

    public void didDeviceDiscovered(SACore saCore, SADevice saDevice) {
        // Add the discovered device to the list if not already present
        if (discoveredDevices.stream().noneMatch(d -> d.deviceMac.equals(saDevice.deviceMac))) {
            discoveredDevices.add(saDevice);
        }

    }



    @Override
    public void didDeviceDiscoveredUpdated(SACore saCore, SADevice saDevice, boolean disappeared) {}
    @Override
    public void didDeviceScanCompleted(SACore saCore) {
        if (!discoveredDevices.isEmpty()) {
            // sort devices by RSSI
            discoveredDevices.sort((d1, d2) -> Integer.compare(d2.returnRSSI(), d1.returnRSSI()));

            discoveredDevices.forEach(device ->
                    Log.d(TAG, "Sorted Device--------------: " + device.deviceName + " / rssi:" + device.returnRSSI()));

            // connect to the strongest(rssi) device if not already connected
            if (!discoveredDevices.isEmpty() && !isConnected(discoveredDevices.get(0))) {
                connectToDevice(discoveredDevices.get(0));
            }

            // after attempting to connect, mark the current request as processed
            isProcessing = false;
            processNextRequest(); // attempt to process the next request, if any
        }else {
            isProcessing= false;
            android.util.Log.d(TAG, "No device found");

            new Handler(Looper.getMainLooper()).postDelayed(() -> {

                        if (saCore == sacore1 && isConnected(device2)) {
                            updateConnectionStatus(1, "disconnected");
                        } else if (saCore == sacore2 && isConnected(device1)) {
                            updateConnectionStatus(2, "disconnected");
                        } else {
                            updateConnectionStatus(1, "disconnected");
                            updateConnectionStatus(2, "disconnected");
                        }
                    },2000);

            Handler mainHandler = new Handler(Looper.getMainLooper());
            String toastMessage = String.format(context.getString(R.string.no_sensoria_device_found));
            mainHandler.post(() -> Toast.makeText(context, toastMessage, Toast.LENGTH_SHORT).show());

        }

    }


    private void connectToDevice(SADevice device) {
        if (activeCore != null) {
            Log.d(TAG, "Connecting to--------: " + device.deviceName + " with RSSI: " + device.returnRSSI());
            activeCore.connect(device);
        } else {
            Log.d(TAG, "SACore instance is null, cannot connect to device.");
        }
    }


    private boolean isConnected(SADevice device) {
        // check if the device is already in the connectedDevices list
        return connectedDevices.stream().anyMatch(d -> d.deviceMac.equals(device.deviceMac));
    }



    @Override
    public void didConnecting(SACore saCore, SADevice saDevice) {}

    @Override
    public void didConnect(SACore saCore, SADevice saDevice) {
        Log.d(TAG, "Connected to---------------: " + saDevice.deviceName + " using SACore" + (saCore == sacore1 ? "1" : "2"));

        // Add the connected device to the list if it's not already present
        if (connectedDevices.stream().noneMatch(d -> d.deviceMac.equals(saDevice.deviceMac))) {
            connectedDevices.add(saDevice);
        }

        // remove the device from discoveredDevices to prevent re-connection attempts
        discoveredDevices.removeIf(d -> d.deviceMac.equals(saDevice.deviceMac));


        if (saCore == sacore1) {
            device1 = saDevice;
            updateConnectionStatus(1, "connected");
        } else if (saCore == sacore2) {
            device2 = saDevice;
            updateConnectionStatus(2, "connected");
        }

        isProcessing = false;
        processNextRequest();



    }


    public void disconnectDevice(int coreIndex) {
        SACore core = (coreIndex == 1) ? sacore1 : sacore2;
        CSBatteryService batteryService = (coreIndex == 1) ? batteryService1 : batteryService2;
        SAStreamingService sensoriaStreamingService = (coreIndex == 1) ? sensoriaStreamingService1 : sensoriaStreamingService2;

        // Stop Battery Service if not null
        if (batteryService != null ) {
            try {
                batteryService.pause();
                batteryService.stop();

                Log.d(TAG, "Battery service stopped for coreIndex " + coreIndex);
            } catch (Exception e) {
                Log.e(TAG, "Failed to stop battery service for coreIndex " + coreIndex, e);
            }
        }

        if (sensoriaStreamingService != null) {
            try {
                sensoriaStreamingService.pause();
                sensoriaStreamingService.stop();

                Log.d(TAG, "Streaming service stopped for coreIndex " + coreIndex);
            } catch (Exception e) {
                Log.e(TAG, "Failed to stop streaming service for coreIndex " + coreIndex, e);
            }
        }

//         Disconnect SACore
        if (core != null) {
            core.disconnect();

            Log.d(TAG, "Device with coreIndex " + coreIndex + " is disconnecting.");
        } else {
            Log.e(TAG, "Core not found for index: " + coreIndex);
        }

        if (core == sacore1) {
            updateConnectionStatus(1, "disconnected");
        } else if (core == sacore2) {
            updateConnectionStatus(2, "disconnected");
        }

        if(core.isConnected()){
            android.util.Log.d(TAG, "Still core connected============= : ");
        }else {
            android.util.Log.d(TAG, "not core connected================ : ");

        }


    }



    @Override
    public void didDisconnect(SACore saCore, SADevice saDevice) {

        Log.d(TAG, "Disconnected from: " + saDevice.deviceName + " using SACore" + (saCore == sacore1 ? "1" : "2"));

        // remove the disconnected device from the list
        connectedDevices.removeIf(d -> d.deviceMac.equals(saDevice.deviceMac));

        if (!discoveredDevices.contains(saDevice)) {
            discoveredDevices.add(saDevice);
        }

        isProcessing = false;
        processNextRequest();
    }
    @Override
    public void didDeviceError(SACore saCore, SADevice saDevice, SAErrors saErrors) {}
    @Override
    public void didUninitialized(SACore saCore) {}
    @Override
    public void didDeviceScanning(SACore saCore) {
        android.util.Log.d(TAG, "didDeviceScanning is starting-----------------------------");
    }

    @Override
    public void didServicesDiscovered(SACore saCore, SADevice saDevice) {


        List<SAService> services = saCore.getServiceDiscoveredList();
        if (services != null) {
            for (SAService service : services) {

                Log.d(TAG, "Service Name: " + service.mServiceName);
            }
        }

        try {
        if (saCore == sacore1) {
            batteryService1 = (CSBatteryService) saCore.getServiceByType(SAService.Service.BATTERY_SERVICE);
            sensoriaStreamingService1 = (SAStreamingService) saCore.getServiceByType(SAService.Service.SENSORIA_STREAMING_SERVICE);

        } else if (saCore == sacore2) {
            batteryService2 = (CSBatteryService) saCore.getServiceByType(SAService.Service.BATTERY_SERVICE);
            sensoriaStreamingService2 = (SAStreamingService) saCore.getServiceByType(SAService.Service.SENSORIA_STREAMING_SERVICE);

        }
        } catch (Exception e) {
            Log.e(TAG, "Error initializing services: " + e.getMessage(), e);
        }


        if (saCore == sacore1) {
            try {
                batteryService1.start(this, context);
                batteryService1.resume();

            } catch (InterruptedException e) {
                Log.e(TAG, "Error starting services: " + e.getMessage());
            }
        } else if (saCore == sacore2 ){
            try {
                batteryService2.start(this, context);
                batteryService2.resume();

            } catch (InterruptedException e) {
                Log.e(TAG, "Error starting services: " + e.getMessage());
            }
        }else{
            Log.e(TAG, "Battery or Control Point Service is not available.");
        }

        if (saCore == sacore1 ) {
            try {
                sensoriaStreamingService1.start(SensoriaHandler.this, context);
                sensoriaStreamingService1.resume();

            } catch (InterruptedException e) {
                Log.e(TAG, "Failed to start streaming service", e);
            }
        }else if (saCore == sacore2 ) {
            try {
                sensoriaStreamingService2.start(SensoriaHandler.this, context);
                sensoriaStreamingService2.resume();

            } catch (InterruptedException e) {
                Log.e(TAG, "Failed to start streaming service", e);
            }
        }




    }




    public void readBatteryLevelForCore(int coreIndex, final MethodChannel.Result result) {
        CSBatteryService batteryService = (coreIndex == 1) ? this.batteryService1 : this.batteryService2;

        if (batteryService != null) {
            int batteryLevel = batteryService.readBatteryLevel();
            if (batteryLevel >= 0) {
                Log.d(TAG, "Successfully read battery level: " + batteryLevel);
                result.success(batteryLevel);
            } else {
                Log.e(TAG, "Failed to read battery level");
                result.error("READ_FAILED", "Could not read battery level", null);
            }
        } else {
            Log.e(TAG, "Battery service not available for coreIndex: " + coreIndex);
            result.error("SERVICE_NOT_AVAILABLE", "Battery service not available", null);
        }
    }






    @Override
    public void didServiceStatusChange(SACore saCore, SADevice saDevice, Map<SAService.Service, Boolean> serviceStatus) {
        android.util.Log.d(TAG, "didServiceStatusChange: yes");
    }
    @Override
    public void didRemoteRssiRead(SACore saCore, SADevice saDevice, int rssi) {
        android.util.Log.d(TAG, "didRemoteRssiRead: "+rssi);
    }
    @Override
    public void didSignalLost(SACore saCore, SADevice saDevice) {
        android.util.Log.d(TAG, "didSignalLost: yes");
        updateConnectionStatus(saCore == sacore1 ? 1 : 2, "disconnected");

    }

//----------------------------Streaming Service Interface Callbacks ----------------------------------

@Override
public void didUpdateData(SADevice device, com.sensoria.sensorialibrary.SAService.Service service, final com.sensoria.sensorialibrary.SADataPoint dataPoint) {

    if (device == null || device.deviceMac == null) {
        Log.e(TAG, "Device or DeviceMac is null in didUpdateData.");
        return;
    }


    String footIndicator = (device.deviceMac.equals(device1 != null ? device1.deviceMac : "") ? "Right" : "Left");


    String formattedData = String.format(Locale.US, "%d,%d,%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%s",
            dataPoint.getChannels()[0],
            dataPoint.getChannels()[1],
            dataPoint.getChannels()[2],
            dataPoint.getAccelerometers()[0],
            dataPoint.getAccelerometers()[1],
            dataPoint.getAccelerometers()[2],
            dataPoint.getMagnetometers()[0],
            dataPoint.getMagnetometers()[1],
            dataPoint.getMagnetometers()[2],
            dataPoint.getGyroscopes()[0],
            dataPoint.getGyroscopes()[1],
            dataPoint.getGyroscopes()[2],
            dataPoint.getTimestamp(),
            footIndicator);



    synchronized(bufferLock) {

        dataBuffer1.add(formattedData);

        int size = dataBuffer1.size();

        if (dataBuffer1.size() >= BUFFER_SIZE_THRESHOLD) {

        String timestamp = String.valueOf(System.currentTimeMillis());
        String fileName = "S_" + timestamp + ".txt";


            startLocationUpdates();
            writeBufferToFile(context, fileName, dataBuffer1, lastKnownLatitude, lastKnownLongitude);

        dataBuffer1.clear();




        }
    }

}




    private void writeBufferToFile(Context context, String fileName, ArrayList<String> dataBuffer,double latitude,double longitude) {

//        File file = new File(context.getExternalFilesDir(null), fileName);

        File directory = context.getExternalFilesDir(null);
        if (directory != null && !directory.exists() && !directory.mkdirs()) {
            Log.e("SensoriaHandler", "Failed to create directory");
            return;
        }

        File file = new File(directory, fileName);
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(file))) {

            JSONArray structure = new JSONArray(Arrays.asList("S0","S1","S2","AccelX", "AccelY", "AccelZ", "MagX", "MagY", "MagZ", "GyroX", "GyroY", "GyroZ", "TimeStamp", "Foot"));

            //  json object metadata for the first line
            JSONObject metadata = new JSONObject();
            metadata.put("Id", idNumber);
            metadata.put("Type", "Sensoria");
            metadata.put("Structure", structure);
            metadata.put("Lat", latitude);
            metadata.put("Long", longitude);
            metadata.put("AppVersion", appVersion);


            if (device1 != null) {
                metadata.put("RF-DeviceMac", device1.deviceMac);
                metadata.put("RF-DeviceName", device1.deviceName);

            }
            if (device2 != null) {
                metadata.put("LF-DeviceMac", device2.deviceMac);
                metadata.put("LF-DeviceName", device2.deviceName);

            }



            writer.write(metadata.toString());
            writer.newLine();

            //  rest of the data
            for (String data : dataBuffer) {
                writer.write(data);
                writer.newLine();
            }
            Log.d("SensoriaHandler", "File written successfully: " + file.getAbsolutePath());
        } catch (Exception e) {
            Log.e("SensoriaHandler", "Error writing to file", e);
        }

        compressFile(file);
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


    //------------------Service Interface Callbacks------------------------------
@Override
public void didServiceError(SADevice device, SAService.Service service, String serviceName, String functionName, SAErrors errorCode, String innerErrorCode) {
    Log.e(TAG, "Service error in " + serviceName + "." + functionName + ": " + errorCode.name() + " | Inner code: " + innerErrorCode);
            updateConnectionStatus(device == device1 ? 1 : 2, "disconnected");

}

    @Override
    public void didServiceConnect(SADevice device, SAService.Service service) {
        // Handle service connection event
        Log.d(TAG, "Service connected: " + service.name());
    }

    @Override
    public void didServiceDisconnect(SADevice device, SAService.Service service) {
        // Handle service disconnection event
        Log.d(TAG, "Service disconnected: " + service.name());
    }

    @Override
    public void didServicePause(SADevice device, SAService.Service service) {
        // Handle service pause event
        Log.d(TAG, "Service paused: " + service.name());
    }

    @Override
    public void didServiceResume(SADevice device, SAService.Service service) {
        // Handle service resume event
        Log.d(TAG, "Service resumed: " + service.name());
    }

    @Override
    public void didServiceReady(SADevice device, SAService.Service service) {

    }

    @Override
    public void didServiceReset(SADevice device, SAService.Service service) {
        // Handle service reset event
        Log.d(TAG, "Service reset: " + service.name());
    }


}





