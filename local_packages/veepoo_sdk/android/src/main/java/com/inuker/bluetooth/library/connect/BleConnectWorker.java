package com.inuker.bluetooth.library.connect;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Handler.Callback;
import com.inuker.bluetooth.library.Constants;
import com.inuker.bluetooth.library.RuntimeChecker;
import com.inuker.bluetooth.library.connect.listener.GattResponseListener;
import com.inuker.bluetooth.library.connect.listener.IBluetoothGattResponse;
import com.inuker.bluetooth.library.connect.listener.ReadCharacterListener;
import com.inuker.bluetooth.library.connect.listener.ReadDescriptorListener;
import com.inuker.bluetooth.library.connect.listener.ReadRssiListener;
import com.inuker.bluetooth.library.connect.listener.ServiceDiscoverListener;
import com.inuker.bluetooth.library.connect.listener.WriteCharacterListener;
import com.inuker.bluetooth.library.connect.listener.WriteDescriptorListener;
import com.inuker.bluetooth.library.connect.response.BluetoothGattResponse;
import com.inuker.bluetooth.library.model.BleGattProfile;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import com.inuker.bluetooth.library.utils.BluetoothUtils;
import com.inuker.bluetooth.library.utils.ByteUtils;
import com.inuker.bluetooth.library.utils.Version;
import com.inuker.bluetooth.library.utils.proxy.ProxyBulk;
import com.inuker.bluetooth.library.utils.proxy.ProxyInterceptor;
import com.inuker.bluetooth.library.utils.proxy.ProxyUtils;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class BleConnectWorker implements Callback, IBleConnectWorker, IBluetoothGattResponse, ProxyInterceptor, RuntimeChecker {
   private static final int MSG_GATT_RESPONSE = 288;
   private BluetoothGatt mBluetoothGatt;
   private BluetoothDevice mBluetoothDevice;
   private GattResponseListener mGattResponseListener;
   private Handler mWorkerHandler;
   private volatile int mConnectStatus;
   private BleGattProfile mBleGattProfile;
   private Map<UUID, Map<UUID, BluetoothGattCharacteristic>> mDeviceProfile;
   private IBluetoothGattResponse mBluetoothGattResponse;
   private RuntimeChecker mRuntimeChecker;

   public BleConnectWorker(String mac, RuntimeChecker runtimeChecker) {
      BluetoothAdapter adapter = BluetoothUtils.getBluetoothAdapter();
      if (adapter != null) {
         this.mBluetoothDevice = adapter.getRemoteDevice(mac);
         this.mRuntimeChecker = runtimeChecker;
         this.mWorkerHandler = new Handler(Looper.myLooper(), this);
         this.mDeviceProfile = new HashMap();
         this.mBluetoothGattResponse = (IBluetoothGattResponse)ProxyUtils.getProxy(this, IBluetoothGattResponse.class, this);
      } else {
         throw new IllegalStateException("ble adapter null");
      }
   }

   private void refreshServiceProfile() {
      BluetoothLog.v(String.format("refreshServiceProfile for %s", this.mBluetoothDevice.getAddress()));
      List<BluetoothGattService> services = this.mBluetoothGatt.getServices();
      Map<UUID, Map<UUID, BluetoothGattCharacteristic>> newProfiles = new HashMap();
      Iterator var3 = services.iterator();

      while(var3.hasNext()) {
         BluetoothGattService service = (BluetoothGattService)var3.next();
         UUID serviceUUID = service.getUuid();
         Map<UUID, BluetoothGattCharacteristic> map = (Map)newProfiles.get(serviceUUID);
         if (map == null) {
            BluetoothLog.v("Service: " + serviceUUID);
            map = new HashMap();
            newProfiles.put(service.getUuid(), map);
         }

         List<BluetoothGattCharacteristic> characters = service.getCharacteristics();
         Iterator var8 = characters.iterator();

         while(var8.hasNext()) {
            BluetoothGattCharacteristic character = (BluetoothGattCharacteristic)var8.next();
            UUID characterUUID = character.getUuid();
            BluetoothLog.v("character: uuid = " + characterUUID);
            ((Map)map).put(character.getUuid(), character);
         }
      }

      this.mDeviceProfile.clear();
      this.mDeviceProfile.putAll(newProfiles);
      this.mBleGattProfile = new BleGattProfile(this.mDeviceProfile);
   }

   private BluetoothGattCharacteristic getCharacter(UUID service, UUID character) {
      BluetoothGattCharacteristic characteristic = null;
      if (service != null && character != null) {
         Map<UUID, BluetoothGattCharacteristic> characters = (Map)this.mDeviceProfile.get(service);
         if (characters != null) {
            characteristic = (BluetoothGattCharacteristic)characters.get(character);
         }
      }

      if (characteristic == null && this.mBluetoothGatt != null) {
         BluetoothGattService gattService = this.mBluetoothGatt.getService(service);
         if (gattService != null) {
            characteristic = gattService.getCharacteristic(character);
         }
      }

      return characteristic;
   }

   private void setConnectStatus(int status) {
      BluetoothLog.v(String.format("setConnectStatus status = %s", Constants.getStatusText(status)));
      this.mConnectStatus = status;
   }

   public void onConnectionStateChange(int status, int newState) {
      this.checkRuntime();
      BluetoothLog.v(String.format("onConnectionStateChange for %s: status = %d, newState = %d", this.mBluetoothDevice.getAddress(), status, newState));
      if (status == 0 && newState == 2) {
         this.setConnectStatus(2);
         if (this.mGattResponseListener != null) {
            this.mGattResponseListener.onConnectStatusChanged(true);
         }
      } else {
         this.closeGatt();
      }

   }

   public void onServicesDiscovered(int status) {
      this.checkRuntime();
      BluetoothLog.v(String.format("onServicesDiscovered for %s: status = %d", this.mBluetoothDevice.getAddress(), status));
      if (status == 0) {
         this.setConnectStatus(19);
         this.broadcastConnectStatus(16);
         this.refreshServiceProfile();
      }

      if (this.mGattResponseListener != null && this.mGattResponseListener instanceof ServiceDiscoverListener) {
         ((ServiceDiscoverListener)this.mGattResponseListener).onServicesDiscovered(status, this.mBleGattProfile);
      }

   }

   public void onCharacteristicRead(BluetoothGattCharacteristic characteristic, int status, byte[] value) {
      this.checkRuntime();
      BluetoothLog.v(String.format("onCharacteristicRead for %s: status = %d, service = 0x%s, character = 0x%s, value = %s", this.mBluetoothDevice.getAddress(), status, characteristic.getService().getUuid(), characteristic.getUuid(), ByteUtils.byteToString(value)));
      if (this.mGattResponseListener != null && this.mGattResponseListener instanceof ReadCharacterListener) {
         ((ReadCharacterListener)this.mGattResponseListener).onCharacteristicRead(characteristic, status, value);
      }

   }

   public void onCharacteristicWrite(BluetoothGattCharacteristic characteristic, int status, byte[] value) {
      this.checkRuntime();
      BluetoothLog.v(String.format("onCharacteristicWrite for %s: status = %d, service = 0x%s, character = 0x%s, value = %s", this.mBluetoothDevice.getAddress(), status, characteristic.getService().getUuid(), characteristic.getUuid(), ByteUtils.byteToString(value)));
      if (this.mGattResponseListener != null && this.mGattResponseListener instanceof WriteCharacterListener) {
         ((WriteCharacterListener)this.mGattResponseListener).onCharacteristicWrite(characteristic, status, value);
      }

   }

   public void onCharacteristicChanged(BluetoothGattCharacteristic characteristic, byte[] value) {
      this.checkRuntime();
      BluetoothLog.v(String.format("onCharacteristicChanged for %s: value = %s, service = 0x%s, character = 0x%s", this.mBluetoothDevice.getAddress(), ByteUtils.byteToString(value), characteristic.getService().getUuid(), characteristic.getUuid()));
      this.broadcastCharacterChanged(characteristic.getService().getUuid(), characteristic.getUuid(), value);
   }

   public void onDescriptorRead(BluetoothGattDescriptor descriptor, int status, byte[] value) {
      this.checkRuntime();
      BluetoothLog.v(String.format("onDescriptorRead for %s: status = %d, service = 0x%s, character = 0x%s, descriptor = 0x%s", this.mBluetoothDevice.getAddress(), status, descriptor.getCharacteristic().getService().getUuid(), descriptor.getCharacteristic().getUuid(), descriptor.getUuid()));
      if (this.mGattResponseListener != null && this.mGattResponseListener instanceof ReadDescriptorListener) {
         ((ReadDescriptorListener)this.mGattResponseListener).onDescriptorRead(descriptor, status, value);
      }

   }

   public void onDescriptorWrite(BluetoothGattDescriptor descriptor, int status) {
      this.checkRuntime();
      BluetoothLog.v(String.format("onDescriptorWrite for %s: status = %d, service = 0x%s, character = 0x%s, descriptor = 0x%s", this.mBluetoothDevice.getAddress(), status, descriptor.getCharacteristic().getService().getUuid(), descriptor.getCharacteristic().getUuid(), descriptor.getUuid()));
      if (this.mGattResponseListener != null && this.mGattResponseListener instanceof WriteDescriptorListener) {
         ((WriteDescriptorListener)this.mGattResponseListener).onDescriptorWrite(descriptor, status);
      }

   }

   public void onReadRemoteRssi(int rssi, int status) {
      this.checkRuntime();
      BluetoothLog.v(String.format("onReadRemoteRssi for %s, rssi = %d, status = %d", this.mBluetoothDevice.getAddress(), rssi, status));
      if (this.mGattResponseListener != null && this.mGattResponseListener instanceof ReadRssiListener) {
         ((ReadRssiListener)this.mGattResponseListener).onReadRemoteRssi(rssi, status);
      }

   }

   private void broadcastConnectStatus(int status) {
      Intent intent = new Intent("action.connect_status_changed");
      intent.putExtra("extra.mac", this.mBluetoothDevice.getAddress());
      intent.putExtra("extra.status", status);
      BluetoothUtils.sendBroadcast(intent);
   }

   private void broadcastCharacterChanged(UUID service, UUID character, byte[] value) {
      Intent intent = new Intent("action.character_changed");
      intent.putExtra("extra.mac", this.mBluetoothDevice.getAddress());
      intent.putExtra("extra.service.uuid", service);
      intent.putExtra("extra.character.uuid", character);
      intent.putExtra("extra.byte.value", value);
      BluetoothUtils.sendBroadcast(intent);
   }

   public boolean openGatt() {
      this.checkRuntime();
      BluetoothLog.v(String.format("openGatt for %s", this.getAddress()));
      if (this.mBluetoothGatt != null) {
         BluetoothLog.e(String.format("Previous gatt not closed"));
         return true;
      } else {
         Context context = BluetoothUtils.getContext();
         BluetoothGattCallback callback = new BluetoothGattResponse(this.mBluetoothGattResponse);
         if (Version.isMarshmallow()) {
            this.mBluetoothGatt = this.mBluetoothDevice.connectGatt(context, false, callback, 2);
         } else {
            this.mBluetoothGatt = this.mBluetoothDevice.connectGatt(context, false, callback);
         }

         if (this.mBluetoothGatt == null) {
            BluetoothLog.e(String.format("openGatt failed: connectGatt return null!"));
            return false;
         } else {
            return true;
         }
      }
   }

   private String getAddress() {
      return this.mBluetoothDevice.getAddress();
   }

   public void closeGatt() {
      this.checkRuntime();
      BluetoothLog.v(String.format("closeGatt for %s", this.getAddress()));
      if (this.mBluetoothGatt != null) {
         this.mBluetoothGatt.close();
         this.mBluetoothGatt = null;
      }

      if (this.mGattResponseListener != null) {
         this.mGattResponseListener.onConnectStatusChanged(false);
      }

      this.setConnectStatus(0);
      this.broadcastConnectStatus(32);
   }

   public boolean discoverService() {
      this.checkRuntime();
      BluetoothLog.v(String.format("discoverService for %s", this.getAddress()));
      if (this.mBluetoothGatt == null) {
         BluetoothLog.e(String.format("discoverService but gatt is null!"));
         return false;
      } else if (!this.mBluetoothGatt.discoverServices()) {
         BluetoothLog.e(String.format("discoverServices failed"));
         return false;
      } else {
         return true;
      }
   }

   public int getCurrentStatus() {
      this.checkRuntime();
      return this.mConnectStatus;
   }

   public void registerGattResponseListener(GattResponseListener listener) {
      this.checkRuntime();
      this.mGattResponseListener = listener;
   }

   public void clearGattResponseListener(GattResponseListener listener) {
      this.checkRuntime();
      if (this.mGattResponseListener == listener) {
         this.mGattResponseListener = null;
      }

   }

   public boolean refreshDeviceCache() {
      BluetoothLog.v(String.format("refreshDeviceCache for %s", this.getAddress()));
      this.checkRuntime();
      if (this.mBluetoothGatt == null) {
         BluetoothLog.e(String.format("ble gatt null"));
         return false;
      } else if (!this.refreshGattCache(this.mBluetoothGatt)) {
         BluetoothLog.e(String.format("refreshDeviceCache failed"));
         return false;
      } else {
         return true;
      }
   }

   private boolean refreshGattCache(BluetoothGatt gatt) {
      boolean result = false;

      try {
         if (gatt != null) {
            Method refresh = BluetoothGatt.class.getMethod("refresh");
            if (refresh != null) {
               refresh.setAccessible(true);
               result = (Boolean)refresh.invoke(gatt);
            }
         }
      } catch (Exception var4) {
         BluetoothLog.e((Throwable)var4);
      }

      BluetoothLog.v(String.format("refreshDeviceCache return %b", result));
      return result;
   }

   public boolean readCharacteristic(UUID service, UUID character) {
      BluetoothLog.v(String.format("readCharacteristic for %s: service = 0x%s, character = 0x%s", this.mBluetoothDevice.getAddress(), service, character));
      this.checkRuntime();
      BluetoothGattCharacteristic characteristic = this.getCharacter(service, character);
      if (characteristic == null) {
         BluetoothLog.e(String.format("characteristic not exist!"));
         return false;
      } else if (!this.isCharacteristicReadable(characteristic)) {
         BluetoothLog.e(String.format("characteristic not readable!"));
         return false;
      } else if (this.mBluetoothGatt == null) {
         BluetoothLog.e(String.format("ble gatt null"));
         return false;
      } else if (!this.mBluetoothGatt.readCharacteristic(characteristic)) {
         BluetoothLog.e(String.format("readCharacteristic failed"));
         return false;
      } else {
         return true;
      }
   }

   public boolean writeCharacteristic(UUID service, UUID character, byte[] value) {
      BluetoothLog.v(String.format("writeCharacteristic for %s: service = 0x%s, character = 0x%s, value = 0x%s", this.mBluetoothDevice.getAddress(), service, character, ByteUtils.byteToString(value)));
      this.checkRuntime();
      BluetoothGattCharacteristic characteristic = this.getCharacter(service, character);
      if (characteristic == null) {
         BluetoothLog.e(String.format("characteristic not exist!"));
         return false;
      } else if (!this.isCharacteristicWritable(characteristic)) {
         BluetoothLog.e(String.format("characteristic not writable!"));
         return false;
      } else if (this.mBluetoothGatt == null) {
         BluetoothLog.e(String.format("ble gatt null"));
         return false;
      } else {
         characteristic.setValue(value != null ? value : ByteUtils.EMPTY_BYTES);
         if (!this.mBluetoothGatt.writeCharacteristic(characteristic)) {
            BluetoothLog.e(String.format("writeCharacteristic failed"));
            return false;
         } else {
            return true;
         }
      }
   }

   public boolean readDescriptor(UUID service, UUID character, UUID descriptor) {
      BluetoothLog.v(String.format("readDescriptor for %s: service = 0x%s, character = 0x%s, descriptor = 0x%s", this.mBluetoothDevice.getAddress(), service, character, descriptor));
      this.checkRuntime();
      BluetoothGattCharacteristic characteristic = this.getCharacter(service, character);
      if (characteristic == null) {
         BluetoothLog.e(String.format("characteristic not exist!"));
         return false;
      } else {
         BluetoothGattDescriptor gattDescriptor = characteristic.getDescriptor(descriptor);
         if (gattDescriptor == null) {
            BluetoothLog.e(String.format("descriptor not exist"));
            return false;
         } else if (this.mBluetoothGatt == null) {
            BluetoothLog.e(String.format("ble gatt null"));
            return false;
         } else if (!this.mBluetoothGatt.readDescriptor(gattDescriptor)) {
            BluetoothLog.e(String.format("readDescriptor failed"));
            return false;
         } else {
            return true;
         }
      }
   }

   public boolean writeDescriptor(UUID service, UUID character, UUID descriptor, byte[] value) {
      BluetoothLog.v(String.format("writeDescriptor for %s: service = 0x%s, character = 0x%s, descriptor = 0x%s, value = 0x%s", this.mBluetoothDevice.getAddress(), service, character, descriptor, ByteUtils.byteToString(value)));
      this.checkRuntime();
      BluetoothGattCharacteristic characteristic = this.getCharacter(service, character);
      if (characteristic == null) {
         BluetoothLog.e(String.format("characteristic not exist!"));
         return false;
      } else {
         BluetoothGattDescriptor gattDescriptor = characteristic.getDescriptor(descriptor);
         if (gattDescriptor == null) {
            BluetoothLog.e(String.format("descriptor not exist"));
            return false;
         } else if (this.mBluetoothGatt == null) {
            BluetoothLog.e(String.format("ble gatt null"));
            return false;
         } else {
            gattDescriptor.setValue(value != null ? value : ByteUtils.EMPTY_BYTES);
            if (!this.mBluetoothGatt.writeDescriptor(gattDescriptor)) {
               BluetoothLog.e(String.format("writeDescriptor failed"));
               return false;
            } else {
               return true;
            }
         }
      }
   }

   public boolean writeCharacteristicWithNoRsp(UUID service, UUID character, byte[] value) {
      BluetoothLog.v(String.format("writeCharacteristicWithNoRsp for %s: service = 0x%s, character = 0x%s, value = 0x%s", this.mBluetoothDevice.getAddress(), service, character, ByteUtils.byteToString(value)));
      this.checkRuntime();
      BluetoothGattCharacteristic characteristic = this.getCharacter(service, character);
      if (characteristic == null) {
         BluetoothLog.e(String.format("characteristic not exist!"));
         return false;
      } else if (!this.isCharacteristicNoRspWritable(characteristic)) {
         BluetoothLog.e(String.format("characteristic not norsp writable!"));
         return false;
      } else if (this.mBluetoothGatt == null) {
         BluetoothLog.e(String.format("ble gatt null"));
         return false;
      } else {
         characteristic.setValue(value != null ? value : ByteUtils.EMPTY_BYTES);
         characteristic.setWriteType(1);
         if (!this.mBluetoothGatt.writeCharacteristic(characteristic)) {
            BluetoothLog.e(String.format("writeCharacteristic failed"));
            return false;
         } else {
            return true;
         }
      }
   }

   public boolean setCharacteristicNotification(UUID service, UUID character, boolean enable) {
      this.checkRuntime();
      BluetoothLog.v(String.format("setCharacteristicNotification for %s, service = %s, character = %s, enable = %b", this.getAddress(), service, character, enable));
      BluetoothGattCharacteristic characteristic = this.getCharacter(service, character);
      if (characteristic == null) {
         BluetoothLog.e(String.format("characteristic not exist!"));
         return false;
      } else if (!this.isCharacteristicNotifyable(characteristic)) {
         BluetoothLog.e(String.format("characteristic not notifyable!"));
         return false;
      } else if (this.mBluetoothGatt == null) {
         BluetoothLog.e(String.format("ble gatt null"));
         return false;
      } else if (!this.mBluetoothGatt.setCharacteristicNotification(characteristic, enable)) {
         BluetoothLog.e(String.format("setCharacteristicNotification failed"));
         return false;
      } else {
         BluetoothGattDescriptor descriptor = characteristic.getDescriptor(Constants.CLIENT_CHARACTERISTIC_CONFIG);
         if (descriptor == null) {
            BluetoothLog.e(String.format("getDescriptor for notify null!"));
            return false;
         } else {
            byte[] value = enable ? BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE : BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE;
            if (!descriptor.setValue(value)) {
               BluetoothLog.e(String.format("setValue for notify descriptor failed!"));
               return false;
            } else if (!this.mBluetoothGatt.writeDescriptor(descriptor)) {
               BluetoothLog.e(String.format("writeDescriptor for notify failed"));
               return false;
            } else {
               return true;
            }
         }
      }
   }

   public boolean setCharacteristicIndication(UUID service, UUID character, boolean enable) {
      this.checkRuntime();
      BluetoothLog.v(String.format("setCharacteristicIndication for %s, service = %s, character = %s, enable = %b", this.getAddress(), service, character, enable));
      BluetoothGattCharacteristic characteristic = this.getCharacter(service, character);
      if (characteristic == null) {
         BluetoothLog.e(String.format("characteristic not exist!"));
         return false;
      } else if (!this.isCharacteristicIndicatable(characteristic)) {
         BluetoothLog.e(String.format("characteristic not indicatable!"));
         return false;
      } else if (this.mBluetoothGatt == null) {
         BluetoothLog.e(String.format("ble gatt null"));
         return false;
      } else if (!this.mBluetoothGatt.setCharacteristicNotification(characteristic, enable)) {
         BluetoothLog.e(String.format("setCharacteristicIndication failed"));
         return false;
      } else {
         BluetoothGattDescriptor descriptor = characteristic.getDescriptor(Constants.CLIENT_CHARACTERISTIC_CONFIG);
         if (descriptor == null) {
            BluetoothLog.e(String.format("getDescriptor for indicate null!"));
            return false;
         } else {
            byte[] value = enable ? BluetoothGattDescriptor.ENABLE_INDICATION_VALUE : BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE;
            if (!descriptor.setValue(value)) {
               BluetoothLog.e(String.format("setValue for indicate descriptor failed!"));
               return false;
            } else if (!this.mBluetoothGatt.writeDescriptor(descriptor)) {
               BluetoothLog.e(String.format("writeDescriptor for indicate failed"));
               return false;
            } else {
               return true;
            }
         }
      }
   }

   public boolean readRemoteRssi() {
      this.checkRuntime();
      BluetoothLog.v(String.format("readRemoteRssi for %s", this.getAddress()));
      if (this.mBluetoothGatt == null) {
         BluetoothLog.e(String.format("ble gatt null"));
         return false;
      } else if (!this.mBluetoothGatt.readRemoteRssi()) {
         BluetoothLog.e(String.format("readRemoteRssi failed"));
         return false;
      } else {
         return true;
      }
   }

   public BleGattProfile getGattProfile() {
      return this.mBleGattProfile;
   }

   private boolean isCharacteristicReadable(BluetoothGattCharacteristic characteristic) {
      return characteristic != null && (characteristic.getProperties() & 2) != 0;
   }

   private boolean isCharacteristicWritable(BluetoothGattCharacteristic characteristic) {
      return characteristic != null && (characteristic.getProperties() & 8) != 0;
   }

   private boolean isCharacteristicNoRspWritable(BluetoothGattCharacteristic characteristic) {
      return characteristic != null && (characteristic.getProperties() & 4) != 0;
   }

   private boolean isCharacteristicNotifyable(BluetoothGattCharacteristic characteristic) {
      return characteristic != null && (characteristic.getProperties() & 16) != 0;
   }

   private boolean isCharacteristicIndicatable(BluetoothGattCharacteristic characteristic) {
      return characteristic != null && (characteristic.getProperties() & 32) != 0;
   }

   public boolean handleMessage(Message msg) {
      switch(msg.what) {
      case 288:
         ProxyBulk.safeInvoke(msg.obj);
      default:
         return true;
      }
   }

   public boolean onIntercept(Object object, Method method, Object[] args) {
      this.mWorkerHandler.obtainMessage(288, new ProxyBulk(object, method, args)).sendToTarget();
      return true;
   }

   public void checkRuntime() {
      this.mRuntimeChecker.checkRuntime();
   }
}
