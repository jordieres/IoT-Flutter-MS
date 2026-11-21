package com.upm.healthywear;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.content.res.Configuration;

import androidx.core.content.ContextCompat;

import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.MethodChannel;

import com.sensoria.sensorialibrary.*;
import com.sensoria.sensorialibrary.SACore;
import com.sensoria.sensorialibrary.SADevice;
import com.sensoria.sensorialibrary.SADeviceInterface;
import com.sensoria.sensorialibrary.SAErrors;
import com.sensoria.sensorialibrary.SAServiceStreamingServiceInterface;
import com.sensoria.sensorialibrary.CSBatteryService;
import com.sensoria.sensorialibrary.CSBatteryServiceInterface;
import com.sensoria.sensorialibrary.SASensoriaControlPointService;
import com.sensoria.sensorialibrary.SADataPoint;

import java.util.Arrays;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;
import java.util.zip.GZIPOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.BufferedWriter;

import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.gson.Gson;

import org.json.JSONObject;
import org.json.JSONArray;

public class SensoriaHandler implements SADeviceInterface {
    private Context context;
    private final String TAG = "SensoriaHandler";

    private SADevice device1, device2;
    private FusedLocationProviderClient fusedLocationClient;

    private String idNumber = "";
    public void setIdNumber(String refNumber) {
        if (!java.util.Objects.equals(this.idNumber, refNumber)) setRecording(false);
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

    private final ArrayList<String> dataBuffer1 = new ArrayList<>();
    private LocationCallback locationCallback;
    private boolean closing;
    private boolean recording;
    private long recordingStartedAt;
    private long trialStartedAt;

    private final int BUFFER_SIZE_THRESHOLD = 3000;
    private final Object bufferLock = new Object();

    private volatile double lastKnownLatitude = 0.0;
    private volatile double lastKnownLongitude = 0.0;


    private Long lastDataTimestampSensoriaCore1 = null;
    private Long lastDataTimestampSensoriaCore2 = null;
    private Long lastDataWriteTimestamp = null;

    private boolean core1Connected = false;
    private boolean core2Connected = false;

    public SensoriaHandler(Context context) {
        this.context = context;
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(context);
        startLocationUpdates();
    }

    // ==================== EVENT CONNECTION STATUS ====================
    private EventSink connectionStatusEventSink;

    public void setConnectionStatusEventSink(EventSink eventSink) {
        this.connectionStatusEventSink = eventSink;
    }

    private void updateConnectionStatus(int coreIndex, String status, String error) {
        EventSink sink = connectionStatusEventSink;
        if (sink == null) return;
        Map<String, Object> update = new HashMap<>();
        update.put("coreIndex", coreIndex);
        update.put("status", status);
        Attempt attempt = slots[coreIndex - 1];
        if (status.equals("connected") && attempt != null) {
            update.put("settings", attempt.verifiedSettings);
            update.put("magnetometerGauss", (int) attempt.magnetometer);
            if (attempt.magneticOffsets != null) {
                update.put("magneticOffsets", attempt.magneticOffsets);
            }
        }
        if (error != null) update.put("error", error);
        sink.success(update);
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

        if (locationCallback != null) return;
        locationCallback = new LocationCallback() {
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

    // All connection state is owned by the main thread. SDK command reads
    // can wait for a Bluetooth response, so they run on a worker.
    private final Handler main = new Handler(Looper.getMainLooper());
    private final java.util.concurrent.ExecutorService commands =
            java.util.concurrent.Executors.newFixedThreadPool(2);
    private final Map<String, Candidate> candidates = new HashMap<>();
    private final Attempt[] slots = new Attempt[2];
    private final SACore[] cores = new SACore[2];
    private final boolean[] initialized = new boolean[2];
    private Attempt scanner;
    private long scanGeneration;

    private static class Candidate {
        final SADevice device;
        final long seen = android.os.SystemClock.elapsedRealtime();
        Candidate(SADevice device) { this.device = device; }
    }

    private enum Phase { WAITING, SCANNING, CONNECTING, CHECKING, CALIBRATING, READY, STARTING, STREAMING }

    private class Attempt {
        final int index;
        final short accelerometer, gyroscope, magnetometer;
        final short[] sampling;
        SACore core;
        SADevice target;
        LinkCallbacks callbacks;
        long connectGeneration;
        SASensoriaControlPointService control;
        SAStreamingService streaming;
        CSBatteryService battery;
        Phase phase = Phase.WAITING;
        boolean streamStarted;
        volatile boolean streamRequested;
        volatile long streamGeneration;
        boolean batteryStarted;
        boolean freshScan;
        boolean checking;
        int packetPeriodMs = 32;
        ArrayList<Integer> magneticOffsets;
        Map<String, Integer> verifiedSettings;
        MethodChannel.Result calibrationResult;
        boolean calibrationStarted;
        SAErrors calibrationError;
        String calibrationOutcome;
        long lastRecordingSample;
        volatile boolean cancelled;
        volatile WriteReceipt receipt;

        Attempt(int index, short accelerometer, short gyroscope, short magnetometer, short[] sampling) {
            this.index = index;
            this.accelerometer = accelerometer;
            this.gyroscope = gyroscope;
            this.magnetometer = magnetometer;
            this.sampling = sampling;
        }
    }

    public void enqueueScanAndConnectRequest(int index, short accelerometer, short gyroscope, short magnetometer, short[] sampling) {
        if (slots[index - 1] != null) return;
        Attempt attempt = new Attempt(index, accelerometer, gyroscope, magnetometer, sampling);
        slots[index - 1] = attempt;
        try {
            // The SDK replaces its process-wide BLE queue in the SACore
            // constructor. Create both cores before either begins streaming.
            for (int slot = 0; slot < cores.length; slot++) {
                if (cores[slot] == null) cores[slot] = new SACore(this, context);
            }
            attempt.core = cores[index - 1];
            pumpScans();
            main.postDelayed(() -> {
                if (current(attempt) && !initialized[index - 1]) finish(attempt, "notFound");
            }, 8000);
        } catch (RuntimeException error) {
            Log.w(TAG, "Sensoria SDK initialization failed", error);
            finish(attempt, "notFound");
        }
    }

    private boolean current(Attempt attempt) { return slots[attempt.index - 1] == attempt; }

    private Attempt forCore(SACore core) {
        for (Attempt attempt : slots) if (attempt != null && attempt.core == core) return attempt;
        return null;
    }

    private void pumpScans() {
        if (scanner != null || closing) return;
        for (Attempt attempt : slots) {
            if (attempt == null || attempt.phase != Phase.WAITING || !initialized[attempt.index - 1]) continue;
            if (!attempt.freshScan &&
                    slots[2 - attempt.index] != null && choose(attempt)) continue;
            scanner = attempt;
            final long scan = ++scanGeneration;
            attempt.phase = Phase.SCANNING;
            attempt.freshScan = true;
            candidates.clear();
            final SACore core = attempt.core;
            try {
                core.startScan(6000);
                main.postDelayed(() -> {
                    if (scanGeneration == scan && scanner == attempt) finish(attempt, "notFound");
                }, 14000);
            } catch (RuntimeException error) {
                finish(attempt, "notFound");
            }
            return;
        }
    }

    private boolean choose(Attempt attempt) {
        long now = android.os.SystemClock.elapsedRealtime();
        candidates.values().removeIf(candidate -> now - candidate.seen > 15000);
        Candidate strongest = null;
        for (Candidate candidate : candidates.values()) {
            String mac = candidate.device.deviceMac;
            boolean reserved = false;
            for (Attempt other : slots) {
                if (other != null && other != attempt &&
                        other.target != null && mac.equals(other.target.deviceMac)) reserved = true;
            }
            if (reserved) continue;
            if (strongest == null || candidate.device.returnRSSI() > strongest.device.returnRSSI()) {
                strongest = candidate;
            }
        }
        if (strongest == null) return false;

        attempt.target = strongest.device;
        attempt.phase = Phase.CONNECTING;
        SACore core = attempt.core;
        final long connection = ++attempt.connectGeneration;
        try {
            core.connect(attempt.target, false);
            main.postDelayed(() -> {
                if (current(attempt) && attempt.connectGeneration == connection &&
                        attempt.phase == Phase.CONNECTING) {
                    connectionFailed(attempt);
                }
            }, 12000);
        } catch (Exception error) {
            main.post(() -> { if (current(attempt) && attempt.core == core) connectionFailed(attempt); });
        }
        return true;
    }

    private void connectionFailed(Attempt attempt) {
        if (!attempt.freshScan) {
            releaseLink(attempt);
            attempt.freshScan = true;
            attempt.phase = Phase.WAITING;
            main.postDelayed(this::pumpScans, 500);
        } else {
            finish(attempt, "stream");
        }
    }

    @Override public void didInitialized(SACore core) {
        main.post(() -> {
            for (int slot = 0; slot < cores.length; slot++) {
                if (cores[slot] == core) initialized[slot] = true;
            }
            pumpScans();
        });
    }
    @Override public void didUninitialized(SACore core) {}
    @Override public void didDeviceScanning(SACore core) {}
    @Override public void didConnecting(SACore core, SADevice device) {}
    @Override public void didConnect(SACore core, SADevice device) {}
    @Override public void didRemoteRssiRead(SACore core, SADevice device, int rssi) {}
    @Override public void didServiceStatusChange(SACore core, SADevice device, Map<SAService.Service, Boolean> status) {}

    @Override public void didDeviceDiscovered(SACore core, SADevice device) {
        main.post(() -> {
            if (scanner == null || scanner.core != core || device == null || device.deviceMac == null) return;
            candidates.put(device.deviceMac, new Candidate(device));
        });
    }

    @Override public void didDeviceDiscoveredUpdated(SACore core, SADevice device, boolean disappeared) {
        if (!disappeared) didDeviceDiscovered(core, device);
    }

    @Override public void didDeviceScanCompleted(SACore core) {
        main.post(() -> {
            Attempt attempt = scanner;
            if (attempt == null || attempt.core != core) return;
            scanner = null;
            for (SADevice device : core.getDeviceDiscoveredList()) {
                if (device != null && device.deviceMac != null) {
                    candidates.putIfAbsent(device.deviceMac, new Candidate(device));
                }
            }
            if (!choose(attempt)) finish(attempt, "notFound");
            pumpScans();
        });
    }

    @Override public void didDisconnect(SACore core, SADevice device) {
        main.post(() -> {
            Attempt attempt = forCore(core);
            if (attempt == null ||
                    attempt.phase == Phase.WAITING || attempt.phase == Phase.SCANNING ||
                    (device != null && (attempt.target == null ||
                            !attempt.target.deviceMac.equals(device.deviceMac)))) return;
            if (attempt.phase == Phase.CONNECTING) connectionFailed(attempt);
            else finish(attempt, isReady(attempt) ? null : "configuration");
        });
    }

    @Override public void didSignalLost(SACore core, SADevice device) { didDisconnect(core, device); }

    @Override public void didDeviceError(SACore core, SADevice device, SAErrors error) {
        Log.w(TAG, "Sensoria device error: " + error);
        main.post(() -> {
            Attempt attempt = forCore(core);
            if (attempt == null) return;
            if (attempt.phase == Phase.SCANNING) finish(attempt, "notFound");
            else if (attempt.phase == Phase.CONNECTING) connectionFailed(attempt);
        });
    }

    @Override public void didServicesDiscovered(SACore core, SADevice device) {
        main.post(() -> {
            Attempt attempt = forCore(core);
            if (attempt == null || attempt.phase != Phase.CONNECTING || device == null ||
                    !attempt.target.deviceMac.equals(device.deviceMac)) return;
            attempt.target = device;
            attempt.phase = Phase.CHECKING;
            try {
                startLocationUpdates();
            } catch (SecurityException error) {
                Log.w(TAG, "Location permission unavailable for Sensoria", error);
            }
            try {
                attempt.control = (SASensoriaControlPointService) core.getServiceByType(SAService.Service.SENSORIA_CONTROL_POINT_SERVICE);
                attempt.streaming = (SAStreamingService) core.getServiceByType(SAService.Service.SENSORIA_STREAMING_SERVICE);
                attempt.battery = (CSBatteryService) core.getServiceByType(SAService.Service.BATTERY_SERVICE);
                if (attempt.control == null || attempt.streaming == null) {
                    finish(attempt, "configuration");
                    return;
                }
                LinkCallbacks link = new LinkCallbacks(attempt);
                attempt.callbacks = link;
                updateConnectionStatus(attempt.index, "checking", null);
                attempt.control.start(attempt.callbacks, context);
                attempt.control.resume();
                if (attempt.control.IsServiceReady()) checkConfiguration(attempt);
                main.postDelayed(() -> {
                    if (link.isCurrent() && attempt.phase == Phase.CHECKING) {
                        Log.w(TAG, "Sensoria settings check timed out for slot " + attempt.index);
                        finish(attempt, "configuration");
                    }
                }, 45000);
            } catch (Exception error) {
                Log.w(TAG, "Could not start Sensoria control point", error);
                finish(attempt, "configuration");
            }
        });
    }

    private enum Setting {
        CHANNEL, PERIOD, ACCELEROMETER, GYROSCOPE, MAGNETOMETER, ACCEL_RATE, GYRO_RATE, MAG_RATE
    }

    private static class SettingException extends IllegalStateException {
        final Setting setting;

        SettingException(Setting setting, String message) {
            super(message);
            this.setting = setting;
        }
    }

    private static class WriteReceipt {
        final Setting setting;
        final short value;
        final java.util.concurrent.CompletableFuture<Boolean> response =
                new java.util.concurrent.CompletableFuture<>();

        WriteReceipt(Setting setting, short value) {
            this.setting = setting;
            this.value = value;
        }
    }

    private void writeSetting(Attempt attempt, Setting setting, short value,
                              java.util.function.BooleanSupplier send) throws Exception {
        if (attempt.cancelled) throw new InterruptedException("Sensoria session ended");
        WriteReceipt receipt = new WriteReceipt(setting, value);
        attempt.receipt = receipt;
        try {
            if (attempt.cancelled || !send.getAsBoolean() ||
                    !receipt.response.get(5, java.util.concurrent.TimeUnit.SECONDS)) {
                throw new SettingException(setting, "Sensoria write failed: " + setting + " = " + value);
            }
        } catch (java.util.concurrent.TimeoutException error) {
            // A lost acknowledgement does not establish whether the Core applied
            // the command. Every changed field still needs a matching readback.
            Log.w(TAG, "Missing Sensoria write acknowledgement: " + setting);
        } finally {
            attempt.receipt = null;
        }
    }

    private void acknowledge(LinkCallbacks link, Setting setting, short value) {
        main.post(() -> {
            if (!link.isCurrent()) return;
            WriteReceipt receipt = link.attempt.receipt;
            if (receipt != null && receipt.setting == setting && receipt.value == value) {
                receipt.response.complete(true);
            }
        });
    }

    private <T> T readSetting(Attempt attempt, java.util.function.Supplier<T> read, boolean required)
            throws InterruptedException {
        if (attempt.cancelled) throw new InterruptedException("Sensoria session ended");
        T value = read.get();
        if (value == null && required && !attempt.cancelled) value = read.get();
        if (attempt.cancelled) throw new InterruptedException("Sensoria session ended");
        return value;
    }

    private short verifySetting(Attempt attempt, Setting setting, short expected,
                                java.util.function.Supplier<Short> read) throws InterruptedException {
        Short actual = readSetting(attempt, read, true);
        if (actual != null && actual != expected) {
            Thread.sleep(250);
            actual = readSetting(attempt, read, false);
        }
        if (actual == null || actual != expected) {
            throw new SettingException(setting, "Sensoria " + setting + " readback expected " + expected
                    + ", received " + actual);
        }
        return actual;
    }

    private boolean settingDiffers(short target, Short actual) {
        if (target == 0) return false;
        if (actual == null) throw new IllegalStateException("Sensoria sampling rate read failed for " + target + " Hz");
        return actual != target;
    }

    private void checkConfiguration(Attempt attempt) {
        if (attempt.phase != Phase.CHECKING || attempt.checking) return;
        attempt.checking = true;
        updateConnectionStatus(attempt.index, "checking", null);
        Log.i(TAG, "Checking IMU ranges for slot " + attempt.index);
        SACore core = attempt.core;
        SASensoriaControlPointService control = attempt.control;
        commands.execute(() -> {
            try {
                Short accelerometer = readSetting(attempt, control::readAccelerometerSamplingRange, true);
                Short gyroscope = readSetting(attempt, control::readGyroscopeSamplingRange, true);
                Short magnetometer = readSetting(attempt, control::readMagnetometerSamplingRange, true);
                if (accelerometer == null || gyroscope == null || magnetometer == null) {
                    throw new IllegalStateException("IMU range read failed");
                }
                Log.i(TAG, "Slot " + attempt.index + " read ranges: accelerometer=" + accelerometer
                        + " g, gyroscope=" + gyroscope + " dps, magnetometer=" + magnetometer + " gauss");
                java.util.function.Supplier<ChannelSettings> readChannel =
                        () -> control.readChannelSettings((short) 0);
                ChannelSettings channel = readSetting(attempt, readChannel, true);
                // Only protocols that provide all the recorded sensor fields.
                boolean repair = !validChannel(channel);
                short[] target = attempt.sampling;
                Short accelHz = readSetting(attempt, control::readAccelerometerSamplingRate, target[0] != 0);
                Short gyroHz = readSetting(attempt, control::readGyroscopeSamplingRate, target[1] != 0);
                Short magHz = readSetting(attempt, control::readMagnetometerSamplingRate, target[2] != 0);
                boolean accelRateChanged = settingDiffers(target[0], accelHz);
                boolean gyroRateChanged = settingDiffers(target[1], gyroHz);
                boolean magRateChanged = settingDiffers(target[2], magHz);
                boolean updateChannel = repair || (target[3] != 0 &&
                        target[3] != channel.getSamplingPeriod());

                // Keep a compatible stream protocol and preserve local logging.
                if (repair) {
                    short period = channel != null ? channel.getSamplingPeriod() : 0;
                    ChannelSettings replacement = new ChannelSettings((short) 0,
                            target[3] != 0 ? target[3] : period >= 8 && period <= 200 ? period : (short) 32,
                            ProtocolType.F20, true, true,
                            channel != null && Boolean.TRUE.equals(channel.getLogToLocalMemory()));
                    writeSetting(attempt, Setting.CHANNEL, (short) 0,
                            () -> control.writeChannelSettings(replacement));
                } else if (updateChannel) {
                    writeSetting(attempt, Setting.PERIOD, (short) 0,
                            () -> control.setSamplingPeriod((short) 0, target[3]));
                }
                if (accelRateChanged) writeSetting(attempt, Setting.ACCEL_RATE, target[0],
                        () -> control.writeAccelerometerSamplingRate(target[0]));
                if (gyroRateChanged) writeSetting(attempt, Setting.GYRO_RATE, target[1],
                        () -> control.writeGyroscopeSamplingRate(target[1]));
                if (magRateChanged) writeSetting(attempt, Setting.MAG_RATE, target[2],
                        () -> control.writeMagnetometerSamplingRate(target[2]));
                if (accelerometer != attempt.accelerometer) {
                    writeSetting(attempt, Setting.ACCELEROMETER, attempt.accelerometer,
                            () -> control.writeAccelerometerSamplingRange(attempt.accelerometer));
                }
                if (gyroscope != attempt.gyroscope) {
                    writeSetting(attempt, Setting.GYROSCOPE, attempt.gyroscope,
                            () -> control.writeGyroscopeSamplingRange(attempt.gyroscope));
                }
                if (magnetometer != attempt.magnetometer) {
                    writeSetting(attempt, Setting.MAGNETOMETER, attempt.magnetometer,
                            () -> control.writeMagnetometerSamplingRange(attempt.magnetometer));
                }
                if (accelRateChanged) accelHz = verifySetting(attempt, Setting.ACCEL_RATE, target[0],
                        control::readAccelerometerSamplingRate);
                if (gyroRateChanged) gyroHz = verifySetting(attempt, Setting.GYRO_RATE, target[1],
                        control::readGyroscopeSamplingRate);
                if (magRateChanged) magHz = verifySetting(attempt, Setting.MAG_RATE, target[2],
                        control::readMagnetometerSamplingRate);
                if (accelerometer != attempt.accelerometer) verifySetting(attempt, Setting.ACCELEROMETER,
                        attempt.accelerometer, control::readAccelerometerSamplingRange);
                if (gyroscope != attempt.gyroscope) verifySetting(attempt, Setting.GYROSCOPE,
                        attempt.gyroscope, control::readGyroscopeSamplingRange);
                if (magnetometer != attempt.magnetometer) verifySetting(attempt, Setting.MAGNETOMETER,
                        attempt.magnetometer, control::readMagnetometerSamplingRange);
                if (updateChannel) {
                    channel = readSetting(attempt, readChannel, true);
                    if (!matchesChannel(channel, target[3])) {
                        Thread.sleep(250);
                        channel = readSetting(attempt, readChannel, false);
                    }
                }
                if (!matchesChannel(channel, target[3])) {
                    throw new IllegalStateException("Sensoria stream channel or packet period did not match");
                }
                int verifiedPeriod = channel.getSamplingPeriod();
                Map<String, Integer> settings = new HashMap<>();
                settings.put("streamPeriodMs", verifiedPeriod);
                settings.put("accelerometerG", (int) attempt.accelerometer);
                settings.put("gyroscopeDps", (int) attempt.gyroscope);
                settings.put("magnetometerGauss", (int) attempt.magnetometer);
                if (accelHz != null) settings.put("accelerometerHz", accelHz.intValue());
                if (gyroHz != null) settings.put("gyroscopeHz", gyroHz.intValue());
                if (magHz != null) settings.put("magnetometerHz", magHz.intValue());
                ArrayList<Integer> offsets = readMagneticOffsets(control);
                main.post(() -> {
                    if (!current(attempt) || attempt.core != core || attempt.phase != Phase.CHECKING) return;
                    attempt.verifiedSettings = settings;
                    attempt.packetPeriodMs = verifiedPeriod;
                    attempt.magneticOffsets = offsets;
                    prepareStreaming(attempt);
                });
            } catch (Exception error) {
                Log.w(TAG, "Sensoria configuration failed", error);
                String reason = error instanceof SettingException &&
                        ((SettingException) error).setting == Setting.GYROSCOPE ? "gyroscopeRange" : "configuration";
                main.post(() -> {
                    if (current(attempt) && attempt.core == core) finish(attempt, reason);
                });
            }
        });
    }

    private ArrayList<Integer> readMagneticOffsets(SASensoriaControlPointService control) {
        try {
            Short[] values = control.readMagnetometerCalibrationValues();
            if (values == null || values.length != 3) return null;
            ArrayList<Integer> offsets = new ArrayList<>(3);
            for (Short value : values) {
                if (value == null) return null;
                offsets.add((int) value);
            }
            return offsets;
        } catch (RuntimeException error) {
            Log.w(TAG, "Could not read stored magnetometer offsets", error);
            return null;
        }
    }

    private boolean matchesChannel(ChannelSettings channel, short period) {
        return validChannel(channel) && (period == 0 || period == channel.getSamplingPeriod());
    }

    private boolean validChannel(ChannelSettings channel) {
        if (channel == null || channel.getSamplingPeriod() <= 0 ||
                !Boolean.TRUE.equals(channel.getEnabled()) ||
                !Boolean.TRUE.equals(channel.getTransmitViaBle())) return false;
        ProtocolType protocol = channel.getProtocol();
        return protocol == ProtocolType.F20 || protocol == ProtocolType.H20 ||
                protocol == ProtocolType.I20 || protocol == ProtocolType.J20;
    }

    private boolean isReady(Attempt attempt) {
        return attempt.phase == Phase.READY || attempt.phase == Phase.STARTING ||
                attempt.phase == Phase.STREAMING;
    }

    private boolean canCapture() {
        if (!core1Connected && !core2Connected) return false;
        for (Attempt attempt : slots) {
            if (attempt != null && attempt.calibrationResult != null) return false;
        }
        return true;
    }

    public boolean setRecording(boolean enabled) {
        if (enabled && (collectingTrial || !canCapture())) return false;
        synchronized (bufferLock) {
            if (enabled && !recording) recordingStartedAt = android.os.SystemClock.elapsedRealtimeNanos();
            recording = enabled;
            if (!enabled) flushBuffer();
        }
        updateCapture();
        return true;
    }

    // Configuration establishes the link. Measurements wait for an explicit
    // trial or recording request; returning from calibration also stays idle.
    private void prepareStreaming(Attempt attempt) {
        try {
            if (attempt.control != null) {
                attempt.control.pause();
                attempt.control.stop();
                attempt.control = null;
            }
            if (attempt.battery != null && !attempt.batteryStarted) {
                attempt.battery.start(attempt.callbacks, context);
                attempt.batteryStarted = true;
                attempt.battery.resume();
            }
            if (!attempt.streamStarted) {
                attempt.streaming.start(attempt.callbacks, context);
                attempt.streamStarted = true;
            }
            attempt.phase = Phase.READY;
            if (attempt.index == 1) {
                device1 = attempt.target;
                core1Connected = true;
            } else {
                device2 = attempt.target;
                core2Connected = true;
            }
            Log.i(TAG, "Settings verified; slot " + attempt.index + " connected, waiting for trial or recording");
            updateConnectionStatus(attempt.index, "connected", null);
            completeCalibration(attempt, attempt.calibrationOutcome);
            updateCapture();
        } catch (Exception error) {
            Log.w(TAG, "Sensoria stream could not be prepared", error);
            finish(attempt, "stream");
        }
    }

    private void updateCapture() {
        boolean enabled = collectingTrial || recording;
        for (Attempt attempt : slots) {
            if (attempt == null || !isReady(attempt) || attempt.streamRequested == enabled) continue;
            attempt.streamRequested = enabled;
            long generation = ++attempt.streamGeneration;
            attempt.phase = enabled ? Phase.STARTING : Phase.READY;
            Log.i(TAG, "Slot " + attempt.index + (enabled ? " starting measurements" : " paused; waiting"));
            // resume() can wait for the vendor's protocol initialization. Keep
            // it off the UI thread and serialize pause/resume in request order.
            commands.execute(() -> {
                if (attempt.cancelled) return;
                try {
                    if (enabled) {
                        if (attempt.streamGeneration != generation || !attempt.streamRequested) return;
                        attempt.streaming.resume();
                    } else {
                        attempt.streaming.pause();
                    }
                } catch (Exception error) {
                    Log.w(TAG, "Cannot change Sensoria capture", error);
                    main.post(() -> {
                        if (current(attempt) && attempt.streamGeneration == generation) finish(attempt, "stream");
                    });
                }
            });
            if (enabled) main.postDelayed(() -> {
                if (current(attempt) && attempt.streamGeneration == generation &&
                        attempt.phase == Phase.STARTING) finish(attempt, "stream");
            }, 15000);
        }
    }

    public boolean hasRecordingData(int index) {
        Attempt attempt = slots[index - 1];
        return recording && attempt != null && attempt.lastRecordingSample >= recordingStartedAt &&
                android.os.SystemClock.elapsedRealtimeNanos() - attempt.lastRecordingSample < 2000000000L;
    }

    public void calibrateMagnetometer(int index, MethodChannel.Result result) {
        Attempt attempt = slots[index - 1];
        if (recording || attempt == null || !isReady(attempt) || collectingTrial ||
                attempt.calibrationResult != null) {
            result.success("unavailable");
            return;
        }
        attempt.calibrationResult = result;
        attempt.calibrationStarted = false;
        attempt.calibrationError = null;
        attempt.phase = Phase.CALIBRATING;
        try {
            // Pausing preserves the SDK's streaming listener for resume().
            boolean wasStreaming = attempt.streamRequested;
            attempt.streamRequested = false;
            ++attempt.streamGeneration;
            if (wasStreaming) attempt.streaming.pause();
            // The SDK leaves the ready flag set after stop(). Use a fresh
            // Control Point service and wait for its new Bluetooth connection.
            attempt.control = new SASensoriaControlPointService(attempt.target.deviceMac);
            attempt.control.start(attempt.callbacks, context);
            attempt.control.resume();
            main.postDelayed(() -> {
                if (current(attempt) && attempt.calibrationResult == result) finish(attempt, "stream");
            }, 75000);
        } catch (Exception error) {
            Log.w(TAG, "Cannot prepare Sensoria calibration", error);
            finish(attempt, "stream");
        }
    }

    private void runCalibration(Attempt attempt) {
        if (attempt.phase != Phase.CALIBRATING || attempt.calibrationStarted) return;
        attempt.calibrationStarted = true;
        SASensoriaControlPointService control = attempt.control;
        commands.execute(() -> {
            String outcome = "commandFailed";
            ArrayList<Integer> offsets = null;
            try {
                if (!attempt.cancelled && control.triggerMagnetometerCalibrationValues()) {
                    offsets = readMagneticOffsets(control);
                    if (offsets == null) {
                        outcome = "unavailable";
                    } else {
                        int limit = attempt.magnetometer * 1000;
                        outcome = offsets.stream().anyMatch(value -> Math.abs(value) >= limit)
                                ? "offsetsOutOfRange" : "success";
                    }
                }
            } catch (RuntimeException error) {
                Log.w(TAG, "Sensoria calibration failed", error);
            }
            final String reply = outcome;
            final ArrayList<Integer> readback = offsets;
            main.post(() -> {
                if (!current(attempt) || attempt.phase != Phase.CALIBRATING) return;
                if (readback != null) attempt.magneticOffsets = readback;
                attempt.calibrationOutcome = "commandFailed".equals(reply) &&
                        attempt.calibrationError == SAErrors.ERROR_MAGNETOMETER_CALIBRATION_FAILED
                        ? "retry" : reply;
                Log.i(TAG, "Magnetometer calibration for slot " + attempt.index + ": " +
                        attempt.calibrationOutcome);
                prepareStreaming(attempt);
            });
        });
    }

    private void completeCalibration(Attempt attempt, String outcome) {
        MethodChannel.Result result = attempt.calibrationResult;
        attempt.calibrationResult = null;
        if (result != null) result.success(outcome);
    }

    private void releaseLink(Attempt attempt) {
        attempt.callbacks = null;
        if (attempt.target != null) candidates.remove(attempt.target.deviceMac);
        if (attempt.core == null) return;
        try { attempt.core.stopScan(); } catch (RuntimeException error) { Log.w(TAG, "Scan cleanup", error); }
        if (attempt.streamStarted) {
            try { attempt.streaming.pause(); }
            catch (Exception error) { Log.w(TAG, "Stream pause", error); }
            try { attempt.streaming.stop(); }
            catch (RuntimeException error) { Log.w(TAG, "Stream cleanup", error); }
        }
        try {
            if (attempt.control != null) {
                attempt.control.pause();
                attempt.control.stop();
            }
        }
        catch (RuntimeException error) { Log.w(TAG, "Control point cleanup", error); }
        if (attempt.batteryStarted) {
            try { attempt.battery.pause(); }
            catch (Exception error) { Log.w(TAG, "Battery pause", error); }
            try { attempt.battery.stop(); }
            catch (RuntimeException error) { Log.w(TAG, "Battery cleanup", error); }
        }
        try { attempt.core.disconnect(); } catch (RuntimeException error) { Log.w(TAG, "Link cleanup", error); }
        attempt.target = null;
        attempt.streaming = null;
        attempt.control = null;
        attempt.battery = null;
        attempt.streamStarted = false;
        attempt.batteryStarted = false;
    }

    private void finish(Attempt attempt, String reason) {
        if (!current(attempt)) return;
        attempt.cancelled = true;
        WriteReceipt receipt = attempt.receipt;
        if (receipt != null) receipt.response.complete(false);
        slots[attempt.index - 1] = null;
        if (scanner == attempt) scanner = null;
        synchronized (bufferLock) {
            flushBuffer();
            if (attempt.index == 1) {
                device1 = null;
                core1Connected = false;
            } else {
                device2 = null;
                core2Connected = false;
            }
            if (!core1Connected && !core2Connected) {
                recording = false;
                collectingTrial = false;
                trialSamples.clear();
            }
        }
        releaseLink(attempt);
        updateConnectionStatus(attempt.index, "disconnected", reason);
        completeCalibration(attempt, "unavailable");
        pumpScans();
    }

    public void disconnectDevice(int index) {
        Attempt attempt = slots[index - 1];
        if (attempt != null) finish(attempt, null);
    }

    public void close() {
        closing = true;
        for (Attempt attempt : slots.clone()) if (attempt != null) finish(attempt, null);
        for (SACore core : cores) {
            try { if (core != null) core.dispose(); }
            catch (RuntimeException error) { Log.w(TAG, "Sensoria SDK cleanup", error); }
        }
        commands.shutdownNow();
        if (locationCallback != null) fusedLocationClient.removeLocationUpdates(locationCallback);
    }

    public void readBatteryLevelForCore(int index, MethodChannel.Result result) {
        Attempt attempt = slots[index - 1];
        if (attempt == null || attempt.battery == null) {
            result.error("SERVICE_NOT_AVAILABLE", "Battery service not available", null);
            return;
        }
        CSBatteryService battery = attempt.battery;
        commands.execute(() -> {
            int level;
            try { level = battery.readBatteryLevel(); }
            catch (RuntimeException error) { level = -1; }
            final int value = level;
            main.post(() -> {
                if (value < 0 || !current(attempt)) result.error("READ_FAILED", "Battery unavailable", null);
                else result.success(value);
            });
        });
    }

    private final ArrayList<Object> trialSamples = new ArrayList<>();
    private boolean collectingTrial;

    public boolean setTrialCapture(boolean enabled) {
        if (enabled && (recording || !canCapture())) return false;
        trialStartedAt = enabled ? android.os.SystemClock.elapsedRealtimeNanos() : 0;
        collectingTrial = enabled;
        trialSamples.clear();
        updateCapture();
        return true;
    }

    public ArrayList<Object> drainTrialSamples() {
        ArrayList<Object> samples = new ArrayList<>(trialSamples);
        trialSamples.clear();
        return samples;
    }

    // ==================== STREAMING SERVICE CALLBACKS ====================
    private void receiveSample(LinkCallbacks link, SADataPoint dataPoint) {
        long receivedAt = android.os.SystemClock.elapsedRealtimeNanos();
        if (dataPoint == null) return;

        if (dataPoint.getChannels() == null || dataPoint.getChannels().length < 3 ||
            dataPoint.getAccelerometers() == null || dataPoint.getAccelerometers().length < 3 ||
            dataPoint.getGyroscopes() == null || dataPoint.getGyroscopes().length < 3 ||
            dataPoint.getMagnetometers() == null || dataPoint.getMagnetometers().length < 3) return;

        String formattedData = String.format(Locale.US, "%d,%d,%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d",
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

        int tick = dataPoint.getTickCount();
        ProtocolType protocol = dataPoint.getProtocolType();
        main.post(() -> {
            if (!link.isCurrent()) return;
            boolean streaming = link.attempt.phase == Phase.STARTING || link.attempt.phase == Phase.STREAMING;
            if (collectingTrial && receivedAt >= trialStartedAt && streaming && trialSamples.size() < 2000) {
                int counterBits = protocol == ProtocolType.H20 || protocol == ProtocolType.I20 ? 18 : 24;
                trialSamples.add(Arrays.asList(link.attempt.index, tick, counterBits,
                        (int) link.attempt.accelerometer, (int) link.attempt.magnetometer,
                        link.attempt.packetPeriodMs, formattedData));
            }
            recordSample(link.attempt, formattedData, receivedAt);
        });
    }

    private void recordSample(Attempt attempt, String formattedData, long receivedAt) {
        if (attempt.phase != Phase.STARTING && attempt.phase != Phase.STREAMING) return;
        String footIndicator = attempt.index == 1 ? "Right" : "Left";
        if (attempt.phase == Phase.STARTING) {
            attempt.phase = Phase.STREAMING;
            Log.i(TAG, "Received first Sensoria sample for slot " + attempt.index);
        }

        synchronized (bufferLock) {
            if (recording && receivedAt >= recordingStartedAt) {
                attempt.lastRecordingSample = receivedAt;
                dataBuffer1.add(formattedData + "," + footIndicator);
            }

            if (footIndicator.equals("Right")) {
                lastDataTimestampSensoriaCore1 = System.currentTimeMillis();
            } else {
                lastDataTimestampSensoriaCore2 = System.currentTimeMillis();
            }

            if (dataBuffer1.size() >= BUFFER_SIZE_THRESHOLD) flushBuffer();
        }
    }

    private long lastFileTimestamp;

    private void flushBuffer() {
        if (dataBuffer1.isEmpty()) return;
        lastFileTimestamp = Math.max(System.currentTimeMillis(), lastFileTimestamp + 1);
        writeBufferToFile(context, "S_" + lastFileTimestamp + ".txt", dataBuffer1,
                lastKnownLatitude, lastKnownLongitude);
        dataBuffer1.clear();
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

    // The SDK opens separate GATT clients for each service and constructs
    // separate SADevice objects. Bind callbacks to the link that registered
    // them so delayed callbacks cannot affect a replacement sock.
    private final class LinkCallbacks implements SAServiceControlPointInterface,
            SAServiceStreamingServiceInterface, CSBatteryServiceInterface {
        final Attempt attempt;

        LinkCallbacks(Attempt attempt) { this.attempt = attempt; }

        boolean isCurrent() {
            return current(attempt) && attempt.callbacks == this;
        }

        @Override
        public void didUpdateData(SADevice device, SAService.Service service, SADataPoint dataPoint) {
            receiveSample(this, dataPoint);
        }

        @Override
        public void didServiceError(SADevice device, SAService.Service service, String serviceName,
                                    String functionName, SAErrors errorCode, String innerErrorCode) {
            Log.w(TAG, "Sensoria service error in " + serviceName + "." + functionName + ": " + errorCode);
            main.post(() -> {
                if (!isCurrent()) return;
                if (service == SAService.Service.SENSORIA_CONTROL_POINT_SERVICE &&
                        attempt.phase == Phase.CALIBRATING &&
                        "triggerMagnetometerCalibrationValues".equals(functionName)) {
                    attempt.calibrationError = errorCode;
                }
                if (service == SAService.Service.SENSORIA_CONTROL_POINT_SERVICE &&
                        attempt.phase == Phase.CHECKING && attempt.receipt != null &&
                        functionName != null && (functionName.startsWith("write") ||
                                functionName.startsWith("setSamplingPeriod"))) {
                    attempt.receipt.response.complete(false);
                }
                if (service == SAService.Service.SENSORIA_STREAMING_SERVICE &&
                        isReady(attempt)) {
                    finish(attempt, "stream");
                }
            });
        }

        @Override
        public void didServiceReady(SADevice device, SAService.Service service) {
            if (service != SAService.Service.SENSORIA_CONTROL_POINT_SERVICE) return;
            main.post(() -> {
                if (!isCurrent()) return;
                if (attempt.phase == Phase.CALIBRATING) runCalibration(attempt);
                else checkConfiguration(attempt);
            });
        }

        @Override
        public void didServiceAccelerometerSamplingRangeSet(SADevice d, SAService.Service s, short v) {
            acknowledge(this, Setting.ACCELEROMETER, v);
        }
        @Override
        public void didServiceGyroscopeSamplingRangeSet(SADevice d, SAService.Service s, short v) {
            acknowledge(this, Setting.GYROSCOPE, v);
        }
        @Override
        public void didServiceMagnetometerSamplingRangeSet(SADevice d, SAService.Service s, short v) {
            acknowledge(this, Setting.MAGNETOMETER, v);
        }
        @Override
        public void didServiceWriteChannelSettings(SADevice d, SAService.Service s, short channel) {
            acknowledge(this, Setting.CHANNEL, channel);
        }

        @Override public void didServiceConnect(SADevice d, SAService.Service s) {}
        @Override public void didServiceDisconnect(SADevice d, SAService.Service s) {}
        @Override public void didServicePause(SADevice d, SAService.Service s) {}
        @Override public void didServiceResume(SADevice d, SAService.Service s) {}
        @Override public void didServiceReset(SADevice d, SAService.Service s) {}
        @Override public void didServiceAccelerometerSamplingRateSet(SADevice d, SAService.Service s, short v) {
            acknowledge(this, Setting.ACCEL_RATE, v);
        }
        @Override public void didServiceGyroscopeSamplingRateSet(SADevice d, SAService.Service s, short v) {
            acknowledge(this, Setting.GYRO_RATE, v);
        }
        @Override public void didServiceMagnetometerSamplingRateSet(SADevice d, SAService.Service s, short v) {
            acknowledge(this, Setting.MAG_RATE, v);
        }
        @Override public void didServiceMagnetometerCalibrationValuesSet(SADevice d, SAService.Service s, short[] v) {}
        @Override public void didServiceMagnetometerCalibrated(SADevice d, SAService.Service s, boolean v) {}
        @Override public void didServiceTimeoutSet(SADevice d, SAService.Service s, short a, short b) {}
        @Override public void didServiceConfigurationStorageSet(SADevice d, SAService.Service s, ConfigurationStorage v) {}
        @Override public void didServiceCalibrationIncrement(SADevice d, SAService.Service s, short v) {}
        @Override public void didServiceSamplingPeriodSet(SADevice d, SAService.Service s, short channel) {
            acknowledge(this, Setting.PERIOD, channel);
        }
        @Override public void didServiceChannelProtocolTypeSet(SADevice d, SAService.Service s, short v) {}
        @Override public void didServiceChannelPropertySet(SADevice d, SAService.Service s, short ch, ChannelBitsEnum prop) {}
        @Override public void didServiceHapticDriverMotorAcquired(SADevice d, SAService.Service s, boolean v) {}
        @Override public void didServiceHapticDriverMotorInitialized(SADevice d, SAService.Service s, short v) {}
        @Override public void didServiceHapticDriverMotorReleased(SADevice d, SAService.Service s, boolean v) {}
        @Override public void didServiceHapticDriverMotorOn(SADevice d, SAService.Service s, byte a, byte b, byte c, byte d2) {}
        @Override public void didServiceHapticDriverMotorOff(SADevice d, SAService.Service s, boolean v) {}
        @Override public void didServiceAutoWakeUpModeSourcesSet(SADevice d, SAService.Service s, byte a, byte b, byte c) {}
        @Override public void didPauseLED(SADevice d, SAService.Service s, boolean v) {}
    }

    // ==================== GET STATUS ====================
    public String getCurrentStatus(int coreIndex) {
        Log.d(TAG, "getCurrentStatus: Request received for Sensoria core " + coreIndex);
        Gson gson = new Gson();
        Map<String, Object> statusMap = new HashMap<>();

        statusMap.put("isRecording", recording);
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
