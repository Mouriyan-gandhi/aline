import SwiftUI

// MARK: - Community Models (Section 8 of Product Guide)
public enum DiscussionType: String, CaseIterable, Codable {
    case interviewExperience = "Interview Experience"
    case workExperience = "Work Experience"
    case recruitmentExperience = "Recruitment Experience"
    case generalDiscussion = "General Discussion"

    public var iconName: String {
        switch self {
        case .interviewExperience: return "person.badge.shield.checkmark.fill"
        case .workExperience: return "briefcase.fill"
        case .recruitmentExperience: return "clock.badge.checkmark.fill"
        case .generalDiscussion: return "bubble.left.and.text.bubble.right.fill"
        }
    }
}

public struct DiscussionComment: Identifiable, Hashable {
    public let id: String
    public let authorName: String
    public let authorRole: String
    public let timeAgo: String
    public let text: String
    public var likesCount: Int
    public var isLiked: Bool
    public var replies: [DiscussionComment]
    public var avatarImageName: String?

    public var resolvedAvatar: String {
        if let avatar = avatarImageName, !avatar.isEmpty {
            if DiscussionPost.allAvatars.contains(avatar) {
                return avatar
            }
            if avatar == "avatar_corgi" || avatar == "avatar_puppy" {
                return "avatar_dog"
            }
        }
        let pool = DiscussionPost.allAvatars
        let hash = abs(authorName.hashValue) % pool.count
        return pool[hash]
    }

    public init(
        id: String,
        authorName: String,
        authorRole: String = "",
        timeAgo: String,
        text: String,
        likesCount: Int = 0,
        isLiked: Bool = false,
        replies: [DiscussionComment] = [],
        avatarImageName: String? = nil
    ) {
        self.id = id
        self.authorName = authorName
        self.authorRole = authorRole
        self.timeAgo = timeAgo
        self.text = text
        self.likesCount = likesCount
        self.isLiked = isLiked
        self.replies = replies
        self.avatarImageName = avatarImageName
    }
}

public struct DiscussionPost: Identifiable, Hashable {
    public let id: String
    public let type: DiscussionType
    public let authorName: String
    public let isAnonymous: Bool
    public let companyName: String?
    public let role: String?
    public let timeAgo: String
    public let title: String
    public let excerpt: String
    public let fullContent: String
    public let topics: [String]
    public var likesCount: Int
    public var isLiked: Bool
    public var isSaved: Bool
    public var comments: [DiscussionComment]
    public var avatarImageName: String?
    public var sharesCount: Int
    /// The backend's comment count (replies included), used until the thread itself is loaded.
    public var serverCommentsCount: Int? = nil
    /// Whether `comments` holds the full thread from the backend rather than nothing yet.
    public var commentsLoaded: Bool = false

    public var totalCommentsCount: Int {
        if !commentsLoaded, let serverCommentsCount { return serverCommentsCount }
        var count = comments.count
        for comment in comments {
            count += comment.replies.count
        }
        return count
    }

    // Type-specific metadata
    public var interviewStage: String? // e.g. "All 3 Rounds"
    public var applicationRoute: String? // e.g. "Off-Campus / Referral"
    public var currentStatus: String? // e.g. "Offer Received"
    public var timeAtCompany: String? // e.g. "Intern (Summer '26)"

    public var authorDisplayWithCompany: String {
        if type == .generalDiscussion {
            return authorName
        }
        if let comp = companyName, !comp.isEmpty, comp != "Tech", comp != "None" {
            return "\(authorName) - \(comp)"
        } else {
            return authorName
        }
    }

    public static let allAvatars: [String] = [
        "avatar_fox", "avatar_owl", "avatar_cat", "avatar_dog", "avatar_bunny",
        "avatar_bear", "avatar_panda", "avatar_redpanda", "avatar_raccoon", "avatar_tiger",
        "avatar_lion", "avatar_koala", "avatar_sloth", "avatar_deer", "avatar_hedgehog",
        "avatar_squirrel", "avatar_otter", "avatar_beaver", "avatar_wolf", "avatar_penguin",
        "avatar_duck", "avatar_chicken", "avatar_frog", "avatar_turtle", "avatar_alligator",
        "avatar_whale", "avatar_dolphin", "avatar_seal", "avatar_octopus", "avatar_axolotl",
        "avatar_fish", "avatar_shark", "avatar_bee", "avatar_butterfly", "avatar_ladybug",
        "avatar_parrot", "avatar_toucan", "avatar_raven", "avatar_flamingo", "avatar_swan",
        "avatar_horse", "avatar_alpaca", "avatar_llama", "avatar_elephant", "avatar_giraffe",
        "avatar_monkey", "avatar_capybara", "avatar_hamster", "avatar_bat", "avatar_dragon"
    ]

    public var resolvedAvatar: String {
        if let avatar = avatarImageName, !avatar.isEmpty {
            if DiscussionPost.allAvatars.contains(avatar) {
                return avatar
            }
            // Map legacy / alternative names to valid assets
            if avatar == "avatar_corgi" || avatar == "avatar_puppy" {
                return "avatar_dog"
            }
        }
        let pool = DiscussionPost.allAvatars
        let hash = abs(id.hashValue) % pool.count
        return pool[hash]
    }

    public init(
        id: String,
        type: DiscussionType,
        authorName: String,
        isAnonymous: Bool = true,
        companyName: String? = nil,
        role: String? = nil,
        timeAgo: String,
        title: String,
        excerpt: String,
        fullContent: String,
        topics: [String] = [],
        likesCount: Int = 0,
        isLiked: Bool = false,
        isSaved: Bool = false,
        comments: [DiscussionComment] = [],
        avatarImageName: String? = nil,
        sharesCount: Int = 0,
        interviewStage: String? = nil,
        applicationRoute: String? = nil,
        currentStatus: String? = nil,
        timeAtCompany: String? = nil
    ) {
        self.id = id
        self.type = type
        self.authorName = authorName
        self.isAnonymous = isAnonymous
        self.companyName = companyName
        self.role = role
        self.timeAgo = timeAgo
        self.title = title
        self.excerpt = excerpt
        self.fullContent = fullContent
        self.topics = topics
        self.likesCount = likesCount
        self.isLiked = isLiked
        self.isSaved = isSaved
        self.comments = comments
        self.avatarImageName = avatarImageName
        self.sharesCount = sharesCount
        self.interviewStage = interviewStage
        self.applicationRoute = applicationRoute
        self.currentStatus = currentStatus
        self.timeAtCompany = timeAtCompany
    }
}

public struct CompanyCommunity: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let symbol: String
    public let memberCount: String
    public let description: String
    public var isFollowing: Bool
}

public extension DiscussionPost {
    /// The signed-in user's community identity: one name and one avatar, used on every post,
    /// comment and reply they make, and as their profile picture.
    static let currentUserName = "You"
    /// Assigned by the backend with the community identity (see CommunityViewModel.loadIdentity).
    nonisolated(unsafe) static var currentUserAvatar = "avatar_beaver"

    /// Whether this post was written by the signed-in user
    var isByCurrentUser: Bool { authorName == DiscussionPost.currentUserName }

}
