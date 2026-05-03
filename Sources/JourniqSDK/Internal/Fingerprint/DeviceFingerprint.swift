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
