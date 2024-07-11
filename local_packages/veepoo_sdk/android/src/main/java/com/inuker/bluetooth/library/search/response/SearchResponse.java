package com.inuker.bluetooth.library.search.response;

import com.inuker.bluetooth.library.search.SearchResult;

public interface SearchResponse {
   void onSearchStarted();

   void onDeviceFounded(SearchResult var1);

   void onSearchStopped();

   void onSearchCanceled();
}
