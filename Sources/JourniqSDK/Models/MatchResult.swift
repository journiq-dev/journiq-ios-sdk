import Foundation

/// Result of a deferred deep link match.
public struct MatchResult: Codable, Sendable {
    public let matched: Bool
    public let deepLink: DeepLink?
    public let clickId: String?

    public init(matched: Bool, deepLink: DeepLink? = nil, clickId: String? = nil) {
        self.matched = matched
        self.deepLink = deepLink
        self.clickId = clickId
    }
}
