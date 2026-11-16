import SwiftUI

/// Codable mirror of `ResumeDocument` — what's stored on the backend (`/resumes`) for each
/// document. ResumeDocument itself carries a SwiftUI `Color` and isn't Codable, so the card
/// color travels as an index into `ResumeRecord.cardPalette`.
struct ResumeRecord: Codable, Hashable {
    struct Education: Codable, Hashable {
        var id: String
        var institution: String
        var degree: String
        var period: String
        var location: String
        var details: String
    }

    struct Experience: Codable, Hashable {
        var id: String
        var company: String
        var role: String
        var period: String
        var location: String
        var bullets: [String]
    }

    struct Project: Codable, Hashable {
        var id: String
        var title: String
        var techStack: String
        var bullets: [String]
    }

    struct SkillLine: Codable, Hashable {
        var label: String
        var values: String
    }

    var id: String
    var title: String
    var fileName: String
    var uploadDate: String
    var lastModifiedDate: String
    var fileSize: String
    var isDefault: Bool
    var template: String
    var cardColorIndex: Int
    var targetCompany: String?
    var targetCompanySymbol: String?
    var matchScore: Int?
    var optimizationCount: Int
    var summary: String
    var experiences: [Experience]
    var projects: [Project]
    var skills: [String]
    var education: [Education]
    var achievements: [String]
    var secondPageSections: [String]?
    var skillLines: [SkillLine]?
    var softSkills: [String]?
    var isLinkedToProfile: Bool?
    /// When the document was last saved, for "Modified …" labels — ISO 8601.
    var modifiedAt: String?

    static let cardPalette: [Color] = [
        AlineTheme.cardSkyBlue, AlineTheme.cardYellow, AlineTheme.cardPeach,
        AlineTheme.cardMint, AlineTheme.cardLavender, AlineTheme.cardCoral,
    ]

    init(_ resume: ResumeDocument) {
        id = resume.id
        title = resume.title
        fileName = resume.fileName
        uploadDate = resume.uploadDate
        lastModifiedDate = resume.lastModifiedDate
        fileSize = resume.fileSize
        isDefault = resume.isDefault
        template = resume.selectedTemplate.rawValue
        cardColorIndex = Self.cardPalette.firstIndex(of: resume.cardColor) ?? 0
        targetCompany = resume.targetCompany
        targetCompanySymbol = resume.targetCompanySymbol
        matchScore = resume.matchScore
        optimizationCount = resume.optimizationCount
        summary = resume.summary
        experiences = resume.experiences.map {
            Experience(id: $0.id, company: $0.company, role: $0.role, period: $0.period, location: $0.location, bullets: $0.bullets)
        }
        projects = resume.projects.map { Project(id: $0.id, title: $0.title, techStack: $0.techStack, bullets: $0.bullets) }
        skills = resume.skills
        education = resume.education.map {
            Education(id: $0.id, institution: $0.institution, degree: $0.degree, period: $0.period, location: $0.location, details: $0.details)
        }
        achievements = resume.achievements
        secondPageSections = resume.secondPageSections.map { $0.map(\.rawValue).sorted() }
        skillLines = resume.skillLines?.map { SkillLine(label: $0.label, values: $0.values) }
        softSkills = resume.softSkills
        isLinkedToProfile = resume.isLinkedToProfile
        modifiedAt = ISO8601DateFormatter().string(from: Date())
    }

    var document: ResumeDocument {
        var doc = ResumeDocument(
            id: id,
            title: title,
            fileName: fileName,
            uploadDate: uploadDate,
            lastModifiedDate: modifiedAt.flatMap(RelativeTime.modifiedLabel(isoString:)) ?? lastModifiedDate,
            fileSize: fileSize,
            isDefault: isDefault,
            selectedTemplate: ResumeDocument.ResumeTemplate(rawValue: template) ?? .standard,
            cardColor: Self.cardPalette[cardColorIndex % Self.cardPalette.count],
            targetCompany: targetCompany,
            targetCompanySymbol: targetCompanySymbol,
            matchScore: matchScore,
            optimizationCount: optimizationCount,
            summary: summary,
            experiences: experiences.map {
                ResumeExperience(id: $0.id, company: $0.company, role: $0.role, period: $0.period, location: $0.location, bullets: $0.bullets)
            },
            projects: projects.map { ResumeProject(id: $0.id, title: $0.title, techStack: $0.techStack, bullets: $0.bullets) },
            skills: skills,
            education: education.map {
                ResumeEducation(id: $0.id, institution: $0.institution, degree: $0.degree, period: $0.period, location: $0.location, details: $0.details)
            },
            achievements: achievements,
            secondPageSections: secondPageSections.map { Set($0.compactMap(ResumeSection.init(rawValue:))) },
            skillLines: skillLines?.map { ResumeSkillLine($0.label, $0.values) },
            softSkills: softSkills
        )
        doc.isLinkedToProfile = isLinkedToProfile ?? false
        return doc
    }
}

extension ResumeDocument {
    static func blank(id: String = UUID().uuidString) -> ResumeDocument {
        ResumeDocument(
            id: id, title: "", fileName: "Resume.pdf", uploadDate: "Just now", lastModifiedDate: "Just now",
            fileSize: "", isDefault: false, selectedTemplate: .standard, cardColor: ResumeRecord.cardPalette[0],
            targetCompany: nil, targetCompanySymbol: nil, matchScore: nil, optimizationCount: 0, summary: "",
            experiences: [], projects: [], skills: [], education: [], achievements: []
        )
    }

    /// A resume read from an uploaded PDF (see ResumeStructurer).
    init(parsed: ResumeProfile, fileName: String, fileSize: Int?) {
        self = .blank()
        let baseName = (fileName as NSString).deletingPathExtension
        title = parsed.fullName.isEmpty ? baseName : parsed.fullName
        self.fileName = baseName + ".pdf"
        if let fileSize {
            self.fileSize = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
        }
        summary = parsed.summary
        education = parsed.education.map {
            ResumeEducation(
                id: $0.id.uuidString, institution: $0.institution, degree: $0.degree,
                period: $0.dateRange, location: $0.location, details: $0.detail
            )
        }
        experiences = parsed.experience.map {
            ResumeExperience(
                id: $0.id.uuidString, company: $0.organization, role: $0.title,
                period: $0.dateRange, location: $0.location, bullets: $0.bullets
            )
        }
        projects = parsed.projects.map {
            ResumeProject(id: $0.id.uuidString, title: $0.name, techStack: $0.techStack, bullets: $0.bullets)
        }
        skills = parsed.skillCategories.flatMap(\.items)
        skillLines = parsed.skillCategories.isEmpty ? nil : parsed.skillCategories.map {
            ResumeSkillLine($0.label.isEmpty ? "Skills" : $0.label, $0.items.joined(separator: ", "))
        }
        achievements = parsed.achievements + parsed.certifications.map {
            [$0.name, $0.issuer].filter { !$0.isEmpty }.joined(separator: " — ")
        }
    }
}
