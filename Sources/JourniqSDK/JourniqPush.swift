import Foundation
import os.log

/// Push registration and data message handling.
///
/// ```swift
/// // In AppDelegate:
/// func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
///     Journiq.push.registerAPNsToken(deviceToken)
/// }
///
/// // When receiving a silent push:
/// func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
///     if Journiq.push.handleDataMessage(userInfo) { return .newData }
///     return .noData
/// }
/// ```
public final class JourniqPush: Sendable {
    private static let logger = Logger(subsystem: "com.journiq.sdk", category: "Push")

    private let sdk: Journiq

    init(sdk: Journiq) {
        self.sdk = sdk
    }

    // MARK: - Token Registration

    /// Register an FCM token with the Journiq backend.
    public func registerFCMToken(_ token: String) {
        guard let userId = sdk.storage.userId else {
            Self.logger.warning("Cannot register token without user identity")
            return
        }

        Task {
            do {
                try await sdk.apiClient.registerDeviceToken(userId: userId, token: token, platform: "ios", deviceId: sdk.storage.deviceId)
                Self.logger.debug("FCM token registered")
            } catch {
                Self.logger.warning("Failed to register FCM token: \(error.localizedDescription)")
            }
        }
    }

    /// Register an APNs device token (converts to hex string) with the Journiq backend.
    public func registerAPNsToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        registerFCMToken(token)
    }

    // MARK: - Data Message Handling

    /// Handle an incoming silent/data push notification.
    /// Returns `true` if the message was handled by Journiq SDK.
    @discardableResult
    public func handleDataMessage(_ userInfo: [AnyHashable: Any]) -> Bool {
        guard let type = userInfo["type"] as? String else { return false }

        switch type {
        case "in_app_notification":
            Journiq.notifications.onDataPushReceived()
            return true
        default:
            return false
        }
    }
}
