import SwiftUI
import SwiftData

/// Rebuilt from the real Figma Home/opportunity-feed screen (fileKey AiSKBBDDO9rIzyUPHmRm98,
/// node 410:753 — get_design_context pulled 2026-10-13), replacing the earlier placeholder
/// layout. The "Recommended / Liked / Applied" pills aren't a client-side filter of one list —
/// Liked and Applied are genuinely different data sources (SavedJob, not the live feed), per
/// the Figma file's own separate "Liked Opportunities"/"Applied Opportunities" screens.
private enum FeedMode: String, CaseIterable {
    case recommended = "Recommended"
    case liked = "Liked"
    case applied = "Applied"
}

struct DiscoverView: View {
    @State private var viewModel: DiscoverViewModel
    @State private var showNotifications = false
    @State private var showFilters = false
    @State private var mode: FeedMode = .recommended
    @Query(sort: \ResumeDocument.updatedAt, order: .reverse) private var resumeDocuments: [ResumeDocument]
    @Query(sort: \SavedJob.savedAt, order: .reverse) private var savedJobs: [SavedJob]
    @Environment(\.modelContext) private var modelContext

    init(profile: CareerProfile, preferences: UserPreferences) {
        _viewModel = State(wrappedValue: DiscoverViewModel(profile: profile, preferences: preferences))
    }

    private var defaultResumeProfile: ResumeProfile? {
        (resumeDocuments.first { $0.isDefault } ?? resumeDocuments.first)?.profile
    }

    /// Top 5 by match score read as "Recommended"; the rest as "Explore more" — the app has
    /// no separate recommendation signal from the match score itself, so this is an honest
    /// split of one ranked list, not a second algorithm pretending to be one.
    private var recommendedSlice: ArraySlice<Job> { viewModel.filteredJobs.prefix(5) }
    private var exploreMoreSlice: ArraySlice<Job> { viewModel.filteredJobs.dropFirst(5) }

    private func likedSavedJob(for job: Job) -> SavedJob? {
        savedJobs.first { $0.jobID == job.id }
    }

