import Foundation

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

    func clear() {
        Keys.all.forEach { defaults.removeObject(forKey: $0) }
    }

    private enum Keys {
        static let deferredChecked = "journiq_deferred_checked"
        static let lastFlush = "journiq_last_flush"
        static let userId = "journiq_user_id"
        static let all = [deferredChecked, lastFlush, userId]
    }
}
