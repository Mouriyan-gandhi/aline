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
