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

public extension Opportunity {
    // Dynamic Match Score Badging Colors
    // > 85: Green | 60-85: Yellow | < 60: Red
    var matchBadgeForegroundColor: Color {
        if matchScore > 85 {
            return Color(red: 0.12, green: 0.58, blue: 0.30)
        } else if matchScore >= 60 {
            return Color(red: 0.70, green: 0.48, blue: 0.05)
        } else {
            return Color(red: 0.85, green: 0.20, blue: 0.22)
        }
    }

    var matchBadgeBackgroundColor: Color {
        if matchScore > 85 {
            return Color(red: 0.88, green: 0.96, blue: 0.90)
        } else if matchScore >= 60 {
            return Color(red: 0.99, green: 0.95, blue: 0.80)
        } else {
            return Color(red: 0.99, green: 0.88, blue: 0.88)
        }
    }

    // Parsed recency in minutes for chronological sorting & filtering
    var recencyInMinutes: Int {
        let text = recency.lowercased().trimmingCharacters(in: .whitespaces)
        if text.contains("just now") || text.isEmpty {
            return 0
        }
        if text.contains("m ago") {
            let num = Int(text.replacingOccurrences(of: "m ago", with: "").trimmingCharacters(in: .whitespaces)) ?? 10
            return num
        }
        if text.contains("h ago") {
            let num = Int(text.replacingOccurrences(of: "h ago", with: "").trimmingCharacters(in: .whitespaces)) ?? 1
            return num * 60
        }
        if text.contains("d ago") {
            let num = Int(text.replacingOccurrences(of: "d ago", with: "").trimmingCharacters(in: .whitespaces)) ?? 1
            return num * 1440
        }
        if text.contains("w ago") {
            let num = Int(text.replacingOccurrences(of: "w ago", with: "").trimmingCharacters(in: .whitespaces)) ?? 1
            return num * 10080
        }
        return 99999
    }
}

