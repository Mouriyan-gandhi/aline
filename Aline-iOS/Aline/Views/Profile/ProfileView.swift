import SwiftUI
import UniformTypeIdentifiers
import PDFKit
import QuickLook

// MARK: - Navigation Routes (Profile → Achievement Gallery → Folder → File)
public enum ProfileRoute: Hashable {
    case gallery
    case folder(AchievementCategory)
    case achievement(String)
    case communityActivity
    case myPosts
    case myLikes
    case myComments
    case experiences
    case projects
}

// MARK: - Profile & Career Hub View (Sections 10, 11, 12 of Product Guide)
public struct ProfileView: View {
    @ObservedObject public var viewModel: ProfileViewModel
    public var resumes: [ResumeDocument] = []
    public var navViewModel: AppNavigationViewModel? = nil
    /// The community feed, so the profile can list the user's own posts
    @ObservedObject public var communityViewModel: CommunityViewModel = CommunityViewModel()
    @State private var path: [ProfileRoute] = []
    @State private var showingEditProfileSheet: Bool = false
    @State private var showingPreferencesSheet: Bool = false
    @State private var showingHelpSheet: Bool = false
    @State private var showingSignOutAlert: Bool = false
    @State private var showingDeleteAccountSheet: Bool = false
    @State private var editingExperience: UserExperience?
    @State private var editingProject: UserProject?
    @State private var isExperienceExpanded: Bool = true
    @State private var isProjectsExpanded: Bool = true

