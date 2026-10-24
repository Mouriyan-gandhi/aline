import SwiftUI

// MARK: - Resume & AI Tailoring Models (Section 6 of Product Guide)
public struct ResumeDocument: Identifiable, Hashable {
    public let id: String
    public var title: String
    public var fileName: String
    public var uploadDate: String
    public var lastModifiedDate: String
    public var fileSize: String
    public var isDefault: Bool
    public var selectedTemplate: ResumeTemplate
    public var cardColor: Color
    public var targetCompany: String?
    public var targetCompanySymbol: String?
    public var matchScore: Int?
    public var optimizationCount: Int
    public var summary: String
    public var experiences: [ResumeExperience]
    public var projects: [ResumeProject]
    public var skills: [String]

    public enum ResumeTemplate: String, CaseIterable, Codable {
        case standard = "Standard"
        case professional = "Professional"
        case modern = "Modern"

        public var description: String {
            switch self {
            case .standard: return "Clean and straightforward; general applications."
            case .professional: return "Structured and polished; corporate and tech roles."
            case .modern: return "Minimal and contemporary; tech and creative roles."
            }
        }
    }
}

public struct ResumeExperience: Identifiable, Hashable {
    public let id: String
    public var company: String
    public var role: String
    public var period: String
    public var location: String
    public var bullets: [String]
}

public struct ResumeProject: Identifiable, Hashable {
    public let id: String
    public var title: String
    public var techStack: String
    public var bullets: [String]
}

public struct AISuggestion: Identifiable, Hashable {
    public let id: String
    public let targetSection: String
    public let originalText: String
    public let suggestedText: String
    public let reason: String
    public let includesPlaceholders: Bool
    public var isApplied: Bool
}

public struct AIChatMessage: Identifiable, Hashable {
    public let id: String
    public let sender: Sender
    public let text: String
    public let timestamp: String
    public var targetKey: String? // e.g. "proj-0-bullet-0"
    public var originalText: String?
    public var suggestedRewrite: String?
    public var reason: String?
    public var isApplied: Bool

    public enum Sender: String, Hashable {
        case user
        case ai
        case system
    }

    public init(
        id: String = UUID().uuidString,
        sender: Sender,
        text: String,
        timestamp: String = "Just now",
        targetKey: String? = nil,
        originalText: String? = nil,
        suggestedRewrite: String? = nil,
        reason: String? = nil,
        isApplied: Bool = false
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
        self.targetKey = targetKey
        self.originalText = originalText
        self.suggestedRewrite = suggestedRewrite
        self.reason = reason
        self.isApplied = isApplied
    }
}

