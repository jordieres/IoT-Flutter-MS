package com.inuker.bluetooth.library.connect.listener;

public interface ReadRssiListener extends GattResponseListener {
   void onReadRemoteRssi(int var1, int var2);
}
