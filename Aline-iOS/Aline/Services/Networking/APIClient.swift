import Foundation

/// The device-scoped identity every backend call is made under — a UUID generated once and
/// persisted locally, sent as `device_id`. The backend maps it to one user row holding the
/// anonymous community handle, the profile, resumes and job marks (see
/// backend/app/community_db.py's module docstring). There is no real sign-in yet, so this is
/// the whole identity until auth lands.
enum DeviceIdentity {
    private static let deviceIDKey = "communityDeviceID"

    static var deviceID: String {
        if let existing = UserDefaults.standard.string(forKey: deviceIDKey) {
            return existing
        }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: deviceIDKey)
        return fresh
    }

    /// A deleted account starts over as a brand-new identity on next use.
    static func reset() {
        UserDefaults.standard.removeObject(forKey: deviceIDKey)
    }
}

enum APIError: Error {
    case badStatus(Int)
    case badURL
}

/// Thin JSON-over-HTTP client for the Aline backend. Snake_case on the wire, camelCase in
/// Swift, converted by the shared coders — DTOs never spell out CodingKeys.
enum APIClient {
    /// Deployed on Render's free tier. Override with the `ALINE_API_BASE_URL` environment
    /// variable (Xcode scheme → Run → Arguments) to point a debug build at a local backend.
    static let baseURL: URL = {
        if let override = ProcessInfo.processInfo.environment["ALINE_API_BASE_URL"],
           let url = URL(string: override) {
            return url
        }
        return URL(string: "https://aline-backend-wdp6.onrender.com")!
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    static func url(_ path: String, query: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.badURL
        }
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { throw APIError.badURL }
        return url
    }

    /// `device_id` plus any extra items — nearly every endpoint is scoped to the device.
    static func deviceQuery(_ extra: [URLQueryItem] = []) -> [URLQueryItem] {
        [URLQueryItem(name: "device_id", value: DeviceIdentity.deviceID)] + extra
    }

    static func get<T: Decodable>(_ path: String, query: [URLQueryItem] = [], timeout: TimeInterval = 60) async throws -> T {
        try await send(path, method: "GET", query: query, body: Optional<Int>.none, timeout: timeout)
    }

    static func post<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        try await send(path, method: "POST", query: query, body: Optional<Int>.none)
    }

    static func send<T: Decodable, Body: Encodable>(
        _ path: String, method: String, query: [URLQueryItem] = [], body: Body?, timeout: TimeInterval = 60
    ) async throws -> T {
        let data = try await raw(path, method: method, query: query, body: body, timeout: timeout)
        return try decoder.decode(T.self, from: data)
    }

    @discardableResult
    static func raw<Body: Encodable>(
        _ path: String, method: String, query: [URLQueryItem] = [], body: Body?, timeout: TimeInterval = 60
    ) async throws -> Data {
        var request = URLRequest(url: try url(path, query: query))
        request.httpMethod = method
        request.timeoutInterval = timeout
        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
        guard (200...299).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
        return data
    }

    static func delete(_ path: String, query: [URLQueryItem] = []) async throws {
        try await raw(path, method: "DELETE", query: query, body: Optional<Int>.none)
    }
}

/// For endpoints whose response body carries nothing the app needs.
struct EmptyResponse: Decodable {}
