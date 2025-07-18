## LocationDataManager.swift

```{contents}
:depth: 2
:local:
```

### Purpose

The `LocationDataManager.swift` class handles location tracking using CoreLocation and coordinates with the `FileHandler` to attach location metadata to sensor data collected by the HealthyWear app.

---

### Key Responsibilities

- Manages continuous location updates with `CLLocationManager`.
- Provides the last known location to sensor data when saving.
- Verifies location permission status and responds to system callbacks.
- Designed as a singleton to allow shared access across modules.

---

### Singleton Setup

```swift
static let shared = LocationDataManager()
```

Provides global access to a single instance across the iOS app.

---

### Properties

```swift
private var locationManager = CLLocationManager()
private var lastKnownLocation: CLLocation?
```

- `locationManager`: CoreLocation’s central controller.
- `lastKnownLocation`: Stores the most recent location data.

---

### Initialization

```swift
override init() {
    super.init()
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
}
```

Requests permission and sets up the delegate on initialization.

---

### Start Location Updates

```swift
private func startLocationUpdates()
```

- Uses `DispatchQueue.main.async` to ensure updates run on the main thread.
- Sets `desiredAccuracy` to `kCLLocationAccuracyHundredMeters` for balance of precision and battery.
- TODO: Improve by throttling updates (e.g., every 50 seconds).

---

### Saving Sensor Data with Location

```swift
func fetchLocationAndSaveData(dataType: String, dataBuffer: [String], completion: @escaping (Bool) -> Void)
```

- Ensures a valid location exists.
- Passes location coordinates and buffer to `FileHandler.shared.saveDataToFile`.

---

### CLLocationManagerDelegate Methods

#### `didChangeAuthorization`

Handles permission changes:
- Starts updates if authorized.
- Logs if denied or restricted.

#### `didUpdateLocations`

Updates the `lastKnownLocation` with the most recent GPS result.

#### `didFailWithError`

Handles failure and prints debugging message.

---

### Utility Method

```swift
func checkLocationServicesAndNotify()
```

- Verifies if location services are enabled.
- If not, prints instructions to enable them in device settings.

---

### Integration

Used whenever sensor data must be saved with geolocation context. This includes:
- Smart sock recordings
- Smart band sensor streams
- Motion sensors

