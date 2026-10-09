import Foundation

/// What onboarding actually collects (location, work mode, role interest) but, until now,
/// threw away the moment onboarding finished — OnboardingViewModel computed these, then
/// nothing downstream ever read them again. Persisted the same way CareerProfile is
/// (@AppStorage-backed JSON), and feeds MatchEngine's priority-alignment component.
struct UserPreferences: Codable, Hashable {
    var preferredLocation: String = "All locations"
    var workModes: Set<String> = ["Remote", "Hybrid", "On-site"]
    var preferredRoles: Set<String> = []

    static let empty = UserPreferences()
}
