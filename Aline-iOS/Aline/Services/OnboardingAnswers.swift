import Foundation

/// What onboarding collected, handed to the profile (career stage, graduation year, career
/// preferences) and the resume list (the optional uploaded resume) when it finishes.
struct OnboardingAnswers {
    let opportunityGoal: String
    let careerStage: String
    let graduationYear: String
    let roles: [String]
    let locations: [String]
    let openToAnyLocation: Bool
    let resumeURL: URL?
}

extension Notification.Name {
    static let onboardingDidComplete = Notification.Name("AlineOnboardingDidComplete")
}

extension ProfileViewModel {
    func applyOnboarding(_ answers: OnboardingAnswers) {
        var prefs = preferences
        switch answers.opportunityGoal {
        case "Internship": prefs.opportunityTypes = [.internship]
        case "Full-Time Job": prefs.opportunityTypes = [.fullTime]
        case "Both": prefs.opportunityTypes = [.internship, .fullTime]
        default: break
        }
        prefs.preferredRoles = answers.roles
        prefs.preferredLocations = answers.openToAnyLocation ? [] : answers.locations
        prefs.isOpenToAnyLocation = answers.openToAnyLocation
        if prefs.experienceLevel.isEmpty, !answers.careerStage.isEmpty {
            prefs.experienceLevel = answers.careerStage == "Working professional" ? "Experienced" : "Student / Freshers"
        }
        updatePreferences(prefs)

        var updated = profile
        if updated.titleOrStage.isEmpty { updated.titleOrStage = answers.careerStage }
        if !answers.graduationYear.isEmpty { updated.graduationYear = answers.graduationYear }
        if updated != profile { updateProfile(updated) }
    }
}

extension ProfileViewModel {
    /// Fills whatever the profile is still missing from a parsed resume — never overwrites
    /// something the user already entered.
    func autofill(from parsed: ResumeProfile) {
        var updated = profile
        updated.mergeEmptyFields(from: parsed)
        if updated != profile { updateProfile(updated) }
    }
}

extension UserProfile {
    mutating func mergeEmptyFields(from parsed: ResumeProfile) {
        func fill(_ field: inout String, _ value: String) {
            if field.trimmingCharacters(in: .whitespaces).isEmpty, !value.isEmpty { field = value }
        }
        fill(&name, parsed.fullName)
        fill(&bio, parsed.summary)
        fill(&linkedInURL, parsed.linkedInURL)
        fill(&githubURL, parsed.githubURL)
        fill(&portfolioURL, parsed.portfolioURL)
        if let school = parsed.education.first {
            fill(&institution, school.institution)
            fill(&education, school.degree)
            let years = school.dateRange.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { $0.count == 4 }
            fill(&graduationYear, years.last ?? "")
            fill(&location, school.location)
        }
        for skill in parsed.skillCategories.flatMap(\.items)
        where !skills.contains(where: { $0.caseInsensitiveCompare(skill) == .orderedSame }) {
            skills.append(skill)
        }
        if experiences.isEmpty {
            // The profile lists oldest first; resumes list newest first
            experiences = parsed.experience.reversed().map {
                UserExperience(id: UUID().uuidString, title: $0.title, company: $0.organization,
                               location: $0.location, period: $0.dateRange, bullets: $0.bullets)
            }
        }
        if projects.isEmpty {
            projects = parsed.projects.reversed().map {
                UserProject(id: UUID().uuidString, title: $0.name, period: $0.dateRange, techStack: $0.techStack, bullets: $0.bullets)
            }
        }
    }
}
