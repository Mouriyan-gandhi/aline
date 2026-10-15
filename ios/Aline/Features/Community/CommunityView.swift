import SwiftUI

/// Rebuilt from the real Figma "Community discussions · For You" screen (fileKey
/// AiSKBBDDO9rIzyUPHmRm98, node 887:20228, pulled 2026-10-13) — real backend-wired feed,
/// replacing the Phase-2 placeholder stub. Confirms the actual identity model straight from
/// the design data: posts show the system-generated username paired with company
/// ("rc_Falcon - Google"), not a literal "Anonymous" label — matches exactly what
/// community_db.py generates server-side and what the user cannot edit (see
/// Profile · Edit profile's own line: "Your community posts use your anonymous identity, not
/// your profile name").
///
/// Now wired up for real: the filter bottom sheet (category/topics/sort), the For You/
/// Following tabs (Following = discussions from companies you've followed, with a real empty
/// state when you haven't followed any yet), and bookmarking (the header icon opens your
/// actually-saved posts).
///
/// Two things visible in the design are still deliberately out of scope, not silently dropped:
/// the "Interview Questions" top-level tab (a separate, not-yet-built question-bank feature
/// with its own screens/backend — node 132:xxx) and per-user illustrated animal avatars
/// (impractical to source for an unbounded, dynamically-generated username set) — substituted
/// with the same "colored initial tile" compromise already established for company logos in
/// JobCardView, not a redraw of a specific design asset.
struct CommunityView: View {
    @State private var viewModel = CommunityViewModel()
    @State private var isShowingCompose = false
    @State private var isShowingFilters = false
    @State private var isShowingSaved = false
    @State private var isShowingInterviewQuestionsNotice = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    Text("Share a little. Inspire a lot.")
                        .font(AlineFont.sfPro(13, weight: .semibold))
                        .foregroundStyle(AlineColor.textPrimary)
                    topLevelTabs
                    searchAndFilterRow
                    feedTabs
                    feedHeading
                    content
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 90)
            }
            .background(AlineColor.canvas)
            .navigationBarHidden(true)
            .overlay(alignment: .bottomTrailing) {
                composeFAB
            }
            .task { await viewModel.bootstrap() }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $isShowingCompose) {
                CreateDiscussionView(viewModel: viewModel)
            }
            .sheet(isPresented: $isShowingFilters) {
                CommunityFilterSheetView(viewModel: viewModel)
            }
            .sheet(isPresented: $isShowingSaved) {
                SavedPostsView(viewModel: viewModel)
            }
            .alert("Interview Questions", isPresented: $isShowingInterviewQuestionsNotice) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The interview question bank is a separate feature that needs its own backend — not built yet.")
            }
            .navigationDestination(for: Discussion.self) { discussion in
                DiscussionDetailView(discussionID: discussion.id, viewModel: viewModel)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Community")
                .font(AlineFont.sfPro(25, weight: .bold))
                .foregroundStyle(AlineColor.textPrimary)
            Spacer()
            Button { isShowingSaved = true } label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 17))
                    .foregroundStyle(AlineColor.textPrimary)
            }
        }
    }

    /// Matches the Figma's top-level "Discussions / Interview Questions" tab pair — only
    /// Discussions is real.
    private var topLevelTabs: some View {
        HStack(spacing: 10) {
            Text("Discussions")
                .font(AlineFont.sfPro(13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(AlineColor.primary)
                .clipShape(Capsule())
            Button { isShowingInterviewQuestionsNotice = true } label: {
                Text("Interview Questions")
                    .font(AlineFont.sfPro(13, weight: .semibold))
                    .foregroundStyle(AlineColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(AlineColor.paperWhite)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AlineColor.cardBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var searchAndFilterRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AlineColor.textSecondary)
                TextField(
                    "",
                    text: $viewModel.searchText,
                    prompt: Text("Search discussions, companies...").font(AlineFont.sfPro(13)).foregroundStyle(AlineColor.textSecondary)
                )
                .font(AlineFont.sfPro(13))
                .foregroundStyle(AlineColor.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                if !viewModel.searchText.isEmpty {
                    Button { viewModel.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(AlineColor.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(AlineColor.paperWhite)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AlineColor.cardBorder, lineWidth: 1))

            Button { isShowingFilters = true } label: {
                ZStack(alignment: .topTrailing) {
                    Group {
                        if #available(iOS 26.0, *) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(AlineColor.iconMuted)
                                .frame(width: 44, height: 44)
                                .glassEffect(.regular.interactive(), in: Circle())
                        } else {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(AlineColor.iconMuted)
                                .frame(width: 44, height: 44)
                                .background(AlineColor.paperWhite)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AlineColor.cardBorder, lineWidth: 1))
                        }
                    }
                    if viewModel.activeFilterCount > 0 {
                        Circle().fill(AlineColor.primary).frame(width: 8, height: 8)
                    }
                }
            }
        }
    }

    private var feedTabs: some View {
        HStack(spacing: 8) {
            feedTabButton(label: "For You", isSelected: viewModel.feedTab == .forYou) {
                viewModel.feedTab = .forYou
                Task { await viewModel.load() }
            }
            feedTabButton(label: "Following", isSelected: viewModel.feedTab == .following) {
                viewModel.feedTab = .following
                Task { await viewModel.load() }
            }
        }
    }

    private func feedTabButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AlineFont.sfPro(13))
                .foregroundStyle(isSelected ? .white : AlineColor.textPrimary)
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(isSelected ? AlineColor.primary : AlineColor.paperWhite)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : AlineColor.cardBorder.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var feedHeading: some View {
        HStack {
            Text("Community Discussions")
                .font(AlineFont.sfPro(16, weight: .bold))
                .foregroundStyle(AlineColor.textPrimary)
            Spacer()
            Text(viewModel.sort.label)
                .font(AlineFont.sfPro(11))
                .foregroundStyle(AlineColor.primary)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().tint(AlineColor.primary).frame(maxWidth: .infinity).padding(.top, 40)
        case .failed(let message):
            Text(message).font(AlineFont.sfPro(14)).foregroundStyle(.red)
        case .loaded:
            if viewModel.feedTab == .following, viewModel.followedCompanies.isEmpty {
                Text("You're not following any companies yet — follow a company from one of its posts to see their discussions here.")
                    .font(AlineFont.sfPro(14))
                    .foregroundStyle(AlineColor.textSecondary)
            } else if viewModel.filteredDiscussions.isEmpty {
                Text(viewModel.discussions.isEmpty
                     ? "No discussions match these filters yet."
                     : "No discussions match your search.")
                    .font(AlineFont.sfPro(14))
                    .foregroundStyle(AlineColor.textSecondary)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.filteredDiscussions) { discussion in
                        DiscussionCardView(
                            discussion: discussion,
                            isFollowingCompany: discussion.company.map { viewModel.followedCompanies.contains($0) } ?? false,
                            onToggleLike: { Task { await viewModel.toggleLike(discussion) } },
                            onToggleSave: { Task { await viewModel.toggleSave(discussion) } },
                            onToggleFollow: { company in Task { await viewModel.toggleFollow(company: company) } }
                        )
                    }
                }
            }
        }
    }

    /// A genuinely floating control over scrolling content — exactly the case Apple's Liquid
    /// Glass HIG calls out for `glassEffect` (iOS 26+): the functional/control layer, not
    /// content. Falls back to the flat teal fill + shadow on older OS versions.
    private var composeFAB: some View {
        Button { isShowingCompose = true } label: {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(GlassFABStyle())
        .padding(.trailing, 16)
        .padding(.bottom, 100)
    }
}

