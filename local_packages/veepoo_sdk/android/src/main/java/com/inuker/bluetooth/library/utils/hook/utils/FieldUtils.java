package com.inuker.bluetooth.library.utils.hook.utils;

import com.inuker.bluetooth.library.utils.StringUtils;
import java.lang.reflect.Field;

public class FieldUtils {
   public static Field getDeclaredField(Class<?> cls, String fieldName, boolean forceAccess) {
      Validate.isTrue(cls != null, "The class must not be null");
      Validate.isTrue(StringUtils.isNotBlank(fieldName), "The field name must not be blank/empty");

      try {
         Field field = cls.getDeclaredField(fieldName);
         if (!MemberUtils.isAccessible(field)) {
            if (!forceAccess) {
               return null;
            }

            field.setAccessible(true);
         }

         return field;
      } catch (NoSuchFieldException var4) {
         return null;
      }
   }
}
