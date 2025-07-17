## device_connection_status.dart

```{contents}
:depth: 2
:local:
```

### Purpose

The `device_connection_status.dart` file defines an `enum` that represents the connection states of a Bluetooth device. This enum is used across the Flutter application to reflect and manage connection state logic.

---

### Enum Definition

```dart
enum DeviceConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting
}
```

---

### Enum Values and Meanings

| Status        | Description |
|---------------|-------------|
| `disconnected` | The device is not connected. This is the default or initial state. |
| `connecting`   | The device is in the process of establishing a BLE connection. |
| `connected`    | The device is actively connected via BLE. |
| `reconnecting` | A connection was lost and is currently being re-established. |

---

### Usage Context

This enum is used in:

- SmartBand APIs
- Sensoria APIs
- MetaWear APIs

...to uniformly represent BLE connection lifecycle across all devices in the app.

