import Foundation
import FoundationModels

/// Everything Aline needs from a resume, understood section by section.
struct UnderstoodResume {
    var resume: ResumeProfile
    /// City/region from the contact header, if the resume states one
    var location: String = ""
    /// e.g. "B.Tech CSE (AI-ML) · CGPA 9.94"
    var headline: String = ""
    /// Expected or actual graduation year of the most recent degree
    var graduationYear: String = ""
    /// Certifications, awards, hackathons, courses — ready for the Achievement Gallery
    var achievements: [AchievementItem] = []
    /// Whether the on-device model read it (false = deterministic fallback)
    var usedModel: Bool = false
}

/// Resume text → `UnderstoodResume`.
///
/// 1. Split into sections by their headings (deterministic; a broad list of real headings).
/// 2. Read each section with its own small on-device model call. One call for the whole
///    resume overflowed the model's ~4K-token context on real resumes and silently fell back
///    to pattern matching — per-section calls each fit, and each gets instructions specific
///    to that section (e.g. how to read a flattened table).
/// 3. Clean up and validate what came back (table headers never become values,
///    "2024Present" → "2024 – Present", graduation year inferred from degree length).
/// Without Apple Intelligence, the same sections go through table-aware heuristics.
enum ResumeUnderstanding {
    static func understand(_ text: String) async -> UnderstoodResume {
        let sections = Sections(text: text)
        let contact = ResumeStructurer.extractContactInfo(from: text)
        var resume = ResumeProfile(
            fullName: sections.name, phone: contact.phone, email: contact.email,
            linkedInURL: contact.linkedIn, githubURL: contact.github, portfolioURL: contact.portfolio
        )
        var result = UnderstoodResume(resume: resume)
        result.location = sections.location

        if OnDeviceAI.isAvailable, let read = await readWithModel(sections) {
            resume.summary = read.summary
            resume.education = read.education
            resume.experience = read.experience
            resume.projects = read.projects
            resume.skillCategories = read.skills
            result.achievements = read.achievements
            if resume.fullName.isEmpty { resume.fullName = read.name }
            if result.location.isEmpty { result.location = read.location }
            result.usedModel = true
        }
        // Fill whatever the model didn't return (or everything, without the model)
        if resume.education.isEmpty { resume.education = Heuristics.education(sections["education"]) }
        if resume.experience.isEmpty { resume.experience = Heuristics.experience(sections["experience"]) }
        if resume.projects.isEmpty { resume.projects = Heuristics.projects(sections["projects"]) }
        if resume.skillCategories.isEmpty { resume.skillCategories = Heuristics.skills(sections["skills"]) }
        if resume.summary.isEmpty { resume.summary = sections["summary"].joined(separator: " ") }
        if result.achievements.isEmpty {
            result.achievements = Heuristics.achievements(sections["achievements"] + sections["certifications"])
        }

        resume.education = resume.education.map(Cleanup.education).filter { !$0.institution.isEmpty || !$0.degree.isEmpty }
        resume.experience = resume.experience.map(Cleanup.experience).filter { !$0.title.isEmpty || !$0.organization.isEmpty }
        resume.projects = resume.projects.map(Cleanup.project).filter { !$0.name.isEmpty }
        result.achievements = result.achievements.map(Cleanup.achievement)
        resume.achievements = result.achievements.map { $0.issuer.isEmpty ? $0.title : "\($0.title) — \($0.issuer)" }
        resume.certifications = result.achievements.filter { $0.category == .certificates }.map {
            CertificationEntry(name: $0.title, issuer: $0.issuer, dateEarned: $0.dateEarned)
        }

        if let latest = resume.education.first {
            result.graduationYear = Cleanup.graduationYear(of: latest)
            let score = Cleanup.score(in: latest.detail)
            result.headline = [latest.degree, score.map { "CGPA \($0)" }].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
        }
        result.resume = resume
        return result
    }

    // MARK: - Model reading, one section at a time

    private struct ModelRead {
        var name = "", location = "", summary = ""
        var education: [EducationEntry] = []
        var experience: [ExperienceEntry] = []
        var projects: [ProjectEntry] = []
        var skills: [SkillCategory] = []
        var achievements: [AchievementItem] = []
    }

