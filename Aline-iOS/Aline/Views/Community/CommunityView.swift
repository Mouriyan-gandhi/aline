import SwiftUI

// MARK: - Community & Interview Prep View (Refined UI with Compact Cards, Full Page View More, Notification & Bookmark Header, Realtime Comments)
public struct CommunityView: View {
    @ObservedObject public var communityViewModel: CommunityViewModel
    @ObservedObject public var prepViewModel: InterviewPrepViewModel
    @ObservedObject public var navViewModel: AppNavigationViewModel

    @State private var selectedSegment: CommunitySegment = .discussions
    @State private var selectedPost: DiscussionPost? = nil
    @State private var selectedQuestion: InterviewQuestion? = nil
    @State private var currentDetailQuestions: [InterviewQuestion] = []
    @State private var selectedCompanyCommunity: CompanyCommunity? = nil
    @State private var searchActive: Bool = false
    @State private var focusCommentsOnOpen: Bool = false
    @State private var selectedTrendingSwipePost: DiscussionPost? = nil
    @State private var showTrendingSwipeDeck: Bool = false

    public init(
        communityViewModel: CommunityViewModel,
        prepViewModel: InterviewPrepViewModel,
        navViewModel: AppNavigationViewModel
    ) {
        self.communityViewModel = communityViewModel
        self.prepViewModel = prepViewModel
        self.navViewModel = navViewModel
    }

    public enum CommunitySegment: String, CaseIterable {
        case discussions = "Discussions"
        case interviewQuestions = "Interview Questions"
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background Artwork matching Discover Home Screen
                DiscoverBackgroundArtwork()
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AlineSpacing.section) {
                    // Top Header: Title, Notification & Bookmark Icons (Requirement 10)
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("COMMUNITY")
                                .font(.system(size: 32, weight: .black, design: .default))
                                .lineSpacing(2)
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("Real interview loops & career insights")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }

                        Spacer()

