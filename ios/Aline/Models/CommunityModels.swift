import Foundation

/// Mirrors backend/app/community_schemas.py exactly, same wire-shape convention as Job.swift.
struct CommunityUserIdentity: Codable {
    let id: String
    let username: String
    let roleTitle: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case roleTitle = "role_title"
    }
}

struct Discussion: Codable, Identifiable, Hashable {
    let id: String
    let userID: String
    let username: String
    let roleTitle: String?
    let category: String
    let company: String?
    let title: String
    let body: String
    let createdAt: String
    var likesCount: Int
    let commentsCount: Int
    var likedByMe: Bool
    var savedByMe: Bool = false
    var topics: [String] = []

    enum CodingKeys: String, CodingKey {
        case id, username, category, company, title, body, topics
        case userID = "user_id"
        case roleTitle = "role_title"
        case createdAt = "created_at"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case likedByMe = "liked_by_me"
        case savedByMe = "saved_by_me"
    }
}

struct DiscussionComment: Codable, Identifiable, Hashable {
    let id: String
    let discussionID: String
    let userID: String
    let username: String
    let roleTitle: String?
    let body: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, username, body
        case discussionID = "discussion_id"
        case userID = "user_id"
        case roleTitle = "role_title"
        case createdAt = "created_at"
    }
}

struct DiscussionDetail: Codable {
    let discussion: Discussion
    let comments: [DiscussionComment]

    enum CodingKeys: String, CodingKey {
        case comments
    }

    init(from decoder: Decoder) throws {
        discussion = try Discussion(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        comments = try container.decode([DiscussionComment].self, forKey: .comments)
    }
}

/// Fixed set, matches backend CATEGORIES exactly (and the real Figma "Discussion type"
/// options) — fetched from /community/categories at launch rather than hardcoded twice, but
/// kept here as the Swift-side case list so UI code gets exhaustive switches.
enum DiscussionCategory: String, CaseIterable, Codable, Identifiable {
    case interviewExperience = "Interview Experience"
    case workExperience = "Work Experience"
    case recruitmentExperience = "Recruitment Experience"
    case generalDiscussion = "General Discussion"

    var id: String { rawValue }
}

/// Matches backend TOPICS exactly (the Figma filter sheet's "Topics" chips, node 887:20692).
enum DiscussionTopic: String, CaseIterable, Codable, Identifiable {
    case dsa = "DSA"
    case interviewPrep = "Interview prep"
    case workCulture = "Work culture"
    case salary = "Salary"
    case careerAdvice = "Career advice"

    var id: String { rawValue }
}

enum DiscussionSort: String, CaseIterable, Identifiable {
    case relevant, newest, liked

    var id: String { rawValue }

    var label: String {
        switch self {
        case .relevant: "Most relevant"
        case .newest: "Newest"
        case .liked: "Most liked"
        }
    }
}
