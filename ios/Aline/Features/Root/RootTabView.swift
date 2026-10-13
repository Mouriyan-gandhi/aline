import SwiftUI

struct RootTabView: View {
    let profile: CareerProfile
    let preferences: UserPreferences
    @State private var selected: AlineTab = .discover

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .discover: DiscoverView(profile: profile, preferences: preferences)
                case .resume: ResumeView(profile: profile)
                case .community: CommunityView()
                case .profile: ProfileView(profile: profile)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            AlineTabBar(selected: $selected)
        }
        .ignoresSafeArea(.keyboard)
        .tint(AlineColor.primary)
    }
}
