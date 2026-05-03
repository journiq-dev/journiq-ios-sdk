import Foundation

/// Event to track.
public struct TrackEvent: Sendable {
    public let eventName: String
    public let deepLinkId: String?
    public let metadata: [String: String]?
    public let occurredAt: Date

    public init(
        eventName: String,
        deepLinkId: String? = nil,
        metadata: [String: String]? = nil,
        occurredAt: Date = Date()
    ) {
        self.eventName = eventName
        self.deepLinkId = deepLinkId
        self.metadata = metadata
        self.occurredAt = occurredAt
    }
}
