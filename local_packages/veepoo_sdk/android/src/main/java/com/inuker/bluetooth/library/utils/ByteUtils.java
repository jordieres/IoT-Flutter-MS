package com.inuker.bluetooth.library.utils;

import java.util.Arrays;

public class ByteUtils {
   public static final byte[] EMPTY_BYTES = new byte[0];
   public static final int BYTE_MAX = 255;

   public static byte[] getNonEmptyByte(byte[] bytes) {
      return bytes != null ? bytes : EMPTY_BYTES;
   }

   public static String byteToString(byte[] bytes) {
      StringBuilder sb = new StringBuilder();
      if (!isEmpty(bytes)) {
         for(int i = 0; i < bytes.length; ++i) {
            sb.append(String.format("%02X", bytes[i]));
         }
      }

      return sb.toString();
   }

   public static byte[] trimLast(byte[] bytes) {
      int i;
      for(i = bytes.length - 1; i >= 0 && bytes[i] == 0; --i) {
      }

      return Arrays.copyOfRange(bytes, 0, i + 1);
   }

   public static byte[] stringToBytes(String text) {
      int len = text.length();
      byte[] bytes = new byte[(len + 1) / 2];

      for(int i = 0; i < len; i += 2) {
         int size = Math.min(2, len - i);
         String sub = text.substring(i, i + size);
         bytes[i / 2] = (byte)Integer.parseInt(sub, 16);
      }

      return bytes;
   }

   public static boolean isEmpty(byte[] bytes) {
      return bytes == null || bytes.length == 0;
   }

   public static byte[] fromInt(int n) {
      byte[] bytes = new byte[4];

      for(int i = 0; i < 4; ++i) {
         bytes[i] = (byte)(n >>> i * 8);
      }

      return bytes;
   }

   public static boolean byteEquals(byte[] lbytes, byte[] rbytes) {
      if (lbytes == null && rbytes == null) {
         return true;
      } else if (lbytes != null && rbytes != null) {
         int llen = lbytes.length;
         int rlen = rbytes.length;
         if (llen != rlen) {
            return false;
         } else {
            for(int i = 0; i < llen; ++i) {
               if (lbytes[i] != rbytes[i]) {
                  return false;
               }
            }

            return true;
         }
      } else {
         return false;
      }
   }

   public static byte[] fillBeforeBytes(byte[] bytes, int len, byte fill) {
      byte[] result = bytes;
      int oldLen = bytes != null ? bytes.length : 0;
      if (oldLen < len) {
         result = new byte[len];
         int i = len - 1;

         for(int j = oldLen - 1; i >= 0; --j) {
            if (j >= 0) {
               result[i] = bytes[j];
            } else {
               result[i] = fill;
            }

            --i;
         }
      }

      return result;
   }

   public static byte[] cutBeforeBytes(byte[] bytes, byte cut) {
      if (isEmpty(bytes)) {
         return bytes;
      } else {
         for(int i = 0; i < bytes.length; ++i) {
            if (bytes[i] != cut) {
               return Arrays.copyOfRange(bytes, i, bytes.length);
            }
         }

         return EMPTY_BYTES;
      }
   }

   public static byte[] cutAfterBytes(byte[] bytes, byte cut) {
      if (isEmpty(bytes)) {
         return bytes;
      } else {
         for(int i = bytes.length - 1; i >= 0; --i) {
            if (bytes[i] != cut) {
               return Arrays.copyOfRange(bytes, 0, i + 1);
            }
         }

         return EMPTY_BYTES;
      }
   }

   public static byte[] getBytes(byte[] bytes, int start, int end) {
      if (bytes == null) {
         return null;
      } else if (start >= 0 && start < bytes.length) {
         if (end >= 0 && end < bytes.length) {
            if (start > end) {
               return null;
            } else {
               byte[] newBytes = new byte[end - start + 1];

               for(int i = start; i <= end; ++i) {
                  newBytes[i - start] = bytes[i];
               }

               return newBytes;
            }
         } else {
            return null;
         }
      } else {
         return null;
      }
   }

   public static int ubyteToInt(byte b) {
      return b & 255;
   }

   public static boolean isAllFF(byte[] bytes) {
      int len = bytes != null ? bytes.length : 0;

      for(int i = 0; i < len; ++i) {
         if (ubyteToInt(bytes[i]) != 255) {
            return false;
         }
      }

      return true;
   }

   public static byte[] fromLong(long n) {
      byte[] bytes = new byte[8];

      for(int i = 0; i < 8; ++i) {
         bytes[i] = (byte)((int)(n >>> i * 8));
      }

      return bytes;
   }

   public static void copy(byte[] lbytes, byte[] rbytes, int lstart, int rstart) {
      if (lbytes != null && rbytes != null && lstart >= 0) {
         int i = lstart;

         for(int j = rstart; j < rbytes.length && i < lbytes.length; ++j) {
            lbytes[i] = rbytes[j];
            ++i;
         }
      }

   }
}
