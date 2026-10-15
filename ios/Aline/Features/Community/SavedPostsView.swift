import SwiftUI

/// The header bookmark icon's destination — matches the Figma "Community · Saved posts"
/// screen's intent. Fetches independently of the main feed's filters (a saved post should
/// always show here regardless of what category/topic filters are currently active on the
/// main feed), reusing the same card component.
struct SavedPostsView: View {
    let viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var savedDiscussions: [Discussion] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if isLoading {
                        ProgressView().tint(AlineColor.primary).frame(maxWidth: .infinity).padding(.top, 40)
                    } else if let errorMessage {
                        Text(errorMessage).font(AlineFont.sfPro(14)).foregroundStyle(.red)
                    } else if savedDiscussions.isEmpty {
                        Text("Nothing saved yet — tap the bookmark on a discussion to save it here.")
                            .font(AlineFont.sfPro(14))
                            .foregroundStyle(AlineColor.textSecondary)
                    } else {
                        ForEach(savedDiscussions) { discussion in
                            DiscussionCardView(
                                discussion: discussion,
                                onToggleLike: { Task { await toggleLike(discussion) } },
                                onToggleSave: { Task { await toggleSave(discussion) } }
                            )
                        }
                    }
                }
                .padding(16)
            }
            .background(AlineColor.canvas)
            .navigationTitle("Saved Posts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        do {
            savedDiscussions = try await CommunityAPI.discussions(onlySaved: true)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load your saved posts."
        }
        isLoading = false
    }

    private func toggleLike(_ discussion: Discussion) async {
        guard let index = savedDiscussions.firstIndex(where: { $0.id == discussion.id }) else { return }
        var updated = savedDiscussions[index]
        updated.likesCount += updated.likedByMe ? -1 : 1
        updated.likedByMe.toggle()
        savedDiscussions[index] = updated
        _ = try? await CommunityAPI.toggleLike(discussionID: discussion.id)
    }

    private func toggleSave(_ discussion: Discussion) async {
        _ = try? await CommunityAPI.toggleSave(discussionID: discussion.id)
        savedDiscussions.removeAll { $0.id == discussion.id }
        viewModel.savedDiscussionIDs.remove(discussion.id)
        if let index = viewModel.discussions.firstIndex(where: { $0.id == discussion.id }) {
            viewModel.discussions[index].savedByMe = false
        }
    }
}
