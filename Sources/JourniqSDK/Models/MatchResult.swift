import Foundation

/// Result of a deferred deep link match.
public struct MatchResult: Codable, Sendable {
    public let matched: Bool
    public let deepLinkId: String?
    public let clickId: String?
    public let deepLinkPath: String?
    public let parameters: [String: String]?
    public let utmSource: String?
    public let utmMedium: String?
    public let utmCampaign: String?
    public let utmTerm: String?
    public let utmContent: String?

    public init(
        matched: Bool,
        deepLinkId: String? = nil,
        clickId: String? = nil,
        deepLinkPath: String? = nil,
        parameters: [String: String]? = nil,
        utmSource: String? = nil,
        utmMedium: String? = nil,
        utmCampaign: String? = nil,
        utmTerm: String? = nil,
        utmContent: String? = nil
    ) {
        self.matched = matched
        self.deepLinkId = deepLinkId
        self.clickId = clickId
        self.deepLinkPath = deepLinkPath
        self.parameters = parameters
        self.utmSource = utmSource
        self.utmMedium = utmMedium
        self.utmCampaign = utmCampaign
        self.utmTerm = utmTerm
        self.utmContent = utmContent
    }
}
