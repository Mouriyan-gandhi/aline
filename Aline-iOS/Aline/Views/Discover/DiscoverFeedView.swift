import SwiftUI

// MARK: - Discover Feed View (Left Screen in Reference Image)
public struct DiscoverFeedView: View {
    @ObservedObject public var viewModel: DiscoverViewModel
    @ObservedObject public var navViewModel: AppNavigationViewModel
    @ObservedObject public var resumeViewModel: ResumeViewModel
    @State private var showingDetailFor: Opportunity? = nil
    @State private var showingAllOpportunities: Bool = false
    @State private var highlightedCardId: String? = nil

    public var body: some View {
        ZStack(alignment: .bottom) {
            DiscoverBackgroundArtwork()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Top User Bar
                    HStack(alignment: .center) {
                        Text("Aarav Sharma")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Spacer()

                        // Notifications Bell
                        Button {
                            navViewModel.showNotificationsSheet = true
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                                    .frame(width: 44, height: 44)
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
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    // Hero Headline
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EXPLORE\nVACANCIES")
                            .font(.system(size: 32, weight: .black, design: .default))
                            .lineSpacing(2)
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("\(viewModel.filteredOpportunities.count) Top Opportunities")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                    // Interactive Search Bar with Filter Icon Near It (No Word "Filters")
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)

                            TextField("Search 130+ roles, companies, or skills...", text: $viewModel.searchQuery)
                                .font(.system(size: 14))

                            if !viewModel.searchQuery.isEmpty {
                                Button {
                                    viewModel.searchQuery = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )

                        // Filter Icon Button (no word "Filters", right next to search bar)
                        Button {
                            viewModel.showFilterSheet = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(viewModel.activeFilterCount > 0 ? AlineTheme.pillDark : Color.white)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle().stroke(Color.black.opacity(0.10), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)

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
                        }
                        .buttonStyle(.plain)
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
                                        .background(
                                            Capsule()
                                                .fill(isSelected ? AlineTheme.pillDark : Color.white)
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.black.opacity(isSelected ? 0 : 0.08), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Top Recommended Section Header
                    if !viewModel.filteredOpportunities.isEmpty {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("TOP RECOMMENDED")
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundColor(AlineTheme.inkSecondary)
                                    .tracking(0.6)
                                Text("Showing \(min(10, viewModel.filteredOpportunities.count)) of \(viewModel.filteredOpportunities.count)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                    }

                    // Content Area: Empty State OR Normal Horizontal Scroll
                    if viewModel.filteredOpportunities.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AlineTheme.inkMuted)
                                .padding(.top, 30)
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
                                    .background(Capsule().fill(AlineTheme.pillDark))
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
                        // Normal Horizontal Scroll (Only the Top 10 Recommended Cards)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                let topRecommended = Array(viewModel.filteredOpportunities.prefix(10))

                                ForEach(topRecommended) { opp in
                                    let isHighlighted = (opp.id == (highlightedCardId ?? topRecommended.first?.id))

                                    StackedOpportunityCard(
                                        opportunity: opp,
                                        isExpanded: true,
                                        isHighlighted: isHighlighted,
                                        onSelect: {
                                            withAnimation(AlineTheme.cardSpring) {
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
                                    .frame(width: 330, height: 226)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        }

                        // Small "View More" option below the cards
                        if viewModel.filteredOpportunities.count > 10 {
                            HStack {
                                Spacer()
                                Button {
                                    showingAllOpportunities = true
                                } label: {
                                    HStack(spacing: 5) {
                                        Text("View More")
                                            .font(.system(size: 13, weight: .bold))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(Color.black.opacity(0.12), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                        }
                    }

                    Spacer(minLength: 110) // Room for floating tab bar
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
        .fullScreenCover(isPresented: $showingAllOpportunities) {
            AllOpportunitiesView(
                viewModel: viewModel,
                navViewModel: navViewModel,
                resumeViewModel: resumeViewModel
            )
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            DiscoverFilterSheet(viewModel: viewModel)
        }
    }
}

// MARK: - All Opportunities View (Normal Vertical Scroll, No Stack, No Overlap)
public struct AllOpportunitiesView: View {
    @ObservedObject public var viewModel: DiscoverViewModel
    @ObservedObject public var navViewModel: AppNavigationViewModel
    @ObservedObject public var resumeViewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingDetailFor: Opportunity? = nil
    @State private var highlightedCardId: String? = nil

    public init(
        viewModel: DiscoverViewModel,
        navViewModel: AppNavigationViewModel,
        resumeViewModel: ResumeViewModel
    ) {
        self.viewModel = viewModel
        self.navViewModel = navViewModel
        self.resumeViewModel = resumeViewModel
    }

    public var body: some View {
        ZStack {
            // Background strictly purple, yellow, and green
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
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.black.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("All Opportunities")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("\(viewModel.filteredOpportunities.count) Total Vacancies")
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
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AlineTheme.inkSecondary)

                        TextField("Search all roles, companies, or skills...", text: $viewModel.searchQuery)
                            .font(.system(size: 14))

                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AlineTheme.inkSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )

                    // Filter Icon Button (no word "Filters", right next to search bar)
                    Button {
                        viewModel.showFilterSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(viewModel.activeFilterCount > 0 ? AlineTheme.pillDark : Color.white)
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Circle().stroke(Color.black.opacity(0.10), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)

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
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Normal Vertical Scroll: NO stack, NO overlapping cards
                if viewModel.filteredOpportunities.isEmpty {
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
                                .background(Capsule().fill(AlineTheme.pillDark))
                        }
                        .padding(.top, 4)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredOpportunities) { opp in
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
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .padding(.bottom, 34)
                    }
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
                                    selected.remove(item)
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

                TextField(placeholder, text: $searchText)
                    .font(.system(size: 14))
                    .focused($isFieldFocused)
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
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(isExpanded || isFieldFocused ? 0.20 : 0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)

            // Dropdown List for Search and Selection
            if isExpanded || !searchText.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom term quick-add option
                    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && !cleanOptions.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                selected.insert(trimmed)
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
                                                selected.remove(option)
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
    }
}

// MARK: - Discover Filter Sheet (Matching Discover Screen UI Design)
public struct DiscoverFilterSheet: View {
    @ObservedObject public var viewModel: DiscoverViewModel
    @Environment(\.dismiss) private var dismiss

    let jobTypes = ["All", "Internship", "Full Time"]
    let roles = [
        "All Roles",
        "Software Development Engineer",
        "Product Design",
        "Cloud Solutions Architect",
        "Machine Learning",
        "Autonomous Systems",
        "Battery & Firmware",
        "Data Science",
        "UI/UX Prototyper",
        "Security Engineering"
    ]
    let locations = [
        "All",
        "Bengaluru, India",
        "Hyderabad, India",
        "Mumbai, India",
        "Gurugram, India",
        "Noida, India",
        "Pune, India",
        "Remote"
    ]
    let workModes = ["All", "Remote", "Hybrid", "On-site"]
    let skillsList = [
        "All Skills",
        "Python",
        "Swift",
        "SwiftUI",
        "C++",
        "Java",
        "Go",
        "Figma",
        "Machine Learning",
        "React",
        "Kafka",
        "Docker",
        "Kubernetes",
        "SQL"
    ]
    let companiesList = [
        "All Companies",
        "Ola",
        "Flipkart",
        "Apple",
        "Google",
        "Microsoft",
        "Meta",
        "Amazon",
        "Netflix",
        "Spotify",
        "Uber",
        "CRED",
        "Razorpay",
        "Swiggy",
        "Zomato",
        "Stripe",
        "OpenAI",
        "Anthropic",
        "Nvidia",
        "Zerodha",
        "Groww"
    ]
    let gradYearsList = ["All Years", "2027 – 2028", "2026", "2025", "Freshers (0 yrs)"]

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Background matching Discover Screen (Creme base + blurred pastel circles & sparkle stars)
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header: Title & Reset All
                HStack(alignment: .center) {
                    Text("Filters")
                        .font(.system(size: 26, weight: .heavy, design: .default))
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
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
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
                                            .background(
                                                Capsule()
                                                    .fill(isSelected ? Color.black : Color.white)
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.black.opacity(isSelected ? 0 : 0.08), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(isSelected ? 0.12 : 0.03), radius: 3, x: 0, y: 1)
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
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 9)
                                            .background(
                                                Capsule()
                                                    .fill(isSelected ? Color.black : Color.white)
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.black.opacity(isSelected ? 0 : 0.08), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(isSelected ? 0.12 : 0.03), radius: 3, x: 0, y: 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                        }

                        // 5. MORE FILTERS COLLAPSIBLE SECTION
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
                                        .background(Circle().fill(Color.black))
                                }

                                Spacer()

                                Image(systemName: viewModel.isMoreFiltersExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AlineTheme.inkSecondary)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
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

                                    VStack(spacing: 0) {
                                        ForEach(Array(gradYearsList.enumerated()), id: \.element) { index, yr in
                                            let isSelected = viewModel.filterGradYear == yr
                                            Button {
                                                withAnimation(AlineTheme.fastSpring) {
                                                    viewModel.filterGradYear = yr
                                                }
                                            } label: {
                                                HStack {
                                                    Text(yr)
                                                        .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                                                        .foregroundColor(AlineTheme.inkPrimary)
                                                    Spacer()
                                                    if isSelected {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundColor(Color.black)
                                                    }
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(isSelected ? Color(red: 0.94, green: 0.93, blue: 0.90) : Color.white)
                                            }
                                            .buttonStyle(.plain)

                                            if index < gradYearsList.count - 1 {
                                                Divider().opacity(0.08)
                                            }
                                        }
                                    }
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
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

                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)

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
                        .background(
                            Capsule()
                                .fill(Color.black)
                                .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .background(Color(red: 0.98, green: 0.97, blue: 0.95))
            }
            .ignoresSafeArea(.keyboard)
        }
        .presentationDetents([.fraction(0.88), .large])
        .presentationDragIndicator(.visible)
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

