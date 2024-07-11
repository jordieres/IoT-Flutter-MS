package com.inuker.bluetooth.library.utils.hook;

import com.inuker.bluetooth.library.utils.BluetoothLog;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;

public class BluetoothGattProxyHandler implements InvocationHandler {
   private Object bluetoothGatt;

   BluetoothGattProxyHandler(Object bluetoothGatt) {
      this.bluetoothGatt = bluetoothGatt;
   }

   public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
      BluetoothLog.v(String.format("IBluetoothGatt method: %s", method.getName()));
      return method.invoke(this.bluetoothGatt, args);
   }
}
