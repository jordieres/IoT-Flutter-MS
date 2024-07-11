package com.inuker.bluetooth.library.connect.listener;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;

public interface IBluetoothGattResponse {
   void onConnectionStateChange(int var1, int var2);

   void onServicesDiscovered(int var1);

   void onCharacteristicRead(BluetoothGattCharacteristic var1, int var2, byte[] var3);

   void onCharacteristicWrite(BluetoothGattCharacteristic var1, int var2, byte[] var3);

   void onCharacteristicChanged(BluetoothGattCharacteristic var1, byte[] var2);

   void onDescriptorRead(BluetoothGattDescriptor var1, int var2, byte[] var3);

   void onDescriptorWrite(BluetoothGattDescriptor var1, int var2);

   void onReadRemoteRssi(int var1, int var2);
}
