package com.upm.healthywear;



import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.app.Activity;
import android.util.Log;
import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.DialogInterface;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;


import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

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


import java.util.Arrays;
import java.util.UUID;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;
import java.util.Date;
import java.io.File;
import java.io.IOException;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.text.SimpleDateFormat;

import com.google.gson.Gson;//optional can be removed
import org.json.JSONObject;











public class SensoriaHandler implements SADeviceInterface,SAServiceStreamingServiceInterface,SAServiceInterface,CSBatteryServiceInterface {
    private Context context;
    private SACore sacore1, sacore2;
    private SACore activeCore = null;
    private final String TAG = "SensoriaHandler";

    private CSBatteryService batteryService1;
    private CSBatteryService batteryService2;

    private SASensoriaControlPointService sensoriaControlPointService;

    private SADevice device1, device2;

//    private SAProcessedDataLogger processedDataLogger;

    private String prescriptionRefNumber = "";

    public void setPrescriptionRefNumber(String refNumber) {
        this.prescriptionRefNumber = refNumber;
    }




    private static final int REQUEST_CODE = 1;

    private SAStreamingService sensoriaStreamingService1;
    private SAStreamingService sensoriaStreamingService2;

    private ArrayList<String> dataBuffer1 = new ArrayList<>();
    private ArrayList<String> dataBuffer2 = new ArrayList<>();

    private final int BUFFER_SIZE_THRESHOLD = 1500;




    public SensoriaHandler(Context context) {
        this.context = context;
        sacore1 = new SACore(this, context);
        sacore2 = new SACore(this, context);

    }


    // start scanning with the specified core.
    public void scanAndConnectWithCores(int coreIndex) {
        activeCore = (coreIndex == 1) ? sacore1 : sacore2;
        if (activeCore != null) {
            Log.d(TAG, "Starting scan with SACore" + coreIndex);
            activeCore.startScan(5000); // 5 seconds scan can be changed
        }
    }


//--------------------------------Device Interface Callbacks------------------------------
    @Override
    public void didDeviceDiscovered(SACore saCore, SADevice saDevice) {
        if (saCore == activeCore) {
            Log.d(TAG, "Auto-connecting to: " + saDevice.deviceName);
            activeCore.connect(saDevice); //auto connection to the first discovered device.
            activeCore = null;

        }
    }

    @Override
    public void didConnect(SACore saCore, SADevice saDevice) {
        Log.d(TAG, "Connected to: " + saDevice.deviceName + " using SACore" + (saCore == sacore1 ? "1" : "2"));
        if (saCore == sacore1) {
            device1 = saDevice;
        } else if (saCore == sacore2) {
            device2 = saDevice;
        }

    }

    @Override
    public void didInitialized(SACore saCore) {
        android.util.Log.d(TAG, "the core is initializedddddddddddddddddddddd");
    }
    @Override
    public void didDeviceDiscoveredUpdated(SACore saCore, SADevice saDevice, boolean disappeared) {}
    @Override
    public void didDeviceScanCompleted(SACore saCore) {}
    @Override
    public void didConnecting(SACore saCore, SADevice saDevice) {}
    @Override
    public void didDisconnect(SACore saCore, SADevice saDevice) {}
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
        Log.d(TAG, "Service discovery completed for device: " + saDevice.deviceName);

        //getting list of device Services-optional
        List<SAService> services = saCore.getServiceDiscoveredList();
        if (services != null) {
            Log.d(TAG, "Discovered services:");
            for (SAService service : services) {
                // Log the service name as a substitute for the UUID
                Log.d(TAG, "Service Name: " + service.mServiceName);
            }
        }

        //access the battery service directly from the SACore instance
        batteryService1 = (CSBatteryService) saCore.getServiceByType(SAService.Service.BATTERY_SERVICE);


        if (batteryService1 != null ) {
            try {
                batteryService1.start(this, context);
                batteryService1.resume();

            } catch (InterruptedException e) {
                Log.e(TAG, "Error starting services: " + e.getMessage());
            }
        } else {
            Log.e(TAG, "Battery or Control Point Service is not available.");
        }

