import SwiftUI

// MARK: - Main Application View
public struct MainAppView: View {
    @StateObject private var navViewModel: AppNavigationViewModel
    @StateObject private var discoverViewModel = DiscoverViewModel()
    @StateObject private var resumeViewModel = ResumeViewModel()
    @StateObject private var communityViewModel = CommunityViewModel()
    @StateObject private var prepViewModel = InterviewPrepViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()

    @State private var isSplashActive: Bool
    /// Which auth form is open from the welcome screen (nil = welcome screen itself)
    @State private var authEntry: AuthenticationView.AuthMode? = nil

    public init(
        initialTab: AppTab = .discover,
        hasCompletedOnboarding: Bool? = nil,
        isAuthenticated: Bool? = nil,
        showSplash: Bool = true,
        showNotifications: Bool = false
    ) {
        let nav = AppNavigationViewModel(
            isAuthenticated: isAuthenticated,
            hasCompletedOnboarding: hasCompletedOnboarding
        )
        nav.currentTab = initialTab
        nav.showNotificationsSheet = showNotifications
        self._navViewModel = StateObject(wrappedValue: nav)
        self._isSplashActive = State(initialValue: showSplash)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            if isSplashActive {
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isSplashActive = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            } else if !navViewModel.isAuthenticated {
                if let mode = authEntry {
                    AuthenticationView(
                        navViewModel: navViewModel,
                        initialMode: mode,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.3)) { authEntry = nil }
                        }
                    ) { _ in
                        profileViewModel.syncWithStoredUser()
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                    .zIndex(6)
                } else {
                    // Welcome: feature carousel with Google / Apple / Create account
                    WelcomeView(
                        navViewModel: navViewModel,
                        onCreateAccount: {
                            withAnimation(.easeInOut(duration: 0.3)) { authEntry = .signUp }
                        },
                        onSignIn: {
                            withAnimation(.easeInOut(duration: 0.3)) { authEntry = .signIn }
                        },
                        onAuthSuccess: { _ in
                            profileViewModel.syncWithStoredUser()
                        }
                    )
                    .transition(.opacity)
                    .zIndex(5)
                }
            } else if !navViewModel.hasCompletedOnboarding {
                OnboardingFlowView(navViewModel: navViewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    .zIndex(4)
            } else {
                mainTabsView
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isSplashActive)
        .animation(.easeInOut(duration: 0.35), value: navViewModel.isAuthenticated)
        // Signing out always comes back to the welcome screen, not a half-filled form
        .onChange(of: navViewModel.isAuthenticated) { _, signedIn in
            if !signedIn { authEntry = nil }
        }
        // A new account (or a deleted one) starts with no interview history,
        // so "Continue from where you left" only appears after they open a question themselves
        .onChange(of: navViewModel.hasCompletedOnboarding) { _, completed in
            if !completed { prepViewModel.clearLastVisitedSession() }
        }
        .animation(.easeInOut(duration: 0.35), value: navViewModel.hasCompletedOnboarding)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $navViewModel.showNotificationsSheet) {
            NotificationsSheetView(
                navViewModel: navViewModel,
                discoverViewModel: discoverViewModel,
                communityViewModel: communityViewModel
            )
        }
        .onAppear {
            profileViewModel.syncWithStoredUser()
            profileViewModel.onProfileUpdated = { [weak resumeViewModel, weak navViewModel] updatedProfile in
                navViewModel?.currentUserFullName = updatedProfile.name
                resumeViewModel?.syncWithProfile(updatedProfile, achievements: profileViewModel.achievements)
            }
            resumeViewModel.syncWithProfile(profileViewModel.profile, achievements: profileViewModel.achievements)
        }
        .onReceive(NotificationCenter.default.publisher(for: .userProfileDidUpdate)) { notif in
            if let updated = notif.object as? UserProfile {
                let clean = updated.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty {
                    navViewModel.currentUserFullName = clean
                }
            }
        }
    }

    @ViewBuilder
    private var mainTabsView: some View {
        if #available(iOS 26.0, *) {
            // Native TabView: gets the system Liquid Glass tab bar, and shrinks it while scrolling.
            TabView(selection: $navViewModel.currentTab) {
                Tab(AppTab.discover.title, systemImage: AppTab.discover.iconName, value: AppTab.discover) {
                    DiscoverFeedView(viewModel: discoverViewModel, navViewModel: navViewModel, resumeViewModel: resumeViewModel)
                }
                Tab(AppTab.resume.title, systemImage: AppTab.resume.iconName, value: AppTab.resume) {
                    ResumeDashboardView(viewModel: resumeViewModel)
                }
                Tab(AppTab.community.title, systemImage: AppTab.community.iconName, value: AppTab.community) {
                    CommunityView(communityViewModel: communityViewModel, prepViewModel: prepViewModel, navViewModel: navViewModel)
                }
                Tab(AppTab.profile.title, systemImage: AppTab.profile.iconName, value: AppTab.profile) {
                    ProfileView(viewModel: profileViewModel, resumes: resumeViewModel.resumes, navViewModel: navViewModel, communityViewModel: communityViewModel)
                }
            }
            .tint(AlineTheme.inkPrimary)
            .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            ZStack {
                switch navViewModel.currentTab {
                case .discover:
                    DiscoverFeedView(viewModel: discoverViewModel, navViewModel: navViewModel, resumeViewModel: resumeViewModel)
                case .resume:
                    ResumeDashboardView(viewModel: resumeViewModel)
                case .community:
                    CommunityView(communityViewModel: communityViewModel, prepViewModel: prepViewModel, navViewModel: navViewModel)
                case .profile:
                    ProfileView(viewModel: profileViewModel, resumes: resumeViewModel.resumes, navViewModel: navViewModel, communityViewModel: communityViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Frosted blur backdrop behind floating tab bar
            VStack {
                Spacer()
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .light)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black.opacity(0.65), location: 0.35),
                                .init(color: .black, location: 0.70)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 110)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .bottom)

            // Floating Navigation Bar (Positioned above safe area)
            FloatingTabBar(currentTab: $navViewModel.currentTab)
        }
    }
}

