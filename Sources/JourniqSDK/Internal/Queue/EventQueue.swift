import Foundation
import Network

/// File-based offline event queue.
/// Events are persisted as JSON in Library/Caches/journiq_events/ and flushed in batches.
final class EventQueue: @unchecked Sendable {

    private let apiClient: ApiClient
    private let storage: JourniqStorage
    private let queue = DispatchQueue(label: "com.journiq.eventqueue", qos: .utility)
    private let cacheDir: URL
    private let monitor = NWPathMonitor()
    private var flushTimer: DispatchSourceTimer?

    private let maxQueueSize = 1000
    private let maxRetries = 3
    private let batchSize = 100
    private let flushIntervalSeconds: TimeInterval = 60
    private let eventExpirySeconds: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    init(apiClient: ApiClient, storage: JourniqStorage) {
        self.apiClient = apiClient
        self.storage = storage

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDir = caches.appendingPathComponent("journiq_events", isDirectory: true)

        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func start() {
        startPeriodicFlush()
        startNetworkMonitor()
    }

    func stop() {
        flushTimer?.cancel()
        flushTimer = nil
        monitor.cancel()
    }

    func enqueue(event: TrackEvent) {
        // Capture identity at enqueue time: real userId if identified, else stable anonymousId
        let effectiveUserId = storage.userId ?? storage.anonymousId
        queue.async { [self] in
            enforceMaxSize()

            let entry = PendingEvent(
                id: UUID().uuidString,
                eventName: event.eventName,
                deepLinkId: event.deepLinkId,
                metadata: event.metadata,
                userId: effectiveUserId,
                occurredAt: ISO8601DateFormatter().string(from: event.occurredAt),
                retryCount: 0,
                createdAt: Date().timeIntervalSince1970
            )

            let file = cacheDir.appendingPathComponent("\(entry.id).json")
            if let data = try? JSONEncoder().encode(entry) {
                try? data.write(to: file, options: .atomic)
            }
        }
    }

    func flush() async {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                purgeExpiredAndFailed()

                let entries = loadPendingEvents()
                    .sorted { $0.createdAt < $1.createdAt }
                    .prefix(batchSize)

                guard !entries.isEmpty else {
                    continuation.resume()
                    return
                }

                let items = entries.map { entry in
                    EventItem(
                        eventName: entry.eventName,
                        deepLinkId: entry.deepLinkId,
                        metadata: entry.metadata,
                        occurredAt: entry.occurredAt,
                        userId: entry.userId
                    )
                }

                Task {
                    do {
                        let result = try await self.apiClient.trackEventsBatch(items)
                        self.queue.async {
                            if result.accepted == items.count {
                                for entry in entries {
                                    self.deleteEvent(id: entry.id)
                                }
                            } else {
                                for entry in entries {
                                    self.incrementRetry(id: entry.id)
                                }
                            }
                            continuation.resume()
                        }
                    } catch {
                        self.queue.async {
                            for entry in entries {
                                self.incrementRetry(id: entry.id)
                            }
                            continuation.resume()
                        }
                    }
                }
            }
        }
    }

    func onAppForegrounded() {
        Task { await flush() }
    }

    // MARK: - Private

    private func loadPendingEvents() -> [PendingEvent] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDir, includingPropertiesForKeys: nil
        ) else { return [] }

        return files.compactMap { url -> PendingEvent? in
            guard url.pathExtension == "json",
                  let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(PendingEvent.self, from: data)
        }
    }

    private func enforceMaxSize() {
        let events = loadPendingEvents().sorted { $0.createdAt < $1.createdAt }
        if events.count >= maxQueueSize {
            let excess = events.count - maxQueueSize + 1
            for event in events.prefix(excess) {
                deleteEvent(id: event.id)
            }
        }
    }

    private func purgeExpiredAndFailed() {
        let cutoff = Date().timeIntervalSince1970 - eventExpirySeconds
        for event in loadPendingEvents() {
            if event.retryCount >= maxRetries || event.createdAt < cutoff {
                deleteEvent(id: event.id)
            }
        }
    }

    private func deleteEvent(id: String) {
        let file = cacheDir.appendingPathComponent("\(id).json")
        try? FileManager.default.removeItem(at: file)
    }

    private func incrementRetry(id: String) {
        let file = cacheDir.appendingPathComponent("\(id).json")
        guard let data = try? Data(contentsOf: file),
              var event = try? JSONDecoder().decode(PendingEvent.self, from: data) else { return }
        event.retryCount += 1
        if let newData = try? JSONEncoder().encode(event) {
            try? newData.write(to: file, options: .atomic)
        }
    }

    private func startPeriodicFlush() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + flushIntervalSeconds, repeating: flushIntervalSeconds)
        timer.setEventHandler { [weak self] in
            Task { await self?.flush() }
        }
        timer.resume()
        flushTimer = timer
    }

    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                Task { await self?.flush() }
            }
        }
        monitor.start(queue: queue)
    }
}

// MARK: - Pending Event Model

struct PendingEvent: Codable {
    let id: String
    let eventName: String
    let deepLinkId: String?
    let metadata: [String: String]?
    let userId: String?
    let occurredAt: String
    var retryCount: Int
    let createdAt: TimeInterval
}