    private func toggleLike(_ job: Job) {
        if let existing = likedSavedJob(for: job) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(SavedJob(job: job))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    heroCard
                    searchAndFilterRow
                    modePills
                    content
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90) // clears the floating tab bar
            }
            .background(AlineColor.canvas)
            .navigationBarHidden(true)
            .task {
                viewModel.resumeProfile = defaultResumeProfile
                await viewModel.load()
            }
            .onChange(of: resumeDocuments) {
                viewModel.resumeProfile = defaultResumeProfile
            }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $showFilters) {
                FilterSheetView(viewModel: viewModel)
            }
            .alert("Notifications", isPresented: $showNotifications) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("High-signal job alerts land here — wired up to APNs in Phase 1.")
            }
            .navigationDestination(for: Job.self) { job in
                JobDetailView(job: job, match: viewModel.job(for: job))
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hey there!")
                    .font(AlineFont.sfPro(25, weight: .semibold))
                    .foregroundStyle(AlineColor.textPrimary)
                Text("New opportunities. Closer to your goals.")
                    .font(AlineFont.sfPro(13, weight: .semibold))
                    .foregroundStyle(AlineColor.textPrimary)
            }
            Spacer()
            Button { showNotifications = true } label: {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundStyle(AlineColor.textPrimary)
                    .padding(8)
            }
        }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        ZStack(alignment: .topLeading) {
            // The brand's own glossy blue-to-lavender gradient, echoing the logo treatment,
            // in place of a flat fill + plain decorative circles.
            BrandMeshHero()
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AlineColor.spark)
                    // No fixed width here — at larger Dynamic Type sizes this wrapped to
                    // multiple lines fine on its own; the old fixed `width: 200` frame instead
                    // clipped it down to "Dis…" at the largest accessibility size (verified
                    // live), which is a worse failure than just taking more vertical space.
                    Text("Discover roles that fit you.")
                        .font(AlineFont.sfPro(26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("We track top companies\nso you don't have to.")
                    .font(AlineFont.sfPro(12))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(18)
        }
        // minHeight, not a fixed height — lets the card grow at larger Dynamic Type sizes
        // instead of clipping wrapped text.
        .frame(minHeight: 190)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Search + filter

    private var searchAndFilterRow: some View {
        HStack(spacing: 10) {
            searchField
            filterButton
        }
    }

    @ViewBuilder
    private var searchField: some View {
        let label = HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AlineColor.textPrimary)
            Text("Search roles, companies or skills...")
                .font(AlineFont.inter(12, weight: .medium))
                .foregroundStyle(AlineColor.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 38)

        // Liquid Glass belongs on functional chrome like a search field (per HIG) — but only
        // reads as glass over a genuinely floating shape, so it still gets its own capsule
        // rather than sitting flush against the row.
        if #available(iOS 26.0, *) {
            label.glassEffect(.regular, in: .capsule)
        } else {
            label
                .background(AlineColor.paperWhite)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AlineColor.cardBorder, lineWidth: 1))
        }
    }

    @ViewBuilder
    private var filterButton: some View {
        Button { showFilters = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(AlineColor.iconMuted)
                    .frame(width: 38, height: 38)
                if viewModel.activeFilterCount > 0 {
                    Circle().fill(AlineColor.primary).frame(width: 8, height: 8)
                }
            }
        }
        .buttonStyle(.plain)
        .modifier(GlassCircleBackground())
    }

    // MARK: - Mode pills

    private var modePills: some View {
        HStack(spacing: 8) {
            ForEach(FeedMode.allCases, id: \.self) { candidate in
                Button {
                    mode = candidate
                } label: {
                    Text(candidate.rawValue)
                        .font(AlineFont.sfPro(12, weight: .semibold))
                        .foregroundStyle(mode == candidate ? .white : AlineColor.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .modifier(ModePillBackground(isSelected: mode == candidate))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .recommended: recommendedContent
        case .liked: savedContent(applied: false)
        case .applied: savedContent(applied: true)
        }
    }

    @ViewBuilder
    private var recommendedContent: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().tint(AlineColor.primary).frame(maxWidth: .infinity).padding(.top, 40)
        case .failed(let message):
            BrandEmptyState(icon: "exclamationmark.triangle", title: "Couldn't load opportunities", message: message)
        case .loaded:
            if viewModel.filteredJobs.isEmpty {
                BrandEmptyState(
                    title: viewModel.jobs.isEmpty ? "No matching openings right now" : "No jobs match these filters",
                    message: viewModel.jobs.isEmpty ? "Check back soon — new roles come in throughout the day." : "Try clearing some filters."
                )
            } else {
                sectionHeader(title: "Recommended opportunities", trailing: "\(viewModel.filteredJobs.count) Opportunities")
                cardList(Array(recommendedSlice))

                if !exploreMoreSlice.isEmpty {
                    sectionHeader(title: "Explore more opportunities", trailing: nil)
                    cardList(Array(exploreMoreSlice))
                }
            }
        }
    }

    private func savedContent(applied: Bool) -> some View {
        let entries = savedJobs.filter { $0.isApplied == applied }
        let jobs = entries.compactMap { saved in viewModel.jobs.first { $0.id == saved.jobID } }
        return Group {
            if jobs.isEmpty {
                BrandEmptyState(
                    icon: applied ? "checkmark.circle" : "heart",
                    title: applied ? "Nothing marked as applied yet" : "Nothing liked yet",
                    message: applied ? nil : "Tap the heart on a job to save it here."
                )
            } else {
                sectionHeader(title: applied ? "Applied opportunities" : "Liked opportunities", trailing: "\(jobs.count)")
                cardList(jobs)
            }
        }
    }

    private func sectionHeader(title: String, trailing: String?) -> some View {
        HStack {
            Text(title)
                .font(AlineFont.sfPro(16, weight: .bold))
                .foregroundStyle(AlineColor.textPrimary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(AlineFont.inter(13, weight: .semibold))
                    .foregroundStyle(AlineColor.textPrimary)
            }
        }
    }

    private func cardList(_ jobs: [Job]) -> some View {
        LazyVStack(spacing: 10) {
            ForEach(jobs) { job in
                NavigationLink(value: job) {
                    JobCardView(
                        job: job,
                        match: viewModel.job(for: job),
                        isLiked: likedSavedJob(for: job) != nil,
                        onToggleLike: { toggleLike(job) }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