// MARK: - Notifications Sheet (Matching Discover Screen UI Design)
public struct NotificationsSheetView: View {
    @ObservedObject public var navViewModel: AppNavigationViewModel
    @ObservedObject public var discoverViewModel: DiscoverViewModel
    @ObservedObject public var communityViewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFilter: NotificationCategory
    @State private var communityFilter: CommunityNotificationFilter = .all

    public init(
        navViewModel: AppNavigationViewModel,
        discoverViewModel: DiscoverViewModel,
        communityViewModel: CommunityViewModel
    ) {
        self.navViewModel = navViewModel
        self.discoverViewModel = discoverViewModel
        self.communityViewModel = communityViewModel
        self._selectedFilter = State(initialValue: navViewModel.notificationsInitialCategory)
    }

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Action Bar: Glass Cross on Left Top Corner, Mark all read on Right Top Corner
                HStack(alignment: .center) {
                    // Close Button on Left Top Corner
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .frame(width: 40, height: 40)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .alineGlassCircleButton()

                    Spacer()

                    // Mark all read button on Right Top Corner
                    if navViewModel.unreadNotificationsCount > 0 {
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                navViewModel.unreadNotificationsCount = 0
                            }
                        } label: {
                            Text("Mark all read")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 8)

                // Header Title & Subtitle Row (Matching Discover Screen: Hero Headline + subtitle + unread badge)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("NOTIFICATIONS")
                            .font(.system(size: 26, weight: .black, design: .default))
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

