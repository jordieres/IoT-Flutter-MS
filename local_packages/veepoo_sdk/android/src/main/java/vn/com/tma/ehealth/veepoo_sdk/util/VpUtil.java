package vn.com.tma.ehealth.veepoo_sdk.util;

import android.content.Context;
import android.content.SharedPreferences;

public class VpUtil {
    public static int getDeviceVersion(Context mContext) {
        SharedPreferences sharedPreferences = mContext.getApplicationContext().getSharedPreferences("vpsdk", Context.MODE_PRIVATE);
        return sharedPreferences.getInt("count_origin_protocol_version", 0);
    }
}
