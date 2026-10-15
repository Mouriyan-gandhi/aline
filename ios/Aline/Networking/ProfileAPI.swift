import Foundation

struct ProfileAPI {
    static let baseURL = JobsAPI.baseURL

    static func fetch() async throws -> UserProfileData {
        var components = URLComponents(url: baseURL.appendingPathComponent("profile"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "device_id", value: DeviceIdentity.deviceID)]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CommunityAPIError.badResponse
        }
        return try JSONDecoder().decode(UserProfileData.self, from: data)
    }

    static func update(_ profile: UserProfileData) async throws -> UserProfileData {
        var request = URLRequest(url: baseURL.appendingPathComponent("profile"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ProfileUpdateBody(deviceID: DeviceIdentity.deviceID, profile: profile))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CommunityAPIError.badResponse
        }
        return try JSONDecoder().decode(UserProfileData.self, from: data)
    }

    /// Full account deletion — see backend/app/community_db.py's delete_account docstring for
    /// the cascade (discussions/comments/likes/saves/follows all go too, not just the profile
    /// row). The device still holds the same UUID afterward, so posting again just creates a
    /// brand new identity with a fresh username — this does not "unregister" the device.
    static func deleteAccount() async throws {
        var components = URLComponents(url: baseURL.appendingPathComponent("profile"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "device_id", value: DeviceIdentity.deviceID)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CommunityAPIError.badResponse
        }
    }
}

private struct ProfileUpdateBody: Encodable {
    let deviceID: String
    let profile: UserProfileData

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case name, education, institution, specialization, linkedin, github, portfolio
        case graduationYear = "graduation_year"
        case careerStage = "career_stage"
        case skills, experience, projects
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceID, forKey: .deviceID)
        try container.encodeIfPresent(profile.name, forKey: .name)
        try container.encodeIfPresent(profile.education, forKey: .education)
        try container.encodeIfPresent(profile.institution, forKey: .institution)
        try container.encodeIfPresent(profile.specialization, forKey: .specialization)
        try container.encodeIfPresent(profile.graduationYear, forKey: .graduationYear)
        try container.encodeIfPresent(profile.careerStage, forKey: .careerStage)
        try container.encodeIfPresent(profile.linkedin, forKey: .linkedin)
        try container.encodeIfPresent(profile.github, forKey: .github)
        try container.encodeIfPresent(profile.portfolio, forKey: .portfolio)
        try container.encode(profile.skills, forKey: .skills)
        try container.encode(profile.experience, forKey: .experience)
        try container.encode(profile.projects, forKey: .projects)
    }
}
