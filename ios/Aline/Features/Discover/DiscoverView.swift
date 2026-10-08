import SwiftUI

struct DiscoverView: View {
    @State private var viewModel: DiscoverViewModel
    @State private var showNotifications = false
    @State private var showFilters = false

    init(profile: CareerProfile) {
        _viewModel = State(wrappedValue: DiscoverViewModel(profile: profile))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // LazyVStack, not VStack — at full registry scale (1000+ jobs), an eager
                // VStack would construct every JobCardView on first load instead of only
                // what's on/near screen, causing a real stutter/hang rather than a smooth
                // scroll. Found this by actually checking before claiming "you'll see 1000
                // jobs smoothly" — a plain VStack would not have been smooth.
                LazyVStack(alignment: .leading, spacing: 16) {
                    header
                    content
                }
                .padding(16)
            }
            .background(AlineColor.warmCanvas)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showFilters = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundStyle(AlineColor.inkNavy)
                            if viewModel.activeFilterCount > 0 {
                                Circle()
                                    .fill(AlineColor.electricCobalt)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNotifications = true } label: {
                        Image(systemName: "bell")
                            .foregroundStyle(AlineColor.inkNavy)
                    }
                }
            }
            .task { await viewModel.load() }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recommended for you")
                .font(AlineFont.display(28))
                .foregroundStyle(AlineColor.inkNavy)
            Text("Real, India-filtered openings — ranked by your profile.")
                .font(AlineFont.body(14))
                .foregroundStyle(AlineColor.graphite)
            if viewModel.activeFilterCount > 0 {
                Text("\(viewModel.filteredJobs.count) of \(viewModel.jobs.count) match your filters")
                    .font(AlineFont.body(12, weight: .medium))
                    .foregroundStyle(AlineColor.electricCobalt)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().tint(AlineColor.electricCobalt).padding(.top, 40)
        case .failed(let message):
            Text(message)
                .font(AlineFont.body(14))
                .foregroundStyle(.red)
        case .loaded:
            if viewModel.jobs.isEmpty {
                Text("No matching openings right now — check back soon.")
                    .font(AlineFont.body(14))
                    .foregroundStyle(AlineColor.stone)
            } else if viewModel.filteredJobs.isEmpty {
                // Distinct from "no jobs at all" — the feed has jobs, the user's filters
                // just don't match any of them. Different problem, different message.
                Text("No jobs match these filters. Try clearing some.")
                    .font(AlineFont.body(14))
                    .foregroundStyle(AlineColor.stone)
            } else {
                ForEach(viewModel.filteredJobs) { job in
                    NavigationLink(value: job) {
                        JobCardView(job: job, match: viewModel.job(for: job))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
