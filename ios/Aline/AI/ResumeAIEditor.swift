import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// The "Edit with AI" and JD-keyword-gap flows — both on-device, same framework as
/// ResumeParser/ResumeStructurer/JobSummarizer. The one rule that matters more here than
/// anywhere else in the app: this tool can make someone's resume say something false about
/// their own experience, which is a real harm, not just a wrong answer. Every instruction
/// below is built around never letting that happen silently — rewrites may only rephrase
/// what's already there, and keyword-gap suggestions must flag any unverified specific with
/// a bracketed placeholder for the person to confirm or fill in themselves, never assert it.
enum ResumeAIEditor {
    static func rewrite(selectedText: String, instruction: String) async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return try? await rewriteOnDevice(selectedText: selectedText, instruction: instruction)
        }
        #endif
        return nil
    }

    static func suggestMissingKeywords(
        profile: ResumeProfile, missingSkills: [String], jobTitle: String
    ) async -> [KeywordSuggestion] {
        guard !missingSkills.isEmpty else { return [] }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let result = try? await suggestKeywordsOnDevice(profile: profile, missingSkills: missingSkills, jobTitle: jobTitle) {
                return result
            }
        }
        #endif
        return []
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func rewriteOnDevice(selectedText: String, instruction: String) async throws -> String {
        guard SystemLanguageModel.default.availability == .available else {
            throw ResumeAIEditorError.modelUnavailable
        }
        let session = LanguageModelSession(instructions: """
        You rewrite one piece of resume text per the user's instruction. You may rephrase, \
        reorder, tighten, or restructure wording — you may NEVER add a fact, tool, metric, \
        outcome, or responsibility that was not already present in the original text, even if \
        it would make the bullet stronger. If the instruction asks for something the original \
        text doesn't support (e.g. "add measurable impact" but no number is present), rewrite \
        for clarity/strength within what's there and leave a bracketed placeholder like \
        "[add a specific metric]" rather than inventing a number. Return only the rewritten \
        text, nothing else — no preamble, no quotes around it.
        """)
        let response = try await session.respond(
            to: "Original text:\n\"\(selectedText)\"\n\nInstruction: \(instruction)"
        )
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @available(iOS 26.0, *)
    private static func suggestKeywordsOnDevice(
        profile: ResumeProfile, missingSkills: [String], jobTitle: String
    ) async throws -> [KeywordSuggestion] {
        guard SystemLanguageModel.default.availability == .available else {
            throw ResumeAIEditorError.modelUnavailable
        }
        let session = LanguageModelSession(instructions: """
        A candidate's resume is missing some keywords a target job posting asks for. For each \
        missing keyword, decide: does the candidate's EXISTING experience plausibly already \
        involve this (just under different wording), or is there no real evidence of it at \
        all? Only suggest a keyword if the candidate's existing bullets give genuine grounds \
        for it. Write a suggested bullet revision that naturally works the keyword in — using \
        the person's real existing experience as the basis. Where the exact specific detail \
        (a number, a precise tool version, a scale) isn't evidenced in the original text, use \
        a bracketed placeholder like "[specific detail]" instead of inventing one. Never claim \
        experience with a keyword that has no plausible connection to anything on the resume — \
        skip it instead. Say which existing resume entry (by its title/organization or project \
        name) each suggestion is for.
        """)

        let resumeSummary = profile.experience.map { "\($0.title) at \($0.organization): \($0.bullets.joined(separator: " "))" }
            .joined(separator: "\n")
            + "\n" + profile.projects.map { "\($0.name) (\($0.techStack)): \($0.bullets.joined(separator: " "))" }
            .joined(separator: "\n")

        let response = try await session.respond(
            to: """
            Target job title: \(jobTitle)
            Missing keywords: \(missingSkills.joined(separator: ", "))

            Candidate's existing experience and projects:
            \(String(resumeSummary.prefix(3000)))
            """,
            generating: KeywordSuggestionsModel.self
        )
        return response.content.suggestions.map {
            KeywordSuggestion(keyword: $0.keyword, suggestedBulletText: $0.suggestedBulletText, targetSectionHint: $0.targetSectionHint)
        }
    }
    #endif
}

enum ResumeAIEditorError: Error {
    case modelUnavailable
}

struct KeywordSuggestion: Identifiable, Equatable {
    var id = UUID()
    var keyword: String
    var suggestedBulletText: String
    var targetSectionHint: String
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct KeywordSuggestionModel {
    var keyword: String
    @Guide(description: "A revised bullet that naturally works the keyword into the candidate's real existing experience; use a bracketed placeholder for any unverified specific detail")
    var suggestedBulletText: String
    @Guide(description: "Which existing resume entry this revises, e.g. 'Experience: Software Engineering Intern at Flipkart'")
    var targetSectionHint: String
}

@available(iOS 26.0, *)
@Generable
struct KeywordSuggestionsModel {
    @Guide(description: "Only keywords with genuine grounding in the candidate's existing experience — omit any with no plausible connection")
    var suggestions: [KeywordSuggestionModel]
}
#endif
