import SwiftUI
import SwiftData

@main
struct AlineApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("careerProfileData") private var careerProfileData: Data = Data()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding, let profile = loadProfile() {
                    RootTabView(profile: profile)
                } else {
                    OnboardingView { profile in
                        save(profile)
                        hasCompletedOnboarding = true
                    }
                }
            }
            .tint(AlineColor.electricCobalt)
        }
        .modelContainer(for: SavedJob.self)
    }

    private func loadProfile() -> CareerProfile? {
        try? JSONDecoder().decode(CareerProfile.self, from: careerProfileData)
    }

    private func save(_ profile: CareerProfile) {
        careerProfileData = (try? JSONEncoder().encode(profile)) ?? Data()
    }
}
