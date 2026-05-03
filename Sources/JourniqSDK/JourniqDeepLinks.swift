import Foundation

/// Deferred deep link handling.
public struct JourniqDeepLinks: Sendable {

    let sdk: Journiq

    /// Check for a deferred deep link (first launch only).
    ///
    /// Collects device fingerprint and calls the match endpoint.
    /// Only runs once per install.
    public func checkDeferredDeepLink() async -> MatchResult {
        guard !sdk.storage.deferredLinkChecked else {
            return MatchResult(matched: false)
        }

        do {
            let ip = await sdk.fingerprint.getPublicIPAddress()

            let request = MatchRequest(
                ipAddress: ip,
                userAgent: sdk.fingerprint.userAgent,
                osVersion: sdk.fingerprint.osVersion,
                screenWidth: sdk.fingerprint.screenWidth,
                screenHeight: sdk.fingerprint.screenHeight,
                installReferrer: nil
            )

            let result: MatchResult = try await sdk.apiClient.matchDeferredLink(request)
            sdk.storage.deferredLinkChecked = true
            return result
        } catch {
            return MatchResult(matched: false)
        }
    }

    /// Parse a deep link URL (Universal Link / custom scheme).
    ///
    /// - Parameter url: The incoming URL
    /// - Returns: Parsed deep link path and query parameters, or nil
    public func handleURL(_ url: URL) -> ParsedDeepLink? {
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let params = (components?.queryItems ?? []).reduce(into: [String: String]()) { dict, item in
            dict[item.name] = item.value ?? ""
        }
        return ParsedDeepLink(path: path, parameters: params, url: url)
    }
}

/// A parsed deep link from an incoming URL.
public struct ParsedDeepLink: Sendable {
    public let path: String
    public let parameters: [String: String]
    public let url: URL
}
