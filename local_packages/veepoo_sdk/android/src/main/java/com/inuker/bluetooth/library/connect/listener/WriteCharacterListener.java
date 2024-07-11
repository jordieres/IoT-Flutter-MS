package com.inuker.bluetooth.library.connect.listener;

import android.bluetooth.BluetoothGattCharacteristic;

public interface WriteCharacterListener extends GattResponseListener {
   void onCharacteristicWrite(BluetoothGattCharacteristic var1, int var2, byte[] var3);
}
