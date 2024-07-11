package com.inuker.bluetooth.library.search;

import android.os.Parcel;
import android.os.Parcelable;
import android.os.Parcelable.Creator;

public class SearchTask implements Parcelable {
   private int searchType;
   private int searchDuration;
   public static final Creator<SearchTask> CREATOR = new Creator<SearchTask>() {
      public SearchTask createFromParcel(Parcel source) {
         return new SearchTask(source);
      }

      public SearchTask[] newArray(int size) {
         return new SearchTask[size];
      }
   };

   public int describeContents() {
      return 0;
   }

   public void writeToParcel(Parcel dest, int flags) {
      dest.writeInt(this.searchType);
      dest.writeInt(this.searchDuration);
   }

   public SearchTask() {
   }

   public int getSearchType() {
      return this.searchType;
   }

   public void setSearchType(int searchType) {
      this.searchType = searchType;
   }

   public int getSearchDuration() {
      return this.searchDuration;
   }

   public void setSearchDuration(int searchDuration) {
      this.searchDuration = searchDuration;
   }

   protected SearchTask(Parcel in) {
      this.searchType = in.readInt();
      this.searchDuration = in.readInt();
   }
}
