package com.inuker.bluetooth.library.model;

import android.bluetooth.BluetoothGattCharacteristic;
import android.os.Parcel;
import android.os.Parcelable;
import android.os.Parcelable.Creator;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class BleGattService implements Parcelable, Comparable {
   private UUID uuid;
   private List<BleGattCharacter> characters;
   public static final Creator<BleGattService> CREATOR = new Creator<BleGattService>() {
      public BleGattService createFromParcel(Parcel in) {
         return new BleGattService(in);
      }

      public BleGattService[] newArray(int size) {
         return new BleGattService[size];
      }
   };

   public BleGattService(UUID uuid, Map<UUID, BluetoothGattCharacteristic> characters) {
      this.uuid = uuid;
      Iterator itor = characters.values().iterator();

      while(itor.hasNext()) {
         BluetoothGattCharacteristic characteristic = (BluetoothGattCharacteristic)itor.next();
         this.getCharacters().add(new BleGattCharacter(characteristic));
      }

   }

   protected BleGattService(Parcel in) {
      this.uuid = (UUID)in.readSerializable();
      in.readTypedList(this.getCharacters(), BleGattCharacter.CREATOR);
   }

   public UUID getUUID() {
      return this.uuid;
   }

   public List<BleGattCharacter> getCharacters() {
      if (this.characters == null) {
         this.characters = new ArrayList();
      }

      return this.characters;
   }

   public void writeToParcel(Parcel dest, int flags) {
      dest.writeSerializable(this.uuid);
      dest.writeTypedList(this.getCharacters());
   }

   public int describeContents() {
      return 0;
   }

   public String toString() {
      StringBuilder sb = new StringBuilder();
      sb.append(String.format("Service: %s\n", this.uuid));
      List<BleGattCharacter> characters = this.getCharacters();
      int size = characters.size();

      for(int i = 0; i < size; ++i) {
         sb.append(String.format(">>> Character: %s", characters.get(i)));
         if (i != size - 1) {
            sb.append("\n");
         }
      }

      return sb.toString();
   }

   public int compareTo(Object another) {
      if (another == null) {
         return 1;
      } else {
         BleGattService anotherService = (BleGattService)another;
         return this.uuid.compareTo(anotherService.uuid);
      }
   }
}
