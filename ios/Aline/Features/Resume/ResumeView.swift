import SwiftUI

/// The real resume dashboard (templates, on-device AI tailoring, PDF export) — replaces the
/// old Milestone 0 placeholder now that it's built. Kept as a thin wrapper around
/// ResumeDashboardView so RootTabView's existing call site doesn't need to change.
struct ResumeView: View {
    let profile: CareerProfile

    var body: some View {
        ResumeDashboardView(careerProfile: profile)
    }
}
