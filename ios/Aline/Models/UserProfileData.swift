import Foundation

/// The real identity fields from the Figma "Edit Profile" screen — name, education,
/// institution, specialization, graduation year, career stage, optional professional links —
/// plus skills/experience/projects, captured here (not just inside a specific resume document)
/// because this is the information a resume actually needs, and it should exist once per
/// person, not get re-typed from scratch for every new resume. Persisted server-side on the
/// same device-scoped `users` row Community's identity uses (see
/// backend/app/community_db.py's module docstring). Still distinct from CareerProfile (the
/// lightweight onboarding-resume-parse used for job matching) and the Community `username` —
/// three different concerns sharing one device identity.
struct UserProfileData: Codable, Equatable {
    var username: String
    var name: String?
    var education: String?
    var institution: String?
    var specialization: String?
    var graduationYear: Int?
    var careerStage: CareerStage?
    var linkedin: String?
    var github: String?
    var portfolio: String?
    var skills: [String] = []
    var experience: [ProfileExperienceEntry] = []
    var projects: [ProfileProjectEntry] = []

    enum CodingKeys: String, CodingKey {
        case username, name, education, institution, specialization
        case graduationYear = "graduation_year"
        case careerStage = "career_stage"
        case linkedin, github, portfolio, skills, experience, projects
    }

    static let empty = UserProfileData(username: "")

    /// The gate for "can this person create a resume" (per the product direction: fill the
    /// profile first, either by uploading a resume — which populates these via ResumeStructurer
    /// — or by filling the Edit Profile form manually). Links are explicitly excluded, matching
    /// the Figma form's own "All links are optional" note. Skills/experience/projects are also
    /// excluded here deliberately — they're genuinely useful to have, but requiring them before
    /// someone can even START a resume would block the common case of filling them in AS you
    /// build your first resume.
    var isComplete: Bool {
        guard let name, !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let education, !education.trimmingCharacters(in: .whitespaces).isEmpty,
              let institution, !institution.trimmingCharacters(in: .whitespaces).isEmpty,
              let specialization, !specialization.trimmingCharacters(in: .whitespaces).isEmpty,
              let graduationYear, graduationYear > 0,
              careerStage != nil
        else { return false }
        return true
    }

    /// Seeds a fresh ResumeProfile from whatever's already on file — the actual payoff of
    /// capturing skills/experience/projects at the profile level: "Build from scratch" starts
    /// pre-filled instead of empty. Deliberately NOT used by the "upload a resume" path in
    /// AddResumeView — an uploaded document is a stronger, fresher source for that specific
    /// resume than whatever's saved on the profile.
    func seedResumeProfile() -> ResumeProfile {
        var profile = ResumeProfile()
        profile.fullName = name ?? ""
        profile.linkedInURL = linkedin ?? ""
        profile.githubURL = github ?? ""
        profile.portfolioURL = portfolio ?? ""
        if let education, let institution {
            var entry = EducationEntry()
            entry.institution = institution
            entry.degree = [education, specialization].compactMap { $0 }.joined(separator: " · ")
            if let graduationYear { entry.dateRange = "Class of \(graduationYear)" }
            profile.education = [entry]
        }
        if !skills.isEmpty {
            profile.skillCategories = [SkillCategory(label: "Skills", items: skills)]
        }
        profile.experience = experience.map { $0.toResumeEntry() }
        profile.projects = projects.map { $0.toResumeEntry() }
        return profile
    }
}

/// Wire-format twin of ResumeProfile's ExperienceEntry — kept as a separate type rather than
/// adding CodingKeys to ExperienceEntry itself, because ExperienceEntry is also
/// JSONEncoder/Decoder'd straight into SwiftData for every local ResumeDocument (see
/// LocalStore.swift) — changing its CodingKeys would silently corrupt any resume already saved
/// on a person's device. This type exists only to carry snake_case JSON to/from the backend.
struct ProfileExperienceEntry: Codable, Hashable, Identifiable {
    var id = UUID()
    var title: String = ""
    var organization: String = ""
    var location: String = ""
    var dateRange: String = ""
    var bullets: [String] = []

    enum CodingKeys: String, CodingKey {
        case title, organization, location, bullets
        case dateRange = "date_range"
    }

    func toResumeEntry() -> ExperienceEntry {
        ExperienceEntry(title: title, organization: organization, location: location, dateRange: dateRange, bullets: bullets)
    }
}

struct ProfileProjectEntry: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String = ""
    var techStack: String = ""
    var dateRange: String = ""
    var bullets: [String] = []

    enum CodingKeys: String, CodingKey {
        case name, bullets
        case techStack = "tech_stack"
        case dateRange = "date_range"
    }

    func toResumeEntry() -> ProjectEntry {
        ProjectEntry(name: name, techStack: techStack, dateRange: dateRange, bullets: bullets)
    }
}
