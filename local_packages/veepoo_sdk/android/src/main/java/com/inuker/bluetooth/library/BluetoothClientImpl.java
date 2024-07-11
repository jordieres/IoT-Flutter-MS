package com.inuker.bluetooth.library;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.IBinder;
import android.os.Looper;
import android.os.Message;
import android.os.Handler.Callback;
import com.inuker.bluetooth.library.connect.listener.BleConnectStatusListener;
import com.inuker.bluetooth.library.connect.listener.BluetoothStateListener;
import com.inuker.bluetooth.library.connect.options.BleConnectOptions;
import com.inuker.bluetooth.library.connect.response.BleConnectResponse;
import com.inuker.bluetooth.library.connect.response.BleNotifyResponse;
import com.inuker.bluetooth.library.connect.response.BleReadResponse;
import com.inuker.bluetooth.library.connect.response.BleReadRssiResponse;
import com.inuker.bluetooth.library.connect.response.BleUnnotifyResponse;
import com.inuker.bluetooth.library.connect.response.BleWriteResponse;
import com.inuker.bluetooth.library.connect.response.BluetoothResponse;
import com.inuker.bluetooth.library.model.BleGattProfile;
import com.inuker.bluetooth.library.receiver.BluetoothReceiver;
import com.inuker.bluetooth.library.receiver.listener.BleCharacterChangeListener;
import com.inuker.bluetooth.library.receiver.listener.BleConnectStatusChangeListener;
import com.inuker.bluetooth.library.receiver.listener.BluetoothBondListener;
import com.inuker.bluetooth.library.receiver.listener.BluetoothBondStateChangeListener;
import com.inuker.bluetooth.library.receiver.listener.BluetoothStateChangeListener;
import com.inuker.bluetooth.library.search.SearchRequest;
import com.inuker.bluetooth.library.search.SearchResult;
import com.inuker.bluetooth.library.search.response.SearchResponse;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import com.inuker.bluetooth.library.utils.ListUtils;
import com.inuker.bluetooth.library.utils.proxy.ProxyBulk;
import com.inuker.bluetooth.library.utils.proxy.ProxyInterceptor;
import com.inuker.bluetooth.library.utils.proxy.ProxyUtils;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;

public class BluetoothClientImpl implements IBluetoothClient, ProxyInterceptor, Callback {
   private static final int MSG_INVOKE_PROXY = 1;
   private static final int MSG_REG_RECEIVER = 2;
   private static final String TAG = BluetoothClientImpl.class.getSimpleName();
   private Context mContext;
   private IBluetoothService mBluetoothService;
   private static IBluetoothClient sInstance;
   private CountDownLatch mCountDownLatch;
   private HandlerThread mWorkerThread;
   private Handler mWorkerHandler;
   private HashMap<String, HashMap<String, List<BleNotifyResponse>>> mNotifyResponses;
   private HashMap<String, List<BleConnectStatusListener>> mConnectStatusListeners;
   private List<BluetoothStateListener> mBluetoothStateListeners;
   private List<BluetoothBondListener> mBluetoothBondListeners;
   private final ServiceConnection mConnection = new ServiceConnection() {
      public void onServiceConnected(ComponentName name, IBinder service) {
         BluetoothClientImpl.this.mBluetoothService = IBluetoothService.Stub.asInterface(service);
         BluetoothClientImpl.this.notifyBluetoothManagerReady();
      }

      public void onServiceDisconnected(ComponentName name) {
         BluetoothClientImpl.this.mBluetoothService = null;
      }
   };

   private BluetoothClientImpl(Context context) {
      this.mContext = context.getApplicationContext();
      BluetoothContext.set(this.mContext);
      this.mWorkerThread = new HandlerThread(TAG);
      this.mWorkerThread.start();
      this.mWorkerHandler = new Handler(this.mWorkerThread.getLooper(), this);
      this.mNotifyResponses = new HashMap();
      this.mConnectStatusListeners = new HashMap();
      this.mBluetoothStateListeners = new LinkedList();
      this.mBluetoothBondListeners = new LinkedList();
      this.mWorkerHandler.obtainMessage(2).sendToTarget();
   }

