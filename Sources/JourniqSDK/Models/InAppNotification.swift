import Foundation

/// A button action on an in-app notification.
public struct NotificationButton: Codable, Sendable {
    public let label: String
    public let style: String?
    public let actionType: String
    public let actionUrl: String?
}

/// A single in-app notification.
public struct InAppNotification: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let body: String
    public let imageUrl: String?
    public let actionUrl: String?
    public let actionType: String?
    public let buttons: [NotificationButton]?
    public let displayType: String?
    public let webpageUrl: String?
    public let data: [String: String]?
    public let read: Bool
    public let readAt: String?
    public let createdAt: String?

    public func toMap() -> [String: Any?] {
        [
            "id": id,
            "title": title,
            "body": body,
            "imageUrl": imageUrl,
            "actionUrl": actionUrl,
            "actionType": actionType,
            "buttons": buttons?.map { [
                "label": $0.label,
                "style": $0.style,
                "actionType": $0.actionType,
                "actionUrl": $0.actionUrl,
            ] },
            "displayType": displayType,
            "webpageUrl": webpageUrl,
            "data": data,
            "read": read,
            "readAt": readAt,
            "createdAt": createdAt,
        ]
    }
}

/// Paginated notifications response.
public struct NotificationsResponse: Codable, Sendable {
    public let notifications: [InAppNotification]
    public let meta: NotificationsMeta
}

public struct NotificationsMeta: Codable, Sendable {
    public let total: Int
    public let page: Int
    public let limit: Int
    public let totalPages: Int
}

/// Unread count response.
struct UnreadCountResponse: Codable {
    let count: Int
}
