package vn.com.tma.ehealth.veepoo_sdk.util;

import android.content.Context;
import android.content.SharedPreferences;

public class DeviceConnectUtil {
    private final static String NAME = "device_connect_info";

    public static String getCurrentMacAddress(Context context) {
        SharedPreferences sharedPref = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        return sharedPref.getString("macAddress", "");
    }

    public static String getPin(Context context) {
        SharedPreferences sharedPref = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        return sharedPref.getString("password", "");
    }

    public static boolean get24hSetting(Context context) {
        SharedPreferences sharedPref = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        return sharedPref.getBoolean("is24h", true);
    }

    public static void saveCurrentCredentials(Context context, String macAddress, String password, Boolean is24h) {
        SharedPreferences sharedPref = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();

        editor.putString("macAddress", macAddress);
        editor.putString("password", password);
        editor.putBoolean("is24h", is24h);
        editor.apply();
    }
}
