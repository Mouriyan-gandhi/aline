import SwiftUI

// MARK: - Interview Preparation Models
public enum QuestionTopic: String, CaseIterable, Codable, Hashable, Identifiable {
    case dsa = "Array & DSA"
    case systemDesign = "System Design"
    case coreCS = "Core CS"
    case dbms = "Databases"
    case networking = "Networking"
    case behavioral = "Behavioral"
    case os = "Operating Systems"
    case aiMl = "AI & ML"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .dsa: return "chevron.left.forwardslash.chevron.right"
        case .systemDesign: return "square.stack.3d.up.fill"
        case .coreCS: return "cpu.fill"
        case .dbms: return "cylinder.split.1x2.fill"
        case .networking: return "wifi"
        case .behavioral: return "heart.text.square.fill"
        case .os: return "terminal.fill"
        case .aiMl: return "sparkles"
        }
    }

    public var iconColor: Color {
        switch self {
        case .dsa: return Color(red: 0.96, green: 0.55, blue: 0.16)
        case .systemDesign: return Color(red: 0.18, green: 0.52, blue: 0.95)
        case .coreCS: return Color(red: 0.65, green: 0.32, blue: 0.88)
        case .dbms: return Color(red: 0.15, green: 0.68, blue: 0.42)
        case .networking: return Color(red: 0.08, green: 0.66, blue: 0.82)
        case .behavioral: return Color(red: 0.94, green: 0.35, blue: 0.48)
        case .os: return Color(red: 0.42, green: 0.42, blue: 0.88)
        case .aiMl: return Color(red: 0.92, green: 0.45, blue: 0.10)
        }
    }

    public var iconBgColor: Color {
        switch self {
        case .dsa: return Color(red: 1.0, green: 0.94, blue: 0.88)
        case .systemDesign: return Color(red: 0.89, green: 0.94, blue: 1.0)
        case .coreCS: return Color(red: 0.95, green: 0.90, blue: 1.0)
        case .dbms: return Color(red: 0.88, green: 0.97, blue: 0.92)
        case .networking: return Color(red: 0.88, green: 0.97, blue: 0.99)
        case .behavioral: return Color(red: 1.0, green: 0.92, blue: 0.94)
        case .os: return Color(red: 0.91, green: 0.91, blue: 0.99)
        case .aiMl: return Color(red: 1.0, green: 0.93, blue: 0.88)
        }
    }
}

public struct InterviewQuestion: Identifiable, Hashable, Codable {
    public let id: String
    public let questionText: String
    public let topic: QuestionTopic
    public let companyName: String?
    public let role: String?
    public let difficulty: String
    public var upvotesCount: Int
    public var isUpvoted: Bool
    public var isSaved: Bool
    public let hint: String?
    public let approach: String?
    public let answer: String?
    public let aiGeneratedAnswer: String?
    public let hasAIGeneratedSolution: Bool
    public let timeComplexity: String?
    public let spaceComplexity: String?
    public let isCommunityReported: Bool

    public init(
        id: String,
        questionText: String,
        topic: QuestionTopic,
        companyName: String?,
        role: String?,
        difficulty: String,
        upvotesCount: Int,
        isUpvoted: Bool,
        isSaved: Bool,
        hint: String?,
        approach: String?,
        answer: String? = nil,
        aiGeneratedAnswer: String? = nil,
        hasAIGeneratedSolution: Bool = false,
        timeComplexity: String? = nil,
        spaceComplexity: String? = nil,
        isCommunityReported: Bool = true
    ) {
        self.id = id
        self.questionText = questionText
        self.topic = topic
        self.companyName = companyName
        self.role = role
        self.difficulty = difficulty
        self.upvotesCount = upvotesCount
        self.isUpvoted = isUpvoted
        self.isSaved = isSaved
        self.hint = hint
        self.approach = approach
        self.answer = answer
        self.aiGeneratedAnswer = aiGeneratedAnswer
        self.hasAIGeneratedSolution = hasAIGeneratedSolution
        self.timeComplexity = timeComplexity
        self.spaceComplexity = spaceComplexity
        self.isCommunityReported = isCommunityReported
    }
}

