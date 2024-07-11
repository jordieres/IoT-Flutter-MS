package com.inuker.bluetooth.library.search;

import android.bluetooth.BluetoothAdapter;
import com.inuker.bluetooth.library.search.classic.BluetoothClassicSearcher;
import com.inuker.bluetooth.library.search.le.BluetoothLESearcher;
import com.inuker.bluetooth.library.search.response.BluetoothSearchResponse;

public class BluetoothSearcher {
   protected BluetoothAdapter mBluetoothAdapter;
   protected BluetoothSearchResponse mSearchResponse;

   public static BluetoothSearcher newInstance(int type) {
      switch(type) {
      case 1:
         return BluetoothClassicSearcher.getInstance();
      case 2:
         return BluetoothLESearcher.getInstance();
      default:
         throw new IllegalStateException(String.format("unknown search type %d", type));
      }
   }

   protected void startScanBluetooth(BluetoothSearchResponse callback) {
      this.mSearchResponse = callback;
      this.notifySearchStarted();
   }

   protected void stopScanBluetooth() {
      this.notifySearchStopped();
      this.mSearchResponse = null;
   }

   protected void cancelScanBluetooth() {
      this.notifySearchCanceled();
      this.mSearchResponse = null;
   }

   private void notifySearchStarted() {
      if (this.mSearchResponse != null) {
         this.mSearchResponse.onSearchStarted();
      }

   }

   protected void notifyDeviceFounded(SearchResult device) {
      if (this.mSearchResponse != null) {
         this.mSearchResponse.onDeviceFounded(device);
      }

   }

   private void notifySearchStopped() {
      if (this.mSearchResponse != null) {
         this.mSearchResponse.onSearchStopped();
      }

   }

   private void notifySearchCanceled() {
      if (this.mSearchResponse != null) {
         this.mSearchResponse.onSearchCanceled();
      }

   }
}
