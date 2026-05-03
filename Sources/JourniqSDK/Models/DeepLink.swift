import Foundation

/// A Journiq deep link.
public struct DeepLink: Codable, Sendable {
    public let id: String
    public let appId: String
    public let organizationId: String
    public let shortCode: String
    public let shortUrl: String
    public let webUrl: String
    public let title: String?
    public let description: String?
    public let deepLinkPath: String?
    public let parameters: [String: String]?
    public let utmSource: String?
    public let utmMedium: String?
    public let utmCampaign: String?
    public let utmTerm: String?
    public let utmContent: String?
    public let status: String
    public let totalClicks: Int?
    public let uniqueClicks: Int?
    public let createdAt: String
    public let updatedAt: String
}
