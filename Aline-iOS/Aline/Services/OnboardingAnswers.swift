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

        // Career stage drives which job levels are recommended (students: intern + entry)
        if !answers.careerStage.isEmpty {
            var stage = ProfileUpdateRequest(deviceId: DeviceIdentity.deviceID)
            stage.careerStage = answers.careerStage
            Task {
                if (try? await AlineAPI.updateProfile(stage)) != nil {
                    NotificationCenter.default.post(name: .profileDidSave, object: nil)
                }
            }
        }

        var updated = profile
        if updated.titleOrStage.isEmpty { updated.titleOrStage = answers.careerStage }
        if !answers.graduationYear.isEmpty { updated.graduationYear = answers.graduationYear }
        if updated != profile { updateProfile(updated) }
    }
}

extension ProfileViewModel {
    /// Fills whatever the profile is still missing from a resume — never overwrites something
    /// the user already entered — and adds its certifications/awards to the Achievement Gallery.
    func autofill(from understood: UnderstoodResume) {
        var updated = profile
        updated.mergeEmptyFields(from: understood)
        if updated != profile { updateProfile(updated) }
        addAchievements(understood.achievements)
    }

    /// Adds gallery items whose titles aren't there yet; returns how many were added.
    @discardableResult
    func addAchievements(_ items: [AchievementItem]) -> Int {
        let existing = Set(achievements.map { $0.title.lowercased() })
        let new = items.filter { !$0.title.isEmpty && !existing.contains($0.title.lowercased()) }
        for item in new.reversed() { upsertAchievement(item) }
        return new.count
    }
}

extension UserProfile {
    /// `includeEntries: false` leaves skills/experience/projects to the caller (Edit Profile
    /// merges those itself so it can report counts).
    mutating func mergeEmptyFields(from understood: UnderstoodResume, includeEntries: Bool = true) {
        let parsed = understood.resume
        func fill(_ field: inout String, _ value: String) {
            if field.trimmingCharacters(in: .whitespaces).isEmpty, !value.isEmpty { field = value }
        }
        fill(&name, parsed.fullName)
        fill(&bio, parsed.summary)
        fill(&linkedInURL, parsed.linkedInURL)
        fill(&githubURL, parsed.githubURL)
        fill(&portfolioURL, parsed.portfolioURL)
        fill(&location, understood.location)
        if let school = parsed.education.first {
            fill(&institution, school.institution)
            fill(&education, school.degree)
            fill(&location, school.location)
        }
        fill(&graduationYear, understood.graduationYear)
        fill(&titleOrStage, understood.headline)
        guard includeEntries else { return }
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
