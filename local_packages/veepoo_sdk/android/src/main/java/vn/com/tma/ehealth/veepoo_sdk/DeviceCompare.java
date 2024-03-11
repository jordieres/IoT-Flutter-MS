package vn.com.tma.ehealth.veepoo_sdk;

import com.inuker.bluetooth.library.search.SearchResult;

import java.util.Comparator;

public class DeviceCompare implements Comparator<SearchResult> {

    @Override
    public int compare(SearchResult o1, SearchResult o2) {
        return o2.rssi - o1.rssi;
    }
}
