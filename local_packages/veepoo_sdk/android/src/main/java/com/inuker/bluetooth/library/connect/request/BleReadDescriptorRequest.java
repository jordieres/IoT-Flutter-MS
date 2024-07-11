package com.inuker.bluetooth.library.connect.request;

import android.bluetooth.BluetoothGattDescriptor;
import com.inuker.bluetooth.library.connect.listener.ReadDescriptorListener;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import java.util.UUID;

public class BleReadDescriptorRequest extends BleRequest implements ReadDescriptorListener {
   private UUID mServiceUUID;
   private UUID mCharacterUUID;
   private UUID mDescriptorUUID;

   public BleReadDescriptorRequest(UUID service, UUID character, UUID descriptor, BleGeneralResponse response) {
      super(response);
      this.mServiceUUID = service;
      this.mCharacterUUID = character;
      this.mDescriptorUUID = descriptor;
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
      if (!this.readDescriptor(this.mServiceUUID, this.mCharacterUUID, this.mDescriptorUUID)) {
         this.onRequestCompleted(-1);
      } else {
         this.startRequestTiming();
      }

   }

   public void onDescriptorRead(BluetoothGattDescriptor descriptor, int status, byte[] value) {
      this.stopRequestTiming();
      if (status == 0) {
         this.putByteArray("extra.byte.value", value);
         this.onRequestCompleted(0);
      } else {
         this.onRequestCompleted(-1);
      }

   }
}
