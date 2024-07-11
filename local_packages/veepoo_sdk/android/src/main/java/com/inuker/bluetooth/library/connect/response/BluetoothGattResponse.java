package com.inuker.bluetooth.library.connect.response;

import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import com.inuker.bluetooth.library.connect.listener.IBluetoothGattResponse;

public class BluetoothGattResponse extends BluetoothGattCallback {
   private IBluetoothGattResponse response;

   public BluetoothGattResponse(IBluetoothGattResponse response) {
      this.response = response;
   }

   public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
      this.response.onConnectionStateChange(status, newState);
   }

   public void onServicesDiscovered(BluetoothGatt gatt, int status) {
      this.response.onServicesDiscovered(status);
   }

   public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
      this.response.onCharacteristicRead(characteristic, status, characteristic.getValue());
   }

   public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
      this.response.onCharacteristicWrite(characteristic, status, characteristic.getValue());
   }

   public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
      this.response.onCharacteristicChanged(characteristic, characteristic.getValue());
   }

   public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
      this.response.onDescriptorWrite(descriptor, status);
   }

   public void onDescriptorRead(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
      this.response.onDescriptorRead(descriptor, status, descriptor.getValue());
   }

   public void onReadRemoteRssi(BluetoothGatt gatt, int rssi, int status) {
      this.response.onReadRemoteRssi(rssi, status);
   }
}
