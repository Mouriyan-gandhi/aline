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
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AlineColor.primary)
            // Decorative shapes — recreated as plain native shapes rather than downloading
            // the Figma file's decorative SVGs, which aren't load-bearing content.
            Circle()
                .fill(AlineColor.badgeHighlight)
                .frame(width: 90, height: 90)
                .offset(x: 260, y: -40)
            Circle()
                .fill(Color.purple.opacity(0.35))
                .frame(width: 110, height: 110)
                .offset(x: 230, y: 60)
            VStack(alignment: .leading, spacing: 10) {
                Text("Discover roles that fit you.")
                    .font(AlineFont.sfPro(26, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 180, alignment: .leading)
                Text("We track top companies\nso you don't have to.")
                    .font(AlineFont.sfPro(12))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(18)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Search + filter

    private var searchAndFilterRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AlineColor.textPrimary)
                Text("Search roles, companies or skills...")
                    .font(AlineFont.inter(12, weight: .medium))
                    .foregroundStyle(AlineColor.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(AlineColor.paperWhite)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AlineColor.cardBorder, lineWidth: 1))

            Button { showFilters = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(AlineColor.iconMuted)
                        .frame(width: 38, height: 38)
                        .background(AlineColor.paperWhite)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AlineColor.cardBorder, lineWidth: 1))
                    if viewModel.activeFilterCount > 0 {
                        Circle().fill(AlineColor.primary).frame(width: 8, height: 8)
                    }
                }
            }
        }
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
                        .background(mode == candidate ? AlineColor.primary : AlineColor.paperWhite)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(mode == candidate ? Color.clear : AlineColor.cardBorder, lineWidth: 1))
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
            Text(message).font(AlineFont.sfPro(14)).foregroundStyle(.red)
        case .loaded:
            if viewModel.filteredJobs.isEmpty {
                Text(viewModel.jobs.isEmpty ? "No matching openings right now — check back soon." : "No jobs match these filters. Try clearing some.")
                    .font(AlineFont.sfPro(14))
                    .foregroundStyle(AlineColor.textSecondary)
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
                Text(applied ? "Nothing marked as applied yet." : "Nothing liked yet — tap the heart on a job to save it here.")
                    .font(AlineFont.sfPro(14))
                    .foregroundStyle(AlineColor.textSecondary)
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
