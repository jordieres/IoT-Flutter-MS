package com.inuker.bluetooth.library.receiver;

import com.inuker.bluetooth.library.receiver.listener.BluetoothReceiverListener;
import java.util.List;

public interface IReceiverDispatcher {
   List<BluetoothReceiverListener> getListeners(Class<?> var1);
}
