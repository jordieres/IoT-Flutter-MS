package vn.com.tma.ehealth.veepoo_sdk;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.widget.Toast;
import android.util.Log;
import java.util.Arrays;
import android.Manifest;


import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import com.google.gson.Gson;
import com.inuker.bluetooth.library.Code;
import com.inuker.bluetooth.library.Constants;
import com.inuker.bluetooth.library.model.BleGattProfile;
import com.inuker.bluetooth.library.search.SearchResult;
import com.inuker.bluetooth.library.search.response.SearchResponse;
import com.inuker.bluetooth.library.utils.BluetoothUtils;
import com.orhanobut.logger.Logger;
import com.veepoo.protocol.VPOperateManager;
import com.veepoo.protocol.listener.base.IABleConnectStatusListener;
import com.veepoo.protocol.listener.base.IBleWriteResponse;
import com.veepoo.protocol.listener.base.IConnectResponse;
import com.veepoo.protocol.listener.base.INotifyResponse;
import com.veepoo.protocol.listener.data.IAllSetDataListener;
import com.veepoo.protocol.listener.data.IBatteryDataListener;
import com.veepoo.protocol.listener.data.IDeviceFuctionDataListener;
import com.veepoo.protocol.listener.data.IECGReadDataListener;
import com.veepoo.protocol.listener.data.IHeartDataListener;
import com.veepoo.protocol.listener.data.IOriginData3Listener;
import com.veepoo.protocol.listener.data.IOriginDataListener;
import com.veepoo.protocol.listener.data.IPersonInfoDataListener;
import com.veepoo.protocol.listener.data.IPwdDataListener;
import com.veepoo.protocol.listener.data.ISleepDataListener;
import com.veepoo.protocol.listener.data.ISocialMsgDataListener;
import com.veepoo.protocol.listener.data.ISpo2hDataListener;
import com.veepoo.protocol.listener.data.ISpo2hOriginDataListener;
import com.veepoo.protocol.listener.data.IBPDetectDataListener;
import com.veepoo.protocol.listener.data.ISportDataListener;


import com.veepoo.protocol.listener.data.IECGDetectListener;
import com.veepoo.protocol.model.datas.EcgDetectInfo;
import com.veepoo.protocol.model.datas.EcgDetectState;
import com.veepoo.protocol.model.settings.ReadOriginSetting;


import com.veepoo.protocol.model.datas.AllSetData;
import com.veepoo.protocol.model.datas.SportData;

import com.veepoo.protocol.model.datas.BatteryData;
import com.veepoo.protocol.model.datas.EcgDetectResult;
import com.veepoo.protocol.model.datas.FunctionDeviceSupportData;
import com.veepoo.protocol.model.datas.FunctionSocailMsgData;
import com.veepoo.protocol.model.datas.HRVOriginData;
import com.veepoo.protocol.model.datas.HeartData;
import com.veepoo.protocol.model.datas.OriginData;
import com.veepoo.protocol.model.datas.OriginData3;
import com.veepoo.protocol.model.datas.OriginHalfHourData;
import com.veepoo.protocol.model.datas.PersonInfoData;
import com.veepoo.protocol.model.datas.PwdData;
import com.veepoo.protocol.model.datas.SleepData;
import com.veepoo.protocol.model.datas.SleepPrecisionData;
import com.veepoo.protocol.model.datas.Spo2hData;
import com.veepoo.protocol.model.datas.Spo2hOriginData;
import com.veepoo.protocol.model.datas.TimeData;
import com.veepoo.protocol.model.datas.BpData;
import com.veepoo.protocol.model.datas.OriginData;


import com.veepoo.protocol.model.enums.EEcgDataType;
import com.veepoo.protocol.model.enums.EFunctionStatus;
import com.veepoo.protocol.model.enums.EHeartStatus;
import com.veepoo.protocol.model.enums.EOprateStauts;
import com.veepoo.protocol.model.enums.ESex;
import com.veepoo.protocol.model.enums.EBPDetectModel;

