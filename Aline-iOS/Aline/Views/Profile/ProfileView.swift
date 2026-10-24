import SwiftUI

// MARK: - Profile & Career Hub View (Sections 10, 11, 12 of Product Guide)
public struct ProfileView: View {
    @ObservedObject public var viewModel: ProfileViewModel
    @State private var showingPreferencesSheet: Bool = false
    @State private var showingGallerySheet: Bool = false
    @State private var showingHelpSheet: Bool = false

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color(AlineTheme.canvasBackground).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Top Profile Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AlineTheme.cardYellow)
                                    .frame(width: 68, height: 68)
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 58))
                                    .foregroundColor(AlineTheme.inkPrimary)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(viewModel.profile.name)
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(AlineTheme.inkPrimary)

                                Text("\(viewModel.profile.titleOrStage) • Class of \(viewModel.profile.graduationYear)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AlineTheme.inkSecondary)

                                Text(viewModel.profile.institution)
                                    .font(.system(size: 12))
                                    .foregroundColor(AlineTheme.inkMuted)
                            }

                            Spacer()
                        }

                        // Availability Badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(AlineTheme.accentEmerald)
                                .frame(width: 8, height: 8)
                            Text(viewModel.profile.opportunityAvailability)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.accentEmerald)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AlineTheme.accentEmerald.opacity(0.12))
                        .clipShape(Capsule())

                        // Skills chips
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Core Skills")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 85), spacing: 6)], spacing: 6) {
                                ForEach(viewModel.profile.skills, id: \.self) { skill in
                                    Text(skill)
                                        .font(.system(size: 11, weight: .semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(22)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(AlineTheme.cardPeach.opacity(0.8))
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Hub Navigation Rows
                    VStack(spacing: 12) {
                        ProfileMenuRow(
                            icon: "slider.horizontal.3",
                            iconColor: AlineTheme.cardYellow,
                            title: "Career Preferences",
                            subtitle: "\(viewModel.preferences.preferredRoles.count) Roles • \(viewModel.preferences.preferredLocations.joined(separator: ", "))"
                        ) {
                            showingPreferencesSheet = true
                        }

                        ProfileMenuRow(
                            icon: "trophy.fill",
                            iconColor: AlineTheme.cardLavender,
                            title: "Achievement Gallery",
                            subtitle: "\(viewModel.achievements.count) Saved Credentials & Certificates"
                        ) {
                            showingGallerySheet = true
                        }

                        ProfileMenuRow(
                            icon: "bell.badge.fill",
                            iconColor: AlineTheme.cardMint,
                            title: "Opportunity Alerts",
                            subtitle: viewModel.preferences.alertsEnabled ? "Enabled (Push Active)" : "Disabled"
                        ) {
                            viewModel.preferences.alertsEnabled.toggle()
                        }

                        ProfileMenuRow(
                            icon: "questionmark.circle.fill",
                            iconColor: AlineTheme.cardSkyBlue,
                            title: "Help & Feedback",
                            subtitle: "Resume limits, anonymous identity, support"
                        ) {
                            showingHelpSheet = true
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 120)
                }
            }
        }
        .sheet(isPresented: $showingPreferencesSheet) {
            CareerPreferencesSheet(preferences: $viewModel.preferences)
        }
        .sheet(isPresented: $showingGallerySheet) {
            AchievementGallerySheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingHelpSheet) {
            HelpAndFeedbackSheet()
        }
    }
}

// MARK: - Profile Menu Row Component
public struct ProfileMenuRow: View {
    public let icon: String
    public let iconColor: Color
    public let title: String
    public let subtitle: String
    public let action: () -> Void

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(iconColor)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(AlineTheme.inkSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AlineTheme.inkMuted)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Career Preferences Sheet
public struct CareerPreferencesSheet: View {
    @Binding public var preferences: CareerPreferences
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Preferred Roles")) {
                    ForEach(preferences.preferredRoles, id: \.self) { role in
                        HStack {
                            Text(role)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(AlineTheme.pillDark)
                        }
                    }
                }

                Section(header: Text("Preferred Locations")) {
                    Toggle("Open to Any Location", isOn: $preferences.isOpenToAnyLocation)
                    if !preferences.isOpenToAnyLocation {
                        ForEach(preferences.preferredLocations, id: \.self) { loc in
                            Text(loc)
                        }
                    }
                }

                Section(header: Text("Push Notification Alerts")) {
                    Toggle("Receive Opportunity Alerts", isOn: $preferences.alertsEnabled)
                    Text("iOS System Push: \(preferences.isPushAllowedByOS ? "Allowed" : "Disabled in iOS Settings")")
                        .font(.system(size: 12))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
            }
            .navigationTitle("Career Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                        .font(.alineBodyBold)
                }
            }
        }
    }
}

// MARK: - Achievement Gallery Sheet
public struct AchievementGallerySheet: View {
    @ObservedObject public var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddModal: Bool = false

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewModel.achievements) { ach in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(ach.category.rawValue)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AlineTheme.cardYellow)
                                    .clipShape(Capsule())

                                Spacer()

                                Text(ach.dateEarned)
                                    .font(.system(size: 12))
                                    .foregroundColor(AlineTheme.inkSecondary)

                                Button {
                                    viewModel.deleteAchievement(id: ach.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundColor(AlineTheme.accentHeart)
                                }
                            }

                            Text(ach.title)
                                .font(.system(size: 16, weight: .bold))
                            Text(ach.issuer)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AlineTheme.inkSecondary)
                            Text(ach.descriptionText)
                                .font(.system(size: 13))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding(20)
            }
            .background(Color(AlineTheme.canvasBackground).ignoresSafeArea())
            .navigationTitle("Achievement Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Help and Feedback Sheet
public struct HelpAndFeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Frequently Asked Questions")) {
                    Text("Where do opportunities come from? Listings are aggregated directly from employer career portals.")
                    Text("How does resume optimization work? The AI analyzes job requirements and missing keywords to help you describe your authentic experience effectively.")
                    Text("Community Anonymity: Your community discussions are published with an anonymous handle by default.")
                }
                Section(header: Text("App Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Native iOS)")
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Profile & Career Hub") {
    ProfileView(viewModel: ProfileViewModel())
}

#Preview("Achievement Gallery Sheet") {
    AchievementGallerySheet(viewModel: ProfileViewModel())
}

#Preview("Help and Support Sheet") {
    HelpAndFeedbackSheet()
}

