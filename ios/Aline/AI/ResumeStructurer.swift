import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Resume text → the FULL structured ResumeProfile (contact/education/experience/projects/
/// skills) — same on-device pattern as ResumeParser, just a richer schema. Deliberately
/// separate from ResumeParser/CareerProfile rather than replacing it: CareerProfile already
/// powers the working onboarding + job-matching path, and this feature (the resume
/// dashboard/template system) has no reason to risk that by sharing a model. Two small
/// on-device extractors, one job each.
struct ResumeStructurer {
    static func structure(resumeText: String) async -> ResumeProfile {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let profile = try? await structureOnDevice(resumeText: resumeText) {
                return profile
            }
        }
        #endif
        return ResumeProfile.empty
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func structureOnDevice(resumeText: String) async throws -> ResumeProfile {
        guard SystemLanguageModel.default.availability == .available else {
            throw ResumeStructurerError.modelUnavailable
        }

        let session = LanguageModelSession(instructions: """
        You extract a resume's content into structured fields, verbatim. Only report what is \
        literally present in the text — never invent, infer, or embellish a company, title, \
        date, or bullet that isn't there. If a section is genuinely absent (no projects \
        section, no summary), return an empty list or empty string for it rather than \
        guessing. Preserve each bullet's original wording; do not rewrite or improve anything \
        here — this step is extraction only.
        """)

        let truncated = String(resumeText.prefix(6000)) // on-device context budget guard
        let response = try await session.respond(
            to: "Extract this resume's structured content:\n\n\(truncated)",
            generating: ExtractedResumeModel.self
        )
        return response.content.toResumeProfile()
    }
    #endif
}

enum ResumeStructurerError: Error {
    case modelUnavailable
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct ExtractedResumeModel {
    @Guide(description: "Full name as it appears at the top of the resume")
    var fullName: String
    @Guide(description: "Phone number, if present, exactly as written")
    var phone: String
    @Guide(description: "Email address, if present")
    var email: String
    @Guide(description: "LinkedIn URL or handle, if present")
    var linkedInURL: String
    @Guide(description: "GitHub URL or handle, if present")
    var githubURL: String
    @Guide(description: "Personal website/portfolio URL, if present")
    var portfolioURL: String
    @Guide(description: "A professional summary/objective line, ONLY if one literally appears — most resumes don't have one, leave empty rather than writing one")
    var summary: String
    var education: [ExtractedEducationModel]
    var experience: [ExtractedExperienceModel]
    var projects: [ExtractedProjectModel]
    var skillCategories: [ExtractedSkillCategoryModel]
    @Guide(description: "Certifications listed on the resume, if any — leave empty if none")
    var certifications: [ExtractedCertificationModel]
    @Guide(description: "Standalone achievement lines not already captured elsewhere — hackathon wins, publications, competition placements, awards. Leave empty if none.")
    var achievements: [String]
}

@available(iOS 26.0, *)
@Generable
struct ExtractedCertificationModel {
    var name: String
    @Guide(description: "Issuing organization, if stated, otherwise empty")
    var issuer: String
    @Guide(description: "Date earned, if stated, otherwise empty")
    var dateEarned: String
}

@available(iOS 26.0, *)
@Generable
struct ExtractedEducationModel {
    var institution: String
    var degree: String
    var location: String
    @Guide(description: "Date range as written, e.g. 'Aug 2022 – May 2026'")
    var dateRange: String
    @Guide(description: "GPA/CGPA or honors line, if present, otherwise empty")
    var detail: String
}

@available(iOS 26.0, *)
@Generable
struct ExtractedExperienceModel {
    var title: String
    var organization: String
    var location: String
    var dateRange: String
    @Guide(description: "Each bullet point under this role, verbatim")
    var bullets: [String]
}

@available(iOS 26.0, *)
@Generable
struct ExtractedProjectModel {
    var name: String
    @Guide(description: "Technologies listed for this project, e.g. 'React, Node.js, PostgreSQL'")
    var techStack: String
    var dateRange: String
    var bullets: [String]
}

@available(iOS 26.0, *)
@Generable
struct ExtractedSkillCategoryModel {
    @Guide(description: "Category label as grouped in the resume, e.g. 'Languages', 'Frameworks', 'Developer Tools'")
    var label: String
    var items: [String]
}

@available(iOS 26.0, *)
extension ExtractedResumeModel {
    func toResumeProfile() -> ResumeProfile {
        ResumeProfile(
            fullName: fullName,
            phone: phone,
            email: email,
            linkedInURL: linkedInURL,
            githubURL: githubURL,
            portfolioURL: portfolioURL,
            summary: summary,
            education: education.map {
                EducationEntry(institution: $0.institution, degree: $0.degree, location: $0.location, dateRange: $0.dateRange, detail: $0.detail)
            },
            experience: experience.map {
                ExperienceEntry(title: $0.title, organization: $0.organization, location: $0.location, dateRange: $0.dateRange, bullets: $0.bullets)
            },
            projects: projects.map {
                ProjectEntry(name: $0.name, techStack: $0.techStack, dateRange: $0.dateRange, bullets: $0.bullets)
            },
            skillCategories: skillCategories.map {
                SkillCategory(label: $0.label, items: $0.items)
            },
            certifications: certifications.map {
                CertificationEntry(name: $0.name, issuer: $0.issuer, dateEarned: $0.dateEarned)
            },
            achievements: achievements
        )
    }
}
#endif
