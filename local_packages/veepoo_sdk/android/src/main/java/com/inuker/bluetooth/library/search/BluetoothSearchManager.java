package com.inuker.bluetooth.library.search;

import android.os.Bundle;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import com.inuker.bluetooth.library.search.response.BluetoothSearchResponse;

public class BluetoothSearchManager {
   public static void search(SearchRequest request, final BleGeneralResponse response) {
      BluetoothSearchRequest requestWrapper = new BluetoothSearchRequest(request);
      BluetoothSearchHelper.getInstance().startSearch(requestWrapper, new BluetoothSearchResponse() {
         public void onSearchStarted() {
            response.onResponse(1, (Bundle) null);
         }

         public void onDeviceFounded(SearchResult device) {
            Bundle bundle = new Bundle();
            bundle.putParcelable("extra.search.result", device);
            response.onResponse(4, bundle);
         }

         public void onSearchStopped() {
            response.onResponse(2, (Bundle)null);
         }

         public void onSearchCanceled() {
            response.onResponse(3, (Bundle)null);
         }
      });
   }

   public static void stopSearch() {
      BluetoothSearchHelper.getInstance().stopSearch();
   }
}
