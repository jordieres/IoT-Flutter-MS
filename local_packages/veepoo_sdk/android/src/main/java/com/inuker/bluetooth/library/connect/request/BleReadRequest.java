package com.inuker.bluetooth.library.connect.request;

import android.bluetooth.BluetoothGattCharacteristic;
import com.inuker.bluetooth.library.connect.listener.ReadCharacterListener;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import java.util.UUID;

public class BleReadRequest extends BleRequest implements ReadCharacterListener {
   private UUID mServiceUUID;
   private UUID mCharacterUUID;

   public BleReadRequest(UUID service, UUID character, BleGeneralResponse response) {
      super(response);
      this.mServiceUUID = service;
      this.mCharacterUUID = character;
   }

   public void processRequest() {
      switch(this.getCurrentStatus()) {
      case 0:
         this.onRequestCompleted(-1);
         break;
      case 2:
         this.startRead();
         break;
      case 19:
         this.startRead();
         break;
      default:
         this.onRequestCompleted(-1);
      }

   }

   private void startRead() {
      if (!this.readCharacteristic(this.mServiceUUID, this.mCharacterUUID)) {
         this.onRequestCompleted(-1);
      } else {
         this.startRequestTiming();
      }

   }

   public void onCharacteristicRead(BluetoothGattCharacteristic characteristic, int status, byte[] value) {
      this.stopRequestTiming();
      if (status == 0) {
         this.putByteArray("extra.byte.value", value);
         this.onRequestCompleted(0);
      } else {
         this.onRequestCompleted(-1);
      }

   }
}
