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
        // Most phones aren't Apple-Intelligence-eligible (iPhone 15 Pro+ only, and the
        // feature has to be turned on), so the on-device model path above is unavailable
        // on the majority of real devices — this can't be the only path, or the whole
        // resume-structuring feature is dead for most users. Mirrors ResumeParser's own
        // "AI must not be a hard dependency" fallback, just for the richer schema.
        return structureHeuristically(resumeText: resumeText)
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

// MARK: - Deterministic fallback

private extension ResumeStructurer {
    static let sectionKeywords: [(key: String, variants: [String])] = [
        ("summary", ["summary", "objective", "profile"]),
        ("education", ["education", "academic background"]),
        ("experience", ["experience", "work experience", "professional experience", "employment", "employment history"]),
        ("projects", ["projects", "personal projects", "academic projects"]),
        ("skills", ["skills", "technical skills", "skill set", "core competencies"]),
        ("certifications", ["certifications", "certificates", "licenses", "licenses & certifications"]),
        ("achievements", ["achievements", "awards", "honors", "honors & awards", "accomplishments"]),
    ]

    static func structureHeuristically(resumeText: String) -> ResumeProfile {
        let rawLines = resumeText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        let lines = rawLines.filter { !$0.isEmpty }
        guard !lines.isEmpty else { return .empty }

        let (email, phone, linkedIn, github, portfolio) = extractContactInfo(from: resumeText)
        let name = extractName(from: lines, email: email, phone: phone)
        let sections = splitIntoSections(lines)

        return ResumeProfile(
            fullName: name,
            phone: phone,
            email: email,
            linkedInURL: linkedIn,
            githubURL: github,
            portfolioURL: portfolio,
            summary: (sections["summary"] ?? []).joined(separator: " "),
            education: parseEducation(sections["education"] ?? []),
            experience: parseEntries(sections["experience"] ?? []).map {
                let (title, organization) = splitTitleOrganization($0.header)
                return ExperienceEntry(
                    title: title, organization: organization,
                    location: "", dateRange: $0.dateRange, bullets: $0.bullets
                )
            },
            projects: parseEntries(sections["projects"] ?? []).map {
                ProjectEntry(name: $0.header, techStack: "", dateRange: $0.dateRange, bullets: $0.bullets)
            },
            skillCategories: parseSkills(sections["skills"] ?? []),
            certifications: parseCertifications(sections["certifications"] ?? []),
            achievements: (sections["achievements"] ?? []).map(stripBulletPrefix)
        )
    }

    // MARK: Contact info

