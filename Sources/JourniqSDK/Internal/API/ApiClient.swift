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
        encoder.keyEncodingStrategy = .convertToSnakeCase

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: - Public Endpoints

    func matchDeferredLink(_ request: MatchRequest) async throws -> MatchResult {
        return try await post("/v1/sdk/deferred-links/match", body: request)
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

    // MARK: - HTTP Helpers

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = try buildURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
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
        return try decoder.decode(T.self, from: data)
    }

    private func applyHeaders(_ request: inout URLRequest) {
        request.setValue(config.apiKey, forHTTPHeaderField: "X-Journiq-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("JourniqSDK-iOS/0.1.0", forHTTPHeaderField: "User-Agent")
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
    case invalidURL(String)
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case encodingError(String)

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Journiq SDK not initialized. Call Journiq.configure(apiKey:) first."
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
