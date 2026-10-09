import Foundation
import Observation

enum OnboardingStep {
    case uploadResume
    case parsing
    case confirmRoles
    case location
    case workMode
}

@MainActor
@Observable
final class OnboardingViewModel {
    var step: OnboardingStep = .uploadResume
    var resumeText: String = ""
    var parsedProfile: CareerProfile = .empty
    var confirmedRoles: Set<String> = []
    var preferredLocation: String = "All locations"
    var workModes: Set<String> = ["Remote", "Hybrid", "On-site"]
    var errorMessage: String?

    let locationOptions = ["All locations", "Bengaluru", "Hyderabad", "Pune", "Gurugram", "Mumbai", "Chennai"]
    let workModeOptions = ["Remote", "Hybrid", "On-site"]

    func startParsing() {
        step = .parsing
        Task {
            let profile = await ResumeParser.parse(resumeText: resumeText)
            await MainActor.run {
                self.parsedProfile = profile
                self.confirmedRoles = Set(profile.inferredRoles)
                self.step = .confirmRoles
            }
        }
    }

    func finalProfile() -> CareerProfile {
        CareerProfile(
            skills: parsedProfile.skills,
            inferredRoles: Array(confirmedRoles),
            education: parsedProfile.education,
            rawResumeText: parsedProfile.rawResumeText
        )
    }

    /// Previously computed and discarded — location/workMode/confirmedRoles never made it
    /// past onboarding. Now persisted alongside CareerProfile (see AlineApp.swift) and read
    /// by MatchEngine's priority-alignment component.
    func finalPreferences() -> UserPreferences {
        UserPreferences(
            preferredLocation: preferredLocation,
            workModes: workModes,
            preferredRoles: confirmedRoles
        )
    }
}
