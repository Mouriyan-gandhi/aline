import Foundation
import FoundationModels

/// Everything the app labels "AI": resume point rewrites, the resume assistant, job tailoring,
/// job summaries, keyword gaps and interview solutions — all on device through Apple's
/// Foundation Models framework, nothing sent to a server.
///
/// Prompting follows Apple's guidance for the on-device model (a ~3B-parameter model with a
/// ~4,096-token context shared by instructions, input and output):
/// - Instructions carry the role, numbered rules and output limits; the prompt carries only the
///   task and the data. The model follows instructions over the prompt, and user-provided text
///   never goes into instructions.
/// - User data is wrapped in labelled blocks (<RESUME>…</RESUME>) so it reads as data, not
///   commands.
/// - One small, specific task per call, with explicit lengths ("one sentence, 15–30 words") and
///   capitalised prohibitions ("DO NOT invent numbers") for the rules that matter most.
/// - Typed output (`@Generable`): `@Guide` descriptions say exactly what each field holds,
///   choices are enums instead of free text, list sizes are bounded, and properties are ordered
///   so the model reasons before it answers (it generates them in declaration order).
/// - Extraction uses greedy sampling (same input, same output); writing uses a low temperature.
/// - Inputs are clipped to a budget; if the context still overflows, the call retries once with
///   half the budget instead of failing.
///
/// The model needs Apple Intelligence. When it isn't available every call returns nil and the
/// caller says so plainly; nothing here substitutes canned text that looks AI-written.
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

    // MARK: - Shared generation

    /// Reading facts out of text: deterministic.
    static let extracting = GenerationOptions(samplingMode: .greedy)
    /// Writing for the user: a little variety, still conservative.
    static let writing = GenerationOptions(temperature: 0.4)

    /// One call in a fresh session. `prompt` receives a budget factor (1.0, then 0.5 on
    /// context overflow) to scale how much of each input it includes.
    static func generate<T: Generable>(
        _ type: T.Type, instructions: String, options: GenerationOptions, prompt: (Double) -> String
    ) async -> T? {
        guard isAvailable else { return nil }
        for budget in [1.0, 0.5] {
            let session = LanguageModelSession(instructions: instructions)
            do {
                return try await session.respond(to: prompt(budget), generating: type, options: options).content
            } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
                continue
            } catch {
                return nil
            }
        }
        return nil
    }

    /// `text` cut to `characters × budget`, on a word boundary.
    static func clip(_ text: String, _ characters: Int, _ budget: Double) -> String {
        let limit = Int(Double(characters) * budget)
        guard text.count > limit else { return text }
        let cut = text.prefix(limit)
        return String(cut[..<(cut.lastIndex(of: " ") ?? cut.endIndex)]) + " …"
    }

    /// A labelled block of user data, or nothing when empty.
    static func block(_ label: String, _ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : "<\(label)>\n\(trimmed)\n</\(label)>\n\n"
    }

    // MARK: - Resume: rewrite one point

    @Generable
    struct Rewrite {
        @Guide(description: "First, the facts you are allowed to use: each fact written in <POINT> (and any you take from <BACKGROUND>), a few words each, e.g. 'backend for attendance app', 'Python Flask', 'MySQL'.", .count(1...8))
        var facts: [String]
        @Guide(description: "The rewritten text, built ONLY from the facts listed above. No quotes, no label such as 'Rewritten:', no bullet symbol.")
        var text: String
        @Guide(description: "One sentence, under 25 words, telling the user what changed and, if useful, which real fact they could add (e.g. a number) to make it stronger.")
        var note: String
    }

    private static let rewriteInstructions = """
    You are a resume editor for students and early-career engineers. You rewrite ONE bullet \
    point from their resume.

    Rules:
    1. Apply the request in <REQUEST> to the point in <POINT>.
    2. Keep every fact already in the point: the work done, tools, numbers and outcome.
    3. You may add a fact ONLY if it is written in <BACKGROUND>. DO NOT invent numbers, \
    percentages, user counts, team sizes, tools, employers or results.
    4. Start with a strong action verb (Built, Designed, Reduced, Automated…). Use past tense \
    unless the point clearly describes current work.
    5. Write one sentence of 15–30 words. No "I", no buzzwords such as "synergy", \
    "passionate" or "leveraged".
    6. DO NOT add features, scale or qualities that aren't written, such as "scalable", \
    "real-time", "robust", "secure", "high-performance" or "user authentication".
    7. When <TARGET_ROLE> is given, prefer the role's own terms where they truthfully describe \
    the work.
    8. If the request can't be met without inventing facts, improve only the wording and say \
    in the note which fact the user could add.

    Example
    <POINT>worked on backend of college app using python and mysql</POINT>
    <REQUEST>make it more impactful</REQUEST>
    facts: backend of college app; Python; MySQL
    text: Developed the backend of the college's app using Python and MySQL.
    note: Stronger verb and clearer scope; add a real number (users, requests, time saved) if \
    you have one.
    """

    /// Rewrites one selected resume point following the user's request. `context` is the target
    /// role; `background` is the user's profile and achievement gallery, the only facts that may
    /// be added.
    static func rewrite(_ text: String, instruction: String, context: String? = nil, background: String? = nil) async -> Rewrite? {
        await generate(Rewrite.self, instructions: rewriteInstructions, options: writing) { budget in
            block("POINT", text) + block("REQUEST", instruction)
                + block("TARGET_ROLE", context ?? "")
                + block("BACKGROUND", clip(background ?? "", 2400, budget))
                + "Rewrite the point."
        }
    }

    /// Decides first whether the candidate's own text supports the term, then writes.
    @Generable
    struct TailorDecision {
        @Guide(description: "Words copied from <POINT> or <BACKGROUND> that show the candidate used or did the term. Empty if there are none.")
        var evidence: String
        @Guide(description: "true only if the evidence above really shows the term; false if evidence is empty.")
        var supported: Bool
        @Guide(description: "If supported: the point rewritten to include the term's exact wording, one sentence, 15–30 words, using only facts from the point and evidence. If not supported: the original point unchanged.")
        var text: String
        @Guide(description: "One sentence under 25 words for the user: what changed, or that the term isn't backed by their experience.")
        var note: String
    }

    private static let tailorInstructions = """
    You tailor ONE resume point to a job by working in a term the job asks for, but only when \
    the candidate's own text proves they did it.

    Rules:
    1. Look for evidence of <TERM> in <POINT> and <BACKGROUND>: the same tool, method or \
    concept, possibly in other words. Copy that evidence.
    2. No evidence means NOT supported. DO NOT add the term to the point. A skill the job \
    wants is not evidence.
    3. When supported, rewrite the point to use the term's exact wording, keeping every fact \
    and adding nothing else.
    4. DO NOT invent numbers, tools, results or features.
    """

    /// Rewrites a resume point so a missing skill or keyword from a job shows — only when the
    /// point or the background shows the candidate really did it.
    static func tailor(point: String, toShow term: String, role: String, company: String, background: String = "") async -> Rewrite? {
        let decision = await generate(TailorDecision.self, instructions: tailorInstructions, options: extracting) { budget in
            block("TERM", term) + block("POINT", point) + block("TARGET_ROLE", "\(role) at \(company)")
                + block("BACKGROUND", clip(background, 2400, budget))
                + "Decide whether the term is supported, then write the point."
        }
        guard let decision else { return nil }
        // Unsupported: keep the user's point exactly, whatever the model wrote
        return Rewrite(facts: [], text: decision.supported ? decision.text : point, note: decision.note)
    }

    // MARK: - Resume: whole-resume advice

    @Generable
    struct Advice {
        @Guide(description: "3 to 5 suggestions, most important first. Each is one sentence under 30 words that names a specific line or section of THIS resume and says exactly what to change.", .count(1...5))
        var points: [String]
    }

    private static let adviceInstructions = """
    You are a resume coach for students and early-career engineers applying for tech roles. \
    You answer the user's question about their own resume.

    Rules:
    1. Base every suggestion on what is in <RESUME>. Name the section or line you mean \
    (e.g. "your Alert-X project", "the summary").
    2. Each suggestion is one concrete change the user can make now. DO NOT give generic \
    advice that would apply to any resume.
    3. You may point to items in <PROFILE> that could be added. DO NOT suggest claiming \
    experience, skills or numbers the user doesn't have.
    4. When <TARGET_ROLE> is given, focus on what that role needs.
    5. If the question isn't about the resume or job search, answer with one suggestion \
    saying you can help with their resume.
    """

    /// Answers a question about the whole resume when no single point is selected.
    static func adviseOnResume(_ question: String, resumeText: String, background: String = "", targetRole: String? = nil) async -> String? {
        let advice = await generate(Advice.self, instructions: adviceInstructions, options: writing) { budget in
            block("RESUME", clip(resumeText, 3200, budget))
                + block("PROFILE", clip(background, 1400, budget))
                + block("TARGET_ROLE", targetRole ?? "")
                + block("QUESTION", question)
                + "Answer the question with specific suggestions."
        }
        return advice.map { $0.points.map { "• \($0)" }.joined(separator: "\n") }
    }

    // MARK: - Resume: tailoring to a job

    private static let summaryInstructions = """
    You write the professional summary at the top of a student's or early-career engineer's \
    resume, aimed at one job.

    Rules:
    1. Write 2 or 3 sentences, 40–70 words in total. No "I", no company name.
    2. Sentence 1: who they are (degree or stage, field) and the kind of role they fit, in the \
    job's terms where true.
    3. Sentence 2: their one or two strongest experiences or projects that match <JOB>, with \
    the tools used.
    4. Optional sentence 3: one relevant achievement or certification.
    5. Use ONLY facts from <RESUME> and <PROFILE>. DO NOT invent numbers, employers, tools or \
    achievements. DO NOT copy requirements from <JOB> as if the candidate has them.
    6. No buzzwords such as "passionate", "results-driven" or "go-getter".
    """

    /// A professional summary aimed at one role, built from the resume, profile and achievements.
    static func tailoredSummary(current: String, role: String, company: String, jobText: String, resumeText: String, background: String) async -> Rewrite? {
        await generate(Rewrite.self, instructions: summaryInstructions, options: writing) { budget in
            block("JOB", "\(role) at \(company)\n" + clip(jobText, 1300, budget))
                + block("CURRENT_SUMMARY", current)
                + block("RESUME", clip(resumeText, 2200, budget))
                + block("PROFILE", clip(background, 1500, budget))
                + "Write the summary for this job."
        }
    }

    @Generable
    enum ResumeSection {
        case experience, projects, achievements, skills
    }

    @Generable
    struct Highlight {
        @Guide(description: "The item's name exactly as it appears in <PROFILE>, e.g. 'Alert-X' or 'AWS Certified Cloud Practitioner'.")
        var item: String
        @Guide(description: "Under 15 words: which requirement of the job it shows, in the job's terms.")
        var reason: String
        @Guide(description: "The resume section it belongs in.")
        var section: ResumeSection
    }

    @Generable
    struct Highlights {
        @Guide(description: "0 to 3 items, most relevant first. Empty when nothing qualifies.", .count(0...3))
        var items: [Highlight]
    }

    private static let highlightsInstructions = """
    You compare a resume with the candidate's full profile to find strengths they left off \
    the resume for one job.

    Rules:
    1. List only items that appear in <PROFILE> AND are missing from <RESUME>.
    2. Each item must clearly match a requirement or responsibility in <JOB>.
    3. DO NOT list anything that is not written in <PROFILE>. DO NOT list items already on \
    the resume, even reworded.
    4. Return an empty list when nothing qualifies; that is a good answer.
    """

    /// Profile/achievement items that suit the job but aren't on the selected resume.
    static func profileHighlights(role: String, company: String, jobText: String, resumeText: String, background: String) async -> [String]? {
        guard !background.isEmpty else { return nil }
        let result = await generate(Highlights.self, instructions: highlightsInstructions, options: extracting) { budget in
            block("JOB", "\(role) at \(company)\n" + clip(jobText, 1200, budget))
                + block("RESUME", clip(resumeText, 2000, budget))
                + block("PROFILE", clip(background, 2000, budget))
                + "Find profile items missing from the resume that fit this job."
        }
        return result?.items.map { item in
            let section: String
            switch item.section {
            case .experience: section = "Experience"
            case .projects: section = "Projects"
            case .achievements: section = "Achievements"
            case .skills: section = "Skills"
            }
            return "\(item.item) — \(item.reason) (add under \(section))"
        }
    }

    // MARK: - Interview questions

    /// Behavioral by topic, or by the classic phrasings when the topic is generic.
    static func isBehavioral(question: String, topic: String) -> Bool {
        let t = topic.lowercased(), q = question.lowercased()
        return ["behav", "hr", "culture", "leadership"].contains { t.contains($0) }
            || ["tell me about a time", "describe a time", "give an example of a time", "a situation where"].contains { q.contains($0) }
    }

    @Generable
    enum QuestionKind {
        case coding, systemDesign, conceptual, behavioral
    }

    /// Ordered so the model classifies and plans before it writes the answer.
    @Generable
    struct InterviewSolution {
        @Guide(description: "What kind of question this is; decides the answer's format.")
        var kind: QuestionKind
        @Guide(description: "One sentence that nudges toward the solution without giving it away.")
        var hint: String
        @Guide(description: "2 to 4 sentences: the key idea, why it works, and any assumption made about the question.")
        var approach: String
        @Guide(description: "The full answer in the format the rules give for this kind of question. Code goes in a ```python block with real line breaks and indentation.")
        var answer: String
        @Guide(description: "For coding: time and space complexity, e.g. 'Time O(n), space O(n)'. Empty for other kinds.")
        var complexity: String

        /// The answer with complexity appended (coding only), as shown in the app.
        var fullAnswer: String {
            let note = complexity.trimmingCharacters(in: .whitespaces)
            guard kind == .coding, !note.isEmpty, note.uppercased() != "N/A" else { return answer }
            return "\(answer)\n\nComplexity: \(note)"
        }
    }

    /// Behavioral questions get a fill-in STAR template, never an invented story.
    @Generable
    struct STARTemplate {
        @Guide(description: "One sentence: what the interviewer is checking with this question, e.g. 'How you handle conflict and still deliver.'")
        var lookingFor: String
        @Guide(description: "The word Situation, a colon, then one sentence setting the scene, e.g. Situation: In [project or internship], [the context].")
        var situation: String
        @Guide(description: "The word Task, a colon, then the student's responsibility, e.g. Task: I was responsible for [goal] by [deadline].")
        var task: String
        @Guide(description: "The word Action, a colon, then 2–3 steps that fit this question, with [placeholders] for specifics and why each step mattered.")
        var action: String
        @Guide(description: "The word Result, a colon, then [the outcome, with a real number if you have one] and one thing learned.")
        var result: String
        @Guide(description: "One tip under 20 words on delivering this answer.")
        var tip: String
    }

    private static let interviewInstructions = """
    You are an interview coach preparing a student for a tech interview. You write a correct, \
    clear model answer to one question.

    Format by kind of question:
    - coding: explain the algorithm in 2–4 sentences, then give complete, runnable Python code \
    with short comments. Choose the optimal approach unless the question asks otherwise.
    - systemDesign: requirements and scale assumptions, main components, data flow, storage \
    choice, how it scales, two key trade-offs. Use short labelled lines.
    - conceptual: a precise definition, how it works, one concrete example, one common pitfall.
    - behavioral: a STAR template (Situation, Task, Action, Result) with [square brackets] \
    for every personal detail. NOT a story.

    Rules:
    1. If the question is ambiguous, state the assumption in the approach.
    2. DO NOT claim the code was run or tested. DO NOT invent personal experiences, names or \
    numbers; the student fills those in.
    3. Keep the answer under 300 words, excluding code.
    """

    private static let behavioralInstructions = """
    You are an interview coach. For a behavioral question you write a STAR answer TEMPLATE \
    that the student completes with their own real experience.

    Rules:
    1. DO NOT write a story. DO NOT invent projects, teammates, companies, tools or numbers.
    2. Every specific detail is a placeholder in [square brackets], e.g. [project], \
    [teammate's concern], [metric].
    3. The structure and the actions must fit THIS question: what a strong answer to it shows.
    4. Each part is one or two sentences.
    """

    static func solve(question: String, topic: String, company: String?, role: String?) async -> InterviewSolution? {
        if isBehavioral(question: question, topic: topic) {
            let star = await generate(STARTemplate.self, instructions: behavioralInstructions, options: GenerationOptions(temperature: 0.3)) { budget in
                block("QUESTION", clip(question, 1500, budget)) + "Write the STAR template for this question."
            }
            return star.map {
                InterviewSolution(kind: .behavioral, hint: $0.lookingFor, approach: "Answer with STAR: Situation, Task, Action, Result. \($0.tip)",
                                  answer: [$0.situation, $0.task, $0.action, $0.result].joined(separator: "\n\n"), complexity: "")
            }
        }
        return await generate(InterviewSolution.self, instructions: interviewInstructions, options: GenerationOptions(temperature: 0.3)) { budget in
            block("QUESTION", clip(question, 1500, budget))
                + block("TOPIC", topic)
                + block("ASKED_AT", [company, role].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", "))
                + "Write the model answer."
        }
    }
}

