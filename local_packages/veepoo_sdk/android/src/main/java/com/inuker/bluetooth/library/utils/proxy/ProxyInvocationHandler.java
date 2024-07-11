package com.inuker.bluetooth.library.utils.proxy;

import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Handler.Callback;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import java.lang.ref.WeakReference;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;

public class ProxyInvocationHandler implements InvocationHandler, ProxyInterceptor, Callback {
   private Object subject;
   private ProxyInterceptor interceptor;
   private boolean weakRef;
   private boolean postUI;
   private Handler handler;

   public ProxyInvocationHandler(Object subject) {
      this(subject, (ProxyInterceptor)null);
   }

   public ProxyInvocationHandler(Object subject, ProxyInterceptor interceptor) {
      this(subject, interceptor, false);
   }

   public ProxyInvocationHandler(Object subject, ProxyInterceptor interceptor, boolean weakRef) {
      this(subject, interceptor, weakRef, false);
   }

   public ProxyInvocationHandler(Object subject, ProxyInterceptor interceptor, boolean weakRef, boolean postUI) {
      this.weakRef = weakRef;
      this.interceptor = interceptor;
      this.postUI = postUI;
      this.subject = this.getObject(subject);
      this.handler = new Handler(Looper.getMainLooper(), this);
   }

   public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
      Object subject = this.getObject();
      if (!this.onIntercept(subject, method, args)) {
         ProxyBulk bulk = new ProxyBulk(subject, method, args);
         return this.postUI ? this.postSafeInvoke(bulk) : this.safeInvoke(bulk);
      } else {
         return null;
      }
   }

   public boolean onIntercept(Object object, Method method, Object[] args) {
      if (this.interceptor != null) {
         try {
            return this.interceptor.onIntercept(object, method, args);
         } catch (Exception var5) {
            BluetoothLog.e((Throwable)var5);
         }
      }

      return false;
   }

   private Object getObject(Object object) {
      return this.weakRef ? new WeakReference(object) : object;
   }

   private Object getObject() {
      return this.weakRef ? ((WeakReference)this.subject).get() : this.subject;
   }

   private Object postSafeInvoke(ProxyBulk bulk) {
      this.handler.obtainMessage(0, bulk).sendToTarget();
      return null;
   }

   private Object safeInvoke(ProxyBulk bulk) {
      try {
         return bulk.safeInvoke();
      } catch (Throwable var3) {
         return null;
      }
   }

   public boolean handleMessage(Message msg) {
      ProxyBulk.safeInvoke(msg.obj);
      return true;
   }
}
