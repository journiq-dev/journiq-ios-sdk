import Foundation

// MARK: - Internal API DTOs

struct MatchRequest: Encodable {
    let ipAddress: String
    let userAgent: String
    let osVersion: String
    let screenWidth: Int
    let screenHeight: Int
    let platform: String = "ios"
    let installReferrer: String?
}

struct BatchEventsRequest: Encodable {
    let events: [EventItem]
}

struct EventItem: Encodable {
    let eventName: String
    let deepLinkId: String?
    let metadata: [String: String]?
    let occurredAt: String
}

struct ApiResponse<T: Decodable>: Decodable {
    let data: T?
    let message: String?
    let statusCode: Int?
}

struct BatchResult: Decodable {
    let accepted: Int
    let rejected: Int
}

struct EventCreatedResult: Decodable {
    let id: String
}
