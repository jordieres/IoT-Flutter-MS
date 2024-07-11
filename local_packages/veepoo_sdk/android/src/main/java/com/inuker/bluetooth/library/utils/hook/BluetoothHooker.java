package com.inuker.bluetooth.library.utils.hook;

import android.os.IBinder;
import com.inuker.bluetooth.library.utils.hook.compat.ServiceManagerCompat;
import com.inuker.bluetooth.library.utils.hook.utils.HookUtils;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.HashMap;

public class BluetoothHooker {
   private static final String BLUETOOTH_MANAGER = "bluetooth_manager";

   public static void hook() {
      Method getService = ServiceManagerCompat.getService();
      IBinder iBinder = (IBinder)HookUtils.invoke(getService, (Object)null, "bluetooth_manager");
      IBinder proxy = (IBinder)Proxy.newProxyInstance(iBinder.getClass().getClassLoader(), new Class[]{IBinder.class}, new BluetoothManagerBinderProxyHandler(iBinder));
      HashMap<String, IBinder> cache = ServiceManagerCompat.getCacheValue();
      cache.put("bluetooth_manager", proxy);
   }
}
