package com.inuker.bluetooth.library.connect.request;

import android.os.Message;
import com.inuker.bluetooth.library.connect.listener.ServiceDiscoverListener;
import com.inuker.bluetooth.library.connect.options.BleConnectOptions;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import com.inuker.bluetooth.library.model.BleGattProfile;
import com.inuker.bluetooth.library.utils.BluetoothLog;

public class BleConnectRequest extends BleRequest implements ServiceDiscoverListener {
   private static final int MSG_CONNECT = 1;
   private static final int MSG_DISCOVER_SERVICE = 2;
   private static final int MSG_CONNECT_TIMEOUT = 3;
   private static final int MSG_DISCOVER_SERVICE_TIMEOUT = 4;
   private static final int MSG_RETRY_DISCOVER_SERVICE = 5;
   private BleConnectOptions mConnectOptions;
   private int mConnectCount;
   private int mServiceDiscoverCount;

   public BleConnectRequest(BleConnectOptions options, BleGeneralResponse response) {
      super(response);
      this.mConnectOptions = options != null ? options : (new BleConnectOptions.Builder()).build();
   }

   public void processRequest() {
      this.processConnect();
   }

   private void processConnect() {
      this.mHandler.removeCallbacksAndMessages((Object)null);
      this.mServiceDiscoverCount = 0;
      switch(this.getCurrentStatus()) {
      case 0:
         if (!this.doOpenNewGatt()) {
            this.closeGatt();
         } else {
            this.mHandler.sendEmptyMessageDelayed(3, (long)this.mConnectOptions.getConnectTimeout());
         }
         break;
      case 2:
         this.processDiscoverService();
         break;
      case 19:
         this.onConnectSuccess();
      }

   }

   private boolean doOpenNewGatt() {
      ++this.mConnectCount;
      return this.openGatt();
   }

   private boolean doDiscoverService() {
      ++this.mServiceDiscoverCount;
      return this.discoverService();
   }

   private void retryConnectIfNeeded() {
      if (this.mConnectCount < this.mConnectOptions.getConnectRetry() + 1) {
         this.retryConnectLater();
      } else {
         this.onRequestCompleted(-1);
      }

   }

   private void retryDiscoverServiceIfNeeded() {
      if (this.mServiceDiscoverCount < this.mConnectOptions.getServiceDiscoverRetry() + 1) {
         this.retryDiscoverServiceLater();
      } else {
         this.closeGatt();
      }

   }

   private void onServiceDiscoverFailed() {
      BluetoothLog.v(String.format("onServiceDiscoverFailed"));
      this.refreshDeviceCache();
      this.mHandler.sendEmptyMessage(5);
   }

   private void processDiscoverService() {
      BluetoothLog.v(String.format("processDiscoverService, status = %s", this.getStatusText()));
      switch(this.getCurrentStatus()) {
      case 0:
         this.retryConnectIfNeeded();
         break;
      case 2:
         if (!this.doDiscoverService()) {
            this.onServiceDiscoverFailed();
         } else {
            this.mHandler.sendEmptyMessageDelayed(4, (long)this.mConnectOptions.getServiceDiscoverTimeout());
         }
         break;
      case 19:
         this.onConnectSuccess();
      }

   }

   private void retryConnectLater() {
      this.log(String.format("retry connect later"));
      this.mHandler.removeCallbacksAndMessages((Object)null);
      this.mHandler.sendEmptyMessageDelayed(1, 1000L);
   }

   private void retryDiscoverServiceLater() {
      this.log(String.format("retry discover service later"));
      this.mHandler.removeCallbacksAndMessages((Object)null);
      this.mHandler.sendEmptyMessageDelayed(2, 1000L);
   }

   private void processConnectTimeout() {
      this.log(String.format("connect timeout"));
      this.mHandler.removeCallbacksAndMessages((Object)null);
      this.closeGatt();
   }

   private void processDiscoverServiceTimeout() {
      this.log(String.format("service discover timeout"));
      this.mHandler.removeCallbacksAndMessages((Object)null);
      this.closeGatt();
   }

   public boolean handleMessage(Message msg) {
      switch(msg.what) {
      case 1:
         this.processConnect();
         break;
      case 2:
         this.processDiscoverService();
         break;
      case 3:
         this.processConnectTimeout();
         break;
      case 4:
         this.processDiscoverServiceTimeout();
         break;
      case 5:
         this.retryDiscoverServiceIfNeeded();
      }

      return super.handleMessage(msg);
   }

   public String toString() {
      return "BleConnectRequest{options=" + this.mConnectOptions + '}';
   }

   public void onConnectStatusChanged(boolean connectedOrDisconnected) {
      this.checkRuntime();
      this.mHandler.removeMessages(3);
      if (connectedOrDisconnected) {
         this.mHandler.sendEmptyMessageDelayed(2, 300L);
      } else {
         this.mHandler.removeCallbacksAndMessages((Object)null);
         this.retryConnectIfNeeded();
      }

   }

   public void onServicesDiscovered(int status, BleGattProfile profile) {
      this.checkRuntime();
      this.mHandler.removeMessages(4);
      if (status == 0) {
         this.onConnectSuccess();
      } else {
         this.onServiceDiscoverFailed();
      }

   }

   private void onConnectSuccess() {
      BleGattProfile profile = this.getGattProfile();
      if (profile != null) {
         this.putParcelable("extra.gatt.profile", profile);
      }

      this.onRequestCompleted(0);
   }
}
