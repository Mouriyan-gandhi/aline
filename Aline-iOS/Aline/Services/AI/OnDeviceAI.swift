import Foundation
import FoundationModels

/// Everything the app labels "AI": resume point rewrites, the resume assistant's general
/// advice, job tailoring rewrites and interview-question solutions — all on device through
/// Apple's Foundation Models framework, nothing sent to a server.
///
/// The model needs Apple Intelligence (supported iPhone, feature turned on, model downloaded).
/// When it isn't available every call returns nil and the caller says so plainly; nothing
/// here substitutes canned text that looks AI-written.
enum OnDeviceAI {
    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    /// Plain-language reason shown when `isAvailable` is false.
    static var unavailableMessage: String {
        switch SystemLanguageModel.default.availability {
        case .available:
            return ""
        case .unavailable(.deviceNotEligible):
            return "On-device AI needs an iPhone that supports Apple Intelligence, so I can't write suggestions on this device."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Turn on Apple Intelligence in Settings to use the AI assistant."
        case .unavailable(.modelNotReady):
            return "Apple Intelligence is still downloading its model. Try again in a little while."
        default:
            return "On-device AI isn't available right now."
        }
    }

    // MARK: Resume

    @Generable
    struct Rewrite {
        @Guide(description: "The rewritten resume text, one point, no surrounding quotes or labels.")
        var text: String
        @Guide(description: "One short sentence telling the user what changed and why.")
        var note: String
    }

    /// Rewrites one selected resume point following the user's instruction.
    static func rewrite(_ text: String, instruction: String, context: String? = nil) async -> Rewrite? {
        guard isAvailable else { return nil }
        let session = LanguageModelSession(instructions: """
        You edit single points on a student's or early-career engineer's resume. Follow the \
        user's instruction. Keep every fact the original states and never invent employers, \
        numbers, metrics, tools or results that aren't in the original or the instruction — if a \
        metric would help but none is given, keep the wording without one. Start with a strong \
        action verb, keep it to one or two lines, and write in the same tense as the original.
        """)
        var prompt = "Original point:\n\(text)\n\nInstruction: \(instruction)"
        if let context, !context.isEmpty { prompt += "\n\nTarget role context:\n\(context)" }
        return try? await session.respond(to: prompt, generating: Rewrite.self).content
    }

    /// Answers a question about the whole resume when no single point is selected.
    static func adviseOnResume(_ question: String, resumeText: String) async -> String? {
        guard isAvailable else { return nil }
        let session = LanguageModelSession(instructions: """
        You are a concise resume coach for students and early-career engineers. Answer the \
        user's question about their resume in at most five short bullet points. Refer to what \
        is actually in their resume; don't invent experience they don't have.
        """)
        let prompt = "Resume:\n\(String(resumeText.prefix(5000)))\n\nQuestion: \(question)"
        return try? await session.respond(to: prompt).content
    }

    /// Rewrites a resume point so a missing skill or keyword from a job shows, only as far as
    /// the original point supports it.
    static func tailor(point: String, toShow term: String, role: String, company: String) async -> Rewrite? {
        await rewrite(
            point,
            instruction: "Work in \"\(term)\" naturally if this point could honestly involve it. If it can't, return the point unchanged and say so in the note.",
            context: "\(role) at \(company)"
        )
    }

    // MARK: Interview questions

    @Generable
    struct InterviewSolution {
        @Guide(description: "A one or two sentence hint that nudges toward the solution without giving it away.")
        var hint: String
        @Guide(description: "The approach in a few sentences: the key idea and why it works.")
        var approach: String
        @Guide(description: "The full answer. For coding questions: explanation, then code, then time and space complexity. For design or behavioral questions: a structured answer.")
        var answer: String
    }

    static func solve(question: String, topic: String, company: String?, role: String?) async -> InterviewSolution? {
        guard isAvailable else { return nil }
        let session = LanguageModelSession(instructions: """
        You help students prepare for tech interviews. Give a correct, clear solution to the \
        interview question. If the question is ambiguous, state the assumption you made. Never \
        claim the solution was verified or tested.
        """)
        var prompt = "Topic: \(topic)\nQuestion: \(question)"
        if let company, !company.isEmpty { prompt += "\nAsked at: \(company)" }
        if let role, !role.isEmpty { prompt += "\nRole: \(role)" }
        return try? await session.respond(to: prompt, generating: InterviewSolution.self).content
    }
}