// MARK: - Jobs

extension OnDeviceAI {
    /// Ordered as postings usually are: what the role is, what you'll do, what they need.
    @Generable
    struct JobSummary {
        @Guide(description: "2 or 3 plain sentences, 40–70 words: what the role is, the team or product it works on, and the main goal. No company marketing.")
        var about: String
        @Guide(description: "What the person will do, as stated in the posting. Each item one line under 25 words, in the posting's own words.", .count(0...8))
        var responsibilities: [String]
        @Guide(description: "Must-have requirements as stated: degree, years, specific skills or knowledge. Each one line under 25 words.", .count(0...8))
        var minimumQualifications: [String]
        @Guide(description: "Nice-to-have qualifications, only if the posting marks them as preferred, bonus or plus. Each one line under 25 words.", .count(0...6))
        var preferredQualifications: [String]
        @Guide(description: "Technologies named in the posting: languages, frameworks, databases, platforms and tools as short names, e.g. 'Java', 'Kafka'. NOT concepts, duties or soft skills.", .count(0...12))
        var skills: [String]
    }

    private static let jobSummaryInstructions = """
    You organise one real job posting into sections for a student deciding whether to apply.

    Rules:
    1. Report ONLY what <POSTING> says, close to its own wording. DO NOT add requirements, \
    duties or skills that are not written there.
    2. Put each statement in exactly one section. "Required", "must have", "you have" and \
    "qualifications" go to minimum; "preferred", "nice to have", "bonus" and "plus" go to \
    preferred.
    3. Skip company history, mission statements, benefits, salary, location details and \
    equal-opportunity text.
    4. Leave a list empty when the posting doesn't cover it.
    """

