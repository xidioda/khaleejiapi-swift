import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Client Configuration

/// Configuration for the KhaleejiAPI client
public struct KhaleejiAPIConfig {
    /// Your API key from https://khaleejiapi.dev/dashboard/api-keys
    public let apiKey: String
    /// Base URL (default: https://khaleejiapi.dev/api/v1)
    public let baseURL: String
    /// Request timeout in seconds (default: 30)
    public let timeout: TimeInterval
    /// Maximum number of retries (default: 2)
    public let maxRetries: Int

    public init(
        apiKey: String,
        baseURL: String = "https://khaleejiapi.dev/api/v1",
        timeout: TimeInterval = 30,
        maxRetries: Int = 2
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.timeout = timeout
        self.maxRetries = maxRetries
    }
}

// MARK: - Error Types

/// Errors thrown by the KhaleejiAPI SDK
public enum KhaleejiAPIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case forbidden(String)
    case rateLimited(retryAfter: Int?)
    case badRequest(String)
    case notFound
    case serverError(Int, String)
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .unauthorized: return "Invalid or missing API key"
        case .forbidden(let msg): return "Forbidden: \(msg)"
        case .rateLimited(let retry): return "Rate limited. Retry after \(retry ?? 60) seconds"
        case .badRequest(let msg): return "Bad request: \(msg)"
        case .notFound: return "Resource not found"
        case .serverError(let code, let msg): return "Server error \(code): \(msg)"
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .decodingError(let err): return "Decoding error: \(err.localizedDescription)"
        case .invalidResponse: return "Invalid response from server"
        }
    }
}

// MARK: - Response Types

/// Standard API response wrapper
public struct APIResponse<T: Decodable>: Decodable {
    public let data: T
    public let meta: ResponseMeta
}

public struct ResponseMeta: Decodable {
    public let timestamp: String
    public let requestId: String?
}

/// Rate limit info from response headers
public struct RateLimitInfo {
    public let limit: Int
    public let remaining: Int
    public let reset: Int
}

// MARK: - Main Client

/// KhaleejiAPI Swift SDK client
///
/// ```swift
/// let client = KhaleejiAPI(apiKey: "YOUR_API_KEY")
///
/// // Validate email
/// let result = try await client.validation.validateEmail("user@example.com")
///
/// // Get exchange rates
/// let rates = try await client.finance.getExchangeRates(base: "AED")
///
/// // Convert to Hijri
/// let hijri = try await client.islamic.convertHijri(date: "2026-02-22")
/// ```
public final class KhaleejiAPI: @unchecked Sendable {
    let config: KhaleejiAPIConfig
    let session: URLSession

    /// Validation APIs (email, phone, IBAN, VAT, Emirates ID, Saudi ID)
    public lazy var validation = ValidationResource(client: self)
    /// Geolocation APIs (IP lookup, timezone, geocoding)
    public lazy var geo = GeoResource(client: self)
    /// Finance APIs (exchange rates, VAT calc, holidays, business days)
    public lazy var finance = FinanceResource(client: self)
    /// Communication APIs (translation)
    public lazy var communication = CommunicationResource(client: self)
    /// Islamic APIs (Hijri calendar, prayer times, Arabic text)
    public lazy var islamic = IslamicResource(client: self)
    /// Utility APIs (weather, QR code, URL shortener, fraud check)
    public lazy var utility = UtilityResource(client: self)

    public init(apiKey: String, baseURL: String = "https://khaleejiapi.dev/api/v1", timeout: TimeInterval = 30) {
        self.config = KhaleejiAPIConfig(apiKey: apiKey, baseURL: baseURL, timeout: timeout)
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = timeout
        sessionConfig.httpAdditionalHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "User-Agent": "KhaleejiAPI-Swift/1.1.0",
            "Accept": "application/json",
        ]
        self.session = URLSession(configuration: sessionConfig)
    }

    public init(config: KhaleejiAPIConfig) {
        self.config = config
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.timeout
        sessionConfig.httpAdditionalHeaders = [
            "Authorization": "Bearer \(config.apiKey)",
            "User-Agent": "KhaleejiAPI-Swift/1.1.0",
            "Accept": "application/json",
        ]
        self.session = URLSession(configuration: sessionConfig)
    }

    // MARK: - Internal HTTP Methods

    func get<T: Decodable>(_ path: String, params: [String: String?] = [:]) async throws -> T {
        let url = try buildURL(path, params: params)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return try await execute(request)
    }

    func post<T: Decodable>(_ path: String, body: Encodable) async throws -> T {
        let url = try buildURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        return try await execute(request)
    }

    private func buildURL(_ path: String, params: [String: String?] = [:]) throws -> URL {
        guard var components = URLComponents(string: "\(config.baseURL)\(path)") else {
            throw KhaleejiAPIError.invalidURL
        }
        let queryItems = params.compactMap { key, value -> URLQueryItem? in
            guard let v = value else { return nil }
            return URLQueryItem(name: key, value: v)
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw KhaleejiAPIError.invalidURL
        }
        return url
    }

    private func execute<T: Decodable>(_ request: URLRequest, attempt: Int = 0) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw KhaleejiAPIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw KhaleejiAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(T.self, from: data)
            } catch {
                throw KhaleejiAPIError.decodingError(error)
            }
        case 401:
            throw KhaleejiAPIError.unauthorized
        case 403:
            let msg = parseErrorMessage(data) ?? "Insufficient scope"
            throw KhaleejiAPIError.forbidden(msg)
        case 429:
            if attempt < config.maxRetries {
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                    .flatMap { Int($0) } ?? (1 << attempt)
                try await Task.sleep(nanoseconds: UInt64(retryAfter) * 1_000_000_000)
                return try await execute(request, attempt: attempt + 1)
            }
            let retryAfter = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Reset").flatMap { Int($0) }
            throw KhaleejiAPIError.rateLimited(retryAfter: retryAfter)
        case 400:
            let msg = parseErrorMessage(data) ?? "Bad request"
            throw KhaleejiAPIError.badRequest(msg)
        case 404:
            throw KhaleejiAPIError.notFound
        default:
            let msg = parseErrorMessage(data) ?? "Unknown error"
            throw KhaleejiAPIError.serverError(httpResponse.statusCode, msg)
        }
    }

    private func parseErrorMessage(_ data: Data) -> String? {
        struct ErrorBody: Decodable {
            struct ErrorDetail: Decodable {
                let message: String
            }
            let error: ErrorDetail
        }
        return try? JSONDecoder().decode(ErrorBody.self, from: data).error.message
    }
}

// MARK: - AnyEncodable Helper

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        _encode = { encoder in
            try wrapped.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
