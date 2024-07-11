package com.inuker.bluetooth.library.receiver;

import android.content.Context;
import android.content.Intent;
import com.inuker.bluetooth.library.receiver.listener.BleCharacterChangeListener;
import com.inuker.bluetooth.library.receiver.listener.BluetoothReceiverListener;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.UUID;

public class BleCharacterChangeReceiver extends AbsBluetoothReceiver {
   private static final String[] ACTIONS = new String[]{"action.character_changed"};

   protected BleCharacterChangeReceiver(IReceiverDispatcher dispatcher) {
      super(dispatcher);
   }

   public static BleCharacterChangeReceiver newInstance(IReceiverDispatcher dispatcher) {
      return new BleCharacterChangeReceiver(dispatcher);
   }

   List<String> getActions() {
      return Arrays.asList(ACTIONS);
   }

   boolean onReceive(Context context, Intent intent) {
      String mac = intent.getStringExtra("extra.mac");
      UUID service = (UUID)intent.getSerializableExtra("extra.service.uuid");
      UUID character = (UUID)intent.getSerializableExtra("extra.character.uuid");
      byte[] value = intent.getByteArrayExtra("extra.byte.value");
      this.onCharacterChanged(mac, service, character, value);
      return true;
   }

   private void onCharacterChanged(String mac, UUID service, UUID character, byte[] value) {
      List<BluetoothReceiverListener> listeners = this.getListeners(BleCharacterChangeListener.class);
      Iterator var6 = listeners.iterator();

      while(var6.hasNext()) {
         BluetoothReceiverListener listener = (BluetoothReceiverListener)var6.next();
         listener.invoke(new Object[]{mac, service, character, value});
      }

   }
}
