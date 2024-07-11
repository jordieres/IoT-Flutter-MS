package com.inuker.bluetooth.library.connect.request;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Parcelable;
import android.os.Handler.Callback;
import com.inuker.bluetooth.library.Constants;
import com.inuker.bluetooth.library.RuntimeChecker;
import com.inuker.bluetooth.library.connect.IBleConnectDispatcher;
import com.inuker.bluetooth.library.connect.IBleConnectWorker;
import com.inuker.bluetooth.library.connect.listener.GattResponseListener;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import com.inuker.bluetooth.library.model.BleGattProfile;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import com.inuker.bluetooth.library.utils.BluetoothUtils;
import java.util.UUID;

public abstract class BleRequest implements IBleConnectWorker, IBleRequest, Callback, GattResponseListener, RuntimeChecker {
   protected static final int MSG_REQUEST_TIMEOUT = 32;
   protected BleGeneralResponse mResponse;
   protected Bundle mExtra;
   protected String mAddress;
   protected IBleConnectDispatcher mDispatcher;
   protected IBleConnectWorker mWorker;
   protected Handler mHandler;
   protected Handler mResponseHandler;
   private RuntimeChecker mRuntimeChecker;
   private boolean mFinished;
   protected boolean mRequestTimeout;

   public BleRequest(BleGeneralResponse response) {
      this.mResponse = response;
      this.mExtra = new Bundle();
      this.mHandler = new Handler(Looper.myLooper(), this);
      this.mResponseHandler = new Handler(Looper.getMainLooper());
   }

   public String getAddress() {
      return this.mAddress;
   }

   public void setAddress(String address) {
      this.mAddress = address;
   }

   public void setWorker(IBleConnectWorker worker) {
      this.mWorker = worker;
   }

   public void onResponse(final int code) {
      if (!this.mFinished) {
         this.mFinished = true;
         this.mResponseHandler.post(new Runnable() {
            public void run() {
               try {
                  if (BleRequest.this.mResponse != null) {
                     BleRequest.this.mResponse.onResponse(code, BleRequest.this.mExtra);
                  }
               } catch (Throwable var2) {
                  var2.printStackTrace();
               }

            }
         });
      }
   }

   public String toString() {
      StringBuilder sb = new StringBuilder();
      sb.append(this.getClass().getSimpleName());
      return sb.toString();
   }

   public void putIntExtra(String key, int value) {
      this.mExtra.putInt(key, value);
   }

   public int getIntExtra(String key, int defaultValue) {
      return this.mExtra.getInt(key, defaultValue);
   }

   public void putByteArray(String key, byte[] bytes) {
      this.mExtra.putByteArray(key, bytes);
   }

   public void putParcelable(String key, Parcelable object) {
      this.mExtra.putParcelable(key, object);
   }

   public Bundle getExtra() {
      return this.mExtra;
   }

   protected String getStatusText() {
      return Constants.getStatusText(this.getCurrentStatus());
   }

   public boolean readDescriptor(UUID service, UUID characteristic, UUID descriptor) {
      return this.mWorker.readDescriptor(service, characteristic, descriptor);
   }

   public boolean writeDescriptor(UUID service, UUID characteristic, UUID descriptor, byte[] value) {
      return this.mWorker.writeDescriptor(service, characteristic, descriptor, value);
   }

   public abstract void processRequest();

   public boolean openGatt() {
      return this.mWorker.openGatt();
   }

   public boolean discoverService() {
      return this.mWorker.discoverService();
   }

   public int getCurrentStatus() {
      return this.mWorker.getCurrentStatus();
   }

   public final void process(IBleConnectDispatcher dispatcher) {
      this.checkRuntime();
      this.mDispatcher = dispatcher;
      BluetoothLog.w(String.format("Process %s, status = %s", this.getClass().getSimpleName(), this.getStatusText()));
      if (!BluetoothUtils.isBleSupported()) {
         this.onRequestCompleted(-4);
      } else if (!BluetoothUtils.isBluetoothEnabled()) {
         this.onRequestCompleted(-5);
      } else {
         try {
            this.registerGattResponseListener(this);
            this.processRequest();
         } catch (Throwable var3) {
            BluetoothLog.e(var3);
            this.onRequestCompleted(-10);
         }
      }

   }

   protected void onRequestCompleted(int code) {
      this.log(String.format("request complete: code = %d", code));
      this.mHandler.removeCallbacksAndMessages((Object)null);
      this.clearGattResponseListener(this);
      this.onResponse(code);
      this.mDispatcher.onRequestCompleted(this);
   }

   public void closeGatt() {
      this.log(String.format("close gatt"));
      this.mWorker.closeGatt();
   }

   public boolean handleMessage(Message msg) {
      switch(msg.what) {
      case 32:
         this.mRequestTimeout = true;
         this.closeGatt();
      default:
         return true;
      }
   }

   public void registerGattResponseListener(GattResponseListener listener) {
      this.mWorker.registerGattResponseListener(listener);
   }

   public void clearGattResponseListener(GattResponseListener listener) {
      this.mWorker.clearGattResponseListener(listener);
   }

   public boolean refreshDeviceCache() {
      return this.mWorker.refreshDeviceCache();
   }

   public boolean readCharacteristic(UUID service, UUID characteristic) {
      return this.mWorker.readCharacteristic(service, characteristic);
   }

   public boolean writeCharacteristic(UUID service, UUID character, byte[] value) {
      return this.mWorker.writeCharacteristic(service, character, value);
   }

   public boolean writeCharacteristicWithNoRsp(UUID service, UUID character, byte[] value) {
      return this.mWorker.writeCharacteristicWithNoRsp(service, character, value);
   }

   public boolean setCharacteristicNotification(UUID service, UUID character, boolean enable) {
      return this.mWorker.setCharacteristicNotification(service, character, enable);
   }

   public boolean setCharacteristicIndication(UUID service, UUID character, boolean enable) {
      return this.mWorker.setCharacteristicIndication(service, character, enable);
   }

   public boolean readRemoteRssi() {
      return this.mWorker.readRemoteRssi();
   }

   protected void log(String msg) {
      BluetoothLog.v(String.format("%s %s >>> %s", this.getClass().getSimpleName(), this.getAddress(), msg));
   }

   public void setRuntimeChecker(RuntimeChecker checker) {
      this.mRuntimeChecker = checker;
   }

   public void checkRuntime() {
      this.mRuntimeChecker.checkRuntime();
   }

   public void cancel() {
      this.checkRuntime();
      this.log(String.format("request canceled"));
      this.mHandler.removeCallbacksAndMessages((Object)null);
      this.clearGattResponseListener(this);
      this.onResponse(-2);
   }

   protected long getTimeoutInMillis() {
      return 30000L;
   }

   public void onConnectStatusChanged(boolean connectedOrDisconnected) {
      if (!connectedOrDisconnected) {
         this.onRequestCompleted(this.mRequestTimeout ? -7 : -1);
      }

   }

   protected void startRequestTiming() {
      this.mHandler.sendEmptyMessageDelayed(32, this.getTimeoutInMillis());
   }

   protected void stopRequestTiming() {
      this.mHandler.removeMessages(32);
   }

   public BleGattProfile getGattProfile() {
      return this.mWorker.getGattProfile();
   }
}
