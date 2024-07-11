package com.inuker.bluetooth.library.utils;

import android.os.Build.VERSION;

public class Version {
   public static boolean isMarshmallow() {
      return VERSION.SDK_INT >= 23;
   }
}
