import Foundation

/// What the real onboarding flow (Figma fileKey AiSKBBDDO9rIzyUPHmRm98) actually asks —
/// replacing the earlier placeholder shape, which had a single location string and a
/// "work mode" (remote/hybrid/on-site) question that doesn't exist anywhere in the real
/// flow. The real flow instead asks: what you're looking for, your career stage, up to 3
/// role interests, and a multi-select set of preferred locations (empty set = "open to any
/// location," not a blank default).
struct UserPreferences: Codable, Hashable {
    var lookingFor: LookingFor = .fullTime
    var careerStage: CareerStage?
    /// Display labels from OnboardingRoleInterest, e.g. "Backend Development" — up to 3 per
    /// the real flow's own stated limit (enforced in the UI, not here).
    var preferredRoles: Set<String> = []
    /// Empty = "open to any location," the real flow's own explicit option — not the
    /// placeholder system's "All locations" sentinel string.
    var preferredLocations: Set<String> = []

    static let empty = UserPreferences()
}

enum LookingFor: String, Codable, CaseIterable {
    case internship = "Internship"
    case fullTime = "Full-time job"
    case both = "Both"

    var subtitle: String {
        switch self {
        case .internship: "Short-term internship roles"
        case .fullTime: "Permanent full-time roles"
        case .both: "Open to both internship and full-time"
        }
    }
}

enum CareerStage: String, Codable, CaseIterable {
    case thirdYear = "3rd year student"
    case fourthYear = "4th year student"
    case recentGraduate = "Recent graduate"
    case workingProfessional = "Working professional"

    var subtitle: String {
        switch self {
        case .thirdYear: "Currently in your third year of study"
        case .fourthYear: "Currently in your final year of study"
        case .recentGraduate: "Ready to start your career"
        case .workingProfessional: "Already employed and looking for a new role"
        }
    }
}

/// The real onboarding's 9 role-interest options — a broader, umbrella taxonomy than
/// RoleCategory (Discover's filter sheet), which is deliberately more granular for filtering
/// an already-loaded feed. Keywords here drive MatchEngine's priority-alignment component,
/// not a plain substring match on the label itself — "Backend Development" as a label
/// wouldn't match a real "Backend Engineer" job title via naive containment.
struct OnboardingRoleInterest: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let keywords: [String]

    static let all: [OnboardingRoleInterest] = [
        OnboardingRoleInterest(label: "Software Engineering", keywords: ["software engineer", "software developer", "swe"]),
        OnboardingRoleInterest(label: "Data Science", keywords: ["data scientist", "data science"]),
        OnboardingRoleInterest(label: "AI / ML", keywords: ["ai engineer", "machine learning", "ml engineer", "artificial intelligence"]),
        OnboardingRoleInterest(label: "Data Analyst", keywords: ["data analyst"]),
        OnboardingRoleInterest(label: "Backend Development", keywords: ["backend"]),
        OnboardingRoleInterest(label: "Frontend Development", keywords: ["frontend", "front-end", "front end"]),
        OnboardingRoleInterest(label: "Mobile Development", keywords: ["ios ", "ios developer", "android", "mobile"]),
        OnboardingRoleInterest(label: "Cloud / DevOps", keywords: ["devops", "cloud", "site reliability", "sre"]),
        OnboardingRoleInterest(label: "Cybersecurity", keywords: ["security", "cybersecurity", "cyber security"]),
    ]

    static let preferredLocationChoices = ["Bengaluru", "Hyderabad", "Chennai", "Mumbai", "Pune", "Delhi NCR"]
}