                        HStack(spacing: 10) {
                            // Saved Posts / Questions Bookmark Button (Reflects Active Segment)
                            Button {
                                if selectedSegment == .discussions {
                                    communityViewModel.showSavedPostsSheet = true
                                } else {
                                    prepViewModel.showSavedQuestionsSheet = true
                                }
                            } label: {
                                ZStack {
                                    Color.clear.frame(width: 40, height: 40).alineGlassCircle(selected: false)
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                }
                            }
                            .buttonStyle(.plain)

                            // Notifications Bell Button matching Discover Home Screen
                            Button {
                                navViewModel.openNotifications(category: .community)
                            } label: {
                                ZStack {
                                    Color.clear.frame(width: 40, height: 40).alineGlassCircle(selected: false)
                                    Image(systemName: "bell")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(AlineTheme.inkPrimary)

                                    if navViewModel.unreadNotificationsCount > 0 {
                                        Circle()
                                            .fill(AlineTheme.accentHeart)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 10, y: -10)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    // Top Segment Switcher (Discussions vs Interview Questions)
                    HStack(spacing: 12) {
                        ForEach(CommunitySegment.allCases, id: \.self) { segment in
                            let isSelected = selectedSegment == segment
                            Button {
                                withAnimation(AlineTheme.fastSpring) {
                                    selectedSegment = segment
                                }
                            } label: {
                                Text(segment.rawValue)
                                    .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                                    .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .alineGlassCapsule(selected: isSelected)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Search Bar (Matching Discover Screen Styling via native AlineSearchField)
                    AlineSearchField(
                        selectedSegment == .discussions ? "Search discussions, companies..." : "Search interview questions, companies...",
                        text: selectedSegment == .discussions ? $communityViewModel.searchQuery : $prepViewModel.searchQuery,
                        isActive: $searchActive
                    )
                    .padding(.horizontal, 24)

                    // Sub-filter Pills for Discussions: "For You" vs "Following"
                    if selectedSegment == .discussions {
                        HStack(spacing: 10) {
                            ForEach(CommunityViewModel.CommunitySubFeed.allCases, id: \.self) { feed in
                                let isSelected = communityViewModel.selectedSubFeed == feed
                                Button {
                                    withAnimation(AlineTheme.fastSpring) {
                                        communityViewModel.selectedSubFeed = feed
                                    }
                                } label: {
                                    Text(feed.rawValue)
                                        .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                                        .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .padding(.horizontal, 22)
                                        .padding(.vertical, 9)
                                        .alineGlassCapsule(selected: isSelected)
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }

                    // Body content based on active segment
                    if selectedSegment == .discussions {
                        if communityViewModel.selectedSubFeed == .forYou {
                            forYouDiscussionsContent
                        } else {
                            followingCompaniesContent
                        }
                    } else {
                        if searchActive || !prepViewModel.searchQuery.isEmpty {
                            interviewSearchOverlayContent
                        } else {
                            interviewPrepContent
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .frame(maxWidth: .infinity)

            // Floating Pen / Compose Icon in Bottom Right Corner (Requirement 9)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        if selectedSegment == .discussions {
                            communityViewModel.showCreatePostSheet = true
                        } else {
                            prepViewModel.showContributeSheet = true
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(AlineTheme.pillDark)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.black.opacity(0.20), radius: 6, x: 0, y: 3)
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20) // Positioned directly at the top of the tab bar on the right side
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedPost) { post in
            DiscussionDetailView(post: post, viewModel: communityViewModel, initialFocusComments: focusCommentsOnOpen)
        }
        .navigationDestination(item: $selectedQuestion) { question in
            InterviewQuestionDetailView(
                questions: currentDetailQuestions.isEmpty ? [question] : currentDetailQuestions,
                initialQuestion: question,
                viewModel: prepViewModel
            )
        }
        .navigationDestination(isPresented: $prepViewModel.wizardActive) {
            InterviewWizardFlowView(viewModel: prepViewModel) { q, list in
                currentDetailQuestions = list
                selectedQuestion = q
            }
        }
        .navigationDestination(item: $selectedCompanyCommunity) { company in
            CompanyCommunityDetailView(
                company: company,
                viewModel: communityViewModel,
                onSelectPost: { post in
                    selectedPost = post
                }
            )
        }
        .sheet(isPresented: $communityViewModel.showCreatePostSheet) {
            CreateDiscussionPostView(viewModel: communityViewModel)
        }
        // Saved posts / questions open as full pages in the Community stack, not sheets
        .navigationDestination(isPresented: $communityViewModel.showSavedPostsSheet) {
            SavedPostsView(viewModel: communityViewModel)
        }
        .navigationDestination(isPresented: $prepViewModel.showSavedQuestionsSheet) {
            SavedInterviewQuestionsView(viewModel: prepViewModel)
        }
        // Requirement 9: "when i click view more it should cover the whole page like it covers in the view more of the recommended parts"
        .fullScreenCover(isPresented: $communityViewModel.showAllTrendingSheet) {
            AllTrendingDiscussionsView(viewModel: communityViewModel, onSelectPost: { post in
                selectedTrendingSwipePost = post
                showTrendingSwipeDeck = true
            })
        }
        .fullScreenCover(isPresented: $showTrendingSwipeDeck) {
            TrendingTopicSwipeView(
                initialPost: selectedTrendingSwipePost,
                allPosts: communityViewModel.trendingPosts,
                viewModel: communityViewModel,
                onDismiss: {
                    showTrendingSwipeDeck = false
                },
                onOpenDiscussion: { post in
                    showTrendingSwipeDeck = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedPost = post
                    }
                }
            )
        }
        .sheet(isPresented: $prepViewModel.showContributeSheet) {
            ContributeQuestionModalView(viewModel: prepViewModel) {
                selectedSegment = .interviewQuestions
            }
        }
        .sheet(isPresented: $prepViewModel.showAllCompaniesSheet) {
            AllCompaniesSelectorSheet(viewModel: prepViewModel)
        }
        .sheet(isPresented: $prepViewModel.showAllRolesSheet) {
            AllRolesSelectorSheet(viewModel: prepViewModel)
        }
        .sheet(isPresented: $prepViewModel.showAllTopicsSheet) {
            AllTopicsSelectorSheet(viewModel: prepViewModel)
        }
        .onChange(of: navViewModel.targetCommunityPost) { _, newPost in
            if let post = newPost {
                selectedSegment = .discussions
                selectedPost = post
                navViewModel.targetCommunityPost = nil
            }
        }
    }
    .environment(\.colorScheme, .light)
}

    // MARK: - "For You" Section
    @ViewBuilder
    private var forYouDiscussionsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Horizontal Scroll for Trending Topics with "View more"
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Trending Discussions")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("Popular among students & interns")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }

                    Spacer()

                    // Requirement 9: Opens Full Screen View
                    Button {
                        communityViewModel.showAllTrendingSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("View more")
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(AlineTheme.inkPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .alineGlassCapsule(selected: false)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                // Horizontal Carousel of Compact Trending Cards (Requirement 1, 4)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(communityViewModel.trendingPosts.prefix(5)) { post in
                            TrendingDiscussionCard(
                                post: post,
                                onTap: {
                                    selectedTrendingSwipePost = post
                                    showTrendingSwipeDeck = true
                                },
                                onToggleLike: {
                                    withAnimation(AlineTheme.fastSpring) {
                                        communityViewModel.toggleLike(for: post.id)
                                    }
                                },
                                onTapComment: {
                                    selectedTrendingSwipePost = post
                                    showTrendingSwipeDeck = true
                                },
                                onShare: {
                                    communityViewModel.incrementShare(for: post.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
                }
            }

            // Category Chips Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        communityViewModel.selectedCategory = nil
                    } label: {
                        Text("All")
                            .font(.system(size: 13, weight: communityViewModel.selectedCategory == nil ? .bold : .medium))
                            .foregroundColor(communityViewModel.selectedCategory == nil ? .white : AlineTheme.inkPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .alineGlassCapsule(selected: communityViewModel.selectedCategory == nil)
                    }

                    ForEach(DiscussionType.allCases, id: \.self) { type in
                        let isSelected = communityViewModel.selectedCategory == type
                        Button {
                            communityViewModel.selectedCategory = isSelected ? nil : type
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: type.iconName)
                                    .font(.system(size: 11))
                                Text(type.rawValue)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            }
                            .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .alineGlassCapsule(selected: isSelected)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Normal Discussions Section Header & Cards
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Discussions")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Spacer()
                    Text("\(communityViewModel.filteredPosts.count) Posts")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
                .padding(.horizontal, 24)

                // Normal Discussions Vertical List (Compact Cards - Requirement 4)
                VStack(spacing: 16) {
                    if communityViewModel.filteredPosts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 36))
                                .foregroundColor(AlineTheme.inkMuted)
                            Text("No discussions found")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(communityViewModel.filteredPosts) { post in
                            CommunityDiscussionCard(
                                post: post,
                                onTap: {
                                    focusCommentsOnOpen = false
                                    selectedPost = post
                                },
                                onToggleLike: {
                                    withAnimation(AlineTheme.fastSpring) {
                                        communityViewModel.toggleLike(for: post.id)
                                    }
                                },
                                onToggleSave: {
                                    withAnimation(AlineTheme.fastSpring) {
                                        communityViewModel.toggleSave(for: post.id)
                                    }
                                },
                                onTapComment: {
                                    focusCommentsOnOpen = true
                                    selectedPost = post
                                },
                                onShare: {
                                    communityViewModel.incrementShare(for: post.id)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 120)
        }
    }

    // MARK: - "Following" Section
    @ViewBuilder
    private var followingCompaniesContent: some View {
        VStack(alignment: .leading, spacing: 26) {
            // Section 1: Your followed companies
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Your followed companies")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Spacer()
                    Text("\(communityViewModel.followedCompanies.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.pillDark)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)

                if communityViewModel.followedCompanies.isEmpty {
                    Text("You aren't following any company communities yet. Follow companies below to get direct updates.")
                        .font(.system(size: 13))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 12) {
                        ForEach(communityViewModel.followedCompanies) { company in
                            FollowedCompanyCard(
                                company: company,
                                onToggleFollow: {
                                    withAnimation(AlineTheme.fastSpring) {
                                        communityViewModel.toggleFollowCompany(name: company.name)
                                    }
                                },
                                onTap: {
                                    selectedCompanyCommunity = company
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }

            // Section 2: More company communities to follow
            VStack(alignment: .leading, spacing: 14) {
                Text("More communities to follow")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    ForEach(communityViewModel.moreCompaniesToFollow) { company in
                        FollowedCompanyCard(
                            company: company,
                            onToggleFollow: {
                                withAnimation(AlineTheme.fastSpring) {
                                    communityViewModel.toggleFollowCompany(name: company.name)
                                }
                            },
                            onTap: {
                                selectedCompanyCommunity = company
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 120)
        }
    }

    // MARK: - Interview Prep Section (3 Main Grids: Popular Companies, Explore by Role, Explore by Topics)
    @ViewBuilder
    private var interviewPrepContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Continue From Where You Left (On top of Popular Companies)
            if let session = prepViewModel.lastVisitedSession {
                continueFromWhereYouLeftSection(session)
            }

            // 1. Popular Companies Section (4x2 Grid with See all)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text("Popular Companies")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    Spacer()

                    Button {
                        prepViewModel.showAllCompaniesSheet = true
                    } label: {
                        Text("See all")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AlineTheme.pillDark)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                let companyColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
                LazyVGrid(columns: companyColumns, spacing: 10) {
                    ForEach(prepViewModel.popularCompanies.prefix(6), id: \.self) { comp in
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                prepViewModel.startWizardFromCompany(comp)
                            }
                        } label: {
                            VStack(spacing: 8) {
                                CompanyLogoBadge(companyName: comp, size: 38, isSquircle: true)

                                Text(comp)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 84)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }

            // 2. Explore by Role Section (Single Line of Chips with See all)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text("Explore by Role")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    Spacer()

                    Button {
                        prepViewModel.showAllRolesSheet = true
                    } label: {
                        Text("See all")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AlineTheme.pillDark)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(prepViewModel.popularRoles, id: \.self) { role in
                            prepRoleChip(role)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .scrollBounceBehavior(.always, axes: .horizontal)
            }

            // 3. Explore by Topics Section (3 Columns Grid with Pastel Icons & See all)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text("Explore by Topics")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    Spacer()

                    Button {
                        prepViewModel.showAllTopicsSheet = true
                    } label: {
                        Text("See all")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AlineTheme.pillDark)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                let topicColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
                LazyVGrid(columns: topicColumns, spacing: 10) {
                    ForEach(prepViewModel.popularTopics) { topic in
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                prepViewModel.startWizardFromTopic(topic)
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(topic.iconBgColor)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: topic.iconName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(topic.iconColor)
                                }

                                Text(topic.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 92)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 120)
        }
    }

    // MARK: - Continue from where you left Section
    @ViewBuilder
    private func continueFromWhereYouLeftSection(_ session: LastVisitedQuestionSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AlineTheme.accentAmber)

                    Text("Continue from where you left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }

                Spacer()

                Button {
                    withAnimation(AlineTheme.fastSpring) {
                        prepViewModel.clearLastVisitedSession()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AlineTheme.inkMuted)
                        .padding(6)
                        .background(Circle().fill(Color.black.opacity(0.04)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)

            Button {
                resumePracticeSession(session)
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    CompanyLogoBadge(
                        companyName: session.companyName ?? "General",
                        size: 46,
                        isSquircle: true
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 6) {
                            Text(session.companyName ?? "General Practice")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)

                            if let role = session.role, !role.isEmpty {
                                Text("·")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AlineTheme.inkMuted)
                                Text(role)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AlineTheme.inkSecondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text("Q \(session.questionIndex + 1) of \(session.totalQuestions)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.04))
                                .clipShape(Capsule())
                        }

                        Text(session.questionText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(2)
                            .lineSpacing(2)
                            .multilineTextAlignment(.leading)

                        HStack(alignment: .center) {
                            if let topic = session.topic {
                                HStack(spacing: 4) {
                                    Image(systemName: topic.iconName)
                                        .font(.system(size: 10))
                                    Text(topic.rawValue)
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(topic.iconColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(topic.iconBgColor)
                                .clipShape(Capsule())
                            }

                            Spacer()

                            HStack(spacing: 5) {
                                Text("Continue")
                                    .font(.system(size: 12, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(AlineTheme.pillDark)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.07), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
        }
    }

    private func resumePracticeSession(_ session: LastVisitedQuestionSession) {
        prepViewModel.wizardSelectedCompany = session.companyName
        prepViewModel.wizardSelectedRole = session.role
        prepViewModel.wizardSelectedTopic = session.topic
        if let t = session.topic {
            prepViewModel.wizardSelectedTopics = [t]
        }

        let questionsToUse = session.questionsList.isEmpty ? prepViewModel.wizardFilteredQuestions : session.questionsList
        currentDetailQuestions = questionsToUse

        let targetQuestion = questionsToUse.first(where: { $0.id == session.questionId }) ??
            InterviewQuestion(
                id: session.questionId,
                questionText: session.questionText,
                topic: session.topic ?? .dsa,
                companyName: session.companyName,
                role: session.role,
                difficulty: "General",
                upvotesCount: 0,
                isUpvoted: false,
                isSaved: false,
                hint: nil,
                approach: nil
            )

        withAnimation(AlineTheme.fastSpring) {
            selectedQuestion = targetQuestion
        }
    }

    @ViewBuilder
    private func prepRoleChip(_ role: String) -> some View {
        Button {
            withAnimation(AlineTheme.fastSpring) {
                prepViewModel.startWizardFromRole(role)
            }
        } label: {
            Text(role)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AlineTheme.inkPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func activeFilterPill(text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AlineTheme.pillDark)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AlineTheme.pillDark)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AlineTheme.cardMint.opacity(0.45))
        .clipShape(Capsule())
    }

    // Live Search Overlay Screen (Item 13)
    private var interviewSearchOverlayContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            let query = prepViewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

            // Live Matching Companies
            let matchingCompanies = query.isEmpty ? [] : prepViewModel.allCompanies.filter { $0.localizedCaseInsensitiveContains(query) }
            if !matchingCompanies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("COMPANIES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(matchingCompanies, id: \.self) { comp in
                                Button {
                                    prepViewModel.selectedCompanies = [comp]
                                    prepViewModel.searchQuery = ""
                                    searchActive = false
                                } label: {
                                    Text(comp)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .scrollBounceBehavior(.always, axes: .horizontal)
                }
            }

            // Live Matching Roles
            let matchingRoles = query.isEmpty ? [] : prepViewModel.allRoles.filter { $0.localizedCaseInsensitiveContains(query) }
            if !matchingRoles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ROLES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(matchingRoles, id: \.self) { role in
                                Button {
                                    prepViewModel.selectedRoles = [role]
                                    prepViewModel.searchQuery = ""
                                    searchActive = false
                                } label: {
                                    Text(role)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .scrollBounceBehavior(.always, axes: .horizontal)
                }
            }

            // Questions Search Results
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("SEARCH RESULTS (\(prepViewModel.filteredQuestions.count))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AlineTheme.inkSecondary)

                    Spacer()

                    if !query.isEmpty {
                        Button("Clear") {
                            prepViewModel.searchQuery = ""
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AlineTheme.pillDark)
                    }
                }
                .padding(.horizontal, 24)

                if prepViewModel.filteredQuestions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(AlineTheme.inkMuted)
                        Text(query.isEmpty ? "Type to search interview questions" : "No results for \"\(query)\"")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("Try searching by company (e.g. Google), role, or algorithmic topic.")
                            .font(.system(size: 12))
                            .foregroundColor(AlineTheme.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(28)
                    .background(Color.white.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.06), lineWidth: 1))
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 12) {
                        ForEach(prepViewModel.filteredQuestions) { q in
                            interviewQuestionFeedCard(q: q)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }

            Spacer(minLength: 120)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func interviewQuestionFeedCard(q: InterviewQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Company + Role + Topic (Text-only pills, single line, no icons - Request 1)
            HStack(spacing: 8) {
                if let comp = q.companyName {
                    Text(comp)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                }

                if let role = q.role {
                    Text(role)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.04))
                        .clipShape(Capsule())
                }

                Text(q.topic.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.04))
                    .clipShape(Capsule())

                Spacer()
            }

            Text(q.questionText)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
                .lineLimit(3)
                .lineSpacing(2)

            // Footer info (Item 9: "Solution", NOT "Verified")
            HStack {
                if q.hasAIGeneratedSolution {
                    Text("AI Foundation Solution")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.15))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 1.0, green: 0.94, blue: 0.88))
                        .clipShape(Capsule())
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                        Text("Solution")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AlineTheme.pillDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AlineTheme.cardMint.opacity(0.4))
                    .clipShape(Capsule())
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Practice")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.pillDark)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AlineTheme.pillDark)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedQuestion = q
        }
    }
}

// MARK: - Community Discussion Card (Compact, Rectangular Profile Avatar, Working Buttons, Excerpt with 2+ Lines - Requirements 1, 2, 3, 4, 5)
public struct CommunityDiscussionCard: View {
    public let post: DiscussionPost
    public let onTap: () -> Void
    public let onToggleLike: () -> Void
    public let onToggleSave: () -> Void
    public var onTapComment: (() -> Void)? = nil
    public var onShare: (() -> Void)? = nil

    public init(
        post: DiscussionPost,
        onTap: @escaping () -> Void,
        onToggleLike: @escaping () -> Void,
        onToggleSave: @escaping () -> Void,
        onTapComment: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil
    ) {
        self.post = post
        self.onTap = onTap
        self.onToggleLike = onToggleLike
        self.onToggleSave = onToggleSave
        self.onTapComment = onTapComment
        self.onShare = onShare
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Rectangular Cute Animal Profile Image (Requirement 5) + Author Name + Bookmark Button
            HStack(alignment: .center, spacing: 10) {
                // Profile Avatar: rectangular with proper fill
                Image(post.resolvedAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    // Author Display (No company if general discussion - Requirement 3)
                    Text(post.authorDisplayWithCompany)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(1)

                    Text(post.timeAgo)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Bookmark Icon Button (Working independently - Requirement 2)
                Button {
                    onToggleSave()
                } label: {
                    Image(systemName: post.isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(post.isSaved ? AlineTheme.pillDark : AlineTheme.inkPrimary)
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Tag: e.g. "Interview Experience"
            Text(post.type.rawValue)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AlineTheme.pillDark)

            // Title: Bold headline
            Text(post.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
                .lineSpacing(2)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }

            // Excerpt with at least 2 full lines of content without huge empty gaps (Requirement 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(post.excerpt)
                    .font(.system(size: 13))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineLimit(2)
                    .lineSpacing(2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTap()
                    }

                Button {
                    onTap()
                } label: {
                    Text("read more")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.accentEmerald)
                }
                .buttonStyle(.plain)
            }

            actionRow
        }
        .padding(14) // Slightly smaller card padding (Requirement 4)
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
            onTap()
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        HStack(spacing: 16) {
            Button {
                onToggleLike()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: post.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(post.isLiked ? AlineTheme.pillDark : AlineTheme.inkPrimary)
                    Text(String(post.likesCount))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                (onTapComment ?? onTap)()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Text(String(post.totalCommentsCount))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ShareLink(item: "\(post.title)\n\n\(post.excerpt)") {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    if post.sharesCount > 0 {
                        Text(String(post.sharesCount))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                onShare?()
            })

            Spacer()
        }
        .padding(.top, 2)
    }
}

// MARK: - Trending Discussion Card (Horizontal Carousel - Compact & Rich Content - Requirement 1, 4)
public struct TrendingDiscussionCard: View {
    public let post: DiscussionPost
    public let onTap: () -> Void
    public let onToggleLike: () -> Void
    public var onTapComment: (() -> Void)? = nil
    public var onShare: (() -> Void)? = nil

    public init(
        post: DiscussionPost,
        onTap: @escaping () -> Void,
        onToggleLike: @escaping () -> Void,
        onTapComment: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil
    ) {
        self.post = post
        self.onTap = onTap
        self.onToggleLike = onToggleLike
        self.onTapComment = onTapComment
        self.onShare = onShare
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(post.resolvedAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(post.authorDisplayWithCompany)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(1)
                    Text(post.timeAgo)
                        .font(.system(size: 10))
                        .foregroundColor(AlineTheme.inkMuted)
                }

                Spacer()

                Text(post.type.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(AlineTheme.pillDark)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Capsule())
                    .lineLimit(1)
            }

            Text(post.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
                .lineLimit(1)

            // Content filled for at least 2 lines (Requirement 1)
            Text(post.excerpt)
                .font(.system(size: 11))
                .foregroundColor(AlineTheme.inkSecondary)
                .lineLimit(2)
                .lineSpacing(1.5)

            actionRow
        }
        .padding(12)
        .frame(width: 250, height: 148) // Compact, sleek dimensions (Requirement 4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1.0)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                onToggleLike()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: post.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(post.isLiked ? AlineTheme.pillDark : AlineTheme.inkPrimary)
                    Text(String(post.likesCount))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                (onTapComment ?? onTap)()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Text(String(post.totalCommentsCount))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Share Button (Requirement 7 & User Request 3)
            ShareLink(item: "\(post.title)\n\n\(post.excerpt)") {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    if post.sharesCount > 0 {
                        Text(String(post.sharesCount))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                    }
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                onShare?()
            })

            Spacer()

            Text("Read")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AlineTheme.accentEmerald)
        }
    }
}

// MARK: - Followed Company Card (Matching User Request 6)
public struct FollowedCompanyCard: View {
    public let company: CompanyCommunity
    public let onToggleFollow: () -> Void
    public var onTap: (() -> Void)? = nil

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Logo + (Company Name & Member Count) + Aligned Follow Button on Right
            HStack(alignment: .center, spacing: 12) {
                CompanyLogoBadge(companyName: company.name, size: 44, isSquircle: true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(company.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(1)

                    Text(company.memberCount)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    onToggleFollow()
                } label: {
                    HStack(spacing: 4) {
                        if company.isFollowing {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                            Text("Following")
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Follow")
                        }
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(company.isFollowing ? AlineTheme.inkPrimary : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .alineGlassCapsule(selected: !(company.isFollowing))
                }
                .buttonStyle(.plain)
            }

            // Below All Those: Small Description of the Company
            Text(company.description)
                .font(.system(size: 12))
                .foregroundColor(AlineTheme.inkSecondary)
                .lineLimit(2)
                .lineSpacing(2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1.0)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Trending Swipe Direction
public enum TrendingSwipeDirection {
    case left
    case right
}

// MARK: - Trending Topic Swipe Deck (Immersive Black Experience with Left/Right Swipe & Floating Top)
public struct TrendingTopicSwipeView: View {
    public let initialPost: DiscussionPost?
    public let allPosts: [DiscussionPost]
    @ObservedObject public var viewModel: CommunityViewModel
    public let onDismiss: () -> Void
    public var onOpenDiscussion: ((DiscussionPost) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int = 0
    @State private var cardOffset: CGSize = .zero
    @State private var dragAngle: Double = 0
    @State private var isAnimatingSwipe: Bool = false
    @State private var showDiscussionSheet: DiscussionPost? = nil
    @State private var openDiscussionAtComments: Bool = false
    /// True while a right drag is far enough that letting go will upvote (drives the soft "armed" haptic)
    @State private var isUpvoteArmed: Bool = false
    /// Bumped on every committed upvote (drives the firmer confirmation haptic)
    @State private var upvoteCommitCount: Int = 0
    /// Briefly true as an upvote commits, so the thumb pops before the card leaves
    @State private var isThumbPopping: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far a drag has to travel before letting go commits it
    private let commitDistance: CGFloat = 110

    public init(
        initialPost: DiscussionPost?,
        allPosts: [DiscussionPost],
        viewModel: CommunityViewModel,
        onDismiss: @escaping () -> Void,
        onOpenDiscussion: ((DiscussionPost) -> Void)? = nil
    ) {
        self.initialPost = initialPost
        self.allPosts = allPosts
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.onOpenDiscussion = onOpenDiscussion
    }

    private var deckPosts: [DiscussionPost] {
        if let initial = initialPost {
            var posts = [initial]
            for p in allPosts where p.id != initial.id {
                posts.append(p)
            }
            return posts
        }
        return allPosts
    }

    private func livePost(for post: DiscussionPost) -> DiscussionPost {
        viewModel.posts.first(where: { $0.id == post.id }) ?? post
    }

    /// -1 (fully toward skip) ... 0 (resting) ... 1 (fully toward upvote)
    private var dragProgress: Double {
        max(-1, min(1, Double(cardOffset.width / commitDistance)))
    }
    private var upvoteProgress: Double { max(0, dragProgress) }
    private var skipProgress: Double { max(0, -dragProgress) }

    public var body: some View {
        ZStack {
            // Same pastel background as the rest of the app
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Floating Top Bar: Only cross button and "Trending Topics"
                floatingTopBar
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                Spacer(minLength: 12)

                cardsStackArea
                    .frame(maxWidth: .infinity)

                if currentIndex < deckPosts.count {
                    swipeHint
                        .padding(.top, 22)
                }

                Spacer(minLength: 24)
            }
        }
        // Soft tick when a right drag reaches "release to upvote"; firmer tap when it commits. Left swipes stay silent.
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.55), trigger: isUpvoteArmed) { _, armed in armed }
        .sensoryFeedback(.impact(weight: .medium), trigger: upvoteCommitCount)
        .sheet(item: $showDiscussionSheet) { post in
            NavigationStack {
                DiscussionDetailView(
                    post: livePost(for: post),
                    viewModel: viewModel,
                    initialFocusComments: openDiscussionAtComments
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showDiscussionSheet = nil
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Back")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(AlineTheme.inkPrimary)
                        }
                    }
                }
            }
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Floating Top Bar
    private var floatingTopBar: some View {
        HStack(alignment: .center) {
            // Exit / Cross button (Requirement: "cross button on the top which will exit from the whole thing")
            AlineCloseButton { onDismiss() }

            Spacer()

            // Header: Only "Trending Topics" (Requirement: "And on top I just want trending topics")
            Text("Trending Topics")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)

            Spacer()

            // Invisible placeholder for symmetrical centering
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Card Stack Area
    private var cardsStackArea: some View {
        let lift = abs(dragProgress)

        return ZStack {
            if currentIndex < deckPosts.count {
                // Next card waits underneath and rises as the top card moves away
                if currentIndex + 1 < deckPosts.count {
                    let nextPost = livePost(for: deckPosts[currentIndex + 1])
                    TrendingSwipeCard(post: nextPost, onOpenDiscussion: nil)
                        .scaleEffect(0.93 + 0.05 * lift)
                        .offset(y: 18 * (1 - lift))
                        .opacity(0.5 + 0.5 * lift)
                        .allowsHitTesting(false)
                }

                let activePost = livePost(for: deckPosts[currentIndex])
                TrendingSwipeCard(
                    post: activePost,
                    previewUpvote: isUpvoteArmed,
                    isMoving: cardOffset != .zero || isAnimatingSwipe,
                    onOpenDiscussion: {
                        openDiscussionAtComments = false
                        showDiscussionSheet = activePost
                    },
                    onToggleLike: {
                        withAnimation(AlineTheme.fastSpring) { viewModel.toggleLike(for: activePost.id) }
                    },
                    onOpenComments: {
                        openDiscussionAtComments = true
                        showDiscussionSheet = activePost
                    }
                )
                // Right: the post softly washes out so the thumb reads clearly
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.45 * upvoteProgress))
                        .allowsHitTesting(false)
                }
                // Left: the card quietly recedes, as if set aside: it loses its colour and shrinks a touch (it stays opaque so the next card never shows through)
                .saturation(1 - 0.9 * skipProgress)
                .scaleEffect(1 - 0.05 * skipProgress)
                .offset(x: cardOffset.width, y: cardOffset.height)
                .rotationEffect(.degrees(dragAngle), anchor: .bottom)
                // High priority so the swipe wins over the card's tap and its scrolling text; a tap never moves 10pt, so taps still open the post
                .highPriorityGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { gesture in
                            guard !isAnimatingSwipe else { return }
                            let width = gesture.translation.width
                            cardOffset = CGSize(width: width, height: gesture.translation.height * 0.15)
                            dragAngle = reduceMotion ? 0 : max(-7, min(7, Double(width / 24)))
                            let armed = width > commitDistance
                            if armed != isUpvoteArmed { isUpvoteArmed = armed }
                        }
                        .onEnded { gesture in
                            guard !isAnimatingSwipe else { return }
                            let width = gesture.translation.width
                            let projected = gesture.predictedEndTranslation.width
                            if width > commitDistance || projected > commitDistance * 2 {
                                triggerSwipe(direction: .right)
                            } else if width < -commitDistance || projected < -commitDistance * 2 {
                                triggerSwipe(direction: .left)
                            } else {
                                isUpvoteArmed = false
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                    cardOffset = .zero
                                    dragAngle = 0
                                }
                            }
                        }
                )
                .accessibilityAction(named: "Upvote") { triggerSwipe(direction: .right) }
                .accessibilityAction(named: "Skip") { triggerSwipe(direction: .left) }

                // Right: the same black thumb as the like button grows in the centre, staying put while the card slides away
                upvoteThumb
                    .allowsHitTesting(false)
            } else {
                TrendingSwipeCompletionCard(
                    onRestart: {
                        withAnimation(AlineTheme.cardSpring) {
                            currentIndex = 0
                            cardOffset = .zero
                            dragAngle = 0
                        }
                    },
                    onSeeDiscussions: {
                        onDismiss()
                    }
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Upvote Thumb (grows with the drag, pops on release)
    private var upvoteThumb: some View {
        let p = upvoteProgress
        return ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 150, height: 150)
                .blur(radius: 30)
                .opacity(0.9 * p)
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 76, weight: .semibold))
                .foregroundStyle(AlineTheme.inkPrimary)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                .scaleEffect(isThumbPopping ? 1.22 : 0.55 + 0.45 * p)
                .rotationEffect(.degrees(-12 * (1 - p)))
                .opacity(min(1, p * 1.4))
        }
    }

    // MARK: - Previous / Next (just moves through the trending posts; no upvote)
    private var swipeHint: some View {
        HStack {
            deckNavButton("Previous", isEnabled: currentIndex > 0 && !isAnimatingSwipe) {
                goToPrevious()
            }
            Spacer()
            deckNavButton("Next", isEnabled: !isAnimatingSwipe) {
                triggerSwipe(direction: .left)
            }
        }
        .padding(.horizontal, 24)
    }

    private func deckNavButton(_ title: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AlineTheme.inkPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .alineGlassCapsule()
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }

    /// Brings the previous post back in from the left
    private func goToPrevious() {
        guard currentIndex > 0, !isAnimatingSwipe else { return }
        isAnimatingSwipe = true
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            currentIndex -= 1
            cardOffset = CGSize(width: -520, height: 0)
            dragAngle = reduceMotion ? 0 : -8
        }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
            cardOffset = .zero
            dragAngle = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { isAnimatingSwipe = false }
    }

    // MARK: - Swipe Logic
    private func triggerSwipe(direction: TrendingSwipeDirection) {
        guard currentIndex < deckPosts.count, !isAnimatingSwipe else { return }
        let currentPost = livePost(for: deckPosts[currentIndex])
        isAnimatingSwipe = true
        isUpvoteArmed = false

        if direction == .right {
            if !currentPost.isLiked {
                viewModel.toggleLike(for: currentPost.id)
            }
            upvoteCommitCount += 1

            // Make sure the thumb is fully shown, pop it, then send the card off
            withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) {
                cardOffset = CGSize(width: max(cardOffset.width, commitDistance), height: cardOffset.height)
                isThumbPopping = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.easeIn(duration: 0.26)) {
                    cardOffset = CGSize(width: 520, height: -40)
                    dragAngle = reduceMotion ? 0 : 12
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { advanceDeck() }
        } else {
            // Skip: no haptic, the card just slides away
            withAnimation(.easeIn(duration: 0.26)) {
                cardOffset = CGSize(width: -520, height: cardOffset.height)
                dragAngle = reduceMotion ? 0 : -8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) { advanceDeck() }
        }
    }

    private func advanceDeck() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            currentIndex += 1
            cardOffset = .zero
            dragAngle = 0
            isThumbPopping = false
        }
        isAnimatingSwipe = false
    }
}

// MARK: - Trending Swipe Card Component
public struct TrendingSwipeCard: View {
    public let post: DiscussionPost
    /// While a right swipe is past the commit point, show the like as if it already counted
    public var previewUpvote: Bool = false
    /// Liquid glass stretches while a view is dragged and rotated, so the card swaps to frosted glass while it moves
    public var isMoving: Bool = false
    public var onOpenDiscussion: (() -> Void)? = nil
    public var onToggleLike: (() -> Void)? = nil
    public var onOpenComments: (() -> Void)? = nil

    private var showsLiked: Bool { post.isLiked || previewUpvote }
    private var shownLikes: Int { post.likesCount + (previewUpvote && !post.isLiked ? 1 : 0) }

    public init(
        post: DiscussionPost,
        previewUpvote: Bool = false,
        isMoving: Bool = false,
        onOpenDiscussion: (() -> Void)? = nil,
        onToggleLike: (() -> Void)? = nil,
        onOpenComments: (() -> Void)? = nil
    ) {
        self.post = post
        self.previewUpvote = previewUpvote
        self.isMoving = isMoving
        self.onOpenDiscussion = onOpenDiscussion
        self.onToggleLike = onToggleLike
        self.onOpenComments = onOpenComments
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author & Category Header
            HStack(spacing: 10) {
                Image(post.resolvedAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorDisplayWithCompany)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(1)

                    Text(post.timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(AlineTheme.inkMuted)
                }

                Spacer()

                Text(post.type.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AlineTheme.pillDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Capsule())
                    .lineLimit(1)
            }

            Divider()
                .background(Color.black.opacity(0.06))

            // Post Title
            Text(post.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // Post Content Area (Scrollable if long)
            ScrollView(.vertical, showsIndicators: false) {
                Text(post.fullContent.isEmpty ? post.excerpt : post.fullContent)
                    .font(.system(size: 13.5))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 220)

            Spacer(minLength: 0)

            // Topic tags sit right above the actions
            if !post.topics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(post.topics, id: \.self) { topic in
                            Text("#\(topic)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.05))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Divider()
                .background(Color.black.opacity(0.06))

            // Footer Action Row
            HStack(spacing: 10) {
                // Like: filled black thumb once liked
                Button {
                    onToggleLike?()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: showsLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .contentTransition(.symbolEffect(.replace))
                        Text("\(shownLikes)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white))
                    .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(onToggleLike == nil)
                .animation(AlineTheme.fastSpring, value: shownLikes)
                .accessibilityLabel(post.isLiked ? "Unlike, \(post.likesCount) likes" : "Like, \(post.likesCount) likes")

                // Comments: opens the discussion at its comments
                Button {
                    onOpenComments?()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("\(post.totalCommentsCount)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white))
                    .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(onOpenComments == nil)
                .accessibilityLabel("\(post.totalCommentsCount) comments")

                Spacer()

                if let onOpen = onOpenDiscussion {
                    Button {
                        onOpen()
                    } label: {
                        HStack(spacing: 4) {
                            Text("View Discussion")
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AlineTheme.pillDark))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: 360)
        .frame(height: 500)
        // Liquid glass card. Only the card itself is glass: the buttons inside stay flat, so no glass shapes morph into each other while it moves.
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.ultraThinMaterial))
                .opacity(isMoving ? 1 : 0)
        )
        .glassEffect(isMoving ? .identity : .regular.tint(Color.white.opacity(0.35)), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .animation(.easeOut(duration: 0.18), value: isMoving)
        // Tapping anywhere on the card opens the discussion (buttons keep their own taps)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture { onOpenDiscussion?() }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 12)
    }
}

// MARK: - Trending Swipe Completion Card
public struct TrendingSwipeCompletionCard: View {
    public let onRestart: () -> Void
    public let onSeeDiscussions: () -> Void

    public init(
        onRestart: @escaping () -> Void,
        onSeeDiscussions: @escaping () -> Void
    ) {
        self.onRestart = onRestart
        self.onSeeDiscussions = onSeeDiscussions
    }

    public var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 54, weight: .bold))
                .foregroundColor(Color(red: 0.16, green: 0.82, blue: 0.45))
                .padding(.bottom, 4)

            Text("You're All Caught Up!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)

            Text("You've reviewed all trending discussions. You can review the topics again or jump into the community discussions feed.")
                .font(.system(size: 13.5))
                .foregroundColor(AlineTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2.5)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                Button {
                    onRestart()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .bold))
                        Text("Review Topics Again")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(AlineTheme.inkPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                }
                .buttonStyle(.plain)

                Button {
                    onSeeDiscussions()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Back to All Discussions")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(AlineTheme.inkPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
        }
        .padding(24)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
    }
}

// MARK: - All Trending Discussions Screen (Full Page - Requirement 9)
public struct AllTrendingDiscussionsView: View {
    @ObservedObject public var viewModel: CommunityViewModel
    public let onSelectPost: (DiscussionPost) -> Void
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                DiscoverBackgroundArtwork()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Navigation Bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .frame(width: 42, height: 42)
                                .alineGlassCircle(selected: false)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Trending Discussions")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("\(viewModel.trendingPosts.count) Popular Topics")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        .padding(.leading, 8)

                        Spacer()

                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                if let top = viewModel.trendingPosts.first { onSelectPost(top) }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.orange)
                                Text("Swipe Mode")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(AlineTheme.inkPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .alineGlassCapsule(selected: false)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                    // Search Bar
                    AlineSearchField("Search topics, companies", text: $viewModel.searchQuery)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                    // Full-page Vertical List of Trending Discussions
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(viewModel.trendingPosts) { post in
                                CommunityDiscussionCard(
                                    post: post,
                                    onTap: {
                                        dismiss()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                            onSelectPost(post)
                                        }
                                    },
                                    onToggleLike: {
                                        withAnimation(AlineTheme.fastSpring) {
                                            viewModel.toggleLike(for: post.id)
                                        }
                                    },
                                    onToggleSave: {
                                        withAnimation(AlineTheme.fastSpring) {
                                            viewModel.toggleSave(for: post.id)
                                        }
                                    },
                                    onShare: {
                                        viewModel.incrementShare(for: post.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .padding(.bottom, 36)
                    }
.scrollDismissesKeyboard(.interactively)
                }
            }
            .environment(\.colorScheme, .light)
        }
    }
}

// MARK: - Saved Screens (pushed pages with a search toggle)
/// Shared chrome for the saved posts / questions pages: back button, search toggle, hero title and an optional search bar.
struct SavedPageScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    let searchPlaceholder: String
    @Binding var searchText: String
    @ViewBuilder let content: () -> Content
    @Environment(\.dismiss) private var dismiss
    @State private var isSearching = false
    @State private var isFieldActive = false

    var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AlineSpacing.section) {
                    HStack {
                        circleButton(icon: "chevron.left", label: "Back") { dismiss() }
                        Spacer()
                        circleButton(icon: "magnifyingglass", label: isSearching ? "Close search" : "Search") {
                            withAnimation(AlineTheme.fastSpring) {
                                isSearching.toggle()
                                if !isSearching { searchText = "" }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.alineHero)
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text(subtitle)
                            .font(.alineCallout)
                            .foregroundColor(AlineTheme.inkSecondary)
                    }

                    if isSearching {
                        AlineSearchField(searchPlaceholder, text: $searchText, isActive: $isFieldActive, focusOnAppear: true)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    content()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.colorScheme, .light)
        // The field's own ✕ clears and unfocuses it; with nothing typed, that also closes the search bar
        .onChange(of: isFieldActive) { _, active in
            if !active && searchText.isEmpty {
                withAnimation(AlineTheme.fastSpring) { isSearching = false }
            }
        }
    }

    private func circleButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .alineGlassCircleButton()
        .accessibilityLabel(label)
    }
}

struct SavedEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 44))
                .foregroundColor(AlineTheme.inkMuted)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(AlineTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Saved Posts
public struct SavedPostsView: View {
    @ObservedObject public var viewModel: CommunityViewModel
    @State private var searchText = ""
    @State private var selectedPost: DiscussionPost?

    public init(viewModel: CommunityViewModel) {
        self.viewModel = viewModel
    }

    private var results: [DiscussionPost] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return viewModel.savedPosts }
        return viewModel.savedPosts.filter { post in
            [post.title, post.excerpt, post.fullContent, post.authorName, post.companyName ?? "", post.role ?? "", post.type.rawValue]
                .contains { $0.localizedCaseInsensitiveContains(query) }
                || post.topics.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    public var body: some View {
        let count = viewModel.savedPosts.count
        SavedPageScaffold(
            title: "Saved Posts",
            subtitle: count == 1 ? "1 bookmarked post" : "\(count) bookmarked posts",
            searchPlaceholder: "Search saved posts",
            searchText: $searchText
        ) {
            if viewModel.savedPosts.isEmpty {
                SavedEmptyState(
                    title: "No saved posts yet",
                    message: "Bookmark any discussion post by tapping the bookmark icon to review it anytime."
                )
            } else if results.isEmpty {
                Text("No saved posts match “\(searchText)”.")
                    .font(.alineCallout)
                    .foregroundColor(AlineTheme.inkSecondary)
            } else {
                VStack(spacing: AlineSpacing.card) {
                    ForEach(results) { post in
                        CommunityDiscussionCard(
                            post: post,
                            onTap: { selectedPost = post },
                            onToggleLike: {
                                withAnimation(AlineTheme.fastSpring) { viewModel.toggleLike(for: post.id) }
                            },
                            onToggleSave: {
                                withAnimation(AlineTheme.fastSpring) { viewModel.toggleSave(for: post.id) }
                            },
                            onTapComment: { selectedPost = post },
                            onShare: { viewModel.incrementShare(for: post.id) }
                        )
                    }
                }
            }
        }
        .navigationDestination(item: $selectedPost) { post in
            DiscussionDetailView(post: post, viewModel: viewModel)
        }
    }
}

// MARK: - Saved Interview Questions
public struct SavedInterviewQuestionsView: View {
    @ObservedObject public var viewModel: InterviewPrepViewModel
    @State private var searchText = ""
    @State private var selectedQuestion: InterviewQuestion?

    public init(viewModel: InterviewPrepViewModel) {
        self.viewModel = viewModel
    }

    private var results: [InterviewQuestion] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return viewModel.savedQuestions }
        return viewModel.savedQuestions.filter { q in
            [q.questionText, q.topic.rawValue, q.companyName ?? "", q.role ?? "", q.difficulty]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    public var body: some View {
        let count = viewModel.savedQuestions.count
        SavedPageScaffold(
            title: "Saved Questions",
            subtitle: count == 1 ? "1 bookmarked question" : "\(count) bookmarked questions",
            searchPlaceholder: "Search saved questions",
            searchText: $searchText
        ) {
            if viewModel.savedQuestions.isEmpty {
                SavedEmptyState(
                    title: "No saved questions yet",
                    message: "Bookmark any interview practice question by tapping Save to review and practice it anytime."
                )
            } else if results.isEmpty {
                Text("No saved questions match “\(searchText)”.")
                    .font(.alineCallout)
                    .foregroundColor(AlineTheme.inkSecondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(results) { question in
                        InterviewQuestionItemCard(q: question) { selectedQuestion = question }
                    }
                }
            }
        }
        .navigationDestination(item: $selectedQuestion) { question in
            InterviewQuestionDetailView(
                questions: results.isEmpty ? [question] : results,
                initialQuestion: question,
                viewModel: viewModel
            )
        }
    }
}

public struct DiscussionDetailView: View {
    public let post: DiscussionPost
    @ObservedObject public var viewModel: CommunityViewModel
    public let initialFocusComments: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var newCommentText: String = ""
    @State private var replyingToComment: DiscussionComment? = nil
    @State private var selectedCompanyCommunity: CompanyCommunity? = nil
    @State private var showReportAlert: Bool = false
    @FocusState private var isCommentFocused: Bool

    public init(
        post: DiscussionPost,
        viewModel: CommunityViewModel,
        initialFocusComments: Bool = false
    ) {
        self.post = post
        self.viewModel = viewModel
        self.initialFocusComments = initialFocusComments
    }

    // Requirement 8: Live post binding so new comments reflect and stay immediately!
    private var livePost: DiscussionPost {
        viewModel.posts.first(where: { $0.id == post.id }) ?? post
    }

    private var isFollowingCompany: Bool {
        viewModel.isFollowing(companyName: livePost.companyName)
    }

    public var body: some View {
        detailContent
            // The feed carries only counts; the full thread loads when the discussion opens
            .task(id: post.id) { await viewModel.loadComments(for: post.id) }
    }

    @ViewBuilder
    private var detailContent: some View {
        ZStack(alignment: .bottom) {
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar matching Company Community (Image 1) exactly:
                // Circular 36x36 glass buttons on sides, pure Spacer() in middle (NO "Discussion" text),
                // comfortable top safe padding of 14pt, 20pt horizontal padding.
                HStack(alignment: .center) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .frame(width: 36, height: 36)
                            .alineGlassCircle()
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    ShareLink(item: "\(livePost.title)\n\n\(livePost.fullContent)") {
                        Image(systemName: "arrowshape.turn.up.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .frame(width: 36, height: 36)
                            .alineGlassCircle()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 8)

                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            if let company = livePost.companyName, !company.isEmpty, livePost.type != .generalDiscussion {
                                companyCommunityBanner(for: company)
                            }

                            authorHeaderRow(livePost: livePost)

                            // Post Category Tag
                            Text(livePost.type.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AlineTheme.pillDark)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AlineTheme.cardMint.opacity(0.4))
                                .clipShape(Capsule())

                            // Post Title
                            Text(livePost.title)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .lineSpacing(3)

                            // Full Content
                            Text(livePost.fullContent)
                                .font(.system(size: 14.5))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .lineSpacing(4.5)

                            likesAndStatsRow(livePost: livePost)

                            Divider().padding(.vertical, 4)

                            commentsSection(livePost: livePost)

                            Spacer(minLength: 90)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear {
                        if initialFocusComments {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                withAnimation {
                                    scrollProxy.scrollTo("comments-section", anchor: .top)
                                }
                                isCommentFocused = true
                            }
                        }
                    }
                }
            }

            composerBar(livePost: livePost)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $selectedCompanyCommunity) { comp in
            CompanyCommunityDetailView(
                company: comp,
                viewModel: viewModel,
                onSelectPost: { _ in }
            )
        }
        .alert("Report Submitted", isPresented: $showReportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thank you for helping keep the Aline community safe. Our moderators will review this comment shortly.")
        }
        .environment(\.colorScheme, .light)
    }

    private func companyMemberCount(for company: String) -> String {
        if let match = viewModel.companies.first(where: { $0.name.lowercased() == company.lowercased() }) {
            return match.memberCount
        }
        return "12.4K members"
    }

    private func openCompanyCommunity(company: String, count: String) {
        if let target = viewModel.companies.first(where: { $0.name.lowercased() == company.lowercased() }) {
            selectedCompanyCommunity = target
        } else {
            selectedCompanyCommunity = CompanyCommunity(
                id: company.lowercased(),
                name: company,
                symbol: String(company.prefix(1)).uppercased(),
                memberCount: count,
                description: "Discussions, interview tips, and questions for \(company).",
                isFollowing: isFollowingCompany
            )
        }
    }

    @ViewBuilder
    private func companyCommunityBanner(for company: String) -> some View {
        let count = companyMemberCount(for: company)
        HStack(alignment: .center, spacing: 10) {
            Button {
                openCompanyCommunity(company: company, count: count)
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    CompanyLogoBadge(companyName: company, size: 40, isSquircle: true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(company) Community")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        Text(count)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AlineTheme.inkSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 6)

            Button {
                withAnimation(AlineTheme.fastSpring) {
                    viewModel.toggleFollowCompany(name: company)
                }
            } label: {
                HStack(spacing: 4) {
                    if isFollowingCompany {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                        Text("Following")
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("Follow")
                    }
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isFollowingCompany ? AlineTheme.inkPrimary : .white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .alineGlassCapsule(selected: !(isFollowingCompany))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .alineGlassCapsule(selected: false)
    }

    @ViewBuilder
    private func authorHeaderRow(livePost: DiscussionPost) -> some View {
        HStack(spacing: 12) {
            Image(livePost.resolvedAvatar)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(livePost.authorDisplayWithCompany)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .lineLimit(1)
                Text(livePost.timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(AlineTheme.inkSecondary)
            }

            Spacer()

            Button {
                withAnimation(AlineTheme.fastSpring) {
                    viewModel.toggleSave(for: livePost.id)
                }
            } label: {
                Image(systemName: livePost.isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(livePost.isSaved ? AlineTheme.pillDark : AlineTheme.inkPrimary)
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func likesAndStatsRow(livePost: DiscussionPost) -> some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(AlineTheme.fastSpring) {
                    viewModel.toggleLike(for: livePost.id)
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: livePost.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .foregroundColor(livePost.isLiked ? AlineTheme.pillDark : AlineTheme.inkPrimary)
                    Text("\(livePost.likesCount) Likes")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .alineGlassCapsule(selected: false)
            }
            .buttonStyle(.plain)

            Button {
                isCommentFocused = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(AlineTheme.inkPrimary)
                    Text("\(livePost.totalCommentsCount) Comments")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .alineGlassCapsule(selected: false)
            }
            .buttonStyle(.plain)

            ShareLink(item: "\(livePost.title)\n\n\(livePost.fullContent)") {
                HStack(spacing: 5) {
                    Image(systemName: "arrowshape.turn.up.right")
                        .foregroundColor(AlineTheme.inkPrimary)
                    Text(livePost.sharesCount > 0 ? "\(livePost.sharesCount) Shares" : "Share")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .alineGlassCapsule(selected: false)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                viewModel.incrementShare(for: livePost.id)
            })

            Spacer()
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func commentsSection(livePost: DiscussionPost) -> some View {
        HStack {
            Text("\(livePost.totalCommentsCount) comments")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 11, weight: .semibold))
                Text("Newest to oldest")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(Color(red: 0.15, green: 0.48, blue: 0.65))
        }
        .id("comments-section")

        if livePost.comments.isEmpty {
            Text("No comments yet. Be the first to share your thoughts!")
                .font(.system(size: 13))
                .foregroundColor(AlineTheme.inkSecondary)
                .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(livePost.comments.enumerated()), id: \.element.id) { index, comment in
                    commentItemRow(comment: comment, isPostAuthor: comment.authorName == livePost.authorName)

                    if index < livePost.comments.count - 1 {
                        Divider()
                            .padding(.vertical, 12)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func commentItemRow(comment: DiscussionComment, isPostAuthor: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Image(comment.resolvedAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(comment.authorName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)

                        if isPostAuthor {
                            Text("• Author")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                        }
                    }

                    Text(comment.timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(AlineTheme.inkSecondary)
                }

                Spacer()

                Menu {
                    if comment.authorName == "You" {
                        Button(role: .destructive) {
                            withAnimation(AlineTheme.fastSpring) {
                                viewModel.deleteComment(postId: livePost.id, commentId: comment.id)
                            }
                        } label: {
                            Label("Delete Comment", systemImage: "trash")
                        }
                    } else {
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                replyingToComment = comment
                                isCommentFocused = true
                            }
                        } label: {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                        }

                        Button(role: .destructive) {
                            showReportAlert = true
                        } label: {
                            Label("Report Comment", systemImage: "exclamationmark.bubble")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }

            Text(comment.text)
                .font(.system(size: 14))
                .foregroundColor(AlineTheme.inkPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)

            // Action row under comment text: thumbs up + count and Reply
            HStack(spacing: 14) {
                Button {
                    withAnimation(AlineTheme.fastSpring) {
                        viewModel.toggleLikeComment(postId: livePost.id, commentId: comment.id)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: comment.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(comment.isLiked ? AlineTheme.pillDark : AlineTheme.inkPrimary)
                        if comment.likesCount > 0 {
                            Text("\(comment.likesCount)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AlineTheme.inkPrimary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(AlineTheme.fastSpring) {
                        replyingToComment = comment
                        isCommentFocused = true
                    }
                } label: {
                    Text("Reply")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.15, green: 0.48, blue: 0.65))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.top, 4)

            // Nested Replies (Threaded beneath)
            if !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(comment.replies) { reply in
                        HStack(alignment: .top, spacing: 8) {
                            Image(reply.resolvedAvatar)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(reply.authorName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)

                                    if reply.authorName == livePost.authorName {
                                        Text("• Author")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(AlineTheme.inkPrimary)
                                    }

                                    Spacer()

                                    Text(reply.timeAgo)
                                        .font(.system(size: 11))
                                        .foregroundColor(AlineTheme.inkSecondary)

                                    Menu {
                                        if reply.authorName == "You" {
                                            Button(role: .destructive) {
                                                withAnimation(AlineTheme.fastSpring) {
                                                    viewModel.deleteComment(postId: livePost.id, commentId: reply.id)
                                                }
                                            } label: {
                                                Label("Delete Reply", systemImage: "trash")
                                            }
                                        } else {
                                            Button {
                                                withAnimation(AlineTheme.fastSpring) {
                                                    replyingToComment = comment
                                                    isCommentFocused = true
                                                }
                                            } label: {
                                                Label("Reply", systemImage: "arrowshape.turn.up.left")
                                            }

                                            Button(role: .destructive) {
                                                showReportAlert = true
                                            } label: {
                                                Label("Report Reply", systemImage: "exclamationmark.bubble")
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(AlineTheme.inkSecondary)
                                            .padding(3)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text(reply.text)
                                    .font(.system(size: 13))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .lineSpacing(2)
                                    .padding(.top, 1)

                                HStack(spacing: 12) {
                                    Button {
                                        withAnimation(AlineTheme.fastSpring) {
                                            viewModel.toggleLikeComment(postId: livePost.id, commentId: reply.id)
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: reply.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(reply.isLiked ? AlineTheme.pillDark : AlineTheme.inkPrimary)
                                            if reply.likesCount > 0 {
                                                Text("\(reply.likesCount)")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(AlineTheme.inkPrimary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        withAnimation(AlineTheme.fastSpring) {
                                            replyingToComment = comment
                                            isCommentFocused = true
                                        }
                                    } label: {
                                        Text("Reply")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 0.15, green: 0.48, blue: 0.65))
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()
                                }
                                .padding(.top, 3)
                            }
                        }
                        .padding(.leading, 12)
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func composerBar(livePost: DiscussionPost) -> some View {
        VStack(spacing: 6) {
            if let replying = replyingToComment {
                HStack {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.system(size: 11))
                        .foregroundColor(AlineTheme.inkSecondary)
                    Text("Replying to")
                        .font(.system(size: 12))
                        .foregroundColor(AlineTheme.inkSecondary)
                    Text("@\(replying.authorName)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.pillDark)
                    Spacer()
                    Button {
                        withAnimation(AlineTheme.fastSpring) {
                            replyingToComment = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(AlineTheme.inkMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.04))
                .clipShape(Capsule())
                .padding(.horizontal, 24)
            }

            HStack(spacing: 10) {
                TextField(
                    "",
                    text: $newCommentText,
                    prompt: Text(replyingToComment != nil ? "Write a reply to @\(replyingToComment!.authorName)..." : "Add a question or comment...")
                        .foregroundColor(AlineTheme.inkSecondary)
                )
                .font(.system(size: 14))
                .foregroundColor(AlineTheme.inkPrimary)
                .tint(AlineTheme.inkPrimary)
                .focused($isCommentFocused)
                .alineKeyboardDismissal(.send)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .alineGlassCapsule(selected: false, interactive: false)

                Button {
                    guard !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    withAnimation(AlineTheme.fastSpring) {
                        if let replying = replyingToComment {
                            viewModel.addReply(to: livePost.id, commentId: replying.id, text: newCommentText)
                            replyingToComment = nil
                        } else {
                            viewModel.addComment(to: livePost.id, text: newCommentText)
                        }
                        newCommentText = ""
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .alineGlassCircle(selected: true)
                }
                .buttonStyle(.plain)
                .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Redesigned Create Discussion Post View (Requirement 11)
public struct CreateDiscussionPostView: View {
    @ObservedObject public var viewModel: CommunityViewModel
    public var prefilledCompany: String? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var type: DiscussionType = .generalDiscussion
    @State private var company: String = ""
    @State private var companySearchQuery: String = ""
    @State private var isCompanyDropdownOpen: Bool = false

    public init(viewModel: CommunityViewModel, prefilledCompany: String? = nil) {
        self.viewModel = viewModel
        self.prefilledCompany = prefilledCompany
        if let prefilled = prefilledCompany, !prefilled.isEmpty {
            _company = State(initialValue: prefilled)
            _companySearchQuery = State(initialValue: prefilled)
            _type = State(initialValue: .interviewExperience)
        }
    }

    private var titlePlaceholder: String {
        switch type {
        case .interviewExperience:
            return "E.g. My Google SDE intern interview experience"
        case .workExperience:
            return "E.g. What daily life looks like as an iOS Intern at Apple"
        case .recruitmentExperience:
            return "E.g. Microsoft 2026 University Hiring: OA, Timeline & Referral"
        case .generalDiscussion:
            return "E.g. Tips for staying motivated during internship prep"
        }
    }

    private var contentPlaceholder: String {
        switch type {
        case .interviewExperience:
            return "Share details about the interview process, rounds, questions asked, DSA topics, and key takeaways..."
        case .workExperience:
            return "Describe your daily work, engineering culture, tech stack, team collaboration, and learnings..."
        case .recruitmentExperience:
            return "Share your application timeline, OA structure, referral process, recruiter response time, and interview stages..."
        case .generalDiscussion:
            return "Start an open conversation, ask a career question, or share an insight with the community..."
        }
    }

    private var contentSectionTitle: String {
        switch type {
        case .interviewExperience:
            return "INTERVIEW EXPERIENCE & QUESTIONS"
        case .workExperience:
            return "WORK EXPERIENCE & INSIGHTS"
        case .recruitmentExperience:
            return "RECRUITMENT PROCESS & TIMELINE"
        case .generalDiscussion:
            return "EXPERIENCE & INSIGHTS"
        }
    }

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Action Bar (iOS 27 glass close button + centered title + Publish button, avoiding overlap)
                HStack(alignment: .center) {
                    AlineCloseButton { dismiss() }

                    Spacer()

                    Text("New Discussion")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    Spacer()

                    Button {
                        let postCompany = (type == .generalDiscussion) ? nil : (company.isEmpty ? nil : company)
                        viewModel.createPost(
                            type: type,
                            company: postCompany,
                            title: title.isEmpty ? "Community Experience" : title,
                            content: content.isEmpty ? "No extended notes provided." : content,
                            topics: postCompany != nil ? [postCompany!, type.rawValue] : [type.rawValue]
                        )
                        dismiss()
                    } label: {
                        Text("Publish")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .alineGlassCapsule(selected: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Category Dropdown Picker (Requirement 5: Dropdown picker, General default + 3 more options)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)

                            Menu {
                                Button {
                                    withAnimation(AlineTheme.fastSpring) { type = .generalDiscussion }
                                } label: {
                                    HStack {
                                        Text(DiscussionType.generalDiscussion.rawValue)
                                        if type == .generalDiscussion { Image(systemName: "checkmark") }
                                    }
                                }

                                Button {
                                    withAnimation(AlineTheme.fastSpring) { type = .interviewExperience }
                                } label: {
                                    HStack {
                                        Text(DiscussionType.interviewExperience.rawValue)
                                        if type == .interviewExperience { Image(systemName: "checkmark") }
                                    }
                                }

                                Button {
                                    withAnimation(AlineTheme.fastSpring) { type = .workExperience }
                                } label: {
                                    HStack {
                                        Text(DiscussionType.workExperience.rawValue)
                                        if type == .workExperience { Image(systemName: "checkmark") }
                                    }
                                }

                                Button {
                                    withAnimation(AlineTheme.fastSpring) { type = .recruitmentExperience }
                                } label: {
                                    HStack {
                                        Text(DiscussionType.recruitmentExperience.rawValue)
                                        if type == .recruitmentExperience { Image(systemName: "checkmark") }
                                    }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: type.iconName)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AlineTheme.inkSecondary)

                                    Text(type.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AlineTheme.inkPrimary)

                                    Spacer()

                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                        }

                        // Company Tag Input:
                        // If prefilled from inside a company community, lock it so the user cannot change it (User Request 5)
                        if let lockedCompany = prefilledCompany, !lockedCompany.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TARGET COMPANY")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.inkSecondary)

                                HStack(spacing: 10) {
                                    CompanyLogoBadge(companyName: lockedCompany, size: 28, isSquircle: true)

                                    Text(lockedCompany)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)

                                    Spacer()

                                    HStack(spacing: 4) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 10))
                                        Text("Locked")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(AlineTheme.inkSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.04))
                                    .clipShape(Capsule())
                                }
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                            }
                        } else if type != .generalDiscussion {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TARGET COMPANY")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.inkSecondary)

                                VStack(alignment: .leading, spacing: 0) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(AlineTheme.inkSecondary)

                                        TextField("Search and select company (e.g. Google, Apple)...", text: $companySearchQuery)
                                            .alineKeyboardDismissal(.done)
                                            .font(.system(size: 14))
                                            .foregroundColor(AlineTheme.inkPrimary)
                                            .onChange(of: companySearchQuery) { _, newValue in
                                                company = newValue
                                                isCompanyDropdownOpen = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
                                            }

                                        if !companySearchQuery.isEmpty {
                                            Button {
                                                companySearchQuery = ""
                                                company = ""
                                                isCompanyDropdownOpen = false
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AlineTheme.inkSecondary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(14)

                                    let filteredCompanies = viewModel.companies.filter { comp in
                                        companySearchQuery.isEmpty || comp.name.localizedCaseInsensitiveContains(companySearchQuery)
                                    }

                                    if isCompanyDropdownOpen && !filteredCompanies.isEmpty {
                                        Divider()
                                        VStack(alignment: .leading, spacing: 0) {
                                            ForEach(filteredCompanies.prefix(5)) { comp in
                                                Button {
                                                    company = comp.name
                                                    companySearchQuery = comp.name
                                                    isCompanyDropdownOpen = false
                                                } label: {
                                                    HStack(spacing: 10) {
                                                        CompanyLogoBadge(companyName: comp.name, size: 26, isSquircle: true)
                                                        Text(comp.name)
                                                            .font(.system(size: 14, weight: .medium))
                                                            .foregroundColor(AlineTheme.inkPrimary)
                                                        Spacer()
                                                        Text(comp.memberCount)
                                                            .font(.system(size: 11))
                                                            .foregroundColor(AlineTheme.inkSecondary)
                                                    }
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 10)
                                                }
                                                .buttonStyle(.plain)

                                                if comp.id != filteredCompanies.prefix(5).last?.id {
                                                    Divider().padding(.leading, 50)
                                                }
                                            }
                                        }
                                        .background(Color(red: 0.98, green: 0.98, blue: 0.99))
                                    }
                                }
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                            }
                        }

                        // Title Field with dynamic placeholder based on category (User Request 7)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TITLE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)

                            TextField(titlePlaceholder, text: $title)
                                .alineKeyboardDismissal(.done)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                        }

                        // Content Field with dynamic placeholder based on category (User Request 7)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(contentSectionTitle)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)

                            TextField(contentPlaceholder, text: $content, axis: .vertical)
                                .font(.system(size: 14))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .lineLimit(6...10)
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(20)
                }
.scrollDismissesKeyboard(.interactively)
            }
        }
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Filter Tag Pill
public struct FilterTagPill: View {
    public let text: String
    public let onRemove: () -> Void

    public var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AlineTheme.pillDark)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AlineTheme.pillDark)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AlineTheme.cardMint.opacity(0.55))
        .clipShape(Capsule())
    }
}

// MARK: - 3-Step Guided Interview Wizard Flow View
public struct InterviewWizardFlowView: View {
    @ObservedObject public var viewModel: InterviewPrepViewModel
    public let onSelectQuestion: (InterviewQuestion, [InterviewQuestion]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var stepSearchText: String = ""
    @State private var selectedWizardQuestion: InterviewQuestion? = nil

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topNavBar

                switch viewModel.wizardStep {
                case 1:
                    stepOneView
                case 2:
                    stepTwoView
                default:
                    stepThreeResultsView
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .environment(\.colorScheme, .light)
        .navigationDestination(item: $selectedWizardQuestion) { question in
            InterviewQuestionDetailView(
                questions: viewModel.wizardFilteredQuestions,
                initialQuestion: question,
                viewModel: viewModel,
                onHomeTapped: {
                    selectedWizardQuestion = nil
                    viewModel.resetWizard()
                    dismiss()
                }
            )
        }
    }

    // Top Navigation Bar
    private var topNavBar: some View {
        HStack(alignment: .center) {
            Button {
                withAnimation(AlineTheme.fastSpring) {
                    if viewModel.wizardStep > 1 {
                        viewModel.wizardStep -= 1
                        stepSearchText = ""
                    } else {
                        viewModel.resetWizard()
                        dismiss()
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .frame(width: 36, height: 36)
                    .alineGlassCircle()
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(stepHeaderTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)

                Text(stepSubTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AlineTheme.inkSecondary)
            }

            Spacer()

            // Home appears from the second step on; the first filter screen is one tap from home already (Back)
            if viewModel.wizardStep > 1 {
                Button {
                    withAnimation(AlineTheme.fastSpring) {
                        viewModel.resetWizard()
                        dismiss()
                    }
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .frame(width: 36, height: 36)
                        .alineGlassCircle()
                }
                .buttonStyle(.plain)
            } else {
                // Keeps the title centred
                Color.clear.frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    private var stepHeaderTitle: String {
        switch viewModel.wizardStep {
        case 1:
            switch viewModel.wizardEntry {
            case .company: return "Select Role"
            case .role: return "Select Company"
            case .topic: return "Select Role"
            }
        case 2:
            switch viewModel.wizardEntry {
            case .company: return "Select Topic"
            case .role: return "Select Topic"
            case .topic: return "Select Company"
            }
        default:
            return "Interview Questions"
        }
    }

    private var stepSubTitle: String {
        switch viewModel.wizardStep {
        case 1:
            return "Step 1 of 2"
        case 2:
            return "Step 2 of 2 • Final Step"
        default:
            return "\(viewModel.wizardFilteredQuestions.count) Questions Available"
        }
    }

    // MARK: - Step 1 View
    private var isStepOneComplete: Bool {
        switch viewModel.wizardEntry {
        case .company:
            return viewModel.wizardSelectedRole != nil
        case .role:
            return viewModel.wizardSelectedCompany != nil
        case .topic:
            return viewModel.wizardSelectedRole != nil
        }
    }

    private var stepOnePromptTitle: String {
        switch viewModel.wizardEntry {
        case .company:
            return "Select Role"
        case .role:
            return "Select Company"
        case .topic:
            return "Select Role"
        }
    }

    @ViewBuilder
    private var stepOneView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Selected First Facet Banner
            stepOneInitialBadge
                .padding(.horizontal, 24)

            // Step 1 Prompt Header with Skip option (Item 1: Only 1 skip option, located here)
            HStack {
                Text(stepOnePromptTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                Spacer()
                Button("Skip") {
                    withAnimation(AlineTheme.fastSpring) {
                        // Clear the facet being skipped so it is NOT reflected on the next screen (Item 3)
                        switch viewModel.wizardEntry {
                        case .company, .topic:
                            viewModel.wizardSelectedRole = nil
                        case .role:
                            viewModel.wizardSelectedCompany = nil
                        }
                        stepSearchText = ""
                        viewModel.wizardStep = 2
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AlineTheme.pillDark)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)

            // Search Bar for Second Facet
            AlineSearchField(stepOneSearchPlaceholder, text: $stepSearchText)
                .padding(.horizontal, 24)

            // Options Selection
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    switch viewModel.wizardEntry {
                    case .company, .topic:
                        rolesSelectionList
                    case .role:
                        companiesSelectionGrid
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            // Bottom Continue Button (Item 1: Full-width Continue, no Skip here, no arrow)
            Button {
                withAnimation(AlineTheme.fastSpring) {
                    viewModel.wizardStep = 2
                    stepSearchText = ""
                }
            } label: {
                Text("Continue")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isStepOneComplete ? AlineTheme.pillDark : Color.gray.opacity(0.35))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(!isStepOneComplete)
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
    }

    @ViewBuilder
    private var stepOneInitialBadge: some View {
        switch viewModel.wizardEntry {
        case .company:
            if let comp = viewModel.wizardSelectedCompany {
                HStack(spacing: 12) {
                    CompanyLogoBadge(companyName: comp, size: 34, isSquircle: true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(comp)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("Target Company")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AlineTheme.pillDark)
                        .font(.system(size: 18))
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
            }
        case .role:
            if let role = viewModel.wizardSelectedRole {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(role)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("Target Role")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AlineTheme.pillDark)
                        .font(.system(size: 18))
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
            }
        case .topic:
            if let topic = viewModel.wizardSelectedTopics.first ?? viewModel.wizardSelectedTopic {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(topic.iconBgColor)
                            .frame(width: 34, height: 34)
                        Image(systemName: topic.iconName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(topic.iconColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(topic.rawValue)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("Target Topic")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AlineTheme.pillDark)
                        .font(.system(size: 18))
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
            }
        }
    }

    private var stepOneSearchPlaceholder: String {
        switch viewModel.wizardEntry {
        case .company, .topic: return "Search tech roles..."
        case .role: return "Search companies..."
        }
    }

    // MARK: - Step 2 View
    private var isStepTwoComplete: Bool {
        switch viewModel.wizardEntry {
        case .company, .role:
            return !viewModel.wizardSelectedTopics.isEmpty || viewModel.wizardSelectedTopic != nil
        case .topic:
            return viewModel.wizardSelectedCompany != nil
        }
    }

    @ViewBuilder
    private var stepTwoView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Upper card: Preserves the exact same card layout from Step 1, adding the second facet right next to the initial one
            stepTwoHeaderBadge
                .padding(.horizontal, 24)

            // Step 2 Prompt Header with Skip option (Item 2: Only 1 skip option, located here)
            HStack {
                Text(stepTwoPromptTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                Spacer()
                Button("Skip") {
                    withAnimation(AlineTheme.fastSpring) {
                        // Clear the facet being skipped so it is NOT reflected on the next screen (Item 3)
                        switch viewModel.wizardEntry {
                        case .company, .role:
                            viewModel.wizardSelectedTopics.removeAll()
                            viewModel.wizardSelectedTopic = nil
                        case .topic:
                            viewModel.wizardSelectedCompany = nil
                        }
                        stepSearchText = ""
                        viewModel.wizardStep = 3
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AlineTheme.pillDark)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)

            // Search Bar for Third Facet
            AlineSearchField(stepTwoSearchPlaceholder, text: $stepSearchText)
                .padding(.horizontal, 24)

            // Options Selection
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    switch viewModel.wizardEntry {
                    case .company, .role:
                        topicsSelectionGrid
                    case .topic:
                        companiesSelectionGrid
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            // Bottom View Questions Button (Item 2: Full-width View Questions, no Skip here, no arrow)
            Button {
                withAnimation(AlineTheme.fastSpring) {
                    viewModel.wizardStep = 3
                    stepSearchText = ""
                }
            } label: {
                Text("View Questions")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isStepTwoComplete ? AlineTheme.pillDark : Color.gray.opacity(0.35))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(!isStepTwoComplete)
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
    }

    @ViewBuilder
    private var stepTwoHeaderBadge: some View {
        switch viewModel.wizardEntry {
        case .company:
            if let comp = viewModel.wizardSelectedCompany {
                HStack(spacing: 12) {
                    CompanyLogoBadge(companyName: comp, size: 34, isSquircle: true)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(comp)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            if let role = viewModel.wizardSelectedRole {
                                Text("•")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.inkSecondary)
                                Text(role)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .lineLimit(1)
                            }
                        }
                        Text(viewModel.wizardSelectedRole != nil ? "Company & Role Selected" : "Target Company")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AlineTheme.pillDark)
                        .font(.system(size: 18))
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
            }
        case .role:
            if let role = viewModel.wizardSelectedRole {
                HStack(spacing: 12) {
                    if let comp = viewModel.wizardSelectedCompany {
                        CompanyLogoBadge(companyName: comp, size: 34, isSquircle: true)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(red: 0.95, green: 0.96, blue: 0.97))
                                .frame(width: 34, height: 34)
                            Image(systemName: "briefcase.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AlineTheme.pillDark)
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(role)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            if let comp = viewModel.wizardSelectedCompany {
                                Text("•")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.inkSecondary)
                                Text(comp)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .lineLimit(1)
                            }
                        }
                        Text(viewModel.wizardSelectedCompany != nil ? "Role & Company Selected" : "Target Role")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AlineTheme.pillDark)
                        .font(.system(size: 18))
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
            }
        case .topic:
            if let topic = viewModel.wizardSelectedTopics.first ?? viewModel.wizardSelectedTopic {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(topic.iconBgColor)
                            .frame(width: 34, height: 34)
                        Image(systemName: topic.iconName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(topic.iconColor)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(topic.rawValue)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            if let role = viewModel.wizardSelectedRole {
                                Text("•")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.inkSecondary)
                                Text(role)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .lineLimit(1)
                            }
                        }
                        Text(viewModel.wizardSelectedRole != nil ? "Topic & Role Selected" : "Target Topic")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AlineTheme.pillDark)
                        .font(.system(size: 18))
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
            }
        }
    }

    private var stepTwoPromptTitle: String {
        switch viewModel.wizardEntry {
        case .company, .role:
            return "Select Topics"
        case .topic:
            return "Which company are you looking for?"
        }
    }

    private var stepTwoSearchPlaceholder: String {
        switch viewModel.wizardEntry {
        case .company, .role: return "Search interview topics..."
        case .topic: return "Search companies..."
        }
    }

    // MARK: - Step 3 Results View
    @ViewBuilder
    private var stepThreeResultsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Selected Filters Summary (Single line pure text pills - Request 1)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let comp = viewModel.wizardSelectedCompany {
                        wizardSummaryPill(comp)
                    }
                    if let role = viewModel.wizardSelectedRole {
                        wizardSummaryPill(role)
                    }
                    if !viewModel.wizardSelectedTopics.isEmpty {
                        ForEach(Array(viewModel.wizardSelectedTopics), id: \.self) { topic in
                            wizardSummaryPill(topic.rawValue)
                        }
                    } else if let topic = viewModel.wizardSelectedTopic {
                        wizardSummaryPill(topic.rawValue)
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollBounceBehavior(.always, axes: .horizontal)

            // Search Bar in Results
            AlineSearchField("Search practice questions...", text: $viewModel.wizardSearchQuery)
                .padding(.horizontal, 24)

            // Results Feed
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("\(viewModel.wizardFilteredQuestions.count) Questions Matched")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AlineTheme.inkSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 24)

                    if viewModel.wizardFilteredQuestions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundColor(AlineTheme.inkMuted)
                            Text("No questions matched")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("Try searching with different keywords.")
                                .font(.system(size: 13))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.06), lineWidth: 1))
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(viewModel.wizardFilteredQuestions) { q in
                                InterviewQuestionItemCard(q: q) {
                                    selectedWizardQuestion = q
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func wizardSummaryPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(AlineTheme.inkPrimary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.02), radius: 2, y: 1)
    }

    // MARK: - Reusable Selection Pickers
    private var filteredRoles: [String] {
        if stepSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return viewModel.allRoles
        }
        return viewModel.allRoles.filter { $0.localizedCaseInsensitiveContains(stepSearchText) }
    }

    private var rolesSelectionList: some View {
        LazyVStack(spacing: 8) {
            ForEach(filteredRoles, id: \.self) { role in
                let isSelected = viewModel.wizardSelectedRole == role
                Button {
                    withAnimation(AlineTheme.fastSpring) {
                        viewModel.wizardSelectedRole = role
                    }
                } label: {
                    HStack {
                        Text(role)
                            .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AlineTheme.pillDark)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? AlineTheme.pillDark : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filteredCompanies: [String] {
        if stepSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return viewModel.allCompanies
        }
        return viewModel.allCompanies.filter { $0.localizedCaseInsensitiveContains(stepSearchText) }
    }

    private var companiesSelectionGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(filteredCompanies, id: \.self) { comp in
                let isSelected = viewModel.wizardSelectedCompany == comp
                Button {
                    withAnimation(AlineTheme.fastSpring) {
                        viewModel.wizardSelectedCompany = comp
                    }
                } label: {
                    VStack(spacing: 8) {
                        CompanyLogoBadge(companyName: comp, size: 36, isSquircle: true)

                        Text(comp)
                            .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 82)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? AlineTheme.pillDark : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.02), radius: 3, x: 0, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filteredTopics: [QuestionTopic] {
        if stepSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return QuestionTopic.allCases
        }
        return QuestionTopic.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(stepSearchText) }
    }

    private var topicsSelectionGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(filteredTopics) { topic in
                let isSelected = viewModel.wizardSelectedTopics.contains(topic) || viewModel.wizardSelectedTopic == topic
                Button {
                    withAnimation(AlineTheme.fastSpring) {
                        viewModel.toggleWizardTopic(topic)
                    }
                } label: {
                    VStack(spacing: 8) {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(topic.iconBgColor)
                                .frame(width: 38, height: 38)
                            Image(systemName: topic.iconName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(topic.iconColor)
                                .frame(width: 38, height: 38)

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.pillDark)
                                    .background(Circle().fill(Color.white))
                                    .offset(x: 4, y: -4)
                            }
                        }

                        Text(topic.rawValue)
                            .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? AlineTheme.pillDark : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.02), radius: 3, x: 0, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Interview Question Item Card (Consistent No-Difficulty Card)
public struct InterviewQuestionItemCard: View {
    public let q: InterviewQuestion
    public let onTap: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Company + Role + Topic (Text-only pills, single line, no icons - Request 1)
            HStack(spacing: 8) {
                if let comp = q.companyName {
                    Text(comp)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                }

                if let role = q.role {
                    Text(role)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.04))
                        .clipShape(Capsule())
                }

                Text(q.topic.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.04))
                    .clipShape(Capsule())

                Spacer()
            }

            Text(q.questionText)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
                .lineLimit(3)
                .lineSpacing(2)

            // Footer info (Item 9: "Solution", NOT "Verified")
            HStack {
                if q.hasAIGeneratedSolution {
                    Text("AI Foundation Solution")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.15))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 1.0, green: 0.94, blue: 0.88))
                        .clipShape(Capsule())
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                        Text("Solution")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AlineTheme.pillDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AlineTheme.cardMint.opacity(0.4))
                    .clipShape(Capsule())
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Practice")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.pillDark)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AlineTheme.pillDark)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Interview Question Detail View (Amazon-Style Horizontal Swiping & Direct Home Navigation)
public struct InterviewQuestionDetailView: View {
    public let questions: [InterviewQuestion]
    public let initialQuestion: InterviewQuestion
    @ObservedObject public var viewModel: InterviewPrepViewModel
    public var onHomeTapped: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestionId: String = ""

    public init(questions: [InterviewQuestion] = [], initialQuestion: InterviewQuestion, viewModel: InterviewPrepViewModel, onHomeTapped: (() -> Void)? = nil) {
        self.questions = questions.isEmpty ? [initialQuestion] : questions
        self.initialQuestion = initialQuestion
        self.viewModel = viewModel
        self.onHomeTapped = onHomeTapped
        self._currentQuestionId = State(initialValue: initialQuestion.id)
    }

    public init(question: InterviewQuestion, viewModel: InterviewPrepViewModel, onHomeTapped: (() -> Void)? = nil) {
        self.init(questions: [question], initialQuestion: question, viewModel: viewModel, onHomeTapped: onHomeTapped)
    }

    private var activeQuestion: InterviewQuestion {
        viewModel.questions.first(where: { $0.id == currentQuestionId }) ??
        questions.first(where: { $0.id == currentQuestionId }) ?? initialQuestion
    }

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar with back button <, centered title, and Direct Home button (Item 7: Top Share button removed)
                HStack(alignment: .center) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .frame(width: 36, height: 36)
                            .alineGlassCircle()
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Interview Practice")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    Spacer()

                    // Direct Home Icon Button (Jump straight back to main static screen)
                    Button {
                        withAnimation(AlineTheme.fastSpring) {
                            if let onHome = onHomeTapped {
                                onHome()
                            } else {
                                viewModel.resetWizard()
                                dismiss()
                            }
                        }
                    } label: {
                        Image(systemName: "house.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .frame(width: 36, height: 36)
                            .alineGlassCircle()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 6)

                // Amazon-style Horizontal Swiping between questions
                TabView(selection: $currentQuestionId) {
                    ForEach(questions) { q in
                        InterviewQuestionDetailContent(question: q, viewModel: viewModel)
                            .tag(q.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Previous / Next arrows, so moving between questions doesn't rely on swiping
                if questions.count > 1 {
                    questionNavigator
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .environment(\.colorScheme, .light)
        .onAppear {
            viewModel.recordVisitedQuestion(
                question: activeQuestion,
                in: questions,
                company: viewModel.wizardSelectedCompany ?? activeQuestion.companyName,
                role: viewModel.wizardSelectedRole ?? activeQuestion.role,
                topic: viewModel.wizardSelectedTopic ?? activeQuestion.topic
            )
        }
        .onChange(of: currentQuestionId) { _, newId in
            if let q = questions.first(where: { $0.id == newId }) {
                viewModel.recordVisitedQuestion(
                    question: q,
                    in: questions,
                    company: viewModel.wizardSelectedCompany ?? q.companyName,
                    role: viewModel.wizardSelectedRole ?? q.role,
                    topic: viewModel.wizardSelectedTopic ?? q.topic
                )
            }
        }
    }

    private var currentIndex: Int {
        questions.firstIndex(where: { $0.id == currentQuestionId }) ?? 0
    }

    private func goToQuestion(at index: Int) {
        guard questions.indices.contains(index) else { return }
        withAnimation(AlineTheme.fastSpring) {
            currentQuestionId = questions[index].id
        }
    }

    private var questionNavigator: some View {
        let index = currentIndex
        let hasPrevious = index > 0
        let hasNext = index < questions.count - 1

        return HStack(spacing: 12) {
            Button {
                goToQuestion(at: index - 1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .frame(width: 46, height: 46)
                    .alineGlassCircle()
            }
            .buttonStyle(.plain)
            .disabled(!hasPrevious)
            .opacity(hasPrevious ? 1 : 0.35)
            .accessibilityLabel("Previous question")

            Spacer()

            Text("\(index + 1) of \(questions.count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AlineTheme.inkSecondary)
                .monospacedDigit()

            Spacer()

            Button {
                goToQuestion(at: index + 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .frame(width: 46, height: 46)
                    .alineGlassCircle()
            }
            .buttonStyle(.plain)
            .disabled(!hasNext)
            .opacity(hasNext ? 1 : 0.35)
            .accessibilityLabel("Next question")
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}

// MARK: - Interview Question Detail Scrollable Content
public struct InterviewQuestionDetailContent: View {
    public let question: InterviewQuestion
    @ObservedObject public var viewModel: InterviewPrepViewModel

    private var liveQuestion: InterviewQuestion {
        viewModel.questions.first(where: { $0.id == question.id }) ?? question
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // 1. Question Statement
                Text(question.questionText)
                    .font(.system(size: 21, weight: .heavy))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .lineSpacing(3.5)
                    .padding(.top, 4)

                // 2. Single Line Metadata: Company, Role, and Topic all consistent text buttons (Request 1: No logo, no icon, single line)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let comp = question.companyName {
                            Text(comp)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.02), radius: 2, y: 1)
                        }

                        if let role = question.role {
                            Text(role)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.02), radius: 2, y: 1)
                        }

                        Text(question.topic.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.02), radius: 2, y: 1)

                        Spacer()
                    }
                }
                .scrollBounceBehavior(.always, axes: .horizontal)

                // 3. Upvote, Save, and Share buttons (Change to black on selection, keep white button background)
                HStack(spacing: 10) {
                    Button {
                        withAnimation(AlineTheme.fastSpring) {
                            viewModel.toggleUpvote(for: liveQuestion)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 13, weight: liveQuestion.isUpvoted ? .heavy : .bold))
                                .foregroundColor(liveQuestion.isUpvoted ? Color.black : AlineTheme.inkSecondary)
                            Text("\(liveQuestion.upvotesCount) Upvotes")
                                .font(.system(size: 12.5, weight: liveQuestion.isUpvoted ? .heavy : .bold))
                                .foregroundColor(liveQuestion.isUpvoted ? Color.black : AlineTheme.inkSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(liveQuestion.isUpvoted ? Color.black : Color.black.opacity(0.08), lineWidth: liveQuestion.isUpvoted ? 1.5 : 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(AlineTheme.fastSpring) {
                            viewModel.toggleSave(for: liveQuestion)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: liveQuestion.isSaved ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 13, weight: liveQuestion.isSaved ? .heavy : .bold))
                                .foregroundColor(liveQuestion.isSaved ? Color.black : AlineTheme.inkSecondary)
                            Text(liveQuestion.isSaved ? "Saved" : "Save")
                                .font(.system(size: 12.5, weight: liveQuestion.isSaved ? .heavy : .bold))
                                .foregroundColor(liveQuestion.isSaved ? Color.black : AlineTheme.inkSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(liveQuestion.isSaved ? Color.black : Color.black.opacity(0.08), lineWidth: liveQuestion.isSaved ? 1.5 : 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)

                    ShareLink(item: "\(liveQuestion.questionText)\n\nCompany: \(liveQuestion.companyName ?? "General") | Role: \(liveQuestion.role ?? "General")") {
                        HStack(spacing: 6) {
                            Image(systemName: "arrowshape.turn.up.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)
                            Text("Share")
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)

                Divider().opacity(0.3)

                // 4. Reveal / Hide Hint Card (Item 10: White Background & Hide Button)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(AlineTheme.accentAmber)
                        Text("Interview Hint")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Spacer()

                        if viewModel.revealedHints.contains(question.id) {
                            Button("Hide Hint") {
                                withAnimation(AlineTheme.fastSpring) {
                                    viewModel.toggleHint(for: question.id)
                                }
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AlineTheme.inkSecondary)
                        } else {
                            Button("Reveal Hint") {
                                withAnimation(AlineTheme.fastSpring) {
                                    viewModel.revealHint(for: question.id)
                                }
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.pillDark)
                        }
                    }

                    if viewModel.revealedHints.contains(question.id) {
                        Text(question.hint ?? "Consider breaking the question into input boundaries and analyzing best/worst case trade-offs.")
                            .font(.system(size: 14))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineSpacing(3.5)
                    } else {
                        Text("Think independently first. Tap Reveal Hint for a small nudge without spoiling the complete solution.")
                            .font(.system(size: 12))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.06), lineWidth: 1))

                // 5. Reveal / Hide Approach Card (Item 10: Hide Button)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(AlineTheme.pillDark)
                        Text("Recommended Approach & Framework")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Spacer()

                        if viewModel.revealedApproaches.contains(question.id) {
                            Button("Hide Approach") {
                                withAnimation(AlineTheme.fastSpring) {
                                    viewModel.toggleApproach(for: question.id)
                                }
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AlineTheme.inkSecondary)
                        } else {
                            Button("Show Approach") {
                                withAnimation(AlineTheme.fastSpring) {
                                    viewModel.revealApproach(for: question.id)
                                }
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.pillDark)
                        }
                    }

                    if viewModel.revealedApproaches.contains(question.id) {
                        Text(question.approach ?? "Formulate your reasoning using progressive constraints and data structures.")
                            .font(.system(size: 14))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineSpacing(4)

                        if let tc = question.timeComplexity {
                            HStack(spacing: 12) {
                                Text("Time: \(tc)").font(.system(size: 12, weight: .bold))
                                if let sc = question.spaceComplexity {
                                    Text("Space: \(sc)").font(.system(size: 12, weight: .bold))
                                }
                            }
                            .padding(.top, 4)
                            .foregroundColor(AlineTheme.inkSecondary)
                        }
                    } else {
                        Text("Structured framework covering optimal edge cases, algorithm breakdown, and complexity analysis.")
                            .font(.system(size: 12))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.06), lineWidth: 1))

                // 6. Complete Solution Card (Item 6: Single line & Item 9: No Sparkle)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(question.hasAIGeneratedSolution ? "AI Solution" : "Solution")
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        Spacer(minLength: 8)

                        if viewModel.revealedSolutions.contains(question.id) {
                            Button("Hide Solution") {
                                withAnimation(AlineTheme.fastSpring) {
                                    viewModel.toggleSolution(for: question.id)
                                }
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AlineTheme.inkSecondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        } else if viewModel.isGeneratingAISolution[question.id] == true {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Synthesizing...")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.pillDark)
                                    .lineLimit(1)
                            }
                            .fixedSize(horizontal: true, vertical: false)
                        } else {
                            Button {
                                if question.hasAIGeneratedSolution {
                                    viewModel.generateAISolution(for: question.id)
                                } else {
                                    withAnimation(AlineTheme.fastSpring) {
                                        viewModel.revealSolution(for: question.id)
                                    }
                                }
                            } label: {
                                Text(question.hasAIGeneratedSolution ? "Generate AI Solution" : "Show Solution")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(AlineTheme.pillDark)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if viewModel.revealedSolutions.contains(question.id) {
                        let solutionText = question.answer ?? question.aiGeneratedAnswer ?? "No solution provided."

                        VStack(alignment: .leading, spacing: 8) {
                            if question.hasAIGeneratedSolution {
                                Text("Synthesized by Aline AI Foundation Model")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.15))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 1.0, green: 0.94, blue: 0.88))
                                    .clipShape(Capsule())
                            }

                            Text(solutionText)
                                .font(.system(size: 13.5, design: .monospaced))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .lineSpacing(3)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AlineTheme.cardMint.opacity(0.35))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        Text("Step-by-step implementation code, test cases, and edge-case handling synthesized by peer contributors or Aline AI.")
                            .font(.system(size: 12))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.06), lineWidth: 1))

                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Contribute Question Modal (Item 8: Clean App UI & Item 7: No Difficulty)
public struct ContributeQuestionModalView: View {
    @ObservedObject public var viewModel: InterviewPrepViewModel
    public var onSubmittedToInterviewQuestions: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var questionText: String = ""
    @State private var topic: QuestionTopic = .dsa
    @State private var company: String = "Google"
    @State private var role: String = "Software Engineer"
    @State private var hintText: String = ""
    @State private var approachText: String = ""
    @State private var solutionText: String = ""

    // Search and select sheets (Item 10)
    @State private var showCompanyPicker: Bool = false
    @State private var showRolePicker: Bool = false

    // AI Generation (Item 11)
    @State private var isGeneratingAIAnswer: Bool = false

    // Duplicate detection (Item 13)
    @State private var similarQuestionFound: InterviewQuestion? = nil
    @State private var showSimilarAlert: Bool = false

    public init(viewModel: InterviewPrepViewModel, onSubmittedToInterviewQuestions: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSubmittedToInterviewQuestions = onSubmittedToInterviewQuestions
    }

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Action Bar matching CreateDiscussionPostView
                HStack(alignment: .center) {
                    AlineCloseButton { dismiss() }

                    Spacer()

                    Text("Contribute Question")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    Spacer()

                    // Always the solid dark button (the unselected glass style was nearly invisible
                    // on this background); with no question yet it's dimmed and does nothing
                    Button {
                        handleQuestionSubmission()
                    } label: {
                        Text("Submit")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .alineGlassCapsule(selected: true)
                            .opacity(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // 1. Question Statement Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("INTERVIEW QUESTION")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)

                            TextField("E.g. Design a distributed cache like Redis with eviction policies...", text: $questionText, axis: .vertical)
                                .lineLimit(3...6)
                                .font(.system(size: 15))
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 1))
                        }

                        // 2. Company & Role Search and Select (Item 10: Single Selection with Search)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                // Company Picker Button
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("COMPANY")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AlineTheme.inkSecondary)

                                    Button {
                                        showCompanyPicker = true
                                    } label: {
                                        HStack {
                                            CompanyLogoBadge(companyName: company, size: 20, isSquircle: true)
                                            Text(company)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(AlineTheme.inkPrimary)
                                                .lineLimit(1)
                                            Spacer()
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(AlineTheme.inkSecondary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }

                                // Role Picker Button
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("ROLE")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AlineTheme.inkSecondary)

                                    Button {
                                        showRolePicker = true
                                    } label: {
                                        HStack {
                                            Text(role)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(AlineTheme.inkPrimary)
                                                .lineLimit(1)
                                            Spacer()
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(AlineTheme.inkSecondary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // 3. Topic Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TOPIC")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(QuestionTopic.allCases) { t in
                                        let isSelected = topic == t
                                        Button {
                                            topic = t
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: t.iconName)
                                                    .font(.system(size: 11, weight: .bold))
                                                Text(t.rawValue)
                                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                            }
                                            .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(isSelected ? AlineTheme.pillDark : Color.white)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(isSelected ? Color.clear : Color.black.opacity(0.07), lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .scrollBounceBehavior(.always, axes: .horizontal)
                        }

                        // 4. AI Foundation Banner (Item 9: No Sparkles)
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.15))
                            Text("You can write your own solution, or tap 'Give Answer with AI' below to synthesize and verify an optimal response before posting.")
                                .font(.system(size: 12))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .lineSpacing(2)
                        }
                        .padding(14)
                        .background(Color(red: 1.0, green: 0.96, blue: 0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // 5. Optional Hint
                        VStack(alignment: .leading, spacing: 6) {
                            Text("OPTIONAL HINT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)

                            TextField("Provide a small nudge without spoiling...", text: $hintText, axis: .vertical)
                                .lineLimit(2...3)
                                .font(.system(size: 14))
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06), lineWidth: 1))
                        }

                        // 6. Optional Approach
                        VStack(alignment: .leading, spacing: 6) {
                            Text("OPTIONAL APPROACH")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)

                            TextField("Describe algorithmic framework or constraints...", text: $approachText, axis: .vertical)
                                .lineLimit(2...4)
                                .font(.system(size: 14))
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06), lineWidth: 1))
                        }

                        // 7. Solution / Answer with "Give Answer with AI" (Item 11)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("SOLUTION / ANSWER")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AlineTheme.inkSecondary)

                                Spacer()

                                Button {
                                    synthesizeAIAnswer()
                                } label: {
                                    HStack(spacing: 5) {
                                        if isGeneratingAIAnswer {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                            Text("Synthesizing...")
                                                .font(.system(size: 11, weight: .bold))
                                        } else {
                                            Image(systemName: "brain.head.profile")
                                                .font(.system(size: 11))
                                            Text("Give Answer with AI")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                    }
                                    .foregroundColor(AlineTheme.pillDark)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(AlineTheme.cardMint.opacity(0.5))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .disabled(isGeneratingAIAnswer || questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            TextField("Paste implementation or tap 'Give Answer with AI' to generate for verification...", text: $solutionText, axis: .vertical)
                                .lineLimit(4...8)
                                .font(.system(size: 13.5, design: .monospaced))
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06), lineWidth: 1))
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .environment(\.colorScheme, .light)
        .sheet(isPresented: $showCompanyPicker) {
            ContributeSingleCompanyPickerSheet(selectedCompany: $company, allCompanies: viewModel.allCompanies)
        }
        .sheet(isPresented: $showRolePicker) {
            ContributeSingleRolePickerSheet(selectedRole: $role, allRoles: viewModel.allRoles)
        }
        .alert("Similar Question Found", isPresented: $showSimilarAlert, presenting: similarQuestionFound) { existing in
            Button("Upvote Existing (\(existing.upvotesCount) upvotes)") {
                viewModel.toggleUpvote(for: existing)
                viewModel.wizardSelectedCompany = existing.companyName
                viewModel.wizardSelectedRole = existing.role
                viewModel.wizardSelectedTopics = [existing.topic]
                viewModel.wizardSelectedTopic = existing.topic
                viewModel.wizardStep = 3
                viewModel.wizardActive = true
                dismiss()
                onSubmittedToInterviewQuestions?()
            }
            Button("Post Anyway", role: .none) {
                performAddQuestion()
                dismiss()
                onSubmittedToInterviewQuestions?()
            }
            Button("Cancel", role: .cancel) {}
        } message: { existing in
            Text("A similar question already exists: \"\(existing.questionText)\". Would you like to upvote the existing question instead of creating a duplicate?")
        }
    }

    private func synthesizeAIAnswer() {
        let trimmed = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isGeneratingAIAnswer = true

        Task {
            // On-device model; the contributor reviews the draft before posting it
            if let solution = await OnDeviceAI.solve(question: trimmed, topic: topic.rawValue, company: company, role: role) {
                solutionText = solution.fullAnswer
                if hintText.isEmpty { hintText = solution.hint }
                if approachText.isEmpty { approachText = solution.approach }
            }
            isGeneratingAIAnswer = false
        }
    }

    private func handleQuestionSubmission() {
        let trimmed = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Item 13: Detect similar questions
        if let existing = findSimilarQuestion(for: trimmed) {
            similarQuestionFound = existing
            showSimilarAlert = true
        } else {
            performAddQuestion()
            dismiss()
            onSubmittedToInterviewQuestions?()
        }
    }

    private func performAddQuestion() {
        let trimmed = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        viewModel.addQuestion(
            questionText: trimmed,
            topic: topic,
            company: company,
            role: role,
            difficulty: "General",
            hint: hintText.isEmpty ? nil : hintText,
            approach: approachText.isEmpty ? nil : approachText,
            answer: solutionText.isEmpty ? nil : solutionText
        )

        // Item 3: Directly open Interview Questions screen showing this question at top
        viewModel.wizardSelectedCompany = company
        viewModel.wizardSelectedRole = role
        viewModel.wizardSelectedTopics = [topic]
        viewModel.wizardSelectedTopic = topic
        viewModel.wizardStep = 3
        viewModel.wizardActive = true
    }

    private func findSimilarQuestion(for text: String) -> InterviewQuestion? {
        let lower = text.lowercased()
        let words = Set(lower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 3 })
        for q in viewModel.questions {
            let qLower = q.questionText.lowercased()
            if qLower == lower { return q }
            let qWords = Set(qLower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 3 })
            let intersection = words.intersection(qWords)
            if intersection.count >= 3 && Double(intersection.count) / Double(max(words.count, 1)) >= 0.45 {
                return q
            }
        }
        return nil
    }
}

