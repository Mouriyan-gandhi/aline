import SwiftUI

struct DiscoverView: View {
    @State private var viewModel: DiscoverViewModel
    @State private var showNotifications = false

    init(profile: CareerProfile) {
        _viewModel = State(wrappedValue: DiscoverViewModel(profile: profile))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    content
                }
                .padding(16)
            }
            .background(AlineColor.warmCanvas)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNotifications = true } label: {
                        Image(systemName: "bell")
                            .foregroundStyle(AlineColor.inkNavy)
                    }
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
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
            } else {
                ForEach(viewModel.jobs) { job in
                    NavigationLink(value: job) {
                        JobCardView(job: job, match: viewModel.job(for: job))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