    public var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                DiscoverBackgroundArtwork()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AlineSpacing.section) {
                        topBar
                        headerCard

                        experienceSection
                        projectsSection

                        VStack(spacing: 12) {
                            ProfileMenuRow(
                                icon: "slider.horizontal.3",
                                iconColor: Color.black.opacity(0.06),
                                title: "Career Preferences",
                                subtitle: "\(viewModel.preferences.preferredRoles.count) Roles • \(preferredLocationsSummary)"
                            ) {
                                showingPreferencesSheet = true
                            }

                            ProfileMenuRow(
                                icon: "trophy.fill",
                                iconColor: Color.black.opacity(0.06),
                                title: "Achievement Gallery",
                                subtitle: "\(viewModel.achievements.count) saved credentials & certificates"
                            ) {
                                path.append(.gallery)
                            }

                            ProfileMenuRow(
                                icon: "text.bubble.fill",
                                iconColor: Color.black.opacity(0.06),
                                title: "Community Activity",
                                subtitle: "Your posts, likes and comments"
                            ) {
                                path.append(.communityActivity)
                            }

                            ProfileMenuRow(
                                icon: "bell.badge.fill",
                                iconColor: Color.black.opacity(0.06),
                                title: "Opportunity Alerts",
                                subtitle: viewModel.preferences.alertsEnabled ? "Enabled (Push Active)" : "Disabled",
                                toggle: $viewModel.preferences.alertsEnabled
                            ) {}
                            .onChange(of: viewModel.preferences.alertsEnabled) { oldValue, enabled in
                                // Saves the toggle and asks for notification permission (see JobAlerts)
                                if oldValue != enabled { viewModel.setJobAlerts(enabled) }
                            }

                            ProfileMenuRow(
                                icon: "questionmark.circle.fill",
                                iconColor: Color.black.opacity(0.06),
                                title: "Help & Feedback",
                                subtitle: "Resume limits, anonymous identity, support"
                            ) {
                                showingHelpSheet = true
                            }

                            if navViewModel != nil {
                                ProfileMenuRow(
                                    icon: "rectangle.portrait.and.arrow.right",
                                    iconColor: Color.black.opacity(0.06),
                                    title: "Sign Out",
                                    subtitle: "Sign out of your Aline account"
                                ) {
                                    showingSignOutAlert = true
                                }

                                ProfileMenuRow(
                                    icon: "trash.fill",
                                    iconColor: Color.red.opacity(0.10),
                                    title: "Delete Account",
                                    subtitle: "Permanently delete account and all data"
                                ) {
                                    showingDeleteAccountSheet = true
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 120)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    withAnimation {
                        navViewModel?.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .gallery:
                    AchievementGalleryView(viewModel: viewModel)
                case .folder(let category):
                    AchievementFolderView(viewModel: viewModel, category: category)
                case .achievement(let id):
                    AchievementDetailView(viewModel: viewModel, achievementId: id)
                case .communityActivity:
                    CommunityActivityView(communityViewModel: communityViewModel)
                case .myPosts:
                    MyPostsView(communityViewModel: communityViewModel)
                case .myLikes:
                    MyLikesView(communityViewModel: communityViewModel)
                case .myComments:
                    MyCommentsView(communityViewModel: communityViewModel)
                case .experiences:
                    ProfileEntriesView(viewModel: viewModel, kind: .experience)
                case .projects:
                    ProfileEntriesView(viewModel: viewModel, kind: .project)
                }
            }
        }
        .sheet(isPresented: $showingEditProfileSheet) {
            EditProfileSheet(viewModel: viewModel, resumes: resumes, navViewModel: navViewModel)
        }
        .sheet(isPresented: $showingPreferencesSheet) {
            CareerPreferencesSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingHelpSheet) {
            HelpAndFeedbackSheet()
        }
        .sheet(isPresented: $showingDeleteAccountSheet) {
            if let nav = navViewModel {
                DeleteAccountConfirmationSheet(navViewModel: nav)
            }
        }
        .sheet(item: $editingExperience) { exp in
            ExperienceEditorSheet(experience: exp) { viewModel.upsertExperience($0) }
        }
        .sheet(item: $editingProject) { proj in
            ProjectEditorSheet(project: proj) { viewModel.upsertProject($0) }
        }
    }

    private func newExperience() -> UserExperience { .blank() }

    private func newProject() -> UserProject { .blank() }

    private var preferredLocationsSummary: String {
        viewModel.preferences.isOpenToAnyLocation
            ? "Any location"
            : viewModel.preferences.preferredLocations.joined(separator: ", ")
    }

    // MARK: Top bar
    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PROFILE")
                    .font(.system(size: 32, weight: .black, design: .default))
                    .lineSpacing(2)
                    .foregroundColor(AlineTheme.inkPrimary)
                Text("Career preferences & credentials")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AlineTheme.inkSecondary)
            }
            Spacer()
            ProfileCircleButton(icon: "pencil") {
                showingEditProfileSheet = true
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    // MARK: Header card
    private var headerCard: some View {
        let profile = viewModel.profile
        let links = linkItems(for: profile)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                // Same avatar the user posts and comments with in Community
                Image(DiscussionPost.currentUserAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Text("@\(profile.username)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            if !profile.bio.isEmpty {
                Text(profile.bio)
                    .font(.system(size: 14))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineSpacing(2)
                    .lineLimit(2)
            }

            if !profile.skills.isEmpty {
                skillsRow(profile.skills)
            }

            HStack(spacing: 8) {
                ForEach(links, id: \.title) { link in
                    if let url = link.url {
                        Link(destination: url) { linkButton(icon: link.icon, title: link.title) }
                    } else {
                        linkButton(icon: link.icon, title: link.title)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .profileCardBackground(radius: 28)
        // Tapping the card opens the same Edit Profile sheet as the pencil (link buttons keep their own taps)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture { showingEditProfileSheet = true }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Edit profile")
        .padding(.horizontal, 24)
    }

    /// One line of skill chips: shows as many as fit, ending with a "+N" chip for the rest.
    private func skillsRow(_ skills: [String]) -> some View {
        ViewThatFits(in: .horizontal) {
            ForEach(Array(stride(from: skills.count, through: 0, by: -1)), id: \.self) { visibleCount in
                HStack(spacing: 6) {
                    ForEach(Array(skills.prefix(visibleCount)), id: \.self) { skill in
                        skillChip(skill)
                    }
                    if visibleCount < skills.count {
                        skillChip("+\(skills.count - visibleCount)", bold: true)
                    }
                }
                .fixedSize()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func skillChip(_ text: String, bold: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 12, weight: bold ? .bold : .semibold))
            .foregroundColor(bold ? AlineTheme.inkSecondary : AlineTheme.inkPrimary)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.06)))
    }

    /// LinkedIn and GitHub show their own marks in black and white; anything else keeps its symbol
    private func linkButton(icon: String, title: String) -> some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.06))
            switch title {
            case "LinkedIn":
                Text("in")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(AlineTheme.inkPrimary))
            case "GitHub":
                // The asset is a black tile with a white ring around a black cat: crop to the ring and invert,
                // which gives GitHub's real mark (black circle, white cat)
                Image("company_github")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .scaleEffect(1.42)
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                    .colorInvert()
            default:
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
            }
        }
        .frame(width: 34, height: 34)
        .accessibilityLabel(title)
    }

    private func linkItems(for profile: UserProfile) -> [(icon: String, title: String, url: URL?)] {
        var items: [(String, String, URL?)] = []
        if !profile.linkedInURL.isEmpty { items.append(("person.crop.square", "LinkedIn", Self.url(from: profile.linkedInURL))) }
        if !profile.githubURL.isEmpty { items.append(("chevron.left.forwardslash.chevron.right", "GitHub", Self.url(from: profile.githubURL))) }
        if !profile.portfolioURL.isEmpty { items.append(("globe", "Portfolio", Self.url(from: profile.portfolioURL))) }
        return items
    }

    fileprivate static func url(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed.contains("://") ? trimmed : "https://\(trimmed)")
    }

    // MARK: Experience & Projects
    /// Only the latest entry shows here; the title chevron opens the full list.
    private var experienceSection: some View {
        let latest = viewModel.profile.experiences.last
        return VStack(alignment: .leading, spacing: 12) {
            ProfileCollapsibleHeader(
                title: "Experience",
                isExpanded: $isExperienceExpanded,
                onOpen: { path.append(.experiences) },
                onAdd: { editingExperience = newExperience() }
            )
            if isExperienceExpanded {
                if let exp = latest {
                    ProfileEntryCard(experience: exp) { editingExperience = exp }
                } else {
                    ProfileEmptyPrompt(icon: "briefcase.fill", text: "Add your internships and work experience") {
                        editingExperience = newExperience()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var projectsSection: some View {
        let latest = viewModel.profile.projects.last
        return VStack(alignment: .leading, spacing: 12) {
            ProfileCollapsibleHeader(
                title: "Projects",
                isExpanded: $isProjectsExpanded,
                onOpen: { path.append(.projects) },
                onAdd: { editingProject = newProject() }
            )
            if isProjectsExpanded {
                if let proj = latest {
                    ProfileEntryCard(project: proj) { editingProject = proj }
                } else {
                    ProfileEmptyPrompt(icon: "hammer.fill", text: "Showcase the projects you've built") {
                        editingProject = newProject()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - My Posts (everything the user has posted in Community)
struct MyPostsView: View {
    @ObservedObject var communityViewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPost: DiscussionPost?

    private var myPosts: [DiscussionPost] {
        communityViewModel.posts.filter(\.isByCurrentUser)
    }

    var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AlineSpacing.section) {
                    HStack {
                        ProfileCircleButton(icon: "chevron.left") { dismiss() }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Posts")
                            .font(.alineHero)
                            .textCase(.uppercase)
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text(myPosts.count == 1 ? "1 post in Community" : "\(myPosts.count) posts in Community")
                            .font(.alineCallout)
                            .foregroundColor(AlineTheme.inkSecondary)
                    }

                    if myPosts.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(AlineTheme.inkMuted)
                            Text("No posts yet")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("Posts you share in Community will show up here.")
                                .font(.system(size: 13))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: AlineSpacing.card) {
                            ForEach(myPosts) { post in
                                CommunityDiscussionCard(
                                    post: post,
                                    onTap: { selectedPost = post },
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
                                    onTapComment: { selectedPost = post },
                                    onShare: { communityViewModel.incrementShare(for: post.id) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedPost) { post in
            DiscussionDetailView(post: post, viewModel: communityViewModel)
        }
    }
}

// MARK: - Community Activity (list of the user's posts, likes and comments)
struct CommunityActivityView: View {
    @ObservedObject var communityViewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let activity = CommunityActivity(posts: communityViewModel.posts)
        ZStack {
            DiscoverBackgroundArtwork()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AlineSpacing.section) {
                    HStack {
                        ProfileCircleButton(icon: "chevron.left") { dismiss() }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Community Activity")
                            .font(.alineHero)
                            .textCase(.uppercase)
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("Everything you've shared and interacted with")
                            .font(.alineCallout)
                            .foregroundColor(AlineTheme.inkSecondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("How you use Community")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.inkSecondary)
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            NavigationLink(value: ProfileRoute.myPosts) {
                                ActivityListRow(icon: "square.and.pencil", title: "My Posts", count: activity.myPosts.count)
                            }
                            Divider().padding(.leading, 64)
                            NavigationLink(value: ProfileRoute.myLikes) {
                                ActivityListRow(icon: "heart", title: "My Likes", count: activity.likedPosts.count + activity.likedComments.count)
                            }
                            Divider().padding(.leading, 64)
                            NavigationLink(value: ProfileRoute.myComments) {
                                ActivityListRow(icon: "bubble.left.and.bubble.right", title: "My Comments", count: activity.myComments.count)
                            }
                        }
                        .buttonStyle(.plain)
                        .profileCardBackground(radius: 22)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// One row in the Community Activity list: icon, title, count and chevron.
struct ActivityListRow: View {
    let icon: String
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AlineTheme.inkPrimary)
                .frame(width: 34)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AlineTheme.inkPrimary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AlineTheme.inkSecondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AlineTheme.inkMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

/// The user's footprint in the community feed, derived from the posts.
struct CommunityActivity {
    struct CommentEntry: Identifiable {
        let comment: DiscussionComment
        let post: DiscussionPost
        /// Who the user replied to, nil for a top-level comment
        let replyingTo: String?
        var id: String { comment.id }
    }

    let myPosts: [DiscussionPost]
    let likedPosts: [DiscussionPost]
    let likedComments: [CommentEntry]
    let myComments: [CommentEntry]

    init(posts: [DiscussionPost]) {
        var liked: [CommentEntry] = []
        var mine: [CommentEntry] = []
        for post in posts {
            for comment in post.comments {
                if comment.isLiked { liked.append(CommentEntry(comment: comment, post: post, replyingTo: nil)) }
                if comment.authorName == DiscussionPost.currentUserName {
                    mine.append(CommentEntry(comment: comment, post: post, replyingTo: nil))
                }
                for reply in comment.replies {
                    if reply.isLiked { liked.append(CommentEntry(comment: reply, post: post, replyingTo: comment.authorName)) }
                    if reply.authorName == DiscussionPost.currentUserName {
                        mine.append(CommentEntry(comment: reply, post: post, replyingTo: comment.authorName))
                    }
                }
            }
        }
        myPosts = posts.filter(\.isByCurrentUser)
        likedPosts = posts.filter(\.isLiked)
        likedComments = liked
        myComments = mine
    }
}

/// Shared page chrome for the activity sub-screens: back button, hero title, subtitle.
struct ActivityPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AlineSpacing.section) {
                    HStack {
                        ProfileCircleButton(icon: "chevron.left") { dismiss() }
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.alineHero)
                            .textCase(.uppercase)
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text(subtitle)
                            .font(.alineCallout)
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    content()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct ActivityEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(AlineTheme.inkMuted)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(AlineTheme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

/// A comment or reply, with the post it belongs to. Tapping opens that post.
struct ActivityCommentCard: View {
    let entry: CommunityActivity.CommentEntry
    /// "You commented" style label when listing the user's own comments
    var showsOwnAction: Bool = false
    let onTap: () -> Void

    private var actionLine: String {
        if showsOwnAction {
            if let name = entry.replyingTo { return "You replied to \(name)" }
            return "You commented"
        }
        let kind = entry.replyingTo == nil ? "comment" : "reply"
        return "You liked \(entry.comment.authorName)'s \(kind)"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(entry.comment.resolvedAvatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text(actionLine)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(1)
                        Text(entry.comment.timeAgo)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        Image(systemName: entry.comment.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(entry.comment.isLiked ? AlineTheme.accentHeart : AlineTheme.inkSecondary)
                        Text("\(entry.comment.likesCount)")
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    .font(.system(size: 12, weight: .semibold))
                }

                Text(entry.comment.text)
                    .font(.system(size: 14))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 11, weight: .bold))
                    Text(entry.post.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundColor(AlineTheme.inkSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.05)))
            }
            .padding(16)
            .profileCardBackground(radius: 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - My Likes (posts and comments the user liked)
struct MyLikesView: View {
    @ObservedObject var communityViewModel: CommunityViewModel
    @State private var selectedPost: DiscussionPost?

    var body: some View {
        let activity = CommunityActivity(posts: communityViewModel.posts)
        let total = activity.likedPosts.count + activity.likedComments.count
        ActivityPage(title: "My Likes", subtitle: total == 1 ? "1 like" : "\(total) likes") {
            if total == 0 {
                ActivityEmptyState(icon: "heart", title: "No likes yet", message: "Posts and comments you like will show up here.")
            }
            if !activity.likedPosts.isEmpty {
                VStack(alignment: .leading, spacing: AlineSpacing.card) {
                    Text("Liked posts")
                        .font(.alineTitleMedium)
                        .foregroundColor(AlineTheme.inkPrimary)
                    ForEach(activity.likedPosts) { post in
                        CommunityDiscussionCard(
                            post: post,
                            onTap: { selectedPost = post },
                            onToggleLike: {
                                withAnimation(AlineTheme.fastSpring) { communityViewModel.toggleLike(for: post.id) }
                            },
                            onToggleSave: {
                                withAnimation(AlineTheme.fastSpring) { communityViewModel.toggleSave(for: post.id) }
                            },
                            onTapComment: { selectedPost = post },
                            onShare: { communityViewModel.incrementShare(for: post.id) }
                        )
                    }
                }
            }
            if !activity.likedComments.isEmpty {
                VStack(alignment: .leading, spacing: AlineSpacing.card) {
                    Text("Liked comments")
                        .font(.alineTitleMedium)
                        .foregroundColor(AlineTheme.inkPrimary)
                    ForEach(activity.likedComments) { entry in
                        ActivityCommentCard(entry: entry) { selectedPost = entry.post }
                    }
                }
            }
        }
        .navigationDestination(item: $selectedPost) { post in
            DiscussionDetailView(post: post, viewModel: communityViewModel)
        }
    }
}

// MARK: - My Comments (the user's comments and replies)
struct MyCommentsView: View {
    @ObservedObject var communityViewModel: CommunityViewModel
    @State private var selectedPost: DiscussionPost?

    var body: some View {
        let comments = CommunityActivity(posts: communityViewModel.posts).myComments
        ActivityPage(
            title: "My Comments",
            subtitle: comments.count == 1 ? "1 comment or reply" : "\(comments.count) comments and replies"
        ) {
            if comments.isEmpty {
                ActivityEmptyState(icon: "bubble.left.and.bubble.right", title: "No comments yet", message: "Your comments and replies in Community will show up here.")
            } else {
                VStack(spacing: AlineSpacing.card) {
                    ForEach(comments) { entry in
                        ActivityCommentCard(entry: entry, showsOwnAction: true) { selectedPost = entry.post }
                    }
                }
            }
        }
        .navigationDestination(item: $selectedPost) { post in
            DiscussionDetailView(post: post, viewModel: communityViewModel)
        }
        // Comments live inside each thread, which the feed doesn't carry
        .task { await communityViewModel.loadAllComments() }
    }
}

// MARK: - Experience & Projects (collapsible header, full list, newest first)
extension UserExperience {
    static func blank() -> UserExperience {
        UserExperience(id: UUID().uuidString, title: "", company: "", location: "", period: "", bullets: [""])
    }
}

extension UserProject {
    static func blank() -> UserProject {
        UserProject(id: UUID().uuidString, title: "", period: "", techStack: "", bullets: [""])
    }
}

extension ProfileViewModel {
    /// Edits an existing experience in place, or adds a new one as the latest entry.
    func upsertExperience(_ saved: UserExperience) {
        var updated = profile
        if let index = updated.experiences.firstIndex(where: { $0.id == saved.id }) {
            updated.experiences[index] = saved
        } else {
            updated.experiences.append(saved)
        }
        updateProfile(updated)
    }

    func upsertProject(_ saved: UserProject) {
        var updated = profile
        if let index = updated.projects.firstIndex(where: { $0.id == saved.id }) {
            updated.projects[index] = saved
        } else {
            updated.projects.append(saved)
        }
        updateProfile(updated)
    }
}

extension ProfileEntryCard {
    init(experience exp: UserExperience, onTap: @escaping () -> Void) {
        self.init(
            onTap: onTap,
            icon: "briefcase.fill",
            title: exp.title,
            subtitle: [exp.company, exp.location].filter { !$0.isEmpty }.joined(separator: " • "),
            period: exp.period,
            bullets: exp.bullets
        )
    }

    init(project proj: UserProject, onTap: @escaping () -> Void) {
        self.init(
            onTap: onTap,
            icon: "hammer.fill",
            title: proj.title,
            subtitle: proj.techStack,
            period: proj.period,
            bullets: proj.bullets
        )
    }
}

/// "Experience ›" title that opens the full list, plus Add and a show/hide chevron.
struct ProfileCollapsibleHeader: View {
    let title: String
    @Binding var isExpanded: Bool
    let onOpen: () -> Void
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onOpen) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.alineTitleMedium)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
                .foregroundColor(AlineTheme.inkPrimary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows all \(title.lowercased())")

            Spacer()

            Button(action: onAdd) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text("Add")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .alineGlassCapsule(selected: true)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(AlineTheme.fastSpring) { isExpanded.toggle() }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .alineGlassCircleButton()
            .accessibilityLabel(isExpanded ? "Hide \(title)" : "Show \(title)")
        }
    }
}

/// Every experience or project, newest first. Tap a card to edit it; + adds a new one.
struct ProfileEntriesView: View {
    enum Kind { case experience, project }

    @ObservedObject var viewModel: ProfileViewModel
    let kind: Kind
    @Environment(\.dismiss) private var dismiss
    @State private var editingExperience: UserExperience?
    @State private var editingProject: UserProject?

    private var count: Int {
        kind == .experience ? viewModel.profile.experiences.count : viewModel.profile.projects.count
    }

    var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AlineSpacing.section) {
                    HStack {
                        ProfileCircleButton(icon: "chevron.left") { dismiss() }
                        Spacer()
                        ProfileCircleButton(icon: "plus") {
                            if kind == .experience { editingExperience = .blank() } else { editingProject = .blank() }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(kind == .experience ? "Experience" : "Projects")
                            .font(.alineHero)
                            .textCase(.uppercase)
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text(subtitle)
                            .font(.alineCallout)
                            .foregroundColor(AlineTheme.inkSecondary)
                    }

                    VStack(spacing: AlineSpacing.card) {
                        switch kind {
                        case .experience:
                            if viewModel.profile.experiences.isEmpty {
                                ProfileEmptyPrompt(icon: "briefcase.fill", text: "Add your internships and work experience") {
                                    editingExperience = .blank()
                                }
                            }
                            ForEach(viewModel.profile.experiences.reversed()) { exp in
                                ProfileEntryCard(experience: exp) { editingExperience = exp }
                            }
                        case .project:
                            if viewModel.profile.projects.isEmpty {
                                ProfileEmptyPrompt(icon: "hammer.fill", text: "Showcase the projects you've built") {
                                    editingProject = .blank()
                                }
                            }
                            ForEach(viewModel.profile.projects.reversed()) { proj in
                                ProfileEntryCard(project: proj) { editingProject = proj }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editingExperience) { exp in
            ExperienceEditorSheet(experience: exp) { viewModel.upsertExperience($0) }
        }
        .sheet(item: $editingProject) { proj in
            ProjectEditorSheet(project: proj) { viewModel.upsertProject($0) }
        }
    }

    private var subtitle: String {
        let noun = kind == .experience ? (count == 1 ? "role" : "roles") : (count == 1 ? "project" : "projects")
        return count == 0 ? "Nothing added yet" : "\(count) \(noun)"
    }
}

// MARK: - Shared Profile Building Blocks
fileprivate extension View {
    func profileCardBackground(radius: CGFloat = 22) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

/// White circular icon button used for back / add / edit actions (matches the job detail header).
public struct ProfileCircleButton: View {
    public let icon: String
    public let action: () -> Void

    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
                .frame(width: 40, height: 40)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .alineGlassCircleButton()
    }
}

struct ProfileCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .profileCardBackground()
    }
}

struct ProfileSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: () -> Void = {}

    var body: some View {
        HStack {
            Text(title)
                .font(.alineTitleMedium)
                .foregroundColor(AlineTheme.inkPrimary)
            Spacer()
            if let actionTitle {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text(actionTitle)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .alineGlassCapsule(selected: true)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ProfileEmptyPrompt: View {
    let icon: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .foregroundColor(AlineTheme.inkSecondary)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
        }
        .buttonStyle(.plain)
    }
}

/// Pastel card for an experience / project entry on the profile page.
struct ProfileEntryCard: View {
    let onTap: () -> Void
    let icon: String
    let title: String
    let subtitle: String
    let period: String
    let bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(Color.black.opacity(0.06)).frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(2)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AlineTheme.inkSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }

            if !period.isEmpty {
                Text(period)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.05)))
            }

            // A preview: two points, two lines each — the full entry opens on tap
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(bullets.prefix(2).enumerated()), id: \.offset) { _, bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(bullet).lineSpacing(2).lineLimit(2)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(AlineTheme.inkPrimary.opacity(0.85))
                }
                if bullets.count > 2 {
                    Text("+\(bullets.count - 2) more")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .profileCardBackground()
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

/// Left-aligned wrapping layout for chips.
struct ProfileFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, usedWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            usedWidth = max(usedWidth, x - spacing)
        }
        return CGSize(width: usedWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Profile Menu Row Component
public struct ProfileMenuRow: View {
    public let icon: String
    public let iconColor: Color
    public let title: String
    public let subtitle: String
    public var toggle: Binding<Bool>? = nil
    public let action: () -> Void

    public var body: some View {
        if toggle != nil {
            rowContent
        } else {
            Button(action: action) { rowContent }
                .buttonStyle(.plain)
        }
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if let toggle {
                Toggle("", isOn: toggle)
                    .labelsHidden()
                    .tint(AlineTheme.accentEmerald)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AlineTheme.inkMuted)
            }
        }
        .padding(16)
        .profileCardBackground(radius: 20)
    }
}

// MARK: - Sheet Scaffold (✕ top-left, Save top-right on every profile sheet)
struct ProfileSheetScaffold<Content: View>: View {
    let title: String
    var saveTitle: String = "Save"
    var canSave: Bool = true
    /// Shown if Save is tapped before the required field is filled
    var requiredHint: String = "Add a title to save."
    let onSave: () -> Void
    @ViewBuilder let content: () -> Content
    @Environment(\.dismiss) private var dismiss
    @State private var showRequiredHint = false

    var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()

            VStack(spacing: 0) {
                ZStack {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    HStack {
                        ProfileCircleButton(icon: "xmark") { dismiss() }
                        Spacer()
                        // Always the same black Save as every other sheet (a disabled glass button turned grey-olive);
                        // tapping it too early explains what's missing instead
                        Button {
                            guard canSave else {
                                withAnimation(AlineTheme.fastSpring) { showRequiredHint = true }
                                return
                            }
                            onSave()
                            dismiss()
                        } label: {
                            Text(saveTitle)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 6)
                                .frame(height: 28)
                        }
                        .alineGlassProminentButton()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 12)

                if showRequiredHint && !canSave {
                    Text(requiredHint)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AlineTheme.accentHeart)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        content()
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Form Components
struct ProfileField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var multiline: Bool = false
    var isURL: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AlineTheme.inkSecondary)

            Group {
                if multiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(3...8)
                } else {
                    TextField(placeholder, text: $text)
.alineKeyboardDismissal(.done)
                }
            }
            // Take the width offered, never the text's own length: a long imported value
            // (e.g. a whole table row from a resume) otherwise widened the entire sheet past the screen
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .font(.alineBody)
            .foregroundColor(AlineTheme.inkPrimary)
            .keyboardType(isURL ? .URL : .default)
            .textInputAutocapitalization(isURL ? .never : .sentences)
            .autocorrectionDisabled(isURL)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.04)))
        }
    }
}

struct ProfileTagEditor: View {
    let title: String
    @Binding var items: [String]
    var placeholder: String = "Add"
    /// Known values to suggest while typing (e.g. "py" suggests Python); tapping one adds it
    var suggestions: [String] = []
    @State private var newItem: String = ""

    /// Starts-with matches first, then other matches; skips anything already added
    private var matchingSuggestions: [String] {
        let query = newItem.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return [] }
        let taken = Set(items.map { $0.lowercased() })
        let available = suggestions.filter { !taken.contains($0.lowercased()) }
        let prefix = available.filter { $0.lowercased().hasPrefix(query) }
        let contains = available.filter { !$0.lowercased().hasPrefix(query) && $0.lowercased().contains(query) }
        return Array((prefix + contains).prefix(6))
    }

    var body: some View {
        ProfileCard {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AlineTheme.inkSecondary)

            if !items.isEmpty {
                ProfileFlowLayout(spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        HStack(spacing: 6) {
                            Text(item)
                                .font(.system(size: 12, weight: .semibold))
                            Button {
                                items.removeAll { $0 == item }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .buttonStyle(.plain)
                        }
                        .foregroundColor(AlineTheme.inkPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .alineGlassCapsule(selected: false, interactive: false)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                TextField(placeholder, text: $newItem)
                    .font(.alineBody)
                    // Our own suggestions replace iOS autocorrect here
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit(add)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.04)))

                Button(action: add) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .alineGlassCircle(selected: true)
                }
                .buttonStyle(.plain)
            }

            if !matchingSuggestions.isEmpty {
                // One scrollable row of suggestions, like the keyboard's suggestion bar
                ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(matchingSuggestions, id: \.self) { suggestion in
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                items.append(suggestion)
                                newItem = ""
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 9, weight: .bold))
                                Text(suggestion)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(AlineTheme.inkPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.white))
                            .overlay(Capsule().stroke(Color.black.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [3, 2])))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add \(suggestion)")
                    }
                }
                .padding(.vertical, 1)
                }
                .scrollClipDisabled()
            }
        }
    }

    private func add() {
        let trimmed = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !items.contains(trimmed) else {
            newItem = ""
            return
        }
        items.append(trimmed)
        newItem = ""
    }
}

