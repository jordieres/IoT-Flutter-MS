package com.inuker.bluetooth.library.utils;

public class StringUtils {
   public static boolean isNotBlank(CharSequence cs) {
      return !isBlank(cs);
   }

   public static boolean isBlank(CharSequence cs) {
      int strLen;
      if (cs != null && (strLen = cs.length()) != 0) {
         for(int i = 0; i < strLen; ++i) {
            if (!Character.isWhitespace(cs.charAt(i))) {
               return false;
            }
         }

         return true;
      } else {
         return true;
      }
   }
}
