package com.inuker.bluetooth.library;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.RemoteException;
import android.os.Handler.Callback;
import com.inuker.bluetooth.library.connect.BleConnectManager;
import com.inuker.bluetooth.library.connect.options.BleConnectOptions;
import com.inuker.bluetooth.library.connect.response.BleGeneralResponse;
import com.inuker.bluetooth.library.search.BluetoothSearchManager;
import com.inuker.bluetooth.library.search.SearchRequest;
import java.util.UUID;

public class BluetoothServiceImpl extends IBluetoothService.Stub implements Callback {
   private static BluetoothServiceImpl sInstance;
   private Handler mHandler = new Handler(Looper.getMainLooper(), this);

   private BluetoothServiceImpl() {
   }

   public static BluetoothServiceImpl getInstance() {
      if (sInstance == null) {
         Class var0 = BluetoothServiceImpl.class;
         synchronized(BluetoothServiceImpl.class) {
            if (sInstance == null) {
               sInstance = new BluetoothServiceImpl();
            }
         }
      }

      return sInstance;
   }

   public void callBluetoothApi(int code, Bundle args, final IResponse response) throws RemoteException {
      Message msg = this.mHandler.obtainMessage(code, new BleGeneralResponse() {
         public void onResponse(int code, Bundle data) {
            if (response != null) {
               if (data == null) {
                  data = new Bundle();
               }

               try {
                  response.onResponse(code, data);
               } catch (RemoteException var4) {
                  var4.printStackTrace();
               }
            }

         }
      });
      args.setClassLoader(this.getClass().getClassLoader());
      msg.setData(args);
      msg.sendToTarget();
   }

   public boolean handleMessage(Message msg) {
      Bundle args = msg.getData();
      String mac = args.getString("extra.mac");
      UUID service = (UUID)args.getSerializable("extra.service.uuid");
      UUID character = (UUID)args.getSerializable("extra.character.uuid");
      UUID descriptor = (UUID)args.getSerializable("extra.descriptor.uuid");
      byte[] value = args.getByteArray("extra.byte.value");
      BleGeneralResponse response = (BleGeneralResponse)msg.obj;
      switch(msg.what) {
      case 1:
         BleConnectOptions options = (BleConnectOptions)args.getParcelable("extra.options");
         BleConnectManager.connect(mac, options, response);
         break;
      case 2:
         BleConnectManager.disconnect(mac);
         break;
      case 3:
         BleConnectManager.read(mac, service, character, response);
         break;
      case 4:
         BleConnectManager.write(mac, service, character, value, response);
         break;
      case 5:
         BleConnectManager.writeNoRsp(mac, service, character, value, response);
         break;
      case 6:
         BleConnectManager.notify(mac, service, character, response);
         break;
      case 7:
         BleConnectManager.unnotify(mac, service, character, response);
         break;
      case 8:
         BleConnectManager.readRssi(mac, response);
      case 9:
      case 15:
      case 16:
      case 17:
      case 18:
      case 19:
      default:
         break;
      case 10:
         BleConnectManager.indicate(mac, service, character, response);
         break;
      case 11:
         SearchRequest request = (SearchRequest)args.getParcelable("extra.request");
         BluetoothSearchManager.search(request, response);
         break;
      case 12:
         BluetoothSearchManager.stopSearch();
         break;
      case 13:
         BleConnectManager.readDescriptor(mac, service, character, descriptor, response);
         break;
      case 14:
         BleConnectManager.writeDescriptor(mac, service, character, descriptor, value, response);
         break;
      case 20:
         int clearType = args.getInt("extra.type", 0);
         BleConnectManager.clearRequest(mac, clearType);
      }

      return true;
   }
}
