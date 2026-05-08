import Foundation

/// HTTP client for the Journiq API. Uses only URLSession (zero external deps).
final class ApiClient: @unchecked Sendable {

    private let config: JourniqConfig
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(config: JourniqConfig) {
        self.config = config

        let urlConfig = URLSessionConfiguration.default
        urlConfig.timeoutIntervalForRequest = 30
        urlConfig.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: urlConfig)

        self.encoder = JSONEncoder()

        self.decoder = JSONDecoder()
    }

    // MARK: - Public Endpoints

    func matchDeferredLink(_ request: MatchRequest) async throws -> MatchResult {
        return try await post("/v1/sdk/deferred-links/match", body: request)
    }

    func resolveLink(_ request: ResolveLinkRequest) async throws -> ResolvedLink {
        return try await post("/v1/sdk/links/resolve", body: request)
    }

    func createLink(_ request: LinkCreateRequest) async throws -> DeepLink {
        return try await post("/v1/sdk/links", body: request)
    }

    func listLinks(page: Int, limit: Int) async throws -> [DeepLink] {
        return try await get("/v1/sdk/links?page=\(page)&limit=\(limit)")
    }

    func getLink(_ linkId: String) async throws -> DeepLink {
        return try await get("/v1/sdk/links/\(linkId)")
    }

    func getLinkStats(_ linkId: String) async throws -> LinkStats {
        return try await get("/v1/sdk/links/\(linkId)/stats")
    }

    func trackEvent(_ event: EventItem) async throws -> EventCreatedResult {
        return try await post("/v1/sdk/events", body: event)
    }

    func trackEventsBatch(_ events: [EventItem]) async throws -> BatchResult {
        let body = BatchEventsRequest(events: events)
        return try await post("/v1/sdk/events/batch", body: body)
    }

    func getAppConfig() async throws -> AppConfig {
        return try await get("/v1/sdk/app")
    }

    func setIdentity(_ request: SetIdentityRequest) async throws -> SuccessResponse {
        return try await post("/v1/sdk/identity", body: request)
    }

    func setUserProperties(_ request: SetUserPropertiesRequest) async throws -> SuccessResponse {
        return try await post("/v1/sdk/user-properties", body: request)
    }

    // MARK: - Notifications

    func getNotifications(userId: String, page: Int = 1, limit: Int = 20, unreadOnly: Bool = false) async throws -> NotificationsResponse {
        var path = "/v1/sdk/notifications?userId=\(userId)&page=\(page)&limit=\(limit)"
        if unreadOnly { path += "&unreadOnly=true" }
        return try await get(path)
    }

    func markNotificationRead(id: String, userId: String) async throws {
        let url = try buildURL("/v1/sdk/notifications/\(id)/read")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request)
        request.httpBody = try encoder.encode(["userId": userId])

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    func markNotificationClicked(id: String, userId: String) async throws {
        let url = try buildURL("/v1/sdk/notifications/\(id)/clicked")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request)
        request.httpBody = try encoder.encode(["userId": userId])

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    func reportPushClick(
        userId: String,
        campaignId: String?,
        automationId: String?,
        notificationMessageId: String?,
    ) async throws {
        struct PushClickRequest: Encodable {
            let userId: String
            let campaignId: String?
            let automationId: String?
            let notificationMessageId: String?
        }
        let _: SuccessResponse = try await post(
            "/v1/sdk/notifications/click",
            body: PushClickRequest(
                userId: userId,
                campaignId: campaignId,
                automationId: automationId,
                notificationMessageId: notificationMessageId,
            )
        )
    }

    func getUnreadNotificationCount(userId: String) async throws -> Int {
        let response: UnreadCountResponse = try await get("/v1/sdk/notifications/unread-count?userId=\(userId)")
        return response.count
    }

    // MARK: - Push Token

    func registerDeviceToken(userId: String, token: String, platform: String) async throws {
        struct TokenRequest: Encodable {
            let userId: String
            let token: String
            let platform: String
        }
        let _: SuccessResponse = try await post("/v1/sdk/device-token", body: TokenRequest(userId: userId, token: token, platform: platform))
    }

    // MARK: - HTTP Helpers

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = try buildURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try decodeUnwrapping(data)
    }

    private func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        let url = try buildURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request)
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try decodeUnwrapping(data)
    }

    /// Attempts to decode from `{ data: T }` wrapper first, then falls back to direct decode.
    private func decodeUnwrapping<T: Decodable>(_ data: Data) throws -> T {
        if let wrapped = try? decoder.decode(ApiResponse<T>.self, from: data),
           let unwrapped = wrapped.data {
            return unwrapped
        }
        return try decoder.decode(T.self, from: data)
    }

    private func applyHeaders(_ request: inout URLRequest) {
        request.setValue(config.apiKey, forHTTPHeaderField: "X-Journiq-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("JourniqSDK-iOS/0.2.0", forHTTPHeaderField: "User-Agent")
    }

    private func buildURL(_ path: String) throws -> URL {
        guard let url = URL(string: config.baseUrl + path) else {
            throw JourniqError.invalidURL(path)
        }
        return url
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JourniqError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw JourniqError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

/// Errors thrown by the Journiq SDK.
public enum JourniqError: Error, LocalizedError {
    case notInitialized
    case noIdentity
    case invalidURL(String)
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case encodingError(String)

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Journiq SDK not initialized. Call Journiq.configure(apiKey:) first."
        case .noIdentity:
            return "No user identity set. Call Journiq.setIdentity() first."
        case .invalidURL(let path):
            return "Invalid URL: \(path)"
        case .invalidResponse:
            return "Invalid response from server."
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .encodingError(let detail):
            return "Encoding error: \(detail)"
        }
    }
}
