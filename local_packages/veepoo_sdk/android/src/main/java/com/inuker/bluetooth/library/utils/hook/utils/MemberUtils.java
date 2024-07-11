package com.inuker.bluetooth.library.utils.hook.utils;

import java.lang.reflect.Member;
import java.lang.reflect.Modifier;

public class MemberUtils {
   static boolean isAccessible(Member m) {
      return m != null && Modifier.isPublic(m.getModifiers()) && !m.isSynthetic();
   }
}
