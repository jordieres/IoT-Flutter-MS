package com.inuker.bluetooth.library.receiver.listener;

public abstract class BluetoothClientListener extends AbsBluetoothListener {
   public final void onInvoke(Object... args) {
      throw new UnsupportedOperationException();
   }
}
