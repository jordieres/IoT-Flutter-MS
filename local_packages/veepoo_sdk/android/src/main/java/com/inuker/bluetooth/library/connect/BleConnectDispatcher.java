package com.inuker.bluetooth.library.connect;

import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Handler.Callback;
import com.inuker.bluetooth.library.RuntimeChecker;
import com.inuker.bluetooth.library.connect.options.BleConnectOptions;
import com.inuker.bluetooth.library.connect.request.BleConnectRequest;
import com.inuker.bluetooth.library.connect.request.BleIndicateRequest;
import com.inuker.bluetooth.library.connect.request.BleNotifyRequest;
import com.inuker.bluetooth.library.connect.request.BleReadDescriptorRequest;
import com.inuker.bluetooth.library.connect.request.BleReadRequest;
import com.inuker.bluetooth.library.connect.request.BleReadRssiRequest;
import com.inuker.bluetooth.library.connect.request.BleRequest;
import com.inuker.bluetooth.library.connect.request.BleUnnotifyRequest;
import com.inuker.bluetooth.library.connect.request.BleWriteDescriptorRequest;
import com.inuker.bluetooth.library.connect.request.BleWriteNoRspRequest;
import com.inuker.bluetooth.library.connect.request.BleWriteRequest;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import com.inuker.bluetooth.library.utils.ListUtils;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.UUID;

public class BleConnectDispatcher implements IBleConnectDispatcher, RuntimeChecker, Callback {
   private static final int MAX_REQUEST_COUNT = 100;
   private static final int MSG_SCHEDULE_NEXT = 18;
   private List<BleRequest> mBleWorkList;
   private BleRequest mCurrentRequest;
   private IBleConnectWorker mWorker;
   private String mAddress;
   private Handler mHandler;

   public static BleConnectDispatcher newInstance(String mac) {
      return new BleConnectDispatcher(mac);
   }

   private BleConnectDispatcher(String mac) {
      this.mAddress = mac;
      this.mBleWorkList = new LinkedList();
      this.mWorker = new BleConnectWorker(mac, this);
      this.mHandler = new Handler(Looper.myLooper(), this);
   }

   public void connect(BleConnectOptions options, BleGeneralResponse response) {
      this.addNewRequest(new BleConnectRequest(options, response));
   }

   public void disconnect() {
      this.checkRuntime();
      BluetoothLog.w(String.format("Process disconnect"));
      if (this.mCurrentRequest != null) {
         this.mCurrentRequest.cancel();
         this.mCurrentRequest = null;
      }

      Iterator var1 = this.mBleWorkList.iterator();

      while(var1.hasNext()) {
         BleRequest request = (BleRequest)var1.next();
         request.cancel();
      }

      this.mBleWorkList.clear();
      this.mWorker.closeGatt();
   }

   public void clearRequest(int clearType) {
      this.checkRuntime();
      BluetoothLog.w(String.format("clearRequest %d", clearType));
      List<BleRequest> requestClear = new LinkedList();
      Iterator var3;
      BleRequest request;
      if (clearType == 0) {
         requestClear.addAll(this.mBleWorkList);
      } else {
         var3 = this.mBleWorkList.iterator();

         while(var3.hasNext()) {
            request = (BleRequest)var3.next();
            if (this.isRequestMatch(request, clearType)) {
               requestClear.add(request);
            }
         }
      }

      var3 = requestClear.iterator();

      while(var3.hasNext()) {
         request = (BleRequest)var3.next();
         request.cancel();
      }

      this.mBleWorkList.removeAll(requestClear);
   }

   private boolean isRequestMatch(BleRequest request, int requestType) {
      if ((requestType & 1) != 0) {
         return request instanceof BleReadRequest;
      } else if ((requestType & 2) != 0) {
         return request instanceof BleWriteRequest || request instanceof BleWriteNoRspRequest;
      } else if ((requestType & 4) == 0) {
         return (requestType & 8) != 0 ? request instanceof BleReadRssiRequest : false;
      } else {
         return request instanceof BleNotifyRequest || request instanceof BleUnnotifyRequest || request instanceof BleIndicateRequest;
      }
   }

   public void read(UUID service, UUID character, BleGeneralResponse response) {
      this.addNewRequest(new BleReadRequest(service, character, response));
   }

   public void write(UUID service, UUID character, byte[] bytes, BleGeneralResponse response) {
      this.addNewRequest(new BleWriteRequest(service, character, bytes, response));
   }

   public void writeNoRsp(UUID service, UUID character, byte[] bytes, BleGeneralResponse response) {
      this.addNewRequest(new BleWriteNoRspRequest(service, character, bytes, response));
   }

   public void readDescriptor(UUID service, UUID character, UUID descriptor, BleGeneralResponse response) {
      this.addNewRequest(new BleReadDescriptorRequest(service, character, descriptor, response));
   }

   public void writeDescriptor(UUID service, UUID character, UUID descriptor, byte[] bytes, BleGeneralResponse response) {
      this.addNewRequest(new BleWriteDescriptorRequest(service, character, descriptor, bytes, response));
   }

   public void notify(UUID service, UUID character, BleGeneralResponse response) {
      this.addNewRequest(new BleNotifyRequest(service, character, response));
   }

   public void unnotify(UUID service, UUID character, BleGeneralResponse response) {
      this.addNewRequest(new BleUnnotifyRequest(service, character, response));
   }

   public void indicate(UUID service, UUID character, BleGeneralResponse response) {
      this.addNewRequest(new BleIndicateRequest(service, character, response));
   }

   public void unindicate(UUID service, UUID character, BleGeneralResponse response) {
      this.addNewRequest(new BleUnnotifyRequest(service, character, response));
   }

   public void readRemoteRssi(BleGeneralResponse response) {
      this.addNewRequest(new BleReadRssiRequest(response));
   }

   private void addNewRequest(BleRequest request) {
      this.checkRuntime();
      if (this.mBleWorkList.size() < 100) {
         request.setRuntimeChecker(this);
         request.setAddress(this.mAddress);
         request.setWorker(this.mWorker);
         this.mBleWorkList.add(request);
      } else {
         request.onResponse(-8);
      }

      this.scheduleNextRequest(10L);
   }

   public void onRequestCompleted(BleRequest request) {
      this.checkRuntime();
      if (request != this.mCurrentRequest) {
         throw new IllegalStateException("request not match");
      } else {
         this.mCurrentRequest = null;
         this.scheduleNextRequest(10L);
      }
   }

   private void scheduleNextRequest(long delayInMillis) {
      this.mHandler.sendEmptyMessageDelayed(18, delayInMillis);
   }

   private void scheduleNextRequest() {
      if (this.mCurrentRequest == null) {
         if (!ListUtils.isEmpty(this.mBleWorkList)) {
            this.mCurrentRequest = (BleRequest)this.mBleWorkList.remove(0);
            this.mCurrentRequest.process(this);
         }

      }
   }

   public void checkRuntime() {
      if (Thread.currentThread() != this.mHandler.getLooper().getThread()) {
         throw new IllegalStateException("Thread Context Illegal");
      }
   }

   public boolean handleMessage(Message msg) {
      switch(msg.what) {
      case 18:
         this.scheduleNextRequest();
      default:
         return true;
      }
   }
}
