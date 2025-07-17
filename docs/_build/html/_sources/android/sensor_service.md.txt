## SensorService.java

```{contents}
:depth: 2
:local:
```

### Purpose

The `SensorService` is an Android `Service` class designed to run sensor-related background tasks in a persistent foreground mode. It primarily initializes and manages the MetaWearHandler to keep data streaming alive during app backgrounding.

---

### Features & Responsibilities

- Runs independently of Flutter UI as a long-lived background process.
- Handles localization dynamically based on language settings passed via `Intent`.
- Starts in the foreground with a persistent notification to prevent termination.
- Verifies permission status (e.g. `ACCESS_FINE_LOCATION`) on startup.

---

### Initialization

```java
@Override
public void onCreate() {
    super.onCreate();
    metaWearHandler = new MetaWearHandler(this, null);
}
```

Initializes the `MetaWearHandler` when the service is created.

---

### Start Command Logic

```java
@Override
public int onStartCommand(Intent intent, int flags, int startId)
```

Handles:
- Language switching via `LANGUAGE_CODE` intent extra.
- Permission check: If `ACCESS_FINE_LOCATION` is not granted, the service stops itself.
- Updates the app's locale dynamically if the language is provided.

---

### Foreground Notification

The method `startForegroundServiceWithNotification()`:

- Creates a `NotificationChannel`
- Builds and launches a persistent notification using `NotificationCompat`
- Prevents Android from force-killing the background process

This is essential for uninterrupted sensor operations.

---

### Language Localization

If `LANGUAGE_CODE` is provided via intent:
```java
Locale locale = new Locale(languageCode);
Locale.setDefault(locale);
Configuration config = new Configuration();
config.setLocale(locale);
```

Updates the application's configuration to use the desired language.

---

### Lifecycle Overrides

- `onBind()` returns `null` as this is a started service.
- `onDestroy()` provides cleanup hooks (though none are implemented).

---

### Integration

- Designed to integrate tightly with `MetaWearHandler.java`
- Used in scenarios where BLE sensors must stream data continuously even when the app is backgrounded.

---

### Best Practices

- Handles runtime permission validation safely.
- Starts foreground notification for Android 8+ compliance.
- Avoids binding; focuses on self-contained execution for background data acquisition.

---

### Dependencies

- `MetaWearHandler`
- Android `Service`, `Notification`, `Locale`, and BLE permission classes
