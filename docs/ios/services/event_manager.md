## EventManager.swift

```{contents}
:depth: 2
:local:
```

### Purpose

The `EventManager.swift` class acts as a centralized helper to send event data from native iOS code to the Flutter layer using a shared `FlutterEventSink`.

---

### Singleton Pattern

```swift
static let shared = EventManager()
```

Ensures that all native modules use the same `EventManager` instance to manage event streams.

---

### Key Responsibilities

- Holds a reference to a `FlutterEventSink`.
- Dispatches dictionary-based event messages to Flutter.
- Ensures thread safety by using the main dispatch queue for event emission.

---

### Properties

```swift
private var eventSink: FlutterEventSink?
```

Holds the callback function provided by Flutter to receive stream data.

---

### Methods

#### Set Event Sink

```swift
func setEventSink(sink: @escaping FlutterEventSink)
```

Stores the event sink function that will be used to push updates to Flutter.

#### Dispatch Event

```swift
func dispatchEvent(_ event: [String: Any])
```

- Accepts a dictionary and forwards it to Flutter using the stored `eventSink`.
- Uses `DispatchQueue.main.async` to ensure the update occurs on the main UI thread.

Example usage:
```swift
EventManager.shared.dispatchEvent(["status": "connected"])
```

---

### Integration

- Called by iOS BLE sensor handlers or other iOS logic that needs to report to Dart asynchronously.
- Simplifies communication by abstracting Flutter stream interface away from business logic.

---

### Summary

`EventManager.swift` acts as a tiny but essential abstraction to push structured data from iOS native code to Flutter via `EventChannel`. It is designed for simplicity, thread safety, and reusability.
