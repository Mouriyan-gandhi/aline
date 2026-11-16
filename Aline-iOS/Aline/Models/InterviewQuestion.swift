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

