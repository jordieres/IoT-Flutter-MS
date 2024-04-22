class EventManager {
    static let shared = EventManager()  // Singleton instance

    private var eventSink: FlutterEventSink?

    func setEventSink(sink: @escaping FlutterEventSink) {
        self.eventSink = sink
    }

    func dispatchEvent(_ event: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(event)
        }
    }
}