    static func extractContactInfo(from text: String) -> (email: String, phone: String, linkedIn: String, github: String, portfolio: String) {
        var email = "", phone = "", linkedIn = "", github = "", portfolio = ""
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue) else {
            return (email, phone, linkedIn, github, portfolio)
        }
        let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            let matchedText = String(text[range])
            if let phoneNumber = match.phoneNumber {
                if phone.isEmpty { phone = phoneNumber }
            } else if let url = match.url {
                if url.scheme == "mailto" {
                    if email.isEmpty { email = url.absoluteString.replacingOccurrences(of: "mailto:", with: "") }
                } else if matchedText.lowercased().contains("linkedin.com") {
                    if linkedIn.isEmpty { linkedIn = matchedText }
                } else if matchedText.lowercased().contains("github.com") {
                    if github.isEmpty { github = matchedText }
                } else if portfolio.isEmpty {
                    portfolio = matchedText
                }
            }
        }
        return (email, phone, linkedIn, github, portfolio)
    }

    static func extractName(from lines: [String], email: String, phone: String) -> String {
        for line in lines.prefix(5) {
            if !email.isEmpty && line.contains(email) { continue }
            if !phone.isEmpty && line.contains(phone) { continue }
            if line.contains("@") || line.lowercased().contains("linkedin.com") || line.lowercased().contains("github.com") { continue }
            let wordCount = line.split(separator: " ").count
            if wordCount >= 1 && wordCount <= 5 && line.count <= 60 {
                return line
            }
        }
        return ""
    }

    // MARK: Section splitting

    static func splitIntoSections(_ lines: [String]) -> [String: [String]] {
        var headerIndices: [(index: Int, key: String)] = []
        for (index, line) in lines.enumerated() {
            let normalized = line.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":").union(.whitespaces))
            guard normalized.split(separator: " ").count <= 4 else { continue }
            for (key, variants) in sectionKeywords where variants.contains(normalized) {
                headerIndices.append((index, key))
                break
            }
        }

        var sections: [String: [String]] = [:]
        for (position, header) in headerIndices.enumerated() {
            let start = header.index + 1
            let end = position + 1 < headerIndices.count ? headerIndices[position + 1].index : lines.count
            guard start < end else { continue }
            sections[header.key, default: []].append(contentsOf: lines[start..<end])
        }
        return sections
    }

    // MARK: Entry parsing (experience / projects)

    struct ParsedEntry {
        var header: String
        var dateRange: String
        var bullets: [String]
    }

    static func isBulletLine(_ line: String) -> Bool {
        let bulletChars: Set<Character> = ["•", "●", "◦", "▪", "‣", "·", "-", "*", "➤"]
        guard let first = line.first, bulletChars.contains(first) else { return false }
        let rest = line.dropFirst()
        return rest.first == " " || rest.first == "\t"
    }

    static func stripBulletPrefix(_ line: String) -> String {
        guard isBulletLine(line) else { return line }
        return String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
    }

    static func containsYear(_ line: String) -> Bool {
        line.range(of: #"\b(19|20)\d{2}\b"#, options: .regularExpression) != nil
            || line.lowercased().contains("present")
    }

    static func extractDateRange(from line: String) -> String? {
        let pattern = #"([A-Za-z]{3,9}\.?\s*)?\b(19|20)\d{2}\b(\s*(–|-|—|to)\s*([A-Za-z]{3,9}\.?\s*)?(\b(19|20)\d{2}\b|[Pp]resent|[Cc]urrent))?"#
        guard let range = line.range(of: pattern, options: .regularExpression) else { return nil }
        return String(line[range]).trimmingCharacters(in: .whitespaces)
    }

    /// Groups raw lines into entries: a run of non-bullet "header" lines (institution/title,
    /// location, dates — often split across 1-3 lines) followed by its bullet lines, repeating
    /// for each entry. Handles both bulleted entries (experience/projects) and header-only
    /// entries with no bullets at all (education) by also splitting whenever a second
    /// date-bearing line shows up before any bullet has been seen.
    static func parseEntries(_ lines: [String]) -> [ParsedEntry] {
        var entries: [ParsedEntry] = []
        var header: [String] = []
        var bullets: [String] = []
        var sawBullet = false

        func flush() {
            guard !header.isEmpty || !bullets.isEmpty else { return }
            let joinedHeader = header.joined(separator: " ")
            let dateRange = header.compactMap(extractDateRange).first ?? ""
            let cleanedHeader = dateRange.isEmpty ? joinedHeader : joinedHeader.replacingOccurrences(of: dateRange, with: "").trimmingCharacters(in: CharacterSet(charactersIn: ",|-–— ").union(.whitespaces))
            entries.append(ParsedEntry(header: cleanedHeader, dateRange: dateRange, bullets: bullets))
            header = []; bullets = []; sawBullet = false
        }

        for line in lines {
            if isBulletLine(line) {
                bullets.append(stripBulletPrefix(line))
                sawBullet = true
            } else {
                if sawBullet || (containsYear(line) && header.contains(where: containsYear)) {
                    flush()
                }
                header.append(line)
            }
        }
        flush()
        return entries
    }

    static func splitTitleOrganization(_ header: String) -> (title: String, organization: String) {
        for separator in [" at ", " @ ", " - ", " – ", " — ", "|"] {
            if let range = header.range(of: separator) {
                let left = String(header[header.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let right = String(header[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !left.isEmpty && !right.isEmpty { return (left, right) }
            }
        }
        return (header, "")
    }

    // MARK: Education

    static func parseEducation(_ lines: [String]) -> [EducationEntry] {
        parseEntries(lines).map { entry in
            let parts = entry.header.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return EducationEntry(
                institution: parts.first ?? entry.header,
                degree: parts.count > 1 ? parts[1] : "",
                location: parts.count > 2 ? parts[2] : "",
                dateRange: entry.dateRange,
                detail: entry.bullets.joined(separator: " ")
            )
        }
    }

    // MARK: Skills

    static func parseSkills(_ lines: [String]) -> [SkillCategory] {
        var categories: [SkillCategory] = []
        var uncategorized: [String] = []

        for rawLine in lines {
            let line = stripBulletPrefix(rawLine)
            if let colonRange = line.range(of: ":"), line.distance(from: line.startIndex, to: colonRange.lowerBound) <= 30 {
                let label = String(line[line.startIndex..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let itemsText = String(line[colonRange.upperBound...])
                let items = splitItems(itemsText)
                if !label.isEmpty && !items.isEmpty {
                    categories.append(SkillCategory(label: label, items: items))
                    continue
                }
            }
            uncategorized.append(contentsOf: splitItems(line))
        }

        if !uncategorized.isEmpty {
            categories.append(SkillCategory(label: categories.isEmpty ? "Skills" : "Other", items: uncategorized))
        }
        return categories
    }

    static func splitItems(_ text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet(charactersIn: ",•|;"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: Certifications

    static func parseCertifications(_ lines: [String]) -> [CertificationEntry] {
        lines.map { rawLine in
            let line = stripBulletPrefix(rawLine)
            let dateEarned = extractDateRange(from: line) ?? ""
            let withoutDate = dateEarned.isEmpty ? line : line.replacingOccurrences(of: dateEarned, with: "")
            let parts = withoutDate.components(separatedBy: CharacterSet(charactersIn: "–—-,")).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return CertificationEntry(
                name: parts.first ?? withoutDate.trimmingCharacters(in: .whitespaces),
                issuer: parts.count > 1 ? parts[1] : "",
                dateEarned: dateEarned
            )
        }
    }
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