struct ProfileSelectableChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .alineGlassCapsule(selected: isSelected)
        }
        .buttonStyle(.plain)
    }
}

/// Row in the edit-profile sheet for an existing experience / project (tap to edit, trash to remove).
struct ProfileEditableRow: View {
    let title: String
    let subtitle: String
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onEdit) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title.isEmpty ? "Untitled" : title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.inkMuted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(AlineTheme.accentHeart)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
    }
}

struct ProfileBulletEditor: View {
    @Binding var bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Highlights")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AlineTheme.inkSecondary)

            ForEach(bullets.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    TextField("Describe what you did and the impact", text: bulletBinding(index), axis: .vertical)
                        .lineLimit(1...5)
                        .font(.alineBody)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.04)))

                    Button {
                        if bullets.indices.contains(index) { bullets.remove(at: index) }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AlineTheme.accentHeart)
                            .padding(.top, 10)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                bullets.append("")
            } label: {
                Label("Add highlight", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
            }
            .buttonStyle(.plain)
        }
    }

    private func bulletBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { bullets.indices.contains(index) ? bullets[index] : "" },
            set: { if bullets.indices.contains(index) { bullets[index] = $0 } }
        )
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    public var navViewModel: AppNavigationViewModel? = nil
    @State private var draft: UserProfile
    @State private var editingExperience: UserExperience?
    @State private var editingProject: UserProject?

    let resumes: [ResumeDocument]
    @State private var showingResumeImporter: Bool = false
    @State private var importMessage: String?

    init(viewModel: ProfileViewModel, resumes: [ResumeDocument] = [], navViewModel: AppNavigationViewModel? = nil) {
        self.viewModel = viewModel
        self.resumes = resumes
        self.navViewModel = navViewModel
        _draft = State(initialValue: viewModel.profile)
    }

    var body: some View {
        ProfileSheetScaffold(
            title: "Edit Profile",
            canSave: !draft.name.trimmingCharacters(in: .whitespaces).isEmpty,
            requiredHint: "Add your name to save."
        ) {
            viewModel.updateProfile(draft)
            navViewModel?.currentUserFullName = draft.name
        } content: {
            resumeImportCard

            ProfileCard {
                ProfileField(title: "Full Name", text: $draft.name, placeholder: "Your name")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Community Username")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.inkSecondary)
                    HStack {
                        Text("@\(draft.username)")
                            .font(.alineBody)
                            .foregroundColor(AlineTheme.inkSecondary)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AlineTheme.inkMuted)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.04)))
                    Text("Assigned to you for anonymous community posts. It can't be changed.")
                        .font(.system(size: 11))
                        .foregroundColor(AlineTheme.inkMuted)
                }
                ProfileField(title: "Current Stage", text: $draft.titleOrStage, placeholder: "e.g. 3rd Year CS Student")
                ProfileField(title: "Degree", text: $draft.education, placeholder: "e.g. B.Tech in Computer Science")
                ProfileField(title: "Institution", text: $draft.institution, placeholder: "College or university")
                ProfileField(title: "Graduation Year", text: $draft.graduationYear, placeholder: "2028")
                ProfileField(title: "Location", text: $draft.location, placeholder: "City, Country")
                ProfileField(title: "Bio", text: $draft.bio, placeholder: "A short intro about you", multiline: true)
            }

            ProfileTagEditor(title: "Core Skills", items: $draft.skills, placeholder: "Add a skill", suggestions: ProfileSkillCatalog.all)

            ProfileCard {
                Text("Links")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AlineTheme.inkSecondary)
                ProfileField(title: "LinkedIn", text: $draft.linkedInURL, placeholder: "linkedin.com/in/you", isURL: true)
                ProfileField(title: "GitHub", text: $draft.githubURL, placeholder: "github.com/you", isURL: true)
                ProfileField(title: "Portfolio", text: $draft.portfolioURL, placeholder: "yoursite.dev", isURL: true)
            }

            ProfileCard {
                ProfileSectionHeader(title: "Experience", actionTitle: "Add") {
                    editingExperience = UserExperience(
                        id: UUID().uuidString, title: "", company: "", location: "", period: "", bullets: [""]
                    )
                }
                if draft.experiences.isEmpty {
                    Text("No experience added yet.")
                        .font(.system(size: 13))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
                ForEach(draft.experiences) { exp in
                    ProfileEditableRow(
                        title: exp.title,
                        subtitle: [exp.company, exp.period].filter { !$0.isEmpty }.joined(separator: " • "),
                        onEdit: { editingExperience = exp },
                        onDelete: { draft.experiences.removeAll { $0.id == exp.id } }
                    )
                    if exp.id != draft.experiences.last?.id { Divider() }
                }
            }

            ProfileCard {
                ProfileSectionHeader(title: "Projects", actionTitle: "Add") {
                    editingProject = UserProject(
                        id: UUID().uuidString, title: "", period: "", techStack: "", bullets: [""]
                    )
                }
                if draft.projects.isEmpty {
                    Text("No projects added yet.")
                        .font(.system(size: 13))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
                ForEach(draft.projects) { proj in
                    ProfileEditableRow(
                        title: proj.title,
                        subtitle: [proj.techStack, proj.period].filter { !$0.isEmpty }.joined(separator: " • "),
                        onEdit: { editingProject = proj },
                        onDelete: { draft.projects.removeAll { $0.id == proj.id } }
                    )
                    if proj.id != draft.projects.last?.id { Divider() }
                }
            }
        }
        .fileImporter(isPresented: $showingResumeImporter, allowedContentTypes: [.pdf]) { result in
            if case .success(let url) = result { importUploadedResume(url) }
        }
        .sheet(item: $editingExperience) { exp in
            ExperienceEditorSheet(experience: exp) { saved in
                if let index = draft.experiences.firstIndex(where: { $0.id == saved.id }) {
                    draft.experiences[index] = saved
                } else {
                    draft.experiences.append(saved)
                }
            }
        }
        .sheet(item: $editingProject) { proj in
            ProjectEditorSheet(project: proj) { saved in
                if let index = draft.projects.firstIndex(where: { $0.id == saved.id }) {
                    draft.projects[index] = saved
                } else {
                    draft.projects.append(saved)
                }
            }
        }
    }
}

