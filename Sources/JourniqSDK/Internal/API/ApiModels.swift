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

struct SetIdentityRequest: Encodable {
    let userId: String
}

struct SetUserPropertiesRequest: Encodable {
    let userId: String
    let properties: [String: AnyCodable]
}

struct SuccessResponse: Decodable {
    let success: Bool
    let message: String?
}

/// A type-erased Codable wrapper for arbitrary JSON values.
struct AnyCodable: Encodable {
    let value: Any?

    init(_ value: Any?) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case nil:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any?]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any?]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
