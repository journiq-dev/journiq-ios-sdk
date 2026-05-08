import Foundation
import UIKit

/// Collects device fingerprint data for deferred deep link matching.
final class DeviceFingerprint: @unchecked Sendable {

    var osVersion: String {
        UIDevice.current.systemVersion
    }

    var userAgent: String {
        "iOS/\(UIDevice.current.systemVersion) (\(UIDevice.current.model))"
    }

    var screenWidth: Int {
        Int(UIScreen.main.bounds.width * UIScreen.main.scale)
    }

    var screenHeight: Int {
        Int(UIScreen.main.bounds.height * UIScreen.main.scale)
    }

    /// IANA timezone identifier (e.g. "America/New_York").
    var timezone: String {
        TimeZone.current.identifier
    }

    /// Base language code (e.g. "en"). Falls back to the first component of the locale identifier.
    var language: String? {
        if #available(iOS 16, *) {
            return Locale.current.language.languageCode?.identifier
        }
        return Locale.current.languageCode
    }

    /// ISO region code (e.g. "US"). Locale-derived; not GPS.
    var country: String? {
        if #available(iOS 16, *) {
            return Locale.current.region?.identifier
        }
        return Locale.current.regionCode
    }

    /// Hardware model identifier (e.g. "iPhone15,3"). Server buckets to family ("iPhone").
    var deviceModel: String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let mirror = Mirror(reflecting: sysinfo.machine)
        let identifier = mirror.children.reduce(into: "") { acc, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            acc.append(String(UnicodeScalar(UInt8(value))))
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }

    /// Reads a Journiq clipboard token (format `jq:<uuid>`) from the system pasteboard.
    /// Returns the token (without the prefix) and clears the pasteboard so it cannot be reused.
    /// NOTE: Reading `UIPasteboard.general.string` triggers the iOS "Pasted from <app>" toast on
    /// iOS 14+. This is unavoidable and matches the behaviour of other attribution SDKs.
    @MainActor
    func consumeClipboardToken() -> String? {
        let pasteboard = UIPasteboard.general
        guard pasteboard.hasStrings, let raw = pasteboard.string else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("jq:") else { return nil }
        let token = String(trimmed.dropFirst(3))
        // UUID is 36 chars; allow a small tolerance for safety.
        guard token.count >= 32, token.count <= 64 else { return nil }
        pasteboard.string = ""
        return token
    }

    /// Fetches the device's public IP address via api.ipify.org.
    func getPublicIPAddress() async -> String {
        guard let url = URL(string: "https://api.ipify.org") else { return "" }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return ""
        }
    }
}
