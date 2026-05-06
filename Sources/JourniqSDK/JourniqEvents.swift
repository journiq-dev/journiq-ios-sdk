import Foundation

/// Event tracking module.
///
/// Events are queued locally and flushed to the server in batches.
public struct JourniqEvents: Sendable {

    let sdk: Journiq

    /// Track a conversion or custom event.
    ///
    /// Events are queued locally and flushed to the server in batches.
    /// If no `deepLinkId` is provided, the last attributed deep link ID
    /// (from a deferred match or incoming URL) is used automatically.
    /// - Parameters:
    ///   - eventName: Name of the event (e.g. "purchase", "signup")
    ///   - deepLinkId: Optional ID of the deep link that led to this event
    ///   - metadata: Optional key-value metadata
    public func track(
        eventName: String,
        deepLinkId: String? = nil,
        metadata: [String: String]? = nil
    ) {
        let effectiveDeepLinkId = deepLinkId ?? JourniqAttribution.deepLinkId
        let event = TrackEvent(
            eventName: eventName,
            deepLinkId: effectiveDeepLinkId,
            metadata: metadata
        )
        sdk.eventQueue.enqueue(event: event)
    }

    /// Force flush all pending events immediately.
    public func flush() async {
        await sdk.eventQueue.flush()
    }
}
