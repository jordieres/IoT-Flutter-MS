package vn.com.tma.ehealth.veepoo_sdk.service;

import android.app.IntentService;
import android.content.Intent;
import android.content.Context;

import com.orhanobut.logger.LogLevel;
import com.orhanobut.logger.Logger;
import com.veepoo.protocol.VPOperateManager;
import com.veepoo.protocol.listener.base.IABluetoothStateListener;
import com.veepoo.protocol.util.VPLogger;

import vn.com.tma.ehealth.veepoo_sdk.MethodCallHandlerImpl;
import vn.com.tma.ehealth.veepoo_sdk.adapter.CustomLogAdapter;
import vn.com.tma.ehealth.veepoo_sdk.util.NotificationHelper;

/**
 * An {@link IntentService} subclass for handling asynchronous task requests in
 * a service on a separate handler thread.
 * <p>
 * TODO: Customize class - update intent actions, extra parameters and static
 * helper methods.
 */
public class BleService extends IntentService {
    private final static String TAG = MethodCallHandlerImpl.class.getSimpleName();
    private VPOperateManager mVpoperateManager;
    private final static int NOTIFICATION_ID = 25;
    private NotificationHelper notificationHelper;

    private static final String ACTION_CONNECT = "vn.com.tma.ehealth.veepoo_sdk.service.action.DEVICE_CONNECT";

    private static final String EXTRA_DEVICE_MAC_ADDRESS = "vn.com.tma.ehealth.veepoo_sdk.service.extra.MAC_ADDRESS";

    public BleService() {
        super("BleService");
        Logger.init("ehealth")
                .methodCount(0)
                .methodOffset(0)
                .hideThreadInfo()
                .logLevel(LogLevel.FULL)
                .logAdapter(new CustomLogAdapter());

        Logger.t(TAG).i("BleService Init");

        notificationHelper = new NotificationHelper(this);
    }

    /**
     * Listen for the callback status between Bluetooth and the device
     */
    private final IABluetoothStateListener mBluetoothStateListener = new IABluetoothStateListener() {
        @Override
        public void onBluetoothStateChanged(boolean openOrClosed) {
            Logger.t(TAG).i("Bluetooth open=" + openOrClosed);

            if (!openOrClosed) {
                notificationHelper.showNotificationOnGoing(NOTIFICATION_ID, "E-Health", "Bluetooth was disabled, unable connect to device");
            } else {
                notificationHelper.dismissById(NOTIFICATION_ID);
            }
        }
    };

    public static void startActionDeviceConnect(Context context, String macAddress) {
        Intent intent = new Intent(context, BleService.class);
        intent.setAction(ACTION_CONNECT);
        intent.putExtra(EXTRA_DEVICE_MAC_ADDRESS, macAddress);
        context.startService(intent);
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        if (intent != null) {
            final String action = intent.getAction();
            if (ACTION_CONNECT.equals(action)) {
                final String macAddress = intent.getStringExtra(EXTRA_DEVICE_MAC_ADDRESS);
                handleActionDeviceConnect(macAddress);
            }
        }
    }

    private void handleActionDeviceConnect(String macAddress) {
        // TODO: Handle action Baz
        throw new UnsupportedOperationException("Not yet implemented");
    }
}
