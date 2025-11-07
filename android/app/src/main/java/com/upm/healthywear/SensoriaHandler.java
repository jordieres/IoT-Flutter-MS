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
import com.google.gson.Gson;

import org.json.JSONObject;
import org.json.JSONArray;

public class SensoriaHandler implements SADeviceInterface, SAServiceStreamingServiceInterface, SAServiceInterface, CSBatteryServiceInterface, SAServiceControlPointInterface {
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

    public void setLocale(String languageCode) {
        Locale locale = new Locale(languageCode);
        Locale.setDefault(locale);
        Configuration config = new Configuration(context.getResources().getConfiguration());
        config.setLocale(locale);
        context.getResources().updateConfiguration(config, context.getResources().getDisplayMetrics());
    }

    private static final int REQUEST_CODE = 1;

    private SAStreamingService sensoriaStreamingService1;
    private SAStreamingService sensoriaStreamingService2;

    private CSBatteryService batteryService1;
    private CSBatteryService batteryService2;

    private SASensoriaControlPointService controlPoint1;
    private SASensoriaControlPointService controlPoint2;

    private ArrayList<String> dataBuffer1 = new ArrayList<>();
    private ArrayList<String> dataBuffer2 = new ArrayList<>();

    private final int BUFFER_SIZE_THRESHOLD = 3000;
    private final Object bufferLock = new Object();

    private volatile double lastKnownLatitude = 0.0;
    private volatile double lastKnownLongitude = 0.0;

    private List<SADevice> connectedDevices = new ArrayList<>();
    private List<SADevice> discoveredDevices = new ArrayList<>();

    private Long lastDataTimestampSensoriaCore1 = null;
    private Long lastDataTimestampSensoriaCore2 = null;
    private Long lastDataWriteTimestamp = null;

    private boolean core1Connected = false;
    private boolean core2Connected = false;

    public SensoriaHandler(Context context) {
        this.context = context;
        sacore1 = new SACore(this, context);
        sacore2 = new SACore(this, context);
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(context);
        startLocationUpdates();
    }

    // ==================== EVENT CONNECTION STATUS ====================
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

