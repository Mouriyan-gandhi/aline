import Foundation
import Observation

enum CommunityLoadState {
    case loading
    case loaded
    case failed(String)
}

enum CommunityFeedTab {
    case forYou, following
}

@MainActor
@Observable
final class CommunityViewModel {
    var identity: CommunityUserIdentity?
    var discussions: [Discussion] = []
    var state: CommunityLoadState = .loading
    var searchText: String = ""

    var feedTab: CommunityFeedTab = .forYou
    var selectedCategory: DiscussionCategory?
    var selectedTopics: Set<DiscussionTopic> = []
    var sort: DiscussionSort = .newest
    var followedCompanies: Set<String> = []
    var savedDiscussionIDs: Set<String> = []

    var activeFilterCount: Int {
        (selectedCategory == nil ? 0 : 1) + (selectedTopics.isEmpty ? 0 : 1)
    }

    var filteredDiscussions: [Discussion] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return discussions }
        return discussions.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.body.localizedCaseInsensitiveContains(query)
                || ($0.company?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func bootstrap() async {
        // Fire identity creation/lookup once up front — later screens (compose, like, comment)
        // all need DeviceIdentity.deviceID regardless, but resolving the real username here
        // means the feed can show "posting as <username>" context immediately rather than
        // only discovering it lazily on first post.
        identity = try? await CommunityAPI.identity()
        async let followed = try? CommunityAPI.followedCompanies()
        async let saved = try? CommunityAPI.savedDiscussionIDs()
        followedCompanies = Set(await followed ?? [])
        savedDiscussionIDs = Set(await saved ?? [])
        await load()
    }

    func load() async {
        // Following tab with nothing followed yet would otherwise hit the backend with an
        // empty companies filter, which (by design, see list_discussions) means "no company
        // filter at all" and would show the WHOLE feed — exactly the wrong result for
        // "Following" with zero follows. Short-circuit locally instead of letting that happen.
        if feedTab == .following, followedCompanies.isEmpty {
            discussions = []
            state = .loaded
            return
        }
        state = .loading
        do {
            discussions = try await CommunityAPI.discussions(
                category: selectedCategory,
                sort: sort,
                companies: feedTab == .following ? Array(followedCompanies) : [],
                topics: selectedTopics.map(\.rawValue)
            )
            state = .loaded
        } catch {
            state = .failed("Couldn't reach the backend. Is it running on 127.0.0.1:8000?")
        }
    }

    func toggleLike(_ discussion: Discussion) async {
        guard let index = discussions.firstIndex(where: { $0.id == discussion.id }) else { return }
        // Optimistic update — matches the standing pattern in DiscoverView's SavedJob
        // like-toggle (instant UI feedback, not waiting on a round-trip for a reversible
        // action), reverted if the request actually fails.
        var updated = discussions[index]
        let wasLiked = updated.likedByMe
        updated.likesCount += wasLiked ? -1 : 1
        updated.likedByMe = !wasLiked
        discussions[index] = updated
        do {
            _ = try await CommunityAPI.toggleLike(discussionID: discussion.id)
        } catch {
            discussions[index] = discussion
        }
    }

    func toggleSave(_ discussion: Discussion) async {
        guard let index = discussions.firstIndex(where: { $0.id == discussion.id }) else { return }
        let original = discussions[index]
        var updated = original
        updated.savedByMe = !original.savedByMe
        discussions[index] = updated
        if updated.savedByMe {
            savedDiscussionIDs.insert(discussion.id)
        } else {
            savedDiscussionIDs.remove(discussion.id)
        }
        do {
            _ = try await CommunityAPI.toggleSave(discussionID: discussion.id)
        } catch {
            discussions[index] = original
            if original.savedByMe { savedDiscussionIDs.insert(discussion.id) } else { savedDiscussionIDs.remove(discussion.id) }
        }
    }

    func toggleFollow(company: String) async {
        let wasFollowing = followedCompanies.contains(company)
        if wasFollowing {
            followedCompanies.remove(company)
        } else {
            followedCompanies.insert(company)
        }
        do {
            _ = try await CommunityAPI.toggleFollowCompany(company)
        } catch {
            if wasFollowing { followedCompanies.insert(company) } else { followedCompanies.remove(company) }
        }
        if feedTab == .following {
            await load()
        }
    }

    func createDiscussion(category: DiscussionCategory, company: String?, title: String, body: String, topics: [String]) async throws {
        let created = try await CommunityAPI.createDiscussion(category: category, company: company, title: title, body: body, topics: topics)
        discussions.insert(created, at: 0)
    }
}
