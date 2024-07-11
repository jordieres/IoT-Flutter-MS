package com.inuker.bluetooth.library.search.le;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothAdapter.LeScanCallback;
import com.inuker.bluetooth.library.search.BluetoothSearcher;
import com.inuker.bluetooth.library.search.SearchResult;
import com.inuker.bluetooth.library.search.response.BluetoothSearchResponse;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import com.inuker.bluetooth.library.utils.BluetoothUtils;

public class BluetoothLESearcher extends BluetoothSearcher {
   private final LeScanCallback mLeScanCallback;

   private BluetoothLESearcher() {
      this.mLeScanCallback = new LeScanCallback() {
         public void onLeScan(BluetoothDevice device, int rssi, byte[] scanRecord) {
            BluetoothLESearcher.this.notifyDeviceFounded(new SearchResult(device, rssi, scanRecord));
         }
      };
      this.mBluetoothAdapter = BluetoothUtils.getBluetoothAdapter();
   }

   public static BluetoothLESearcher getInstance() {
      return BluetoothLESearcherHolder.instance;
   }

   @TargetApi(18)
   public void startScanBluetooth(BluetoothSearchResponse response) {
      super.startScanBluetooth(response);
      this.mBluetoothAdapter.startLeScan(this.mLeScanCallback);
   }

   @TargetApi(18)
   public void stopScanBluetooth() {
      try {
         this.mBluetoothAdapter.stopLeScan(this.mLeScanCallback);
      } catch (Exception var2) {
         BluetoothLog.e((Throwable)var2);
      }

      super.stopScanBluetooth();
   }

   @TargetApi(18)
   protected void cancelScanBluetooth() {
      this.mBluetoothAdapter.stopLeScan(this.mLeScanCallback);
      super.cancelScanBluetooth();
   }

   // $FF: synthetic method
   BluetoothLESearcher(Object x0) {
      this();
   }

   private static class BluetoothLESearcherHolder {
      private static BluetoothLESearcher instance = new BluetoothLESearcher();
   }
}
