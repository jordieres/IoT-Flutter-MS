package com.inuker.bluetooth.library.receiver;

import android.content.Context;
import android.content.Intent;
import com.inuker.bluetooth.library.receiver.listener.BluetoothReceiverListener;
import com.inuker.bluetooth.library.receiver.listener.BluetoothStateChangeListener;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;

public class BluetoothStateReceiver extends AbsBluetoothReceiver {
   private static final String[] ACTIONS = new String[]{"android.bluetooth.adapter.action.STATE_CHANGED"};

   protected BluetoothStateReceiver(IReceiverDispatcher dispatcher) {
      super(dispatcher);
   }

   List<String> getActions() {
      return Arrays.asList(ACTIONS);
   }

   public static BluetoothStateReceiver newInstance(IReceiverDispatcher dispatcher) {
      return new BluetoothStateReceiver(dispatcher);
   }

   public boolean onReceive(Context context, Intent intent) {
      int state = intent.getIntExtra("android.bluetooth.adapter.extra.STATE", 0);
      int previousState = intent.getIntExtra("android.bluetooth.adapter.extra.PREVIOUS_STATE", 0);
      BluetoothLog.v(String.format("state changed: %s -> %s", this.getStateString(previousState), this.getStateString(state)));
      this.onBluetoothStateChanged(previousState, state);
      return true;
   }

   private void onBluetoothStateChanged(int previousState, int state) {
      List<BluetoothReceiverListener> listeners = this.getListeners(BluetoothStateChangeListener.class);
      Iterator var4 = listeners.iterator();

      while(var4.hasNext()) {
         BluetoothReceiverListener listener = (BluetoothReceiverListener)var4.next();
         listener.invoke(new Object[]{previousState, state});
      }

   }

   private String getStateString(int state) {
      switch(state) {
      case 10:
         return "state_off";
      case 11:
         return "state_turning_on";
      case 12:
         return "state_on";
      case 13:
         return "state_turning_off";
      default:
         return "unknown";
      }
   }
}
