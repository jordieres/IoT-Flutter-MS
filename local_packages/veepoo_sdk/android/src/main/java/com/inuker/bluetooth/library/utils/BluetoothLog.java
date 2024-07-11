package com.inuker.bluetooth.library.utils;

import android.util.Log;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;

public class BluetoothLog {
   private static final String LOG_TAG = "veepoo-bluetooth";
   public static boolean isDebug = true;

   public static void setDebug(boolean isdebug) {
      isDebug = isdebug;
   }

   public static void i(String msg) {
      if (isDebug) {
         Log.i("veepoo-bluetooth", msg);
      }

   }

   public static void e(String msg) {
      if (isDebug) {
         Log.e("veepoo-bluetooth", msg);
      }

   }

   public static void v(String msg) {
      if (isDebug) {
         Log.v("veepoo-bluetooth", msg);
      }

   }

   public static void d(String msg) {
      if (isDebug) {
         Log.d("veepoo-bluetooth", msg);
      }

   }

   public static void w(String msg) {
      if (isDebug) {
         Log.w("veepoo-bluetooth", msg);
      }

   }

   public static void e(Throwable e) {
      if (isDebug) {
         e(getThrowableString(e));
      }

   }

   public static void w(Throwable e) {
      if (isDebug) {
         w(getThrowableString(e));
      }

   }

   private static String getThrowableString(Throwable e) {
      Writer writer = new StringWriter();

      PrintWriter printWriter;
      for(printWriter = new PrintWriter(writer); e != null; e = e.getCause()) {
         e.printStackTrace(printWriter);
      }

      String text = writer.toString();
      printWriter.close();
      return text;
   }
}
