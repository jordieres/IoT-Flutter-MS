package com.inuker.bluetooth.library.connect.options;

import android.os.Parcel;
import android.os.Parcelable.Creator;

public class BleConnectOption extends GeneralOption {
   public static final Creator<BleConnectOption> CREATOR = new Creator<BleConnectOption>() {
      public BleConnectOption createFromParcel(Parcel in) {
         return new BleConnectOption(in);
      }

      public BleConnectOption[] newArray(int size) {
         return new BleConnectOption[size];
      }
   };

   protected BleConnectOption(Parcel in) {
      super(in);
   }

   public int describeContents() {
      return 0;
   }

   public void writeToParcel(Parcel dest, int flags) {
   }
}