import com.veepoo.protocol.model.settings.AllSetSetting;
import com.veepoo.protocol.util.VPLogger;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import vn.com.tma.ehealth.veepoo_sdk.model.DOriginHalfHourData;
import vn.com.tma.ehealth.veepoo_sdk.model.DSleepData;
import vn.com.tma.ehealth.veepoo_sdk.service.BleService;
import vn.com.tma.ehealth.veepoo_sdk.util.BluetoothUtil;
import vn.com.tma.ehealth.veepoo_sdk.util.DeviceConnectUtil;
import vn.com.tma.ehealth.veepoo_sdk.util.NotificationHelper;
import vn.com.tma.ehealth.veepoo_sdk.util.VpUtil;

import com.veepoo.protocol.listener.data.IBPDetectDataListener;
//import com.veepoo.protocol.model.datas.BPDetectData;
import android.util.Log;

import static com.veepoo.protocol.model.enums.EFunctionStatus.SUPPORT;
import static vn.com.tma.ehealth.veepoo_sdk.util.BluetoothUtil.MY_PERMISSIONS_REQUEST_BLUETOOTH;

public class MethodCallHandlerImpl implements MethodChannel.MethodCallHandler, PluginRegistry.RequestPermissionsResultListener {
    private final static String TAG = MethodCallHandlerImpl.class.getSimpleName();
    private final static int NOTIFICATION_ID = 102;

    private final Context mContext;
    @Nullable
    private Activity activity;

    private static boolean isConnected = false;
    private VPOperateManager mVpoperateManager;
    private WriteResponse writeResponse = new WriteResponse();
//    private NotificationHelper notificationHelper;

    private String currentDevice = "";

    MethodCallHandlerImpl(Context mContext) {
        this.mContext = mContext;

//        notificationHelper = new NotificationHelper(mContext);

        Logger.t(TAG).i("MethodCallHandlerImpl");
//        notificationHelper.showNotificationOnGoing(NOTIFICATION_ID, "E-Health", "No device connected");

//        BleService.startActionDeviceConnect(mContext, "xxx");

        // Init SDK
        //noinspection AccessStaticViaInstance
        mVpoperateManager = mVpoperateManager.getMangerInstance(mContext);
        VPLogger.setDebug(true);
    }

    public void setActivity(@Nullable Activity activity) {
        this.activity = activity;
    }

    /**
     * Handle platform channel call
     *
     * @param call
     * @param result
     */
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        sendLocalBoardCast(0, call.method, "");

        switch (call.method) {
            case "requestPermission":
                String[] permissions = {Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION};
                BluetoothUtil.requestPermission(activity, permissions);
                result.success(null);
                break;

            ////////////////////////////////////////////////////////////////////////////////////////
            // Device basic operate
            ////////////////////////////////////////////////////////////////////////////////////////
            case "scanDevice":
                scanDevice(result);
                break;
            case "stopScanDevice":
                stopScanDevice();
                result.success(null);
                break;
            case "connect":
                connectDevice(result, (String) call.argument("macAddress"));
                break;
            case "disconnect":
                disconnectDevice(result);
                break;
            case "confirmDevicePwd":
                confirmDevicePwd(result, (String) call.argument("password"), (boolean) call.argument("is24h"));
                break;
            case "isConnected":
                isConnected(result);
                break;
            case "syncPersonInfo":
                syncPersonInfo(result, (boolean) call.argument("isMale"), (int) call.argument("height"), (int) call.argument("weight"), (int) call.argument("age"), (int) call.argument("targetStep"));
                break;
            case "readBattery":
                readBattery(result);
                break;
            case "getCountVersion":
                result.success(VpUtil.getDeviceVersion(mContext));
                break;

            ////////////////////////////////////////////////////////////////////////////////////////
            // Manual measurement
            ////////////////////////////////////////////////////////////////////////////////////////
            case "startDetectHeart":
                startDetectHeart(result);
                break;
            case "stopDetectHeart":
                stopDetectHeart(result);
                break;
            case "startDetectSPO2H":
                startDetectSPO2H(result);
                break;
            case "stopDetectSPO2H":
                stopDetectSPO2H(result);
                break;
            case "startDetectBP":
                startDetectBP(result);
                break;
            case "stopDetectBP":
                stopDetectBP(result);
                break;
//            case "startDetectECG":
//                startDetectECG(result);
//                break;
//            case "stopDetectECG":
//                stopDetectECG(result);
//                break;
            case "readStepData":
                readStepData(result);
                break;


            ////////////////////////////////////////////////////////////////////////////////////////
            // Manual measurement
            ////////////////////////////////////////////////////////////////////////////////////////
            case "readOriginData":
                readOriginData(result);
                break;
            case "readOrigin3Data":
                readOrigin3Data(result);
                break;
            case "readSleepData":
                readSleepData(result);
                break;
            case "readSpo2hOrigin":
                readSpo2hOrigin(result);
                break;
            case "readECGData":
                readECGData(result);
                break;
            case "readFiveMinutes":
                FiveMinuteDataChange(result);
                break;

            ////////////////////////////////////////////////////////////////////////////////////////
            case "sdkTest":
                sdkTest(result);
                break;
            case "dummyTest":
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    // ---------------------------------------------------------------------------------------------
    // Permission request

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        switch (requestCode) {
            case MY_PERMISSIONS_REQUEST_BLUETOOTH: {
                Logger.t(TAG).i("onRequestPermissionsResult,MY_PERMISSIONS_REQUEST_BLUETOOTH ");
                if (grantResults.length > 0
                        && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    BluetoothUtil.initBLE(activity);
                }

                return true;
            }
        }

        return false;
    }

