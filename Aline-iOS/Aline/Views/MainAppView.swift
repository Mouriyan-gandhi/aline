import SwiftUI

// MARK: - Main Application View
public struct MainAppView: View {
    @StateObject private var navViewModel = AppNavigationViewModel()
    @StateObject private var discoverViewModel = DiscoverViewModel()
    @StateObject private var resumeViewModel = ResumeViewModel()
    @StateObject private var communityViewModel = CommunityViewModel()
    @StateObject private var prepViewModel = InterviewPrepViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()

    public init(
        initialTab: AppTab = .discover,
        hasCompletedOnboarding: Bool = true,
        showNotifications: Bool = false
    ) {
        let nav = AppNavigationViewModel()
        nav.currentTab = initialTab
        nav.hasCompletedOnboarding = hasCompletedOnboarding
        nav.showNotificationsSheet = showNotifications
        self._navViewModel = StateObject(wrappedValue: nav)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            if !navViewModel.hasCompletedOnboarding {
                OnboardingFlowView(navViewModel: navViewModel)
                    .transition(.move(edge: .leading))
            } else {
                ZStack {
                    switch navViewModel.currentTab {
                    case .discover:
                        DiscoverFeedView(viewModel: discoverViewModel, navViewModel: navViewModel, resumeViewModel: resumeViewModel)
                    case .resume:
                        ResumeDashboardView(viewModel: resumeViewModel)
                    case .community:
                        CommunityView(communityViewModel: communityViewModel, prepViewModel: prepViewModel)
                    case .profile:
                        ProfileView(viewModel: profileViewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Floating Navigation Bar (Positioned above safe area)
                FloatingTabBar(currentTab: $navViewModel.currentTab)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $navViewModel.showNotificationsSheet) {
            NotificationsSheetView(navViewModel: navViewModel)
        }
    }
}

// MARK: - Notifications Sheet (Matching Home Page Color Scheme & Design System)
public struct NotificationsSheetView: View {
    @ObservedObject public var navViewModel: AppNavigationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFilter: NotificationCategory = .all

    public enum NotificationCategory: String, CaseIterable {
        case all = "All (5)"
        case opportunities = "Opportunities"
        case resumeAI = "Resume AI"
        case updates = "Updates"
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag indicator handle
            Capsule()
                .fill(Color.black.opacity(0.18))
                .frame(width: 40, height: 4.5)
                .padding(.top, 10)
                .padding(.bottom, 12)

            // Header Row: Title, Unread Pill, Mark All Read & Close
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("Notifications")
                            .font(.system(size: 26, weight: .heavy, design: .default))
                            .foregroundColor(AlineTheme.inkPrimary)

                        if navViewModel.unreadNotificationsCount > 0 {
                            Text("\(navViewModel.unreadNotificationsCount) New")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(AlineTheme.accentHeart))
                        }
                    }
                    Text("Updates, opportunities & AI recommendations")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AlineTheme.inkSecondary)
                }

                Spacer()

