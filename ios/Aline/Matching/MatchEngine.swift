import Foundation

/// Deterministic matching — pure set math and date arithmetic, no model call, computed fresh
/// for every job in the feed (has to sort 1000+ jobs instantly, which rules out any
/// per-job AI call — that stays reserved for JobSummarizer's on-demand detail-screen
/// enrichment, never the ranking signal). This is the plan's core cost-control +
/// explainability design (spec sections 13-14): "why you match" must be real, inspectable
/// math the user can trust, never an opaque "AI says 94%."
///
/// v2: four weighted components, using whichever profile data is actually available —
/// ResumeProfile (rich: experience/projects/certs/achievements) when the person has built a
/// resume, CareerProfile (skills-only, from onboarding) as the day-one fallback before they
/// have. Previously this only ever looked at CareerProfile.skills; everything else the
/// person provides (experience depth, projects, certifications, location/role priorities)
/// was collected and then silently ignored.
struct MatchResult {
    let score: Int // 0-100
    let matchedSkills: [String]
    let missingSkills: [String]
    /// Plain-language explanation of the experience-fit component — nil when the job states
    /// no explicit years requirement (there's nothing to explain, not a penalty).
    let experienceNote: String?
    /// Plain-language explanation of the priority-alignment component — nil when the user
    /// hasn't set a location/role preference to align against.
    let priorityNote: String?
}

struct MatchEngine {
    // Weights sum to 100 — kept as named constants, not magic numbers scattered through the
    // function, so the "why" of the final number stays auditable in one place.
    private static let skillsWeight = 0.50
    private static let experienceWeight = 0.20
    private static let credentialsWeight = 0.10
    private static let priorityWeight = 0.20

    static func match(
        resumeProfile: ResumeProfile?,
        careerProfile: CareerProfile,
        preferences: UserPreferences,
        job: Job
    ) -> MatchResult {
        let jobSkills = Set(job.extractedSkills.map { $0.lowercased() })

        // Component 1: skills overlap — the one component that's always computable, even on
        // day one with nothing but CareerProfile's flat skill list.
        let candidateSkills = candidateSkillSet(resumeProfile: resumeProfile, careerProfile: careerProfile)
        let (skillsScore, matchedDisplay, missingDisplay) = skillsComponent(jobSkills: jobSkills, candidateSkills: candidateSkills, job: job)

        // Component 2: experience fit — only computable with a real ResumeProfile (CareerProfile
        // has no dated experience entries to measure from) and only meaningful when the job
        // states a years requirement at all.
        let (experienceScore, experienceNote) = experienceComponent(resumeProfile: resumeProfile, job: job)

        // Component 3: certifications/achievements — small deterministic keyword-overlap bonus.
        let credentialsScore = credentialsComponent(resumeProfile: resumeProfile, jobSkills: jobSkills)

        // Component 4: priority alignment — soft boost toward the user's stated location/role
        // preference, never a hard filter (standing architecture rule: score and let the user
        // decide, don't silently drop opportunities — see ingestion filter's own one-sided design).
        let (priorityScore, priorityNote) = priorityComponent(preferences: preferences, job: job)

        guard !jobSkills.isEmpty else {
            // No skills extracted from this JD at all — skills component has nothing to say,
            // so lean on the other three rather than defaulting the whole score to a flat 50.
            let fallback = experienceScore * (experienceWeight / (experienceWeight + credentialsWeight + priorityWeight))
                + credentialsScore * (credentialsWeight / (experienceWeight + credentialsWeight + priorityWeight))
                + priorityScore * (priorityWeight / (experienceWeight + credentialsWeight + priorityWeight))
            return MatchResult(
                score: Int((fallback * 100).rounded()),
                matchedSkills: [], missingSkills: [],
                experienceNote: experienceNote, priorityNote: priorityNote
            )
        }

        let combined = skillsScore * skillsWeight
            + experienceScore * experienceWeight
            + credentialsScore * credentialsWeight
            + priorityScore * priorityWeight

        return MatchResult(
            score: Int((combined * 100).rounded()),
            matchedSkills: matchedDisplay,
            missingSkills: missingDisplay,
            experienceNote: experienceNote,
            priorityNote: priorityNote
        )
    }

