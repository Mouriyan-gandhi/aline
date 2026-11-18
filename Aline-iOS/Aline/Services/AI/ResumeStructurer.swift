import Foundation

/// Deterministic resume parsing helpers from the previous app. The resume pipeline now lives in
/// ResumeUnderstanding.swift (layout-aware sections, one focused model call per section); it
/// still uses `extractContactInfo` from here. The old single-call model path was removed: one
/// prompt for a whole resume overflowed the on-device model's context on real resumes.
struct ResumeStructurer {}

extension ResumeStructurer {
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