   public static IBluetoothClient getInstance(Context context) {
      if (sInstance == null) {
         Class var1 = BluetoothClientImpl.class;
         synchronized(BluetoothClientImpl.class) {
            if (sInstance == null) {
               BluetoothClientImpl client = new BluetoothClientImpl(context);
               sInstance = (IBluetoothClient)ProxyUtils.getProxy(client, IBluetoothClient.class, client);
            }
         }
      }

      return sInstance;
   }

   private IBluetoothService getBluetoothService() {
      if (this.mBluetoothService == null) {
         this.bindServiceSync();
      }

      return this.mBluetoothService;
   }

   private void bindServiceSync() {
      this.checkRuntime(true);
      this.mCountDownLatch = new CountDownLatch(1);
      Intent intent = new Intent();
      intent.setClass(this.mContext, BluetoothService.class);
      if (this.mContext.bindService(intent, this.mConnection, 1)) {
         BluetoothLog.v(String.format("BluetoothService registered"));
         this.waitBluetoothManagerReady();
      } else {
         BluetoothLog.v(String.format("BluetoothService not registered"));
         this.mBluetoothService = BluetoothServiceImpl.getInstance();
      }

   }

   public void connect(String mac, BleConnectOptions options, final BleConnectResponse response) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      args.putParcelable("extra.options", options);
      this.safeCallBluetoothApi(1, args, new BluetoothResponse() {
         protected void onAsyncResponse(int code, Bundle data) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (response != null) {
               data.setClassLoader(this.getClass().getClassLoader());
               BleGattProfile profile = (BleGattProfile)data.getParcelable("extra.gatt.profile");
               response.onResponse(code, profile);
            }

         }
      });
   }

   public void disconnect(String mac) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      this.safeCallBluetoothApi(2, args, (BluetoothResponse)null);
      this.clearNotifyListener(mac);
   }

   public void registerConnectStatusListener(String mac, BleConnectStatusListener listener) {
      this.checkRuntime(true);
      List<BleConnectStatusListener> listeners = (List)this.mConnectStatusListeners.get(mac);
      if (listeners == null) {
         listeners = new ArrayList();
         this.mConnectStatusListeners.put(mac, listeners);
      }

      if (listener != null && !((List)listeners).contains(listener)) {
         ((List)listeners).add(listener);
      }

   }

   public void unregisterConnectStatusListener(String mac, BleConnectStatusListener listener) {
      this.checkRuntime(true);
      List<BleConnectStatusListener> listeners = (List)this.mConnectStatusListeners.get(mac);
      if (listener != null && !ListUtils.isEmpty(listeners)) {
         listeners.remove(listener);
      }

   }

   public void read(String mac, UUID service, UUID character, final BleReadResponse response) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      args.putSerializable("extra.service.uuid", service);
      args.putSerializable("extra.character.uuid", character);
      this.safeCallBluetoothApi(3, args, new BluetoothResponse() {
         protected void onAsyncResponse(int code, Bundle data) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (response != null) {
               response.onResponse(code, data.getByteArray("extra.byte.value"));
            }

         }
      });
   }

   public void write(String mac, UUID service, UUID character, byte[] value, final BleWriteResponse response) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      args.putSerializable("extra.service.uuid", service);
      args.putSerializable("extra.character.uuid", character);
      args.putByteArray("extra.byte.value", value);
      this.safeCallBluetoothApi(4, args, new BluetoothResponse() {
         protected void onAsyncResponse(int code, Bundle data) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (response != null) {
               response.onResponse(code);
            }

         }
      });
   }

   public void readDescriptor(String mac, UUID service, UUID character, UUID descriptor, final BleReadResponse response) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      args.putSerializable("extra.service.uuid", service);
      args.putSerializable("extra.character.uuid", character);
      args.putSerializable("extra.descriptor.uuid", descriptor);
      this.safeCallBluetoothApi(13, args, new BluetoothResponse() {
         protected void onAsyncResponse(int code, Bundle data) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (response != null) {
               response.onResponse(code, data.getByteArray("extra.byte.value"));
            }

         }
      });
   }

   public void writeDescriptor(String mac, UUID service, UUID character, UUID descriptor, byte[] value, final BleWriteResponse response) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      args.putSerializable("extra.service.uuid", service);
      args.putSerializable("extra.character.uuid", character);
      args.putSerializable("extra.descriptor.uuid", descriptor);
      args.putByteArray("extra.byte.value", value);
      this.safeCallBluetoothApi(14, args, new BluetoothResponse() {
         protected void onAsyncResponse(int code, Bundle data) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (response != null) {
               response.onResponse(code);
            }

         }
      });
   }

   public void writeNoRsp(String mac, UUID service, UUID character, byte[] value, final BleWriteResponse response) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      args.putSerializable("extra.service.uuid", service);
      args.putSerializable("extra.character.uuid", character);
      args.putByteArray("extra.byte.value", value);
      this.safeCallBluetoothApi(5, args, new BluetoothResponse() {
         protected void onAsyncResponse(int code, Bundle data) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (response != null) {
               response.onResponse(code);
            }

         }
      });
   }

   private void saveNotifyListener(String mac, UUID service, UUID character, BleNotifyResponse response) {
      this.checkRuntime(true);
      HashMap<String, List<BleNotifyResponse>> listenerMap = (HashMap)this.mNotifyResponses.get(mac);
      if (listenerMap == null) {
         listenerMap = new HashMap();
         this.mNotifyResponses.put(mac, listenerMap);
      }

      String key = this.generateCharacterKey(service, character);
      List<BleNotifyResponse> responses = (List)listenerMap.get(key);
      if (responses == null) {
         responses = new ArrayList();
         listenerMap.put(key, responses);
      }

      ((List)responses).add(response);
   }

   private void removeNotifyListener(String mac, UUID service, UUID character) {
      this.checkRuntime(true);
      HashMap<String, List<BleNotifyResponse>> listenerMap = (HashMap)this.mNotifyResponses.get(mac);
      if (listenerMap != null) {
         String key = this.generateCharacterKey(service, character);
         listenerMap.remove(key);
      }

   }

   private void clearNotifyListener(String mac) {
      this.checkRuntime(true);
      this.mNotifyResponses.remove(mac);
   }

   private String generateCharacterKey(UUID service, UUID character) {
      return String.format("%s_%s", service, character);
   }

   public void notify(final String mac, final UUID service, final UUID character, final BleNotifyResponse response) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      args.putSerializable("extra.service.uuid", service);
      args.putSerializable("extra.character.uuid", character);
      this.safeCallBluetoothApi(6, args, new BluetoothResponse() {
         protected void onAsyncResponse(int code, Bundle data) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (response != null) {
               if (code == 0) {
                  BluetoothClientImpl.this.saveNotifyListener(mac, service, character, response);
               }

               response.onResponse(code);
            }

         }
      });
   }

   public void unnotify(final String mac, final UUID service, final UUID character, final BleUnnotifyResponse response) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      args.putSerializable("extra.service.uuid", service);
      args.putSerializable("extra.character.uuid", character);
      this.safeCallBluetoothApi(7, args, new BluetoothResponse() {
         protected void onAsyncResponse(int code, Bundle data) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (response != null) {
               response.onResponse(code);
            }

            if (code == 0) {
               BluetoothClientImpl.this.removeNotifyListener(mac, service, character);
            }

         }
      });
   }

   public void indicate(final String mac, final UUID service, final UUID character, final BleNotifyResponse response) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      args.putSerializable("extra.service.uuid", service);
      args.putSerializable("extra.character.uuid", character);
      this.safeCallBluetoothApi(10, args, new BluetoothResponse() {
         protected void onAsyncResponse(int code, Bundle data) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (response != null) {
               if (code == 0) {
                  BluetoothClientImpl.this.saveNotifyListener(mac, service, character, response);
               }

               response.onResponse(code);
            }

         }
      });
   }

   public void unindicate(String mac, UUID service, UUID character, BleUnnotifyResponse response) {
      this.unnotify(mac, service, character, response);
   }

   public void readRssi(String mac, final BleReadRssiResponse response) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      this.safeCallBluetoothApi(8, args, new BluetoothResponse() {
         protected void onAsyncResponse(int code, Bundle data) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (response != null) {
               response.onResponse(code, data.getInt("extra.rssi", 0));
            }

         }
      });
   }

   public void search(SearchRequest request, final SearchResponse response) {
      Bundle args = new Bundle();
      args.putParcelable("extra.request", request);
      this.safeCallBluetoothApi(11, args, new BluetoothResponse() {
         protected void onAsyncResponse(int code, Bundle data) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (response != null) {
               data.setClassLoader(this.getClass().getClassLoader());
               switch(code) {
               case 1:
                  response.onSearchStarted();
                  break;
               case 2:
                  response.onSearchStopped();
                  break;
               case 3:
                  response.onSearchCanceled();
                  break;
               case 4:
                  SearchResult device = (SearchResult)data.getParcelable("extra.search.result");
                  response.onDeviceFounded(device);
                  break;
               default:
                  throw new IllegalStateException("unknown code");
               }

            }
         }
      });
   }

   public void stopSearch() {
      this.safeCallBluetoothApi(12, (Bundle)null, (BluetoothResponse)null);
   }

   public void registerBluetoothStateListener(BluetoothStateListener listener) {
      this.checkRuntime(true);
      if (listener != null && !this.mBluetoothStateListeners.contains(listener)) {
         this.mBluetoothStateListeners.add(listener);
      }

   }

   public void unregisterBluetoothStateListener(BluetoothStateListener listener) {
      this.checkRuntime(true);
      if (listener != null) {
         this.mBluetoothStateListeners.remove(listener);
      }

   }

   public void registerBluetoothBondListener(BluetoothBondListener listener) {
      this.checkRuntime(true);
      if (listener != null && !this.mBluetoothBondListeners.contains(listener)) {
         this.mBluetoothBondListeners.add(listener);
      }

   }

   public void unregisterBluetoothBondListener(BluetoothBondListener listener) {
      this.checkRuntime(true);
      if (listener != null) {
         this.mBluetoothBondListeners.remove(listener);
      }

   }

   public void clearRequest(String mac, int type) {
      Bundle args = new Bundle();
      args.putString("extra.mac", mac);
      args.putInt("extra.type", type);
      this.safeCallBluetoothApi(20, args, (BluetoothResponse)null);
   }

   private void safeCallBluetoothApi(int code, Bundle args, BluetoothResponse response) {
      this.checkRuntime(true);

      try {
         IBluetoothService service = this.getBluetoothService();
         if (service != null) {
            args = args != null ? args : new Bundle();
            service.callBluetoothApi(code, args, response);
         } else {
            response.onResponse(-6, (Bundle)null);
         }
      } catch (Throwable var5) {
         BluetoothLog.e(var5);
      }

   }

   public boolean onIntercept(Object object, Method method, Object[] args) {
      this.mWorkerHandler.obtainMessage(1, new ProxyBulk(object, method, args)).sendToTarget();
      return true;
   }

   private void notifyBluetoothManagerReady() {
      if (this.mCountDownLatch != null) {
         this.mCountDownLatch.countDown();
         this.mCountDownLatch = null;
      }

   }

   private void waitBluetoothManagerReady() {
      try {
         this.mCountDownLatch.await();
      } catch (InterruptedException var2) {
         var2.printStackTrace();
      }

   }

   public boolean handleMessage(Message msg) {
      switch(msg.what) {
      case 1:
         ProxyBulk.safeInvoke(msg.obj);
         break;
      case 2:
         this.registerBluetoothReceiver();
      }

      return true;
   }

   private void registerBluetoothReceiver() {
      this.checkRuntime(true);
      BluetoothReceiver.getInstance().register(new BluetoothStateChangeListener() {
         protected void onBluetoothStateChanged(int prevState, int curState) {
            BluetoothClientImpl.this.checkRuntime(true);
            BluetoothClientImpl.this.dispatchBluetoothStateChanged(curState);
         }
      });
      BluetoothReceiver.getInstance().register(new BluetoothBondStateChangeListener() {
         protected void onBondStateChanged(String mac, int bondState) {
            BluetoothClientImpl.this.checkRuntime(true);
            BluetoothClientImpl.this.dispatchBondStateChanged(mac, bondState);
         }
      });
      BluetoothReceiver.getInstance().register(new BleConnectStatusChangeListener() {
         protected void onConnectStatusChanged(String mac, int status) {
            BluetoothClientImpl.this.checkRuntime(true);
            if (status == 32) {
               BluetoothClientImpl.this.clearNotifyListener(mac);
            }

            BluetoothClientImpl.this.dispatchConnectionStatus(mac, status);
         }
      });
      BluetoothReceiver.getInstance().register(new BleCharacterChangeListener() {
         public void onCharacterChanged(String mac, UUID service, UUID character, byte[] value) {
            BluetoothClientImpl.this.checkRuntime(true);
            BluetoothClientImpl.this.dispatchCharacterNotify(mac, service, character, value);
         }
      });
   }

   private void dispatchCharacterNotify(String mac, UUID service, UUID character, byte[] value) {
      this.checkRuntime(true);
      HashMap<String, List<BleNotifyResponse>> notifyMap = (HashMap)this.mNotifyResponses.get(mac);
      if (notifyMap != null) {
         String key = this.generateCharacterKey(service, character);
         List<BleNotifyResponse> responses = (List)notifyMap.get(key);
         if (responses != null) {
            Iterator var8 = responses.iterator();

            while(var8.hasNext()) {
               BleNotifyResponse response = (BleNotifyResponse)var8.next();
               response.onNotify(service, character, value);
            }
         }
      }

   }

   private void dispatchConnectionStatus(String mac, int status) {
      this.checkRuntime(true);
      List<BleConnectStatusListener> listeners = (List)this.mConnectStatusListeners.get(mac);
      if (!ListUtils.isEmpty(listeners)) {
         Iterator var4 = listeners.iterator();

         while(var4.hasNext()) {
            BleConnectStatusListener listener = (BleConnectStatusListener)var4.next();
            listener.invokeSync(new Object[]{mac, status});
         }
      }

   }

   private void dispatchBluetoothStateChanged(int currentState) {
      this.checkRuntime(true);
      if (currentState == 10 || currentState == 12) {
         Iterator var2 = this.mBluetoothStateListeners.iterator();

         while(var2.hasNext()) {
            BluetoothStateListener listener = (BluetoothStateListener)var2.next();
            listener.invokeSync(new Object[]{currentState == 12});
         }
      }

   }

   private void dispatchBondStateChanged(String mac, int bondState) {
      this.checkRuntime(true);
      Iterator var3 = this.mBluetoothBondListeners.iterator();

      while(var3.hasNext()) {
         BluetoothBondListener listener = (BluetoothBondListener)var3.next();
         listener.invokeSync(new Object[]{mac, bondState});
      }

   }

   private void checkRuntime(boolean async) {
      Looper targetLooper = async ? this.mWorkerHandler.getLooper() : Looper.getMainLooper();
      if (Looper.myLooper() != targetLooper) {
         throw new RuntimeException();
      }
   }
}