    /// Shared by every section call. Section-specific direction goes in each prompt's task line.
    private static let rules = """
    You extract structured data from ONE section of a resume written by a student or \
    early-career engineer in India.

    About the text in <SECTION>:
    - It was extracted from a PDF. " | " separates table cells or a right-aligned date, and a \
    sentence may be broken across lines.
    - A table may start with a header row naming its columns (e.g. "Degree | Institute/Board \
    | CGPA/Percentage | Year"). Use it to map the cells of the rows below. Header words are \
    NEVER values.

    Rules:
    1. Copy names, titles, dates and numbers exactly as written. DO NOT invent, guess, \
    translate or improve anything.
    2. Leave a field empty ("") when the section doesn't state it.
    3. Rejoin text that was broken across lines. Drop bullet symbols (•, -, ▪).
    4. Return every entry in the section, in the order they appear.
    """

    /// One section call: extraction is deterministic, data is delimited, and an over-long
    /// section retries at half length.
    private static func respond<T: Generable>(_ task: String, _ text: String, as type: T.Type) async -> T? {
        await OnDeviceAI.generate(type, instructions: rules, options: OnDeviceAI.extracting) { budget in
            OnDeviceAI.block("SECTION", OnDeviceAI.clip(text, 2600, budget)) + task
        }
    }

