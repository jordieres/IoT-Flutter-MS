package com.inuker.bluetooth.library.receiver.listener;

public abstract class BluetoothBondStateChangeListener extends BluetoothReceiverListener {
   protected abstract void onBondStateChanged(String var1, int var2);

   public void onInvoke(Object... args) {
      String mac = (String)args[0];
      int bondState = (Integer)args[1];
      this.onBondStateChanged(mac, bondState);
   }

   public String getName() {
      return BluetoothBondStateChangeListener.class.getSimpleName();
   }
}