// MARK: - Contribute Single Company Picker Sheet (Item 10)
public struct ContributeSingleCompanyPickerSheet: View {
    @Binding public var selectedCompany: String
    public let allCompanies: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var search: String = ""

    private var filteredList: [String] {
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return allCompanies }
        return allCompanies.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                DiscoverBackgroundArtwork()
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    AlineSearchField("Search companies...", text: $search)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty && !allCompanies.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                                Button {
                                    selectedCompany = trimmed
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        CompanyLogoBadge(companyName: trimmed, size: 30, isSquircle: true)
                                        Text("Use \"\(trimmed)\"")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(AlineTheme.pillDark)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AlineTheme.pillDark.opacity(0.3), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }

                            ForEach(filteredList, id: \.self) { comp in
                                let isSelected = selectedCompany.caseInsensitiveCompare(comp) == .orderedSame
                                Button {
                                    selectedCompany = comp
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        CompanyLogoBadge(companyName: comp, size: 30, isSquircle: true)
                                        Text(comp)
                                            .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                                            .foregroundColor(AlineTheme.inkPrimary)
                                        Spacer()
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AlineTheme.pillDark)
                                                .font(.system(size: 18))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? AlineTheme.pillDark : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Select Company")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    AlineCloseButton { dismiss() }
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }
}

