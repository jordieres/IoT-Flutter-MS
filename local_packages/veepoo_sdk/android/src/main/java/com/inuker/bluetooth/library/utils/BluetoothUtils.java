package com.inuker.bluetooth.library.utils;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;
import android.os.Build;
import android.os.Build.VERSION;
import android.text.TextUtils;
import com.inuker.bluetooth.library.BluetoothContext;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import android.util.Log;

public class BluetoothUtils {
   private static BluetoothManager mBluetoothManager;
   private static BluetoothAdapter mBluetoothAdapter;
   private static Handler mHandler;

//   public static Context getContext() {
//      return BluetoothContext.get();
//   }


   public static Context getContext() {
      // Ensuring the use of the application context to prevent leaking.
      Context context = BluetoothContext.get();
      if (context == null) {
         Log.e("BluetoothUtils", "Context is null");
         return null;
      }
      return context.getApplicationContext();
   }



   private static Handler getHandler() {
      if (mHandler == null) {
         mHandler = new Handler(Looper.getMainLooper());
      }

      return mHandler;
   }

   public static void post(Runnable runnable) {
      getHandler().post(runnable);
   }

   public static void registerReceiver(BroadcastReceiver receiver, IntentFilter filter) {
      registerGlobalReceiver(receiver, filter);
   }




   private static void registerGlobalReceiver(BroadcastReceiver receiver, IntentFilter filter) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
         // Explicitly stating that the receiver is not exported.
         getContext().registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED);


      } else {
         getContext().registerReceiver(receiver, filter);

      }
   }




//   private static void registerGlobalReceiver(BroadcastReceiver receiver, IntentFilter filter) {
//      getContext().registerReceiver(receiver, filter);
//   }

   public static void unregisterReceiver(BroadcastReceiver receiver) {
      unregisterGlobalReceiver(receiver);
   }

   private static void unregisterGlobalReceiver(BroadcastReceiver receiver) {
      getContext().unregisterReceiver(receiver);
   }

   public static void sendBroadcast(Intent intent) {
      sendGlobalBroadcast(intent);
   }

   public static void sendBroadcast(String action) {
      sendGlobalBroadcast(new Intent(action));
   }

   private static void sendGlobalBroadcast(Intent intent) {
      getContext().sendBroadcast(intent);
   }

   public static boolean isBleSupported() {
      return VERSION.SDK_INT >= 18 && getContext() != null && getContext().getPackageManager().hasSystemFeature("android.hardware.bluetooth_le");
   }

   public static boolean isBluetoothEnabled() {
      return getBluetoothState() == 12;
   }

   public static int getBluetoothState() {
      BluetoothAdapter adapter = getBluetoothAdapter();
      return adapter != null ? adapter.getState() : 0;
   }

   public static boolean openBluetooth() {
      BluetoothAdapter adapter = getBluetoothAdapter();
      return adapter != null ? adapter.enable() : false;
   }

   public static boolean closeBluetooth() {
      BluetoothAdapter adapter = getBluetoothAdapter();
      return adapter != null ? adapter.disable() : false;
   }

   public static BluetoothManager getBluetoothManager() {
      if (isBleSupported()) {
         if (mBluetoothManager == null) {
            mBluetoothManager = (BluetoothManager)getContext().getSystemService("bluetooth");
         }

         return mBluetoothManager;
      } else {
         return null;
      }
   }

   public static BluetoothAdapter getBluetoothAdapter() {
      if (mBluetoothAdapter == null) {
         mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
      }

      return mBluetoothAdapter;
   }

   public static BluetoothDevice getRemoteDevice(String mac) {
      if (!TextUtils.isEmpty(mac)) {
         BluetoothAdapter adapter = getBluetoothAdapter();
         if (adapter != null) {
            return adapter.getRemoteDevice(mac);
         }
      }

      return null;
   }

   @TargetApi(18)
   public static List<BluetoothDevice> getConnectedBluetoothLeDevices() {
      List<BluetoothDevice> devices = new ArrayList();
      BluetoothManager manager = getBluetoothManager();
      if (manager != null) {
         devices.addAll(manager.getConnectedDevices(7));
      }

      return devices;
   }

   @TargetApi(18)
   public static int getConnectStatus(String mac) {
      BluetoothManager manager = getBluetoothManager();
      if (manager != null) {
         try {
            BluetoothDevice device = getRemoteDevice(mac);
            return manager.getConnectionState(device, 7);
         } catch (Throwable var3) {
            BluetoothLog.e(var3);
         }
      }

      return -1;
   }

   public static List<BluetoothDevice> getBondedBluetoothClassicDevices() {
      BluetoothAdapter adapter = getBluetoothAdapter();
      List<BluetoothDevice> devices = new ArrayList();
      if (adapter != null) {
         Set<BluetoothDevice> sets = adapter.getBondedDevices();
         if (sets != null) {
            devices.addAll(sets);
         }
      }

      return devices;
   }

   @TargetApi(18)
   public static boolean isDeviceConnected(String mac) {
      if (!TextUtils.isEmpty(mac) && isBleSupported()) {
         BluetoothDevice device = getBluetoothAdapter().getRemoteDevice(mac);
         return getBluetoothManager().getConnectionState(device, 7) == 2;
      } else {
         return false;
      }
   }

   public static boolean checkMainThread() {
      return Looper.myLooper() == Looper.getMainLooper();
   }
}
