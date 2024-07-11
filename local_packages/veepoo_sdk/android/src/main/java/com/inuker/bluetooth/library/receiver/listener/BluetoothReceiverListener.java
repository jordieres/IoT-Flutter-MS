package com.inuker.bluetooth.library.receiver.listener;

public abstract class BluetoothReceiverListener extends AbsBluetoothListener {
   public abstract String getName();

   public final void onSyncInvoke(Object... args) {
      throw new UnsupportedOperationException();
   }
}