// MARK: - Contribute Single Role Picker Sheet (Item 10)
public struct ContributeSingleRolePickerSheet: View {
    @Binding public var selectedRole: String
    public let allRoles: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var search: String = ""

    private var filteredList: [String] {
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return allRoles }
        return allRoles.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                DiscoverBackgroundArtwork()
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    AlineSearchField("Search tech roles...", text: $search)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty && !allRoles.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                                Button {
                                    selectedRole = trimmed
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        Text("Use \"\(trimmed)\"")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(AlineTheme.pillDark)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AlineTheme.pillDark.opacity(0.3), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }

                            ForEach(filteredList, id: \.self) { r in
                                let isSelected = selectedRole.caseInsensitiveCompare(r) == .orderedSame
                                Button {
                                    selectedRole = r
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(r)
                                            .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                                            .foregroundColor(AlineTheme.inkPrimary)
                                        Spacer()
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AlineTheme.pillDark)
                                                .font(.system(size: 18))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? AlineTheme.pillDark : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Select Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    AlineCloseButton { dismiss() }
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }
}

// MARK: - All Companies Selector Sheet (Direct Single Tap Select & Dismiss - Request 2)
public struct AllCompaniesSelectorSheet: View {
    @ObservedObject public var viewModel: InterviewPrepViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var search: String = ""

