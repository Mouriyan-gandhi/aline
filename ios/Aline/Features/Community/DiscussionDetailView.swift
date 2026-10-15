import SwiftUI

/// Full post + comment thread. Matches the real Figma "Community · Full post" screens'
/// intent (post body, comment list, comment composer) without the exact pixel layout pulled —
/// deprioritized against the feed/compose/backend loop for this pass, revisit against the real
/// design context once the core loop is verified end-to-end.
struct DiscussionDetailView: View {
    let discussionID: String
    let viewModel: CommunityViewModel

    @State private var detail: DiscussionDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var commentText: String = ""
    @State private var isPostingComment = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let detail {
                    postHeader(detail.discussion)
                    Divider()
                    Text("Comments (\(detail.comments.count))")
                        .font(AlineFont.sfPro(14, weight: .bold))
                        .foregroundStyle(AlineColor.textPrimary)
                    if detail.comments.isEmpty {
                        Text("No comments yet — be the first to respond.")
                            .font(AlineFont.sfPro(13))
                            .foregroundStyle(AlineColor.textSecondary)
                    } else {
                        ForEach(detail.comments) { comment in
                            commentRow(comment)
                        }
                    }
                } else if let errorMessage {
                    Text(errorMessage).font(AlineFont.sfPro(14)).foregroundStyle(.red)
                } else {
                    ProgressView().tint(AlineColor.primary).frame(maxWidth: .infinity).padding(.top, 40)
                }
            }
            .padding(16)
        }
        .background(AlineColor.canvas)
        .navigationTitle("Discussion")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if detail != nil {
                commentComposer
            }
        }
        .task { await load() }
    }

    private func postHeader(_ discussion: Discussion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(AlineColor.primary.opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(discussion.username.prefix(1)).uppercased())
                            .font(AlineFont.sfPro(14, weight: .bold))
                            .foregroundStyle(AlineColor.primary)
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text(discussion.company.map { "\(discussion.username) · \($0)" } ?? discussion.username)
                        .font(AlineFont.sfPro(13, weight: .bold))
                    Text([discussion.roleTitle, discussion.createdAt.timeAgoDisplay].compactMap { $0 }.joined(separator: " · "))
                        .font(AlineFont.sfPro(11))
                        .foregroundStyle(AlineColor.iconMuted)
                }
                Spacer(minLength: 0)
                Button {
                    Task {
                        _ = try? await CommunityAPI.toggleSave(discussionID: discussion.id)
                        await load()
                    }
                } label: {
                    Image(systemName: discussion.savedByMe ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(discussion.savedByMe ? AlineColor.primary : AlineColor.iconMuted)
                }
                .buttonStyle(.plain)
            }
            Text(discussion.category)
                .font(AlineFont.sfPro(11, weight: .semibold))
                .foregroundStyle(AlineColor.primary)
            Text(discussion.title)
                .font(AlineFont.sfPro(18, weight: .bold))
                .foregroundStyle(AlineColor.textPrimary)
            Text(discussion.body)
                .font(AlineFont.sfPro(14))
                .foregroundStyle(AlineColor.textPrimary)
                .lineSpacing(3)
            if !discussion.topics.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(discussion.topics, id: \.self) { topic in
                        Text(topic)
                            .font(AlineFont.sfPro(10, weight: .medium))
                            .foregroundStyle(AlineColor.textPrimary)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(AlineColor.chipUnselected)
                            .clipShape(Capsule())
                    }
                }
            }
            HStack(spacing: 18) {
                Button {
                    Task {
                        await viewModel.toggleLike(discussion)
                        await load()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: discussion.likedByMe ? "hand.thumbsup.fill" : "hand.thumbsup")
                        Text("\(discussion.likesCount)")
                    }
                }
                .buttonStyle(.plain)
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left")
                    Text("\(discussion.commentsCount)")
                }
            }
            .font(AlineFont.sfPro(13))
            .foregroundStyle(AlineColor.textPrimary)
        }
    }

    private func commentRow(_ comment: DiscussionComment) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(comment.username)
                    .font(AlineFont.sfPro(12, weight: .bold))
                if let roleTitle = comment.roleTitle {
                    Text(roleTitle).font(AlineFont.sfPro(11)).foregroundStyle(AlineColor.iconMuted)
                }
                Spacer()
                Text(comment.createdAt.timeAgoDisplay).font(AlineFont.sfPro(10)).foregroundStyle(AlineColor.iconMuted)
            }
            Text(comment.body).font(AlineFont.sfPro(13)).foregroundStyle(AlineColor.textPrimary)
        }
        .padding(10)
        .background(AlineColor.paperWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))
    }

    private var commentComposer: some View {
        HStack(spacing: 8) {
            TextField("Add a comment...", text: $commentText)
                .font(AlineFont.sfPro(13))
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(AlineColor.paperWhite)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AlineColor.cardBorder, lineWidth: 1))
            Button {
                postComment()
            } label: {
                if isPostingComment {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 30)).foregroundStyle(AlineColor.primary)
                }
            }
            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPostingComment)
        }
        .padding(12)
        .background(AlineColor.canvas)
    }

    private func load() async {
        do {
            detail = try await CommunityAPI.discussionDetail(id: discussionID)
        } catch {
            errorMessage = "Couldn't load this discussion."
        }
    }

    private func postComment() {
        let body = commentText
        isPostingComment = true
        Task {
            do {
                _ = try await CommunityAPI.addComment(discussionID: discussionID, body: body)
                commentText = ""
                await load()
            } catch {
                errorMessage = "Couldn't post your comment — try again."
            }
            isPostingComment = false
        }
    }
}
