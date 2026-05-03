import Foundation

/// Analytics module for retrieving link performance data.
/// Requires secret key (`jq_app_*`).
public struct JourniqAnalytics: Sendable {

    let sdk: Journiq

    /// Get click statistics for a specific link.
    public func getLinkStats(linkId: String) async throws -> LinkStats {
        try await sdk.apiClient.getLinkStats(linkId)
    }

    /// Get app configuration and metadata from the server.
    public func getAppConfig() async throws -> AppConfig {
        try await sdk.apiClient.getAppConfig()
    }
}
