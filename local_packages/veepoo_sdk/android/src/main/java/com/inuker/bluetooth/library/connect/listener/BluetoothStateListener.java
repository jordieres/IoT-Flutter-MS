package com.inuker.bluetooth.library.connect.listener;

import com.inuker.bluetooth.library.receiver.listener.BluetoothClientListener;

public abstract class BluetoothStateListener extends BluetoothClientListener {
   public abstract void onBluetoothStateChanged(boolean var1);

   public void onSyncInvoke(Object... args) {
      boolean openOrClosed = (Boolean)args[0];
      this.onBluetoothStateChanged(openOrClosed);
   }
}