                // Close Button
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // Filter Pills (Matching Home Page Aesthetic)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(NotificationCategory.allCases, id: \.self) { cat in
                        let isSelected = selectedFilter == cat
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                selectedFilter = cat
                            }
                        } label: {
                            Text(cat.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? AlineTheme.pillDark : Color.white)
                                        .shadow(color: Color.black.opacity(isSelected ? 0.12 : 0.04), radius: 3, x: 0, y: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Mark all read button
                    if navViewModel.unreadNotificationsCount > 0 {
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                navViewModel.unreadNotificationsCount = 0
                            }
                        } label: {
                            Text("Mark all read")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)

            Divider().opacity(0.12)

            // Notifications Cards Feed (Home Page Pastel Cards)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    // 1. Google SDE Intern (Yellow card)
                    if selectedFilter == .all || selectedFilter == .opportunities {
                        notificationCard(
                            bgColor: AlineTheme.cardYellow,
                            companyName: "Google",
                            title: "Google SDE Intern for 2027–2028 batch",
                            message: "Matches your location preference (Bengaluru) • 92% Match score with C++ & Algorithms",
                            time: "10m ago",
                            isUnread: true,
                            actionTitle: "View Posting"
                        )
                    }

                    // 2. Ola Autonomous Mobility (Mint card)
                    if selectedFilter == .all || selectedFilter == .opportunities {
                        notificationCard(
                            bgColor: AlineTheme.cardMint,
                            companyName: "Ola",
                            title: "Ola Autonomous Mobility Systems opening",
                            message: "Electric & Autonomous Vehicle division posted new intern role in Bengaluru • 93% Fit",
                            time: "35m ago",
                            isUnread: true,
                            actionTitle: "View Posting"
                        )
                    }

                    // 3. Resume AI Feedback (Lavender card)
                    if selectedFilter == .all || selectedFilter == .resumeAI {
                        notificationCard(
                            bgColor: AlineTheme.cardLavender,
                            customIcon: "sparkles",
                            iconColor: Color(red: 0.35, green: 0.25, blue: 0.85),
                            title: "Resume Keyword Analysis Ready",
                            message: "Aline AI detected 3 missing high-impact keywords for Flipkart & Google SDE applications",
                            time: "1h ago",
                            isUnread: false,
                            actionTitle: "Review AI Tips"
                        )
                    }

                    // 4. Flipkart Application Viewed (Peach card)
                    if selectedFilter == .all || selectedFilter == .updates {
                        notificationCard(
                            bgColor: AlineTheme.cardPeach,
                            companyName: "Flipkart",
                            title: "Application Reviewed by Recruiter",
                            message: "Your resume for Flipkart SDE Backend Intern was downloaded by campus hiring team",
                            time: "3h ago",
                            isUnread: false,
                            actionTitle: "Track Application"
                        )
                    }

                    // 5. System Design Practice (Sky Blue card)
                    if selectedFilter == .all || selectedFilter == .updates {
                        notificationCard(
                            bgColor: AlineTheme.cardSkyBlue,
                            customIcon: "waveform.circle.fill",
                            iconColor: Color(red: 0.15, green: 0.45, blue: 0.85),
                            title: "System Design Daily Question Ready",
                            message: "Sharpen your skills: 'Design a distributed rate-limiter for payment gateways'",
                            time: "Yesterday",
                            isUnread: false,
                            actionTitle: "Start Practice"
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(AlineTheme.canvasBackground.ignoresSafeArea())
        .presentationDetents([.fraction(0.85), .large])
    }

    // MARK: - Notification Pastel Card Helper View
    @ViewBuilder
    private func notificationCard(
        bgColor: Color,
        companyName: String? = nil,
        customIcon: String? = nil,
        iconColor: Color = AlineTheme.inkPrimary,
        title: String,
        message: String,
        time: String,
        isUnread: Bool,
        actionTitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Circular White Icon Badge (matching home page)
                if let comp = companyName {
                    CompanyLogoBadge(companyName: comp, size: 44)
                } else if let icon = customIcon {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(iconColor)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(2)

                        Spacer()

                        if isUnread {
                            Circle()
                                .fill(AlineTheme.accentHeart)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(message)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .lineSpacing(2)
                        .padding(.top, 1)
                }
            }

            // Bottom row: Time badge & Action Button
            HStack {
                Text(time)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.85))
                    .clipShape(Capsule())

                Spacer()

                Button {
                    navViewModel.unreadNotificationsCount = max(0, navViewModel.unreadNotificationsCount - 1)
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AlineTheme.pillDark)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(bgColor)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Previews
#Preview("Collective App (Interactive)") {
    MainAppView()
}

#Preview("Collective App - Resume Tab") {
    MainAppView(initialTab: .resume)
}

#Preview("Collective App - Community Tab") {
    MainAppView(initialTab: .community)
}

#Preview("Collective App - Profile Tab") {
    MainAppView(initialTab: .profile)
}

#Preview("Collective App - Onboarding") {
    MainAppView(hasCompletedOnboarding: false)
}

#Preview("Notifications Center Sheet") {
    let nav = AppNavigationViewModel()
    nav.unreadNotificationsCount = 3
    return NotificationsSheetView(navViewModel: nav)
}

#Preview("Collective App (Dark Mode)") {
    MainAppView()
        .preferredColorScheme(.dark)
}

