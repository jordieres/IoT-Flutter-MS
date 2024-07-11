package com.inuker.bluetooth.library.receiver.listener;

import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Handler.Callback;

public abstract class AbsBluetoothListener implements Callback {
   private static final int MSG_INVOKE = 1;
   private static final int MSG_SYNC_INVOKE = 2;
   private Handler mHandler;
   private Handler mSyncHandler;

   public AbsBluetoothListener() {
      if (Looper.myLooper() == null) {
         throw new IllegalStateException();
      } else {
         this.mHandler = new Handler(Looper.myLooper(), this);
         this.mSyncHandler = new Handler(Looper.getMainLooper(), this);
      }
   }

   public boolean handleMessage(Message msg) {
      Object[] args = (Object[])((Object[])msg.obj);
      switch(msg.what) {
      case 1:
         this.onInvoke(args);
         break;
      case 2:
         this.onSyncInvoke(args);
      }

      return true;
   }

   public final void invoke(Object... args) {
      this.mHandler.obtainMessage(1, args).sendToTarget();
   }

   public final void invokeSync(Object... args) {
      this.mSyncHandler.obtainMessage(2, args).sendToTarget();
   }

   public abstract void onInvoke(Object... var1);

   public abstract void onSyncInvoke(Object... var1);
}
