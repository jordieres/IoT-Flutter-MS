## SensoriaHandler.java

```{contents}
:depth: 2
:local:
```

### Purpose

The `SensoriaHandler` class in the Android module handles communication with **Sensoria Smart Garment** devices. It interfaces with the Sensoria SDK for BLE management, sensor data streaming, connection status, and error handling. It enables bidirectional interaction between Flutter and native Android using Flutter’s `EventChannel`.

---

### Key Responsibilities

- Initialize and manage two Sensoria cores concurrently.
- Bind to the Sensoria Service and manage Bluetooth GATT callbacks.
- Handle streaming events and propagate them to Flutter.
- Serialize connection status and timestamps to JSON for diagnostics.

---

### Imports

Includes Android system APIs, BLE classes, and Sensoria SDK:

```java
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothDevice;
import com.sensoria.sensorialibrary.*;
```

Also includes:

- `EventChannel`, `MethodChannel` from Flutter
- `Handler`, `Looper`, `Gson`, and `Toast`

---

### Initialization Flow

1. **Service Binding**
   ```java
   SACore sacore1 = null;
   SADevice device1 = null;
   ```
   Each core-device pair is initialized upon service readiness.

2. **Permission Handling**
   Requests and verifies Bluetooth and Location permissions required by the Sensoria SDK.

3. **Sensor Binding**
   Sensoria devices are discovered and connected using:
   ```java
   sacore1.setSAServiceInterface(...);
   sacore1.connectSensor(...)
   ```

---

### Status Tracking

Tracks timestamps and provides structured output via:

```java
public String getCurrentStatus(int coreIndex)
```

Returns a JSON object with keys:
- `lastDataTimestampSensoriaCore`
- `lastDataWriteTimestamp`
- `isConnected`

---

### Stream Handling

Uses Flutter's `EventSink` to push live updates:
```java
eventSink.success(message)
```

This allows Flutter to reflect real-time BLE status and connectivity events from Sensoria devices.

---

### Best Practices

- Supports dual-core setup for concurrent smart garments.
- Strong null-checks and error logs for connection failure.
- Timestamp tracking enhances debugging and health monitoring.

---

### Dependencies

- Sensoria SDK (`sensorialibrary`)
- Gson for status serialization
- Android BLE and permission management

---

### Notes

- All interactions use Android's main thread via `Handler` and `Looper`.
- Designed to integrate seamlessly with `MainActivity.java` and Flutter event channels.
