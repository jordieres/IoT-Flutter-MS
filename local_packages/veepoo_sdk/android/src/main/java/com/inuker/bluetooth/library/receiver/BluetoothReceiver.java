package com.inuker.bluetooth.library.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Handler.Callback;
import android.text.TextUtils;
import com.inuker.bluetooth.library.receiver.listener.BluetoothReceiverListener;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import com.inuker.bluetooth.library.utils.BluetoothUtils;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

public class BluetoothReceiver extends BroadcastReceiver implements IBluetoothReceiver, Callback {
   private static final int MSG_REGISTER = 1;
   private Map<String, List<BluetoothReceiverListener>> mListeners;
   private static IBluetoothReceiver mReceiver;
   private Handler mHandler;
   private IReceiverDispatcher mDispatcher = new IReceiverDispatcher() {
      public List<BluetoothReceiverListener> getListeners(Class<?> clazz) {
         return (List)BluetoothReceiver.this.mListeners.get(clazz.getSimpleName());
      }
   };
   private AbsBluetoothReceiver[] RECEIVERS;

   public static IBluetoothReceiver getInstance() {
      if (mReceiver == null) {
         Class var0 = BluetoothReceiver.class;
         synchronized(BluetoothReceiver.class) {
            if (mReceiver == null) {
               mReceiver = new BluetoothReceiver();
            }
         }
      }

      return mReceiver;
   }

   private BluetoothReceiver() {
      this.RECEIVERS = new AbsBluetoothReceiver[]{BluetoothStateReceiver.newInstance(this.mDispatcher), BluetoothBondReceiver.newInstance(this.mDispatcher), BleConnectStatusChangeReceiver.newInstance(this.mDispatcher), BleCharacterChangeReceiver.newInstance(this.mDispatcher)};
      this.mListeners = new HashMap();
      this.mHandler = new Handler(Looper.getMainLooper(), this);
      BluetoothUtils.registerReceiver(this, this.getIntentFilter());
   }

   private IntentFilter getIntentFilter() {
      IntentFilter filter = new IntentFilter();
      AbsBluetoothReceiver[] var2 = this.RECEIVERS;
      int var3 = var2.length;

      for(int var4 = 0; var4 < var3; ++var4) {
         AbsBluetoothReceiver receiver = var2[var4];
         List<String> actions = receiver.getActions();
         Iterator var7 = actions.iterator();

         while(var7.hasNext()) {
            String action = (String)var7.next();
            filter.addAction(action);
         }
      }

      return filter;
   }

   public void onReceive(Context context, Intent intent) {
      if (intent != null) {
         String action = intent.getAction();
         if (!TextUtils.isEmpty(action)) {
            BluetoothLog.v(String.format("BluetoothReceiver onReceive: %s", action));
            AbsBluetoothReceiver[] var4 = this.RECEIVERS;
            int var5 = var4.length;

            for(int var6 = 0; var6 < var5; ++var6) {
               AbsBluetoothReceiver receiver = var4[var6];
               if (receiver.containsAction(action) && receiver.onReceive(context, intent)) {
                  return;
               }
            }

         }
      }
   }

   public void register(BluetoothReceiverListener listener) {
      this.mHandler.obtainMessage(1, listener).sendToTarget();
   }

   private void registerInner(BluetoothReceiverListener listener) {
      if (listener != null) {
         List<BluetoothReceiverListener> listeners = (List)this.mListeners.get(listener.getName());
         if (listeners == null) {
            listeners = new LinkedList();
            this.mListeners.put(listener.getName(), listeners);
         }

         ((List)listeners).add(listener);
      }

   }

   public boolean handleMessage(Message msg) {
      switch(msg.what) {
      case 1:
         this.registerInner((BluetoothReceiverListener)msg.obj);
      default:
         return true;
      }
   }
}
