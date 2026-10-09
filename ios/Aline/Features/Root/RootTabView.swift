import SwiftUI

struct RootTabView: View {
    let profile: CareerProfile
    let preferences: UserPreferences

    var body: some View {
        TabView {
            DiscoverView(profile: profile, preferences: preferences)
                .tabItem { Label("Discover", systemImage: "sparkles") }

            ResumeView(profile: profile)
                .tabItem { Label("Resume", systemImage: "doc.text") }

            CommunityView()
                .tabItem { Label("Community", systemImage: "bubble.left.and.bubble.right") }

            ProfileView(profile: profile)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(AlineColor.electricCobalt)
    }
}
