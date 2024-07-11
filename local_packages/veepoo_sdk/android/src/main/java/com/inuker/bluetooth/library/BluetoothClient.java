package com.inuker.bluetooth.library;

import android.content.Context;
import com.inuker.bluetooth.library.connect.listener.BleConnectStatusListener;
import com.inuker.bluetooth.library.connect.listener.BluetoothStateListener;
import com.inuker.bluetooth.library.connect.options.BleConnectOptions;
import com.inuker.bluetooth.library.connect.response.BleConnectResponse;
import com.inuker.bluetooth.library.connect.response.BleNotifyResponse;
import com.inuker.bluetooth.library.connect.response.BleReadResponse;
import com.inuker.bluetooth.library.connect.response.BleReadRssiResponse;
import com.inuker.bluetooth.library.connect.response.BleUnnotifyResponse;
import com.inuker.bluetooth.library.connect.response.BleWriteResponse;
import com.inuker.bluetooth.library.receiver.listener.BluetoothBondListener;
import com.inuker.bluetooth.library.search.SearchRequest;
import com.inuker.bluetooth.library.search.response.SearchResponse;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import com.inuker.bluetooth.library.utils.BluetoothUtils;
import com.inuker.bluetooth.library.utils.ByteUtils;
import com.inuker.bluetooth.library.utils.proxy.ProxyUtils;
import java.util.UUID;

public class BluetoothClient implements IBluetoothClient {
   private IBluetoothClient mClient;

   public BluetoothClient(Context context) {
      if (context == null) {
         throw new NullPointerException("Context null");
      } else {
         this.mClient = BluetoothClientImpl.getInstance(context);
      }
   }

   public void connect(String mac, BleConnectResponse response) {
      this.connect(mac, (BleConnectOptions)null, response);
   }

   public void connect(String mac, BleConnectOptions options, BleConnectResponse response) {
      BluetoothLog.v(String.format("connect %s", mac));
      response = (BleConnectResponse)ProxyUtils.getUIProxy(response);
      this.mClient.connect(mac, options, response);
   }

   public void disconnect(String mac) {
      BluetoothLog.v(String.format("disconnect %s", mac));
      this.mClient.disconnect(mac);
   }

   public void read(String mac, UUID service, UUID character, BleReadResponse response) {
      BluetoothLog.v(String.format("read character for %s: service = %s, character = %s", mac, service, character));
      response = (BleReadResponse)ProxyUtils.getUIProxy(response);
      this.mClient.read(mac, service, character, response);
   }

   public void write(String mac, UUID service, UUID character, byte[] value, BleWriteResponse response) {
      BluetoothLog.v(String.format("write character for %s: service = %s, character = %s, value = %s", mac, service, character, ByteUtils.byteToString(value)));
      response = (BleWriteResponse)ProxyUtils.getUIProxy(response);
      this.mClient.write(mac, service, character, value, response);
   }

   public void readDescriptor(String mac, UUID service, UUID character, UUID descriptor, BleReadResponse response) {
      BluetoothLog.v(String.format("readDescriptor for %s: service = %s, character = %s", mac, service, character));
      response = (BleReadResponse)ProxyUtils.getUIProxy(response);
      this.mClient.readDescriptor(mac, service, character, descriptor, response);
   }

   public void writeDescriptor(String mac, UUID service, UUID character, UUID descriptor, byte[] value, BleWriteResponse response) {
      BluetoothLog.v(String.format("writeDescriptor for %s: service = %s, character = %s", mac, service, character));
      response = (BleWriteResponse)ProxyUtils.getUIProxy(response);
      this.mClient.writeDescriptor(mac, service, character, descriptor, value, response);
   }

   public void writeNoRsp(String mac, UUID service, UUID character, byte[] value, BleWriteResponse response) {
      BluetoothLog.v(String.format("writeNoRsp %s: service = %s, character = %s, value = %s", mac, service, character, ByteUtils.byteToString(value)));
      response = (BleWriteResponse)ProxyUtils.getUIProxy(response);
      this.mClient.writeNoRsp(mac, service, character, value, response);
   }

   public void notify(String mac, UUID service, UUID character, BleNotifyResponse response) {
      BluetoothLog.v(String.format("notify %s: service = %s, character = %s", mac, service, character));
      response = (BleNotifyResponse)ProxyUtils.getUIProxy(response);
      this.mClient.notify(mac, service, character, response);
   }

   public void unnotify(String mac, UUID service, UUID character, BleUnnotifyResponse response) {
      BluetoothLog.v(String.format("unnotify %s: service = %s, character = %s", mac, service, character));
      response = (BleUnnotifyResponse)ProxyUtils.getUIProxy(response);
      this.mClient.unnotify(mac, service, character, response);
   }

   public void indicate(String mac, UUID service, UUID character, BleNotifyResponse response) {
      BluetoothLog.v(String.format("indicate %s: service = %s, character = %s", mac, service, character));
      response = (BleNotifyResponse)ProxyUtils.getUIProxy(response);
      this.mClient.indicate(mac, service, character, response);
   }

   public void unindicate(String mac, UUID service, UUID character, BleUnnotifyResponse response) {
      BluetoothLog.v(String.format("indicate %s: service = %s, character = %s", mac, service, character));
      response = (BleUnnotifyResponse)ProxyUtils.getUIProxy(response);
      this.unindicate(mac, service, character, response);
   }

   public void readRssi(String mac, BleReadRssiResponse response) {
      BluetoothLog.v(String.format("readRssi %s", mac));
      response = (BleReadRssiResponse)ProxyUtils.getUIProxy(response);
      this.mClient.readRssi(mac, response);
   }

   public void search(SearchRequest request, SearchResponse response) {
      BluetoothLog.v(String.format("search %s", request));
      response = (SearchResponse)ProxyUtils.getUIProxy(response);
      this.mClient.search(request, response);
   }

   public void stopSearch() {
      BluetoothLog.v(String.format("stopSearch"));
      this.mClient.stopSearch();
   }

   public void registerConnectStatusListener(String mac, BleConnectStatusListener listener) {
      this.mClient.registerConnectStatusListener(mac, listener);
   }

   public void unregisterConnectStatusListener(String mac, BleConnectStatusListener listener) {
      this.mClient.unregisterConnectStatusListener(mac, listener);
   }

   public void registerBluetoothStateListener(BluetoothStateListener listener) {
      this.mClient.registerBluetoothStateListener(listener);
   }

   public void unregisterBluetoothStateListener(BluetoothStateListener listener) {
      this.mClient.unregisterBluetoothStateListener(listener);
   }

   public void registerBluetoothBondListener(BluetoothBondListener listener) {
      this.mClient.registerBluetoothBondListener(listener);
   }

   public void unregisterBluetoothBondListener(BluetoothBondListener listener) {
      this.mClient.unregisterBluetoothBondListener(listener);
   }

   public int getConnectStatus(String mac) {
      return BluetoothUtils.getConnectStatus(mac);
   }

   public boolean isBluetoothOpened() {
      return BluetoothUtils.isBluetoothEnabled();
   }

   public boolean openBluetooth() {
      return BluetoothUtils.openBluetooth();
   }

   public boolean closeBluetooth() {
      return BluetoothUtils.closeBluetooth();
   }

   public boolean isBleSupported() {
      return BluetoothUtils.isBleSupported();
   }

   public void clearRequest(String mac, int type) {
      this.mClient.clearRequest(mac, type);
   }
}
