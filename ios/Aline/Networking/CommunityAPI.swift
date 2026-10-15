import Foundation

enum CommunityAPIError: Error {
    case badResponse
}

struct CommunityAPI {
    static let baseURL = JobsAPI.baseURL

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }

    private static func request(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CommunityAPIError.badResponse
        }
        return data
    }

    private static func get(_ path: String, query: [URLQueryItem]) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = query
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CommunityAPIError.badResponse
        }
        return data
    }

    private static func post(_ path: String, query: [URLQueryItem]) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = query
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CommunityAPIError.badResponse
        }
        return data
    }

    static func identity(roleTitle: String? = nil) async throws -> CommunityUserIdentity {
        let data = try await request(
            "community/identity", method: "POST",
            body: IdentityRequestBody(deviceID: DeviceIdentity.deviceID, roleTitle: roleTitle)
        )
        return try decode(CommunityUserIdentity.self, from: data)
    }

    static func categories() async throws -> [String] {
        try await decode([String].self, from: request("community/categories"))
    }

    static func topics() async throws -> [String] {
        try await decode([String].self, from: request("community/topics"))
    }

    static func discussions(
        category: DiscussionCategory? = nil,
        sort: DiscussionSort = .newest,
        companies: [String] = [],
        topics: [String] = [],
        onlySaved: Bool = false
    ) async throws -> [Discussion] {
        var items = [
            URLQueryItem(name: "device_id", value: DeviceIdentity.deviceID),
            URLQueryItem(name: "sort", value: sort.rawValue),
        ]
        if let category {
            items.append(URLQueryItem(name: "category", value: category.rawValue))
        }
        items.append(contentsOf: companies.map { URLQueryItem(name: "companies", value: $0) })
        items.append(contentsOf: topics.map { URLQueryItem(name: "topics", value: $0) })
        if onlySaved {
            items.append(URLQueryItem(name: "only_saved", value: "true"))
        }
        return try await decode([Discussion].self, from: get("community/discussions", query: items))
    }

    static func createDiscussion(category: DiscussionCategory, company: String?, title: String, body: String, topics: [String] = []) async throws -> Discussion {
        let data = try await request(
            "community/discussions", method: "POST",
            body: CreateDiscussionBody(
                deviceID: DeviceIdentity.deviceID, category: category.rawValue, company: company, title: title, body: body, topics: topics
            )
        )
        return try decode(Discussion.self, from: data)
    }

    static func discussionDetail(id: String) async throws -> DiscussionDetail {
        try await decode(
            DiscussionDetail.self,
            from: get("community/discussions/\(id)", query: [URLQueryItem(name: "device_id", value: DeviceIdentity.deviceID)])
        )
    }

    static func addComment(discussionID: String, body: String) async throws -> DiscussionComment {
        let data = try await request(
            "community/discussions/\(discussionID)/comments", method: "POST",
            body: CreateCommentBody(deviceID: DeviceIdentity.deviceID, body: body)
        )
        return try decode(DiscussionComment.self, from: data)
    }

    @discardableResult
    static func toggleLike(discussionID: String) async throws -> Bool {
        let data = try await post(
            "community/discussions/\(discussionID)/like",
            query: [URLQueryItem(name: "device_id", value: DeviceIdentity.deviceID)]
        )
        return try decode(LikeResponseBody.self, from: data).liked
    }

    @discardableResult
    static func toggleSave(discussionID: String) async throws -> Bool {
        let data = try await post(
            "community/discussions/\(discussionID)/save",
            query: [URLQueryItem(name: "device_id", value: DeviceIdentity.deviceID)]
        )
        return try decode(SavedResponseBody.self, from: data).saved
    }

    static func savedDiscussionIDs() async throws -> [String] {
        try await decode(
            [String].self,
            from: get("community/saved", query: [URLQueryItem(name: "device_id", value: DeviceIdentity.deviceID)])
        )
    }

    static func followedCompanies() async throws -> [String] {
        try await decode(
            [String].self,
            from: get("community/following", query: [URLQueryItem(name: "device_id", value: DeviceIdentity.deviceID)])
        )
    }

    @discardableResult
    static func toggleFollowCompany(_ company: String) async throws -> Bool {
        let encoded = company.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? company
        let data = try await post(
            "community/following/\(encoded)",
            query: [URLQueryItem(name: "device_id", value: DeviceIdentity.deviceID)]
        )
        return try decode(FollowedResponseBody.self, from: data).following
    }

    static func submitFeedback(category: String, message: String) async throws {
        _ = try await request(
            "feedback", method: "POST",
            body: FeedbackBody(deviceID: DeviceIdentity.deviceID, category: category, message: message)
        )
    }
}

private struct IdentityRequestBody: Encodable {
    let deviceID: String
    let roleTitle: String?
    enum CodingKeys: String, CodingKey { case deviceID = "device_id", roleTitle = "role_title" }
}

private struct CreateDiscussionBody: Encodable {
    let deviceID: String
    let category: String
    let company: String?
    let title: String
    let body: String
    let topics: [String]
    enum CodingKeys: String, CodingKey { case deviceID = "device_id", category, company, title, body, topics }
}

private struct CreateCommentBody: Encodable {
    let deviceID: String
    let body: String
    enum CodingKeys: String, CodingKey { case deviceID = "device_id", body }
}

private struct FeedbackBody: Encodable {
    let deviceID: String
    let category: String
    let message: String
    enum CodingKeys: String, CodingKey { case deviceID = "device_id", category, message }
}

private struct LikeResponseBody: Decodable {
    let liked: Bool
}

private struct SavedResponseBody: Decodable {
    let saved: Bool
}

private struct FollowedResponseBody: Decodable {
    let following: Bool
}

/// Type-erasure box so `request(_:method:body:)` can take any Encodable without generic
/// propagation through every call site.
private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    init<T: Encodable>(_ wrapped: T) {
        encodeClosure = wrapped.encode
    }
    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
