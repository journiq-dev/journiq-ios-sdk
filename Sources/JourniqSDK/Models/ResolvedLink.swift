import Foundation

/// Source of the link open event.
public enum LinkOpenSource: String, Codable, Sendable {
    case universalLink = "universal_link"
    case appLink = "app_link"
    case scheme = "scheme"
    case deferred = "deferred"
}

/// Result of resolving a universal/app link URL via the Journiq API.
public struct ResolvedLink: Codable, Sendable {
    public let deepLinkId: String
    public let deepLinkPath: String?
    public let webUrl: String?
    public let parameters: [String: String]?
    public let utmSource: String?
    public let utmMedium: String?
    public let utmCampaign: String?
    public let utmTerm: String?
    public let utmContent: String?
}

/// Internal request body for link resolution.
struct ResolveLinkRequest: Encodable {
    let url: String
    let source: String?
    let userId: String?
    let deviceId: String?
}
