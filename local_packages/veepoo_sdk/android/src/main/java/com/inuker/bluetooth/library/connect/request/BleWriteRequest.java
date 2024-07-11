package com.inuker.bluetooth.library.connect.request;

import android.bluetooth.BluetoothGattCharacteristic;
import com.inuker.bluetooth.library.connect.listener.WriteCharacterListener;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import java.util.UUID;

public class BleWriteRequest extends BleRequest implements WriteCharacterListener {
   private UUID mServiceUUID;
   private UUID mCharacterUUID;
   private byte[] mBytes;

   public BleWriteRequest(UUID service, UUID character, byte[] bytes, BleGeneralResponse response) {
      super(response);
      this.mServiceUUID = service;
      this.mCharacterUUID = character;
      this.mBytes = bytes;
   }

   public void processRequest() {
      switch(this.getCurrentStatus()) {
      case 0:
         this.onRequestCompleted(-1);
         break;
      case 2:
         this.startWrite();
         break;
      case 19:
         this.startWrite();
         break;
      default:
         this.onRequestCompleted(-1);
      }

   }

   private void startWrite() {
      if (!this.writeCharacteristic(this.mServiceUUID, this.mCharacterUUID, this.mBytes)) {
         this.onRequestCompleted(-1);
      } else {
         this.startRequestTiming();
      }

   }

   public void onCharacteristicWrite(BluetoothGattCharacteristic characteristic, int status, byte[] value) {
      this.stopRequestTiming();
      if (status == 0) {
         this.onRequestCompleted(0);
      } else {
         this.onRequestCompleted(-1);
      }

   }
}