    private var filteredCompanies: [String] {
        if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return viewModel.allCompanies
        }
        return viewModel.allCompanies.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                DiscoverBackgroundArtwork()
                    .ignoresSafeArea()

            VStack(spacing: 12) {
                AlineSearchField("Search companies...", text: $search)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                ScrollView(.vertical, showsIndicators: false) {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(filteredCompanies, id: \.self) { comp in
                            let isSelected = viewModel.selectedCompanies.contains(comp) || viewModel.wizardSelectedCompany == comp
                            let questionCount = viewModel.questions.filter {
                                guard let c = $0.companyName else { return false }
                                return c.localizedCaseInsensitiveContains(comp)
                            }.count

                            Button {
                                withAnimation(AlineTheme.fastSpring) {
                                    viewModel.startWizardFromCompany(comp)
                                }
                                dismiss()
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack(alignment: .topTrailing) {
                                        CompanyLogoBadge(companyName: comp, size: 38, isSquircle: true)

                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(AlineTheme.pillDark)
                                                .background(Circle().fill(Color.white))
                                                .offset(x: 4, y: -4)
                                        }
                                    }

                                    Text(comp)
                                        .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                        .lineLimit(1)

                                    Text("\(questionCount) Qs")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 94)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(isSelected ? AlineTheme.pillDark : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                                )
                                .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.02), radius: 3, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("All Companies")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                AlineCloseButton { dismiss() }
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.selectedCompanies.isEmpty {
                    Button("Clear") {
                        viewModel.selectedCompanies.removeAll()
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AlineTheme.pillDark)
                }
            }
        }
    }
}
}

