package com.inuker.bluetooth.library.connect.request;

import android.bluetooth.BluetoothGattDescriptor;
import com.inuker.bluetooth.library.connect.listener.WriteDescriptorListener;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import java.util.UUID;

public class BleWriteDescriptorRequest extends BleRequest implements WriteDescriptorListener {
   private UUID mServiceUUID;
   private UUID mCharacterUUID;
   private UUID mDescriptorUUID;
   private byte[] mBytes;

   public BleWriteDescriptorRequest(UUID service, UUID character, UUID descriptor, byte[] bytes, BleGeneralResponse response) {
      super(response);
      this.mServiceUUID = service;
      this.mCharacterUUID = character;
      this.mDescriptorUUID = descriptor;
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
      if (!this.writeDescriptor(this.mServiceUUID, this.mCharacterUUID, this.mDescriptorUUID, this.mBytes)) {
         this.onRequestCompleted(-1);
      } else {
         this.startRequestTiming();
      }

   }

   public void onDescriptorWrite(BluetoothGattDescriptor descriptor, int status) {
      this.stopRequestTiming();
      if (status == 0) {
         this.onRequestCompleted(0);
      } else {
         this.onRequestCompleted(-1);
      }

   }
}
