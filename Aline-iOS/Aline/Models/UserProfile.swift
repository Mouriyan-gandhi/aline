import SwiftUI

// MARK: - User Profile, Career Preferences & Achievement Gallery (Sections 10, 11, 12)
public struct UserProfile: Hashable, Codable {
    public var name: String
    /// Auto-assigned anonymous community handle. Read-only for the user.
    public let username: String
    public var titleOrStage: String
    public var education: String
    public var institution: String
    public var graduationYear: String
    public var location: String
    public var bio: String
    public var skills: [String]
    
    // Links
    public var linkedInURL: String
    public var githubURL: String
    public var portfolioURL: String

    // Work Experience & Projects
    public var experiences: [UserExperience]
    public var projects: [UserProject]
}

public struct UserExperience: Identifiable, Hashable, Codable {
    public let id: String
    public var title: String
    public var company: String
    public var location: String
    public var period: String
    public var bullets: [String]
}

public struct UserProject: Identifiable, Hashable, Codable {
    public let id: String
    public var title: String
    public var period: String
    public var techStack: String
    public var bullets: [String]
}

public struct CareerPreferences: Hashable, Codable {
    public var preferredRoles: [String]
    public var preferredCompanies: [String]
    public var preferredLocations: [String]
    public var isOpenToAnyLocation: Bool
    public var opportunityTypes: [Opportunity.OpportunityType]
    public var workArrangements: [Opportunity.WorkMode]
    public var experienceLevel: String
    public var alertsEnabled: Bool
    public var isPushAllowedByOS: Bool
}

public enum AchievementCategory: String, CaseIterable, Codable {
    case certificates = "Certificates"
    case hackathons = "Hackathons"
    case awards = "Awards"
    case internships = "Internships"
    case courses = "Courses"
    case other = "Other"

    public var iconName: String {
        switch self {
        case .certificates: return "seal.fill"
        case .hackathons: return "trophy.fill"
        case .awards: return "star.fill"
        case .internships: return "briefcase.fill"
        case .courses: return "book.closed.fill"
        case .other: return "sparkles"
        }
    }
}

public struct AchievementItem: Identifiable, Hashable, Codable {
    public let id: String
    public var title: String
    public var issuer: String
    public var category: AchievementCategory
    public var dateEarned: String
    public var descriptionText: String
    public var credentialURL: String?
    public var attachmentName: String?
}
