package com.inuker.bluetooth.library;

public class Code {
   public static final int REQUEST_SUCCESS = 0;
   public static final int REQUEST_FAILED = -1;
   public static final int REQUEST_CANCELED = -2;
   public static final int ILLEGAL_ARGUMENT = -3;
   public static final int BLE_NOT_SUPPORTED = -4;
   public static final int BLUETOOTH_DISABLED = -5;
   public static final int SERVICE_UNREADY = -6;
   public static final int REQUEST_TIMEDOUT = -7;
   public static final int REQUEST_OVERFLOW = -8;
   public static final int REQUEST_DENIED = -9;
   public static final int REQUEST_EXCEPTION = -10;
   public static final int REQUEST_UNKNOWN = -11;

   public static String toString(int code) {
      switch(code) {
      case -9:
         return "REQUEST_DENIED";
      case -8:
      case -2:
      default:
         return "unknown code: " + code;
      case -7:
         return "REQUEST_TIMEDOUT";
      case -6:
         return "SERVICE_UNREADY";
      case -5:
         return "BLUETOOTH_DISABLED";
      case -4:
         return "BLE_NOT_SUPPORTED";
      case -3:
         return "ILLEGAL_ARGUMENT";
      case -1:
         return "REQUEST_FAILED";
      case 0:
         return "REQUEST_SUCCESS";
      }
   }
}