    /// Long sections are read in chunks that fit the model's context, then merged.
    private static func chunks(_ lines: [String], limit: Int = 2600) -> [String] {
        var result: [String] = [], current = ""
        for line in lines {
            if current.count + line.count > limit, !current.isEmpty {
                result.append(current)
                current = ""
            }
            current += line + "\n"
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    private static func readWithModel(_ sections: Sections) async -> ModelRead? {
        var read = ModelRead()
        var anySucceeded = false

        if !sections["header"].isEmpty, let header = await respond(
            "This is the top of the resume, before the first section heading. Extract the person's name and location.",
            sections["header"].prefix(8).joined(separator: "\n"), as: HeaderModel.self
        ) {
            read.name = header.name
            read.location = header.location
            anySucceeded = true
        }
        if !sections["summary"].isEmpty, let summary = await respond(
            "This is the summary or objective section. Return its text.",
            sections["summary"].joined(separator: "\n"), as: SummaryModel.self
        ) {
            read.summary = summary.summary
        }
        for chunk in chunks(sections["education"]) {
            guard let list = await respond(
                "This is the education section. Extract every qualification: degree programmes and school classes (Class XII, Class X).",
                chunk, as: EducationListModel.self
            ) else { continue }
            anySucceeded = true
            read.education += list.entries.map {
                // Branch only when the degree doesn't already name one ("B.Tech. (CSE AI-ML)")
                let degree = $0.degree.contains("(") || $0.fieldOfStudy.isEmpty ? $0.degree : "\($0.degree) (\($0.fieldOfStudy))"
                let years = [$0.startYear, $0.endYear].filter { !$0.isEmpty }
                let dates = Set(years).count == 1 ? years[0] : years.joined(separator: " – ")
                return EducationEntry(institution: $0.institution, degree: degree, location: $0.location,
                                      dateRange: dates, detail: $0.score.isEmpty ? "" : "CGPA/Score: \($0.score)")
            }
        }
        for chunk in chunks(sections["experience"]) {
            guard let list = await respond(
                "This is the experience section. Extract every role, internships included. A line with a title, an organisation and dates starts a new role; the lines under it are its points.",
                chunk, as: ExperienceListModel.self
            ) else { continue }
            anySucceeded = true
            read.experience += list.entries.map {
                ExperienceEntry(title: $0.title, organization: $0.organization, location: $0.location,
                                dateRange: $0.dateRange, bullets: $0.bullets)
            }
        }
        for chunk in chunks(sections["projects"]) {
            guard let list = await respond(
                "This is the projects section. Extract every project. A short line naming a project starts a new one; a 'Tech Stack:' line gives its technologies.",
                chunk, as: ProjectListModel.self
            ) else { continue }
            anySucceeded = true
            read.projects += list.entries.map {
                ProjectEntry(name: $0.name, techStack: $0.techStack, dateRange: $0.dateRange, bullets: $0.bullets)
            }
        }
        if !sections["skills"].isEmpty, let skills = await respond(
            "This is the skills section. Extract each group of skills with its label, splitting lists into individual skills.",
            sections["skills"].joined(separator: "\n"), as: SkillsModel.self
        ) {
            anySucceeded = true
            read.skills = skills.groups.map { SkillCategory(label: $0.label, items: $0.items) }.filter { !$0.items.isEmpty }
        }
        for chunk in chunks(sections["achievements"] + sections["certifications"]) {
            guard let list = await respond(
                "This lists achievements, awards, certifications and activities. Extract each one as a separate item and choose its folder.",
                chunk, as: AchievementListModel.self
            ) else { continue }
            anySucceeded = true
            read.achievements += list.entries.map {
                AchievementItem(
                    id: UUID().uuidString, title: $0.title, issuer: $0.issuer,
                    category: $0.folder.category,
                    dateEarned: $0.date, descriptionText: $0.details, credentialURL: nil, attachmentName: nil
                )
            }
        }
        return anySucceeded ? read : nil
    }

    // MARK: - Model schemas

    @Generable struct HeaderModel {
        @Guide(description: "The person's full name as written, usually the first line, e.g. 'Aarav Kumar'. Not a job title.")
        var name: String
        @Guide(description: "City and state or country only if written, e.g. 'Chennai, Tamil Nadu'. Not an email, phone or URL. Empty if not stated.")
        var location: String
    }

    @Generable struct SummaryModel {
        @Guide(description: "The summary or objective text copied as written, without the heading.")
        var summary: String
    }

    @Generable struct EducationModel {
        @Guide(description: "The degree or class exactly as written, e.g. 'B.Tech.', 'B.E.', 'M.Sc.', 'Class XII'. Include a branch only if written inside it, e.g. 'B.Tech. (CSE AI-ML)'.")
        var degree: String
        @Guide(description: "The branch or major if written separately from the degree, e.g. 'Computer Science and Engineering'. Empty otherwise.")
        var fieldOfStudy: String
        @Guide(description: "College, university or school name, e.g. 'SRM Institute of Science and Technology'. For a school class with only a board, the board, e.g. 'CBSE'.")
        var institution: String
        @Guide(description: "The first year of the programme as 4 digits, e.g. '2024'. Empty if not stated.")
        var startYear: String
        @Guide(description: "The final or expected graduation year as 4 digits, e.g. '2028'. 'Present' only if written as Present/Current with no end year. For a single year, put it here.")
        var endYear: String
        @Guide(description: "The CGPA, GPA or percentage exactly as written, e.g. '9.94' or '95.6%'. Empty if not stated.")
        var score: String
        @Guide(description: "City if written next to the institution. Empty otherwise.")
        var location: String
    }

    @Generable struct EducationListModel {
        @Guide(description: "Every qualification in the section, most recent first.")
        var entries: [EducationModel]
    }

    @Generable struct ExperienceModel {
        @Guide(description: "The role title only, e.g. 'AI/ML Intern', 'Software Engineer'. Not the company.")
        var title: String
        @Guide(description: "The company or organisation only, e.g. 'Tagros Chemicals India Pvt. Ltd.'")
        var organization: String
        @Guide(description: "City, or 'Remote'/'Virtual', if written for this role. Empty otherwise.")
        var location: String
        @Guide(description: "The dates exactly as written, e.g. 'Jun 2026 – Aug 2026' or 'Jul 2025 – Present'. Empty if none.")
        var dateRange: String
        @Guide(description: "Every point under this role, word for word, each as one complete sentence.")
        var bullets: [String]
    }

    @Generable struct ExperienceListModel {
        @Guide(description: "Every role in the section, internships included, in the order written.")
        var entries: [ExperienceModel]
    }

    @Generable struct ProjectModel {
        @Guide(description: "Project name only, e.g. 'Alert-X' or 'Alert-X – AI-Powered Surveillance System'. Never the description.")
        var name: String
        @Guide(description: "Technologies used, comma separated, e.g. 'React, FastAPI, SQLite' — from a 'Tech Stack:' line if there is one")
        var techStack: String
        @Guide(description: "Dates or year only if stated as dates; empty otherwise")
        var dateRange: String
        @Guide(description: "Each point about the project. If written as a paragraph ('Objective: … Engineered …'), one point per sentence, without the 'Objective:' label and without the tech stack line")
        var bullets: [String]
    }

    @Generable struct ProjectListModel {
        @Guide(description: "Every project in the section, in the order written.")
        var entries: [ProjectModel]
    }

    @Generable struct SkillGroupModel {
        @Guide(description: "The group's label as written, e.g. 'Languages', 'Frameworks', 'Developer Tools'. 'Skills' when the list has no label.")
        var label: String
        @Guide(description: "Each skill as its own short item exactly as written, e.g. 'Python', 'React', 'Git'. Never a sentence.")
        var items: [String]
    }

    @Generable struct SkillsModel {
        @Guide(description: "Every skill group in the section, in the order written.")
        var groups: [SkillGroupModel]
    }

    /// The Achievement Gallery folders as a fixed choice — the model can't return anything else.
    @Generable enum Folder {
        case certificates, hackathons, awards, internships, courses, other

        var category: AchievementCategory {
            switch self {
            case .certificates: return .certificates
            case .hackathons: return .hackathons
            case .awards: return .awards
            case .internships: return .internships
            case .courses: return .courses
            case .other: return .other
            }
        }
    }

    @Generable struct AchievementModel {
        @Guide(description: "What was achieved, under 10 words, e.g. 'Winner, Pitch Perfect Ideathon' or 'AWS Certified Cloud Practitioner'. Without the issuer or date.")
        var title: String
        @Guide(description: "Who issued or organised it, e.g. 'Amazon Web Services', 'Coursera', 'Horizon 2025'. Empty if not written.")
        var issuer: String
        @Guide(description: "Hackathon/ideathon/coding contest → hackathons; certification or certificate → certificates; online course or NPTEL → courses; prize, rank, scholarship, award → awards; internship → internships; anything else → other.")
        var folder: Folder
        @Guide(description: "The date or year exactly as written. Empty if none.")
        var date: String
        @Guide(description: "One sentence of detail the resume gives (rank, score, team size). Empty if none.")
        var details: String
    }

    @Generable struct AchievementListModel {
        var entries: [AchievementModel]
    }
}

// MARK: - Sections

/// The resume split by its headings. Lines before the first heading are the header.
struct Sections {
    private(set) var byKey: [String: [String]] = [:]
    var name: String = ""
    var location: String = ""

    subscript(key: String) -> [String] { byKey[key] ?? [] }

    private static let headings: [(key: String, names: [String])] = [
        ("summary", ["summary", "professional summary", "profile", "objective", "career objective", "about me", "about"]),
        ("education", ["education", "academic background", "academic qualifications", "academics", "educational qualifications", "qualifications", "academic details", "scholastic achievements"]),
        ("experience", ["experience", "work experience", "professional experience", "employment", "employment history", "internships", "internship", "internship experience", "work history", "industrial experience", "training"]),
        ("projects", ["projects", "personal projects", "academic projects", "key projects", "technical projects", "project work", "selected projects"]),
        ("skills", ["skills", "technical skills", "skill set", "core competencies", "technologies", "tech stack", "tools", "skills & tools", "technical expertise", "key skills", "soft skills", "skills and interests"]),
        ("certifications", ["certifications", "certificates", "certification", "licenses", "licenses & certifications", "courses", "online courses", "coursework", "relevant coursework", "trainings & certifications", "certifications & courses"]),
        ("achievements", ["achievements", "awards", "honors", "honours", "honors & awards", "awards & achievements", "achievements & awards", "accomplishments", "extracurricular", "extracurricular activities", "extra-curricular activities", "positions of responsibility", "leadership", "leadership & activities", "hackathons", "competitions", "co-curricular activities", "publications", "volunteering", "activities", "certifications & achievements", "achievements & certifications"]),
        ("other", ["languages", "interests", "hobbies", "references", "declaration", "personal details"]),
    ]

    init(text: String) {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        var current = "header"
        for line in lines {
            if let key = Self.headingKey(line) {
                current = key
                continue
            }
            byKey[current, default: []].append(line)
        }
        // Name: first header line that looks like a name (no digits, @, or URL)
        let header = self["header"]
        name = header.first { line in
            let plain = line.components(separatedBy: " | ").first ?? line
            return plain.range(of: #"[0-9@/:]"#, options: .regularExpression) == nil
                && (1...5).contains(plain.split(separator: " ").count) && plain.count <= 50
        }.map { ($0.components(separatedBy: " | ").first ?? $0).trimmingCharacters(in: .whitespaces) } ?? ""
        location = Self.location(in: header)
    }

    private static func headingKey(_ line: String) -> String? {
        let cleaned = line.lowercased()
            .replacingOccurrences(of: " | ", with: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: ":-–—•|_ ").union(.whitespaces))
        guard !cleaned.isEmpty, cleaned.split(separator: " ").count <= 5 else { return nil }
        for (key, names) in headings where names.contains(cleaned) {
            return key
        }
        return nil
    }

    private static let cities = ["Bengaluru", "Bangalore", "Chennai", "Hyderabad", "Mumbai", "Pune", "Delhi", "New Delhi",
                                 "Noida", "Gurugram", "Gurgaon", "Kolkata", "Ahmedabad", "Jaipur", "Kochi", "Coimbatore",
                                 "Trivandrum", "Thiruvananthapuram", "Indore", "Bhopal", "Lucknow", "Chandigarh", "Mysuru",
                                 "Mysore", "Vellore", "Madurai", "Nagpur", "Visakhapatnam", "Bhubaneswar", "Patna"]

    private static func location(in header: [String]) -> String {
        for line in header.prefix(6) {
            for part in line.components(separatedBy: CharacterSet(charactersIn: "|•·")) {
                let trimmed = part.trimmingCharacters(in: .whitespaces)
                if let city = cities.first(where: { trimmed.localizedCaseInsensitiveContains($0) }),
                   !trimmed.contains("@"), trimmed.count <= 40 {
                    return trimmed.range(of: #"\d"#, options: .regularExpression) == nil ? trimmed : city
                }
            }
        }
        return ""
    }
}

// MARK: - Cleanup

enum Cleanup {
    private static let headerWords: Set<String> = ["degree", "institute", "institution", "board", "cgpa", "gpa",
                                                   "percentage", "year", "university", "college", "score", "marks", "qualification"]

    /// "2024Present" → "2024 – Present", "2024-2028" → "2024 – 2028"
    static func dates(_ text: String) -> String {
        var t = text.replacingOccurrences(of: #"((?:19|20)\d{2})\s*[-–—]?\s*(Present|present|Current|current|Now|now)"#,
                                          with: "$1 – $2", options: .regularExpression)
        t = t.replacingOccurrences(of: #"((?:19|20)\d{2})\s*[-–—]\s*((?:19|20)\d{2})"#, with: "$1 – $2", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespaces)
    }

    /// Drops values that are really a table's header row ("Degree Institute/Board CGPA …").
    private static func notHeader(_ text: String) -> String {
        let words = text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        guard !words.isEmpty else { return text }
        let headerish = words.filter { headerWords.contains($0) }.count
        return headerish >= 2 && Double(headerish) / Double(words.count) >= 0.3 ? "" : text
    }

    private static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: " | ", with: " ").replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: ",;|-– ").union(.whitespaces))
    }

