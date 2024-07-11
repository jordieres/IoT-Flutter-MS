package com.inuker.bluetooth.library.receiver;

import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.content.Intent;
import com.inuker.bluetooth.library.receiver.listener.BluetoothBondStateChangeListener;
import com.inuker.bluetooth.library.receiver.listener.BluetoothReceiverListener;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;

public class BluetoothBondReceiver extends AbsBluetoothReceiver {
   private static final String[] ACTIONS = new String[]{"android.bluetooth.device.action.BOND_STATE_CHANGED"};

   protected BluetoothBondReceiver(IReceiverDispatcher dispatcher) {
      super(dispatcher);
   }

   public static BluetoothBondReceiver newInstance(IReceiverDispatcher dispatcher) {
      return new BluetoothBondReceiver(dispatcher);
   }

   List<String> getActions() {
      return Arrays.asList(ACTIONS);
   }

   boolean onReceive(Context context, Intent intent) {
      BluetoothDevice device = (BluetoothDevice)intent.getParcelableExtra("android.bluetooth.device.extra.DEVICE");
      int state = intent.getIntExtra("android.bluetooth.device.extra.BOND_STATE", -1);
      if (device != null) {
         this.onBondStateChanged(device.getAddress(), state);
      }

      return true;
   }

   private void onBondStateChanged(String mac, int bondState) {
      List<BluetoothReceiverListener> listeners = this.getListeners(BluetoothBondStateChangeListener.class);
      Iterator var4 = listeners.iterator();

      while(var4.hasNext()) {
         BluetoothReceiverListener listener = (BluetoothReceiverListener)var4.next();
         listener.invoke(new Object[]{mac, bondState});
      }

   }
}
