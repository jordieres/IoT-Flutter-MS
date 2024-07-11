package com.inuker.bluetooth.library.connect.request;

import com.inuker.bluetooth.library.connect.listener.ReadRssiListener;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;

public class BleReadRssiRequest extends BleRequest implements ReadRssiListener {
   public BleReadRssiRequest(BleGeneralResponse response) {
      super(response);
   }

   public void processRequest() {
      switch(this.getCurrentStatus()) {
      case 0:
         this.onRequestCompleted(-1);
         break;
      case 2:
         this.startReadRssi();
         break;
      case 19:
         this.startReadRssi();
         break;
      default:
         this.onRequestCompleted(-1);
      }

   }

   private void startReadRssi() {
      if (!this.readRemoteRssi()) {
         this.onRequestCompleted(-1);
      } else {
         this.startRequestTiming();
      }

   }

   public void onReadRemoteRssi(int rssi, int status) {
      this.stopRequestTiming();
      if (status == 0) {
         this.putIntExtra("extra.rssi", rssi);
         this.onRequestCompleted(0);
      } else {
         this.onRequestCompleted(-1);
      }

   }
}
