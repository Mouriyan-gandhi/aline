import SwiftUI

// MARK: - Opportunity Model (Section 4 & 5 of Product Guide)
public struct Opportunity: Identifiable, Hashable {
    public let id: String
    public let companyName: String
    public let companySymbol: String // SF Symbol name or brand icon representation
    public let roleTitle: String
    public let location: String
    public let opportunityType: OpportunityType
    public let workMode: WorkMode
    public let salaryRange: String
    public let experienceYears: String
    public let eligibleGradYears: String
    public let matchScore: Int // Labeled as Match/Fit percentage
    public let recency: String
    public let cardColor: Color
    public var isLiked: Bool
    public var isApplied: Bool
    public var applicationDate: String?
    public let externalCareersURL: String

    // Detail Tabs Content
    public let aboutRole: String
    public let minimumQualifications: [String]
    public let preferredQualifications: [String]
    public let applicantTips: [String]
    public let responsibilities: [String]
    public let skills: [String]
    
    // Resume Match Insights
    public let detectedKeywords: [String]
    public let missingKeywords: [MissingKeyword]

    public enum OpportunityType: String, CaseIterable, Codable {
        case internship = "Internship"
        case fullTime = "Full-Time"
        case contract = "Contract"
    }

    public enum WorkMode: String, CaseIterable, Codable {
        case onSite = "On-Site"
        case hybrid = "Hybrid"
        case remote = "Remote"
    }
}

public struct MissingKeyword: Identifiable, Hashable {
    public var id: String { keyword }
    public let keyword: String
    public let recommendation: String
    public let placeholderTemplate: String
}

// MARK: - Mock Dataset for Discover Feed (130+ Opportunities)
public extension Opportunity {
    static var samples: [Opportunity] {
        return dataset
    }
}

