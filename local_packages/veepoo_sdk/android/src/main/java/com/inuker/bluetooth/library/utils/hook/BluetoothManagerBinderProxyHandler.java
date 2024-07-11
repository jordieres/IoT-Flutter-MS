package com.inuker.bluetooth.library.utils.hook;

import android.os.IBinder;
import android.os.IInterface;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import com.inuker.bluetooth.library.utils.hook.utils.HookUtils;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

public class BluetoothManagerBinderProxyHandler implements InvocationHandler {
   private IBinder iBinder;
   private Class<?> iBluetoothManagerClaz;
   private Object iBluetoothManager;

   BluetoothManagerBinderProxyHandler(IBinder iBinder) {
      this.iBinder = iBinder;
      this.iBluetoothManagerClaz = HookUtils.getClass("android.bluetooth.IBluetoothManager");
      Class<?> stub = HookUtils.getClass("android.bluetooth.IBluetoothManager$Stub");
      Method asInterface = HookUtils.getMethod(stub, "asInterface", IBinder.class);
      this.iBluetoothManager = HookUtils.invoke(asInterface, (Object)null, iBinder);
   }

   public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
      BluetoothLog.v(String.format("IBinder method: %s", method.getName()));
      return "queryLocalInterface".equals(method.getName()) ? Proxy.newProxyInstance(proxy.getClass().getClassLoader(), new Class[]{IBinder.class, IInterface.class, this.iBluetoothManagerClaz}, new BluetoothManagerProxyHandler(this.iBluetoothManager)) : method.invoke(this.iBinder, args);
   }
}