    /// Splits a posting that arrived as one undivided block (most Workday sources) into the
    /// detail screen's sections. Extraction only.
    static func summarizeJob(title: String, description: String) async -> JobSummary? {
        guard !description.isEmpty else { return nil }
        return await generate(JobSummary.self, instructions: jobSummaryInstructions, options: extracting) { budget in
            block("JOB_TITLE", title) + block("POSTING", clip(description, 4200, budget))
                + "Organise this posting into sections."
        }
    }

    @Generable
    struct KeywordGap {
        @Guide(description: "A 1–4 word phrase copied from <POSTING> naming a concept, method or responsibility, e.g. 'distributed systems', 'A/B testing', 'on-call support'.")
        var keyword: String
        @Guide(description: "One sentence under 25 words: which project or role in <PROFILE> could show it if the candidate really did it; otherwise, that it's a gap to build with a small project.")
        var recommendation: String
        @Guide(description: "One example resume point, different from the recommendation, that uses the phrase. Every specific detail is a placeholder: [project], [tool], [number]. NO real numbers or percentages.")
        var example: String
    }

    @Generable
    struct KeywordGaps {
        @Guide(description: "0 to 4 gaps, most important to the job first. Empty when the profile already covers the posting.", .count(0...4))
        var gaps: [KeywordGap]
    }

