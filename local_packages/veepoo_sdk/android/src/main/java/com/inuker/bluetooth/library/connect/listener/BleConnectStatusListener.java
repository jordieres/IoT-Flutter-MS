package com.inuker.bluetooth.library.connect.listener;

import com.inuker.bluetooth.library.receiver.listener.BluetoothClientListener;

public abstract class BleConnectStatusListener extends BluetoothClientListener {
   public abstract void onConnectStatusChanged(String var1, int var2);

   public void onSyncInvoke(Object... args) {
      String mac = (String)args[0];
      int status = (Integer)args[1];
      this.onConnectStatusChanged(mac, status);
   }
}
