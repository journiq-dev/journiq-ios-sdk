import Foundation

/// Link management (create, list, get).
public struct JourniqLinks: Sendable {

    let sdk: Journiq

    /// Create a new deep link. Requires secret key (`jq_app_*`).
    public func create(_ request: LinkCreateRequest) async throws -> DeepLink {
        try await sdk.apiClient.createLink(request)
    }

    /// List deep links for the app. Requires secret key (`jq_app_*`).
    public func list(page: Int = 1, limit: Int = 20) async throws -> [DeepLink] {
        try await sdk.apiClient.listLinks(page: page, limit: limit)
    }

    /// Get a single deep link by ID. Requires secret key (`jq_app_*`).
    public func get(linkId: String) async throws -> DeepLink {
        try await sdk.apiClient.getLink(linkId)
    }
}
