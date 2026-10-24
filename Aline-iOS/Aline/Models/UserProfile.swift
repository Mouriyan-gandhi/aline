import SwiftUI

// MARK: - User Profile, Career Preferences & Achievement Gallery (Sections 10, 11, 12)
public struct UserProfile: Hashable {
    public var name: String
    public var titleOrStage: String
    public var education: String
    public var institution: String
    public var graduationYear: String
    public var location: String
    public var opportunityAvailability: String
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

public struct UserExperience: Identifiable, Hashable {
    public let id: String
    public var title: String
    public var company: String
    public var location: String
    public var period: String
    public var bullets: [String]
}

public struct UserProject: Identifiable, Hashable {
    public let id: String
    public var title: String
    public var period: String
    public var techStack: String
    public var bullets: [String]
}

public struct CareerPreferences: Hashable {
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

public struct AchievementItem: Identifiable, Hashable {
    public let id: String
    public var title: String
    public var issuer: String
    public var category: AchievementCategory
    public var dateEarned: String
    public var descriptionText: String
    public var credentialURL: String?
    public var attachmentName: String?
}

public extension UserProfile {
    static let sample = UserProfile(
        name: "Aarav Sharma",
        titleOrStage: "3rd Year CS Student",
        education: "B.Tech in Computer Science & Engineering",
        institution: "National Institute of Technology",
        graduationYear: "2028",
        location: "Bengaluru, India",
        opportunityAvailability: "Summer 2026 Internships",
        bio: "Aspiring Software Engineer passionate about high-performance iOS systems, algorithms, and microservice infrastructure.",
        skills: ["Swift", "SwiftUI", "C++", "Java", "Python", "Data Structures", "Algorithms", "Git"],
        linkedInURL: "linkedin.com/in/aarav-cs",
        githubURL: "github.com/aarav-dev",
        portfolioURL: "aarav.dev",
        experiences: [
            UserExperience(
                id: "uexp-1",
                title: "Software Engineering Intern",
                company: "Campus Tech Labs",
                location: "Bengaluru, India",
                period: "May 2026 – Jul 2026",
                bullets: [
                    "Engineered real-time telemetry pipelines handling 50+ IoT nodes.",
                    "Improved query efficiency by 32% using indexing and connection pooling."
                ]
            )
        ],
        projects: [
            UserProject(
                id: "uproj-1",
                title: "Aline Career Experience",
                period: "Aug 2026 – Present",
                techStack: "Swift, SwiftUI, Combine",
                bullets: [
                    "Engineered an interactive stacked card discovery UI with spring physics.",
                    "Built full offline cache support and resume match diff viewer."
                ]
            )
        ]
    )
}

public extension CareerPreferences {
    static let sample = CareerPreferences(
        preferredRoles: ["Software Engineering", "Mobile Development", "Backend Development"],
        preferredCompanies: ["Google", "Apple", "Flipkart", "Microsoft"],
        preferredLocations: ["Bengaluru", "Hyderabad"],
        isOpenToAnyLocation: false,
        opportunityTypes: [.internship],
        workArrangements: [.hybrid, .onSite],
        experienceLevel: "Freshers (0 yrs)",
        alertsEnabled: true,
        isPushAllowedByOS: true
    )
}

public extension AchievementItem {
    static let samples: [AchievementItem] = [
        AchievementItem(
            id: "ach-1",
            title: "AWS Certified Cloud Practitioner",
            issuer: "Amazon Web Services",
            category: .certificates,
            dateEarned: "12 Aug 2026",
            descriptionText: "Demonstrated fundamental understanding of AWS Cloud infrastructure, security models, and serverless compute primitives.",
            credentialURL: "https://aws.amazon.com/verification/CLD-84920",
            attachmentName: "AWS_Certificate.pdf"
        ),
        AchievementItem(
            id: "ach-2",
            title: "National Hackathon 2026 — 1st Runner Up",
            issuer: "Smart India Tech Council",
            category: .hackathons,
            dateEarned: "15 Jul 2026",
            descriptionText: "Built an offline mesh-networking emergency response app within 36 hours, evaluated across 400+ national teams.",
            credentialURL: "https://hackathon.gov.in/winners/2026",
            attachmentName: "Hackathon_Award.pdf"
        )
    ]
}
