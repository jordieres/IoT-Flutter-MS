package com.inuker.bluetooth.library.search;

import android.os.Parcel;
import android.os.Parcelable;
import android.os.Parcelable.Creator;
import com.inuker.bluetooth.library.utils.BluetoothUtils;
import java.util.ArrayList;
import java.util.List;

public class SearchRequest implements Parcelable {
   private List<SearchTask> tasks;
   public static final Creator<SearchRequest> CREATOR = new Creator<SearchRequest>() {
      public SearchRequest createFromParcel(Parcel source) {
         return new SearchRequest(source);
      }

      public SearchRequest[] newArray(int size) {
         return new SearchRequest[size];
      }
   };

   public int describeContents() {
      return 0;
   }

   public void writeToParcel(Parcel dest, int flags) {
      dest.writeTypedList(this.tasks);
   }

   public SearchRequest() {
   }

   protected SearchRequest(Parcel in) {
      this.tasks = new ArrayList();
      in.readTypedList(this.tasks, SearchTask.CREATOR);
   }

   public List<SearchTask> getTasks() {
      return this.tasks;
   }

   public void setTasks(List<SearchTask> tasks) {
      this.tasks = tasks;
   }

   public static class Builder {
      private List<SearchTask> tasks = new ArrayList();

      public Builder searchBluetoothLeDevice(int duration) {
         if (BluetoothUtils.isBleSupported()) {
            SearchTask search = new SearchTask();
            search.setSearchType(2);
            search.setSearchDuration(duration);
            this.tasks.add(search);
         }

         return this;
      }

      public Builder searchBluetoothLeDevice(int duration, int times) {
         for(int i = 0; i < times; ++i) {
            this.searchBluetoothLeDevice(duration);
         }

         return this;
      }

      public Builder searchBluetoothClassicDevice(int duration) {
         SearchTask search = new SearchTask();
         search.setSearchType(1);
         search.setSearchDuration(duration);
         this.tasks.add(search);
         return this;
      }

      public Builder searchBluetoothClassicDevice(int duration, int times) {
         for(int i = 0; i < times; ++i) {
            this.searchBluetoothClassicDevice(duration);
         }

         return this;
      }

      public SearchRequest build() {
         SearchRequest group = new SearchRequest();
         group.setTasks(this.tasks);
         return group;
      }
   }
}