extension EditProfileSheet {
    var resumeImportCard: some View {
        ProfileCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fill in faster")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                Text("Pull your skills, experience and projects from a resume. You can review everything before saving.")
                    .font(.system(size: 13))
                    .foregroundColor(AlineTheme.inkSecondary)
            }

            HStack(spacing: 10) {
                Menu {
                    ForEach(resumes) { resume in
                        Button(resume.title) { importAlineResume(resume) }
                    }
                } label: {
                    importButtonLabel("From Aline resume", filled: true)
                }
                .disabled(resumes.isEmpty)

                Button { showingResumeImporter = true } label: {
                    importButtonLabel("Upload PDF", filled: false)
                }
                .buttonStyle(.plain)
            }

            if let importMessage {
                Text(importMessage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AlineTheme.inkSecondary)
            }
        }
    }

    private func importButtonLabel(_ title: String, filled: Bool) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(filled ? .white : AlineTheme.inkPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .alineGlassCapsule(selected: filled)
    }

    /// Merges an in-app resume into the draft without overwriting what the user already entered.
    func importAlineResume(_ resume: ResumeDocument) {
        var addedSkills = 0, addedExperiences = 0, addedProjects = 0

        for skill in resume.skills where !draft.skills.contains(where: { $0.caseInsensitiveCompare(skill) == .orderedSame }) {
            draft.skills.append(skill)
            addedSkills += 1
        }
        for exp in resume.experiences where !draft.experiences.contains(where: {
            $0.company.caseInsensitiveCompare(exp.company) == .orderedSame && $0.title.caseInsensitiveCompare(exp.role) == .orderedSame
        }) {
            draft.experiences.append(UserExperience(
                id: UUID().uuidString, title: exp.role, company: exp.company,
                location: exp.location, period: exp.period, bullets: exp.bullets
            ))
            addedExperiences += 1
        }
        for proj in resume.projects where !draft.projects.contains(where: {
            $0.title.caseInsensitiveCompare(proj.title) == .orderedSame
        }) {
            draft.projects.append(UserProject(
                id: UUID().uuidString, title: proj.title, period: "", techStack: proj.techStack, bullets: proj.bullets
            ))
            addedProjects += 1
        }
        if draft.bio.trimmingCharacters(in: .whitespaces).isEmpty, !resume.summary.isEmpty {
            draft.bio = resume.summary
        }

        importMessage = addedSkills + addedExperiences + addedProjects == 0
            ? "Everything in “\(resume.title)” is already on your profile."
            : "Added \(addedSkills) skills, \(addedExperiences) experiences, \(addedProjects) projects. Tap Save to keep them."
    }

    /// Reads an uploaded PDF into the draft — skills, experience and projects — without
    /// overwriting what the user already entered (on-device model when available, heuristics otherwise).
    func importUploadedResume(_ url: URL) {
        let hasAccess = url.startAccessingSecurityScopedResource()
        let text = PDFTextExtractor.extractText(from: url)
        if hasAccess { url.stopAccessingSecurityScopedResource() }

        guard let text, !text.isEmpty else {
            importMessage = "We couldn't read that file. Try another PDF or add details manually."
            return
        }
        importMessage = "Reading your resume…"
        Task {
            let understood = await ResumeUnderstanding.understand(text)
            // Identity fields (name, degree, institution, year, links, location, bio) only where the form is still empty
            var identity = draft
            identity.mergeEmptyFields(from: understood, includeEntries: false)
            draft = identity
            importAlineResume(ResumeDocument(parsed: understood.resume, fileName: url.lastPathComponent, fileSize: nil))
            let added = viewModel.addAchievements(understood.achievements)
            if added > 0, let message = importMessage {
                importMessage = message + " \(added) achievement\(added == 1 ? "" : "s") added to your gallery."
            }
        }
    }
}

