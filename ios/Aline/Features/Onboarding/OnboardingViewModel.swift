import Foundation
import Observation

/// Matches the real Figma onboarding flow (fileKey AiSKBBDDO9rIzyUPHmRm98) exactly — 5
/// counted steps (progress bar reads "STEP X OF 5") preceded by welcome/sign-in and
/// followed by an uncounted success screen. Replaces the earlier placeholder flow, which had
/// a different step order and a "work mode" question that doesn't exist in the real design.
enum OnboardingStep {
    case welcome
    case signIn
    case lookingFor       // STEP 1 OF 5
    case careerStage      // STEP 2 OF 5
    case roleInterests    // STEP 3 OF 5
    case locations        // STEP 4 OF 5
    case resumeUpload     // STEP 5 OF 5 (optional/skippable)
    case parsing
    case success
}

@MainActor
@Observable
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome

    // Step 1
    var lookingFor: LookingFor = .fullTime
    // Step 2
    var careerStage: CareerStage?
    // Step 3 — max 3, enforced in the view (tapping a 4th option when 3 are already
    // selected is simply ignored, not an error state)
    var selectedRoleInterests: Set<String> = []
    var roleSearchText: String = ""
    // Step 4
    var selectedLocations: Set<String> = []
    var openToAnyLocation = false

    // Step 5 — resume, optional
    var resumeText: String = ""
    var parsedProfile: CareerProfile = .empty
    var errorMessage: String?

    var roleInterestChoices: [OnboardingRoleInterest] {
        guard !roleSearchText.isEmpty else { return OnboardingRoleInterest.all }
        return OnboardingRoleInterest.all.filter { $0.label.localizedCaseInsensitiveContains(roleSearchText) }
    }

    func toggleRoleInterest(_ label: String) {
        if selectedRoleInterests.contains(label) {
            selectedRoleInterests.remove(label)
        } else if selectedRoleInterests.count < 3 {
            selectedRoleInterests.insert(label)
        }
    }

    func toggleLocation(_ location: String) {
        openToAnyLocation = false
        if selectedLocations.contains(location) {
            selectedLocations.remove(location)
        } else {
            selectedLocations.insert(location)
        }
    }

    func selectOpenToAnyLocation() {
        openToAnyLocation = true
        selectedLocations.removeAll()
    }

    /// Resume is optional (per the real flow's own "Optional resume" step name) — skipping
    /// goes straight to success with an empty CareerProfile rather than blocking completion.
    func skipResume() {
        step = .success
    }

    func startParsing() {
        step = .parsing
        Task {
            let profile = await ResumeParser.parse(resumeText: resumeText)
            await MainActor.run {
                self.parsedProfile = profile
                self.step = .success
            }
        }
    }

    func finalProfile() -> CareerProfile {
        parsedProfile
    }

    func finalPreferences() -> UserPreferences {
        UserPreferences(
            lookingFor: lookingFor,
            careerStage: careerStage,
            preferredRoles: selectedRoleInterests,
            preferredLocations: openToAnyLocation ? [] : selectedLocations
        )
    }
}
