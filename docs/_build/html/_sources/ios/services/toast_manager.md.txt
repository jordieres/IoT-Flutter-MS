## ToastManager.swift

```{contents}
:depth: 2
:local:
```

### Purpose

`ToastManager.swift` is a lightweight utility class that provides simple toast-like message functionality for iOS using `UIAlertController`. It enables temporary messages to be shown in the app without requiring any third-party dependencies.

---

### Key Features

- Singleton design for global access.
- Presents a `UIAlertController` with a message.
- Automatically dismisses the alert after a specified duration.

---

### Design Pattern

```swift
static let shared = ToastManager()
private init() {}
```

Implements the Singleton pattern to ensure a single shared instance throughout the app.

---

### Method: showToast

```swift
func showToast(message: String, duration: TimeInterval = 2.0, in viewController: UIViewController?)
```

- `message`: The string to display in the toast.
- `duration`: How long the toast should be shown (defaults to 2 seconds).
- `viewController`: The current `UIViewController` to present from.

#### Behavior:
1. Creates a `UIAlertController` with no title and the message body.
2. Presents the alert on the provided view controller.
3. Uses `DispatchQueue.main.asyncAfter(...)` to dismiss the alert after the duration.

Example usage:
```swift
ToastManager.shared.showToast(message: "Sensor connected", in: self)
```

---

### Use Cases

- Notifying the user when a sensor connects or disconnects.
- Alerting of a successful file save or error.
- Displaying non-intrusive status updates in test builds.


