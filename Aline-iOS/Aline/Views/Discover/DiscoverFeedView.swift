import SwiftUI

// MARK: - Discover Feed View (Left Screen in Reference Image)
public struct DiscoverFeedView: View {
    @AppStorage("userFullName") private var userFullName: String = ""
    @State private var searchActive: Bool = false
    @State private var screenHeight: CGFloat = 900
    @State private var topInset: CGFloat = 59
    @ObservedObject public var viewModel: DiscoverViewModel
    @ObservedObject public var navViewModel: AppNavigationViewModel
    @ObservedObject public var resumeViewModel: ResumeViewModel
    @State private var showingDetailFor: Opportunity? = nil
    @State private var showingRecommendedAll: Bool = false
    @State private var showingExploreMoreAll: Bool = false
    @State private var highlightedCardId: String? = nil

    private var dynamicFirstName: String {
        let activeName = !navViewModel.currentUserFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? navViewModel.currentUserFullName
            : userFullName
        return activeName.components(separatedBy: " ").first ?? activeName
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            DiscoverBackgroundArtwork()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AlineSpacing.section) {
                    // Top User Bar
                    HStack(alignment: .center) {
                        Text("Hey \(dynamicFirstName)!")
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Spacer()

                        // Notifications Bell
                        Button {
                            navViewModel.openNotifications(category: .opportunities)
                        } label: {
                            ZStack {
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
                            .frame(width: 40, height: 40)
                            .alineGlassCircle()
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    // Dynamic Hero Headline (Changes to LIKED or APPLIED OPPORTUNITIES)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(headlineTitle)
                            .font(.system(size: 32, weight: .black, design: .default))
                            .lineSpacing(2)
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text(headlineSubtitle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    .padding(.horizontal, 24)

                    // Interactive Search Bar with Filter Icon Near It (No Word "Filters")
                    HStack(spacing: 10) {
                        AlineSearchField("Search roles, companies, or skills", text: $viewModel.searchQuery, isActive: $searchActive)

                        // Filter Icon Button (no word "Filters", right next to search bar)
                        if !searchActive {
                        Button {
                            viewModel.showFilterSheet = true
                        } label: {
                            ZStack {
                                Color.clear.frame(width: 44, height: 44)
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(viewModel.activeFilterCount > 0 ? .white : AlineTheme.inkPrimary)

                                if viewModel.activeFilterCount > 0 {
                                    Circle()
                                        .fill(AlineTheme.accentHeart)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 10, y: -10)
                                }
                            }
.alineGlassCircle(selected: viewModel.activeFilterCount > 0)
                        }
                        .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Filter Segments (Recommended, Liked, Applied)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(DiscoverViewModel.FilterTab.allCases, id: \.self) { tab in
                                let isSelected = viewModel.selectedFilterTab == tab
                                Button {
                                    withAnimation(AlineTheme.fastSpring) {
                                        viewModel.selectedFilterTab = tab
                                    }
                                } label: {
                                    Text(tab.rawValue)
                                        .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                                        .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                                        .padding(.horizontal, 22)
                                        .padding(.vertical, 8)
                                        .alineGlassCapsule(selected: isSelected)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    if viewModel.selectedFilterTab == .liked {
                        // MARK: - Liked Opportunities (Proper Vertical Scroll, Non-Overlapping)
                        let likedJobs = viewModel.filteredOpportunities
                        if likedJobs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "heart.slash")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(AlineTheme.inkMuted)
                                    .padding(.top, 30)
                                Text("No liked opportunities yet")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                Text("Tap the heart icon on any job card to save it here.")
                                    .font(.system(size: 13))
                                    .foregroundColor(AlineTheme.inkSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                        } else {
                            LazyVStack(spacing: AlineSpacing.card) {
                                ForEach(likedJobs) { opp in
                                    StackedOpportunityCard(
                                        opportunity: opp,
                                        isExpanded: true,
                                        isHighlighted: false,
                                        onSelect: {
                                            showingDetailFor = opp
                                        },
                                        onOpenDetail: {
                                            showingDetailFor = opp
                                        },
                                        onLike: {
                                            withAnimation(AlineTheme.cardSpring) {
                                                viewModel.toggleLike(for: opp.id)
                                            }
                                        }
                                    )
                                    .contextMenu {
                                        // "Not relevant": hides the job and steers recommendations away from similar ones
                                        Button("Not relevant", systemImage: "hand.thumbsdown") {
                                            withAnimation(AlineTheme.fastSpring) { viewModel.dismissJob(opp.id) }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    } else if viewModel.selectedFilterTab == .applied {
                        // MARK: - Applied Opportunities (Proper Vertical Scroll, Non-Overlapping)
                        let appliedJobs = viewModel.filteredOpportunities
                        if appliedJobs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "briefcase")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(AlineTheme.inkMuted)
                                    .padding(.top, 30)
                                Text("No applied opportunities yet")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                Text("Jobs you apply to will automatically appear here.")
                                    .font(.system(size: 13))
                                    .foregroundColor(AlineTheme.inkSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(appliedJobs) { opp in
                                    StackedOpportunityCard(
                                        opportunity: opp,
                                        isExpanded: true,
                                        isHighlighted: false,
                                        onSelect: {
                                            showingDetailFor = opp
                                        },
                                        onOpenDetail: {
                                            showingDetailFor = opp
                                        },
                                        onLike: {
                                            withAnimation(AlineTheme.cardSpring) {
                                                viewModel.toggleLike(for: opp.id)
                                            }
                                        }
                                    )
                                    .contextMenu {
                                        // "Not relevant": hides the job and steers recommendations away from similar ones
                                        Button("Not relevant", systemImage: "hand.thumbsdown") {
                                            withAnimation(AlineTheme.fastSpring) { viewModel.dismissJob(opp.id) }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    } else {
                        // MARK: - Recommended Tab Feed
                        let recommendedJobs = viewModel.recommendedOpportunities
                        let exploreJobs = viewModel.exploreMoreOpportunities

                        // Recommended Section Header
                        if !recommendedJobs.isEmpty {
                            HStack(alignment: .center) {
                                Text("Showing \(min(10, recommendedJobs.count)) of \(recommendedJobs.count)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)

                                Spacer()

                                if recommendedJobs.count > 10 {
                                    Button {
                                        showingRecommendedAll = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text("View More")
                                                .font(.system(size: 13, weight: .bold))
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .foregroundColor(AlineTheme.inkPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .alineGlassCapsule(selected: false)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        // Content Area: Empty State OR Normal Horizontal Scroll (>85% Match)
                        if recommendedJobs.isEmpty && viewModel.isLoading {
                            // First fetch (or a cold backend) can take a while: say so instead of "nothing found"
                            DiscoverLoadingCard()
                                .padding(.horizontal, 24)
                        } else if recommendedJobs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(AlineTheme.inkMuted)
                                    .padding(.top, 30)
                                Text("No recommended opportunities found")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                Text("Try adjusting your filters or search keywords.")
                                    .font(.system(size: 13))
                                    .foregroundColor(AlineTheme.inkSecondary)
                                Button {
                                    viewModel.resetFilters()
                                } label: {
                                    Text("Reset Filters")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .alineGlassCapsule(selected: true)
                                }
                                .padding(.top, 4)
                                .padding(.bottom, 30)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                        } else {
                            // Normal Horizontal Scroll (Only Top 10 Recommended Cards > 85% Match)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    let topRecommended = Array(recommendedJobs.prefix(10))

                                    ForEach(topRecommended) { opp in
                                        StackedOpportunityCard(
                                            opportunity: opp,
                                            isExpanded: true,
                                            isHighlighted: false,
                                            onSelect: {
                                                showingDetailFor = opp
                                            },
                                            onOpenDetail: {
                                                showingDetailFor = opp
                                            },
                                            onLike: {
                                                withAnimation(AlineTheme.cardSpring) {
                                                    viewModel.toggleLike(for: opp.id)
                                                }
                                            }
                                        )
                                        .contextMenu {
                                            // "Not relevant": hides the job and steers recommendations away from similar ones
                                            Button("Not relevant", systemImage: "hand.thumbsdown") {
                                                withAnimation(AlineTheme.fastSpring) { viewModel.dismissJob(opp.id) }
                                            }
                                        }
                                        .frame(width: 330, height: 226)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 4)
                            }
                        }

                        // MARK: - Explore More Section (Sticky Pinned Header & Compact List Cards)
                        if !exploreJobs.isEmpty {
                            LazyVStack(spacing: AlineSpacing.card, pinnedViews: [.sectionHeaders]) {
                                Section {
                                    VStack(spacing: AlineSpacing.card) {
                                        ForEach(Array(exploreJobs.prefix(10))) { opp in
                                            CompactExploreOpportunityCard(
                                                opportunity: opp,
                                                onOpenDetail: {
                                                    showingDetailFor = opp
                                                }
                                            )
                                            .contextMenu {
                                                // "Not relevant": hides the job and steers recommendations away from similar ones
                                                Button("Not relevant", systemImage: "hand.thumbsdown") {
                                                    withAnimation(AlineTheme.fastSpring) { viewModel.dismissJob(opp.id) }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                } header: {
                                    ExploreMorePinnedHeader(
                                        count: exploreJobs.count,
                                        screenHeight: screenHeight,
                                        onViewMore: {
                                            showingExploreMoreAll = true
                                        }
                                    )
                                }
                            }
                        }
                    }

                    Spacer(minLength: 110) // Room for floating tab bar
                }
            }
.scrollDismissesKeyboard(.interactively)
.scrollEdgeEffectHidden(true, for: .top)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
        } action: { screenHeight = $0 }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        // Status-bar cap: same page gradient, so scrolling content never shows behind the time / Wi-Fi icons
        .overlay(alignment: .top) {
            DiscoverBlendedBackground(screenHeight: screenHeight)
                .frame(height: topInset)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
        .fullScreenCover(item: $showingDetailFor) { opportunity in
            JobDetailView(
                opportunity: opportunity,
                viewModel: viewModel,
                navViewModel: navViewModel,
                resumeViewModel: resumeViewModel
            )
        }
        .fullScreenCover(isPresented: $showingRecommendedAll) {
            AllOpportunitiesView(
                viewModel: viewModel,
                navViewModel: navViewModel,
                resumeViewModel: resumeViewModel,
                title: "Recommended",
                isExploreMore: false
            )
        }
        .fullScreenCover(isPresented: $showingExploreMoreAll) {
            AllOpportunitiesView(
                viewModel: viewModel,
                navViewModel: navViewModel,
                resumeViewModel: resumeViewModel,
                title: "Explore More",
                isExploreMore: true
            )
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            DiscoverFilterSheet(viewModel: viewModel)
        }
        .onChange(of: navViewModel.targetOpportunity) { _, newOpp in
            if let opp = newOpp {
                showingDetailFor = opp
                navViewModel.targetOpportunity = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userProfileDidUpdate)) { notif in
            if let updated = notif.object as? UserProfile {
                let clean = updated.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty {
                    navViewModel.currentUserFullName = clean
                }
            }
        }
        .environment(\.colorScheme, .light)
    }

    private var headlineTitle: String {
        "EXPLORE\nOPPORTUNITIES"
    }

    private var headlineSubtitle: String {
        switch viewModel.selectedFilterTab {
        case .recommended:
            return "\(viewModel.filteredOpportunities.count) Top Opportunities"
        case .liked:
            return "\(viewModel.filteredOpportunities.count) Liked Opportunities"
        case .applied:
            return "\(viewModel.filteredOpportunities.count) Applied Opportunities"
        }
    }
}

// MARK: - Explore More Pinned Section Header (Sticky at top, seamless background matching Discover artwork)
/// Shown in place of the Recommended cards while the job feed loads — same white card as the
/// empty state, with a spinner instead of the magnifying glass.
struct DiscoverLoadingCard: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .tint(AlineTheme.inkMuted)
                .padding(.top, 30)
            Text("Finding opportunities for you")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
            Text("Fetching the latest openings from company career sites. The first load can take a minute.")
                .font(.system(size: 13))
                .foregroundColor(AlineTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

public struct ExploreMorePinnedHeader: View {
    public let count: Int
    public let screenHeight: CGFloat
    public let onViewMore: () -> Void

    public init(count: Int, screenHeight: CGFloat, onViewMore: @escaping () -> Void) {
        self.count = count
        self.screenHeight = screenHeight
        self.onViewMore = onViewMore
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Explore More")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                Text("Showing \(min(10, count)) of \(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AlineTheme.inkSecondary)
            }

            Spacer()

            if count > 10 {
                Button {
                    onViewMore()
                } label: {
                    HStack(spacing: 4) {
                        Text("View More")
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(AlineTheme.inkPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .alineGlassCapsule(selected: false)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(DiscoverBlendedBackground(screenHeight: screenHeight).ignoresSafeArea(edges: .top))
        .contentShape(Rectangle())
    }
}

// MARK: - All Opportunities View (Normal Vertical Scroll, No Stack, No Overlap)
public struct AllOpportunitiesView: View {
    @State private var searchActive: Bool = false
    @ObservedObject public var viewModel: DiscoverViewModel
    @ObservedObject public var navViewModel: AppNavigationViewModel
    @ObservedObject public var resumeViewModel: ResumeViewModel
    public let title: String
    public let isExploreMore: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var showingDetailFor: Opportunity? = nil
    @State private var highlightedCardId: String? = nil

    public init(
        viewModel: DiscoverViewModel,
        navViewModel: AppNavigationViewModel,
        resumeViewModel: ResumeViewModel,
        title: String = "All Opportunities",
        isExploreMore: Bool = false
    ) {
        self.viewModel = viewModel
        self.navViewModel = navViewModel
        self.resumeViewModel = resumeViewModel
        self.title = title
        self.isExploreMore = isExploreMore
    }

    private var displayOpportunities: [Opportunity] {
        if isExploreMore {
            return viewModel.exploreMoreOpportunities
        } else {
            return viewModel.recommendedOpportunities
        }
    }

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()

            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack(alignment: .center) {
                    // Back button '<' only as requested by user
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .frame(width: 40, height: 40)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .alineGlassCircleButton()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("\(displayOpportunities.count) Total Vacancies")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    .padding(.leading, 8)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 12)

                // Search Bar with Filter Icon Near It (No Word "Filters")
                HStack(spacing: 10) {
                    AlineSearchField("Search roles, companies, or skills", text: $viewModel.searchQuery, isActive: $searchActive)

                    // Filter Icon Button (no word "Filters", right next to search bar)
                    if !searchActive {
                    Button {
                        viewModel.showFilterSheet = true
                    } label: {
                        ZStack {
                            Color.clear.frame(width: 44, height: 44)
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(viewModel.activeFilterCount > 0 ? .white : AlineTheme.inkPrimary)

                            if viewModel.activeFilterCount > 0 {
                                Circle()
                                    .fill(AlineTheme.accentHeart)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 10, y: -10)
                            }
                        }
.alineGlassCircle(selected: viewModel.activeFilterCount > 0)
                    }
                    .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Normal Vertical Scroll: NO stack, NO overlapping cards
                if displayOpportunities.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AlineTheme.inkMuted)
                            .padding(.top, 40)
                        Text("No opportunities found")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("Try adjusting your filters or search keywords.")
                            .font(.system(size: 13))
                            .foregroundColor(AlineTheme.inkSecondary)
                        Button {
                            viewModel.resetFilters()
                        } label: {
                            Text("Reset Filters")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .alineGlassCapsule(selected: true)
                        }
                        .padding(.top, 4)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        if isExploreMore {
                            // Same spacing and insets as Explore More on the Discover page
                            LazyVStack(spacing: AlineSpacing.card) {
                                ForEach(displayOpportunities) { opp in
                                    CompactExploreOpportunityCard(
                                        opportunity: opp,
                                        onOpenDetail: {
                                            showingDetailFor = opp
                                        }
                                    )
                                    .contextMenu {
                                        // "Not relevant": hides the job and steers recommendations away from similar ones
                                        Button("Not relevant", systemImage: "hand.thumbsdown") {
                                            withAnimation(AlineTheme.fastSpring) { viewModel.dismissJob(opp.id) }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .padding(.bottom, 34)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(displayOpportunities) { opp in
                                    let isHighlighted = (opp.id == highlightedCardId)

                                    StackedOpportunityCard(
                                        opportunity: opp,
                                        isExpanded: true,
                                        isHighlighted: isHighlighted,
                                        onSelect: {
                                            withAnimation(AlineTheme.fastSpring) {
                                                highlightedCardId = opp.id
                                            }
                                        },
                                        onOpenDetail: {
                                            showingDetailFor = opp
                                        },
                                        onLike: {
                                            withAnimation(AlineTheme.cardSpring) {
                                                viewModel.toggleLike(for: opp.id)
                                            }
                                        }
                                    )
                                    .contextMenu {
                                        // "Not relevant": hides the job and steers recommendations away from similar ones
                                        Button("Not relevant", systemImage: "hand.thumbsdown") {
                                            withAnimation(AlineTheme.fastSpring) { viewModel.dismissJob(opp.id) }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .padding(.bottom, 34)
                        }
                    }
.scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .fullScreenCover(item: $showingDetailFor) { opportunity in
            JobDetailView(
                opportunity: opportunity,
                viewModel: viewModel,
                navViewModel: navViewModel,
                resumeViewModel: resumeViewModel
            )
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            DiscoverFilterSheet(viewModel: viewModel)
        }
        .onChange(of: navViewModel.targetOpportunity) { _, newOpp in
            if let opp = newOpp {
                showingDetailFor = opp
                navViewModel.targetOpportunity = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userProfileDidUpdate)) { notif in
            if let updated = notif.object as? UserProfile {
                let clean = updated.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty {
                    navViewModel.currentUserFullName = clean
                }
            }
        }
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Flow Layout for Wrapping Multi-Select Chips
public struct FlowLayout: Layout {
    public var spacing: CGFloat = 8

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

// MARK: - Searchable Multi-Select Filter Component (Matching Home Screen UI)
public struct SearchableMultiSelectFilter: View {
    public let title: String
    public let placeholder: String
    public let options: [String]
    @Binding public var selected: Set<String>

    @State private var searchText: String = ""
    @State private var isExpanded: Bool = false
    @FocusState private var isFieldFocused: Bool

    // Exclude generic "All / All Roles / All Skills / All Companies" from the multiselectable pool
    private var cleanOptions: [String] {
        options.filter { !$0.lowercased().hasPrefix("all") }
    }

    private var filteredOptions: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return cleanOptions
        }
        return cleanOptions.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Title and Active Count / Clear Action
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .tracking(0.6)

                Spacer()

                if !selected.isEmpty {
                    Button {
                        withAnimation(AlineTheme.fastSpring) {
                            selected.removeAll()
                        }
                    } label: {
                        Text("Clear (\(selected.count))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Selected Items Tags (Matching Home Screen Pill Aesthetics)
            if !selected.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(Array(selected).sorted(), id: \.self) { item in
                        HStack(spacing: 6) {
                            Text(item)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Button {
                                withAnimation(AlineTheme.fastSpring) {
                                    _ = selected.remove(item)
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AlineTheme.pillDark)
                        )
                    }
                }
                .padding(.vertical, 2)
            }

            // Search Input Row (Matching Home Screen Search Bar Style)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AlineTheme.inkSecondary)

                TextField(
                    "",
                    text: $searchText,
                    prompt: Text(placeholder)
                        .foregroundColor(AlineTheme.inkSecondary)
                )
                .font(.system(size: 14))
                .foregroundColor(AlineTheme.inkPrimary)
                .tint(AlineTheme.inkPrimary)
                .focused($isFieldFocused)
                .submitLabel(.search)
                .onSubmit { isFieldFocused = false }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onTapGesture {
                    withAnimation(AlineTheme.fastSpring) {
                        isExpanded = true
                    }
                }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    withAnimation(AlineTheme.fastSpring) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .alineGlassCapsule(selected: false, interactive: false)
            .environment(\.colorScheme, .light)

            // Dropdown List for Search and Selection
            if isExpanded || !searchText.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom term quick-add option
                    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && !cleanOptions.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                _ = selected.insert(trimmed)
                                searchText = ""
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AlineTheme.pillDark)
                                Text("Add \"\(trimmed)\"")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AlineTheme.canvasBackground.opacity(0.8))
                        }
                        .buttonStyle(.plain)

                        Divider().opacity(0.12)
                    }

                    if filteredOptions.isEmpty && trimmed.isEmpty {
                        Text("No options available")
                            .font(.system(size: 13))
                            .foregroundColor(AlineTheme.inkSecondary)
                            .padding(14)
                    } else {
                        ScrollView(.vertical, showsIndicators: true) {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredOptions, id: \.self) { option in
                                    let isSelected = selected.contains(option)
                                    Button {
                                        withAnimation(AlineTheme.fastSpring) {
                                            if isSelected {
                                                _ = selected.remove(option)
                                            } else {
                                                selected.insert(option)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(option)
                                                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                                                .foregroundColor(AlineTheme.inkPrimary)
                                                .lineLimit(1)
                                            Spacer()
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(AlineTheme.pillDark)
                                            } else {
                                                Image(systemName: "plus.circle")
                                                    .font(.system(size: 15))
                                                    .foregroundColor(AlineTheme.inkMuted)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(isSelected ? AlineTheme.canvasBackground.opacity(0.6) : Color.white)
                                    }
                                    .buttonStyle(.plain)

                                    Divider().opacity(0.08)
                                }
                            }
                        }
.scrollDismissesKeyboard(.interactively)
                        .frame(maxHeight: 160)
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Discover Filter Sheet (Matching Discover Screen UI Design)
public struct DiscoverFilterSheet: View {
    @ObservedObject public var viewModel: DiscoverViewModel
    @Environment(\.dismiss) private var dismiss

    let jobTypes = ["All", "Internship", "Full Time"]
    // Filter options come from the jobs actually in the feed (see DiscoverViewModel.rebuildFilterOptions)
    var roles: [String] { ["All Roles"] + viewModel.roleOptions }
    var locations: [String] { ["All"] + viewModel.locationOptions }
    let workModes = ["All", "Remote", "Hybrid", "On-site"]
    var skillsList: [String] { ["All Skills"] + viewModel.skillOptions }
    var companiesList: [String] { ["All Companies"] + viewModel.companyOptions }
    let gradYearsList: [String] = ["All Years"] + (2015...2030).reversed().map { String($0) }
    let postedTimeOptions = ["All", "Recent", "Newest to Oldest", "Oldest to Newest"]

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Clean Creme Background (no colorful gradient)
            Color(AlineTheme.canvasBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header: Cross Button near Title & Reset All
                HStack(alignment: .center, spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .frame(width: 40, height: 40)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .alineGlassCircleButton()

                    Text("Filters")
                        .font(.system(size: 24, weight: .heavy, design: .default))
                        .foregroundColor(AlineTheme.inkPrimary)

                    Spacer()

                    Button {
                        withAnimation(AlineTheme.fastSpring) {
                            viewModel.resetFilters()
                        }
                    } label: {
                        Text("Reset All")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AlineTheme.inkSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .alineGlassCapsule(selected: false)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                // Scrollable Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // 1. JOB TYPE (Pill Style Matching Discover Feed Segments)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("JOB TYPE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .tracking(0.6)

                            HStack(spacing: 8) {
                                ForEach(jobTypes, id: \.self) { type in
                                    let isSelected = viewModel.filterJobType == type
                                    Button {
                                        withAnimation(AlineTheme.fastSpring) {
                                            viewModel.filterJobType = type
                                        }
                                    } label: {
                                        Text(type)
                                            .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                                            .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 9)
                                            .alineGlassCapsule(selected: isSelected)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                        }

                        // 2. ROLE
                        SearchableMultiSelectFilter(
                            title: "ROLE",
                            placeholder: "Search and add roles...",
                            options: roles,
                            selected: $viewModel.selectedRoles
                        )

                        // 3. LOCATION
                        SearchableMultiSelectFilter(
                            title: "LOCATION",
                            placeholder: "Search and add locations...",
                            options: locations,
                            selected: $viewModel.selectedLocations
                        )

                        // 4. WORK MODE
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WORK MODE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .tracking(0.6)

                            HStack(spacing: 8) {
                                ForEach(workModes, id: \.self) { mode in
                                    let isSelected = viewModel.filterWorkMode == mode
                                    Button {
                                        withAnimation(AlineTheme.fastSpring) {
                                            viewModel.filterWorkMode = mode
                                        }
                                    } label: {
                                        Text(mode)
                                            .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                                            .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                            .padding(.horizontal, 13)
                                            .padding(.vertical, 9)
                                            .alineGlassCapsule(selected: isSelected)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                        }

                        // 5. POSTED TIME / RECENCY
                        VStack(alignment: .leading, spacing: 10) {
                            Text("POSTED TIME")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .tracking(0.6)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(postedTimeOptions, id: \.self) { option in
                                        let isSelected = viewModel.filterPostedTime == option
                                        Button {
                                            withAnimation(AlineTheme.fastSpring) {
                                                viewModel.filterPostedTime = option
                                            }
                                        } label: {
                                            Text(option)
                                                .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                                                .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                                                .padding(.horizontal, 18)
                                                .padding(.vertical, 9)
                                                .alineGlassCapsule(selected: isSelected)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // 6. MORE FILTERS COLLAPSIBLE SECTION
                        Button {
                            withAnimation(AlineTheme.cardSpring) {
                                viewModel.isMoreFiltersExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)

                                Text("More Filters")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)

                                let moreFiltersCount = viewModel.selectedSkills.count + viewModel.selectedCompanies.count + (viewModel.filterGradYear != "All Years" ? 1 : 0)
                                if moreFiltersCount > 0 {
                                    Text("\(moreFiltersCount)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .alineGlassCircle(selected: true)
                                }

                                Spacer()

                                Image(systemName: viewModel.isMoreFiltersExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AlineTheme.inkSecondary)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .alineGlassCapsule(selected: false)
                        }
                        .buttonStyle(.plain)

                        // Expanded Section: SKILLS, COMPANIES, GRADUATION YEAR
                        if viewModel.isMoreFiltersExpanded {
                            VStack(alignment: .leading, spacing: 18) {
                                // SKILLS
                                SearchableMultiSelectFilter(
                                    title: "SKILLS",
                                    placeholder: "Search and add skills...",
                                    options: skillsList,
                                    selected: $viewModel.selectedSkills
                                )

                                // COMPANIES
                                SearchableMultiSelectFilter(
                                    title: "COMPANIES",
                                    placeholder: "Search and add companies...",
                                    options: companiesList,
                                    selected: $viewModel.selectedCompanies
                                )

                                // GRADUATION YEAR (Inline Picker)
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("GRADUATION YEAR")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(AlineTheme.inkSecondary)
                                            .tracking(0.6)

                                        Spacer()

                                        if viewModel.filterGradYear != "All Years" {
                                            Button {
                                                withAnimation(AlineTheme.fastSpring) {
                                                    viewModel.filterGradYear = "All Years"
                                                }
                                            } label: {
                                                Text("Reset")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(AlineTheme.inkSecondary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }

                                    Picker("Graduation Year", selection: $viewModel.filterGradYear) {
                                        ForEach(gradYearsList, id: \.self) { yr in
                                            Text(yr)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(AlineTheme.inkPrimary)
                                                .tag(yr)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 125)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                                    .environment(\.colorScheme, .light)
                                }
                            }
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Spacer(minLength: 100) // Spacing for bottom button
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                }
.scrollDismissesKeyboard(.interactively)

                Spacer(minLength: 0)
            }

            // Bottom Sticky Bar (Matches Discover / Detail Screen Action Style)
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.97, blue: 0.95).opacity(0.0),
                        Color(red: 0.98, green: 0.97, blue: 0.95).opacity(0.85),
                        Color(red: 0.98, green: 0.97, blue: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Text("Apply Filters")
                            .font(.system(size: 16, weight: .bold))
                        if viewModel.activeFilterCount > 0 {
                            Text("(\(viewModel.activeFilterCount))")
                                .font(.system(size: 15, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .alineGlassCapsule(selected: true)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .background(Color(red: 0.98, green: 0.97, blue: 0.95))
            }
            .ignoresSafeArea(.keyboard)
        }
        .presentationDetents([.fraction(0.88), .large])
        .presentationDragIndicator(.visible)
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Previews
#Preview("Discover Feed Canvas") {
    DiscoverFeedView(
        viewModel: DiscoverViewModel(),
        navViewModel: AppNavigationViewModel(),
        resumeViewModel: ResumeViewModel()
    )
}

#Preview("Filters Sheet - Collapsed") {
    DiscoverFilterSheet(viewModel: {
        let vm = DiscoverViewModel()
        vm.isMoreFiltersExpanded = false
        return vm
    }())
}

#Preview("Filters Sheet - Expanded") {
    DiscoverFilterSheet(viewModel: {
        let vm = DiscoverViewModel()
        vm.isMoreFiltersExpanded = true
        return vm
    }())
}