// MARK: - All Roles Selector Sheet (Direct Single Tap Select & Dismiss - Request 2)
public struct AllRolesSelectorSheet: View {
    @ObservedObject public var viewModel: InterviewPrepViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var search: String = ""

    private var filteredRoles: [String] {
        if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return viewModel.allRoles
        }
        return viewModel.allRoles.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                DiscoverBackgroundArtwork()
                    .ignoresSafeArea()

            VStack(spacing: 12) {
                AlineSearchField("Search roles...", text: $search)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredRoles, id: \.self) { role in
                            let isSelected = viewModel.selectedRoles.contains(role)
                            let questionCount = viewModel.questions.filter {
                                guard let r = $0.role else { return false }
                                return r.localizedCaseInsensitiveContains(role)
                            }.count

                            Button {
                                withAnimation(AlineTheme.fastSpring) {
                                    viewModel.startWizardFromRole(role)
                                }
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(role)
                                            .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                                            .foregroundColor(AlineTheme.inkPrimary)
                                        Text("\(questionCount) Questions")
                                            .font(.system(size: 12))
                                            .foregroundColor(AlineTheme.inkSecondary)
                                    }

                                    Spacer()

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AlineTheme.pillDark)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(isSelected ? AlineTheme.pillDark : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("All Tech Roles")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                AlineCloseButton { dismiss() }
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.selectedRoles.isEmpty {
                    Button("Clear") {
                        viewModel.selectedRoles.removeAll()
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AlineTheme.pillDark)
                }
            }
        }
    }
}
}

