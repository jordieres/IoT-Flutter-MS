package vn.com.tma.ehealth.veepoo_sdk.util;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
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
        if (checkBLE(activity) && checkPermission(activity)) {
            // Perform additional operations here if needed after successful checks
        }
    }

    /**
     * Check if Bluetooth is enabled on the device.
     */
    private static boolean checkBLE(Activity activity) {
        if (!BluetoothUtils.isBluetoothEnabled()) {
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            activity.startActivityForResult(enableBtIntent, REQUEST_CODE);
            return false;
        }
        return true;
    }

    /**
     * Check and request necessary permissions.
     */
    private static boolean checkPermission(Activity activity) {
        String[] permissions = {
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.ACCESS_FINE_LOCATION
        };

        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(activity, permission) != PackageManager.PERMISSION_GRANTED) {
                requestPermission(activity, permissions);
                return false;
            }
        }
        return true;
    }

    /**
     * Request permissions that are not already granted.
     */
    public static void requestPermission(Activity activity, String[] permissions) {
        if (ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.ACCESS_FINE_LOCATION) ||
                ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.ACCESS_COARSE_LOCATION)) {
            Logger.t(TAG).i("Displaying permission rationale to provide additional context.");
            Toast.makeText(activity, "Please allow location access to scan for Bluetooth devices.", Toast.LENGTH_LONG).show();
        }
        ActivityCompat.requestPermissions(activity, permissions, MY_PERMISSIONS_REQUEST_BLUETOOTH);
    }
}