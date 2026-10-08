import Foundation

/// Mirrors backend/app/schemas.py's Job model exactly — one shared shape across the wire.
struct Job: Codable, Identifiable, Hashable {
    let id: String
    let company: String
    let platform: String
    let title: String
    let department: String
    let location: String
    let applyURL: String
    let postedAt: String?
    let extractedSkills: [String]

    enum CodingKeys: String, CodingKey {
        case id, company, platform, title, department, location
        case applyURL = "apply_url"
        case postedAt = "posted_at"
        case extractedSkills = "extracted_skills"
    }
}
