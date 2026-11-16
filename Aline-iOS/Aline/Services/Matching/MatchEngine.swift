import Foundation

/// The "% Match" on every job card — deterministic and explainable, computed on device for
/// every job in the feed (no per-job model call; it has to rank 1000+ jobs instantly).
///
/// Four weighted components, ported from the original app's MatchEngine and pointed at the
/// final frontend's models:
/// - skills (50%): the job's extracted skills found in the profile's skills, experience and
///   project text
/// - experience (20%): profile experience time against the posting's stated minimum years
/// - credentials (10%): job skills mentioned in achievements
/// - priorities (20%): career preferences — roles, locations, opportunity type, work mode,
///   companies. A soft boost, never a filter.
struct MatchResult {
    let score: Int
    let matchedSkills: [String]
    let missingSkills: [String]
}

struct MatchEngine {
    private static let skillsWeight = 0.50
    private static let experienceWeight = 0.20
    private static let credentialsWeight = 0.10
    private static let priorityWeight = 0.20

    /// Keywords behind each role label the app offers (onboarding's catalog, which Career
    /// Preferences also starts from). A label like "Backend Development" wouldn't
    /// substring-match a real "Backend Engineer" title on its own.
    static let roleKeywords: [String: [String]] = [
        "software engineering": ["software engineer", "software developer", "swe", "sde", "developer", "programmer"],
        "data science": ["data scientist", "data science"],
        "data scientist": ["data scientist", "data science"],
        "ai / ml": ["machine learning", "ml engineer", "ai engineer", "artificial intelligence", "deep learning", "ai/ml"],
        "ai/ml engineering": ["machine learning", "ml engineer", "ai engineer", "artificial intelligence", "ai/ml"],
        "data analyst": ["data analyst", "analytics", "business analyst", "bi analyst"],
        "backend development": ["backend", "back-end", "back end", "server", "platform engineer", "api"],
        "frontend development": ["frontend", "front-end", "front end", "ui engineer", "web developer"],
        "mobile development": ["ios", "android", "mobile", "flutter", "react native"],
        "cloud / devops": ["devops", "cloud", "site reliability", "sre", "infrastructure", "platform"],
        "cybersecurity": ["security", "cyber", "soc analyst", "penetration"],
        "product management": ["product manager", "product management", "apm"],
        "ui/ux design": ["designer", "ux", "ui/ux", "product design"],
        "embedded systems": ["embedded", "firmware", "hardware", "vlsi"],
        "quality assurance": ["qa", "quality", "test engineer", "sdet", "automation test"],
    ]

    struct Candidate {
        let skills: Set<String>
        let experienceYears: Double?
        let credentialText: String
        let preferences: CareerPreferences

        init(profile: UserProfile, achievements: [AchievementItem], preferences: CareerPreferences) {
            var skills = Set(profile.skills.map { $0.lowercased() })
            // Tools named in bullets and project stacks count too — a skill doesn't have to sit
            // in the Skills list to be real.
            let text = (profile.experiences.flatMap(\.bullets) + profile.projects.flatMap(\.bullets)
                + profile.projects.map(\.techStack)).joined(separator: " ").lowercased()
            for skill in SkillVocabulary.all where text.contains(skill.lowercased()) {
                skills.insert(skill.lowercased())
            }
            self.skills = skills
            let months = profile.experiences.compactMap { DateRangeParser.months(in: $0.period) }
            self.experienceYears = months.isEmpty ? nil : months.reduce(0, +) / 12.0
            self.credentialText = achievements.map { "\($0.title) \($0.issuer) \($0.descriptionText)" }
                .joined(separator: " ").lowercased()
            self.preferences = preferences
        }
    }

    static func match(_ candidate: Candidate, job: JobDTO) -> MatchResult {
        let jobSkills = job.extractedSkills
        let jobSkillSet = Set(jobSkills.map { $0.lowercased() })
        let matched = jobSkills.filter { candidate.skills.contains($0.lowercased()) }
        let missing = jobSkills.filter { !candidate.skills.contains($0.lowercased()) }

        let experience = experienceScore(candidate, job: job)
        let credentials = credentialsScore(candidate, jobSkills: jobSkillSet)
        let priority = priorityScore(candidate.preferences, job: job)

        let combined: Double
        if jobSkillSet.isEmpty {
            // Nothing to compare skills against — weigh the other three proportionally rather
            // than defaulting the whole score to a flat number.
            let total = experienceWeight + credentialsWeight + priorityWeight
            combined = (experience * experienceWeight + credentials * credentialsWeight + priority * priorityWeight) / total
        } else {
            let skills = Double(matched.count) / Double(jobSkillSet.count)
            combined = skills * skillsWeight + experience * experienceWeight
                + credentials * credentialsWeight + priority * priorityWeight
        }
        return MatchResult(score: Int((combined * 100).rounded()), matchedSkills: matched, missingSkills: missing)
    }

    private static func experienceScore(_ candidate: Candidate, job: JobDTO) -> Double {
        guard let required = job.minYearsExperience, required > 0 else { return 1.0 }
        guard let years = candidate.experienceYears else { return 0.6 } // nothing to measure
        return min(1.0, years / Double(required))
    }

