package com.inuker.bluetooth.library.model;

import android.bluetooth.BluetoothGattCharacteristic;
import android.os.Parcel;
import android.os.Parcelable;
import android.os.Parcelable.Creator;
import com.inuker.bluetooth.library.utils.ListUtils;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.Map.Entry;

public class BleGattProfile implements Parcelable {
   private List<BleGattService> services;
   public static final Creator<BleGattProfile> CREATOR = new Creator<BleGattProfile>() {
      public BleGattProfile createFromParcel(Parcel in) {
         return new BleGattProfile(in);
      }

      public BleGattProfile[] newArray(int size) {
         return new BleGattProfile[size];
      }
   };

   public BleGattProfile(Map<UUID, Map<UUID, BluetoothGattCharacteristic>> map) {
      Iterator itor = map.entrySet().iterator();
      ArrayList serviceList = new ArrayList();

      while(itor.hasNext()) {
         Entry entry = (Entry)itor.next();
         UUID serviceUUID = (UUID)entry.getKey();
         Map<UUID, BluetoothGattCharacteristic> characters = (Map)entry.getValue();
         BleGattService service = new BleGattService(serviceUUID, characters);
         if (!serviceList.contains(service)) {
            serviceList.add(service);
         }
      }

      this.addServices(serviceList);
   }

   public BleGattProfile(Parcel in) {
      in.readTypedList(this.getServices(), BleGattService.CREATOR);
   }

   public void addServices(List<BleGattService> services) {
      Collections.sort(services);
      this.getServices().addAll(services);
   }

   public List<BleGattService> getServices() {
      if (this.services == null) {
         this.services = new ArrayList();
      }

      return this.services;
   }

   public BleGattService getService(UUID serviceId) {
      if (serviceId == null) {
         return null;
      } else {
         List<BleGattService> services = this.getServices();
         Iterator var3 = services.iterator();

         BleGattService service;
         do {
            if (!var3.hasNext()) {
               return null;
            }

            service = (BleGattService)var3.next();
         } while(!service.getUUID().equals(serviceId));

         return service;
      }
   }

   public boolean containsCharacter(UUID serviceId, UUID characterId) {
      if (serviceId != null && characterId != null) {
         BleGattService service = this.getService(serviceId);
         if (service != null) {
            List<BleGattCharacter> characters = service.getCharacters();
            if (!ListUtils.isEmpty(characters)) {
               Iterator var5 = characters.iterator();

               while(var5.hasNext()) {
                  BleGattCharacter character = (BleGattCharacter)var5.next();
                  if (characterId.equals(character.getUuid())) {
                     return true;
                  }
               }
            }
         }

         return false;
      } else {
         return false;
      }
   }

   public void writeToParcel(Parcel dest, int flags) {
      dest.writeTypedList(this.getServices());
   }

   public int describeContents() {
      return 0;
   }

   public String toString() {
      StringBuilder sb = new StringBuilder();
      Iterator var2 = this.services.iterator();

      while(var2.hasNext()) {
         BleGattService service = (BleGattService)var2.next();
         sb.append(service).append("\n");
      }

      return sb.toString();
   }
}
