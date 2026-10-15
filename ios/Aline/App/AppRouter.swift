import Foundation
import Observation

/// Shared cross-tab coordination, owned by RootTabView and injected via environment. Exists
/// for exactly one real need right now: ResumeDashboardView redirecting to the Profile tab
/// (with an explanatory banner) when someone tries to create a resume before their profile is
/// filled in — a plain @State tab selector inside RootTabView has no way for a sibling tab's
/// view to switch tabs or hand it a message, since SwiftUI tab content doesn't talk to its
/// siblings directly.
@MainActor
@Observable
final class AppRouter {
    var selectedTab: AlineTab = .discover
    /// Set right before switching to .profile from elsewhere; ProfileView reads and clears it
    /// on appear so it only shows once per redirect, not on every normal visit to the tab.
    var pendingProfileBanner: String?

    func redirectToProfile(message: String) {
        pendingProfileBanner = message
        selectedTab = .profile
    }
}