    // ---------------------------------------------------------------------------------------------

    /**
     * Monitor the callback status of the system Bluetooth on and off
     */
    private final IABleConnectStatusListener mBleConnectStatusListener = new IABleConnectStatusListener() {

        @Override
        public void onConnectStatusChanged(String mac, int status) {
            if (status == Constants.STATUS_CONNECTED) {
                isConnected = true;
                Logger.t(TAG).i("STATUS_CONNECTED");
//                notificationHelper.showNotificationOnGoing(NOTIFICATION_ID, "E-Health", "Device connected");
            } else if (status == Constants.STATUS_DISCONNECTED) {
                isConnected = false;
//                notificationHelper.showNotificationOnGoing(NOTIFICATION_ID, "E-Health", "Device disconnected");
                Logger.t(TAG).i("STATUS_DISCONNECTED");
            }
        }
    };

    public BroadcastReceiver createDeviceConnectStateChangeReceiver(final EventChannel.EventSink events) {
        return new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                Bundle bundle = intent.getExtras();

                if (bundle == null) {
                    return;
                }

                if (bundle.getInt("error", 1) != 0) {
                    events.error(intent.getAction(), bundle.getString("message", ""), bundle.getString("detail", ""));

                    return;
                }

                HashMap<String, Object> payload = new HashMap<>();
                payload.put("error", bundle.getInt("error", 1));
                payload.put("action", bundle.getString("action", ""));
                payload.put("payload", bundle.getString("payload", ""));
                events.success(new Gson().toJson(payload));
            }
        };
    }

    public void sendLocalBoardCast(Integer error, String action, String payload) {
        Intent intent = new Intent();
        intent.setAction(VeepooSdkPlugin.ACTION_SDK_NEW_EVENT);
        intent.putExtra("error", error);
        intent.putExtra("action", action);
        intent.putExtra("payload", payload);

        LocalBroadcastManager.getInstance(mContext).sendBroadcast(intent);
    }

    // ---------------------------------------------------------------------------------------------

    private void connectDevice(final MethodChannel.Result result, final String mac) {
        if (!BluetoothUtils.isBluetoothEnabled()) {
            Toast.makeText(mContext, "Bluetooth is not turned on", Toast.LENGTH_SHORT).show();
            result.error("1", "Bluetooth is not turned on", "");
            return;
        }

//        notificationHelper.showNotificationOnGoing(NOTIFICATION_ID, "E-Health", "Connecting to device...");

        mVpoperateManager.registerConnectStatusListener(mac, mBleConnectStatusListener);
        mVpoperateManager.connectDevice(mac, "", new IConnectResponse() {

            @Override
            public void connectState(int code, BleGattProfile profile, boolean isoadModel) {
                if (code == Code.REQUEST_SUCCESS) {
                    // Bluetooth connection status with the device
                    Logger.t(TAG).i("Connection succeeded");
                    Logger.t(TAG).i("Whether it is firmware upgrade mode=" + isoadModel);
                } else {
                    Logger.t(TAG).i("Connection failed");
                    result.error("error", "Error message", null);
                }
            }
        }, new INotifyResponse() {
            @Override
            public void notifyState(int state) {
                if (state == Code.REQUEST_SUCCESS) {
                    // Bluetooth connection status with the device
                    Logger.t(TAG).i("Monitoring success-other operations available");
                    currentDevice = mac;
                    result.success(true);
                } else {
                    Logger.t(TAG).i("Failed to listen, reconnect");
                    result.error("error", "Error message", null);
                }

            }
        });
    }

    private void disconnectDevice(final MethodChannel.Result result) {
        isConnected = false;

        mVpoperateManager.disconnectWatch(new IBleWriteResponse() {
            @Override
            public void onResponse(int code) {
                Logger.t(TAG).i("write cmd status:" + code);

                result.success("OK");
            }
        });
    }

    private void confirmDevicePwd(final MethodChannel.Result result, String pwdStr, Boolean is24Hourmodel) {
        try {
                mVpoperateManager.confirmDevicePwd(new IBleWriteResponse() {
                @Override
                public void onResponse(int i) {
                    if (i != Code.REQUEST_SUCCESS) {
                        result.error(String.valueOf(i), "Bind error", "");
                    }
                }
            }, new IPwdDataListener() {
                @Override
                public void onPwdDataChange(PwdData pwdData) {
                    //触发回调
                    String message = "PwdData:\n" + pwdData.toString();
                    Logger.t(TAG).i(message);
                    isConnected = true;
                    saveDeviceConnectionInfo(pwdStr, is24Hourmodel);
                    result.success(true);
                }
            }, new IDeviceFuctionDataListener() {
                @Override
                public void onFunctionSupportDataChange(FunctionDeviceSupportData functionSupport) {
                    //触发回调
                    String message = "FunctionDeviceSupportData:\n" + functionSupport.toString();
                    Logger.t(TAG).i(message);

                    EFunctionStatus newCalcSport = functionSupport.getNewCalcSport();
                    DeviceState.isNewSportCalc = newCalcSport != null && newCalcSport.equals(SUPPORT);
                    DeviceState.watchDataDay = functionSupport.getWathcDay();
                    DeviceState.contactMsgLength = functionSupport.getContactMsgLength();
                    DeviceState.allMsgLenght = functionSupport.getAllMsgLength();
                    DeviceState.isSleepPrecision = functionSupport.getPrecisionSleep() == SUPPORT;
                }
            }, new ISocialMsgDataListener() {
                @Override
                public void onSocialMsgSupportDataChange(FunctionSocailMsgData socailMsgData) {
                    //触发回调
                    String message = "FunctionSocailMsgData:\n" + socailMsgData.toString();
                    Logger.t(TAG).i(message);
                }
            }, pwdStr, is24Hourmodel);
        } catch (Exception e) {
            result.error("1", e.getMessage(), e);
        }
    }

    private void saveDeviceConnectionInfo(String password, Boolean is24h) {
        DeviceConnectUtil.saveCurrentCredentials(mContext, currentDevice, password, is24h);
    }

    private void isConnected(final MethodChannel.Result result) {
        result.success(isConnected);
    }

    /**
     * Start scan
     *
     * @param result Flutter Result callback
     */
    private void scanDevice(final MethodChannel.Result result) {
        if (!BluetoothUtils.isBluetoothEnabled()) {
            Toast.makeText(mContext, "Bluetooth is not turned on", Toast.LENGTH_SHORT).show();
            result.error("1", "Bluetooth is not turned on", "");
            return;
        }

        final List<SearchResult> mListData = new ArrayList<>();
        final List<String> mListAddress = new ArrayList<>();
        final List<HashMap<String, Object>> r = new ArrayList<>();

        mVpoperateManager.startScanDevice(new SearchResponse() {
            @Override
            public void onSearchStarted() {
                Logger.t(TAG).i("onSearchStarted");

                mListAddress.clear();
                mListData.clear();
                r.clear();
            }

            @Override
            public void onDeviceFounded(final SearchResult device) {
                Logger.t(TAG).i(String.format("Found %s-%s-%d", device.getName(), device.getAddress(), device.rssi));

                if (!mListAddress.contains(device.getAddress())) {
                    mListData.add(device);
                    mListAddress.add(device.getAddress());
                }
            }

            @Override
            public void onSearchStopped() {
                Logger.t(TAG).i("onSearchStopped");

                mListAddress.clear();

                for (SearchResult searchResult : mListData) {
                    HashMap<String, Object> d = new HashMap<>();
                    d.put("name", searchResult.getName());
                    d.put("mac", searchResult.getAddress());
                    d.put("rssi", searchResult.rssi);
                    r.add(d);
                }

                mListData.clear();

                result.success(r);
            }

            @Override
            public void onSearchCanceled() {
                Logger.t(TAG).i("onSearchCanceled");

                mListData.clear();
                mListAddress.clear();
                r.clear();

                result.success(mListAddress);
            }
        });
    }

    private void readBattery(final MethodChannel.Result result) {
        mVpoperateManager.readBattery(new IBleWriteResponse() {
            @Override
            public void onResponse(int i) {
                if (i != Code.REQUEST_SUCCESS) {
                    result.error(String.valueOf(i), "Unable get battery level", "");
                }
            }
        }, new IBatteryDataListener() {
            @Override
            public void onDataChange(BatteryData batteryData) {
//                Log.d("BatteryData", "Raw battery data: " + batteryData.toString());

                result.success(batteryData.getBatteryLevel());
            }
        });
    }

    // / Device manual measurement
    // ---------------------------------------------------------------------------------------------

    private void startDetectHeart(final MethodChannel.Result result) {
        mVpoperateManager.startDetectHeart(writeResponse, new IHeartDataListener() {
            @Override
            public void onDataChange(HeartData heartData) {
                sendLocalBoardCast(0, "onHrDataChange", new Gson().toJson(heartData));
            }
        });

        result.success(null);
    }

    private void stopDetectHeart(final MethodChannel.Result result) {
        mVpoperateManager.stopDetectHeart(writeResponse);
        result.success(null);
    }

    private void startDetectSPO2H(final MethodChannel.Result result) {
        mVpoperateManager.startDetectSPO2H(writeResponse, new ISpo2hDataListener() {
            @Override
            public void onSpO2HADataChange(Spo2hData spo2hData) {
                //Logger.t(TAG).e(spo2hData.toString());
                sendLocalBoardCast(0, "onSpO2HADataChange", new Gson().toJson(spo2hData));
            }
        });

        result.success(null);
    }

    private void stopDetectSPO2H(final MethodChannel.Result result) {
        mVpoperateManager.stopDetectSPO2H(writeResponse, new ISpo2hDataListener() {
            @Override
            public void onSpO2HADataChange(Spo2hData spo2hData) {
                Logger.t(TAG).e(spo2hData.toString());
            }
        });
        result.success(null);
    }

    private void startDetectBP(final MethodChannel.Result result) {
        mVpoperateManager.startDetectBP(writeResponse, new IBPDetectDataListener() {
            @Override
            public void onDataChange(BpData bpData) {
                // Handle BP data change
//                Log.d(TAG, "BP Detection Data: " + bpData.toString());
                // Convert bpData to JSON and send it back to Flutter
                String bpDataJson = new Gson().toJson(bpData);
                sendLocalBoardCast(0, "onBPDataChange", bpDataJson);
//                result.success(bpDataJson); // Send BP data back to Flutter
            }
        }, EBPDetectModel.DETECT_MODEL_PUBLIC); // Use the correct detection model as needed
        result.success(null);

    }

    private void stopDetectBP(final MethodChannel.Result result) {
        mVpoperateManager.stopDetectBP(writeResponse,EBPDetectModel.DETECT_MODEL_PUBLIC);
        result.success(null);
    }