// MARK: - All Topics Selector Sheet (Direct Single Tap Select & Dismiss - Request 2)
public struct AllTopicsSelectorSheet: View {
    @ObservedObject public var viewModel: InterviewPrepViewModel
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                DiscoverBackgroundArtwork()
                    .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(QuestionTopic.allCases) { topic in
                        let isSelected = viewModel.selectedTopics.contains(topic) || viewModel.wizardSelectedTopic == topic
                        let count = viewModel.questions.filter { $0.topic == topic }.count

                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                viewModel.startWizardFromTopic(topic)
                            }
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(topic.iconBgColor)
                                        .frame(width: 38, height: 38)
                                    Image(systemName: topic.iconName)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(topic.iconColor)
                                        .frame(width: 38, height: 38)

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(AlineTheme.pillDark)
                                            .background(Circle().fill(Color.white))
                                            .offset(x: 4, y: -4)
                                    }
                                }

                                Text(topic.rawValue)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .lineLimit(1)

                                Text("\(count) Qs")
                                    .font(.system(size: 11))
                                    .foregroundColor(AlineTheme.inkSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 94)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(isSelected ? AlineTheme.pillDark : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                            )
                            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.02), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("All Topics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                AlineCloseButton { dismiss() }
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.selectedTopics.isEmpty {
                    Button("Clear") {
                        viewModel.selectedTopics.removeAll()
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AlineTheme.pillDark)
                }
            }
        }
    }
}
}

