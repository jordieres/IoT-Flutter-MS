package com.inuker.bluetooth.library.utils.hook.utils;

import java.lang.reflect.Method;
import java.lang.reflect.Modifier;

public class MethodUtils {
   public static Method getAccessibleMethod(Class<?> cls, String methodName, Class<?>... parameterTypes) {
      try {
         return getAccessibleMethod(cls.getMethod(methodName, parameterTypes));
      } catch (NoSuchMethodException var4) {
         return null;
      }
   }

   public static Method getAccessibleMethod(Method method) {
      if (!MemberUtils.isAccessible(method)) {
         return null;
      } else {
         Class<?> cls = method.getDeclaringClass();
         if (Modifier.isPublic(cls.getModifiers())) {
            return method;
         } else {
            String methodName = method.getName();
            Class<?>[] parameterTypes = method.getParameterTypes();
            method = getAccessibleMethodFromInterfaceNest(cls, methodName, parameterTypes);
            if (method == null) {
               method = getAccessibleMethodFromSuperclass(cls, methodName, parameterTypes);
            }

            return method;
         }
      }
   }

   private static Method getAccessibleMethodFromSuperclass(Class<?> cls, String methodName, Class<?>... parameterTypes) {
      for(Class parentClass = cls.getSuperclass(); parentClass != null; parentClass = parentClass.getSuperclass()) {
         if (Modifier.isPublic(parentClass.getModifiers())) {
            try {
               return parentClass.getMethod(methodName, parameterTypes);
            } catch (NoSuchMethodException var5) {
               return null;
            }
         }
      }

      return null;
   }

   private static Method getAccessibleMethodFromInterfaceNest(Class<?> cls, String methodName, Class<?>... parameterTypes) {
      while(cls != null) {
         Class<?>[] interfaces = cls.getInterfaces();

         for(int i = 0; i < interfaces.length; ++i) {
            if (Modifier.isPublic(interfaces[i].getModifiers())) {
               try {
                  return interfaces[i].getDeclaredMethod(methodName, parameterTypes);
               } catch (NoSuchMethodException var6) {
                  Method method = getAccessibleMethodFromInterfaceNest(interfaces[i], methodName, parameterTypes);
                  if (method != null) {
                     return method;
                  }
               }
            }
         }

         cls = cls.getSuperclass();
      }

      return null;
   }
}
