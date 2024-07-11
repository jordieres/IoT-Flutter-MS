package com.inuker.bluetooth.library.search;

import android.bluetooth.BluetoothDevice;
import android.os.Parcel;
import android.os.Parcelable;
import android.os.Parcelable.Creator;
import android.text.TextUtils;

public class SearchResult implements Parcelable {
   public BluetoothDevice device;
   public int rssi;
   public byte[] scanRecord;
   public static final Creator<SearchResult> CREATOR = new Creator<SearchResult>() {
      public SearchResult createFromParcel(Parcel source) {
         return new SearchResult(source);
      }

      public SearchResult[] newArray(int size) {
         return new SearchResult[size];
      }
   };

   public SearchResult(BluetoothDevice device) {
      this(device, 0, (byte[])null);
   }

   public SearchResult(BluetoothDevice device, int rssi, byte[] scanRecord) {
      this.device = device;
      this.rssi = rssi;
      this.scanRecord = scanRecord;
   }

   public String getName() {
      String name = this.device.getName();
      return TextUtils.isEmpty(name) ? "NULL" : name;
   }

   public String getAddress() {
      return this.device != null ? this.device.getAddress() : "";
   }

   public byte[] getScanRecord() {
      return this.scanRecord;
   }

   public String toString() {
      StringBuilder sb = new StringBuilder();
      sb.append(", mac = " + this.device.getAddress());
      return sb.toString();
   }

   public int describeContents() {
      return 0;
   }

   public void writeToParcel(Parcel dest, int flags) {
      dest.writeParcelable(this.device, 0);
      dest.writeInt(this.rssi);
      dest.writeByteArray(this.scanRecord);
   }

   public SearchResult(Parcel in) {
      this.device = (BluetoothDevice)in.readParcelable(BluetoothDevice.class.getClassLoader());
      this.rssi = in.readInt();
      this.scanRecord = in.createByteArray();
   }

   public boolean equals(Object o) {
      if (this == o) {
         return true;
      } else if (o != null && this.getClass() == o.getClass()) {
         SearchResult that = (SearchResult)o;
         return this.device.equals(that.device);
      } else {
         return false;
      }
   }

   public int hashCode() {
      return this.device.hashCode();
   }
}