// MARK: - Last Visited Practice Session
public struct LastVisitedQuestionSession: Codable, Hashable {
    public let questionId: String
    public let questionText: String
    public let companyName: String?
    public let role: String?
    public let topic: QuestionTopic?
    public let questionsList: [InterviewQuestion]
    public let questionIndex: Int
    public let totalQuestions: Int
    public let timestamp: Date

    public init(
        questionId: String,
        questionText: String,
        companyName: String?,
        role: String?,
        topic: QuestionTopic?,
        questionsList: [InterviewQuestion],
        questionIndex: Int,
        totalQuestions: Int,
        timestamp: Date = Date()
    ) {
        self.questionId = questionId
        self.questionText = questionText
        self.companyName = companyName
        self.role = role
        self.topic = topic
        self.questionsList = questionsList
        self.questionIndex = questionIndex
        self.totalQuestions = totalQuestions
        self.timestamp = timestamp
    }
}

public extension InterviewQuestion {
    static let samples: [InterviewQuestion] = [
        InterviewQuestion(
            id: "q-1",
            questionText: "Find all duplicate elements in an unsorted array where duplicates must be reported in the order of their first appearance.",
            topic: .dsa,
            companyName: "Google",
            role: "Software Engineer",
            difficulty: "Medium",
            upvotesCount: 88,
            isUpvoted: true,
            isSaved: true,
            hint: "Remember previously seen values using fast membership checks. Ensure that each duplicate is appended to the result list only once upon second occurrence.",
            approach: """
            Algorithm Walkthrough:
            1. Maintain two HashSets: 'seen' to record elements encountered so far, and 'reported' to track duplicates already added.
            2. Iterate through each number in the input array.
            3. If 'seen' already contains the element and it is not yet in 'reported', append the element to an ordered results list and insert it into 'reported'.
            4. If the element is not in 'seen', insert it into 'seen'.
            5. Return the ordered results list.
            """,
            answer: """
            func findDuplicates(_ nums: [Int]) -> [Int] {
                var seen = Set<Int>()
                var reported = Set<Int>()
                var duplicates: [Int] = []
                
                for num in nums {
                    if seen.contains(num) {
                        if !reported.contains(num) {
                            duplicates.append(num)
                            reported.insert(num)
                        }
                    } else {
                        seen.insert(num)
                    }
                }
                return duplicates
            }
            """,
            hasAIGeneratedSolution: false,
            timeComplexity: "O(N) Time",
            spaceComplexity: "O(N) Space",
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-2",
            questionText: "Tell me about a time you had a strong technical disagreement with a teammate. How did you resolve it?",
            topic: .behavioral,
            companyName: "Google",
            role: "Software Engineer",
            difficulty: "Behavioral",
            upvotesCount: 42,
            isUpvoted: false,
            isSaved: true,
            hint: "Focus on active listening, evaluating trade-offs objectively with benchmarks/data, and committing fully to the team's shared outcome.",
            approach: """
            Use the STAR framework:
            • Situation: In our distributed systems project, my teammate and I disagreed on whether to use WebSocket vs. HTTP Long-Polling for real-time notifications.
            • Task: We needed to ensure sub-50ms latency while keeping server memory within free-tier limits.
            • Action: Rather than arguing subjective opinions, I proposed writing a 30-minute prototype script to measure memory footprint under 500 simulated connections. The benchmark showed WebSockets used 40% less CPU overhead.
            • Result: My teammate agreed with the benchmark data, and our project delivered a fluid user experience without dropped connections.
            """,
            answer: nil,
            aiGeneratedAnswer: """
            Recommended STAR Response Model:
            1. Setting: Name the project, your role, and the specific technical crossroad.
            2. Friction Point: State the colleague's perspective with empathy and valid merits.
            3. Resolution Mechanism: Explain the neutral decision-making tool you used (e.g. A/B benchmark, spike PR, RFC RFC doc).
            4. Outcome & Learning: Highlight that both of you maintained mutual trust and delivered on time.
            """,
            hasAIGeneratedSolution: true,
            timeComplexity: nil,
            spaceComplexity: nil,
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-3",
            questionText: "Design a distributed rate limiter that restricts clients to a maximum of 100 requests per minute across multiple API gateways.",
            topic: .systemDesign,
            companyName: "Microsoft",
            role: "Software Engineer",
            difficulty: "Hard",
            upvotesCount: 94,
            isUpvoted: false,
            isSaved: false,
            hint: "Consider sliding window log vs sliding window counter with Redis sorted sets (ZSET) using client IP/token as key.",
            approach: """
            Architectural Blueprint:
            • Ingestion: API Gateway proxies request to Rate Limiting Middleware.
            • Data Store: Centralized in-memory Redis cluster.
            • Algorithm: Sliding Window Log using Redis ZREMRANGEBYSCORE and ZADD inside a Lua script to ensure atomicity.
            • Fallback: If Redis latency exceeds 15ms, degrade gracefully to local token bucket in-memory at each gateway pod.
            """,
            answer: nil,
            aiGeneratedAnswer: """
            Redis Lua Script (Atomic Sliding Window):
            ```lua
            local key = KEYS[1]
            local now = tonumber(ARGV[1])
            local window = tonumber(ARGV[2])
            local limit = tonumber(ARGV[3])
            
            local clearBefore = now - window
            redis.call('ZREMRANGEBYSCORE', key, 0, clearBefore)
            local currentRequests = redis.call('ZCARD', key)
            
            if currentRequests < limit then
                redis.call('ZADD', key, now, now)
                redis.call('EXPIRE', key, window)
                return 1 -- Allowed
            else
                return 0 -- Throttled (HTTP 429)
            end
            ```
            """,
            hasAIGeneratedSolution: true,
            timeComplexity: "O(log N) per request",
            spaceComplexity: "O(K * R) where K is active users",
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-4",
            questionText: "Explain how database indexing works under the hood. Why is a B+ Tree preferred over a Hash Index or Binary Search Tree?",
            topic: .dbms,
            companyName: "Amazon",
            role: "Software Engineer",
            difficulty: "Medium",
            upvotesCount: 65,
            isUpvoted: false,
            isSaved: false,
            hint: "Consider disk I/O block reads, range query operations (`BETWEEN`, `>`, `<`), and tree height / fanout.",
            approach: """
            Key Points to Cover:
            • B+ Trees have high fanout, meaning very low tree height (3-4 levels for millions of records), minimizing costly disk seeks.
            • Leaf nodes in a B+ tree are linked sequentially in a doubly-linked list, enabling high-performance range scans.
            • Hash indexes are O(1) for point lookups but cannot execute range scans efficiently.
            • Standard BSTs can become unbalanced and store data at internal nodes, reducing cache line utilization.
            """,
            answer: """
            A B+ Tree stores all key-value records exclusively at the leaf level, linked by forward and backward pointers. Internal nodes solely store navigation routing keys. Because disk reads occur in 4KB/8KB pages, a B+ tree node can store hundreds of keys per block, keeping disk I/O to a minimal 3-4 block reads even for 100 million entries.
            """,
            hasAIGeneratedSolution: false,
            timeComplexity: "O(log_B N) Disk I/O",
            spaceComplexity: "O(N) Index Table",
            isCommunityReported: false
        ),
        InterviewQuestion(
            id: "q-5",
            questionText: "How does the TCP Three-Way Handshake establish a reliable connection? What is SYN flood and how is it mitigated?",
            topic: .networking,
            companyName: "Infosys",
            role: "DevOps Engineer",
            difficulty: "Medium",
            upvotesCount: 31,
            isUpvoted: false,
            isSaved: false,
            hint: "Detail SYN, SYN-ACK, and ACK steps with Sequence (SEQ) and Acknowledgment (ACK) numbers.",
            approach: """
            1. Client -> Server: SYN (seq = x)
            2. Server -> Client: SYN-ACK (seq = y, ack = x + 1)
            3. Client -> Server: ACK (ack = y + 1)
            
            SYN Flood Mitigation:
            • SYN Cookies: Server encodes connection state into the initial sequence number instead of allocating backlog memory until the final ACK arrives.
            • Backlog queue enlargement & timeout reduction.
            """,
            answer: nil,
            aiGeneratedAnswer: """
            Detailed Explanation:
            1. Client initiates connection by transmitting a SYN packet with random initial sequence number X.
            2. Server responds with SYN-ACK containing its own random sequence number Y and acknowledgment number X+1.
            3. Client sends back ACK with acknowledgment Y+1. The socket enters ESTABLISHED state.
            
            Security Defense:
            In a SYN flood, an attacker fills the embryonic connection queue with unanswered SYNs. Linux uses SYN Cookies (`tcp_syncookies = 1`), deferring socket allocation until the handshake completes.
            """,
            hasAIGeneratedSolution: true,
            timeComplexity: "1 RTT",
            spaceComplexity: "O(1) with SYN Cookies",
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-6",
            questionText: "What is the difference between Process and Thread? How does Context Switching differ between them?",
            topic: .coreCS,
            companyName: "Apple",
            role: "Software Engineer",
            difficulty: "Easy",
            upvotesCount: 77,
            isUpvoted: true,
            isSaved: false,
            hint: "Think about shared virtual memory address space vs isolated address space and TLB flushing.",
            approach: """
            Key Distinctions:
            • Memory: A process has its own isolated address space (code, data, heap). Threads within the same process share heap, code, and global variables, but have independent stacks and registers.
            • Cost of Context Switching: Thread context switch preserves the Translation Lookaside Buffer (TLB) cache. Process context switch requires changing page tables (CR3 register), flushing the TLB, resulting in higher cache misses.
            """,
            answer: """
            Process = An executing instance of a program with its own dedicated memory space, file descriptors, and security context.
            Thread = The smallest unit of execution scheduled by the OS kernel within a process.
            
            Context switch between processes requires invalidating CPU cache lines and virtual memory mappings (TLB). Context switch between threads in the same process only saves/restores CPU registers and stack pointer.
            """,
            hasAIGeneratedSolution: false,
            timeComplexity: "Thread: ~1-2µs | Process: ~10-20µs",
            spaceComplexity: "Thread: ~1MB Stack",
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-7",
            questionText: "Write a SQL query to find the 3rd highest salary in an Employee table without using the LIMIT or TOP keyword.",
            topic: .dbms,
            companyName: "Wells Fargo",
            role: "Data Analyst",
            difficulty: "Medium",
            upvotesCount: 52,
            isUpvoted: false,
            isSaved: true,
            hint: "Use DENSE_RANK() window function or a correlated subquery counting distinct higher salaries.",
            approach: """
            Two standard approaches:
            Method A (Modern SQL Window Function):
            `WITH Ranked AS (SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) as rnk FROM Employee) SELECT DISTINCT salary FROM Ranked WHERE rnk = 3;`
            
            Method B (Correlated Subquery):
            `SELECT DISTINCT e1.salary FROM Employee e1 WHERE 2 = (SELECT COUNT(DISTINCT e2.salary) FROM Employee e2 WHERE e2.salary > e1.salary);`
            """,
            answer: """
            WITH RankedSalaries AS (
                SELECT 
                    salary,
                    DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
                FROM Employee
            )
            SELECT DISTINCT salary
            FROM RankedSalaries
            WHERE salary_rank = 3;
            """,
            hasAIGeneratedSolution: false,
            timeComplexity: "O(N log N)",
            spaceComplexity: "O(N)",
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-8",
            questionText: "Given a list of transactional event timestamps, compute the 7-day rolling average of daily transaction volume.",
            topic: .dbms,
            companyName: "Wells Fargo",
            role: "Data Analyst",
            difficulty: "Medium",
            upvotesCount: 39,
            isUpvoted: false,
            isSaved: false,
            hint: "Group transactions by date first, then apply `AVG(daily_volume) OVER (ORDER BY trans_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)`.",
            approach: """
            Step 1: Aggregate daily count in a Common Table Expression (CTE).
            Step 2: Use window frame `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` to calculate rolling average.
            """,
            answer: nil,
            aiGeneratedAnswer: """
            ```sql
            WITH DailyAgg AS (
                SELECT 
                    DATE(transaction_time) AS tx_date,
                    COUNT(*) AS daily_volume
                FROM Transactions
                GROUP BY DATE(transaction_time)
            )
            SELECT 
                tx_date,
                daily_volume,
                ROUND(AVG(daily_volume) OVER (
                    ORDER BY tx_date 
                    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
                ), 2) AS rolling_7day_avg
            FROM DailyAgg
            ORDER BY tx_date DESC;
            ```
            """,
            hasAIGeneratedSolution: true,
            timeComplexity: "O(N log N)",
            spaceComplexity: "O(N)",
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-9",
            questionText: "How do you handle class imbalance in a fraud detection dataset where fraudulent cases comprise only 0.1% of transactions?",
            topic: .aiMl,
            companyName: "Meta",
            role: "AI/ML Engineer",
            difficulty: "Hard",
            upvotesCount: 68,
            isUpvoted: true,
            isSaved: true,
            hint: "Do not evaluate using Accuracy. Consider PR-AUC, Focal Loss, SMOTE, and Cost-Sensitive learning.",
            approach: """
            Structured Framework:
            1. Metric Alignment: Reject Accuracy; prioritize Precision-Recall AUC (PR-AUC), F-beta (with beta=2 to prioritize recall), and cost-weighted loss.
            2. Resampling: Stratified K-Fold, SMOTE (Synthetic Minority Over-sampling Technique) or Tomek links on training folds only.
            3. Algorithmic adjustments: Weighted cross-entropy / Focal Loss to down-weight easy negatives.
            4. Threshold Tuning: Calibrate probability threshold based on business financial trade-off (cost of false negative vs friction of false positive).
            """,
            answer: nil,
            aiGeneratedAnswer: """
            Comprehensive ML Strategy:
            • Data Level: SMOTE + ENN (resampling applied only inside cross-validation splits to avoid data leakage).
            • Model Level: LightGBM / XGBoost with `scale_pos_weight = 1000` or Focal Loss (FL(p_t) = -alpha * (1 - p_t)^gamma * log(p_t)).
            • Evaluation: Precision-Recall Curve (PR-AUC) and Expected Cost Matrix calculation.
            • Post-Processing: Isotonic Regression for well-calibrated probabilities.
            """,
            hasAIGeneratedSolution: true,
            timeComplexity: nil,
            spaceComplexity: nil,
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-10",
            questionText: "Design a URL shortening service like TinyURL. How do you handle 500 million new URLs per month and ensure collision-free key generation?",
            topic: .systemDesign,
            companyName: "Meta",
            role: "Software Engineer",
            difficulty: "Medium",
            upvotesCount: 104,
            isUpvoted: false,
            isSaved: false,
            hint: "Use Base62 encoding on a unique distributed 64-bit integer ID generated via Twitter Snowflake or pre-generated KGS (Key Generation Service).",
            approach: """
            Components:
            1. Key Generation: Base62 [a-zA-Z0-9]. A 7-character string allows 62^7 ≈ 3.5 trillion unique URLs.
            2. Conflict-free IDs: Pre-generated Key Generation Service (KGS) stores unused keys in memory ring buffer.
            3. Storage: NoSQL Key-Value store (Cassandra or DynamoDB) keyed by short hash.
            4. Caching: Redis cluster storing top 20% hot links with LRU eviction.
            5. Redirection: HTTP 302 Found (to track analytics) vs HTTP 301 Moved Permanently (reduces server load).
            """,
            answer: nil,
            aiGeneratedAnswer: """
            High-Level Architecture:
            • User Request -> Load Balancer -> Web App Cluster -> Redis Cache -> Cassandra DB.
            • Key Generation: KGS daemon precomputes random 7-character Base62 keys in batches, moving them from 'available' to 'allocated' tables to prevent duplicate collisions under parallel traffic.
            • Capacity Estimation: 500M / month = ~200 writes/sec, 2000 reads/sec. 100 bytes per URL = ~60GB/month.
            """,
            hasAIGeneratedSolution: true,
            timeComplexity: "O(1) Lookup",
            spaceComplexity: "60GB/month Storage",
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-11",
            questionText: "Given a string containing parentheses '(', ')', '{', '}', '[' and ']', determine if the input string is valid.",
            topic: .dsa,
            companyName: "TCS",
            role: "Software Engineer",
            difficulty: "Easy",
            upvotesCount: 45,
            isUpvoted: false,
            isSaved: false,
            hint: "Use a Stack. Push opening brackets and pop when encountering corresponding closing brackets.",
            approach: """
            1. Initialize an empty stack of characters.
            2. Map closing brackets to opening brackets: ')' -> '(', '}' -> '{', ']' -> '['.
            3. Iterate through characters in string.
            4. If char is a closing bracket, pop from stack and check if it matches the expected opening bracket.
            5. At end, stack must be empty for string to be valid.
            """,
            answer: """
            func isValid(_ s: String) -> Bool {
                var stack: [Character] = []
                let pairs: [Character: Character] = [")": "(", "}": "{", "]": "["]
                
                for ch in s {
                    if let opening = pairs[ch] {
                        if stack.popLast() != opening {
                            return false
                        }
                    } else {
                        stack.append(ch)
                    }
                }
                return stack.isEmpty
            }
            """,
            hasAIGeneratedSolution: false,
            timeComplexity: "O(N) Time",
            spaceComplexity: "O(N) Space",
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-12",
            questionText: "How would you prioritize feature roadmap requests when engineering, marketing, and sales have competing priorities?",
            topic: .behavioral,
            companyName: "Amazon",
            role: "Product Manager",
            difficulty: "Behavioral",
            upvotesCount: 58,
            isUpvoted: false,
            isSaved: true,
            hint: "Demonstrate structured prioritization frameworks like RICE (Reach, Impact, Confidence, Effort) or Kano Model.",
            approach: """
            1. Strategic Alignment: Evaluate each initiative against company OKRs (e.g., retention vs expansion).
            2. Objective Scoring: Score candidate features using RICE (Reach * Impact * Confidence / Effort).
            3. Stakeholder Alignment: Hold an interactive grooming workshop where engineering explains technical debt trade-offs and sales provides revenue risk data.
            4. Phased Delivery: Break big bets into MVPs to deliver quick feedback loops.
            """,
            answer: nil,
            aiGeneratedAnswer: """
            Recommended PM Answering Framework:
            • Core Philosophy: Customer obsession over internal loudest-voice politics.
            • Framework Applied: RICE scoring combined with strategic bucket allocation (e.g. 50% core customer needs, 30% revenue unlocks, 20% technical debt / stability).
            • Communication: Transparently publish the scoring criteria so teams whose features are deferred understand the analytical reasons and target subsequent milestones.
            """,
            hasAIGeneratedSolution: true,
            timeComplexity: nil,
            spaceComplexity: nil,
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-13",
            questionText: "What happens from a networking perspective when a client sends a secure HTTPS request to Google's API gateway?",
            topic: .networking,
            companyName: "Google",
            role: "Software Engineer",
            difficulty: "General",
            upvotesCount: 74,
            isUpvoted: false,
            isSaved: false,
            hint: "Trace the flow from DNS resolution, BGP Anycast routing, TCP three-way handshake, TLS 1.3 key exchange, to HTTP/2/3 request multiplexing at the reverse proxy.",
            approach: "Break down into layers: 1) DNS & Geo-resolution; 2) Anycast routing to Google Edge PoP; 3) TCP & TLS Handshake offloading; 4) Envoy/BFE reverse proxy forwarding to regional microservices.",
            answer: """
            Comprehensive Network Flow Walkthrough:
            1. DNS Resolution (DoH / 8.8.8.8) yields Google Anycast VIP.
            2. BGP Anycast routes packets to the topologically closest Google Edge Point of Presence (PoP).
            3. TLS 1.3 termination happens at the edge via Google Frontend (GFE).
            4. Request is forwarded over Google's private Andromeda SDN fiber backbone to the target service cluster.
            """,
            aiGeneratedAnswer: nil,
            hasAIGeneratedSolution: true,
            timeComplexity: "O(RTT) Handshake Latency",
            spaceComplexity: "O(1) Per Connection",
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-14",
            questionText: "Explain the differences between HTTP/2 multiplexing, HTTP/3 QUIC over UDP, and head-of-line blocking.",
            topic: .networking,
            companyName: "Google",
            role: "Software Engineer",
            difficulty: "General",
            upvotesCount: 62,
            isUpvoted: false,
            isSaved: false,
            hint: "Contrast TCP-level head-of-line blocking with application-level stream multiplexing, and explain why UDP enables independent QUIC packet streams.",
            approach: "1) HTTP/1.1 pipelining limitations; 2) HTTP/2 binary framing and TCP-layer HOL blocking when packet loss occurs; 3) HTTP/3 QUIC architecture running on UDP with independent packet-level stream delivery.",
            answer: """
            Key Differences & Architectural Analysis:
            • HTTP/2 solves application HOL blocking with binary framing multiplexing, but if a TCP packet drops, all streams stall (TCP HOL blocking).
            • HTTP/3 runs over QUIC (UDP), providing stream independence where packet loss on stream A does not block stream B.
            • QUIC integrates TLS 1.3 into its transport layer for 0-RTT connection establishment.
            """,
            aiGeneratedAnswer: nil,
            hasAIGeneratedSolution: true,
            timeComplexity: "O(1) Multiplexing",
            spaceComplexity: "O(S) where S is stream count",
            isCommunityReported: true
        ),
        InterviewQuestion(
            id: "q-15",
            questionText: "How does BGP anycast routing direct global user traffic to the closest Google edge points of presence?",
            topic: .networking,
            companyName: "Google",
            role: "Software Engineer",
            difficulty: "General",
            upvotesCount: 51,
            isUpvoted: false,
            isSaved: false,
            hint: "Consider how Autonomous Systems (AS15169) advertise identical IP prefixes across multiple worldwide data centers simultaneously.",
            approach: "1) Anycast concept: single IP advertised from hundreds of locations; 2) BGP path vector algorithm selects shortest AS-path; 3) Traffic routes to nearest geographic ingress; 4) Graceful failover if an edge PoP becomes unreachable.",
            answer: """
            Anycast Mechanism:
            • Google's ASN (AS15169) announces identical IP prefixes globally via BGP.
            • Intermediate ISP routers forward traffic along the lowest metric/shortest AS path.
            • Users automatically reach the nearest healthy Google edge node without client-side reconfiguration.
            """,
            aiGeneratedAnswer: nil,
            hasAIGeneratedSolution: true,
            timeComplexity: "Sub-second BGP convergence",
            spaceComplexity: "Global routing table entry",
            isCommunityReported: true
        )
    ]
}
