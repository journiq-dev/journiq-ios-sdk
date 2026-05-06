import Foundation

/// Stores deep link attribution data for automatic event attribution.
///
/// After a deferred deep link match or incoming URL is handled,
/// subsequent event tracking calls will automatically include
/// the attributed `deepLinkId` unless explicitly overridden.
public final class JourniqAttribution: @unchecked Sendable {

    private static let lock = NSLock()
    private static var _deepLinkId: String?
    private static var _clickId: String?

    /// The deep link ID from the last matched/handled deep link.
    public static var deepLinkId: String? {
        lock.lock()
        defer { lock.unlock() }
        return _deepLinkId
    }

    /// The click ID from the last matched/handled deep link.
    public static var clickId: String? {
        lock.lock()
        defer { lock.unlock() }
        return _clickId
    }

    /// Store attribution data from a match result or incoming link.
    public static func setAttribution(deepLinkId: String?, clickId: String?) {
        lock.lock()
        defer { lock.unlock() }
        if let deepLinkId { _deepLinkId = deepLinkId }
        if let clickId { _clickId = clickId }
    }

    /// Clear stored attribution (e.g. on logout).
    public static func clear() {
        lock.lock()
        defer { lock.unlock() }
        _deepLinkId = nil
        _clickId = nil
    }

    /// Extract attribution params from a URL (jq_link, jq_click).
    /// - Returns: true if any attribution param was found.
    @discardableResult
    public static func extractFromURL(_ url: URL) -> Bool {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        let link = items.first(where: { $0.name == "jq_link" })?.value
        let click = items.first(where: { $0.name == "jq_click" })?.value
        if link != nil || click != nil {
            setAttribution(deepLinkId: link, clickId: click)
            return true
        }
        return false
    }

    private init() {}
}
