package vn.com.tma.ehealth.veepoo_sdk.util;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.BluetoothLeScanner;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.widget.Toast;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.inuker.bluetooth.library.utils.BluetoothUtils;
import com.orhanobut.logger.Logger;

public class BluetoothUtil {
    private final static String TAG = BluetoothUtil.class.getSimpleName();

    private static final int REQUEST_CODE = 1;
    public static final int MY_PERMISSIONS_REQUEST_BLUETOOTH = 0x55;

    public static void initBLE(Activity activity) {
        checkBLE(activity);
    }

    /**
     * Detect if Bluetooth device is on
     *
     * @return boolean
     */
    private static boolean checkBLE(Activity activity) {
        if (!BluetoothUtils.isBluetoothEnabled()) {
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            activity.startActivityForResult(enableBtIntent, REQUEST_CODE);
            return false;
        } else {
            return true;
        }
    }

    private static void checkPermission(Activity activity) {
        Logger.t(TAG).i("Build.VERSION.SDK_INT =" + Build.VERSION.SDK_INT);
        if (Build.VERSION.SDK_INT <= 22) {
            initBLE(activity);
            return;
        }

        int permissionCheck = ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_COARSE_LOCATION);
        if (permissionCheck == PackageManager.PERMISSION_GRANTED) {
            Logger.t(TAG).i("checkPermission,PERMISSION_GRANTED");
            initBLE(activity);
        } else if (permissionCheck == PackageManager.PERMISSION_DENIED) {
            requestPermission(activity);
            Toast.makeText(activity, "Please allow location access to scan device", Toast.LENGTH_LONG).show();
            Logger.t(TAG).i("checkPermission,PERMISSION_DENIED");
        }
    }

    public static void requestPermission(Activity activity) {
        if (activity == null) {
            Logger.t(TAG).e("Unable open request permission dialog");
            return;
        }

        if (ContextCompat.checkSelfPermission(activity,
                Manifest.permission.ACCESS_COARSE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            // Should we show an explanation?
            if (ActivityCompat.shouldShowRequestPermissionRationale(activity,
                    Manifest.permission.ACCESS_COARSE_LOCATION)) {
                Logger.t(TAG).i("requestPermission,shouldShowRequestPermissionRationale");

            } else {
                Logger.t(TAG).i("requestPermission,shouldShowRequestPermissionRationale else");
                ActivityCompat.requestPermissions(activity,
                        new String[]{Manifest.permission.ACCESS_COARSE_LOCATION},
                        MY_PERMISSIONS_REQUEST_BLUETOOTH);
            }
        } else {
            Logger.t(TAG).i("requestPermission,shouldShowRequestPermissionRationale hehe");
        }
    }


}
