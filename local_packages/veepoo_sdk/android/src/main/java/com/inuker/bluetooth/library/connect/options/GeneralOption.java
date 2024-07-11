package com.inuker.bluetooth.library.connect.options;

import android.os.Parcel;
import android.os.Parcelable;
import android.os.Parcelable.Creator;

public class GeneralOption implements Parcelable {
   private int maxRetry;
   private int timeoutInMillis;
   public static final Creator<GeneralOption> CREATOR = new Creator<GeneralOption>() {
      public GeneralOption createFromParcel(Parcel in) {
         return new GeneralOption(in);
      }

      public GeneralOption[] newArray(int size) {
         return new GeneralOption[size];
      }
   };

   public int getMaxRetry() {
      return this.maxRetry;
   }

   public void setMaxRetry(int maxRetry) {
      this.maxRetry = Math.max(maxRetry, 0);
   }

   public int getTimeoutInMillis() {
      return this.timeoutInMillis;
   }

   public void setTimeoutInMillis(int timeoutInMillis) {
      this.timeoutInMillis = Math.max(timeoutInMillis, 1000);
   }

   protected GeneralOption(Parcel in) {
      this.maxRetry = in.readInt();
      this.timeoutInMillis = in.readInt();
   }

   public int describeContents() {
      return 0;
   }

   public void writeToParcel(Parcel dest, int flags) {
      dest.writeInt(this.maxRetry);
      dest.writeInt(this.timeoutInMillis);
   }
}