    private static let keywordInstructions = """
    You find what a job posting emphasises that a candidate's profile doesn't show yet.

    What counts as a gap: a responsibility, domain, method or concept that <POSTING> asks for \
    and that appears nowhere in <PROFILE>, in any wording.

    Rules:
    1. Copy each phrase from <POSTING>. DO NOT list anything that isn't written there.
    2. DO NOT list single technology names such as "Python" or "AWS"; skills are compared \
    separately.
    3. DO NOT list soft skills ("communication", "team player") or generic words \
    ("experience", "software", "development").
    4. DO NOT list anything the profile already shows, even in other words.
    5. In examples, put every fact the candidate must supply in [square brackets].
    """

    /// Keywords the posting emphasises that the candidate's profile and resume don't mention.
    static func missingKeywords(jobTitle: String, jobText: String, candidateText: String) async -> [KeywordGap]? {
        let gaps = await generate(KeywordGaps.self, instructions: keywordInstructions, options: extracting) { budget in
            block("JOB_TITLE", jobTitle)
                + block("POSTING", clip(jobText, 2600, budget))
                + block("PROFILE", clip(candidateText, 2200, budget))
                + "List the gaps."
        }?.gaps
        // Grounding check: keep only phrases that really appear in the posting, and leave bare
        // technology names to the skills comparison
        let posting = jobText.lowercased()
        let technologies = Set(SkillVocabulary.all.map { $0.lowercased() })
        return gaps?.filter {
            let keyword = $0.keyword.lowercased()
            return posting.contains(keyword) && !technologies.contains(keyword)
        }
    }
}
