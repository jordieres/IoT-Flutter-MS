package com.inuker.bluetooth.library.connect.request;

import android.bluetooth.BluetoothGattDescriptor;
import com.inuker.bluetooth.library.connect.listener.WriteDescriptorListener;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import java.util.UUID;

public class BleIndicateRequest extends BleRequest implements WriteDescriptorListener {
   private UUID mServiceUUID;
   private UUID mCharacterUUID;

   public BleIndicateRequest(UUID service, UUID character, BleGeneralResponse response) {
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
         this.openIndicate();
         break;
      case 19:
         this.openIndicate();
         break;
      default:
         this.onRequestCompleted(-1);
      }

   }

   private void openIndicate() {
      if (!this.setCharacteristicIndication(this.mServiceUUID, this.mCharacterUUID, true)) {
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
