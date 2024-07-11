package com.inuker.bluetooth.library.receiver.listener;

public abstract class BleConnectStatusChangeListener extends BluetoothReceiverListener {
   protected abstract void onConnectStatusChanged(String var1, int var2);

   public void onInvoke(Object... args) {
      String mac = (String)args[0];
      int status = (Integer)args[1];
      this.onConnectStatusChanged(mac, status);
   }

   public String getName() {
      return BleConnectStatusChangeListener.class.getSimpleName();
   }
}
