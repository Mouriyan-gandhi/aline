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
    /// `context` is the target role; `background` is the user's full profile and achievement
    /// gallery, which the model may draw facts from (and only from).
    static func rewrite(_ text: String, instruction: String, context: String? = nil, background: String? = nil) async -> Rewrite? {
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
        if let background, !background.isEmpty {
            prompt += "\n\nThe candidate's profile and achievements (facts you may use; nothing beyond these):\n\(String(background.prefix(2500)))"
        }
        return try? await session.respond(to: prompt, generating: Rewrite.self).content
    }

    /// Answers a question about the whole resume when no single point is selected.
    static func adviseOnResume(_ question: String, resumeText: String, background: String = "", targetRole: String? = nil) async -> String? {
        guard isAvailable else { return nil }
        let session = LanguageModelSession(instructions: """
        You are a concise resume coach for students and early-career engineers. Answer the \
        user's question about their resume in at most five short bullet points. Refer to what \
        is actually in their resume; don't invent experience they don't have.
        """)
        var prompt = "Resume:\n\(String(resumeText.prefix(4000)))"
        if !background.isEmpty { prompt += "\n\nEverything else on their profile and achievement gallery:\n\(String(background.prefix(2000)))" }
        if let targetRole { prompt += "\n\nThey are tailoring this resume for: \(targetRole)" }
        prompt += "\n\nQuestion: \(question)"
        return try? await session.respond(to: prompt).content
    }

    /// Rewrites a resume point so a missing skill or keyword from a job shows, only as far as
    /// the original point supports it.
    static func tailor(point: String, toShow term: String, role: String, company: String, background: String = "") async -> Rewrite? {
        await rewrite(
            point,
            instruction: "Work in \"\(term)\" naturally if this point or the candidate's profile shows they genuinely did it. If not, return the point unchanged and say so in the note.",
            context: "\(role) at \(company)",
            background: background
        )
    }

    /// A professional summary aimed at one role, built from the resume, profile and achievements.
    static func tailoredSummary(current: String, role: String, company: String, jobText: String, resumeText: String, background: String) async -> Rewrite? {
        guard isAvailable else { return nil }
        let session = LanguageModelSession(instructions: """
        You write a two or three sentence professional summary for a student or early-career \
        resume, aimed at one specific job. Use only facts from the resume, profile and \
        achievements given — no invented numbers, employers or skills. Lead with what makes \
        them a fit for this role.
        """)
        let prompt = """
        Target: \(role) at \(company)
        Job highlights:
        \(String(jobText.prefix(1500)))

        Current summary: \(current.isEmpty ? "(none)" : current)

        Resume:
        \(String(resumeText.prefix(2500)))

        Profile and achievements:
        \(String(background.prefix(2000)))
        """
        return try? await session.respond(to: prompt, generating: Rewrite.self).content
    }

    @Generable
    struct ProfileHighlights {
        @Guide(description: "Up to three items from the candidate's profile or achievement gallery that fit the job but are missing from this resume. Each: what it is and where to add it. Empty if there are none.", .count(0...3))
        var items: [String]
    }

    /// Profile/achievement items that suit the job but aren't on the selected resume.
    static func profileHighlights(role: String, company: String, jobText: String, resumeText: String, background: String) async -> [String]? {
        guard isAvailable, !background.isEmpty else { return nil }
        let session = LanguageModelSession(instructions: """
        You compare a resume with the candidate's full profile and achievement gallery and point \
        out experience, projects or achievements that are relevant to the target job but not on \
        the resume. Only mention items that really appear in the profile.
        """)
        let prompt = """
        Target: \(role) at \(company)
        Job highlights:
        \(String(jobText.prefix(1500)))

        Resume:
        \(String(resumeText.prefix(2500)))

        Full profile and achievements:
        \(String(background.prefix(2500)))
        """
        return try? await session.respond(to: prompt, generating: ProfileHighlights.self).content.items
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

// MARK: - Jobs

extension OnDeviceAI {
    @Generable
    struct JobSummary {
        @Guide(description: "Two or three plain sentences: what the role is and what the team does.")
        var about: String
        @Guide(description: "Must-have requirements stated in the posting (degree, years, specific skills). Empty if none are stated.")
        var minimumQualifications: [String]
        @Guide(description: "Nice-to-have qualifications stated in the posting. Empty if none are stated.")
        var preferredQualifications: [String]
        @Guide(description: "What the person will do day to day, as stated in the posting. Empty if not stated.")
        var responsibilities: [String]
        @Guide(description: "Technologies, tools and technical skills named in the posting, e.g. Python, Kubernetes.")
        var skills: [String]
    }

    /// Splits a posting that arrived as one undivided block (most Workday sources) into the
    /// detail screen's sections. Extraction only: nothing that isn't in the posting.
    static func summarizeJob(title: String, description: String) async -> JobSummary? {
        guard isAvailable, !description.isEmpty else { return nil }
        let session = LanguageModelSession(instructions: """
        You organize a real job posting into sections for someone deciding whether to apply. \
        Only report what the posting actually says, close to its own wording. Never invent \
        requirements, responsibilities or skills; leave a list empty when the posting doesn't \
        cover it. Skip company boilerplate, benefits and equal-opportunity statements.
        """)
        let prompt = "Job title: \(title)\n\nPosting:\n\(String(description.prefix(4500)))"
        return try? await session.respond(to: prompt, generating: JobSummary.self).content
    }

    @Generable
    struct KeywordGap {
        @Guide(description: "A specific keyword or phrase from the job posting that the candidate's profile doesn't show, e.g. 'distributed systems', 'A/B testing'. Not a generic word.")
        var keyword: String
        @Guide(description: "One sentence on where and how the candidate could show it, if they genuinely have the experience.")
        var recommendation: String
        @Guide(description: "An example resume bullet using the keyword, with [brackets] around details the candidate must fill in with their own facts.")
        var example: String
    }

    @Generable
    struct KeywordGaps {
        @Guide(description: "Up to four of the most important gaps, most important first.", .count(0...4))
        var gaps: [KeywordGap]
    }

    /// Keywords the posting emphasizes that the candidate's profile and resume don't mention.
    static func missingKeywords(jobTitle: String, jobText: String, candidateText: String) async -> [KeywordGap]? {
        guard isAvailable else { return nil }
        let session = LanguageModelSession(instructions: """
        You compare a job posting with a candidate's profile and list important keywords and \
        phrases from the posting that the profile doesn't show — responsibilities, domains, \
        methods, tools. Ignore anything the profile already covers, and ignore single skills \
        that are just technology names. Never claim the candidate has experience they don't list.
        """)
        let prompt = """
        Job: \(jobTitle)
        Posting:
        \(String(jobText.prefix(3000)))

        Candidate profile:
        \(String(candidateText.prefix(2500)))
        """
        return try? await session.respond(to: prompt, generating: KeywordGaps.self).content.gaps
    }
}
