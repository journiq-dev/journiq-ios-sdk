import Foundation
import os.log

/// Action taken by the user on a displayed in-app notification.
public enum JourniqNotificationAction: Sendable {
    case tapped
    case dismissed
}

/// Protocol for custom in-app notification display.
///
/// Implement this protocol to provide your own UI for in-app notifications.
/// The SDK will call `displayNotification(_:)` whenever a new notification
/// arrives via FCM data push. Your implementation decides how to present
/// the notification (banner, sheet, full-screen, etc.).
///
/// ```swift
/// class MyNotificationPresenter: JourniqNotificationDisplayDelegate {
///     func displayNotification(_ notification: InAppNotification) {
///         // Show your custom banner/overlay
///     }
///
///     func notificationAction(_ notification: InAppNotification, action: JourniqNotificationAction) {
///         // Handle tap or dismiss
///     }
/// }
///
/// Journiq.notifications.displayDelegate = MyNotificationPresenter()
/// ```
public protocol JourniqNotificationDisplayDelegate: AnyObject, Sendable {
    /// Called when a new in-app notification should be displayed.
    /// Implement this to show your custom notification UI.
    @MainActor
    func displayNotification(_ notification: InAppNotification)

    /// Called when the user interacts with a displayed notification.
    /// Default implementation does nothing.
    @MainActor
    func notificationAction(_ notification: InAppNotification, action: JourniqNotificationAction)
}

/// Default implementations for optional methods.
public extension JourniqNotificationDisplayDelegate {
    func notificationAction(_ notification: InAppNotification, action: JourniqNotificationAction) {}
}

/// In-app notifications module.
///
/// Provides methods to fetch, read, and listen for in-app notifications
/// delivered via FCM data-only push.
///
/// ```swift
/// // Listen for new notifications
/// for await notification in Journiq.notifications.newNotifications {
///     // Show banner
/// }
///
/// // Fetch all
/// let response = try await Journiq.notifications.getAll()
/// ```
public final class JourniqNotifications: Sendable {
    private static let logger = Logger(subsystem: "com.journiq.sdk", category: "Notifications")

    private let sdk: Journiq

    /// AsyncStream continuation for broadcasting new notifications.
    private static let streamContinuation = StreamHolder()

    /// Custom display delegate for showing in-app notification UI.
    /// Set this to your own implementation to control how notifications are presented.
    @MainActor
    public weak var displayDelegate: JourniqNotificationDisplayDelegate?

    init(sdk: Journiq) {
        self.sdk = sdk
    }

    // MARK: - Public API

    /// Fetch paginated in-app notifications for the current user.
    public func getAll(
        page: Int = 1,
        limit: Int = 20,
        unreadOnly: Bool = false
    ) async throws -> NotificationsResponse {
        guard let userId = sdk.storage.userId else {
            throw JourniqError.noIdentity
        }
        return try await sdk.apiClient.getNotifications(userId: userId, page: page, limit: limit, unreadOnly: unreadOnly)
    }

    /// Mark a notification as read.
    public func markAsRead(_ notificationId: String) async throws {
        guard let userId = sdk.storage.userId else {
            throw JourniqError.noIdentity
        }
        try await sdk.apiClient.markNotificationRead(id: notificationId, userId: userId)
    }

    /// Get the current unread count.
    public func getUnreadCount() async throws -> Int {
        guard let userId = sdk.storage.userId else {
            throw JourniqError.noIdentity
        }
        return try await sdk.apiClient.getUnreadNotificationCount(userId: userId)
    }

    /// An AsyncStream that emits new notifications when FCM data pushes arrive.
    public var newNotifications: AsyncStream<InAppNotification> {
        Self.streamContinuation.makeStream()
    }

    // MARK: - Internal

    /// Called when a silent push with type "in_app_notification" is received.
    internal func onDataPushReceived() {
        Task {
            guard let userId = sdk.storage.userId else { return }
            do {
                let response = try await sdk.apiClient.getNotifications(userId: userId, page: 1, limit: 1, unreadOnly: true)
                if let notification = response.notifications.first {
                    Self.streamContinuation.yield(notification)
                    // Invoke custom display delegate on main thread
                    await MainActor.run {
                        displayDelegate?.displayNotification(notification)
                    }
                }
            } catch {
                Self.logger.warning("Failed to fetch notification after data push: \(error.localizedDescription)")
            }
        }
    }

    /// Report a user action on a notification. Call this from your custom UI.
    @MainActor
    public func reportAction(_ notification: InAppNotification, action: JourniqNotificationAction) {
        displayDelegate?.notificationAction(notification, action: action)
    }
}

// MARK: - Stream Holder (thread-safe)

private final class StreamHolder: @unchecked Sendable {
    private var continuations: [UUID: AsyncStream<InAppNotification>.Continuation] = [:]
    private let lock = NSLock()

    func makeStream() -> AsyncStream<InAppNotification> {
        let id = UUID()
        return AsyncStream { continuation in
            lock.lock()
            continuations[id] = continuation
            lock.unlock()

            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.continuations.removeValue(forKey: id)
                self?.lock.unlock()
            }
        }
    }

    func yield(_ value: InAppNotification) {
        lock.lock()
        let conts = continuations.values
        lock.unlock()
        for cont in conts {
            cont.yield(value)
        }
    }
}
