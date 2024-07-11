package com.inuker.bluetooth.library.search;

import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Handler.Callback;
import com.inuker.bluetooth.library.search.response.BluetoothSearchResponse;

public class BluetoothSearchTask implements Callback {
   private static final int MSG_SEARCH_TIMEOUT = 34;
   private int searchType;
   private int searchDuration;
   private BluetoothSearcher mBluetoothSearcher;
   private Handler mHandler;

   public BluetoothSearchTask(SearchTask task) {
      this.setSearchType(task.getSearchType());
      this.setSearchDuration(task.getSearchDuration());
      this.mHandler = new Handler(Looper.myLooper(), this);
   }

   public void setSearchType(int searchType) {
      this.searchType = searchType;
   }

   public void setSearchDuration(int searchDuration) {
      this.searchDuration = searchDuration;
   }

   public boolean isBluetoothLeSearch() {
      return this.searchType == 2;
   }

   public boolean isBluetoothClassicSearch() {
      return this.searchType == 1;
   }

   private BluetoothSearcher getBluetoothSearcher() {
      if (this.mBluetoothSearcher == null) {
         this.mBluetoothSearcher = BluetoothSearcher.newInstance(this.searchType);
      }

      return this.mBluetoothSearcher;
   }

   public void start(BluetoothSearchResponse response) {
      this.getBluetoothSearcher().startScanBluetooth(response);
      this.mHandler.sendEmptyMessageDelayed(34, (long)this.searchDuration);
   }

   public void cancel() {
      this.mHandler.removeCallbacksAndMessages((Object)null);
      this.getBluetoothSearcher().cancelScanBluetooth();
   }

   public String toString() {
      String type = "";
      if (this.isBluetoothLeSearch()) {
         type = "Ble";
      } else if (this.isBluetoothClassicSearch()) {
         type = "classic";
      } else {
         type = "unknown";
      }

      return this.searchDuration >= 1000 ? String.format("%s search (%ds)", type, this.searchDuration / 1000) : String.format("%s search (%.1fs)", type, 1.0D * (double)this.searchDuration / 1000.0D);
   }

   public boolean handleMessage(Message msg) {
      switch(msg.what) {
      case 34:
         this.getBluetoothSearcher().stopScanBluetooth();
      default:
         return true;
      }
   }
}
