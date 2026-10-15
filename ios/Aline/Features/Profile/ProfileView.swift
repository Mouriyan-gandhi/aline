import SwiftUI
import SwiftData

/// Rebuilt from the real Figma "Profile · Overview" screen (fileKey AiSKBBDDO9rIzyUPHmRm98,
/// node 1139:2195, pulled 2026-10-13) — identity card, quick links (Resumes/Achievements),
/// career profile card (education + role preferences + skills), settings list, sign out.
/// Replaces the old placeholder List-based screen.
///
/// All four settings rows are real, not stubs: Career preferences, Job alerts, Account &
/// privacy (with a real cascading delete-account flow), and Help & feedback (submits to a real
/// backend-stored feedback table) each push to a real screen. "Achievement Gallery" is the one
/// deliberate exception — it needs a whole new data model plus image handling, a genuinely
/// separate large feature, so it stays an honest "coming soon" alert rather than a half-built
/// screen. "Sign out" is real too: there's no server session to end (no auth exists yet), but
/// it does something genuine — resets local onboarding state so the person re-enters the flow,
/// the closest honest equivalent available right now.
struct ProfileView: View {
    let careerProfile: CareerProfile
    let preferences: UserPreferences

    @Environment(AppRouter.self) private var router
    @Environment(ProfileViewModel.self) private var viewModel
    @Query private var resumeDocuments: [ResumeDocument]
    @State private var bannerMessage: String?
    @State private var alertMessage: String?
    @State private var isShowingSignOutConfirm = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("jobAlertsEnabled") private var jobAlertsEnabled = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("My profile")
                        .font(AlineFont.sfPro(25, weight: .semibold))
                        .foregroundStyle(AlineColor.textPrimary)

                    if let bannerMessage {
                        banner(bannerMessage)
                    }

