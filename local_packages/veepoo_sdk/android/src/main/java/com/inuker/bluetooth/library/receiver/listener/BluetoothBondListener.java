package com.inuker.bluetooth.library.receiver.listener;

public abstract class BluetoothBondListener extends BluetoothClientListener {
   public abstract void onBondStateChanged(String var1, int var2);

   public void onSyncInvoke(Object... args) {
      String mac = (String)args[0];
      int bondState = (Integer)args[1];
      this.onBondStateChanged(mac, bondState);
   }
}
