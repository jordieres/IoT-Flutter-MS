package com.inuker.bluetooth.library.model;

import android.bluetooth.BluetoothGattCharacteristic;
import android.os.Parcel;
import android.os.Parcelable;
import android.os.Parcelable.Creator;
import java.util.UUID;

public class BleGattCharacter implements Parcelable {
   private UUID uuid;
   private int property;
   private int permissions;
   public static final Creator<BleGattCharacter> CREATOR = new Creator<BleGattCharacter>() {
      public BleGattCharacter createFromParcel(Parcel in) {
         return new BleGattCharacter(in);
      }

      public BleGattCharacter[] newArray(int size) {
         return new BleGattCharacter[size];
      }
   };

   protected BleGattCharacter(Parcel in) {
      this.uuid = (UUID)in.readSerializable();
      this.property = in.readInt();
      this.permissions = in.readInt();
   }

   public BleGattCharacter(BluetoothGattCharacteristic characteristic) {
      this.uuid = characteristic.getUuid();
      this.property = characteristic.getProperties();
      this.permissions = characteristic.getPermissions();
   }

   public void writeToParcel(Parcel dest, int flags) {
      dest.writeSerializable(this.uuid);
      dest.writeInt(this.property);
      dest.writeInt(this.permissions);
   }

   public int describeContents() {
      return 0;
   }

   public int getProperty() {
      return this.property;
   }

   public void setProperty(int property) {
      this.property = property;
   }

   public UUID getUuid() {
      return this.uuid;
   }

   public void setUuid(UUID uuid) {
      this.uuid = uuid;
   }

   public int getPermissions() {
      return this.permissions;
   }

   public void setPermissions(int permissions) {
      this.permissions = permissions;
   }

   public String toString() {
      return "BleGattCharacter{uuid=" + this.uuid + ", property=" + this.property + ", permissions=" + this.permissions + '}';
   }
}
