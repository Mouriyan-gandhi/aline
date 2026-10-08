import Foundation

/// Curated, user-facing role groupings for the Discover filter (spec section 28: "Role —
/// Software Engineer, Backend, ML, AI, Data, etc."). Deliberately condensed from the
/// backend's full ~70-term TARGET_ROLES keyword list down to categories a person would
/// actually tap through in a filter sheet — several raw keywords collapse into one chip.
struct RoleCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let keywords: [String]

    static let all: [RoleCategory] = [
        RoleCategory(name: "Software Engineer", keywords: ["software engineer", "swe", "software developer"]),
        RoleCategory(name: "Backend", keywords: ["backend"]),
        RoleCategory(name: "Frontend", keywords: ["frontend", "front end", "front-end"]),
        RoleCategory(name: "Full Stack", keywords: ["full stack", "fullstack", "full-stack"]),
        RoleCategory(name: "Data Engineer", keywords: ["data engineer"]),
        RoleCategory(name: "Data Scientist", keywords: ["data scientist", "data science"]),
        RoleCategory(name: "Machine Learning", keywords: ["machine learning", "ml engineer"]),
        RoleCategory(name: "AI Engineer", keywords: ["ai engineer", "artificial intelligence"]),
        RoleCategory(name: "DevOps / SRE", keywords: ["devops", "site reliability", "sre"]),
        RoleCategory(name: "Security", keywords: ["security engineer", "cybersecurity", "cyber security"]),
        RoleCategory(name: "Mobile (iOS/Android)", keywords: ["ios", "android", "mobile"]),
        RoleCategory(name: "QA / Test", keywords: ["qa engineer", "test engineer", "sdet", "quality"]),
        RoleCategory(name: "Architect", keywords: ["architect"]),
        RoleCategory(name: "Computer Scientist", keywords: ["computer scientist", "computer science"]),
        RoleCategory(name: "Product / Program Manager", keywords: ["product manager", "program manager"]),
    ]

    func matches(title: String) -> Bool {
        let lowered = title.lowercased()
        return keywords.contains { lowered.contains($0) }
    }
}
