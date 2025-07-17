## MainActivity.java

```{contents}
:depth: 2
:local:
```

### Purpose

The `MainActivity.java` class acts as the Android entry point for the **HealthyWear** Flutter application. It extends `FlutterActivity` and bridges native Android functionality with Flutter using `MethodChannel` and `EventChannel`. It also manages Bluetooth device scanning and communication for MetaWear and Sensoria sensors.

---

### Key Imports

```java
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.content.pm.PackageManager;
import android.Manifest;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.ScanResult;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.NotificationChannel;
import android.os.Build;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.annotation.NonNull;
```

#### Flutter & Plugin APIs

```java
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;
```

#### Networking

```java
import okhttp3.*;
```

#### MetaWear SDK

```java
import com.mbientlab.metawear.android.BtleService;
```

---

### Responsibilities

- **Bluetooth Permission Handling**
- **MetaWear Service Binding**
- **File Upload via OkHttp**
- **Event Channels for MetaWear and Sensoria status streaming**
- **Flutter MethodChannel Handlers for platform interop**

---

### Flutter Channels

#### MethodChannels

Handles one-shot requests from Flutter, such as:

- Uploading files to server
- Initiating sensor commands
- Querying permission status

#### EventChannels

Enables real-time stream communication to Flutter, such as:

- `metawear_connection_status`
- `sensoria_connection_status`

These push live BLE connection updates into the Dart application UI layer.

---

### Service Binding

```java
Intent serviceIntent = new Intent(this, BtleService.class);
bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE);
```

Binds the Android service used to communicate with MetaWear sensors.

---

### Notifications

```java
NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
```

Custom notifications are created during scanning or error handling.

---

### Uploads

```java
RequestBody fileBody = RequestBody.create(file, MediaType.parse("application/octet-stream"));
Request request = new Request.Builder().url(serverUrl).post(requestBody).build();
```

Files are uploaded from Android storage using OkHttp.

---

### Structure

- `configureFlutterEngine()` sets up all channels and service bindings.
- Sensors are initialized via `SensorHandler` objects.
- Communication is managed using `EventSink`.

---

### Platform-Specific Logic

All Bluetooth and file-handling operations are done through native Android code, while status and results are forwarded to Flutter through interop channels.