struct DiscussionCardView: View {
    let discussion: Discussion
    var isFollowingCompany: Bool = false
    let onToggleLike: () -> Void
    var onToggleSave: (() -> Void)?
    var onToggleFollow: ((String) -> Void)?

    var body: some View {
        NavigationLink(value: discussion) {
            VStack(alignment: .leading, spacing: 6) {
                authorRow
                HStack(spacing: 4) {
                    Text(discussion.category)
                        .font(AlineFont.sfPro(10, weight: .semibold))
                        .foregroundStyle(AlineColor.primary)
                    if let company = discussion.company, !company.isEmpty {
                        Text("· \(company)").font(AlineFont.sfPro(10)).foregroundStyle(AlineColor.textPrimary)
                        if let onToggleFollow {
                            Button { onToggleFollow(company) } label: {
                                Text(isFollowingCompany ? "Following" : "+ Follow")
                                    .font(AlineFont.sfPro(9, weight: .semibold))
                                    .foregroundStyle(isFollowingCompany ? AlineColor.textSecondary : AlineColor.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Text(discussion.title)
                    .font(AlineFont.sfPro(13, weight: .bold))
                    .foregroundStyle(AlineColor.textPrimary)
                    .lineLimit(2)
                Text(discussion.body)
                    .font(AlineFont.sfPro(12))
                    .foregroundStyle(AlineColor.textPrimary)
                    .lineLimit(2)
                if !discussion.topics.isEmpty {
                    FlowLayout(spacing: 5) {
                        ForEach(discussion.topics, id: \.self) { topic in
                            Text(topic)
                                .font(AlineFont.sfPro(9, weight: .medium))
                                .foregroundStyle(AlineColor.textPrimary)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(AlineColor.chipUnselected)
                                .clipShape(Capsule())
                        }
                    }
                }
                engagementRow
            }
            .padding(12)
            .background(AlineColor.paperWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var authorRow: some View {
        HStack(spacing: 9) {
            avatar
            VStack(alignment: .leading, spacing: 1) {
                Text(discussion.username)
                    .font(AlineFont.sfPro(12, weight: .bold))
                    .foregroundStyle(AlineColor.textPrimary)
                Text(subtitle)
                    .font(AlineFont.sfPro(10))
                    .foregroundStyle(AlineColor.iconMuted)
            }
            Spacer(minLength: 0)
            Button { onToggleSave?() } label: {
                Image(systemName: discussion.savedByMe ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 14))
                    .foregroundStyle(discussion.savedByMe ? AlineColor.primary : AlineColor.iconMuted)
            }
            .buttonStyle(.plain)
        }
    }

    private var subtitle: String {
        let parts = [discussion.roleTitle, discussion.createdAt.timeAgoDisplay].compactMap { $0 }
        return parts.joined(separator: " · ")
    }

    private var avatar: some View {
        Circle()
            .fill(AlineColor.primary.opacity(0.12))
            .frame(width: 32, height: 32)
            .overlay(
                Text(String(discussion.username.prefix(1)).uppercased())
                    .font(AlineFont.sfPro(13, weight: .bold))
                    .foregroundStyle(AlineColor.primary)
            )
    }

    private var engagementRow: some View {
        HStack(spacing: 18) {
            Button(action: onToggleLike) {
                HStack(spacing: 5) {
                    Image(systemName: discussion.likedByMe ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 13))
                        .foregroundStyle(discussion.likedByMe ? AlineColor.primary : AlineColor.textPrimary)
                    Text("\(discussion.likesCount)")
                        .font(AlineFont.sfPro(10))
                        .foregroundStyle(AlineColor.textPrimary)
                }
            }
            .buttonStyle(.plain)
            HStack(spacing: 5) {
                Image(systemName: "bubble.left").font(.system(size: 13))
                Text("\(discussion.commentsCount)").font(AlineFont.sfPro(10))
            }
            .foregroundStyle(AlineColor.textPrimary)
            Spacer()
        }
    }
}

/// Parses the ISO8601 `created_at` string the backend sends and renders it the same
/// human-relative way as job freshness (see Job+Freshness.swift) — never shows the raw
/// timestamp, degrades to the raw string only as an explicit, visible last resort.
extension String {
    var timeAgoDisplay: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: self) else { return self }
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .short
        return relative.localizedString(for: date, relativeTo: Date())
    }
}
