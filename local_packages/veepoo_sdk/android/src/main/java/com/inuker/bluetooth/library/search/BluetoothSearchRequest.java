package com.inuker.bluetooth.library.search;

import android.bluetooth.BluetoothDevice;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Handler.Callback;
import com.inuker.bluetooth.library.search.response.BluetoothSearchResponse;
import com.inuker.bluetooth.library.utils.BluetoothLog;
import com.inuker.bluetooth.library.utils.BluetoothUtils;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class BluetoothSearchRequest implements Callback {
   private static final int SCAN_INTERVAL = 100;
   private static final int MSG_START_SEARCH = 17;
   private static final int MSG_DEVICE_FOUND = 18;
   private List<BluetoothSearchTask> mSearchTaskList = new ArrayList();
   private BluetoothSearchResponse mSearchResponse;
   private BluetoothSearchTask mCurrentTask;
   private Handler mHandler;

   public BluetoothSearchRequest(SearchRequest request) {
      List<SearchTask> tasks = request.getTasks();
      Iterator var3 = tasks.iterator();

      while(var3.hasNext()) {
         SearchTask task = (SearchTask)var3.next();
         this.mSearchTaskList.add(new BluetoothSearchTask(task));
      }

      this.mHandler = new Handler(Looper.myLooper(), this);
   }

   public void setSearchResponse(BluetoothSearchResponse response) {
      this.mSearchResponse = response;
   }

   public void start() {
      if (this.mSearchResponse != null) {
         this.mSearchResponse.onSearchStarted();
      }

      this.notifyConnectedBluetoothDevices();
      this.mHandler.sendEmptyMessageDelayed(17, 100L);
   }

   public boolean handleMessage(Message msg) {
      switch(msg.what) {
      case 17:
         this.scheduleNewSearchTask();
         break;
      case 18:
         SearchResult device = (SearchResult)msg.obj;
         if (this.mSearchResponse != null) {
            this.mSearchResponse.onDeviceFounded(device);
         }
      }

      return true;
   }

   private void scheduleNewSearchTask() {
      if (this.mSearchTaskList.size() > 0) {
         this.mCurrentTask = (BluetoothSearchTask)this.mSearchTaskList.remove(0);
         this.mCurrentTask.start(new BluetoothSearchTaskResponse(this.mCurrentTask));
      } else {
         this.mCurrentTask = null;
         if (this.mSearchResponse != null) {
            this.mSearchResponse.onSearchStopped();
         }
      }

   }

   public void cancel() {
      if (this.mCurrentTask != null) {
         this.mCurrentTask.cancel();
         this.mCurrentTask = null;
      }

      this.mSearchTaskList.clear();
      if (this.mSearchResponse != null) {
         this.mSearchResponse.onSearchCanceled();
      }

      this.mSearchResponse = null;
   }

   private void notifyConnectedBluetoothDevices() {
      boolean hasBleTask = false;
      boolean hasBscTask = false;
      Iterator var3 = this.mSearchTaskList.iterator();

      while(var3.hasNext()) {
         BluetoothSearchTask task = (BluetoothSearchTask)var3.next();
         if (task.isBluetoothLeSearch()) {
            hasBleTask = true;
         } else {
            if (!task.isBluetoothClassicSearch()) {
               throw new IllegalArgumentException("unknown search task type!");
            }

            hasBscTask = true;
         }
      }

      if (hasBleTask) {
         this.notifyConnectedBluetoothLeDevices();
      }

      if (hasBscTask) {
         this.notifyBondedBluetoothClassicDevices();
      }

   }

   private void notifyConnectedBluetoothLeDevices() {
      List<BluetoothDevice> devices = BluetoothUtils.getConnectedBluetoothLeDevices();
      Iterator var2 = devices.iterator();

      while(var2.hasNext()) {
         BluetoothDevice device = (BluetoothDevice)var2.next();
         this.notifyDeviceFounded(new SearchResult(device));
      }

   }

   private void notifyBondedBluetoothClassicDevices() {
      List<BluetoothDevice> devices = BluetoothUtils.getBondedBluetoothClassicDevices();
      Iterator var2 = devices.iterator();

      while(var2.hasNext()) {
         BluetoothDevice device = (BluetoothDevice)var2.next();
         this.notifyDeviceFounded(new SearchResult(device));
      }

   }

   private void notifyDeviceFounded(SearchResult device) {
      this.mHandler.obtainMessage(18, device).sendToTarget();
   }

   public String toString() {
      StringBuilder sb = new StringBuilder();
      Iterator var2 = this.mSearchTaskList.iterator();

      while(var2.hasNext()) {
         BluetoothSearchTask task = (BluetoothSearchTask)var2.next();
         sb.append(task.toString() + ", ");
      }

      return sb.toString();
   }

   private class BluetoothSearchTaskResponse implements BluetoothSearchResponse {
      BluetoothSearchTask task;

      BluetoothSearchTaskResponse(BluetoothSearchTask task) {
         this.task = task;
      }

      public void onSearchStarted() {
         BluetoothLog.v(String.format("%s onSearchStarted", this.task));
      }

      public void onDeviceFounded(SearchResult device) {
         BluetoothLog.v(String.format("onDeviceFounded %s", device));
         BluetoothSearchRequest.this.notifyDeviceFounded(device);
      }

      public void onSearchStopped() {
         BluetoothLog.v(String.format("%s onSearchStopped", this.task));
         BluetoothSearchRequest.this.mHandler.sendEmptyMessageDelayed(17, 100L);
      }

      public void onSearchCanceled() {
         BluetoothLog.v(String.format("%s onSearchCanceled", this.task));
      }
   }
}
