package com.inuker.bluetooth.library.connect.listener;

import android.bluetooth.BluetoothGattCharacteristic;

public interface ReadCharacterListener extends GattResponseListener {
   void onCharacteristicRead(BluetoothGattCharacteristic var1, int var2, byte[] var3);
}
