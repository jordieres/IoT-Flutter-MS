package com.inuker.bluetooth.library.utils.proxy;

import java.lang.reflect.Method;

public interface ProxyInterceptor {
   boolean onIntercept(Object var1, Method var2, Object[] var3);
}