// MARK: - Experience Editor Sheet
struct ExperienceEditorSheet: View {
    @State private var draft: UserExperience
    let onSave: (UserExperience) -> Void

    init(experience: UserExperience, onSave: @escaping (UserExperience) -> Void) {
        _draft = State(initialValue: experience)
        self.onSave = onSave
    }

    var body: some View {
        ProfileSheetScaffold(
            title: "Experience",
            canSave: !draft.title.trimmingCharacters(in: .whitespaces).isEmpty,
            requiredHint: "Add a role to save."
        ) {
            var cleaned = draft
            cleaned.bullets = draft.bullets
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            onSave(cleaned)
        } content: {
            ProfileCard {
                ProfileField(title: "Role", text: $draft.title, placeholder: "e.g. Software Engineering Intern")
                ProfileField(title: "Company", text: $draft.company, placeholder: "Company name")
                ProfileField(title: "Location", text: $draft.location, placeholder: "City, Country")
                ProfileField(title: "Period", text: $draft.period, placeholder: "e.g. May 2026 – Jul 2026")
            }
            ProfileCard {
                ProfileBulletEditor(bullets: $draft.bullets)
            }
        }
    }
}

// MARK: - Project Editor Sheet
struct ProjectEditorSheet: View {
    @State private var draft: UserProject
    let onSave: (UserProject) -> Void