    // MARK: - Component 1: skills

    private static func candidateSkillSet(resumeProfile: ResumeProfile?, careerProfile: CareerProfile) -> Set<String> {
        var skills = Set(careerProfile.skills.map { $0.lowercased() })
        guard let resumeProfile else { return skills }

        skills.formUnion(resumeProfile.skillCategories.flatMap(\.items).map { $0.lowercased() })

        // Experience/project bullets often mention tools that never made it into a dedicated
        // "Skills" section (e.g. "...using Redis caching..." in an impact bullet) — scan them
        // against the same vocabulary the backend uses, so a real skill isn't missed just
        // because it wasn't separately categorized.
        let bulletText = (resumeProfile.experience.flatMap(\.bullets) + resumeProfile.projects.flatMap(\.bullets))
            .joined(separator: " ")
        let projectStacks = resumeProfile.projects.map(\.techStack).joined(separator: " ")
        let fullText = "\(bulletText) \(projectStacks)".lowercased()
        for skill in SkillVocabulary.all where fullText.contains(skill.lowercased()) {
            skills.insert(skill.lowercased())
        }
        return skills
    }

    private static func skillsComponent(
        jobSkills: Set<String>, candidateSkills: Set<String>, job: Job
    ) -> (score: Double, matched: [String], missing: [String]) {
        guard !jobSkills.isEmpty else { return (0, [], []) }
        let matched = jobSkills.intersection(candidateSkills)
        let missing = jobSkills.subtracting(candidateSkills)
        let score = Double(matched.count) / Double(jobSkills.count)
        let matchedDisplay = job.extractedSkills.filter { matched.contains($0.lowercased()) }
        let missingDisplay = job.extractedSkills.filter { missing.contains($0.lowercased()) }
        return (score, matchedDisplay, missingDisplay)
    }

    // MARK: - Component 2: experience fit

    private static func experienceComponent(resumeProfile: ResumeProfile?, job: Job) -> (score: Double, note: String?) {
        guard let requiredYears = job.minYearsExperience else {
            return (1.0, nil) // nothing stated — full credit, nothing to explain
        }
        guard let resumeProfile else {
            return (0.6, nil) // no dated experience to measure — neutral-leaning, not a penalty
        }
        let candidateYears = totalExperienceYears(resumeProfile)
        if requiredYears == 0 {
            return (1.0, "Open to candidates with no prior experience required")
        }
        if candidateYears >= Double(requiredYears) {
            return (1.0, "Meets the \(requiredYears)+ year\(requiredYears == 1 ? "" : "s") experience ask")
        }
        let ratio = max(0, candidateYears / Double(requiredYears))
        let yearsText = candidateYears < 1 ? "under a year" : String(format: "~%.1f years", candidateYears)
        return (ratio, "Asks for \(requiredYears)+ years — you have \(yearsText)")
    }

    /// Sums ExperienceEntry date ranges in years — internships/part-time roles included
    /// equally (the plan's audience is 3rd/4th-year students through ~3 years, where
    /// internship time is the real signal, not something to discount).
    private static func totalExperienceYears(_ profile: ResumeProfile) -> Double {
        let totalMonths = profile.experience.reduce(0.0) { sum, entry in
            sum + (DateRangeParser.months(in: entry.dateRange) ?? 0)
        }
        return totalMonths / 12.0
    }

    // MARK: - Component 3: certifications/achievements

    private static func credentialsComponent(resumeProfile: ResumeProfile?, jobSkills: Set<String>) -> Double {
        guard let resumeProfile, !jobSkills.isEmpty else { return 0.5 } // neutral when nothing to check
        let credentialText = (
            resumeProfile.certifications.map(\.name)
            + resumeProfile.achievements
        ).joined(separator: " ").lowercased()
        guard !credentialText.isEmpty else { return 0.5 }
        let mentioned = jobSkills.filter { credentialText.contains($0) }
        return mentioned.isEmpty ? 0.5 : min(1.0, 0.5 + Double(mentioned.count) * 0.25)
    }

