package com.inuker.bluetooth.library.connect.response;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.RemoteException;
import android.os.Handler.Callback;
import com.inuker.bluetooth.library.IResponse;

public abstract class BluetoothResponse extends IResponse.Stub implements Callback {
   private static final int MSG_RESPONSE = 1;
   private Handler mHandler;

   protected abstract void onAsyncResponse(int var1, Bundle var2);

   protected BluetoothResponse() {
      if (Looper.myLooper() == null) {
         throw new RuntimeException();
      } else {
         this.mHandler = new Handler(Looper.myLooper(), this);
      }
   }

   public void onResponse(int code, Bundle data) throws RemoteException {
      this.mHandler.obtainMessage(1, code, 0, data).sendToTarget();
   }

   public boolean handleMessage(Message msg) {
      switch(msg.what) {
      case 1:
         this.onAsyncResponse(msg.arg1, (Bundle)msg.obj);
      default:
         return true;
      }
   }
}