public extension ResumeDocument {
    static let samples: [ResumeDocument] = [
        ResumeDocument(
            id: "res-google",
            title: "Google SDE Tailored",
            fileName: "Google_SDE_Tailored.pdf",
            uploadDate: "Just now",
            lastModifiedDate: "Modified 5m ago",
            fileSize: "296 KB",
            isDefault: false,
            selectedTemplate: .standard,
            cardColor: AlineTheme.cardYellow,
            targetCompany: "Google",
            targetCompanySymbol: "g.circle.fill",
            matchScore: 88,
            optimizationCount: 3,
            summary: "Third-year Computer Science student passionate about distributed infrastructure and algorithmic optimization. Proficient in C++, Python, and Swift with proven track record in low-latency systems.",
            experiences: [
                ResumeExperience(
                    id: "exp-google-1",
                    company: "Campus Tech Labs",
                    role: "Software Engineering Intern",
                    period: "May 2026 – Jul 2026",
                    location: "Bengaluru, India",
                    bullets: [
                        "Architected an event-driven telemetry ingestion engine for 50+ IoT nodes; leveraged a concurrent Hash Map and worker queue to decrease query response latency by 32%.",
                        "Optimized PostgreSQL storage schemas and indexing strategies, scaling throughput to 10k events/sec.",
                        "Collaborated with senior engineers to implement continuous integration pipelines using GitHub Actions."
                    ]
                )
            ],
            projects: [
                ResumeProject(
                    id: "proj-google-1",
                    title: "Distributed Key-Value Store",
                    techStack: "C++, gRPC, Raft Consensus",
                    bullets: [
                        "Engineered a fault-tolerant replicated storage cluster utilizing Raft consensus algorithm with leader election and log compaction.",
                        "Implemented in-memory LRU cache with O(1) lookup latency, elevating read benchmark performance by 45%."
                    ]
                ),
                ResumeProject(
                    id: "proj-google-2",
                    title: "Aline Career Experience",
                    techStack: "Swift, SwiftUI, Combine",
                    bullets: [
                        "Crafted an interactive stacked card discovery UI with spring physics and missing keyword semantic diff analyzer."
                    ]
                )
            ],
            skills: [
                "C++", "Java", "Python", "Data Structures", "Algorithms", "Distributed Systems", "Linux", "Git"
            ]
        ),
        ResumeDocument(
            id: "res-apple",
            title: "Apple iOS Specialist",
            fileName: "Apple_iOS_Tailored.pdf",
            uploadDate: "Yesterday",
            lastModifiedDate: "Modified 2h ago",
            fileSize: "278 KB",
            isDefault: false,
            selectedTemplate: .modern,
            cardColor: AlineTheme.cardPeach,
            targetCompany: "Apple",
            targetCompanySymbol: "apple.logo",
            matchScore: 92,
            optimizationCount: 2,
            summary: "iOS Engineer focused on fluid micro-interactions, Swift concurrency, and tactile interface craft. Deep enthusiasm for Apple Human Interface Guidelines and ProMotion responsiveness.",
            experiences: [
                ResumeExperience(
                    id: "exp-apple-1",
                    company: "Mobile Design Guild",
                    role: "iOS Developer Lead",
                    period: "Jan 2026 – Present",
                    location: "Bengaluru, India",
                    bullets: [
                        "Developed 5+ production-grade SwiftUI modules achieving strict 120Hz scrolling without main thread hitching.",
                        "Integrated SF Symbols variable color effects and dynamic type accessibility across all views."
                    ]
                )
            ],
            projects: [
                ResumeProject(
                    id: "proj-apple-1",
                    title: "Aline iOS Client",
                    techStack: "Swift 6, SwiftUI, matchedGeometryEffect",
                    bullets: [
                        "Architected a custom card stack physics system with interactive gestures and fluid springs."
                    ]
                )
            ],
            skills: ["Swift", "SwiftUI", "iOS", "SF Symbols", "Instruments", "Combine"]
        ),
        ResumeDocument(
            id: "res-default",
            title: "Master Tech Resume",
            fileName: "Master_Aarav_Resume.pdf",
            uploadDate: "12 Oct 2026",
            lastModifiedDate: "1 day ago",
            fileSize: "284 KB",
            isDefault: true,
            selectedTemplate: .standard,
            cardColor: AlineTheme.cardMint,
            targetCompany: "General Roles",
            targetCompanySymbol: "briefcase.fill",
            matchScore: 95,
            optimizationCount: 1,
            summary: "Computer Science undergraduate (Class of 2028) with strong foundations in data structures, algorithms, object-oriented design, and mobile app architecture.",
            experiences: [
                ResumeExperience(
                    id: "exp-1",
                    company: "Campus Tech Labs",
                    role: "Software Engineering Intern",
                    period: "May 2026 – Jul 2026",
                    location: "Bengaluru, India",
                    bullets: [
                        "Built real-time telemetry dashboards processing sensor data from 50+ IoT nodes.",
                        "Optimized backend queries in PostgreSQL, improving dashboard load times by 32%."
                    ]
                )
            ],
            projects: [
                ResumeProject(
                    id: "proj-1",
                    title: "Aline Career Engine",
                    techStack: "Swift, SwiftUI, Combine",
                    bullets: [
                        "Architected an interactive stacked card vacancy explorer with spring animations.",
                        "Implemented missing keyword parser mapping job requirements to applicant experience."
                    ]
                )
            ],
            skills: [
                "Swift", "SwiftUI", "C++", "Java", "Python", "Data Structures", "Algorithms", "Git", "Linux"
            ]
        ),
        ResumeDocument(
            id: "res-barclays",
            title: "Barclays Enterprise",
            fileName: "Barclays_Enterprise_Resume.pdf",
            uploadDate: "20 Sep 2026",
            lastModifiedDate: "3 days ago",
            fileSize: "312 KB",
            isDefault: false,
            selectedTemplate: .professional,
            cardColor: AlineTheme.cardLavender,
            targetCompany: "Barclays",
            targetCompanySymbol: "building.columns.fill",
            matchScore: 84,
            optimizationCount: 0,
            summary: "CS Undergraduate focused on financial software systems, transactional consistency, distributed resilience, and database normalization.",
            experiences: [],
            projects: [],
            skills: ["Java", "Spring Boot", "SQL", "Algorithms", "Financial Systems"]
        )
    ]
}
