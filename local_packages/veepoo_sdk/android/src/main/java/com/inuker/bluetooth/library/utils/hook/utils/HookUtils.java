package com.inuker.bluetooth.library.utils.hook.utils;

import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

public class HookUtils {
   public static Class<?> getClass(String name) {
      try {
         return Class.forName(name);
      } catch (ClassNotFoundException var2) {
         var2.printStackTrace();
         return null;
      }
   }

   public static Method getMethod(Class<?> clazz, String name, Class<?>... parameterTypes) {
      return MethodUtils.getAccessibleMethod(clazz, name, parameterTypes);
   }

   public static Field getField(Class<?> clazz, String name) {
      return clazz != null ? FieldUtils.getDeclaredField(clazz, name, true) : null;
   }

   public static <T> T getValue(Field field) {
      return getValue(field, (Object)null);
   }

   public static <T> T getValue(Field field, Object object) {
      try {
         if (field != null) {
            return (T) field.get(object);
         }
      } catch (IllegalAccessException var3) {
         var3.printStackTrace();
      }

      return null;
   }

   public static <T> T invoke(Method method, Object object, Object... parameters) {
      try {
         return (T) method.invoke(object, parameters);
      } catch (IllegalAccessException var4) {
         var4.printStackTrace();
      } catch (InvocationTargetException var5) {
         var5.printStackTrace();
      }

      return null;
   }
}
