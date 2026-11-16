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

    public var totalCommentsCount: Int {
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
    static let currentUserAvatar = "avatar_beaver"

    /// Whether this post was written by the signed-in user
    var isByCurrentUser: Bool { authorName == DiscussionPost.currentUserName }

    static let samples: [DiscussionPost] = [
        DiscussionPost(
            id: "post-1",
            type: .interviewExperience,
            authorName: "rc_Falcon",
            isAnonymous: true,
            companyName: "Google",
            role: "SDE Intern",
            timeAgo: "2 hours ago",
            title: "My Google SDE intern interview experience",
            excerpt: "From the online assessment to the final round — here's what helped me prepare and what I wish I knew soon...",
            fullContent: """
            From the online assessment to the final round — here's what helped me prepare and what I wish I knew soon.

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
            likesCount: 124,
            isLiked: false,
            isSaved: false,
            comments: [
                DiscussionComment(
                    id: "com-1",
                    authorName: "algo_Panda",
                    authorRole: "CS Senior",
                    timeAgo: "1h ago",
                    text: "How tricky were the edge cases in Round 2 compared to LeetCode medium questions?",
                    likesCount: 8,
                    isLiked: true
                ),
                DiscussionComment(
                    id: "com-2",
                    authorName: "You",
                    authorRole: "3rd Year CS",
                    timeAgo: "Just now",
                    text: "Did you need to write full syntactically compilable code or was pseudo-code acceptable initially?",
                    likesCount: 2,
                    isLiked: false,
                    replies: [
                        DiscussionComment(
                            id: "com-2-r1",
                            authorName: "rc_Falcon",
                            authorRole: "SDE Intern",
                            timeAgo: "2h ago",
                            text: "Pseudo-code was fine for the first pass, but they asked me to turn the core loop into real code before time ran out.",
                            likesCount: 4,
                            isLiked: false,
                            avatarImageName: "avatar_otter"
                        )
                    ],
                    avatarImageName: DiscussionPost.currentUserAvatar
                )
            ],
            avatarImageName: "avatar_otter",
            interviewStage: "All 3 Rounds",
            applicationRoute: "Alumni Referral",
            currentStatus: "Offer Received"
        ),
        DiscussionPost(
            id: "post-2",
            type: .workExperience,
            authorName: "swift_Otter",
            isAnonymous: true,
            companyName: "Apple",
            role: "iOS Platform Intern",
            timeAgo: "4 hours ago",
            title: "What daily life looks like as an iOS Engineering Intern at Apple",
            excerpt: "From code reviews on Swift concurrency to weekly design critiques with human interface designers — the focus on craft and detail is remarkable...",
            fullContent: """
            The focus on craft and detail at Apple is remarkable. My day-to-day involved pairing with senior engineers on SwiftUI layout performance, running Instruments traces, and contributing to internal developer toolkits.

            Key advice for aspiring applicants:
            Master Swift memory semantics (ARC, strong/weak references) and cultivate an eye for fluid, tactile 120Hz interactions.
            """,
            topics: ["Apple", "iOS", "SwiftUI", "Work Culture"],
            likesCount: 98,
            isLiked: true,
            isSaved: true,
            comments: [
                DiscussionComment(
                    id: "com-3",
                    authorName: "rc_Falcon",
                    authorRole: "SDE Intern",
                    timeAgo: "3h ago",
                    text: "Did they ask much on CoreData or SwiftData during interviews?",
                    likesCount: 4,
                    isLiked: false,
                    replies: [
                        DiscussionComment(
                            id: "com-3-r1",
                            authorName: "You",
                            authorRole: "3rd Year CS",
                            timeAgo: "1h ago",
                            text: "Asking the same! I heard SwiftData basics came up in the second round.",
                            likesCount: 1,
                            isLiked: false,
                            avatarImageName: DiscussionPost.currentUserAvatar
                        )
                    ]
                )
            ],
            avatarImageName: "avatar_dog",
            timeAtCompany: "Summer Intern '26"
        ),
        DiscussionPost(
            id: "post-3",
            type: .recruitmentExperience,
            authorName: "binary_Fox",
            isAnonymous: true,
            companyName: "Amazon",
            role: "SDE-1",
            timeAgo: "1 day ago",
            title: "Amazon Off-Campus Hiring Timeline & Leadership Principles",
            excerpt: "Applied in August, completed OA in September, and final loop in October. Here is what you need to know about Amazon LP prep...",
            fullContent: """
            Amazon's Leadership Principles are tested in every single round. For every technical problem, prepare 2 concrete stories demonstrating 'Customer Obsession', 'Bias for Action', and 'Deliver Results'.
            """,
            topics: ["Amazon", "Recruitment", "Leadership Principles"],
            likesCount: 89,
            isLiked: false,
            isSaved: false,
            comments: [],
            avatarImageName: "avatar_fox",
            applicationRoute: "Off-Campus Portal",
            currentStatus: "Offer Received"
        ),
        DiscussionPost(
            id: "post-4",
            type: .interviewExperience,
            authorName: "algo_Panda",
            isAnonymous: true,
            companyName: "Microsoft",
            role: "SWE Intern",
            timeAgo: "1 day ago",
            title: "Microsoft SWE Internship: Round Details & Preparation Roadmap",
            excerpt: "Sharing my preparation roadmap for DP on trees and system design basics for junior candidates — 3 rounds breakdown inside...",
            fullContent: """
            Microsoft's rounds were very collaborative. Round 1 focused on tree traversals and dynamic programming. Round 2 was an API design question with concurrency considerations. Round 3 was an engineering manager conversation focusing on leadership in team projects.
            """,
            topics: ["Microsoft", "Interview Loop", "System Design", "DSA"],
            likesCount: 156,
            isLiked: false,
            isSaved: false,
            comments: [],
            avatarImageName: "avatar_panda",
            interviewStage: "3 Technical Rounds",
            applicationRoute: "University Portal",
            currentStatus: "Offer Accepted"
        ),
        DiscussionPost(
            id: "post-5",
            type: .generalDiscussion,
            authorName: "pixel_Corgi",
            isAnonymous: true,
            companyName: nil,
            role: "Product Intern",
            timeAgo: "2 days ago",
            title: "How to stand out in behavioral interviews using STAR + Metrics",
            excerpt: "Every story needs an unambiguous metric. Don't say 'improved performance' — say 'reduced p99 latency by 34%' so interviewers remember your impact.",
            fullContent: """
            Behavioral questions make or break L3/intern conversions. Frame every single project with:
            1. Situation & Constraints
            2. Task & Personal Ownership
            3. Action & Architectural Trade-offs
            4. Result quantified with numbers!
            """,
            topics: ["Behavioral", "Career Tips", "STAR Method"],
            likesCount: 210,
            isLiked: false,
            isSaved: true,
            comments: [],
            avatarImageName: "avatar_dog",
            currentStatus: "General Insight"
        ),
        DiscussionPost(
            id: "post-6",
            type: .interviewExperience,
            authorName: "cyber_Penguin",
            isAnonymous: true,
            companyName: "Netflix",
            role: "Backend Intern",
            timeAgo: "3 days ago",
            title: "Netflix Distributed Systems Interview: Real Questions & Takeaways",
            excerpt: "How we discussed cache invalidation, idempotent endpoints, and gRPC streaming during the technical loop...",
            fullContent: """
            Netflix technical discussions are deep. Be prepared to explain network partitions, how Raft consensus works at a high level, and how circuit breakers prevent cascading outages.
            """,
            topics: ["Netflix", "Distributed Systems", "gRPC", "Architecture"],
            likesCount: 178,
            isLiked: false,
            isSaved: false,
            comments: [],
            avatarImageName: "avatar_penguin",
            interviewStage: "Deep Dive Loop",
            applicationRoute: "Engineering Blog Referral",
            currentStatus: "Offer Received"
        ),
        DiscussionPost(
            id: "post-7",
            type: .interviewExperience,
            authorName: "matrix_Neo",
            isAnonymous: true,
            companyName: "Meta",
            role: "Product SWE Intern",
            timeAgo: "4 days ago",
            title: "Meta London SWE Intern Interview Breakdown (Graph Traversal & Hash Maps)",
            excerpt: "Detailed breakdown of the two 45-minute live coding rounds for Meta EMEA university graduate track...",
            fullContent: """
            Round 1 was all about topological sorting for task scheduling.
            Round 2 was LRU cache implementation and discussing lock contention when handling multiple reader threads.
            Interviewers were very encouraging and gave helpful hints when analyzing memory constraints.
            """,
            topics: ["Meta", "SWE", "Graphs", "Concurrency"],
            likesCount: 142,
            isLiked: false,
            isSaved: false,
            comments: [],
            avatarImageName: "avatar_tiger",
            interviewStage: "Technical Phone + Onsite",
            applicationRoute: "Campus Referral",
            currentStatus: "Offer Accepted"
        ),
        DiscussionPost(
            id: "post-8",
            type: .generalDiscussion,
            authorName: "tensor_Wizard",
            isAnonymous: true,
            companyName: "OpenAI",
            role: "Research Engineer",
            timeAgo: "5 days ago",
            title: "Cracking OpenAI Research Engineering loops: What they evaluate",
            excerpt: "Key insights on Triton kernels, memory bandwidth bottlenecks, and distributed training setups...",
            fullContent: """
            OpenAI looks for individuals who understand hardware limits: FLOPs utilization, tensor parallelism, and attention memory management. Review FlashAttention and KV-cache optimizations thoroughly.
            """,
            topics: ["OpenAI", "ML Infra", "CUDA", "LLMs"],
            likesCount: 265,
            isLiked: false,
            isSaved: false,
            comments: [],
            avatarImageName: "avatar_dragon",
            currentStatus: "Staff Insight"
        ),
        DiscussionPost(
            id: "post-9",
            type: .interviewExperience,
            authorName: "stripe_Hacker",
            isAnonymous: true,
            companyName: "Stripe",
            role: "Platform Engineer",
            timeAgo: "6 days ago",
            title: "Stripe Integration Round & Bug Squashing: How to prepare",
            excerpt: "Stripe's interview focuses on real codebases instead of LeetCode. Here is how to navigate the integration and bug squash rounds...",
            fullContent: """
            You get access to a real repository with documentation and test suites. Focus on:
            1. Writing clean, idiomatic code with error handling.
            2. Running unit tests frequently.
            3. Thinking out loud about API contracts and backward compatibility.
            """,
            topics: ["Stripe", "Practical Coding", "APIs", "System Design"],
            likesCount: 189,
            isLiked: false,
            isSaved: false,
            comments: [],
            avatarImageName: "avatar_otter",
            interviewStage: "Take-home + Live Debugging",
            currentStatus: "Offer Accepted"
        ),
        DiscussionPost(
            id: "post-10",
            type: .workExperience,
            authorName: "cuda_Beast",
            isAnonymous: true,
            companyName: "NVIDIA",
            role: "Systems Software Intern",
            timeAgo: "1 week ago",
            title: "Life as an NVIDIA Systems Software Intern in Santa Clara",
            excerpt: "Working on compiler backends for Blackwell architectures and collaborating with top hardware architects...",
            fullContent: """
            The intern mentorship at NVIDIA is unmatched. You get to contribute directly to LLVM backend optimizations and see your code run on the newest GPU architectures. Great team culture and food trucks!
            """,
            topics: ["NVIDIA", "Compilers", "Hardware", "Internship"],
            likesCount: 198,
            isLiked: false,
            isSaved: false,
            comments: [],
            avatarImageName: "avatar_owl",
            currentStatus: "Intern Experience"
        ),
        DiscussionPost(
            id: "post-11",
            type: .interviewExperience,
            authorName: "route_Rider",
            isAnonymous: true,
            companyName: "Uber",
            role: "Backend Engineer",
            timeAgo: "1 week ago",
            title: "Uber System Design Round: Designing Geospatial Indexing for Drivers",
            excerpt: "How I approached H3 hexagonal indexing and real-time pub/sub messaging for driver locations during Uber's L4 loop...",
            fullContent: """
            Key architectural components covered:
            - Uber H3 spatial index for tile lookups.
            - Kafka message partitions partitioned by city geohash.
            - In-memory Redis cluster for tracking real-time GPS pings.
            - Fallback mechanisms for connectivity drops.
            """,
            topics: ["Uber", "Geospatial", "System Design", "Kafka"],
            likesCount: 154,
            isLiked: false,
            isSaved: false,
            comments: [],
            avatarImageName: "avatar_raccoon",
            currentStatus: "Offer Accepted"
        ),
        // The signed-in user's own post, so "commented on your post" notifications open a real post
        DiscussionPost(
            id: "post-12",
            type: .generalDiscussion,
            authorName: "You",
            isAnonymous: true,
            timeAgo: "3 days ago",
            title: "How do you balance DSA prep with college coursework?",
            excerpt: "Third year CS here. Between assignments and labs I barely get an hour a day for LeetCode. How are you all planning your week?",
            fullContent: """
            Third year CS here. Between assignments and labs I barely get an hour a day for LeetCode. How are you all planning your week?

            Right now I do 2 problems on weekdays and a mock contest on Sunday, but I keep falling behind before internal exams. Would love to hear what schedule worked for you.
            """,
            topics: ["DSA", "Placements", "Time Management"],
            likesCount: 18,
            comments: [
                DiscussionComment(
                    id: "com-12-1",
                    authorName: "pixel_Corgi",
                    authorRole: "SDE Intern",
                    timeAgo: "20m ago",
                    text: "Block 45 minutes right after your last class and only do one pattern per week. Consistency beats volume.",
                    likesCount: 3,
                    isLiked: true,
                    avatarImageName: "avatar_dog"
                ),
                DiscussionComment(
                    id: "com-12-2",
                    authorName: "stripe_Hacker",
                    authorRole: "Final Year CS",
                    timeAgo: "3h ago",
                    text: "Skip contests during exam weeks and revise old problems instead. It keeps the streak without the stress.",
                    likesCount: 1,
                    isLiked: false,
                    avatarImageName: "avatar_otter"
                )
            ],
            avatarImageName: "avatar_beaver"
        )
    ]
}

public extension CompanyCommunity {
    static let samples: [CompanyCommunity] = [
        CompanyCommunity(
            id: "comp-google",
            name: "Google",
            symbol: "g.circle.fill",
            memberCount: "12.4K members",
            description: "Discussions on engineering, design & life at Google. Interview tips, culture, and career growth.",
            isFollowing: true
        ),
        CompanyCommunity(
            id: "comp-microsoft",
            name: "Microsoft",
            symbol: "window.badge.magnifyingglass",
            memberCount: "9.8K members",
            description: "From Azure to Xbox — conversations on teams, interviews, and navigating MSFT's culture.",
            isFollowing: true
        ),
        CompanyCommunity(
            id: "comp-amazon",
            name: "Amazon",
            symbol: "cart.fill",
            memberCount: "8.1K members",
            description: "Leadership principles, SDE prep, and real stories from Amazonians across all levels.",
            isFollowing: true
        ),
        CompanyCommunity(
            id: "comp-apple",
            name: "Apple",
            symbol: "apple.logo",
            memberCount: "15.2K members",
            description: "Discussions on iOS platform engineering, Swift concurrency, human interface design, and WWDC scholar tracks.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-meta",
            name: "Meta",
            symbol: "globe",
            memberCount: "11.6K members",
            description: "Distributed infra, PyTorch ML research, React ecosystem, and product engineering at scale.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-netflix",
            name: "Netflix",
            symbol: "play.rectangle.fill",
            memberCount: "7.3K members",
            description: "Chaos engineering, microservice architectures, high-leverage ownership, and culture of freedom.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-openai",
            name: "OpenAI",
            symbol: "sparkles",
            memberCount: "18.5K members",
            description: "LLM architectures, RLHF loops, agent engineering, and building frontier AI models.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-github",
            name: "GitHub",
            symbol: "chevron.left.forwardslash.chevron.right",
            memberCount: "14.1K members",
            description: "Developer tooling, GitHub Actions, Copilot platform engineering, and open source ecosystems.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-stripe",
            name: "Stripe",
            symbol: "creditcard.fill",
            memberCount: "10.9K members",
            description: "Global financial infrastructure, idempotent payments, developer APIs, and engineering velocity.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-nvidia",
            name: "NVIDIA",
            symbol: "cpu.fill",
            memberCount: "16.8K members",
            description: "CUDA optimizations, accelerated computing, TensorRT inference, and GPU system architecture.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-figma",
            name: "Figma",
            symbol: "paintpalette.fill",
            memberCount: "8.7K members",
            description: "WebAssembly canvas engines, multiplayer collaborative CRDTs, and design system engineering.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-swiggy",
            name: "Swiggy",
            symbol: "location.fill",
            memberCount: "6.5K members",
            description: "Hyperlocal dispatch routing, high-concurrency order management, and quick commerce engineering.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-zomato",
            name: "Zomato",
            symbol: "fork.knife",
            memberCount: "7.9K members",
            description: "Flash delivery optimization, Blinkit logistics, and resilient microservices at consumer scale.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-zepto",
            name: "Zepto",
            symbol: "bolt.fill",
            memberCount: "5.4K members",
            description: "10-minute grocery logistics, micro-warehouse inventory systems, and fast delivery dispatch.",
            isFollowing: false
        ),
        CompanyCommunity(
            id: "comp-uber",
            name: "Uber",
            symbol: "car.fill",
            memberCount: "11.2K members",
            description: "Dynamic pricing algorithms, marketplace matching, driver geospatial routing, and backend systems.",
            isFollowing: false
        )
    ]
}