                    Text("Updates on opportunities, community discussions & replies")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                // Filter Pills (Matching Discover Feed Segments: "Opportunity" and "Community")
                HStack(alignment: .center, spacing: 8) {
                    ForEach(NotificationCategory.allCases, id: \.self) { cat in
                        let isSelected = selectedFilter == cat
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                selectedFilter = cat
                            }
                        } label: {
                            Text(cat.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                                .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .alineGlassCapsule(selected: isSelected)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 14)

                Divider().opacity(0.12)

                // Notifications Cards Feed (Matching Discover Screen Card Style)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        if selectedFilter == .opportunities {
                            // OPPORTUNITY NOTIFICATIONS (same card as Discover's Explore More, plus a View button)
                            opportunityNotificationCard(oppId: "opp-google-4", companyName: "Google", time: "10m ago", isUnread: true)
                            opportunityNotificationCard(oppId: "opp-ola-1", companyName: "Ola", time: "35m ago", isUnread: true)
                            opportunityNotificationCard(oppId: "opp-flipkart-2", companyName: "Flipkart", time: "2h ago", isUnread: false)
                            opportunityNotificationCard(oppId: "opp-apple-3", companyName: "Apple", time: "1d ago", isUnread: false)
                        } else {
                            // COMMUNITY NOTIFICATIONS (compact cards styled like the Community feed posts)
                            communityFilterRow

                            let items = CommunityNotificationItem.samples.filter {
                                communityFilter == .all || $0.kind.filter == communityFilter
                            }
                            ForEach(items) { item in
                                communityNotificationCard(item)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            selectedFilter = navViewModel.notificationsInitialCategory
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .environment(\.colorScheme, .light)
    }

    // MARK: - Community Filter Row (All / Likes / Comments / Posts)
    private var communityFilterRow: some View {
        HStack(spacing: 8) {
            ForEach(CommunityNotificationFilter.allCases, id: \.self) { filter in
                let isSelected = communityFilter == filter
                Button {
                    withAnimation(AlineTheme.fastSpring) {
                        communityFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(isSelected ? AlineTheme.pillDark : Color.white)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(isSelected ? 0 : 0.08), lineWidth: 1)
                                .allowsHitTesting(false)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Opportunity Notification Card (Explore More card + View button)
    @ViewBuilder
    private func opportunityNotificationCard(
        oppId: String,
        companyName: String,
        time: String,
        isUnread: Bool
    ) -> some View {
        let targetOpp = discoverViewModel.opportunities.first(where: { $0.id == oppId })
            ?? Opportunity.dataset.first(where: { $0.id == oppId })
            ?? Opportunity.samples.first(where: { $0.companyName == companyName })
            ?? Opportunity.samples[0]
        let showsUnreadDot = navViewModel.isNotificationUnread(oppId, initiallyUnread: isUnread)
        let shortLocation = targetOpp.location.components(separatedBy: ",").first ?? targetOpp.location

        VStack(alignment: .leading, spacing: 12) {
            // Row 1: company (logo + name + unread dot) on the left, match score on the right
            HStack(spacing: 10) {
                CompanyLogoBadge(companyName: targetOpp.companyName, size: 36, isSquircle: true)

                Text(targetOpp.companyName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .lineLimit(1)

                if showsUnreadDot {
                    Circle()
                        .fill(AlineTheme.accentHeart)
                        .frame(width: 8, height: 8)
                }

                Spacer(minLength: 8)

                Text("\(targetOpp.matchScore)% Match")
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(targetOpp.matchBadgeForegroundColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(targetOpp.matchBadgeBackgroundColor)
                    .clipShape(Capsule())
                    .fixedSize(horizontal: true, vertical: false)
            }

            // Row 2: job role
            Text(targetOpp.roleTitle)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            // Row 3: quiet meta line + View button
            HStack(spacing: 6) {
                Text(shortLocation)
                Text("·")
                Text(targetOpp.opportunityType.rawValue)
                Text("·")
                Text(time)
                Spacer(minLength: 8)
                Button {
                    openOpportunity(targetOpp, notificationID: oppId, isUnread: isUnread)
                } label: {
                    Text("View")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize()
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(AlineTheme.pillDark)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(AlineTheme.inkMuted)
            .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1.0)
                .allowsHitTesting(false)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            openOpportunity(targetOpp, notificationID: oppId, isUnread: isUnread)
        }
    }

    // MARK: - Community Notification Card (compact, styled like a Community feed post)
    @ViewBuilder
    private func communityNotificationCard(_ item: CommunityNotificationItem) -> some View {
        let targetPost = communityViewModel.posts.first(where: { $0.id == item.postId })
            ?? DiscussionPost.samples.first(where: { $0.id == item.postId })
            ?? DiscussionPost.samples[0]
        let actorAvatar = communityViewModel.posts.first(where: { $0.authorName == item.actor })?.resolvedAvatar
            ?? targetPost.resolvedAvatar
        let showsUnreadDot = navViewModel.isNotificationUnread(item.id, initiallyUnread: item.isUnread)
        let snippet = item.snippet.isEmpty ? targetPost.excerpt : item.snippet

        VStack(alignment: .leading, spacing: 8) {
            // Top row: who did it (feed-style avatar with a small activity badge), what they did, when
            HStack(alignment: .center, spacing: 10) {
                Image(actorAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: item.kind.iconName)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(AlineTheme.pillDark))
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(x: 5, y: 5)
                            .allowsHitTesting(false)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("**\(item.actor)** \(item.kind.actionText(company: targetPost.companyName))")
                        .font(.system(size: 14))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(2)

                    Text(item.time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AlineTheme.inkSecondary)
                }

                Spacer(minLength: 8)

                if showsUnreadDot {
                    Circle()
                        .fill(AlineTheme.accentHeart)
                        .frame(width: 8, height: 8)
                }
            }

            // Post title, like the feed card headline
            Text(targetPost.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
                .lineLimit(1)

            // The comment / liked comment / post excerpt
            Text(snippet)
                .font(.system(size: 13))
                .foregroundColor(AlineTheme.inkSecondary)
                .lineLimit(2)
                .lineSpacing(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1.0)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            openCommunityPost(targetPost, notificationID: item.id, isUnread: item.isUnread)
        }
    }

    // MARK: - Navigation Redirection
    private func openOpportunity(_ opp: Opportunity, notificationID: String, isUnread: Bool) {
        navViewModel.markNotificationRead(notificationID, initiallyUnread: isUnread)
        navViewModel.currentTab = .discover
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            navViewModel.targetOpportunity = opp
        }
    }

    private func openCommunityPost(_ post: DiscussionPost, notificationID: String, isUnread: Bool) {
        navViewModel.markNotificationRead(notificationID, initiallyUnread: isUnread)
        navViewModel.currentTab = .community
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            navViewModel.targetCommunityPost = post
        }
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
    return NotificationsSheetView(
        navViewModel: nav,
        discoverViewModel: DiscoverViewModel(),
        communityViewModel: CommunityViewModel()
    )
}

#Preview("Collective App (Dark Mode)") {
    MainAppView()
        .preferredColorScheme(.dark)
}

// MARK: - Community Notification Data (mock activity on the user's posts and comments)
struct CommunityNotificationItem: Identifiable {
    enum Kind {
        case commentedOnPost
        case repliedToComment
        case likedComment
        case likedPost
        case newPost

        var filter: CommunityNotificationFilter {
            switch self {
            case .likedComment, .likedPost: return .likes
            case .commentedOnPost, .repliedToComment: return .comments
            case .newPost: return .posts
            }
        }

        var iconName: String {
            switch self {
            case .commentedOnPost: return "bubble.right.fill"
            case .repliedToComment: return "arrowshape.turn.up.left.fill"
            case .likedComment, .likedPost: return "hand.thumbsup.fill"
            case .newPost: return "square.and.pencil"
            }
        }

        func actionText(company: String?) -> String {
            switch self {
            case .commentedOnPost: return "commented on your post"
            case .repliedToComment: return "replied to your comment"
            case .likedComment: return "liked your comment"
            case .likedPost: return "liked your post"
            case .newPost:
                if let company, !company.isEmpty { return "posted in \(company) Community" }
                return "posted a new discussion"
            }
        }
    }

    let id: String
    let kind: Kind
    let actor: String
    let postId: String
    /// Comment text shown under the title; empty uses the post excerpt
    let snippet: String
    let time: String
    let isUnread: Bool

    static let samples: [CommunityNotificationItem] = [
        CommunityNotificationItem(
            id: "notif-com-12-1",
            kind: .commentedOnPost,
            actor: "pixel_Corgi",
            postId: "post-12",
            snippet: "Block 45 minutes right after your last class and only do one pattern per week. Consistency beats volume.",
            time: "20m ago",
            isUnread: true
        ),
        CommunityNotificationItem(
            id: "notif-like-com-2",
            kind: .likedComment,
            actor: "algo_Panda",
            postId: "post-1",
            snippet: "Did you need to write full syntactically compilable code or was pseudo-code acceptable initially?",
            time: "1h ago",
            isUnread: true
        ),
        CommunityNotificationItem(
            id: "notif-reply-com-2",
            kind: .repliedToComment,
            actor: "rc_Falcon",
            postId: "post-1",
            snippet: "Pseudo-code was fine for the first pass, but they asked me to turn the core loop into real code before time ran out.",
            time: "2h ago",
            isUnread: false
        ),
        CommunityNotificationItem(
            id: "notif-com-12-2",
            kind: .commentedOnPost,
            actor: "stripe_Hacker",
            postId: "post-12",
            snippet: "Skip contests during exam weeks and revise old problems instead. It keeps the streak without the stress.",
            time: "3h ago",
            isUnread: false
        ),
        CommunityNotificationItem(
            id: "notif-like-post-12",
            kind: .likedPost,
            actor: "swift_Otter",
            postId: "post-12",
            snippet: "",
            time: "5h ago",
            isUnread: false
        ),
        CommunityNotificationItem(
            id: "notif-post-4",
            kind: .newPost,
            actor: "algo_Panda",
            postId: "post-4",
            snippet: "",
            time: "1d ago",
            isUnread: false
        ),
        CommunityNotificationItem(
            id: "notif-post-6",
            kind: .newPost,
            actor: "cyber_Penguin",
            postId: "post-6",
            snippet: "",
            time: "2d ago",
            isUnread: false
        )
    ]
}

// MARK: - Community Notification Filter (All, or just likes / comments & replies / new posts)
enum CommunityNotificationFilter: String, CaseIterable {
    case all = "All"
    case likes = "Likes"
    case comments = "Comments"
    case posts = "Posts"
}
