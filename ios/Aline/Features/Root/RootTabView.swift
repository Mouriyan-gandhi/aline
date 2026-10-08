import SwiftUI

struct RootTabView: View {
    let profile: CareerProfile

    var body: some View {
        TabView {
            DiscoverView(profile: profile)
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
