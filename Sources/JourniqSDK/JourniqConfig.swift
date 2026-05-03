import Foundation

/// Configuration for the Journiq SDK.
public struct JourniqConfig: Sendable {
    public let apiKey: String
    public let baseUrl: String
    public let keyType: KeyType

    public enum KeyType: Sendable {
        case `public`
        case secret
    }

    public init(apiKey: String, baseUrl: String = "https://api.getjourniq.com") {
        self.apiKey = apiKey
        self.baseUrl = baseUrl

        if apiKey.hasPrefix("jq_pub_") {
            self.keyType = .public
        } else if apiKey.hasPrefix("jq_app_") {
            self.keyType = .secret
        } else {
            fatalError("Invalid API key format. Must start with 'jq_pub_' (public) or 'jq_app_' (secret).")
        }
    }
}
