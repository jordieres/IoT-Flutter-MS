package com.inuker.bluetooth.library.connect.request;

import com.inuker.bluetooth.library.connect.IBleConnectDispatcher;

public interface IBleRequest {
   void process(IBleConnectDispatcher var1);

   void cancel();
}
