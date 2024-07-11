package com.inuker.bluetooth.library.receiver.listener;

import java.util.UUID;

public abstract class BleCharacterChangeListener extends BluetoothReceiverListener {
   protected abstract void onCharacterChanged(String var1, UUID var2, UUID var3, byte[] var4);

   public void onInvoke(Object... args) {
      String mac = (String)args[0];
      UUID service = (UUID)args[1];
      UUID character = (UUID)args[2];
      byte[] value = (byte[])((byte[])args[3]);
      this.onCharacterChanged(mac, service, character, value);
   }

   public String getName() {
      return BleCharacterChangeListener.class.getSimpleName();
   }
}
