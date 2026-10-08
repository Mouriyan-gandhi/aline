import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// JD → structured summary, on-device — same AI usage map entry as ResumeParser (one
/// document, fits the on-device context budget once truncated), and the same reason it
/// exists: per the user's explicit direction, the real listing text should never be dumped
/// raw into the app. It passes through the Foundation Models framework first, and what the
/// job detail screen shows is four short, scannable sections (overview, requirements,
/// responsibilities, skills), not a wall of JD prose.
struct JobSummarizer {
    static func summarize(job: Job) async -> JobSummaryResult {
        if let cached = await JobSummaryCache.shared.get(job.id) {
            return cached
        }

        let result = await resolve(job: job)
        await JobSummaryCache.shared.set(job.id, result)
        return result
    }

    private static func resolve(job: Job) async -> JobSummaryResult {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let summary = try? await summarizeOnDevice(description: job.description, title: job.title) {
                return JobSummaryResult(
                    overview: summary.overview,
                    requirements: summary.requirements,
                    responsibilities: summary.responsibilities,
                    // Prefer the model's own skills read when it found any — it's reading
                    // the full JD prose, not just a keyword vocabulary, so it can catch
                    // skills the deterministic extractor's fixed list doesn't know about.
                    // Falls back to the backend's extracted_skills (always present,
                    // deterministic) rather than an empty block.
                    skills: summary.skills.isEmpty ? job.extractedSkills : summary.skills
                )
            }
        }
        #endif
        return fallback(job: job)
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func summarizeOnDevice(description: String, title: String) async throws -> JobSummaryModel {
        guard SystemLanguageModel.default.availability == .available else {
            throw JobSummarizerError.modelUnavailable
        }
        guard !description.isEmpty else {
            throw JobSummarizerError.noDescription
        }

        let session = LanguageModelSession(instructions: """
        You summarize a real job posting into four short, scannable sections for someone \
        deciding whether to apply. Only report what's actually stated in the posting — never \
        invent requirements, responsibilities, or skills that aren't there. If a section \
        genuinely isn't covered in the text, return an empty list (or a short honest sentence \
        for the overview) rather than guessing or padding.
        """)

        let truncated = String(description.prefix(4000)) // on-device context budget guard
        let response = try await session.respond(
            to: "Summarize this job posting titled \"\(title)\":\n\n\(truncated)",
            generating: JobSummaryModel.self
        )
        return response.content
    }
    #endif

    /// Deterministic fallback — older device, Simulator without model support, user denied
    /// Apple Intelligence, or the model call failed. The app must still show something
    /// useful rather than a blank summary panel: the real description text stands in for
    /// "overview" (better an honest raw paragraph than a fabricated structured summary),
    /// requirements/responsibilities stay empty (we're not inventing a bad heuristic split
    /// just to fill them), and skills reuses the backend's already-reliable extraction.
    private static func fallback(job: Job) -> JobSummaryResult {
        JobSummaryResult(
            overview: job.description,
            requirements: [],
            responsibilities: [],
            skills: job.extractedSkills
        )
    }
}

enum JobSummarizerError: Error {
    case modelUnavailable
    case noDescription
}

/// Plain (non-@Generable) result type the rest of the app actually works with — keeps every
/// call site oblivious to whether a given summary came from the model or the fallback.
struct JobSummaryResult: Equatable {
    var overview: String
    var requirements: [String]
    var responsibilities: [String]
    var skills: [String]
}

actor JobSummaryCache {
    static let shared = JobSummaryCache()
    private var cache: [String: JobSummaryResult] = [:]

    func get(_ jobID: String) -> JobSummaryResult? { cache[jobID] }
    func set(_ jobID: String, _ result: JobSummaryResult) { cache[jobID] = result }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct JobSummaryModel {
    @Guide(description: "A 2-3 sentence plain-language summary of what this role actually is and who's hiring for it.")
    var overview: String

    @Guide(description: "Must-have requirements literally stated in the posting (education, years of experience, specific qualifications) — not general skills, those go in the skills list.")
    var requirements: [String]

    @Guide(description: "What the person will actually do day-to-day in this role, as stated in the posting.")
    var responsibilities: [String]

    @Guide(description: "Technical skills/technologies/tools mentioned in the posting, e.g. Python, Kubernetes, React.")
    var skills: [String]
}
#endif
