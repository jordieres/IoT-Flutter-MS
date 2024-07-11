package com.inuker.bluetooth.library.connect.listener;

import android.bluetooth.BluetoothGattDescriptor;

public interface ReadDescriptorListener extends GattResponseListener {
   void onDescriptorRead(BluetoothGattDescriptor var1, int var2, byte[] var3);
}
