package com.inuker.bluetooth.library;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;
import com.inuker.bluetooth.library.utils.BluetoothLog;

public class BluetoothService extends Service {
   private static Context mContext;

   public static Context getContext() {
      return mContext;
   }

   public void onCreate() {
      super.onCreate();
      BluetoothLog.v(String.format("BluetoothService onCreate"));
      mContext = this.getApplicationContext();
      BluetoothContext.set(mContext);
   }

   public IBinder onBind(Intent intent) {
      BluetoothLog.v(String.format("BluetoothService onBind"));
      return BluetoothServiceImpl.getInstance();
   }
}
