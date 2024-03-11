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
import android.location.Location;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;


import java.io.File;
import java.io.IOException;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.util.Set;
import java.util.Map;
import java.util.List;
import java.util.Queue;
import java.util.HashMap;
import java.util.HashSet;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.zip.GZIPOutputStream;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;

import io.flutter.plugin.common.MethodChannel;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import okhttp3.*;

import org.json.JSONObject;
import org.json.JSONException;


import com.google.gson.Gson;//optional can be removed
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.FusedLocationProviderClient;



import com.mbientlab.metawear.Route;
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
import com.mbientlab.metawear.module.Led;
import com.mbientlab.metawear.module.Accelerometer;
import com.mbientlab.metawear.module.AccelerometerBmi270;
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




public class MetaWearHandler implements ServiceConnection {
    private BtleService.LocalBinder serviceBinder;
    private Context context;
    private final String TAG = "MetaWearHandler";
    private MetaWearBoard board;
    private Set<BluetoothDevice> scannedDevices = new HashSet<>();

    private Map<String, Handler> deviceHandlers = new HashMap<>();
    private Map<String, Runnable> deviceRunnables = new HashMap<>();

    private String prescriptionRefNumber = "";

    public void setPrescriptionRefNumber(String refNumber) {
        this.prescriptionRefNumber = refNumber;

    }

    private FusedLocationProviderClient fusedLocationClient;


    // interface for sensor data
    interface SensorData {
        String toFileString();
    }

    private ScanCallback leScanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            BluetoothDevice device = result.getDevice();
            if (device.getName() != null && device.getName().startsWith("MetaWear")) {
                scannedDevices.add(device);
                Log.d(TAG, "Found MetaWear Board: " + device.getName());
            }
        }
    };

    private List<AccelerometerData> accelerometerBuffer = new ArrayList<>();
    private List<MagnetometerData> magnetometerBuffer = new ArrayList<>();