    init(project: UserProject, onSave: @escaping (UserProject) -> Void) {
        _draft = State(initialValue: project)
        self.onSave = onSave
    }

    var body: some View {
        ProfileSheetScaffold(
            title: "Project",
            canSave: !draft.title.trimmingCharacters(in: .whitespaces).isEmpty,
            requiredHint: "Add a project name to save."
        ) {
            var cleaned = draft
            cleaned.bullets = draft.bullets
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            onSave(cleaned)
        } content: {
            ProfileCard {
                ProfileField(title: "Project Name", text: $draft.title, placeholder: "e.g. Aline Career Experience")
                ProfileField(title: "Tech Stack", text: $draft.techStack, placeholder: "e.g. Swift, SwiftUI, Combine")
                ProfileField(title: "Period", text: $draft.period, placeholder: "e.g. Aug 2026 – Present")
            }
            ProfileCard {
                ProfileBulletEditor(bullets: $draft.bullets)
            }
        }
    }
}

// MARK: - Career Preferences Sheet
public struct CareerPreferencesSheet: View {
    @ObservedObject public var viewModel: ProfileViewModel
    @State private var draft: CareerPreferences

    public init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _draft = State(initialValue: viewModel.preferences)
    }

    public var body: some View {
        ProfileSheetScaffold(title: "Career Preferences") {
            viewModel.updatePreferences(draft)
        } content: {
            ProfileTagEditor(title: "Preferred Roles", items: $draft.preferredRoles, placeholder: "Add a role")
            ProfileTagEditor(title: "Preferred Companies", items: $draft.preferredCompanies, placeholder: "Add a company")

            ProfileCard {
                Toggle(isOn: $draft.isOpenToAnyLocation) {
                    Text("Open to any location")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
                .tint(AlineTheme.accentEmerald)
            }

            if !draft.isOpenToAnyLocation {
                ProfileTagEditor(title: "Preferred Locations", items: $draft.preferredLocations, placeholder: "Add a city")
            }

            ProfileCard {
                Text("Opportunity Type")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AlineTheme.inkSecondary)
                ProfileFlowLayout(spacing: 8) {
                    ForEach(Opportunity.OpportunityType.allCases, id: \.self) { type in
                        ProfileSelectableChip(title: type.rawValue, isSelected: draft.opportunityTypes.contains(type)) {
                            toggle(type, in: &draft.opportunityTypes)
                        }
                    }
                }

                Text("Work Arrangement")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .padding(.top, 4)
                ProfileFlowLayout(spacing: 8) {
                    ForEach(Opportunity.WorkMode.allCases, id: \.self) { mode in
                        ProfileSelectableChip(title: mode.rawValue, isSelected: draft.workArrangements.contains(mode)) {
                            toggle(mode, in: &draft.workArrangements)
                        }
                    }
                }

                ProfileField(title: "Experience Level", text: $draft.experienceLevel, placeholder: "e.g. Freshers (0 yrs)")
            }
        }
    }

    private func toggle<T: Equatable>(_ value: T, in array: inout [T]) {
        if let index = array.firstIndex(of: value) {
            array.remove(at: index)
        } else {
            array.append(value)
        }
    }
}

// MARK: - Achievement File Styling (monochrome, no icons)
fileprivate extension AchievementItem {
    /// Short file-type label shown instead of an icon (e.g. "PDF"); falls back to the folder's initial.
    var fileLabel: String {
        let ext = (attachmentName as NSString?)?.pathExtension ?? ""
        return ext.isEmpty ? String(category.rawValue.prefix(1)) : ext.uppercased()
    }
}

fileprivate let achievementDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "d MMM yyyy"
    return formatter
}()

// MARK: - Achievement Gallery (Root: folders, like the Files app)
public struct AchievementGalleryView: View {
    @ObservedObject public var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var showingAddSheet: Bool = false

    private var searchResults: [AchievementItem] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }
        return viewModel.achievements.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.issuer.localizedCaseInsensitiveContains(query) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AlineSpacing.section) {
                    HStack {
                        ProfileCircleButton(icon: "chevron.left") { dismiss() }
                        Spacer()
                        ProfileCircleButton(icon: "plus") { showingAddSheet = true }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Achievements")
                            .font(.alineHero)
                            .textCase(.uppercase)
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("\(viewModel.achievements.count) items in \(AchievementCategory.allCases.count) folders")
                            .font(.alineCallout)
                            .foregroundColor(AlineTheme.inkSecondary)
                    }

                    AlineSearchField("Search achievements", text: $searchText)

                    if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        recentsSection
                        foldersSection
                    } else {
                        resultsSection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
.scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddSheet) {
            AchievementEditorSheet { viewModel.upsertAchievement($0) }
        }
    }

    private var recentsSection: some View {
        let recents = Array(viewModel.achievements.prefix(3))
        return Group {
            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recents")
                        .font(.alineTitleMedium)
                        .foregroundColor(AlineTheme.inkPrimary)
                    AchievementFileList(items: recents)
                }
            }
        }
    }

    private var foldersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Folders")
                .font(.alineTitleMedium)
                .foregroundColor(AlineTheme.inkPrimary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    NavigationLink(value: ProfileRoute.folder(category)) {
                        AchievementFolderTile(
                            category: category,
                            count: viewModel.achievements(in: category).count
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Results")
                .font(.alineTitleMedium)
                .foregroundColor(AlineTheme.inkPrimary)
            if searchResults.isEmpty {
                Text("No achievements match “\(searchText)”.")
                    .font(.alineCallout)
                    .foregroundColor(AlineTheme.inkSecondary)
                    .padding(.top, 8)
            } else {
                AchievementFileList(items: searchResults)
            }
        }
    }
}

struct AchievementFolderTile: View {
    let category: AchievementCategory
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text(count == 1 ? "1 item" : "\(count) items")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(count == 0 ? AlineTheme.inkSecondary : .white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(count == 0 ? Color.black.opacity(0.06) : AlineTheme.pillDark))

            Text(category.rawValue)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .profileCardBackground()
    }
}

/// Files-app style list: rows separated by hairlines inside one white container.
struct AchievementFileList: View {
    let items: [AchievementItem]
    var onEdit: ((AchievementItem) -> Void)? = nil
    var onDelete: ((AchievementItem) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                NavigationLink(value: ProfileRoute.achievement(item.id)) {
                    AchievementFileRow(item: item)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if let onEdit {
                        Button { onEdit(item) } label: { Label("Edit", systemImage: "pencil") }
                    }
                    if let onDelete {
                        Button(role: .destructive) { onDelete(item) } label: { Label("Delete", systemImage: "trash") }
                    }
                }

                if item.id != items.last?.id {
                    Divider().padding(.leading, 76)
                }
            }
        }
        .profileCardBackground()
    }
}

