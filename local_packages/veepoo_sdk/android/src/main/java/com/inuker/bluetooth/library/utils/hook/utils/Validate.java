package com.inuker.bluetooth.library.utils.hook.utils;

public class Validate {
   public static void isTrue(boolean expression, String message, Object... values) {
      if (!expression) {
         throw new IllegalArgumentException(String.format(message, values));
      }
   }
}
