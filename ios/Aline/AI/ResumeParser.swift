import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device resume → structured fields, per the plan's AI usage map: this is the one place
/// Milestone 0 genuinely needs a model (a single user's own document, fits the on-device
/// context budget once we're just extracting from already-short resume text). Falls back to
/// deterministic keyword extraction when Foundation Models isn't available (older device,
/// Simulator without model support, or the user denied Apple Intelligence) — the app must
/// still work, per the plan's "AI must not be a hard dependency" principle (spec section 52).
struct ResumeParser {
    static func parse(resumeText: String) async -> CareerProfile {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let profile = try? await parseOnDevice(resumeText: resumeText) {
                return profile
            }
        }
        #endif
        return parseHeuristically(resumeText: resumeText)
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func parseOnDevice(resumeText: String) async throws -> CareerProfile {
        guard SystemLanguageModel.default.availability == .available else {
            throw ResumeParserError.modelUnavailable
        }

        let session = LanguageModelSession(instructions: """
        You extract structured facts from a resume. Only report skills, roles, and \
        education that literally appear in the text. Never invent or infer anything \
        not evidenced in the resume — this is an accuracy requirement, not a style one.
        """)

        let truncated = String(resumeText.prefix(4000)) // on-device context budget guard
        let response = try await session.respond(
            to: "Extract the technical skills, likely IT/software/AI job roles, and " +
                "education line from this resume. Resume:\n\n\(truncated)",
            generating: ExtractedResume.self
        )
        return CareerProfile(
            skills: response.content.skills,
            inferredRoles: response.content.likelyRoles,
            education: response.content.education,
            rawResumeText: resumeText
        )
    }
    #endif

    /// Deterministic fallback — same skill vocabulary concept as the backend's
    /// extract_skills, kept intentionally simple and honest rather than guessing.
    private static func parseHeuristically(resumeText: String) -> CareerProfile {
        let lowered = resumeText.lowercased()
        let foundSkills = SkillVocabulary.all.filter { lowered.contains($0.lowercased()) }

        var roles: [String] = []
        if foundSkills.contains(where: { ["Python", "Machine Learning", "PyTorch", "TensorFlow"].contains($0) }) {
            roles.append("ML Engineer")
        }
        if foundSkills.contains(where: { ["React", "JavaScript", "TypeScript", "HTML", "CSS"].contains($0) }) {
            roles.append("Frontend Engineer")
        }
        if foundSkills.contains(where: { ["FastAPI", "Django", "Flask", "Spring", "Node.js"].contains($0) }) {
            roles.append("Backend Engineer")
        }
        if roles.isEmpty {
            roles.append("Software Engineer")
        }

        return CareerProfile(skills: foundSkills, inferredRoles: roles, education: "", rawResumeText: resumeText)
    }
}

enum ResumeParserError: Error {
    case modelUnavailable
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct ExtractedResume {
    @Guide(description: "Technical skills literally mentioned in the resume, e.g. Python, React, AWS")
    var skills: [String]

    @Guide(description: "IT/software/AI job roles this person's background realistically fits, e.g. Backend Engineer")
    var likelyRoles: [String]

    @Guide(description: "The person's most recent/highest education line, e.g. 'B.Tech Computer Science, 2026'")
    var education: String
}
#endif

/// Shared with the backend's SKILL_VOCABULARY concept (backend/app/filters.py) so resume
/// skills and job-extracted skills are directly comparable strings in MatchEngine.
enum SkillVocabulary {
    static let all = [
        "Python", "Java", "JavaScript", "TypeScript", "Swift", "Kotlin", "C++", "C", "Go", "Rust",
        "React", "Angular", "Vue", "Node.js", "FastAPI", "Django", "Flask", "Spring", "Spring Boot",
        "AWS", "GCP", "Azure", "Docker", "Kubernetes", "SQL", "PostgreSQL", "MySQL", "MongoDB",
        "Redis", "Machine Learning", "Deep Learning", "TensorFlow", "PyTorch", "NLP",
        "Computer Vision", "Data Structures", "Algorithms", "REST API", "GraphQL", "CI/CD", "Git",
        "Linux", "Android", "iOS", "HTML", "CSS", "SwiftUI", "UIKit", "Spark", "Hadoop", "Kafka",
        "Terraform", "Jenkins", "GitHub Actions", "Microservices", "System Design", "DSA",
        "Pandas", "NumPy", "Scikit-learn", "LLM", "Generative AI", "GraphDB", "Elasticsearch",
    ]
}