    private static func credentialsScore(_ candidate: Candidate, jobSkills: Set<String>) -> Double {
        guard !candidate.credentialText.isEmpty, !jobSkills.isEmpty else { return 0.5 }
        let mentioned = jobSkills.filter { candidate.credentialText.contains($0) }
        return mentioned.isEmpty ? 0.5 : min(1.0, 0.5 + Double(mentioned.count) * 0.25)
    }

    private static func priorityScore(_ prefs: CareerPreferences, job: JobDTO) -> Double {
        var scores: [Double] = []
        let title = job.title.lowercased()

        if !prefs.preferredRoles.isEmpty {
            let hit = prefs.preferredRoles.contains { role in
                let key = role.lowercased()
                let keywords = roleKeywords[key] ?? [key]
                return keywords.contains { title.contains($0) }
            }
            scores.append(hit ? 1.0 : 0.3)
        }
        if !prefs.isOpenToAnyLocation, !prefs.preferredLocations.isEmpty {
            let hit = prefs.preferredLocations.contains { location in
                LocationAliases.matches(location, jobLocation: job.location)
            }
            scores.append(hit ? 1.0 : 0.3)
        }
        if !prefs.opportunityTypes.isEmpty {
            let jobType: Opportunity.OpportunityType = job.jobType == "internship" ? .internship
                : job.jobType == "contract" ? .contract : .fullTime
            scores.append(prefs.opportunityTypes.contains(jobType) ? 1.0 : 0.3)
        }
        if !prefs.workArrangements.isEmpty {
            let mode: Opportunity.WorkMode = job.workMode == "remote" ? .remote : job.workMode == "hybrid" ? .hybrid : .onSite
            scores.append(prefs.workArrangements.contains(mode) ? 1.0 : 0.5)
        }
        if !prefs.preferredCompanies.isEmpty,
           prefs.preferredCompanies.contains(where: { job.company.localizedCaseInsensitiveContains($0) }) {
            scores.append(1.0)
        }
        guard !scores.isEmpty else { return 0.6 } // no stated preference — neutral-leaning
        return scores.reduce(0, +) / Double(scores.count)
    }
}

/// Indian cities appear under several names across job sources ("Bangalore" vs "Bengaluru").
enum LocationAliases {
    private static let groups: [[String]] = [
        ["bengaluru", "bangalore"],
        ["delhi ncr", "delhi", "new delhi", "gurgaon", "gurugram", "noida"],
        ["mumbai", "bombay", "navi mumbai"],
        ["chennai", "madras"],
        ["hyderabad", "secunderabad"],
        ["pune"],
        ["kolkata", "calcutta"],
    ]

    /// One display name per city: "Bangalore" → "Bengaluru", "Gurgaon" → "Delhi NCR"
    static func canonical(_ name: String) -> String {
        guard let group = groups.first(where: { $0.contains(name.lowercased()) }) else { return name }
        return group[0].split(separator: " ").map { $0.count <= 3 ? $0.uppercased() : $0.capitalized }.joined(separator: " ")
    }

    static func matches(_ preferred: String, jobLocation: String) -> Bool {
        let location = jobLocation.lowercased()
        let key = preferred.lowercased()
        let names = groups.first { $0.contains(key) } ?? [key]
        return names.contains { location.contains($0) }
    }
}

/// Forgiving "Mon YYYY – Mon YYYY" / "Mon YYYY – Present" / "YYYY – YYYY" parser for free-text
/// date ranges; unparseable ranges contribute nothing rather than failing.
enum DateRangeParser {
    private static let monthNames: [String: Int] = [
        "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
        "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12,
    ]

    static func months(in dateRange: String) -> Double? {
        let normalized = dateRange.replacingOccurrences(of: "–", with: "-").replacingOccurrences(of: "—", with: "-")
        let parts = normalized.split(separator: "-", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        guard let start = parseMonthYear(parts.first ?? "") else { return nil }
        let end: (year: Int, month: Int)
        if parts.count < 2 {
            end = start // a single month, e.g. "Jun 2026"
        } else if parts[1].lowercased().contains("present") || parts[1].lowercased().contains("current") {
            let now = Calendar.current.dateComponents([.year, .month], from: Date())
            end = (now.year ?? start.year, now.month ?? start.month)
        } else if let parsed = parseMonthYear(parts[1]) {
            end = parsed
        } else {
            return nil
        }
        return Double(max(1, (end.year - start.year) * 12 + (end.month - start.month) + 1))
    }

    private static func parseMonthYear(_ text: String) -> (year: Int, month: Int)? {
        let tokens = text.split(separator: " ").map(String.init)
        let digits = text.filter(\.isNumber)
        guard digits.count >= 4, let year = Int(digits.suffix(4)) else { return nil }
        if let first = tokens.first, let month = monthNames[String(first.prefix(3)).lowercased()] {
            return (year, month)
        }
        return (year, 1)
    }
}
