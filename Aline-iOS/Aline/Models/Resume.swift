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
    public var education: [ResumeEducation]
    public var achievements: [String]
    /// Sections printed on page 2; nil for single-page resumes
    public var secondPageSections: Set<ResumeSection>? = nil
    /// "Label: values" skill rows; nil keeps the template's default skills block
    public var skillLines: [ResumeSkillLine]? = nil
    /// Shown as a Soft Skills section when present
    public var softSkills: [String]? = nil
    /// Built from the profile: profile edits flow into it. Uploaded and tailored resumes keep
    /// their own content.
    public var isLinkedToProfile: Bool = false

    /// Sections on each printed page, in order; [nil] means one page with everything
    public var pageSections: [Set<ResumeSection>?] {
        guard let second = secondPageSections, !second.isEmpty else { return [nil] }
        return [Set(ResumeSection.allCases).subtracting(second), second]
    }

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

/// Blocks of a resume that can be placed on a page
public enum ResumeSection: String, CaseIterable, Hashable, Sendable {
    case header, summary, education, experience, projects, achievements, skills, softSkills
}

public struct ResumeSkillLine: Hashable, Sendable {
    public var label: String
    public var values: String
    public init(_ label: String, _ values: String) {
        self.label = label
        self.values = values
    }
}

public struct ResumeEducation: Identifiable, Hashable {
    public let id: String
    public var institution: String
    public var degree: String
    public var period: String
    public var location: String
    public var details: String
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