    static func education(_ e: EducationEntry) -> EducationEntry {
        var e = e
        e.institution = notHeader(clean(e.institution))
        e.degree = notHeader(clean(e.degree))
        e.location = clean(e.location)
        e.dateRange = dates(clean(e.dateRange))
        e.detail = clean(e.detail)
        return e
    }

    /// Clear keywords decide the gallery folder over the model's guess; the issuer and date are
    /// trimmed off the title when they're repeated there.
    static func achievement(_ a: AchievementItem) -> AchievementItem {
        var a = a
        let lower = (a.title + " " + a.issuer).lowercased()
        if lower.contains("hackathon") || lower.contains("ideathon") || lower.contains("codeathon") { a.category = .hackathons }
        else if lower.contains("certif") { a.category = .certificates }
        else if lower.contains("course") || lower.contains("coursera") || lower.contains("udemy") || lower.contains("nptel") { a.category = .courses }
        for tail in [a.dateEarned, a.issuer] where !tail.isEmpty {
            for separator in [", ", " – ", " - ", " — ", " | "] where a.title.hasSuffix(separator + tail) {
                a.title = String(a.title.dropLast(separator.count + tail.count))
            }
        }
        a.title = a.title.trimmingCharacters(in: CharacterSet(charactersIn: ",–—- ").union(.whitespaces))
        a.issuer = a.issuer.trimmingCharacters(in: CharacterSet(charactersIn: ",–—- ").union(.whitespaces))
        return a
    }