// MARK: - Company Community Detail View (Company Discussions & Search Bar - Requirement 4)
public struct CompanyCommunityDetailView: View {
    public let company: CompanyCommunity
    @ObservedObject public var viewModel: CommunityViewModel
    public let onSelectPost: (DiscussionPost) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery: String = ""
    @State private var searchActive: Bool = false
    @State private var showCreatePostForCompany: Bool = false
    @State private var selectedPostInCommunity: DiscussionPost? = nil

    private var companyDiscussions: [DiscussionPost] {
        let matching = viewModel.posts.filter { post in
            guard let comp = post.companyName, !comp.isEmpty else { return false }
            return comp.localizedCaseInsensitiveContains(company.name) || company.name.localizedCaseInsensitiveContains(comp)
        }
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return matching
        }
        let query = searchQuery.lowercased()
        return matching.filter { post in
            post.title.lowercased().contains(query) ||
            post.excerpt.lowercased().contains(query) ||
            post.authorName.lowercased().contains(query) ||
            post.topics.contains { $0.lowercased().contains(query) }
        }
    }

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar with iOS 27 glass back button & Share button on top right (matching Image 1 exactly)
                HStack(alignment: .center) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .frame(width: 36, height: 36)
                            .alineGlassCircle()
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Share Company Community at the top right hand corner
                    ShareLink(item: "\(company.name) Community on Aline - \(company.memberCount)\n\(company.description)") {
                        Image(systemName: "arrowshape.turn.up.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .frame(width: 36, height: 36)
                            .alineGlassCircle()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                            // Company Header: Logo + Name + Members + Following button on right + Description (User Request 2)
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .center, spacing: 12) {
                                    CompanyLogoBadge(companyName: company.name, size: 48, isSquircle: true)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(company.name)
                                            .font(.system(size: 20, weight: .heavy))
                                            .foregroundColor(AlineTheme.inkPrimary)
                                        Text(company.memberCount)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(AlineTheme.inkSecondary)
                                    }

                                    Spacer()

                                    // Following button aligned to the company name at the right hand end (User Request 2)
                                    Button {
                                        withAnimation(AlineTheme.fastSpring) {
                                            viewModel.toggleFollowCompany(name: company.name)
                                        }
                                    } label: {
                                        let isFollowed = viewModel.followedCompanies.contains { $0.name == company.name }
                                        HStack(spacing: 5) {
                                            Image(systemName: isFollowed ? "checkmark" : "plus")
                                                .font(.system(size: 11, weight: .bold))
                                            Text(isFollowed ? "Following" : "Follow")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        .foregroundColor(isFollowed ? AlineTheme.inkPrimary : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .alineGlassCapsule(selected: !(isFollowed))
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text(company.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(AlineTheme.inkSecondary)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)

                            // Company Discussions Search Bar
                            AlineSearchField("Search \(company.name) discussions...", text: $searchQuery, isActive: $searchActive)

                            // Section Title
                            HStack {
                                Text("Company Discussions")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)

                                Spacer()

                                Text("\(companyDiscussions.count) Posts")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.inkSecondary)
                            }

                            // Discussions List
                            if companyDiscussions.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 32))
                                        .foregroundColor(AlineTheme.inkMuted)
                                    Text("No discussions found for \(company.name)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                    Text("Be the first to share an interview loop, OA pattern, or insight for \(company.name)!")
                                        .font(.system(size: 12))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(28)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                                )
                            } else {
                                VStack(spacing: 14) {
                                    ForEach(companyDiscussions) { post in
                                        CommunityDiscussionCard(
                                            post: post,
                                            onTap: {
                                                selectedPostInCommunity = post
                                            },
                                            onToggleLike: {
                                                withAnimation(AlineTheme.fastSpring) {
                                                    viewModel.toggleLike(for: post.id)
                                                }
                                            },
                                            onToggleSave: {
                                                withAnimation(AlineTheme.fastSpring) {
                                                    viewModel.toggleSave(for: post.id)
                                                }
                                            },
                                            onShare: {
                                                viewModel.incrementShare(for: post.id)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        .padding(.bottom, 90)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }

                // Floating Action Button to post directly in this company (User Request 4)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showCreatePostForCompany = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(AlineTheme.pillDark)
                                    .frame(width: 54, height: 54)
                                    .shadow(color: Color.black.opacity(0.20), radius: 6, x: 0, y: 3)
                                Image(systemName: "plus")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showCreatePostForCompany) {
            CreateDiscussionPostView(viewModel: viewModel, prefilledCompany: company.name)
        }
        .navigationDestination(item: $selectedPostInCommunity) { post in
            DiscussionDetailView(post: post, viewModel: viewModel)
        }
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Previews
#Preview("Community Hub Canvas") {
    CommunityView(
        communityViewModel: CommunityViewModel(),
        prepViewModel: InterviewPrepViewModel(),
        navViewModel: AppNavigationViewModel()
    )
}

#Preview("Discussion Post Detail") {
    let communityVM = CommunityViewModel()
    let post = communityVM.posts.first ?? .previewSample
    return NavigationStack {
        DiscussionDetailView(post: post, viewModel: communityVM)
    }
}

#Preview("Interview Question Detail") {
    let prepVM = InterviewPrepViewModel()
    let q = prepVM.questions.first ?? .previewSample
    return InterviewQuestionDetailView(question: q, viewModel: prepVM)
}
