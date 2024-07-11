package com.inuker.bluetooth.library.connect.response;

import java.util.UUID;

public interface BleNotifyResponse extends BleResponse {
   void onNotify(UUID var1, UUID var2, byte[] var3);
}