//    private List<AccelerometerData> leftHandBuffer = new ArrayList<>();
//    private List<AccelerometerData> rightHandBuffer = new ArrayList<>();

    private static final int BUFFER_SIZE = 1500;


    public MetaWearHandler(Context context) {
        this.context = context;
        Intent bindIntent = new Intent(context, BtleService.class);
        context.bindService(bindIntent, this, Context.BIND_AUTO_CREATE);
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(context);

    }

    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
        serviceBinder = (BtleService.LocalBinder) service;
        Log.d(TAG, "Service connected: " + name.toString());
    }

    @Override
    public void onServiceDisconnected(ComponentName componentName) {
        serviceBinder = null;
        Log.d(TAG, "Service disconnected: " + componentName.toString());
    }

    public void startScanning() {
        BluetoothAdapter bluetoothAdapter = ((BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE)).getAdapter();
        bluetoothAdapter.getBluetoothLeScanner().startScan(leScanCallback);
        Log.d(TAG, "Started scanning for MetaWear boards.");
    }

    public void stopScanning() {
        BluetoothAdapter bluetoothAdapter = ((BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE)).getAdapter();
        bluetoothAdapter.getBluetoothLeScanner().stopScan(leScanCallback);
        Log.d(TAG, "Stopped scanning for MetaWear boards.");
    }

    public Set<BluetoothDevice> getScannedDevices() {
        return scannedDevices;
    }

    public void connectToMetaWearBoard(String macAddress,String hand) {
        Log.d(TAG, "Attempting to connect to MetaWear Board with MAC: " + macAddress + hand);

        final BluetoothManager btManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        final BluetoothDevice remoteDevice = btManager.getAdapter().getRemoteDevice(macAddress);

        if (serviceBinder != null) {
            board = serviceBinder.getMetaWearBoard(remoteDevice);
            board.connectAsync().continueWith(task -> {
                if (task.isFaulted()) {
                    Log.e(TAG, "Failed to connect to " + macAddress);
                } else {
                    Log.i(TAG, "Connected to " + macAddress);

                    blinkLed(macAddress, hand, 6);
                    Log.d(TAG, "send connect led to the method blinled "+macAddress+hand);
                }
                return null;
            });
        } else {
            Log.e(TAG, "Service Binder is null. Cannot connect to MetaWear Board.");
        }
    }


    public void blinkLed(String macAddress, String hand, int blinkCount) {
        MetaWearBoard board = getBoard(macAddress);
        Log.d(TAG, "receive led blinking for board: "+board);
        if (board != null) {
            Led led = board.getModule(Led.class);
            Log.d(TAG, "the led is : "+led);
            if (led != null) {
                Log.d(TAG, "try to turn on the led for  "+hand+blinkCount);
                Led.Color ledColor = hand.equals("left") ? Led.Color.GREEN : Led.Color.RED;
                led.editPattern(ledColor, Led.PatternPreset.BLINK)
                        .repeatCount((byte) blinkCount)
                        .commit();
                led.play();
            } else {
                Log.e(TAG, "LED module not available for " + macAddress);
            }
        } else {
            Log.e(TAG, "Board not connected for " + macAddress);
        }
    }


    private void startPeriodicLedBlink(String macAddress, String hand) {
        MetaWearBoard board = getBoard(macAddress);
        if (board == null) return;

        Led led = board.getModule(Led.class);
        if (led == null) return;

        Led.Color color = hand.equals("left") ? Led.Color.RED : Led.Color.GREEN;

        Handler handler = new Handler(Looper.getMainLooper());
        Runnable ledBlinkRunnable = new Runnable() {
            @Override
            public void run() {
                try {
                    if (checkDataStreaming(macAddress)) {
                        blinkLed(macAddress, hand, 2); // blink the led once every minute if streaming

                    }
                } catch (Exception e) {
                    Log.e(TAG, "Error checking data streaming: " + e.getMessage());

                }
                handler.postDelayed(this, 60000); // repeat every 60 seconds
            }
        };

        handler.post(ledBlinkRunnable);
    }

    public void getBatteryLevel(String macAddress, MethodChannel.Result result) {
        MetaWearBoard board = getBoard(macAddress);
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




    public boolean isBoardConnected(String macAddress) {
        MetaWearBoard board = getBoard(macAddress);
        return board != null && board.isConnected();
    }


    public boolean checkDataStreaming(String macAddress) throws Exception {
        MetaWearBoard board = getBoard(macAddress);
        if (board != null && board.isConnected()) {
            // check if data is being streamed like  accelerometer data
            // it will return true if streaming is active
            boolean isStreaming = true;

            if (!isStreaming) {
                throw new Exception("Data is not streaming");
            }
            return true;
        } else {
            throw new Exception("Board not connected or not found");
        }
    }



    private void setupLedModule() {
        if (board != null) {
            Led led = board.getModule(Led.class);
            if (led != null) {
                led.editPattern(Led.Color.RED, Led.PatternPreset.BLINK)
                        .repeatCount((byte) 3)
                        .commit();
                led.play();
            } else {
                Log.d(TAG, "LED Module not available");
            }
        } else {
            Log.e(TAG, "MetaWear board is not connected.");
        }
    }


    private MetaWearBoard getBoard(String macAddress) {
        final BluetoothManager btManager =
                (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        final BluetoothDevice remoteDevice =
                btManager.getAdapter().getRemoteDevice(macAddress);

        if (serviceBinder != null) {
            return serviceBinder.getMetaWearBoard(remoteDevice);
        }
        return null;
    }


//    public void blinkLed() {
//        Log.d(TAG, "receive request");
//        MetaWearBoard board = getBoard("E8:D4:6C:D3:DD:2E");
//        Log.d(TAG, "trying to turn on led to board:  "+board);
//        Led led = board.getModule(Led.class);
//        Log.d(TAG, "trying to turn on led to led module: "+led);
//        if (led != null) {
//
//            Led.PatternEditor editor = led.editPattern(Led.Color.BLUE, Led.PatternPreset.BLINK);
//            editor.repeatCount((byte) 3).commit();
//            led.play();
//
//        }
//    }

    public void setupDevices(String macAddress, String hand) {
        MetaWearBoard board = getBoard(macAddress);
        if (board != null) {

            //setup accelerometer
            setupAccelerometer(board, macAddress, hand);

            //setup magnetometer
            setupMagnetometer(board, macAddress, hand);


        } else {
            Log.e(TAG, "MetaWear board not connected.");
        }

    }


//----------------------Setup Accelerometer-----------------------------------------------
    private void setupAccelerometer(MetaWearBoard board, String macAddress, String hand) {
        Accelerometer accelerometer = board.getModule(Accelerometer.class);

        if (accelerometer != null) {
            accelerometer.configure()
                    .odr(70f)
                    .range(4f)
                    .commit();

            accelerometer.acceleration().addRouteAsync(source ->
                            source.stream((data, env) -> {
                                Acceleration value = data.value(Acceleration.class);
                                long timestamp = System.currentTimeMillis();

                                // logging accelerometer data based on hand
//                                    Log.d(hand.equals("left") ? "LeftHandAccel" : "RightHandAccel", "Acceleration: " + value);
                                //initiate led blink process
                                startPeriodicLedBlink(macAddress, hand);

                                // Add data to buffer
                                synchronized (accelerometerBuffer) {
                                    accelerometerBuffer.add(new AccelerometerData(value.x(), value.y(), value.z(), timestamp, hand));

                                    if (accelerometerBuffer.size() >= BUFFER_SIZE) {
                                        List<SensorData> sensorDataList = new ArrayList<>(accelerometerBuffer);
                                        fetchLocationAndSaveData("MA", sensorDataList);
                                        accelerometerBuffer.clear();
                                    }
                                }

                                Log.d(TAG, String.format("Acceleration: x=%.3f, y=%.3f, z=%.3f, hand=%s, timestamp=%d",
                                        value.x(), value.y(), value.z(), hand, timestamp));
                            })
            ).continueWith(task -> {
                if (task.isFaulted()) {
                    Log.e(TAG, "Failed to configure route for accelerometer", task.getError());
                } else {
                    accelerometer.acceleration().start();
                    accelerometer.start();
                    startPeriodicLedBlink(macAddress, hand); //start periodic blinking

                }
                return null;
            });
        } else {
            Log.e(TAG, "This device does not have an accelerometer.");
        }
    }



////------------Setup Magnetometer--------------------------------------------

    private void setupMagnetometer(MetaWearBoard board, String macAddress, String hand) {
        MagnetometerBmm150 magnetometer = board.getModule(MagnetometerBmm150.class);

        if (magnetometer != null) {
//            Log.d(TAG, "magnemete is not null ------------------------");

            //using a preset setting or we can define manually
            magnetometer.usePreset(MagnetometerBmm150.Preset.REGULAR);


            //todo: i can remove this manual config as i have already use preset REGULAR
            magnetometer.configure()
                    .outputDataRate(MagnetometerBmm150.OutputDataRate.ODR_30_HZ)
                    .commit();

            //start magnetic field measurements
            magnetometer.magneticField().addRouteAsync(source -> source.stream((data, env) -> {

//                Log.d(TAG, "Magnetometer data stream callback entered");

                float x = data.value(MagneticField.class).x();
                float y = data.value(MagneticField.class).y();
                float z = data.value(MagneticField.class).z();
                long timestamp = System.currentTimeMillis();

                //assuming hand is a variable that stores which hand is being used
                Log.d(TAG, "Magnetometer data for " + hand + " hand: x=" + x + ", y=" + y + ", z=" + z);


                synchronized (magnetometerBuffer) {
                    magnetometerBuffer.add(new MagnetometerData(x, y, z, timestamp, hand));

                    if (magnetometerBuffer.size() >= BUFFER_SIZE) {
                        List<SensorData> sensorDataList = new ArrayList<>(magnetometerBuffer);
                        fetchLocationAndSaveData("MM", sensorDataList);
                        magnetometerBuffer.clear();
                    }
                }

            })).continueWith(task -> {
                if (!task.isFaulted()) {
//                    Log.d(TAG, "Magnetometer route successfully configured");
                    magnetometer.magneticField().start();
                    magnetometer.start();
                } else {
                    Log.e(TAG, "Failed to configure magnetometer route", task.getError());
                }
                return null;
            });
        } else {
            Log.e(TAG, "This device does not have a magnetometer.");
        }
    }

    // accelerometerData class implementing SensorData
    class AccelerometerData implements SensorData {
        public float x, y, z;
        public long timestamp;
        public String hand; // "left" or "right"

        public AccelerometerData(float x, float y, float z, long timestamp, String hand) {
            this.x = x;
            this.y = y;
            this.z = z;
            this.timestamp = timestamp;
            this.hand = hand;
        }

        @Override
        public String toFileString() {
//            return x + ", " + y + ", " + z + ", " + timestamp + ", " + hand;
            return "Accel: "+ "[X] "+ x + ", " + "[Y] "+ y + ", " + "[Z] "+ z + ", " +"[Timestamp:] "+ timestamp + ", " +"[hand:] "+ hand;

        }
    }

    class MagnetometerData implements SensorData {
        public float x, y, z;
        public long timestamp;
        public String hand;

        public MagnetometerData(float x, float y, float z, long timestamp, String hand) {
            this.x = x;
            this.y = y;
            this.z = z;
            this.timestamp = timestamp;
            this.hand = hand;
        }
        @Override
        public String toFileString() {
            return x + ", " + y + ", " + z + ", " + timestamp + ", " + hand;
        }
    }


    private void fetchLocationAndSaveData(String dataType, List<SensorData> dataBuffer) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "Location permission not granted");
            return;
        }

        LocationRequest locationRequest = LocationRequest.create();
        locationRequest.setNumUpdates(1); //request a single update
        locationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);

        locationRequest.setInterval(10000); //request update every 10 seconds
        locationRequest.setFastestInterval(5000); // accept updates as fast as 5 seconds
        locationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);

        LocationCallback locationCallback = new LocationCallback() {
            @Override
            public void onLocationResult(LocationResult locationResult) {
                if (locationResult == null) {
                    Log.e(TAG, "Location result is null");
                    return;
                }
                Location location = locationResult.getLocations().get(0); //get the latest location
                double latitude = location.getLatitude();
                double longitude = location.getLongitude();

                saveDataToFile(dataType, dataBuffer, latitude, longitude);

                fusedLocationClient.removeLocationUpdates(this);
            }
        };

        fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper());
    }


    // dataBuffer contains the actual buffer containing sensor data
    public void saveDataToFile(String dataType, List<SensorData> dataBuffer,double latitude, double longitude) {
        String fileName = dataType + "_" + System.currentTimeMillis() + ".txt";
        File file = new File(context.getExternalFilesDir(null), fileName);

        try (FileOutputStream fos = new FileOutputStream(file);
             OutputStreamWriter writer = new OutputStreamWriter(fos)) {

            try{
                JSONObject packInfo = new JSONObject();

                packInfo.put("codeId", prescriptionRefNumber);
                packInfo.put("latitude", latitude);
                packInfo.put("longitude", longitude);
                writer.write(packInfo.toString() + "\n");

        } catch (JSONException e) {
            Log.e(TAG, "JSONException occurred: " + e.getMessage());
        }

//            writer.write("codeId: "+prescriptionRefNumber + "\n");

            for (SensorData data : dataBuffer) {
                writer.write(data.toFileString() + "\n");
            }
//            // todo:if we want the data stored as Json,Convert the buffer to JSON string and write to file
//            String jsonData = new Gson().toJson(dataBuffer);
//            writer.write(jsonData);


//            Log.d("MetaWearHandler", "Data saved to " + fileName);
        } catch (IOException e) {
            Log.e("MetaWearHandler", "Failed to save data to file", e);
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



    public void disconnectBoard(String macAddress) {
        MetaWearBoard board = getBoard(macAddress);
        if (board != null) {
            board.disconnectAsync().continueWith(task -> {
                Log.i(TAG, "Disconnected from the MetaWear board: " + macAddress);
                return null;
            });
        }
    }


}

//-------------------------END-------------------------------------------------


