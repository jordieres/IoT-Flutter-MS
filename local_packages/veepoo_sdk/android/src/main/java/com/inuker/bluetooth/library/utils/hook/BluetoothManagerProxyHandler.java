package com.inuker.bluetooth.library.utils.hook;

import android.os.IBinder;
import android.os.IInterface;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import com.inuker.bluetooth.library.utils.hook.utils.HookUtils;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

public class BluetoothManagerProxyHandler implements InvocationHandler {
   private Object iBluetoothManager;
   private Class<?> bluetoothGattClaz;
   private Object bluetoothGatt;

   BluetoothManagerProxyHandler(Object iBluetoothManager) {
      this.iBluetoothManager = iBluetoothManager;
      this.bluetoothGattClaz = HookUtils.getClass("android.bluetooth.IBluetoothGatt");
      Class<?> stub = HookUtils.getClass("android.bluetooth.IBluetoothManager");
      Method method = HookUtils.getMethod(stub, "getBluetoothGatt");
      this.bluetoothGatt = HookUtils.invoke(method, iBluetoothManager);
   }

   public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
      BluetoothLog.v(String.format("IBluetoothManager method: %s", method.getName()));
      return "getBluetoothGatt".equals(method.getName()) ? Proxy.newProxyInstance(proxy.getClass().getClassLoader(), new Class[]{IBinder.class, IInterface.class, this.bluetoothGattClaz}, new BluetoothGattProxyHandler(this.bluetoothGatt)) : method.invoke(this.iBluetoothManager, args);
   }
}