struct AchievementFileRow: View {
    let item: AchievementItem

    var body: some View {
        HStack(spacing: 14) {
            AchievementFileIcon(item: item, size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .lineLimit(1)
                Text("\(item.dateEarned) • \(item.issuer)")
                    .font(.system(size: 12))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AlineTheme.inkMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct AchievementFileIcon: View {
    let item: AchievementItem
    var size: CGFloat = 46

    var body: some View {
        Text(item.fileLabel)
            .font(.system(size: size * 0.28, weight: .heavy))
            .foregroundColor(AlineTheme.inkPrimary)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                    .fill(Color.black.opacity(0.06))
            )
    }
}

// MARK: - Achievement Folder (Inside one category)
public struct AchievementFolderView: View {
    @ObservedObject public var viewModel: ProfileViewModel
    public let category: AchievementCategory
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddSheet: Bool = false
    @State private var editingItem: AchievementItem?

    private var items: [AchievementItem] { viewModel.achievements(in: category) }

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        ProfileCircleButton(icon: "chevron.left") { dismiss() }
                        Spacer()
                        ProfileCircleButton(icon: "plus") { showingAddSheet = true }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.rawValue)
                            .font(.alineHero)
                            .textCase(.uppercase)
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text(items.count == 1 ? "1 item" : "\(items.count) items")
                            .font(.alineCallout)
                            .foregroundColor(AlineTheme.inkSecondary)
                    }

                    if items.isEmpty {
                        VStack(spacing: 12) {
                            Text("This folder is empty")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("Add certificates, awards and credentials to keep them in one place.")
                                .font(.alineCallout)
                                .foregroundColor(AlineTheme.inkSecondary)
                                .multilineTextAlignment(.center)
                            Button { showingAddSheet = true } label: {
                                Text("Add Achievement")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .alineGlassCapsule(selected: true)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                        .padding(.horizontal, 20)
                    } else {
                        AchievementFileList(
                            items: items,
                            onEdit: { editingItem = $0 },
                            onDelete: { item in
                                withAnimation(AlineTheme.fastSpring) {
                                    viewModel.deleteAchievement(id: item.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
.scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddSheet) {
            AchievementEditorSheet(category: category) { viewModel.upsertAchievement($0) }
        }
        .sheet(item: $editingItem) { item in
            AchievementEditorSheet(item: item) { viewModel.upsertAchievement($0) }
        }
    }
}

// MARK: - Achievement Detail (A single "file")
public struct AchievementDetailView: View {
    @ObservedObject public var viewModel: ProfileViewModel
    public let achievementId: String
    @Environment(\.dismiss) private var dismiss
    @State private var editingItem: AchievementItem?
    @State private var showingDeleteConfirm: Bool = false
    /// The attachment being shown in Quick Look
    @State private var previewURL: URL?

    private var item: AchievementItem? {
        viewModel.achievements.first { $0.id == achievementId }
    }

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()

            if let item {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            ProfileCircleButton(icon: "chevron.left") { dismiss() }
                            Spacer()
                            Menu {
                                Button { editingItem = item } label: { Label("Edit", systemImage: "pencil") }
                                Button(role: .destructive) { showingDeleteConfirm = true } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .frame(width: 40, height: 40)
                                .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .alineGlassCircleButton()
                        }

                        // File preview
                        VStack(spacing: 14) {
                            // The certificate itself; tap to open it full screen
                            AttachmentThumbnail(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // Opens the attached file (downloaded from the backend if needed)
                                    guard let name = item.attachmentName else { return }
                                    Task { previewURL = await AttachmentStore.localURL(forAchievement: item.id, filename: name) }
                                }
                                .quickLookPreview($previewURL)
                            Text(item.attachmentName ?? "No attachment")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .profileCardBackground(radius: 28)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text(item.issuer)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }

                        ProfileCard(padding: 0) {
                            detailRow(label: "Folder", value: item.category.rawValue)
                            Divider().padding(.leading, 16)
                            detailRow(label: "Date Earned", value: item.dateEarned)
                            if let attachment = item.attachmentName {
                                Divider().padding(.leading, 16)
                                detailRow(label: "Attachment", value: attachment)
                            }
                            if let urlString = item.credentialURL, !urlString.isEmpty {
                                Divider().padding(.leading, 16)
                                credentialRow(urlString)
                            }
                        }

                        if !item.descriptionText.isEmpty {
                            ProfileCard {
                                Text("About")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.inkSecondary)
                                Text(item.descriptionText)
                                    .font(.alineBody)
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .lineSpacing(3)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
.scrollDismissesKeyboard(.interactively)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editingItem) { item in
            AchievementEditorSheet(item: item) { viewModel.upsertAchievement($0) }
        }
        .confirmationDialog("Delete this achievement?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                viewModel.deleteAchievement(id: achievementId)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AlineTheme.inkSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AlineTheme.inkPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func credentialRow(_ urlString: String) -> some View {
        let content = HStack(spacing: 14) {
            Text("Credential")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AlineTheme.inkSecondary)
            Spacer()
            Text("Open")
                .font(.system(size: 14, weight: .bold))
            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(AlineTheme.inkPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)

        if let url = ProfileView.url(from: urlString) {
            Link(destination: url) { content }
        } else {
            content
        }
    }
}

// MARK: - Add / Edit Achievement Sheet
struct AchievementEditorSheet: View {
    @State private var draft: AchievementItem
    @State private var date: Date
    @State private var showingFileImporter: Bool = false
    /// Reading the attached certificate to fill the form
    @State private var isReadingCertificate: Bool = false
    @State private var readMessage: String?
    let onSave: (AchievementItem) -> Void

    init(item: AchievementItem? = nil, category: AchievementCategory = .certificates, onSave: @escaping (AchievementItem) -> Void) {
        let base = item ?? AchievementItem(
            id: UUID().uuidString,
            title: "",
            issuer: "",
            category: category,
            dateEarned: "",
            descriptionText: "",
            credentialURL: nil,
            attachmentName: nil
        )
        _draft = State(initialValue: base)
        _date = State(initialValue: achievementDateFormatter.date(from: base.dateEarned) ?? Date())
        self.onSave = onSave
    }

    private var urlBinding: Binding<String> {
        Binding(
            get: { draft.credentialURL ?? "" },
            set: { draft.credentialURL = $0.isEmpty ? nil : $0 }
        )
    }

    var body: some View {
        ProfileSheetScaffold(
            title: "Achievement",
            canSave: !draft.title.trimmingCharacters(in: .whitespaces).isEmpty
        ) {
            var saved = draft
            saved.dateEarned = achievementDateFormatter.string(from: date)
            onSave(saved)
        } content: {
            certificateCard

            ProfileCard {
                Text("Folder")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AlineTheme.inkSecondary)
                ProfileFlowLayout(spacing: 8) {
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        ProfileSelectableChip(
                            title: category.rawValue,
                            isSelected: draft.category == category
                        ) {
                            withAnimation(AlineTheme.fastSpring) { draft.category = category }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            ProfileCard {
                ProfileField(title: "Title", text: $draft.title, placeholder: "e.g. AWS Certified Cloud Practitioner")
                ProfileField(title: "Issuer", text: $draft.issuer, placeholder: "Who awarded it?")
                DatePicker("Date Earned", selection: $date, in: ...Date(), displayedComponents: .date)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AlineTheme.inkPrimary)
                ProfileField(title: "Description", text: $draft.descriptionText, placeholder: "What did you accomplish?", multiline: true)
            }

            ProfileCard {
                ProfileField(title: "Credential URL", text: urlBinding, placeholder: "https://…", isURL: true)
            }
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.pdf, .image]) { result in
            if case .success(let url) = result { attach(url) }
        }
    }

    /// Attach first: the certificate fills in the rest of the form
    private var certificateCard: some View {
        ProfileCard {
                Text("Certificate")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AlineTheme.inkSecondary)

                if let name = draft.attachmentName {
                    HStack(spacing: 12) {
                        Text(name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(1)
                        Spacer()
                        Button { draft.attachmentName = nil } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AlineTheme.inkMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.04)))
                } else {
                    Button { showingFileImporter = true } label: {
                        VStack(spacing: 4) {
                            Text("Attach certificate")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("PDF or photo — we'll fill in the details")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        )
                    }
                    .buttonStyle(.plain)
                }

                if isReadingCertificate {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Reading your certificate…")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AlineTheme.inkSecondary)
                } else if let readMessage {
                    Text(readMessage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
        }
    }

    /// Stores the file, then fills every empty field from what the certificate says.
    private func attach(_ url: URL) {
        let hasAccess = url.startAccessingSecurityScopedResource()
        AttachmentStore.store(url, forAchievement: draft.id)
        // Read from the app's own copy (the picked file's access ends here)
        let local = URL.documentsDirectory.appendingPathComponent("Attachments/\(draft.id)/\(url.lastPathComponent)")
        if hasAccess { url.stopAccessingSecurityScopedResource() }
        draft.attachmentName = url.lastPathComponent
        isReadingCertificate = true
        readMessage = nil
        Task { @MainActor in
            let fields = await CertificateReader.read(local)
            var filled = 0
            @MainActor func fill(_ keyPath: WritableKeyPath<AchievementItem, String>, _ value: String) {
                guard draft[keyPath: keyPath].trimmingCharacters(in: .whitespaces).isEmpty, !value.isEmpty else { return }
                draft[keyPath: keyPath] = value
                filled += 1
            }
            fill(\.title, fields.title)
            fill(\.issuer, fields.issuer)
            fill(\.descriptionText, fields.description)
            if (draft.credentialURL ?? "").isEmpty, !fields.credentialURL.isEmpty {
                draft.credentialURL = fields.credentialURL
                filled += 1
            }
            if let parsed = fields.date {
                date = min(parsed, Date())
                filled += 1
            }
            if let category = fields.category { draft.category = category }
            isReadingCertificate = false
            readMessage = filled > 0
                ? "Filled in from your certificate — check the details before saving."
                : "Couldn't read details from this file. Fill them in below."
        }
    }
}

// MARK: - Help and Feedback Sheet
public struct HelpAndFeedbackSheet: View {
    @State private var feedback: String = ""

    public init() {}

    public var body: some View {
        ProfileSheetScaffold(
            title: "Help & Feedback",
            saveTitle: "Send",
            canSave: !feedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            requiredHint: "Write your feedback to send it."
        ) {
            let message = feedback.trimmingCharacters(in: .whitespacesAndNewlines)
            Task { try? await AlineAPI.sendFeedback(category: "General", message: message) }
        } content: {
            ProfileCard {
                ProfileField(title: "Send us feedback", text: $feedback, placeholder: "Tell us what's working and what isn't", multiline: true)
            }

            ProfileCard {
                Text("Frequently Asked Questions")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AlineTheme.inkSecondary)
                faq("Where do opportunities come from?", "Listings are aggregated directly from employer career portals.")
                Divider()
                faq("How does resume optimization work?", "The AI analyzes job requirements and missing keywords to help you describe your authentic experience effectively.")
                Divider()
                faq("Is my community activity anonymous?", "Your community discussions are published with an anonymous handle by default.")
            }

            ProfileCard {
                HStack {
                    Text("Version")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Spacer()
                    Text("1.0.0 (Native iOS)")
                        .font(.system(size: 14))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
            }
        }
    }

    private func faq(_ question: String, _ answer: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(question)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
            Text(answer)
                .font(.system(size: 13))
                .foregroundColor(AlineTheme.inkSecondary)
                .lineSpacing(2)
        }
    }
}

// MARK: - Delete Account Confirmation Sheet
public struct DeleteAccountConfirmationSheet: View {
    @ObservedObject public var navViewModel: AppNavigationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmationWord: String = ""

    private var isConfirmed: Bool {
        confirmationWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "delete"
    }

    public init(navViewModel: AppNavigationViewModel) {
        self.navViewModel = navViewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                DiscoverBackgroundArtwork()
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.10))
                            .frame(width: 68, height: 68)

                        Image(systemName: "trash.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color.red)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 8) {
                        Text("Delete Account?")
                            .font(.system(size: 24, weight: .heavy, design: .default))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Text("This action is permanent and cannot be undone. All your profile information, resumes, job applications, and saved content will be permanently removed.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AlineTheme.inkSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 16)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("To confirm, type the word \"delete\" below:")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AlineTheme.inkPrimary)

                        TextField("Type delete", text: $confirmationWord)
                            .font(.system(size: 15))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(isConfirmed ? Color.red : Color.black.opacity(0.12), lineWidth: isConfirmed ? 1.5 : 1)
                            )
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 6)

                    Spacer(minLength: 16)

                    // Delete Account Button (Disabled until 'delete' is typed)
                    Button {
                        if isConfirmed {
                            dismiss()
                            withAnimation(.easeInOut(duration: 0.35)) {
                                navViewModel.deleteAccount()
                            }
                        }
                    } label: {
                        Text("Delete Account")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Capsule()
                                    .fill(isConfirmed ? Color(red: 0.88, green: 0.22, blue: 0.22) : Color.gray.opacity(0.35))
                            )
                    }
                    .disabled(!isConfirmed)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)

                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .padding(.bottom, 8)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(440), .medium])
    }
}

