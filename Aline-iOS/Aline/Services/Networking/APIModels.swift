import Foundation

// Wire shapes for the Aline backend (backend/app/*_schemas.py, interview.py, resumes.py,
// main.py). Property names are the camelCase of the snake_case JSON keys — APIClient's coders
// convert between them, so no type here declares CodingKeys. Avoid acronym capitals in these
// names ("applyUrl", not "applyURL"): the automatic conversion can't round-trip them.

// MARK: - Jobs

struct JobDTO: Codable, Hashable {
    let id: String
    let company: String
    let platform: String
    let title: String
    var department: String = ""
    let location: String
    let applyUrl: String
    var postedAt: String?
    var extractedSkills: [String] = []
    var description: String = ""
    var minYearsExperience: Int?
    var jobType: String = "full_time"
    var workMode: String = "on_site"
    var about: String = ""
    var minimumQualifications: [String] = []
    var preferredQualifications: [String] = []
    var responsibilities: [String] = []
    var eligibleGradYears: String = ""
}

struct JobMarkDTO: Decodable {
    let jobId: String
    let liked: Bool
    let applied: Bool
    let appliedAt: String?
    let job: JobDTO?
}

/// One job scored for this user by the backend recommender (backend/app/recommend.py)
struct RecommendationDTO: Codable {
    let jobId: String
    let score: Int
    let eligible: Bool
    let level: String?
    let roleFamily: String
    let matchedSkills: [String]
    let missingSkills: [String]
    let reasons: [String]
}

struct RecommendationsDTO: Codable {
    let results: [RecommendationDTO]
    let dismissedJobIds: [String]
}

struct DismissRequest: Encodable {
    let deviceId: String
    let dismissed: Bool
}

struct JobMarkRequest: Encodable {
    let deviceId: String
    let liked: Bool?
    let applied: Bool?
}

// MARK: - Community

struct IdentityDTO: Decodable {
    let id: String
    let username: String
    let roleTitle: String?
    let avatar: String?
}

struct DiscussionDTO: Decodable {
    let id: String
    let userId: String
    let username: String
    let roleTitle: String?
    let avatar: String?
    let category: String
    let company: String?
    let title: String
    let body: String
    let createdAt: String
    let likesCount: Int
    let commentsCount: Int
    let likedByMe: Bool
    let savedByMe: Bool
    let topics: [String]
    let sharesCount: Int
    let isMine: Bool
}

struct CommentDTO: Decodable {
    let id: String
    let discussionId: String
    let userId: String
    let username: String
    let roleTitle: String?
    let avatar: String?
    let body: String
    let createdAt: String
    let parentId: String?
    let likesCount: Int
    let likedByMe: Bool
    let isMine: Bool
}

struct DiscussionDetailDTO: Decodable {
    let id: String
    let userId: String
    let username: String
    let roleTitle: String?
    let avatar: String?
    let category: String
    let company: String?
    let title: String
    let body: String
    let createdAt: String
    let likesCount: Int
    let commentsCount: Int
    let likedByMe: Bool
    let savedByMe: Bool
    let topics: [String]
    let sharesCount: Int
    let isMine: Bool
    let comments: [CommentDTO]

    var discussion: DiscussionDTO {
        DiscussionDTO(
            id: id, userId: userId, username: username, roleTitle: roleTitle, avatar: avatar, category: category,
            company: company, title: title, body: body, createdAt: createdAt, likesCount: likesCount,
            commentsCount: commentsCount, likedByMe: likedByMe, savedByMe: savedByMe, topics: topics,
            sharesCount: sharesCount, isMine: isMine
        )
    }
}

struct CreateDiscussionRequest: Encodable {
    let deviceId: String
    let category: String
    let company: String?
    let title: String
    let body: String
    let topics: [String]
}

struct CreateCommentRequest: Encodable {
    let deviceId: String
    let body: String
    let parentId: String?
}

struct CompanyCommunityDTO: Decodable {
    let name: String
    let followersCount: Int
    let postsCount: Int
    let following: Bool
}

