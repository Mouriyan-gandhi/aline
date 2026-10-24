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

    // Type-specific metadata
    public var interviewStage: String? // e.g. "All 3 Rounds"
    public var applicationRoute: String? // e.g. "Off-Campus / Referral"
    public var currentStatus: String? // e.g. "Offer Received"
    public var timeAtCompany: String? // e.g. "Intern (Summer '26)"
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
    static let samples: [DiscussionPost] = [
        DiscussionPost(
            id: "post-1",
            type: .interviewExperience,
            authorName: "Aarav K. (Anonymous)",
            isAnonymous: true,
            companyName: "Google",
            role: "Software Engineering Intern",
            timeAgo: "3h ago",
            title: "Google Summer '26 SDE Intern: My Complete 3-Round Experience",
            excerpt: "Detailed breakdown of the online assessment, data structures round (graphs & hash maps), and behavioral fitment...",
            fullContent: """
            Application Route:
            Applied via Google Careers with a referral from an alumnus. Received the OA link 3 weeks later.

            Round 1 — Online Assessment:
            2 coding questions (90 mins). Question 1 was a sliding window string manipulation problem. Question 2 was a dynamic programming grid traversal. Scored 100% on both test suites.

            Round 2 — Technical Interview (45 mins):
            Interviewer was an SDE-3 from the Cloud infrastructure team. Problem asked was to detect duplicate subtrees in a binary tree. Used post-order serialization with a hash map. Discussed time complexity O(N) and memory overhead.

            Round 3 — Behavioral & Googliness:
            Used the STAR framework throughout. The interviewer asked about a time I faced conflicting architectural priorities in a student hackathon. Be genuine and highlight collaborative decision making!
            """,
            topics: ["Google", "SDE Intern", "Graphs", "DSA", "STAR Method"],
            likesCount: 142,
            isLiked: false,
            isSaved: true,
            comments: [
                DiscussionComment(
                    id: "com-1",
                    authorName: "Dev P.",
                    authorRole: "CS Senior",
                    timeAgo: "2h ago",
                    text: "How tricky were the edge cases in Round 2 compared to LeetCode medium questions?",
                    likesCount: 5,
                    isLiked: false
                ),
                DiscussionComment(
                    id: "com-2",
                    authorName: "You",
                    authorRole: "3rd Year CS",
                    timeAgo: "Just now",
                    text: "Did you need to write full syntactically compilable code or was pseudo-code acceptable initially?",
                    likesCount: 0,
                    isLiked: false
                )
            ],
            interviewStage: "All 3 Rounds",
            applicationRoute: "Alumni Referral",
            currentStatus: "Offer Received"
        ),
        DiscussionPost(
            id: "post-2",
            type: .workExperience,
            authorName: "Priya S.",
            isAnonymous: false,
            companyName: "Apple",
            role: "iOS Platform Intern",
            timeAgo: "1d ago",
            title: "What daily life looks like as an iOS Engineering Intern at Apple",
            excerpt: "From code reviews on Swift concurrency to weekly design critiques with human interface designers...",
            fullContent: """
            The focus on craft and detail at Apple is remarkable. My day-to-day involved pairing with senior engineers on SwiftUI layout performance, running Instruments traces, and contributing to internal developer toolkits.

            Key advice for aspiring applicants:
            Master Swift memory semantics (ARC, strong/weak references) and cultivate an eye for fluid, tactile 120Hz interactions.
            """,
            topics: ["Apple", "iOS", "SwiftUI", "Work Culture"],
            likesCount: 98,
            isLiked: true,
            isSaved: false,
            comments: [],
            timeAtCompany: "Summer Intern '26"
        ),
        DiscussionPost(
            id: "post-3",
            type: .recruitmentExperience,
            authorName: "Rohan M.",
            isAnonymous: true,
            companyName: "Amazon",
            role: "SDE-1",
            timeAgo: "2d ago",
            title: "Amazon Off-Campus Hiring Timeline & Leadership Principles",
            excerpt: "Applied in August, completed OA in September, and final loop in October. Here is what you need to know...",
            fullContent: """
            Amazon's Leadership Principles are tested in every single round. For every technical problem, prepare 2 concrete stories demonstrating 'Customer Obsession', 'Bias for Action', and 'Deliver Results'.
            """,
            topics: ["Amazon", "Recruitment", "Leadership Principles"],
            likesCount: 67,
            isLiked: false,
            isSaved: false,
            comments: [],
            applicationRoute: "Off-Campus Portal",
            currentStatus: "Offer Received"
        )
    ]
}

public extension CompanyCommunity {
    static let samples: [CompanyCommunity] = [
        CompanyCommunity(
            id: "comp-google",
            name: "Google",
            symbol: "g.circle.fill",
            memberCount: "42.8k members",
            description: "Discussions, OA patterns, interview rounds, and intern experiences for Google roles worldwide.",
            isFollowing: true
        ),
        CompanyCommunity(
            id: "comp-apple",
            name: "Apple",
            symbol: "apple.logo",
            memberCount: "31.2k members",
            description: "Community for iOS, macOS, silicon engineering, and software development opportunities at Apple.",
            isFollowing: true
        ),
        CompanyCommunity(
            id: "comp-amazon",
            name: "Amazon",
            symbol: "cart.fill",
            memberCount: "54.1k members",
            description: "AWS cloud, retail systems, SDE hiring timelines, and Leadership Principle preparation.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-microsoft",
            name: "Microsoft",
            symbol: "window.badge.magnifyingglass",
            memberCount: "38.6k members",
            description: "Azure, Office, Developer Division, and Engage program internship accounts.",
            isFollowing: false
        )
    ]
}
