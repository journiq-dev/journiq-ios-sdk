import Foundation

/// App configuration from the server.
public struct AppConfig: Codable, Sendable {
    public let id: String
    public let name: String
    public let platform: String
    public let bundleId: String?
    public let packageName: String?
    public let iosUrlScheme: String?
    public let androidUrlScheme: String?
    public let appStoreUrl: String?
    public let playStoreUrl: String?
    public let websiteUrl: String?
}

/// Link click statistics.
public struct LinkStats: Codable, Sendable {
    public let totalClicks: Int
    public let uniqueClicks: Int
    public let dailyClicks: [DailyClick]?
}

/// Daily click count entry.
public struct DailyClick: Codable, Sendable {
    public let date: String
    public let clicks: Int
    public let uniqueClicks: Int
}