    // MARK: - Component 4: priority alignment

    private static func priorityComponent(preferences: UserPreferences, job: Job) -> (score: Double, note: String?) {
        var subscores: [Double] = []
        var matchNotes: [String] = []
        var mismatchNotes: [String] = []

        if preferences.preferredLocation != "All locations" {
            if job.location.localizedCaseInsensitiveContains(preferences.preferredLocation) {
                subscores.append(1.0)
                matchNotes.append("In your preferred location (\(preferences.preferredLocation))")
            } else {
                // Not excluded, just not boosted — see the standing one-sided-filter rule
                // (ingestion never hard-drops on a soft preference, and neither does this).
                // Still worth a note: a lower score with no explanation at all breaks the
                // "never an opaque number" principle just as much as a wrong one would.
                subscores.append(0.3)
                mismatchNotes.append("Outside your preferred location (\(preferences.preferredLocation))")
            }
        }

        if !preferences.preferredRoles.isEmpty {
            let lowerTitle = job.title.lowercased()
            if preferences.preferredRoles.contains(where: { lowerTitle.contains($0.lowercased()) }) {
                subscores.append(1.0)
                matchNotes.append("Matches a role you're interested in")
            } else {
                subscores.append(0.3)
                mismatchNotes.append("Not one of your selected role interests")
            }
        }

        guard !subscores.isEmpty else { return (0.6, nil) } // no stated preference — neutral-leaning
        let avg = subscores.reduce(0, +) / Double(subscores.count)
        // Prefer surfacing a genuine match if there is one; only fall back to explaining a
        // mismatch when nothing positive happened, so a real preference being set never
        // produces a silently unexplained score either way.
        return (avg, matchNotes.first ?? mismatchNotes.first)
    }

    /// Kept for any older call site expecting the pre-v2 signature — delegates straight
    /// through with empty preferences/no resume profile.
    static func match(profile: CareerProfile, job: Job) -> MatchResult {
        match(resumeProfile: nil, careerProfile: profile, preferences: .empty, job: job)
    }
}

/// Minimal "Mon YYYY – Mon YYYY" / "Mon YYYY – Present" / "YYYY – YYYY" parser — resume date
/// ranges are free text, not a structured field, so this is deliberately forgiving rather
/// than failing closed; an unparseable range just contributes 0 months instead of crashing
/// or throwing, consistent with "degrade gracefully" everywhere else in this app's AI-adjacent
/// code.
enum DateRangeParser {
    private static let monthNames: [String: Int] = [
        "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
        "jul": 7, "aug": 8, "sep": 9, "sept": 9, "oct": 10, "nov": 11, "dec": 12,
    ]

    static func months(in dateRange: String) -> Double? {
        let normalized = dateRange
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
        let parts = normalized.split(separator: "-", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return nil }

        guard let start = parseMonthYear(parts[0]) else { return nil }
        let end: (year: Int, month: Int)
        if parts[1].lowercased().contains("present") || parts[1].lowercased().contains("current") {
            let now = Calendar.current.dateComponents([.year, .month], from: Date())
            end = (now.year ?? start.year, now.month ?? start.month)
        } else if let parsedEnd = parseMonthYear(parts[1]) {
            end = parsedEnd
        } else {
            return nil
        }

        let months = Double((end.year - start.year) * 12 + (end.month - start.month))
        return max(0, months)
    }

    private static func parseMonthYear(_ text: String) -> (year: Int, month: Int)? {
        let tokens = text.split(separator: " ").map { $0.trimmingCharacters(in: .whitespaces) }
        if tokens.count >= 2,
           let month = monthNames[String(tokens[0].prefix(4)).lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))]
               ?? monthNames[String(tokens[0].prefix(3)).lowercased()],
           let year = Int(tokens.last!.filter(\.isNumber)) {
            return (year, month)
        }
        if let year = Int(text.filter(\.isNumber)), text.filter(\.isNumber).count == 4 {
            return (year, 1)
        }
        return nil
    }
}
