package com.inuker.bluetooth.library.connect;

import com.inuker.bluetooth.library.connect.listener.GattResponseListener;
import com.inuker.bluetooth.library.model.BleGattProfile;
import java.util.UUID;

public interface IBleConnectWorker {
   boolean openGatt();

   void closeGatt();

   boolean discoverService();

   int getCurrentStatus();

   void registerGattResponseListener(GattResponseListener var1);

   void clearGattResponseListener(GattResponseListener var1);

   boolean refreshDeviceCache();

   boolean readCharacteristic(UUID var1, UUID var2);

   boolean writeCharacteristic(UUID var1, UUID var2, byte[] var3);

   boolean readDescriptor(UUID var1, UUID var2, UUID var3);

   boolean writeDescriptor(UUID var1, UUID var2, UUID var3, byte[] var4);

   boolean writeCharacteristicWithNoRsp(UUID var1, UUID var2, byte[] var3);

   boolean setCharacteristicNotification(UUID var1, UUID var2, boolean var3);

   boolean setCharacteristicIndication(UUID var1, UUID var2, boolean var3);

   boolean readRemoteRssi();

   BleGattProfile getGattProfile();
}
