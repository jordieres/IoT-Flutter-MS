package com.inuker.bluetooth.library.receiver;

import android.content.Context;
import android.content.Intent;
import com.inuker.bluetooth.library.receiver.listener.BleConnectStatusChangeListener;
import com.inuker.bluetooth.library.receiver.listener.BluetoothReceiverListener;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;

public class BleConnectStatusChangeReceiver extends AbsBluetoothReceiver {
   private static final String[] ACTIONS = new String[]{"action.connect_status_changed"};

   protected BleConnectStatusChangeReceiver(IReceiverDispatcher dispatcher) {
      super(dispatcher);
   }

   public static BleConnectStatusChangeReceiver newInstance(IReceiverDispatcher dispatcher) {
      return new BleConnectStatusChangeReceiver(dispatcher);
   }

   List<String> getActions() {
      return Arrays.asList(ACTIONS);
   }

   boolean onReceive(Context context, Intent intent) {
      String mac = intent.getStringExtra("extra.mac");
      int status = intent.getIntExtra("extra.status", 0);
      BluetoothLog.v(String.format("onConnectStatusChanged for %s, status = %d", mac, status));
      this.onConnectStatusChanged(mac, status);
      return true;
   }

   private void onConnectStatusChanged(String mac, int status) {
      List<BluetoothReceiverListener> listeners = this.getListeners(BleConnectStatusChangeListener.class);
      Iterator var4 = listeners.iterator();

      while(var4.hasNext()) {
         BluetoothReceiverListener listener = (BluetoothReceiverListener)var4.next();
         listener.invoke(new Object[]{mac, status});
      }

   }
}
