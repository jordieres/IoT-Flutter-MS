package com.inuker.bluetooth.library.connect;

import com.inuker.bluetooth.library.IBluetoothBase;
import com.inuker.bluetooth.library.connect.listener.GattResponseListener;
import com.inuker.bluetooth.library.model.BleGattProfile;
import java.util.UUID;

public interface IBleRequestProcessor extends IBluetoothBase {
   int STATUS_DEVICE_CONNECTED = 2;
   int STATUS_DEVICE_DISCONNECTED = 0;
   int STATUS_DEVICE_SERVICE_READY = 19;

   void registerGattResponseListener(int var1, GattResponseListener var2);

   void unregisterGattResponseListener(int var1);

   void notifyRequestResult();

   int getConnectStatus();

   BleGattProfile getGattProfile();

   boolean openBluetoothGatt();

   void disconnect();

   void closeBluetoothGatt();

   boolean readCharacteristic(UUID var1, UUID var2);

   boolean writeCharacteristic(UUID var1, UUID var2, byte[] var3);

   boolean writeCharacteristicWithNoRsp(UUID var1, UUID var2, byte[] var3);

   boolean setCharacteristicNotification(UUID var1, UUID var2, boolean var3);

   boolean readRemoteRssi();

   void refreshCache();
}
