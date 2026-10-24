import SwiftUI

// MARK: - Interview Preparation Models (Section 9 of Product Guide)
public enum QuestionTopic: String, CaseIterable, Codable {
    case dsa = "Arrays & Data Structures"
    case behavioral = "HR & Behavioural"
    case systemDesign = "System Design"
    case dbms = "DBMS & SQL"
    case os = "Operating Systems"
    case networking = "Computer Networks"

    public var iconName: String {
        switch self {
        case .dsa: return "square.stack.3d.down.right.fill"
        case .behavioral: return "person.2.wave.2.fill"
        case .systemDesign: return "network"
        case .dbms: return "cylinder.split.1x2.fill"
        case .os: return "cpu.fill"
        case .networking: return "antenna.radiowaves.left.and.right"
        }
    }
}

public struct InterviewQuestion: Identifiable, Hashable {
    public let id: String
    public let questionText: String
    public let topic: QuestionTopic
    public let companyName: String?
    public let role: String?
    public let difficulty: String
    public var upvotesCount: Int
    public var isUpvoted: Bool
    public var isSaved: Bool
    public let hint: String
    public let approach: String
    public let timeComplexity: String?
    public let spaceComplexity: String?
    public let isCommunityReported: Bool
}

public extension InterviewQuestion {
    static let samples: [InterviewQuestion] = [
        InterviewQuestion(
            id: "q-1",
            questionText: "Tell me about a time you had a strong technical disagreement with a teammate. How did you resolve it?",
            topic: .behavioral,
            companyName: "Google",
            role: "Software Engineer Intern",
            difficulty: "Behavioral",
            upvotesCount: 42,
            isUpvoted: false,
            isSaved: true,
            hint: """
            Choose a genuine technical disagreement from a course project or internship. Focus on active listening, evaluating trade-offs objectively with benchmarks/data, and committing fully to the team's shared outcome.
            """,
            approach: """
            Use the STAR framework (aim for a 1.5–2 minute verbal answer):

            • Situation: In our distributed systems project, my teammate and I disagreed on whether to use WebSocket vs. HTTP Long-Polling for real-time notifications.
            • Task: We needed to ensure sub-50ms latency while keeping server memory within free-tier tier limits.
            • Action: Rather than arguing subjective opinions, I proposed writing a 30-minute prototype script to measure memory footprint under 500 simulated connections. The data showed WebSockets used 40% less CPU overhead.
            • Result: My teammate agreed with the benchmark data, and our project delivered a fluid user experience without dropped connections.
            """,
            timeComplexity: nil,
            spaceComplexity: nil,
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-2",
            questionText: "Find all duplicate elements in an unsorted array where duplicates must be reported in the order of their first appearance.",
            topic: .dsa,
            companyName: "Google",
            role: "Software Engineer Intern",
            difficulty: "Medium",
            upvotesCount: 88,
            isUpvoted: true,
            isSaved: true,
            hint: """
            Remember previously seen values using fast membership checks. Ensure that each duplicate is appended to the result list only once upon second occurrence, without mutating the input array.
            """,
            approach: """
            Algorithm Walkthrough:
            1. Maintain two HashSets: 'seen' to record elements encountered so far, and 'reported' to track duplicates already added.
            2. Iterate through each number in the input array.
            3. If 'seen' already contains the element and it is not yet in 'reported', append the element to an ordered results list and insert it into 'reported'.
            4. If the element is not in 'seen', insert it into 'seen'.
            5. Return the ordered results list.

            Edge Cases Considered:
            - Empty array or array with all unique elements (returns empty list).
            - Elements appearing 3+ times (handled by 'reported' set).
            - Negative numbers and zero.
            """,
            timeComplexity: "O(N) Time",
            spaceComplexity: "O(N) Auxiliary Space",
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-3",
            questionText: "Explain how database indexing works under the hood. Why is a B+ Tree preferred over a Hash Index or Binary Search Tree?",
            topic: .dbms,
            companyName: "Flipkart",
            role: "Backend Engineer",
            difficulty: "Medium",
            upvotesCount: 35,
            isUpvoted: false,
            isSaved: false,
            hint: """
            Consider disk I/O block reads, range query operations (`BETWEEN`, `>`, `<`), and tree height / fanout.
            """,
            approach: """
            Key Points to Cover:
            • B+ Trees have high fanout, meaning very low tree height (typically 3-4 levels for millions of records), minimizing costly disk seeks.
            • Leaf nodes in a B+ tree are linked sequentially in a doubly-linked list, enabling high-performance range scans.
            • Hash indexes are O(1) for point lookups but cannot execute range scans efficiently.
            • Standard BSTs can become unbalanced and store data at internal nodes, reducing cache line utilization.
            """,
            timeComplexity: "O(log B N) Disk I/O",
            spaceComplexity: "O(N) Index Table",
            isCommunityReported: false
        )
    ]
}