//this is good for the one day report
    private void FiveMinuteDataChange(final MethodChannel.Result result) {

        int currentDay = 0;
        int startPosition = 1;
        int watchDay = 0;


        ReadOriginSetting readOriginSetting = new ReadOriginSetting(currentDay, startPosition, true, watchDay);

        mVpoperateManager.readOriginDataBySetting(writeResponse, new IOriginDataListener() {

            @Override
            public void onOringinFiveMinuteDataChange(OriginData originData) {
                // Handle the five-minute interval data
                Gson gson = new Gson();
                String jsonData = gson.toJson(originData);
                sendLocalBoardCast(0, "onOriginFiveMinuteDataChange", jsonData);
                android.util.Log.d(TAG, "five minutessssssssssssss: "+jsonData);
            }

            @Override
            public void onOringinHalfHourDataChange(OriginHalfHourData originHalfHourData) {
                // Handle the half-hour interval data
                Gson gson = new Gson();
                String jsonData = gson.toJson(originHalfHourData);
                sendLocalBoardCast(0, "onOriginHalfHourDataChange", jsonData);
            }

            @Override
            public void onReadOriginProgress(float progress) {
                // Handle progress updates
                sendLocalBoardCast(0, "onReadOriginProgress", Float.toString(progress));
            }

            @Override
            public void onReadOriginProgressDetail(int day, String date, int allPackage, int currentPackage) {
                // Handle detailed progress updates
                Map<String, Object> detail = new HashMap<>();
                detail.put("day", day);
                detail.put("date", date);
                detail.put("allPackage", allPackage);
                detail.put("currentPackage", currentPackage);
                String jsonDetails = new Gson().toJson(detail);
                sendLocalBoardCast(0, "onReadOriginProgressDetail", jsonDetails);
            }

            @Override
            public void onReadOriginComplete() {
                // Handle the completion of data reading
                sendLocalBoardCast(0, "onReadOriginComplete", "{}");
                result.success(null); // Indicate to the Flutter side that data reading is complete.
            }

        },readOriginSetting ); // Adjust the last parameter as per your actual requirement
    }




    public void readStepData(final MethodChannel.Result result) {
        mVpoperateManager.readSportStep(writeResponse, new ISportDataListener() {
            @Override
            public void onSportDataChange(SportData sportData) {
//                sendLocalBoardCast(0, "onSportDataChange", new Gson().toJson(sportData));

//                if (sportData != null) {
//                    String sportDataJson = new Gson().toJson(sportData);

//                int steps = sportData.getStep();
//                double distance = sportData.getDis();
//                double calories = sportData.getKcal();
//                int calctype=sportData.getCalcType();
//                int TriaxialX=sportData.getTriaxialX();
//                int TriaxialY=sportData.getTriaxialY();
//                int TriaxialZ=sportData.getTriaxialZ();
//
//                Log.i("SportData", "Steps: " + steps + ", Distance: " + distance + "m, Calories: " + calories + "kcal calctype:"+calctype+"triaxialX:"+TriaxialX+"Y:"+TriaxialY+"Z:"+TriaxialZ);


//                sendLocalBoardCast(0, "onSportDataChange", sportDataJson);


//                     You can modify this Map to include any other details you need.
                    Map<String, Object> stepData = new HashMap<>();
                    stepData.put("steps", sportData.getStep());
                    stepData.put("distance", sportData.getDis());
                    stepData.put("calories", sportData.getKcal());
//                android.util.Log.d(TAG, "steppp dataaaaaaaaaa"+stepData);

                    result.success(stepData);
//                    result.success(null);
//                } else {
//                    result.error("UNAVAILABLE", "Step data is not available", null);
//                }
            }
        });
    }



    private void syncPersonInfo(final MethodChannel.Result result, boolean isMale, int height, int weight, int age, int targetStep) {
        PersonInfoData personInfoData = new PersonInfoData(
                isMale ? ESex.MAN : ESex.WOMEN,
                height,
                weight,
                age,
                targetStep
        );

        mVpoperateManager.syncPersonInfo(writeResponse, new IPersonInfoDataListener() {
            @Override
            public void OnPersoninfoDataChange(EOprateStauts eOprateStauts) {
                if (eOprateStauts.equals(EOprateStauts.OPRATE_SUCCESS)) {
                    result.success(null);
                } else {
                    result.error(eOprateStauts.toString(), "", null);
                }

            }
        }, personInfoData);
    }

    private void readOriginData(final MethodChannel.Result result) {

        final List<OriginData> originDataList = new ArrayList<>();
        final List<OriginHalfHourData> originHalfHourDataList = new ArrayList<>();

        mVpoperateManager.readOriginData(
                writeResponse,
                new IOriginDataListener() {
                    @Override
                    public void onOringinFiveMinuteDataChange(OriginData originData) {
                        //Logger.t(TAG).e(originData.toString());
                        originDataList.add(originData);
                    }

                    @Override
                    public void onOringinHalfHourDataChange(OriginHalfHourData originHalfHourData) {
                        //Logger.t(TAG).e(originHalfHourData.toString());
                        originHalfHourDataList.add(originHalfHourData);
                    }

                    @Override
                    public void onReadOriginProgressDetail(int day, String date, int allPackage, int currentPackage) {
                        Logger.t(TAG).i("onReadOriginProgressDetail " + day + " " + date + " " + allPackage + "-" + currentPackage);
                    }

                    @Override
                    public void onReadOriginProgress(float progress) {
                        Logger.t(TAG).i("onReadOriginProgress " + progress);
                    }


                    @Override
                    public void onReadOriginComplete() {
                        Map<String, Object> payload = new HashMap<>();
                        payload.put("originData", originDataList);
                        payload.put("originHalfHourData", originHalfHourDataList);

                        result.success(new Gson().toJson(payload));
                    }
                },
                DeviceState.watchDataDay
        );
    }

    private void readOrigin3Data(final MethodChannel.Result result) {
        final List<OriginData3> originData3s = new ArrayList<>();
        final List<DOriginHalfHourData> originHalfHourDataList = new ArrayList<>();
        final List<HRVOriginData> hrvOriginDataList = new ArrayList<>();
        final List<Spo2hOriginData> spo2hOriginDataList = new ArrayList<>();

        mVpoperateManager.readOriginData(
                writeResponse,
                new IOriginData3Listener() {
                    @Override
                    public void onOriginFiveMinuteListDataChange(List<OriginData3> list) {
                        originData3s.addAll(list);
                    }

                    @Override
                    public void onOriginHalfHourDataChange(OriginHalfHourData originHalfHourData) {
                        originHalfHourDataList.add(new DOriginHalfHourData(originHalfHourData));
                    }

                    @Override
                    public void onOriginHRVOriginListDataChange(List<HRVOriginData> list) {
                        hrvOriginDataList.addAll(list);
                    }

                    @Override
                    public void onOriginSpo2OriginListDataChange(List<Spo2hOriginData> list) {
                        spo2hOriginDataList.addAll(list);
                    }

                    @Override
                    public void onReadOriginProgressDetail(int day, String date, int allPackage, int currentPackage) {
                        Logger.t(TAG).i("onReadOriginProgressDetail " + day + " " + date + " " + allPackage + "-" + currentPackage);
                    }

                    @Override
                    public void onReadOriginProgress(float progress) {
                        Logger.t(TAG).i("onReadOriginProgress " + progress);
                        sendLocalBoardCast(0, "onReadOriginProgress", String.valueOf(progress));
                    }

                    @Override
                    public void onReadOriginComplete() {
                        Logger.t(TAG).i("onReadOriginComplete ");

                        Map<String, Object> payload = new HashMap<>();
                        payload.put("originData3s", originData3s);
                        payload.put("originHalfHourData", originHalfHourDataList);
                        payload.put("hrvOriginData", hrvOriginDataList);
                        payload.put("spo2hOriginData", spo2hOriginDataList);

                        result.success(new Gson().toJson(payload));
                    }
                },
                DeviceState.watchDataDay
        );
    }

    private void readSpo2hOrigin(final MethodChannel.Result result) {

        final List<Spo2hOriginData> originDataList = new ArrayList<>();

        mVpoperateManager.readSpo2hOrigin(
                writeResponse,
                new ISpo2hOriginDataListener() {
                    @Override
                    public void onReadOriginProgress(float progress) {

                    }

                    @Override
                    public void onReadOriginProgressDetail(int day, String date, int allPackage, int currentPackage) {

                    }

                    @Override
                    public void onSpo2hOriginListener(Spo2hOriginData spo2hOriginData) {
                        originDataList.add(spo2hOriginData);
                    }

                    @Override
                    public void onReadOriginComplete() {
                        result.success(new Gson().toJson(originDataList));
                    }
                },
                DeviceState.watchDataDay
        );
    }

    private void readECGData(final MethodChannel.Result result) {
        TimeData timeData = new TimeData();
        timeData.setCurrentTime();

        mVpoperateManager.readECGData(writeResponse, timeData, EEcgDataType.ALL, new IECGReadDataListener() {
            @Override
            public void readDataFinish(List<EcgDetectResult> list) {
                result.success(new Gson().toJson(list));
            }
        });
    }

    private void readSleepData(final MethodChannel.Result result) {
        Logger.t(TAG).e("Start readSleepData");
        mVpoperateManager.readSleepData(writeResponse, new ISleepDataListener() {
            List<DSleepData> sleepDataList = new ArrayList<>();

            /**
             * Return data. Sleep may be normal sleep or precise sleep.
             * If it is precise sleep, it needs to be forced to SleepPrecisionData.
             * There are two ways to determine: 1. According to the function flag after the password is passed;
             * 2. According to the instanceof keyword ,if(sleepData instanceof SleepPrecisionData)
             * @param sleepDataChange
             */
            @Override
            public void onSleepDataChange(SleepData sleepDataChange) {
                if (sleepDataChange instanceof SleepPrecisionData && DeviceState.isSleepPrecision) {
                    SleepPrecisionData sleepPrecisionData = (SleepPrecisionData) sleepDataChange;
                    Logger.t(TAG).d(sleepPrecisionData.getSleepLine());
                    Logger.t(TAG).d(sleepPrecisionData.toString());
                    sleepDataList.add(new DSleepData(sleepPrecisionData));
                } else {
                    Logger.t(TAG).d(sleepDataChange.toString());
                    sleepDataList.add(new DSleepData(sleepDataChange));
                }
            }

            /**
             * Returns the progress of sleep reading, range [0-1]
             * @param progress
             */
            @Override
            public void onSleepProgress(float progress) {
                // Logger.t(TAG).i("onSleepProgress " + progress);
                sendLocalBoardCast(0, "onSleepProgress", String.valueOf(progress));
            }

            /**
             * Return the details of reading sleep. This interface is only used for testing, which is convenient for developers to view the reading progress
             * @param day
             * @param packagenumber
             */
            @Override
            public void onSleepProgressDetail(String day, int packagenumber) {
                //Logger.t(TAG).i("onSleepProgressDetail " + day + " | " + packagenumber);
            }

            @Override
            public void onReadSleepComplete() {
                Logger.t(TAG).i("onReadSleepComplete");

                result.success(new Gson().toJson(sleepDataList));
            }
        }, DeviceState.watchDataDay);
    }

    private void sdkTest(final MethodChannel.Result result) {
//        mVpoperateManager.readLongSeat(writeResponse, new ILongSeatDataListener() {
//            @Override
//            public void onLongSeatDataChange(LongSeatData longSeatData) {
//                Logger.t(TAG).e(longSeatData.toString());
//                longSeatData.setOpen(true);
//
//                LongSeatSetting longSeatSetting = new LongSeatSetting(
//                        longSeatData.getStartHour(), longSeatData.getStartMinute(),
//                        longSeatData.getStartHour(), longSeatData.getStartMinute(),
//                        longSeatData.getThreshold(),
//                        true
//                );
//
//                mVpoperateManager.settingLongSeat(writeResponse, longSeatSetting, new ILongSeatDataListener() {
//                    @Override
//                    public void onLongSeatDataChange(LongSeatData longSeatData) {
//                        Logger.t(TAG).e(longSeatData.toString());
//                    }
//                });
//            }
//        });

        mVpoperateManager.readSpo2hAutoDetect(writeResponse, new IAllSetDataListener() {
            @Override
            public void onAllSetDataChangeListener(AllSetData allSetData) {
                Logger.t(TAG).e(allSetData.toString());
                AllSetSetting allSetSetting = new AllSetSetting(
                        allSetData.getType(),
                        allSetData.getStartHour(),
                        allSetData.getStartMinute(),
                        allSetData.getEndHour(),
                        allSetData.getEndMinute(),
                        0,
                        1);

                mVpoperateManager.settingSpo2hAutoDetect(writeResponse, new IAllSetDataListener() {
                    @Override
                    public void onAllSetDataChangeListener(AllSetData allSetData) {
                        Logger.t(TAG).i(allSetData.toString());
                        result.success(null);
                    }
                }, allSetSetting);
            }
        });
    }

    /**
     * Stop scan BLE device
     */
    private void stopScanDevice() {
        mVpoperateManager.stopScanDevice();
    }
}
