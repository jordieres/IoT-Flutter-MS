package com.inuker.bluetooth.library;

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
import java.util.UUID;

public interface IBluetoothClient {
   void connect(String var1, BleConnectOptions var2, BleConnectResponse var3);

   void disconnect(String var1);

   void registerConnectStatusListener(String var1, BleConnectStatusListener var2);

   void unregisterConnectStatusListener(String var1, BleConnectStatusListener var2);

   void read(String var1, UUID var2, UUID var3, BleReadResponse var4);

   void write(String var1, UUID var2, UUID var3, byte[] var4, BleWriteResponse var5);

   void readDescriptor(String var1, UUID var2, UUID var3, UUID var4, BleReadResponse var5);

   void writeDescriptor(String var1, UUID var2, UUID var3, UUID var4, byte[] var5, BleWriteResponse var6);

   void writeNoRsp(String var1, UUID var2, UUID var3, byte[] var4, BleWriteResponse var5);

   void notify(String var1, UUID var2, UUID var3, BleNotifyResponse var4);

   void unnotify(String var1, UUID var2, UUID var3, BleUnnotifyResponse var4);

   void indicate(String var1, UUID var2, UUID var3, BleNotifyResponse var4);

   void unindicate(String var1, UUID var2, UUID var3, BleUnnotifyResponse var4);

   void readRssi(String var1, BleReadRssiResponse var2);

   void search(SearchRequest var1, SearchResponse var2);

   void stopSearch();

   void registerBluetoothStateListener(BluetoothStateListener var1);

   void unregisterBluetoothStateListener(BluetoothStateListener var1);

   void registerBluetoothBondListener(BluetoothBondListener var1);

   void unregisterBluetoothBondListener(BluetoothBondListener var1);

   void clearRequest(String var1, int var2);
}