                    identityCard
                    quickLinks
                    careerProfileSection
                    settingsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }
            .background(AlineColor.canvas)
            .navigationBarHidden(true)
            .task {
                if !viewModel.isLoaded { await viewModel.load() }
            }
            .onAppear {
                if let pending = router.pendingProfileBanner {
                    bannerMessage = pending
                    router.pendingProfileBanner = nil
                }
            }
            .alert("Coming soon", isPresented: .constant(alertMessage != nil), presenting: alertMessage) { _ in
                Button("OK") { alertMessage = nil }
            } message: { message in
                Text(message)
            }
            .alert("Sign out?", isPresented: $isShowingSignOutConfirm) {
                Button("Sign Out", role: .destructive) { signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your local onboarding data and takes you back to the welcome screen. Your resumes and community posts stay on the backend.")
            }
        }
    }

    private func banner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(AlineColor.primary)
            Text(message).font(AlineFont.sfPro(13)).foregroundStyle(AlineColor.textPrimary)
            Spacer(minLength: 0)
            Button { bannerMessage = nil } label: {
                Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundStyle(AlineColor.textSecondary)
            }
        }
        .padding(12)
        .background(AlineColor.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Identity card

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Circle()
                    .fill(AlineColor.chipUnselected)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(initials)
                            .font(AlineFont.sfPro(20, weight: .semibold))
                            .foregroundStyle(AlineColor.primary)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.profile.name?.isEmpty == false ? viewModel.profile.name! : "Add your name")
                        .font(AlineFont.sfPro(18, weight: .bold))
                        .foregroundStyle(AlineColor.textPrimary)
                    if !educationSummary.isEmpty {
                        Text(educationSummary).font(AlineFont.sfPro(12)).foregroundStyle(AlineColor.textSecondary)
                    }
                    if let location = preferences.preferredLocations.first {
                        Text(location).font(AlineFont.sfPro(12)).foregroundStyle(AlineColor.textSecondary)
                    }
                }
            }
            HStack {
                Text("Open to opportunities")
                    .font(AlineFont.sfPro(11))
                    .foregroundStyle(AlineColor.textPrimary)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(AlineColor.badgeHighlight)
                    .clipShape(Capsule())
                Spacer()
                NavigationLink {
                    EditProfileView(viewModel: viewModel)
                } label: {
                    Text("Edit profile")
                        .font(AlineFont.sfPro(14, weight: .semibold))
                        .foregroundStyle(AlineColor.primary)
                        .frame(width: 106, height: 34)
                        .background(AlineColor.paperWhite)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AlineColor.cardBorder, lineWidth: 1))
                }
            }
        }
        .padding(14)
        .background(AlineColor.paperWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))
    }

    private var initials: String {
        guard let name = viewModel.profile.name, !name.isEmpty else { return "?" }
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    private var educationSummary: String {
        let profile = viewModel.profile
        let parts = [profile.education, profile.specialization, profile.institution].compactMap { $0 }.filter { !$0.isEmpty }
        guard !parts.isEmpty else { return "" }
        var summary = parts.joined(separator: " · ")
        if let year = profile.graduationYear {
            summary += " · Class of \(year)"
        }
        return summary
    }

    /// Union of CareerProfile's resume-parsed skills (from onboarding) and the profile's own
    /// editable skill list — nothing a person already had disappears just because they haven't
    /// re-entered it into the new Edit Profile skills editor yet.
    private var allSkills: [String] {
        var seen = Set<String>()
        return (careerProfile.skills + viewModel.profile.skills).filter { seen.insert($0.lowercased()).inserted }
    }

    // MARK: - Quick links

    private var quickLinks: some View {
        HStack(spacing: 10) {
            Button { router.selectedTab = .resume } label: {
                quickLinkTile(icon: "doc.text", tint: Color(hex: 0xE5F4F7), count: resumeDocuments.count, label: "My Resumes")
            }
            .buttonStyle(.plain)
            Button { alertMessage = "Achievement galleries (certificates, awards) are a Phase 2 feature — not built yet." } label: {
                quickLinkTile(icon: "rosette", tint: Color(hex: 0xFFF4E5), count: 0, label: "Achievement Gallery")
            }
            .buttonStyle(.plain)
        }
    }

    private func quickLinkTile(icon: String, tint: Color, count: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AlineColor.primary)
                .frame(width: 30, height: 30)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text("\(count)").font(AlineFont.sfPro(18, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
            Text(label).font(AlineFont.sfPro(11)).foregroundStyle(AlineColor.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AlineColor.paperWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))
    }

    // MARK: - Career profile

    private var careerProfileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Career profile").font(AlineFont.sfPro(18, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
                Spacer()
                NavigationLink {
                    EditProfileView(viewModel: viewModel)
                } label: {
                    Text("Manage").font(AlineFont.sfPro(12)).foregroundStyle(AlineColor.primary)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                if !educationSummary.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "graduationcap")
                            .foregroundStyle(AlineColor.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: 0xEDF5F5))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(educationSummary).font(AlineFont.sfPro(13)).foregroundStyle(AlineColor.textPrimary)
                            if let stage = viewModel.profile.careerStage {
                                Text(stage.rawValue).font(AlineFont.sfPro(11)).foregroundStyle(AlineColor.textSecondary)
                            }
                        }
                    }
                    Divider()
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(preferences.preferredRoles.isEmpty ? "No role preferences set" : preferences.preferredRoles.joined(separator: ", "))
                        .font(AlineFont.sfPro(13)).foregroundStyle(AlineColor.textPrimary)
                    Text("\(preferences.lookingFor.rawValue) · \(locationsSummary)")
                        .font(AlineFont.sfPro(11)).foregroundStyle(AlineColor.textSecondary)
                }
                if !allSkills.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(allSkills.prefix(8), id: \.self) { skill in
                            Text(skill)
                                .font(AlineFont.sfPro(11))
                                .foregroundStyle(AlineColor.textPrimary)
                                .padding(.horizontal, 9).padding(.vertical, 4)
                                .background(AlineColor.chipUnselected)
                                .clipShape(Capsule())
                        }
                    }
                }
                if !viewModel.profile.experience.isEmpty || !viewModel.profile.projects.isEmpty {
                    Divider()
                    HStack(spacing: 16) {
                        if !viewModel.profile.experience.isEmpty {
                            Label("\(viewModel.profile.experience.count) role\(viewModel.profile.experience.count == 1 ? "" : "s")", systemImage: "briefcase")
                        }
                        if !viewModel.profile.projects.isEmpty {
                            Label("\(viewModel.profile.projects.count) project\(viewModel.profile.projects.count == 1 ? "" : "s")", systemImage: "hammer")
                        }
                    }
                    .font(AlineFont.sfPro(11))
                    .foregroundStyle(AlineColor.textSecondary)
                }
            }
            .padding(14)
            .background(AlineColor.paperWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))
        }
    }

    private var locationsSummary: String {
        preferences.preferredLocations.isEmpty ? "Open to any location" : preferences.preferredLocations.joined(separator: ", ")
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings").font(AlineFont.sfPro(18, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
            VStack(spacing: 0) {
                NavigationLink { CareerPreferencesView() } label: {
                    settingsRowContent(icon: "briefcase", label: "Career preferences", trailing: nil)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 44)
                NavigationLink { JobAlertsView() } label: {
                    settingsRowContent(icon: "bell", label: "Job alerts", trailing: jobAlertsEnabled ? "On" : "Off")
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 44)
                NavigationLink { AccountPrivacyView(viewModel: viewModel) } label: {
                    settingsRowContent(icon: "checkmark.shield", label: "Account & privacy", trailing: nil)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 44)
                NavigationLink { HelpFeedbackView() } label: {
                    settingsRowContent(icon: "questionmark.circle", label: "Help & feedback", trailing: nil)
                }
                .buttonStyle(.plain)
            }
            .background(AlineColor.paperWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))

            Button { isShowingSignOutConfirm = true } label: {
                HStack(spacing: 7) {
                    Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 13))
                    Text("Sign out").font(AlineFont.sfPro(12))
                }
                .foregroundStyle(AlineColor.textSecondary)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }

    private func settingsRowContent(icon: String, label: String, trailing: String?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(AlineColor.textPrimary).frame(width: 20)
            Text(label).font(AlineFont.sfPro(13)).foregroundStyle(AlineColor.textPrimary)
            Spacer()
            if let trailing {
                Text(trailing).font(AlineFont.sfPro(11)).foregroundStyle(AlineColor.textSecondary)
            }
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(AlineColor.iconMuted)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .contentShape(Rectangle())
    }

    private func signOut() {
        hasCompletedOnboarding = false
    }
}
