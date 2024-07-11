package com.inuker.bluetooth.library.connect.options;

import android.os.Parcel;
import android.os.Parcelable;
import android.os.Parcelable.Creator;

public class BleConnectOptions implements Parcelable {
   private int connectRetry;
   private int serviceDiscoverRetry;
   private int connectTimeout;
   private int serviceDiscoverTimeout;
   public static final Creator<BleConnectOptions> CREATOR = new Creator<BleConnectOptions>() {
      public BleConnectOptions createFromParcel(Parcel in) {
         return new BleConnectOptions(in);
      }

      public BleConnectOptions[] newArray(int size) {
         return new BleConnectOptions[size];
      }
   };

   public BleConnectOptions(Builder builder) {
      this.connectRetry = builder.connectRetry;
      this.serviceDiscoverRetry = builder.serviceDiscoverRetry;
      this.connectTimeout = builder.connectTimeout;
      this.serviceDiscoverTimeout = builder.serviceDiscoverTimeout;
   }

   protected BleConnectOptions(Parcel in) {
      this.connectRetry = in.readInt();
      this.serviceDiscoverRetry = in.readInt();
      this.connectTimeout = in.readInt();
      this.serviceDiscoverTimeout = in.readInt();
   }

   public int describeContents() {
      return 0;
   }

   public void writeToParcel(Parcel dest, int flags) {
      dest.writeInt(this.connectRetry);
      dest.writeInt(this.serviceDiscoverRetry);
      dest.writeInt(this.connectTimeout);
      dest.writeInt(this.serviceDiscoverTimeout);
   }

   public int getConnectRetry() {
      return this.connectRetry;
   }

   public void setConnectRetry(int connectRetry) {
      this.connectRetry = connectRetry;
   }

   public int getServiceDiscoverRetry() {
      return this.serviceDiscoverRetry;
   }

   public void setServiceDiscoverRetry(int serviceDiscoverRetry) {
      this.serviceDiscoverRetry = serviceDiscoverRetry;
   }

   public int getConnectTimeout() {
      return this.connectTimeout;
   }

   public void setConnectTimeout(int connectTimeout) {
      this.connectTimeout = connectTimeout;
   }

   public int getServiceDiscoverTimeout() {
      return this.serviceDiscoverTimeout;
   }

   public void setServiceDiscoverTimeout(int serviceDiscoverTimeout) {
      this.serviceDiscoverTimeout = serviceDiscoverTimeout;
   }

   public String toString() {
      return "BleConnectOptions{connectRetry=" + this.connectRetry + ", serviceDiscoverRetry=" + this.serviceDiscoverRetry + ", connectTimeout=" + this.connectTimeout + ", serviceDiscoverTimeout=" + this.serviceDiscoverTimeout + '}';
   }

   public static class Builder {
      private static final int DEFAULT_CONNECT_RETRY = 0;
      private static final int DEFAULT_SERVICE_DISCOVER_RETRY = 0;
      private static final int DEFAULT_CONNECT_TIMEOUT = 30000;
      private static final int DEFAULT_SERVICE_DISCOVER_TIMEOUT = 30000;
      private int connectRetry = 0;
      private int serviceDiscoverRetry = 0;
      private int connectTimeout = 30000;
      private int serviceDiscoverTimeout = 30000;

      public Builder setConnectRetry(int retry) {
         this.connectRetry = retry;
         return this;
      }

      public Builder setServiceDiscoverRetry(int retry) {
         this.serviceDiscoverRetry = retry;
         return this;
      }

      public Builder setConnectTimeout(int timeout) {
         this.connectTimeout = timeout;
         return this;
      }

      public Builder setServiceDiscoverTimeout(int timeout) {
         this.serviceDiscoverTimeout = timeout;
         return this;
      }

      public BleConnectOptions build() {
         return new BleConnectOptions(this);
      }
   }
}