// MARK: - Previews
#Preview("Profile & Career Hub") {
    ProfileView(viewModel: ProfileViewModel())
}

#Preview("Edit Profile Sheet") {
    EditProfileSheet(viewModel: ProfileViewModel())
}

#Preview("Career Preferences Sheet") {
    CareerPreferencesSheet(viewModel: ProfileViewModel())
}

#Preview("Achievement Gallery") {
    NavigationStack {
        AchievementGalleryView(viewModel: ProfileViewModel())
    }
}

#Preview("Add Achievement Sheet") {
    AchievementEditorSheet { _ in }
}

#Preview("Help and Support Sheet") {
    HelpAndFeedbackSheet()
}

// MARK: - Skill suggestions for the profile editor
enum ProfileSkillCatalog {
    static let all: [String] = [
        // Languages
        "Python", "Java", "JavaScript", "TypeScript", "C", "C++", "C#", "Go", "Rust", "Kotlin", "Swift",
        "Objective-C", "Ruby", "PHP", "Scala", "R", "MATLAB", "Dart", "SQL", "Bash", "HTML", "CSS",
        // Apple & mobile
        "SwiftUI", "UIKit", "Combine", "Core Data", "SwiftData", "Xcode", "Android", "Jetpack Compose", "Flutter", "React Native",
        // Web
        "React", "Next.js", "Angular", "Vue.js", "Node.js", "Express.js", "Django", "Flask", "FastAPI", "Spring Boot",
        "GraphQL", "REST APIs", "Tailwind CSS", "Redux",
        // Data, AI & ML
        "Machine Learning", "Deep Learning", "PyTorch", "TensorFlow", "Keras", "scikit-learn", "Pandas", "NumPy",
        "OpenCV", "NLP", "Computer Vision", "LLMs", "Prompt Engineering", "RAG", "LangChain", "Data Analysis",
        "Data Visualization", "Power BI", "Tableau", "Excel", "Statistics", "Apache Spark", "Hadoop",
        // Databases
        "PostgreSQL", "MySQL", "MongoDB", "Redis", "SQLite", "Firebase", "DynamoDB", "Elasticsearch",
        // Cloud & DevOps
        "AWS", "Google Cloud", "Azure", "Docker", "Kubernetes", "Terraform", "CI/CD", "GitHub Actions", "Jenkins",
        "Linux", "Git", "Kafka", "Microservices", "System Design",
        // CS fundamentals
        "Data Structures", "Algorithms", "Object-Oriented Programming", "Operating Systems", "Computer Networks",
        "DBMS", "Distributed Systems", "Cybersecurity", "Blockchain",
        // Design & product
        "Figma", "UI/UX Design", "Product Management", "Agile", "Scrum", "Unit Testing", "Test-Driven Development"
    ]
}