        sensoriaStreamingService1 = (SAStreamingService) saCore.getServiceByType(SAService.Service.SENSORIA_STREAMING_SERVICE);


    }


    private void readBatteryLevel() {
        int batteryLevel = batteryService1.readBatteryLevel();
        if (batteryLevel >= 0) {
            Log.d(TAG, "Battery level is: " + batteryLevel + "%");
        } else {
            Log.e(TAG, "Failed to read battery level.");
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
    }

//----------------------------Streaming Service Interface Callbacks ----------------------------------

@Override
public void didUpdateData(SADevice device, com.sensoria.sensorialibrary.SAService.Service service, final com.sensoria.sensorialibrary.SADataPoint dataPoint) {
//    Log.d(TAG, "Received Data: " + dataPoint.toString());
    Log.d(TAG, "Updating Data for Device: " + device.deviceName + ", Device1: " + (device1 != null ? device1.deviceName : "null") + ", Device2: " + (device2 != null ? device2.deviceName : "null"));

    String footIndicator = (device.deviceMac.equals(device1.deviceMac)) ? "Right" : "Left";

    String formattedData = String.format(Locale.US,
            "Device: %s ,Foot: %s, Tick: %d, Sample Rates: Actual %d Hz, Nominal %d Hz, Packets Lost: %d, "
                    + "Channels: [0] %d, [1] %d, [2] %d, "
                    + "Accel: [X] %f, [Y] %f, [Z] %f, "
                    + "Mag: [X] %f, [Y] %f, [Z] %f, "
                    + "Gyro: [X] %f, [Y] %f, [Z] %f"
                    + "Timestamp :Timestamp: %d",
            device.deviceName,footIndicator,
            dataPoint.getTickCount(),
            dataPoint.getActualSamplingRate(),
            dataPoint.getNominalSamplingRate(),
            dataPoint.getPacketsLost(),
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
            dataPoint.getTimestamp());

    Log.d("SensoriaHandler", formattedData);

//    processedDataLogger.logDataPoint(dataPoint.toRawDataString() + ",1,2,3");

    dataBuffer1.add(formattedData);
    int size=dataBuffer1.size();
    android.util.Log.d(TAG, "data buffer size------------------"+size);

    if (dataBuffer1.size() >= BUFFER_SIZE_THRESHOLD) {

//        String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date());
        String timestamp=String.valueOf(System.currentTimeMillis());
        String fileName = "sensoria_" + timestamp + ".txt";

        writeBufferToFile(context, fileName, dataBuffer1);

        ///////////////if i want to save in different buffer and files/////////////////
        // selecting which buffer to use based on the device
//        ArrayList<String> targetBuffer = (device == device1) ? dataBuffer1 : dataBuffer2;
//        targetBuffer.add(formattedData);
//
//        if (targetBuffer.size() >= BUFFER_SIZE_THRESHOLD) {
//            // write the buffer to file
//            String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date());
//            String fileName = "sensoria_" + footIndicator + "_" + timestamp + ".txt";
//            writeBufferToFile(context, fileName, targetBuffer);
//            targetBuffer.clear();
//        }
        //////////


        dataBuffer1.clear();
    }

}

//    private void writeBufferToFile(Context context, String fileName, ArrayList<String> dataBuffer) {
//        File file = new File(context.getExternalFilesDir(null), fileName);
//        try {
//            BufferedWriter writer = new BufferedWriter(new FileWriter(file, true)); // Append mode
//            for (String data : dataBuffer) {
//                writer.write(data);
//                writer.newLine();
//            }
//            writer.close();
//            Log.d("SensoriaHandler", "File written successfully: " + file.getAbsolutePath());
//        } catch (IOException e) {
//            Log.e("SensoriaHandler", "Error writing to file", e);
//        }
//    }

    private void writeBufferToFile(Context context, String fileName, ArrayList<String> dataBuffer) {
        File file = new File(context.getExternalFilesDir(null), fileName);
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(file))) {

            // create a json object for the firstb line
            JSONObject packInfo = new JSONObject();
            packInfo.put("codeId", prescriptionRefNumber);

            // write the json object as the first line of the file
            writer.write(packInfo.toString());
            writer.newLine();

            //  write the rest of the data
            for (String data : dataBuffer) {
                writer.write(data);
                writer.newLine();
            }
            Log.d("SensoriaHandler", "File written successfully: " + file.getAbsolutePath());
        } catch (Exception e) {
            Log.e("SensoriaHandler", "Error writing to file", e);
        }
    }



    //------------------Service Interface Callbacks------------------------------
@Override
public void didServiceError(SADevice device, SAService.Service service, String serviceName, String functionName, SAErrors errorCode, String innerErrorCode) {
    // Log or handle service errors
    Log.e(TAG, "Service error in " + serviceName + "." + functionName + ": " + errorCode.name() + " | Inner code: " + innerErrorCode);
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

        Log.d(TAG, "Service readyyyyyyyyyyyy: " + service.name());

        readBatteryLevel();



        if (sensoriaStreamingService1 != null ) {
            try {
                sensoriaStreamingService1.start(SensoriaHandler.this, context);
                sensoriaStreamingService1.resume();

            } catch (InterruptedException e) {
                Log.e(TAG, "Failed to start streaming service", e);
            }
        }


    }

    @Override
    public void didServiceReset(SADevice device, SAService.Service service) {
        // Handle service reset event
        Log.d(TAG, "Service reset: " + service.name());
    }


}





