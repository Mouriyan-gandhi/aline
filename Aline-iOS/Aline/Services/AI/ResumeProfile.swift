import Foundation

/// The full structured resume — richer than CareerProfile (which stays exactly as-is: it
/// only feeds job matching and onboarding, and nothing here should risk that working path).
/// Section set and order (Education → Experience → Projects → Skills) is deliberately the
/// same proven structure used by "Jake's Resume," the open-source template that's become the
/// de facto ATS-safe standard in tech hiring — not an arbitrary choice, see ResumeTemplate.swift.
struct ResumeProfile: Codable, Hashable {
    var fullName: String = ""
    var phone: String = ""
    var email: String = ""
    var linkedInURL: String = ""
    var githubURL: String = ""
    var portfolioURL: String = ""
    /// Optional 1-2 sentence summary. Many strong early-career resumes skip this entirely
    /// (Jake's Resume has none) — kept optional, never forced into every template.
    var summary: String = ""
    var education: [EducationEntry] = []
    var experience: [ExperienceEntry] = []
    var projects: [ProjectEntry] = []
    var skillCategories: [SkillCategory] = []
    /// Added for match-scoring (see MatchEngine's certifications/achievements component) —
    /// not every resume has these, both default empty rather than forcing a template section.
    var certifications: [CertificationEntry] = []
    /// Free-text lines — hackathon wins, publications, competition placements. Deliberately
    /// not structured like certifications (no issuer/date); these are too heterogeneous to
    /// force into one shape, and the matching use (keyword overlap against a JD) only needs
    /// the text itself.
    var achievements: [String] = []

    static let empty = ResumeProfile()

    var contactLine: String {
        [phone, email, linkedInURL, githubURL, portfolioURL]
            .filter { !$0.isEmpty }
            .joined(separator: "  |  ")
    }
}

struct EducationEntry: Codable, Hashable, Identifiable {
    var id = UUID()
    var institution: String = ""
    var degree: String = ""
    var location: String = ""
    var dateRange: String = ""
    /// Free-text detail line — CGPA, honors, relevant coursework. Optional, often omitted.
    var detail: String = ""
}

struct ExperienceEntry: Codable, Hashable, Identifiable {
    var id = UUID()
    var title: String = ""
    var organization: String = ""
    var location: String = ""
    var dateRange: String = ""
    var bullets: [String] = []
}

struct ProjectEntry: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String = ""
    var techStack: String = ""
    var dateRange: String = ""
    var bullets: [String] = []
}

struct SkillCategory: Codable, Hashable, Identifiable {
    var id = UUID()
    var label: String = ""
    var items: [String] = []
}

struct CertificationEntry: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String = ""
    var issuer: String = ""
    var dateEarned: String = ""
}
