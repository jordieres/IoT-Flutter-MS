package com.inuker.bluetooth.library.receiver;

import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import com.inuker.bluetooth.library.BluetoothContext;
import com.inuker.bluetooth.library.receiver.listener.BluetoothReceiverListener;
import com.inuker.bluetooth.library.utils.ListUtils;
import java.util.Collections;
import java.util.List;

public abstract class AbsBluetoothReceiver {
   protected Context mContext;
   protected Handler mHandler;
   protected IReceiverDispatcher mDispatcher;

   protected AbsBluetoothReceiver(IReceiverDispatcher dispatcher) {
      this.mDispatcher = dispatcher;
      this.mContext = BluetoothContext.get();
      this.mHandler = new Handler(Looper.getMainLooper());
   }

   boolean containsAction(String action) {
      List<String> actions = this.getActions();
      return !ListUtils.isEmpty(actions) && !TextUtils.isEmpty(action) ? actions.contains(action) : false;
   }

   protected List<BluetoothReceiverListener> getListeners(Class<?> clazz) {
      List<BluetoothReceiverListener> listeners = this.mDispatcher.getListeners(clazz);
      return listeners != null ? listeners : Collections.EMPTY_LIST;
   }

   abstract List<String> getActions();

   abstract boolean onReceive(Context var1, Intent var2);
}
