package com.inuker.bluetooth.library.utils.hook.compat;

import android.os.IBinder;
import com.inuker.bluetooth.library.utils.hook.utils.HookUtils;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.HashMap;

public class ServiceManagerCompat {
   private static Class<?> serviceManager = HookUtils.getClass("android.os.ServiceManager");
   private static Field sCache;
   private static Method getService;

   public static Class<?> getServiceManager() {
      return serviceManager;
   }

   public static Field getCacheField() {
      return sCache;
   }

   public static HashMap<String, IBinder> getCacheValue() {
      return (HashMap)HookUtils.getValue(sCache);
   }

   public static Method getService() {
      return getService;
   }

   static {
      sCache = HookUtils.getField(serviceManager, "sCache");
      sCache.setAccessible(true);
      getService = HookUtils.getMethod(serviceManager, "getService", String.class);
   }
}
