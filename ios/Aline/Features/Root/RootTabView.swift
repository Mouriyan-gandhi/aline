import SwiftUI

/// Now owns `AppRouter` and `ProfileViewModel` at the top of the tree and injects both via
/// `.environment()`, since Community (redirect-to-profile banners) and the Resume dashboard's
/// gating logic both need to drive tab selection, and Profile's own screens all share one
/// loaded `ProfileViewModel` instance rather than each re-fetching `/profile` independently.
struct RootTabView: View {
    let profile: CareerProfile
    let preferences: UserPreferences

    @State private var router = AppRouter()
    @State private var profileViewModel = ProfileViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch router.selectedTab {
                case .discover: DiscoverView(profile: profile, preferences: preferences)
                case .resume: ResumeDashboardView(careerProfile: profile)
                case .community: CommunityView()
                case .profile: ProfileView(careerProfile: profile, preferences: preferences)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            AlineTabBar(selected: $router.selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .tint(AlineColor.primary)
        .environment(router)
        .environment(profileViewModel)
        .task {
            if !profileViewModel.isLoaded {
                await profileViewModel.load()
            }
        }
    }
}
