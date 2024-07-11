package com.inuker.bluetooth.library.connect;

import com.inuker.bluetooth.library.connect.options.BleConnectOptions;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import java.util.UUID;

public interface IBleConnectMaster {
   void connect(BleConnectOptions var1, BleGeneralResponse var2);

   void disconnect();

   void read(UUID var1, UUID var2, BleGeneralResponse var3);

   void write(UUID var1, UUID var2, byte[] var3, BleGeneralResponse var4);

   void writeNoRsp(UUID var1, UUID var2, byte[] var3, BleGeneralResponse var4);

   void readDescriptor(UUID var1, UUID var2, UUID var3, BleGeneralResponse var4);

   void writeDescriptor(UUID var1, UUID var2, UUID var3, byte[] var4, BleGeneralResponse var5);

   void notify(UUID var1, UUID var2, BleGeneralResponse var3);

   void unnotify(UUID var1, UUID var2, BleGeneralResponse var3);

   void readRssi(BleGeneralResponse var1);

   void indicate(UUID var1, UUID var2, BleGeneralResponse var3);

   void clearRequest(int var1);
}
