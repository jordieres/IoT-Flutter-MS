package com.inuker.bluetooth.library;

import com.inuker.bluetooth.library.connect.listener.BleConnectStatusListener;
import com.inuker.bluetooth.library.connect.listener.BluetoothStateListener;
import com.inuker.bluetooth.library.connect.response.BleNotifyResponse;
import com.inuker.bluetooth.library.receiver.listener.BluetoothBondListener;
import java.util.HashMap;
import java.util.List;

public class BluetoothClientReceiver {
   private HashMap<String, HashMap<String, List<BleNotifyResponse>>> mNotifyResponses;
   private HashMap<String, List<BleConnectStatusListener>> mConnectStatusListeners;
   private List<BluetoothStateListener> mBluetoothStateListeners;
   private List<BluetoothBondListener> mBluetoothBondListeners;
}
