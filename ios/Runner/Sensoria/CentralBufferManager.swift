import Foundation

/// Sensoria SDK callbacks and slot changes are delivered on the main queue.
final class CentralBufferManager {
    private(set) var isRecording = false
    private(set) var recordingStartedAt: TimeInterval = .infinity
    private var streamingSlots = Set<Int>()
    private var dataBuffer: [String] = []

    func setRecording(_ enabled: Bool) {
        if enabled && !isRecording { recordingStartedAt = ProcessInfo.processInfo.systemUptime }
        isRecording = enabled
        if !enabled { flush() }
    }

    func connected(_ slot: Int) {
        streamingSlots.insert(slot)
    }

    func disconnected(_ slot: Int) {
        streamingSlots.remove(slot)
        if streamingSlots.isEmpty { setRecording(false) }
    }

    func addData(data: String) {
        guard isRecording else { return }
        dataBuffer.append(data)
        if dataBuffer.count >= 1000 { flush() }
    }

    func flush() {
        guard !dataBuffer.isEmpty else { return }
        LocationDataManager.shared.fetchLocationAndSaveData(
            dataType: "S", dataBuffer: dataBuffer
        ) { success in
            if success { self.dataBuffer.removeAll() }
        }
    }
}
