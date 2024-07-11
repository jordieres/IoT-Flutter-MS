package com.inuker.bluetooth.library.receiver.listener;

import android.content.Context;
import com.inuker.bluetooth.library.BluetoothClientImpl;

public abstract class BluetoothStateChangeListener extends BluetoothReceiverListener {
   protected abstract void onBluetoothStateChanged(int var1, int var2);

   public void onInvoke(Object... args) {
      int prevState = (Integer)args[0];
      int curState = (Integer)args[1];
      if (curState == 10 || curState == 13) {
         BluetoothClientImpl.getInstance((Context)null).stopSearch();
      }

      this.onBluetoothStateChanged(prevState, curState);
   }

   public String getName() {
      return BluetoothStateChangeListener.class.getSimpleName();
   }
}