    static func experience(_ e: ExperienceEntry) -> ExperienceEntry {
        var e = e
        e.title = clean(e.title); e.organization = clean(e.organization); e.location = clean(e.location)
        e.dateRange = dates(clean(e.dateRange))
        e.bullets = e.bullets.map(clean).filter { $0.count > 2 }
        return e
    }

    static func project(_ p: ProjectEntry) -> ProjectEntry {
        var p = p
        p.name = clean(p.name); p.techStack = clean(p.techStack); p.dateRange = dates(clean(p.dateRange))
        p.bullets = p.bullets.map(clean).filter { $0.count > 2 }
        return p
    }

    /// End year when stated; for an ongoing degree, start year + typical length.
    static func graduationYear(of e: EducationEntry) -> String {
        let years = e.dateRange.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { $0.count == 4 ? Int($0) : nil }
        let ongoing = e.dateRange.lowercased().contains("present") || e.dateRange.lowercased().contains("current")
        if let last = years.last, !(ongoing && years.count == 1) { return String(last) }
        guard let start = years.first else { return "" }
        let degree = e.degree.lowercased()
        let length = degree.contains("m.tech") || degree.contains("m.sc") || degree.contains("mba") || degree.contains("m.e")
            || degree.contains("master") ? 2 : degree.contains("b.sc") || degree.contains("bca") || degree.contains("b.com") ? 3 : 4
        return String(start + length)
    }