struct NotificationDTO: Decodable {
    let id: String
    let kind: String
    let actor: String
    let actorAvatar: String?
    let postId: String
    let snippet: String
    let createdAt: String
}

struct LikedResponse: Decodable { let liked: Bool }
struct SavedResponse: Decodable { let saved: Bool }
struct FollowingResponse: Decodable { let following: Bool }
struct UpvotedResponse: Decodable { let upvoted: Bool }
struct SharesResponse: Decodable { let sharesCount: Int }

struct FeedbackRequest: Encodable {
    let deviceId: String
    let category: String
    let message: String
}

// MARK: - Interview questions

struct InterviewQuestionDTO: Decodable {
    let id: String
    let question: String
    let topic: String
    let company: String?
    let role: String?
    let difficulty: String
    let hint: String?
    let approach: String?
    let answer: String?
    let timeComplexity: String?
    let spaceComplexity: String?
    let upvotesCount: Int
    let upvotedByMe: Bool
    let savedByMe: Bool
    let isMine: Bool
    let createdAt: String
}

struct CreateQuestionRequest: Encodable {
    let deviceId: String
    let question: String
    let topic: String
    let company: String?
    let role: String?
    let difficulty: String
    let hint: String?
    let approach: String?
    let answer: String?
}

// MARK: - Profile

struct ProfileExperienceDTO: Codable {
    var id: String?
    var title: String = ""
    var organization: String = ""
    var location: String = ""
    var dateRange: String = ""
    var bullets: [String] = []
}

struct ProfileProjectDTO: Codable {
    var id: String?
    var name: String = ""
    var techStack: String = ""
    var dateRange: String = ""
    var bullets: [String] = []
}

struct AchievementDTO: Codable {
    var id: String
    var title: String = ""
    var issuer: String = ""
    var category: String = "Other"
    var dateEarned: String = ""
    var description: String = ""
    var credentialUrl: String?
    var attachmentName: String?
}

/// Career preferences as stored on the profile — the backend keeps this object verbatim.
struct PreferencesDTO: Codable {
    var preferredRoles: [String] = []
    var preferredCompanies: [String] = []
    var preferredLocations: [String] = []
    var isOpenToAnyLocation: Bool = true
    var opportunityTypes: [String] = []
    var workArrangements: [String] = []
    var experienceLevel: String = ""
    var alertsEnabled: Bool = true
}

struct ProfileDTO: Decodable {
    let username: String
    let avatar: String?
    let name: String?
    let education: String?
    let institution: String?
    let specialization: String?
    let graduationYear: Int?
    let careerStage: String?
    let linkedin: String?
    let github: String?
    let portfolio: String?
    let skills: [String]
    let experience: [ProfileExperienceDTO]
    let projects: [ProfileProjectDTO]
    let headline: String?
    let location: String?
    let bio: String?
    let achievements: [AchievementDTO]
    let preferences: PreferencesDTO?
}

/// Every field optional: the backend applies only the keys that are present, so each save
/// sends just what that screen owns.
struct ProfileUpdateRequest: Encodable {
    let deviceId: String
    var name: String?
    var education: String?
    var institution: String?
    var graduationYear: Int?
    var careerStage: String?
    var linkedin: String?
    var github: String?
    var portfolio: String?
    var skills: [String]?
    var experience: [ProfileExperienceDTO]?
    var projects: [ProfileProjectDTO]?
    var headline: String?
    var location: String?
    var bio: String?
    var achievements: [AchievementDTO]?
    var preferences: PreferencesDTO?

    init(deviceId: String) {
        self.deviceId = deviceId
    }

    // Synthesized Encodable writes nil optionals as absent keys — exactly the partial-update
    // contract the backend expects.
}

// MARK: - Resumes

struct StoredResumeDTO: Decodable {
    let id: String
    let data: ResumeRecord
    let createdAt: String
    let updatedAt: String
}

struct SaveResumeRequest: Encodable {
    let deviceId: String
    let data: ResumeRecord
}
