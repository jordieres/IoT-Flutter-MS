package com.inuker.bluetooth.library.connect;

import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Handler.Callback;
import com.inuker.bluetooth.library.connect.options.BleConnectOptions;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import com.inuker.bluetooth.library.utils.proxy.ProxyBulk;
import com.inuker.bluetooth.library.utils.proxy.ProxyInterceptor;
import com.inuker.bluetooth.library.utils.proxy.ProxyUtils;
import java.lang.reflect.Method;
import java.util.UUID;

public class BleConnectMaster implements IBleConnectMaster, ProxyInterceptor, Callback {
   private Handler mHandler;
   private String mAddress;
   private BleConnectDispatcher mBleConnectDispatcher;

   private BleConnectMaster(String mac, Looper looper) {
      this.mAddress = mac;
      this.mHandler = new Handler(looper, this);
   }

   private BleConnectDispatcher getConnectDispatcher() {
      if (this.mBleConnectDispatcher == null) {
         this.mBleConnectDispatcher = BleConnectDispatcher.newInstance(this.mAddress);
      }

      return this.mBleConnectDispatcher;
   }

   static IBleConnectMaster newInstance(String mac, Looper looper) {
      BleConnectMaster master = new BleConnectMaster(mac, looper);
      return (IBleConnectMaster)ProxyUtils.getProxy(master, IBleConnectMaster.class, master);
   }

   public void connect(BleConnectOptions options, BleGeneralResponse response) {
      this.getConnectDispatcher().connect(options, response);
   }

   public void disconnect() {
      this.getConnectDispatcher().disconnect();
   }

   public void read(UUID service, UUID character, BleGeneralResponse response) {
      this.getConnectDispatcher().read(service, character, response);
   }

   public void write(UUID service, UUID character, byte[] bytes, BleGeneralResponse response) {
      this.getConnectDispatcher().write(service, character, bytes, response);
   }

   public void writeNoRsp(UUID service, UUID character, byte[] bytes, BleGeneralResponse response) {
      this.getConnectDispatcher().writeNoRsp(service, character, bytes, response);
   }

   public void readDescriptor(UUID service, UUID character, UUID descriptor, BleGeneralResponse response) {
      this.getConnectDispatcher().readDescriptor(service, character, descriptor, response);
   }

   public void writeDescriptor(UUID service, UUID character, UUID descriptor, byte[] value, BleGeneralResponse response) {
      this.getConnectDispatcher().writeDescriptor(service, character, descriptor, value, response);
   }

   public void notify(UUID service, UUID character, BleGeneralResponse response) {
      this.getConnectDispatcher().notify(service, character, response);
   }

   public void unnotify(UUID service, UUID character, BleGeneralResponse response) {
      this.getConnectDispatcher().unnotify(service, character, response);
   }

   public void readRssi(BleGeneralResponse response) {
      this.getConnectDispatcher().readRemoteRssi(response);
   }

   public void indicate(UUID service, UUID character, BleGeneralResponse response) {
      this.getConnectDispatcher().indicate(service, character, response);
   }

   public void clearRequest(int clearType) {
      this.getConnectDispatcher().clearRequest(clearType);
   }

   public boolean onIntercept(Object object, Method method, Object[] args) {
      this.mHandler.obtainMessage(0, new ProxyBulk(object, method, args)).sendToTarget();
      return true;
   }

   public boolean handleMessage(Message msg) {
      ProxyBulk.safeInvoke(msg.obj);
      return true;
   }
}
