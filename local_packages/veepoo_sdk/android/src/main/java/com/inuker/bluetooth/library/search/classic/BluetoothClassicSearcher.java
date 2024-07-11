package com.inuker.bluetooth.library.search.classic;

import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import com.inuker.bluetooth.library.search.BluetoothSearcher;
import com.inuker.bluetooth.library.search.SearchResult;
import com.inuker.bluetooth.library.search.response.BluetoothSearchResponse;
import com.inuker.bluetooth.library.utils.BluetoothUtils;

public class BluetoothClassicSearcher extends BluetoothSearcher {
   private BluetoothSearchReceiver mReceiver;

   private BluetoothClassicSearcher() {
      this.mBluetoothAdapter = BluetoothUtils.getBluetoothAdapter();
   }

   public static BluetoothClassicSearcher getInstance() {
      return BluetoothClassicSearcherHolder.instance;
   }

   public void startScanBluetooth(BluetoothSearchResponse callback) {
      super.startScanBluetooth(callback);
      this.registerReceiver();
      if (this.mBluetoothAdapter.isDiscovering()) {
         this.mBluetoothAdapter.cancelDiscovery();
      }

      this.mBluetoothAdapter.startDiscovery();
   }

   public void stopScanBluetooth() {
      this.unregisterReceiver();
      if (this.mBluetoothAdapter.isDiscovering()) {
         this.mBluetoothAdapter.cancelDiscovery();
      }

      super.stopScanBluetooth();
   }

   protected void cancelScanBluetooth() {
      this.unregisterReceiver();
      if (this.mBluetoothAdapter.isDiscovering()) {
         this.mBluetoothAdapter.cancelDiscovery();
      }

      super.cancelScanBluetooth();
   }

   private void registerReceiver() {
      if (this.mReceiver == null) {
         this.mReceiver = new BluetoothSearchReceiver();
         BluetoothUtils.registerReceiver(this.mReceiver, new IntentFilter("android.bluetooth.device.action.FOUND"));
      }

   }

   private void unregisterReceiver() {
      if (this.mReceiver != null) {
         BluetoothUtils.unregisterReceiver(this.mReceiver);
         this.mReceiver = null;
      }

   }

   // $FF: synthetic method
   BluetoothClassicSearcher(Object x0) {
      this();
   }

   private class BluetoothSearchReceiver extends BroadcastReceiver {
      private BluetoothSearchReceiver() {
      }

      public void onReceive(Context context, Intent intent) {
         if (intent.getAction().equals("android.bluetooth.device.action.FOUND")) {
            BluetoothDevice device = (BluetoothDevice)intent.getParcelableExtra("android.bluetooth.device.extra.DEVICE");
            int rssi = intent.getShortExtra("android.bluetooth.device.extra.RSSI", (short)-32768);
            SearchResult xmDevice = new SearchResult(device, rssi, (byte[])null);
            BluetoothClassicSearcher.this.notifyDeviceFounded(xmDevice);
         }

      }

      // $FF: synthetic method
      BluetoothSearchReceiver(Object x1) {
         this();
      }
   }

   private static class BluetoothClassicSearcherHolder {
      private static BluetoothClassicSearcher instance = new BluetoothClassicSearcher();
   }
}
