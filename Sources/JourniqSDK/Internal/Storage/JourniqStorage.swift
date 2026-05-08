import Foundation
import Security

/// Simple UserDefaults-backed storage for SDK state.
final class JourniqStorage: @unchecked Sendable {

    private let defaults: UserDefaults

    init() {
        self.defaults = UserDefaults(suiteName: "com.journiq.sdk") ?? .standard
    }

    var deferredLinkChecked: Bool {
        get { defaults.bool(forKey: Keys.deferredChecked) }
        set { defaults.set(newValue, forKey: Keys.deferredChecked) }
    }

    var lastFlushTime: Date {
        get { Date(timeIntervalSince1970: defaults.double(forKey: Keys.lastFlush)) }
        set { defaults.set(newValue.timeIntervalSince1970, forKey: Keys.lastFlush) }
    }

    var userId: String? {
        get { defaults.string(forKey: Keys.userId) }
        set { defaults.set(newValue, forKey: Keys.userId) }
    }

    /// A stable per-install identifier. Stored in the Keychain
    /// (kSecAttrAccessibleAfterFirstUnlock) so it survives app uninstall
    /// and reinstall on the same device — letting the server replace the
    /// old (now-dead) FCM token instead of accumulating a duplicate.
    /// Falls back to UserDefaults if Keychain access fails (e.g. tests).
    var deviceId: String {
        if let existing = readKeychainDeviceId() {
            return existing
        }
        if let legacy = defaults.string(forKey: Keys.deviceId) {
            // Migrate any pre-Keychain value into the Keychain.
            _ = writeKeychainDeviceId(legacy)
            return legacy
        }
        let fresh = UUID().uuidString
        if !writeKeychainDeviceId(fresh) {
            defaults.set(fresh, forKey: Keys.deviceId)
        }
        return fresh
    }

    func clear() {
        Keys.all.forEach { defaults.removeObject(forKey: $0) }
        // Note: deviceId in Keychain is intentionally NOT cleared on logout
        // so a re-login on the same physical device dedups against the
        // existing token entry.
    }

    private enum Keys {
        static let deferredChecked = "journiq_deferred_checked"
        static let lastFlush = "journiq_last_flush"
        static let userId = "journiq_user_id"
        static let deviceId = "journiq_device_id"
        static let all = [deferredChecked, lastFlush, userId]
    }

    // MARK: - Keychain

    private static let keychainService = "com.journiq.sdk"
    private static let keychainAccount = "device_id"

    private func readKeychainDeviceId() -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func writeKeychainDeviceId(_ value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        // Try add first; if a stale entry exists, update it.
        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        if addStatus == errSecSuccess { return true }
        if addStatus == errSecDuplicateItem {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Self.keychainService,
                kSecAttrAccount as String: Self.keychainAccount,
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
            return updateStatus == errSecSuccess
        }
        return false
    }
}
