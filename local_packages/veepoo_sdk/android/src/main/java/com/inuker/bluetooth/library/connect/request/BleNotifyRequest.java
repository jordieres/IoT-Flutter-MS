package com.inuker.bluetooth.library.connect.request;

import android.bluetooth.BluetoothGattDescriptor;
import com.inuker.bluetooth.library.connect.listener.WriteDescriptorListener;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import java.util.UUID;

public class BleNotifyRequest extends BleRequest implements WriteDescriptorListener {
   private UUID mServiceUUID;
   private UUID mCharacterUUID;

   public BleNotifyRequest(UUID service, UUID character, BleGeneralResponse response) {
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
         this.openNotify();
         break;
      case 19:
         this.openNotify();
         break;
      default:
         this.onRequestCompleted(-1);
      }

   }

   private void openNotify() {
      if (!this.setCharacteristicNotification(this.mServiceUUID, this.mCharacterUUID, true)) {
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