    // ==================== LOCATION UPDATES ====================
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
                    lastKnownLatitude = location.getLatitude();
                    lastKnownLongitude = location.getLongitude();
                }
            }
        };

        fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper());
    }

    // ==================== SCAN & CONNECT QUEUE ====================
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

    public void enqueueScanAndConnectRequest(int coreIndex) {
        ScanConnectRequest request = new ScanConnectRequest(coreIndex);
        requestQueue.add(request);
        processNextRequest();
    }

    private void processNextRequest() {
        if (!isProcessing && !requestQueue.isEmpty()) {
            isProcessing = true;
            ScanConnectRequest nextRequest = requestQueue.poll();
            nextRequest.process();
        }
    }

    // ==================== DEVICE INTERFACE CALLBACKS ====================
    @Override
    public void didInitialized(SACore saCore) {
    }

    public void scanAndConnectWithCores(int coreIndex) {
        activeCore = (coreIndex == 1) ? sacore1 : sacore2;
        if (activeCore == null) {
            Log.e(TAG, "Active core is null for coreIndex: " + coreIndex);
            isProcessing = false;
            processNextRequest();
            return;
        }

        if (!activeCore.isConnected()) {
            updateConnectionStatus(coreIndex, "connecting");
            discoveredDevices.clear(); // Clear previous scan results
            activeCore.startScan(3000);
        } else {
            // Already connected, restart services
            startAgainServices(activeCore);
        }
    }

    public void startAgainServices(SACore saCore) {
        if (saCore == null) {
            Log.e(TAG, "SACore is null in startAgainServices");
            isProcessing = false;
            processNextRequest();
            return;
        }

        int coreIndex = (saCore == sacore1) ? 1 : 2;

        if (saCore == sacore1) {
            try {
                if (batteryService1 != null) {
                    batteryService1.start(this, context);
                    batteryService1.resume();
                }
                if (sensoriaStreamingService1 != null) {
                    sensoriaStreamingService1.start(SensoriaHandler.this, context);
                    sensoriaStreamingService1.resume();
                }
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    updateConnectionStatus(1, "connected");
                }, 5000);
            } catch (InterruptedException e) {
                Log.e(TAG, "Error starting services for core 1: " + e.getMessage());
                updateConnectionStatus(1, "disconnected");
            }
        } else if (saCore == sacore2) {
            try {
                if (batteryService2 != null) {
                    batteryService2.start(this, context);
                    batteryService2.resume();
                }
                if (sensoriaStreamingService2 != null) {
                    sensoriaStreamingService2.start(SensoriaHandler.this, context);
                    sensoriaStreamingService2.resume();
                }
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    updateConnectionStatus(2, "connected");
                }, 5000);
            } catch (InterruptedException e) {
                Log.e(TAG, "Error starting services for core 2: " + e.getMessage());
                updateConnectionStatus(2, "disconnected");
            }
        }

        isProcessing = false;
        processNextRequest();
    }

    @Override
    public void didDeviceDiscovered(SACore saCore, SADevice saDevice) {
        if (saDevice == null || saDevice.deviceMac == null) {
            Log.w(TAG, "Discovered device is null");
            return;
        }
        // Add the discovered device to the list if not already present
        if (discoveredDevices.stream().noneMatch(d -> d != null && d.deviceMac != null && d.deviceMac.equals(saDevice.deviceMac))) {
            discoveredDevices.add(saDevice);
            Log.d(TAG, "Device discovered: " + saDevice.deviceName + " RSSI: " + saDevice.returnRSSI());
        }
    }

    @Override
    public void didDeviceDiscoveredUpdated(SACore saCore, SADevice saDevice, boolean disappeared) {
    }

    @Override
    public void didDeviceScanCompleted(SACore saCore) {
        int coreIdx = (saCore == sacore1) ? 1 : 2;

        if (!discoveredDevices.isEmpty()) {
            // Sort devices by RSSI (strongest first)
            discoveredDevices.sort((d1, d2) -> Integer.compare(d2.returnRSSI(), d1.returnRSSI()));

            for (SADevice device : discoveredDevices) {
                if (device != null) {
                    Log.d(TAG, "Sorted Device: " + device.deviceName + " / rssi: " + device.returnRSSI());
                }
            }

            // Connect to the strongest device if not already connected
            SADevice strongestDevice = discoveredDevices.get(0);
            if (strongestDevice != null && !isConnected(strongestDevice)) {
                connectToDevice(strongestDevice);
            } else {
                Log.d(TAG, "Strongest device is null or already connected");
                isProcessing = false;
                processNextRequest();
            }
        } else {
            isProcessing = false;
            Log.d(TAG, "No device found during scan");

            new Handler(Looper.getMainLooper()).postDelayed(() -> {
                if (saCore == sacore1 && device2 != null && core2Connected) {
                    updateConnectionStatus(1, "disconnected");
                } else if (saCore == sacore2 && device1 != null && core1Connected) {
                    updateConnectionStatus(2, "disconnected");
                } else {
                    updateConnectionStatus(coreIdx, "disconnected");
                }
            }, 2000);

            Handler mainHandler = new Handler(Looper.getMainLooper());
            String toastMessage = String.format(context.getString(R.string.no_sensoria_device_found));
            mainHandler.post(() -> Toast.makeText(context, toastMessage, Toast.LENGTH_SHORT).show());

            processNextRequest();
        }
    }

    private void connectToDevice(SADevice device) {
        if (activeCore != null && device != null) {
            Log.d(TAG, "Connecting to: " + device.deviceName + " with RSSI: " + device.returnRSSI());
            activeCore.connect(device);
        } else {
            Log.e(TAG, "Cannot connect: activeCore or device is null");
            isProcessing = false;
            processNextRequest();
        }
    }

    private boolean isConnected(SADevice device) {
        if (device == null || device.deviceMac == null) {
            return false;
        }
        return connectedDevices.stream().anyMatch(d -> d != null && d.deviceMac != null && d.deviceMac.equals(device.deviceMac));
    }

    @Override
    public void didConnecting(SACore saCore, SADevice saDevice) {
        int coreIdx = (saCore == sacore1) ? 1 : 2;
        updateConnectionStatus(coreIdx, "connecting");
    }

    @Override
    public void didConnect(SACore saCore, SADevice saDevice) {
        if (saDevice == null) {
            Log.e(TAG, "Connected device is null");
            isProcessing = false;
            processNextRequest();
            return;
        }

        int coreIdx = (saCore == sacore1) ? 1 : 2;
        Log.d(TAG, "Connected to: " + saDevice.deviceName + " using SACore" + coreIdx);

        // Add the connected device to the list if not already present
        if (connectedDevices.stream().noneMatch(d -> d != null && d.deviceMac != null && d.deviceMac.equals(saDevice.deviceMac))) {
            connectedDevices.add(saDevice);
        }

        // Remove from discovered list to prevent re-connection attempts
        if (discoveredDevices != null) {
            discoveredDevices.removeIf(d -> d != null && d.deviceMac != null && d.deviceMac.equals(saDevice.deviceMac));
        }

        if (saCore == sacore1) {
            device1 = saDevice;
            core1Connected = true;
            updateConnectionStatus(1, "connected");
        } else if (saCore == sacore2) {
            device2 = saDevice;
            core2Connected = true;
            updateConnectionStatus(2, "connected");
        }

        isProcessing = false;
        processNextRequest();
    }

    @Override
    public void didDisconnect(SACore saCore, SADevice saDevice) {
        if (saDevice == null) {
            Log.w(TAG, "Disconnect device is null");
            return;
        }

        int coreIdx = (saCore == sacore1) ? 1 : 2;
        Log.d(TAG, "Disconnected from: " + saDevice.deviceName);

        // Remove from connected list
        connectedDevices.removeIf(d -> d != null && d.deviceMac != null && d.deviceMac.equals(saDevice.deviceMac));

        // Add back to discovered list for re-scanning
        if (!discoveredDevices.stream().anyMatch(d -> d != null && d.deviceMac != null && d.deviceMac.equals(saDevice.deviceMac))) {
            discoveredDevices.add(saDevice);
        }

        if (saCore == sacore1) {
            core1Connected = false;
        } else if (saCore == sacore2) {
            core2Connected = false;
        }

        isProcessing = false;
        processNextRequest();
    }

    @Override
    public void didDeviceError(SACore saCore, SADevice saDevice, SAErrors saErrors) {
    }

    @Override
    public void didUninitialized(SACore saCore) {
    }

    @Override
    public void didDeviceScanning(SACore saCore) {
    }

    @Override
    public void didServicesDiscovered(SACore saCore, SADevice saDevice) {
        if (saCore == null) {
            Log.e(TAG, "SACore is null in didServicesDiscovered");
            return;
        }

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
                controlPoint1 = (SASensoriaControlPointService) saCore.getServiceByType(SAService.Service.SENSORIA_CONTROL_POINT_SERVICE);
            } else if (saCore == sacore2) {
                batteryService2 = (CSBatteryService) saCore.getServiceByType(SAService.Service.BATTERY_SERVICE);
                sensoriaStreamingService2 = (SAStreamingService) saCore.getServiceByType(SAService.Service.SENSORIA_STREAMING_SERVICE);
                controlPoint2 = (SASensoriaControlPointService) saCore.getServiceByType(SAService.Service.SENSORIA_CONTROL_POINT_SERVICE);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error initializing services: " + e.getMessage(), e);
        }

        // Start battery service
        if (saCore == sacore1) {
            try {
                if (batteryService1 != null) {
                    batteryService1.start(this, context);
                    batteryService1.resume();
                }
            } catch (InterruptedException e) {
                Log.e(TAG, "Error starting battery service for core 1: " + e.getMessage());
            }
        } else if (saCore == sacore2) {
            try {
                if (batteryService2 != null) {
                    batteryService2.start(this, context);
                    batteryService2.resume();
                }
            } catch (InterruptedException e) {
                Log.e(TAG, "Error starting battery service for core 2: " + e.getMessage());
            }
        }

        // Start streaming service
        if (saCore == sacore1) {
            try {
                if (sensoriaStreamingService1 != null) {
                    sensoriaStreamingService1.start(SensoriaHandler.this, context);
                    sensoriaStreamingService1.resume();
                }
            } catch (InterruptedException e) {
                Log.e(TAG, "Failed to start streaming service for core 1: " + e.getMessage());
            }
        } else if (saCore == sacore2) {
            try {
                if (sensoriaStreamingService2 != null) {
                    sensoriaStreamingService2.start(SensoriaHandler.this, context);
                    sensoriaStreamingService2.resume();
                }
            } catch (InterruptedException e) {
                Log.e(TAG, "Failed to start streaming service for core 2: " + e.getMessage());
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
        Log.d(TAG, "didServiceStatusChange: yes");
    }

    @Override
    public void didRemoteRssiRead(SACore saCore, SADevice saDevice, int rssi) {
        Log.d(TAG, "didRemoteRssiRead: " + rssi);
    }

    @Override
    public void didSignalLost(SACore saCore, SADevice saDevice) {
        Log.d(TAG, "didSignalLost");
        int coreIdx = (saCore == sacore1) ? 1 : 2;
        updateConnectionStatus(coreIdx, "disconnected");
    }

    // ==================== STREAMING SERVICE CALLBACKS ====================
    @Override
    public void didUpdateData(SADevice device, com.sensoria.sensorialibrary.SAService.Service service, final com.sensoria.sensorialibrary.SADataPoint dataPoint) {

        if (device == null || device.deviceMac == null || dataPoint == null) {
            Log.e(TAG, "Device, DeviceMac or DataPoint is null in didUpdateData");
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

        synchronized (bufferLock) {
            dataBuffer1.add(formattedData);

            if (footIndicator.equals("Right")) {
                lastDataTimestampSensoriaCore1 = System.currentTimeMillis();
            } else {
                lastDataTimestampSensoriaCore2 = System.currentTimeMillis();
            }

            if (dataBuffer1.size() >= BUFFER_SIZE_THRESHOLD) {
                String timestamp = String.valueOf(System.currentTimeMillis());
                String fileName = "S_" + timestamp + ".txt";

                startLocationUpdates();
                writeBufferToFile(context, fileName, dataBuffer1, lastKnownLatitude, lastKnownLongitude);
                dataBuffer1.clear();
            }
        }
    }

    private void writeBufferToFile(Context context, String fileName, ArrayList<String> dataBuffer, double latitude, double longitude) {
        File directory = context.getExternalFilesDir(null);
        if (directory != null && !directory.exists() && !directory.mkdirs()) {
            Log.e(TAG, "Failed to create directory");
            return;
        }

        File file = new File(directory, fileName);
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(file))) {

            JSONArray structure = new JSONArray(Arrays.asList("S0", "S1", "S2", "AccelX", "AccelY", "AccelZ", "MagX", "MagY", "MagZ", "GyroX", "GyroY", "GyroZ", "TimeStamp", "Foot"));

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

            for (String data : dataBuffer) {
                writer.write(data);
                writer.newLine();
            }
            Log.d(TAG, "File written successfully: " + file.getAbsolutePath());

        } catch (Exception e) {
            Log.e(TAG, "Error writing to file", e);
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
            while ((len = fis.read(buffer)) != -1) {
                gzipOS.write(buffer, 0, len);
            }

            lastDataWriteTimestamp = System.currentTimeMillis();
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

    // ==================== SERVICE INTERFACE CALLBACKS ====================
    @Override
    public void didServiceError(SADevice device, SAService.Service service, String serviceName, String functionName, SAErrors errorCode, String innerErrorCode) {
        if (device == null) {
            Log.e(TAG, "Service error: device is null");
            return;
        }
        int coreIdx = (device == device1) ? 1 : 2;
        Log.e(TAG, "Service error in " + serviceName + "." + functionName + ": " + errorCode.name() + " | Inner code: " + innerErrorCode);
        updateConnectionStatus(coreIdx, "disconnected");
    }

    @Override
    public void didServiceConnect(SADevice device, SAService.Service service) {
        Log.d(TAG, "Service connected: " + service.name());
    }

    @Override
    public void didServiceDisconnect(SADevice device, SAService.Service service) {
        Log.d(TAG, "Service disconnected: " + service.name());
    }

    @Override
    public void didServicePause(SADevice device, SAService.Service service) {
        Log.d(TAG, "Service paused: " + service.name());
    }

    @Override
    public void didServiceResume(SADevice device, SAService.Service service) {
        Log.d(TAG, "Service resumed: " + service.name());
    }

    @Override
    public void didServiceReady(SADevice device, SAService.Service service) {
    }

    @Override
    public void didServiceReset(SADevice device, SAService.Service service) {
        Log.d(TAG, "Service reset: " + service.name());
    }

    @Override
    public void didServiceAccelerometerSamplingRateSet(SADevice d, SAService.Service s, short v) {}
    @Override
    public void didServiceAccelerometerSamplingRangeSet(SADevice d, SAService.Service s, short v) {}
    @Override
    public void didServiceGyroscopeSamplingRateSet(SADevice d, SAService.Service s, short v) {}
    @Override
    public void didServiceGyroscopeSamplingRangeSet(SADevice d, SAService.Service s, short v) {}
    @Override
    public void didServiceMagnetometerSamplingRateSet(SADevice d, SAService.Service s, short v) {}
    @Override
    public void didServiceMagnetometerSamplingRangeSet(SADevice d, SAService.Service s, short v) {}
    @Override
    public void didServiceMagnetometerCalibrationValuesSet(SADevice d, SAService.Service s, short[] v) {}
    @Override
    public void didServiceMagnetometerCalibrated(SADevice d, SAService.Service s, boolean v) {}
    @Override
    public void didServiceTimeoutSet(SADevice d, SAService.Service s, short v1, short v2) {}
    @Override
    public void didServiceConfigurationStorageSet(SADevice d, SAService.Service s, ConfigurationStorage v) {}
    @Override
    public void didServiceCalibrationIncrement(SADevice d, SAService.Service s, short v) {}
    @Override
    public void didServiceSamplingPeriodSet(SADevice d, SAService.Service s, short v) {}
    @Override
    public void didServiceChannelProtocolTypeSet(SADevice d, SAService.Service s, short v) {}
    @Override
    public void didServiceChannelPropertySet(SADevice d, SAService.Service s, short ch, ChannelBitsEnum prop) {}
    @Override
    public void didServiceWriteChannelSettings(SADevice d, SAService.Service s, short status) {}
    @Override
    public void didServiceHapticDriverMotorAcquired(SADevice d, SAService.Service s, boolean v) {}
    @Override
    public void didServiceHapticDriverMotorInitialized(SADevice d, SAService.Service s, short v) {}
    @Override
    public void didServiceHapticDriverMotorReleased(SADevice d, SAService.Service s, boolean v) {}
    @Override
    public void didServiceHapticDriverMotorOn(SADevice d, SAService.Service s, byte a, byte b, byte c, byte d2) {}
    @Override
    public void didServiceHapticDriverMotorOff(SADevice d, SAService.Service s, boolean v) {}
    @Override
    public void didServiceAutoWakeUpModeSourcesSet(SADevice d, SAService.Service s, byte a, byte b, byte c) {}
    @Override
    public void didPauseLED(SADevice d, SAService.Service s, boolean v) {}

    // ==================== DISCONNECT DEVICE ====================
    public void disconnectDevice(int coreIndex) {
        SACore core = (coreIndex == 1) ? sacore1 : sacore2;
        CSBatteryService batteryService = (coreIndex == 1) ? batteryService1 : batteryService2;
        SAStreamingService sensoriaStreamingService = (coreIndex == 1) ? sensoriaStreamingService1 : sensoriaStreamingService2;
        SASensoriaControlPointService controlPoint = (coreIndex == 1) ? controlPoint1 : controlPoint2;

        // Stop streaming service
        if (sensoriaStreamingService != null) {
            try {
                sensoriaStreamingService.pause();
                sensoriaStreamingService.stop();
                Log.d(TAG, "Streaming service stopped for coreIndex " + coreIndex);
            } catch (Exception e) {
                Log.e(TAG, "Failed to stop streaming service for coreIndex " + coreIndex, e);
            }
        }

        // Stop control point service
        if (controlPoint != null) {
            try {
                controlPoint.pause();
                controlPoint.stop();
                Log.d(TAG, "Control point service stopped for coreIndex " + coreIndex);
            } catch (Exception e) {
                Log.e(TAG, "Failed to stop control point service for coreIndex " + coreIndex, e);
            }
        }

        // Stop battery service
        if (batteryService != null) {
            try {
                batteryService.pause();
                batteryService.stop();
                Log.d(TAG, "Battery service stopped for coreIndex " + coreIndex);
            } catch (Exception e) {
                Log.e(TAG, "Failed to stop battery service for coreIndex " + coreIndex, e);
            }
        }

        // Disconnect SACore
        if (core != null) {
            core.disconnect();
            Log.d(TAG, "Device with coreIndex " + coreIndex + " is disconnecting.");
        } else {
            Log.e(TAG, "Core not found for index: " + coreIndex);
        }

        if (coreIndex == 1) {
            core1Connected = false;
            updateConnectionStatus(1, "disconnected");
        } else if (coreIndex == 2) {
            core2Connected = false;
            updateConnectionStatus(2, "disconnected");
        }
    }

    // ==================== GET STATUS ====================
    public String getCurrentStatus(int coreIndex) {
        Log.d(TAG, "getCurrentStatus: Request received for Sensoria core " + coreIndex);
        Gson gson = new Gson();
        Map<String, Object> statusMap = new HashMap<>();

        if (coreIndex == 1) {
            statusMap.put("lastDataTimestampSensoriaCore", lastDataTimestampSensoriaCore1);
            statusMap.put("lastDataWriteTimestampSensoria", lastDataWriteTimestamp);
            statusMap.put("isConnected", core1Connected);
        } else if (coreIndex == 2) {
            statusMap.put("lastDataTimestampSensoriaCore", lastDataTimestampSensoriaCore2);
            statusMap.put("lastDataWriteTimestampSensoria", lastDataWriteTimestamp);
            statusMap.put("isConnected", core2Connected);
        } else {
            statusMap.put("lastDataTimestampSensoriaCore", "N/A");
            statusMap.put("lastDataWriteTimestampSensoria", "N/A");
            statusMap.put("isConnected", false);
        }

        String statusJson = gson.toJson(statusMap);
        Log.d(TAG, "getCurrentStatus: The statusMap for core " + coreIndex + " is " + statusJson);

        return statusJson;
    }
}