    /// "CGPA/Score: 9.94" / "CGPA 9.94/10" / "92%" → "9.94" / "92%"
    static func score(in text: String) -> String? {
        if let r = text.range(of: #"\b\d{1,2}\.\d{1,2}\b"#, options: .regularExpression) { return String(text[r]) }
        if let r = text.range(of: #"\b\d{2}(\.\d+)?\s?%"#, options: .regularExpression) { return String(text[r]) }
        return nil
    }
}

// MARK: - Deterministic fallback (no Apple Intelligence)

enum Heuristics {
    private static func isBullet(_ line: String) -> Bool {
        guard let first = line.first else { return false }
        return "•●◦▪‣·-*➤–".contains(first)
    }

    private static func stripBullet(_ line: String) -> String {
        isBullet(line) ? String(line.dropFirst()).trimmingCharacters(in: .whitespaces) : line
    }

    private static func dateRange(in line: String) -> String? {
        // Only month names count as the word before a year — "Horizon 2025" isn't a date range
        let month = #"(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)[a-z]*\.?\s*"#
        let pattern = "(\(month))?(19|20)\\d{2}(\\s*(–|-|—|to)?\\s*(\(month))?((19|20)\\d{2}|[Pp]resent|[Cc]urrent))?"
        return line.range(of: pattern, options: .regularExpression).map { Cleanup.dates(String(line[$0])) }
    }

    /// Entries: header line(s) followed by bullets; a new non-bullet line with a date after
    /// bullets starts the next entry. Bullet text broken across lines is rejoined.
    private static func entries(_ lines: [String]) -> [(header: [String], bullets: [String])] {
        var result: [(header: [String], bullets: [String])] = []
        var header: [String] = [], bullets: [String] = []
        for line in lines {
            if isBullet(line) {
                bullets.append(stripBullet(line))
            } else if !bullets.isEmpty, dateRange(in: line) == nil, line.first?.isLowercase == true {
                bullets[bullets.count - 1] += " " + line // continuation of a wrapped bullet
            } else {
                if !bullets.isEmpty || (dateRange(in: line) != nil && header.contains { dateRange(in: $0) != nil }) {
                    result.append((header, bullets)); header = []; bullets = []
                }
                header.append(line)
            }
        }
        if !header.isEmpty || !bullets.isEmpty { result.append((header, bullets)) }
        return result
    }

    private static func cells(_ line: String) -> [String] {
        line.components(separatedBy: " | ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    static func education(_ lines: [String]) -> [EducationEntry] {
        // Table form: a header row naming the columns, then one row per qualification
        if let headerIndex = lines.firstIndex(where: { line in
            let l = line.lowercased()
            return cells(line).count >= 3 && ["degree", "institut", "board", "cgpa", "year", "percentage", "qualification"].filter { l.contains($0) }.count >= 2
        }) {
            let columns = cells(lines[headerIndex]).map { $0.lowercased() }
            func column(_ keys: [String]) -> Int? { columns.firstIndex { c in keys.contains { c.contains($0) } } }
            let degreeCol = column(["degree", "qualification", "course"])
            let instCol = column(["institut", "college", "school", "university", "board"])
            let scoreCol = column(["cgpa", "gpa", "percent", "score", "marks", "grade"])
            let yearCol = column(["year", "duration", "period"])
            return lines[(headerIndex + 1)...].compactMap { row -> EducationEntry? in
                var c = cells(row)
                guard c.count >= 2 else { return nil }
                // Adjacent columns set close together come out as one cell ("… Technology 9.94"):
                // split a trailing score or year off into its own cell until the row matches the header
                var i = 0
                while c.count < columns.count, i < c.count {
                    if let r = c[i].range(of: #"\s+(\d{1,2}\.\d{1,2}|\d{2}(\.\d+)?%|(19|20)\d{2}\S*)$"#, options: .regularExpression) {
                        let tail = String(c[i][r]).trimmingCharacters(in: .whitespaces)
                        c[i] = String(c[i][..<r.lowerBound])
                        c.insert(tail, at: i + 1)
                    } else {
                        i += 1
                    }
                }
                func at(_ i: Int?) -> String { i.flatMap { $0 < c.count ? c[$0] : nil } ?? "" }
                return EducationEntry(institution: at(instCol), degree: at(degreeCol), location: "",
                                      dateRange: at(yearCol), detail: at(scoreCol).isEmpty ? "" : "CGPA/Score: \(at(scoreCol))")
            }
        }
        return entries(lines).map { entry in
            let joined = entry.header.joined(separator: " | ")
            let parts = cells(joined).flatMap { $0.components(separatedBy: ", ") }.map { $0.trimmingCharacters(in: .whitespaces) }
            let date = dateRange(in: joined) ?? ""
            let institution = parts.first { p in ["university", "institute", "college", "school", "iit", "nit", "vidyalaya"].contains { p.lowercased().contains($0) } } ?? parts.first ?? ""
            let degree = parts.first { p in ["b.tech", "btech", "b.e", "bachelor", "master", "m.tech", "b.sc", "bca", "mca", "class", "xii", "x ", "diploma", "hsc", "ssc"].contains { p.lowercased().contains($0) } } ?? ""
            let score = Cleanup.score(in: joined + " " + entry.bullets.joined(separator: " "))
            return EducationEntry(institution: institution, degree: degree, location: "", dateRange: date,
                                  detail: score.map { "CGPA/Score: \($0)" } ?? entry.bullets.joined(separator: " "))
        }
    }

    static func experience(_ lines: [String]) -> [ExperienceEntry] {
        entries(lines).map { entry in
            let header = entry.header.joined(separator: " | ")
            let date = dateRange(in: header) ?? ""
            var parts = cells(header.replacingOccurrences(of: date, with: ""))
            if parts.count == 1 {
                for sep in [" at ", " @ ", " – ", " - ", ", "] where parts[0].contains(sep) {
                    parts = parts[0].components(separatedBy: sep).map { $0.trimmingCharacters(in: .whitespaces) }
                    break
                }
            }
            return ExperienceEntry(title: parts.first ?? "", organization: parts.count > 1 ? parts[1] : "",
                                   location: parts.count > 2 ? parts[2] : "", dateRange: date, bullets: entry.bullets)
        }
    }

    /// Labelled lines inside a project ("Tech Stack: …", "Objective: …") are fields, not titles.
    private static let stackLabels = ["tech stack", "technologies", "tech used", "tools used", "built with", "stack", "tools"]
    private static let descriptionLabels = ["objective", "description", "overview", "summary", "about", "outcome", "impact", "role"]

    private static func label(of line: String, in labels: [String]) -> String? {
        guard let colon = line.firstIndex(of: ":") else { return nil }
        let key = line[..<colon].lowercased().trimmingCharacters(in: .whitespaces)
        guard labels.contains(key) else { return nil }
        return String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
    }

    /// Projects written either as bullets or as a paragraph. A short line with no sentence in
    /// it opens a project; "Tech Stack:" lines fill the stack; paragraph sentences become points.
    static func projects(_ lines: [String]) -> [ProjectEntry] {
        var projects: [ProjectEntry] = []
        var current: ProjectEntry?
        var body: [String] = []

        func finish() {
            guard var project = current else { return }
            var bullets: [String] = []
            for piece in body {
                if let stack = label(of: piece, in: stackLabels) {
                    if project.techStack.isEmpty { project.techStack = stack }
                    continue
                }
                let content = label(of: piece, in: descriptionLabels) ?? piece
                // Sentences of a paragraph read better as separate points
                bullets += content.components(separatedBy: ". ")
                    .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ". ").union(.whitespaces)) }
                    .filter { $0.count > 3 }
                    .map { $0 + "." }
            }
            project.bullets = bullets
            projects.append(project)
            current = nil
            body = []
        }

        for raw in lines {
            let line = stripBullet(raw)
            let labelled = label(of: line, in: stackLabels + descriptionLabels) != nil
            let opensProject = !isBullet(raw) && !labelled && line.count <= 110 && !line.contains(". ")
                && (line.first?.isUppercase ?? false) && (current == nil || !body.isEmpty)
            if opensProject {
                finish()
                let date = dateRange(in: line) ?? ""
                let parts = cells(line.replacingOccurrences(of: date, with: ""))
                let first = parts.first ?? line
                // "Alert-X | AI-Powered … System": a tech list after the bar is the stack,
                // a descriptive subtitle stays part of the name
                let second = parts.dropFirst().first ?? ""
                let looksLikeStack = second.contains(",") && second.split(separator: ",").allSatisfy { $0.count <= 25 }
                let name = looksLikeStack || second.isEmpty ? first : "\(first) – \(second)"
                current = ProjectEntry(name: name, techStack: looksLikeStack ? second : "", dateRange: date, bullets: [])
            } else if current == nil {
                current = ProjectEntry(name: line, techStack: "", dateRange: "", bullets: [])
            } else if !isBullet(raw), !labelled, let last = body.last, !last.hasSuffix("."), label(of: last, in: stackLabels) == nil {
                body[body.count - 1] += " " + line // a wrapped line continues the previous one
            } else {
                body.append(line)
            }
        }
        finish()
        return projects
    }

