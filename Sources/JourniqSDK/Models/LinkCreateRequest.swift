import Foundation

/// Request to create a new deep link.
public struct LinkCreateRequest: Codable, Sendable {
    public let webUrl: String
    public let title: String?
    public let description: String?
    public let deepLinkPath: String?
    public let customShortCode: String?
    public let domain: String?
    public let parameters: [String: String]?
    public let utmSource: String?
    public let utmMedium: String?
    public let utmCampaign: String?
    public let utmTerm: String?
    public let utmContent: String?

    public init(
        webUrl: String,
        title: String? = nil,
        description: String? = nil,
        deepLinkPath: String? = nil,
        customShortCode: String? = nil,
        domain: String? = nil,
        parameters: [String: String]? = nil,
        utmSource: String? = nil,
        utmMedium: String? = nil,
        utmCampaign: String? = nil,
        utmTerm: String? = nil,
        utmContent: String? = nil
    ) {
        self.webUrl = webUrl
        self.title = title
        self.description = description
        self.deepLinkPath = deepLinkPath
        self.customShortCode = customShortCode
        self.domain = domain
        self.parameters = parameters
        self.utmSource = utmSource
        self.utmMedium = utmMedium
        self.utmCampaign = utmCampaign
        self.utmTerm = utmTerm
        self.utmContent = utmContent
    }
}
