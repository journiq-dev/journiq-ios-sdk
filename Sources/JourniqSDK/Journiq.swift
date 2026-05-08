import Foundation
import os.log

/// Main entry point for the Journiq SDK.
///
/// Initialize in your AppDelegate or App init:
/// ```swift
/// Journiq.configure(apiKey: "jq_pub_your_key_here")
/// ```
public final class Journiq: @unchecked Sendable {

    private static let logger = Logger(subsystem: "com.journiq.sdk", category: "Journiq")
    private static var shared: Journiq?

    let config: JourniqConfig
    let apiClient: ApiClient
    let fingerprint: DeviceFingerprint
    let storage: JourniqStorage
    let eventQueue: EventQueue

    private init(config: JourniqConfig) {
        self.config = config
        self.apiClient = ApiClient(config: config)
        self.fingerprint = DeviceFingerprint()
        self.storage = JourniqStorage()
        self.eventQueue = EventQueue(apiClient: apiClient, storage: storage)
        self.eventQueue.start()
    }

    // MARK: - Configuration

    /// Configure the Journiq SDK.
    /// - Parameters:
    ///   - apiKey: Your public key (`jq_pub_*`) or secret key (`jq_app_*`)
    ///   - baseUrl: Optional custom API base URL
    public static func configure(apiKey: String, baseUrl: String = "https://api.getjourniq.com") {
        let config = JourniqConfig(apiKey: apiKey, baseUrl: baseUrl)
        shared = Journiq(config: config)
        logger.info("Journiq SDK initialized (key type: \(String(describing: config.keyType)))")
    }

    /// Check if SDK is initialized.
    public static var isInitialized: Bool {
        shared != nil
    }

    // MARK: - Modules

    /// Deep link handling module.
    public static var deepLinks: JourniqDeepLinks {
        JourniqDeepLinks(sdk: current)
    }

    /// Link management module.
    public static var links: JourniqLinks {
        JourniqLinks(sdk: current)
    }

    /// Event tracking module.
    public static var events: JourniqEvents {
        JourniqEvents(sdk: current)
    }

    /// Analytics module.
    public static var analytics: JourniqAnalytics {
        JourniqAnalytics(sdk: current)
    }

    /// In-app notifications module.
    public static var notifications: JourniqNotifications {
        JourniqNotifications(sdk: current)
    }

    /// Push registration and data message handling.
    public static var push: JourniqPush {
        JourniqPush(sdk: current)
    }

    /// Call from applicationDidBecomeActive or sceneDidBecomeActive to trigger event flush.
    public static func onAppForegrounded() {
        shared?.eventQueue.onAppForegrounded()
    }

    // MARK: - Identity & User Properties

    /// Set user identity for cross-device attribution.
    /// - Parameter userId: A unique identifier for the user in your system.
    public static func setIdentity(_ userId: String) {
        let sdk = current
        sdk.storage.userId = userId
        Task {
            _ = try? await sdk.apiClient.setIdentity(SetIdentityRequest(userId: userId))
        }
    }

    /// Clear user identity (logout).
    public static func logout() {
        current.storage.userId = nil
        JourniqAttribution.clear()
    }

    /// Set custom properties on the current user's profile.
    /// Properties are merged with existing values. Set a value to `nil` to remove it.
    /// - Parameter properties: Key-value pairs to set on the user profile.
    public static func setUserProperties(_ properties: [String: Any?]) async throws {
        let sdk = current
        guard let userId = sdk.storage.userId else {
            logger.warning("setUserProperties called without a user identity. Call setIdentity first.")
            return
        }
        let codableProps = properties.mapValues { AnyCodable($0) }
        let request = SetUserPropertiesRequest(userId: userId, properties: codableProps)
        _ = try await sdk.apiClient.setUserProperties(request)
    }

    // MARK: - Internal

    static var current: Journiq {
        guard let sdk = shared else {
            fatalError("Journiq SDK not initialized. Call Journiq.configure(apiKey:) first.")
        }
        return sdk
    }
}