    static func skills(_ lines: [String]) -> [SkillCategory] {
        var groups: [SkillCategory] = [], loose: [String] = []
        for raw in lines {
            let line = stripBullet(raw).replacingOccurrences(of: " | ", with: ", ")
            if let colon = line.firstIndex(of: ":"), line.distance(from: line.startIndex, to: colon) <= 32 {
                let label = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
                let items = split(String(line[line.index(after: colon)...]))
                if !items.isEmpty { groups.append(SkillCategory(label: label, items: items)); continue }
            }
            loose += split(line)
        }
        if !loose.isEmpty { groups.append(SkillCategory(label: groups.isEmpty ? "Skills" : "Other", items: loose)) }
        return groups
    }

    private static func split(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: ",•;|"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count <= 40 }
    }

    static func achievements(_ lines: [String]) -> [AchievementItem] {
        var items: [String] = []
        for line in lines {
            if isBullet(line) || items.isEmpty || dateRange(in: line) != nil && line.count > 25 {
                items.append(stripBullet(line))
            } else {
                items[items.count - 1] += " " + line
            }
        }
        return items.filter { $0.count > 3 }.map { text in
            let lower = text.lowercased()
            let category: AchievementCategory =
                lower.contains("hackathon") || lower.contains("ideathon") ? .hackathons
                : lower.contains("certif") ? .certificates
                : lower.contains("course") || lower.contains("coursera") || lower.contains("udemy") || lower.contains("nptel") ? .courses
                : lower.contains("intern") ? .internships
                : lower.contains("award") || lower.contains("winner") || lower.contains("rank") || lower.contains("prize") || lower.contains("medal") ? .awards
                : .other
            let date = dateRange(in: text) ?? ""
            let parts = text.replacingOccurrences(of: date, with: "").components(separatedBy: CharacterSet(charactersIn: "–—|"))
                .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return AchievementItem(
                id: UUID().uuidString, title: String((parts.first ?? text).prefix(80)), issuer: parts.count > 1 ? parts[1] : "",
                category: category, dateEarned: date, descriptionText: text.count > 80 ? text : "", credentialURL: nil, attachmentName: nil
            )
        }
    }
}
