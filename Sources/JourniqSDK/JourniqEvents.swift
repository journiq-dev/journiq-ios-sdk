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

    /// Track a screen view.
    ///
    /// Fires a `screen_view` event with `metadata["screen"]` set to `screenName`.
    /// Use this to power page-specific automation triggers in the Journiq
    /// dashboard (Trigger Event = `screen_view`, Page Name = the value you pass here).
    /// - Parameters:
    ///   - screenName: The name of the screen being viewed (e.g. "Home", "Checkout")
    ///   - metadata: Optional additional key-value metadata
    public func trackScreenView(
        screenName: String,
        metadata: [String: String]? = nil
    ) {
        var merged: [String: String] = ["screen": screenName]
        if let extra = metadata {
            merged.merge(extra) { _, new in new }
        }
        let event = TrackEvent(
            eventName: "screen_view",
            deepLinkId: nil,
            metadata: merged
        )
        sdk.eventQueue.enqueue(event: event)
    }

    /// Force flush all pending events immediately.
    public func flush() async {
        await sdk.eventQueue.flush()
    }
}
