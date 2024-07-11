package com.inuker.bluetooth.library.utils.proxy;

import com.inuker.bluetooth.library.utils.BluetoothLog;
import java.lang.reflect.Method;

public class ProxyBulk {
   public Object object;
   public Method method;
   public Object[] args;

   public ProxyBulk(Object object, Method method, Object[] args) {
      this.object = object;
      this.method = method;
      this.args = args;
   }

   public Object safeInvoke() {
      Object result = null;

      try {
         result = this.method.invoke(this.object, this.args);
      } catch (Throwable var3) {
         BluetoothLog.e(var3);
      }

      return result;
   }

   public static Object safeInvoke(Object obj) {
      return ((ProxyBulk)obj).safeInvoke();
   }
}
