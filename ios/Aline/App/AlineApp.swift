import SwiftUI
import SwiftData

@main
struct AlineApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("careerProfileData") private var careerProfileData: Data = Data()
    @AppStorage("userPreferencesData") private var userPreferencesData: Data = Data()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding, let profile = loadProfile() {
                    RootTabView(profile: profile, preferences: loadPreferences())
                } else {
                    OnboardingView { profile, preferences in
                        save(profile)
                        save(preferences)
                        hasCompletedOnboarding = true
                    }
                }
            }
            .tint(AlineColor.electricCobalt)
        }
        .modelContainer(for: [SavedJob.self, ResumeDocument.self])
    }

    private func loadProfile() -> CareerProfile? {
        try? JSONDecoder().decode(CareerProfile.self, from: careerProfileData)
    }

    private func loadPreferences() -> UserPreferences {
        (try? JSONDecoder().decode(UserPreferences.self, from: userPreferencesData)) ?? .empty
    }

    private func save(_ profile: CareerProfile) {
        careerProfileData = (try? JSONEncoder().encode(profile)) ?? Data()
    }

    private func save(_ preferences: UserPreferences) {
        userPreferencesData = (try? JSONEncoder().encode(preferences)) ?? Data()
    }
}
