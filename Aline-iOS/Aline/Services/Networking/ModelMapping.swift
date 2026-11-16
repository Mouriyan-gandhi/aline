import SwiftUI

// Backend wire shapes → the frontend's own models (Opportunity, DiscussionPost,
// InterviewQuestion, UserProfile, …). The views only ever see the frontend models; this file
// is the one place that knows both sides.

// MARK: - Dates & relative time

enum RelativeTime {
    private nonisolated(unsafe) static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private nonisolated(unsafe) static let isoPlain = ISO8601DateFormatter()
    private static let plainDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
    private static let longForm: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    /// Backend timestamps are Python isoformat() with microseconds and "+00:00" — six
    /// fractional digits, which ISO8601DateFormatter's fractional option doesn't accept.
    private static let pythonISO: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Job posted dates vary by source platform (ISO 8601 with or without fractions, a plain
    /// "yyyy-MM-dd", or "July 16, 2026") — try each, nil when none fit.
    static func parse(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return pythonISO.date(from: string)
            ?? isoFractional.date(from: string)
            ?? isoPlain.date(from: string)
            ?? plainDate.date(from: string)
            ?? longForm.date(from: string)
    }

    /// "Just now" / "12m ago" / "3h ago" / "2d ago" / "5w ago" — the exact shapes
    /// `Opportunity.recencyInMinutes` parses back for sorting.
    static func shortLabel(since date: Date, now: Date = Date()) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(date) / 60))
        switch minutes {
        case 0..<1: return "Just now"
        case 1..<60: return "\(minutes)m ago"
        case 60..<1440: return "\(minutes / 60)h ago"
        case 1440..<10080: return "\(minutes / 1440)d ago"
        default: return "\(minutes / 10080)w ago"
        }
    }

    static func shortLabel(isoString: String?) -> String {
        guard let date = parse(isoString) else { return "" }
        return shortLabel(since: date)
    }

    static func modifiedLabel(isoString: String) -> String? {
        guard let date = parse(isoString) else { return nil }
        let label = shortLabel(since: date)
        return label == "Just now" ? label : "Modified \(label)"
    }
}

// MARK: - Jobs

extension Opportunity {
    private static let cardPalette: [Color] = [
        AlineTheme.cardMint, AlineTheme.cardLavender, AlineTheme.cardPeach,
        AlineTheme.cardYellow, AlineTheme.cardSkyBlue, AlineTheme.cardCoral,
    ]

    init(job: JobDTO, match: MatchResult, isLiked: Bool, isApplied: Bool, appliedAt: String?) {
        let type: OpportunityType
        switch job.jobType {
        case "internship": type = .internship
        case "contract": type = .contract
        default: type = .fullTime
        }
        let mode: WorkMode
        switch job.workMode {
        case "remote": mode = .remote
        case "hybrid": mode = .hybrid
        default: mode = .onSite
        }
        let experience: String
        switch job.minYearsExperience {
        case nil, 0?: experience = "Freshers"
        case let years?: experience = "\(years)+ years"
        }
        let paletteIndex = abs(job.company.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }) % Self.cardPalette.count

        self.init(
            id: job.id,
            companyName: job.company,
            companySymbol: "building.2.fill",
            roleTitle: job.title,
            location: job.location,
            opportunityType: type,
            workMode: mode,
            salaryRange: "",
            experienceYears: experience,
            eligibleGradYears: job.eligibleGradYears.isEmpty ? "Not specified" : job.eligibleGradYears,
            matchScore: match.score,
            recency: RelativeTime.shortLabel(isoString: job.postedAt),
            cardColor: Self.cardPalette[paletteIndex],
            isLiked: isLiked,
            isApplied: isApplied,
            applicationDate: isApplied ? (appliedAt.flatMap { "Applied \(RelativeTime.shortLabel(isoString: $0))" } ?? "Applied") : nil,
            externalCareersURL: job.applyUrl,
            aboutRole: job.about.isEmpty ? job.description : job.about,
            minimumQualifications: job.minimumQualifications,
            preferredQualifications: job.preferredQualifications,
            applicantTips: [],
            responsibilities: job.responsibilities,
            skills: job.extractedSkills,
            detectedKeywords: match.matchedSkills,
            missingKeywords: []
        )
    }
}

// MARK: - Community

extension DiscussionType {
    init(category: String) {
        self = DiscussionType(rawValue: category) ?? .generalDiscussion
    }
}

extension DiscussionPost {
    /// The app's "You" convention (DiscussionPost.currentUserName) marks the signed-in user's
    /// own posts and comments everywhere — My Posts, delete permissions, notifications.
    init(dto: DiscussionDTO, comments: [DiscussionComment] = []) {
        let excerpt = dto.body.count > 140 ? String(dto.body.prefix(137)).trimmingCharacters(in: .whitespaces) + "..." : dto.body
        self.init(
            id: dto.id,
            type: DiscussionType(category: dto.category),
            authorName: dto.isMine ? DiscussionPost.currentUserName : dto.username,
            isAnonymous: true,
            companyName: dto.company,
            role: dto.roleTitle,
            timeAgo: RelativeTime.shortLabel(isoString: dto.createdAt),
            title: dto.title,
            excerpt: excerpt,
            fullContent: dto.body,
            topics: dto.topics,
            likesCount: dto.likesCount,
            isLiked: dto.likedByMe,
            isSaved: dto.savedByMe,
            comments: comments,
            avatarImageName: dto.avatar,
            sharesCount: dto.sharesCount
        )
        self.serverCommentsCount = dto.commentsCount
    }

    init(detail: DiscussionDetailDTO) {
        let replies = Dictionary(grouping: detail.comments.filter { $0.parentId != nil }, by: { $0.parentId! })
        let topLevel = detail.comments.filter { $0.parentId == nil }.map { comment -> DiscussionComment in
            var mapped = DiscussionComment(dto: comment)
            mapped.replies = (replies[comment.id] ?? []).map(DiscussionComment.init(dto:))
            return mapped
        }
        self.init(dto: detail.discussion, comments: topLevel)
        self.commentsLoaded = true
    }
}

extension DiscussionComment {
    init(dto: CommentDTO) {
        self.init(
            id: dto.id,
            authorName: dto.isMine ? DiscussionPost.currentUserName : dto.username,
            authorRole: dto.roleTitle ?? "",
            timeAgo: RelativeTime.shortLabel(isoString: dto.createdAt),
            text: dto.body,
            likesCount: dto.likesCount,
            isLiked: dto.likedByMe,
            replies: [],
            avatarImageName: dto.avatar
        )
    }
}

extension CompanyCommunity {
    init(dto: CompanyCommunityDTO) {
        self.init(
            id: "comp-\(dto.name.lowercased())",
            name: dto.name,
            symbol: "building.2.fill",
            memberCount: dto.followersCount == 1 ? "1 member" : "\(dto.followersCount) members",
            description: "Discussions, interview advice, and updates for \(dto.name).",
            isFollowing: dto.following
        )
    }
}

// MARK: - Interview questions

extension InterviewQuestion {
    init(dto: InterviewQuestionDTO) {
        self.init(
            id: dto.id,
            questionText: dto.question,
            topic: QuestionTopic(rawValue: dto.topic) ?? .dsa,
            companyName: dto.company,
            role: dto.role,
            difficulty: dto.difficulty,
            upvotesCount: dto.upvotesCount,
            isUpvoted: dto.upvotedByMe,
            isSaved: dto.savedByMe,
            hint: dto.hint,
            approach: dto.approach,
            answer: dto.answer,
            aiGeneratedAnswer: nil,
            // No contributor answer: the detail screen offers an on-device AI solution instead.
            hasAIGeneratedSolution: dto.answer == nil,
            timeComplexity: dto.timeComplexity,
            spaceComplexity: dto.spaceComplexity,
            isCommunityReported: true
        )
    }
}

// MARK: - Profile

extension UserProfile {
    static let empty = UserProfile(
        name: "", username: "", titleOrStage: "", education: "", institution: "", graduationYear: "",
        location: "", bio: "", skills: [], linkedInURL: "", githubURL: "", portfolioURL: "",
        experiences: [], projects: []
    )

    init(dto: ProfileDTO, fallbackName: String) {
        self.init(
            name: dto.name ?? fallbackName,
            username: dto.username,
            titleOrStage: dto.headline ?? dto.careerStage ?? "",
            education: dto.education ?? "",
            institution: dto.institution ?? "",
            graduationYear: dto.graduationYear.map(String.init) ?? "",
            location: dto.location ?? "",
            bio: dto.bio ?? "",
            skills: dto.skills,
            linkedInURL: dto.linkedin ?? "",
            githubURL: dto.github ?? "",
            portfolioURL: dto.portfolio ?? "",
            experiences: dto.experience.map {
                UserExperience(
                    id: $0.id ?? UUID().uuidString, title: $0.title, company: $0.organization,
                    location: $0.location, period: $0.dateRange, bullets: $0.bullets
                )
            },
            projects: dto.projects.map {
                UserProject(id: $0.id ?? UUID().uuidString, title: $0.name, period: $0.dateRange, techStack: $0.techStack, bullets: $0.bullets)
            }
        )
    }

    /// The full editable profile as a backend update — everything the Edit Profile screen owns.
    func updateRequest() -> ProfileUpdateRequest {
        var request = ProfileUpdateRequest(deviceId: DeviceIdentity.deviceID)
        request.name = name
        request.headline = titleOrStage
        request.education = education
        request.institution = institution
        // Free text in the app ("2028" or "2024 – 2028"); the backend column is a year.
        request.graduationYear = graduationYear
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { $0.count == 4 ? Int($0) : nil }
            .last
        request.location = location
        request.bio = bio
        request.skills = skills
        request.linkedin = linkedInURL
        request.github = githubURL
        request.portfolio = portfolioURL
        request.experience = experiences.map {
            ProfileExperienceDTO(id: $0.id, title: $0.title, organization: $0.company, location: $0.location, dateRange: $0.period, bullets: $0.bullets)
        }
        request.projects = projects.map {
            ProfileProjectDTO(id: $0.id, name: $0.title, techStack: $0.techStack, dateRange: $0.period, bullets: $0.bullets)
        }
        return request
    }
}

extension AchievementItem {
    init(dto: AchievementDTO) {
        self.init(
            id: dto.id,
            title: dto.title,
            issuer: dto.issuer,
            category: AchievementCategory(rawValue: dto.category) ?? .other,
            dateEarned: dto.dateEarned,
            descriptionText: dto.description,
            credentialURL: dto.credentialUrl,
            attachmentName: dto.attachmentName
        )
    }

    var dto: AchievementDTO {
        AchievementDTO(
            id: id, title: title, issuer: issuer, category: category.rawValue, dateEarned: dateEarned,
            description: descriptionText, credentialUrl: credentialURL, attachmentName: attachmentName
        )
    }
}

extension CareerPreferences {
    /// Nothing chosen yet: open to everything, alerts on.
    static let empty = CareerPreferences(
        preferredRoles: [], preferredCompanies: [], preferredLocations: [], isOpenToAnyLocation: true,
        opportunityTypes: [], workArrangements: [], experienceLevel: "", alertsEnabled: true, isPushAllowedByOS: false
    )

    init(dto: PreferencesDTO) {
        self.init(
            preferredRoles: dto.preferredRoles,
            preferredCompanies: dto.preferredCompanies,
            preferredLocations: dto.preferredLocations,
            isOpenToAnyLocation: dto.isOpenToAnyLocation,
            opportunityTypes: dto.opportunityTypes.compactMap(Opportunity.OpportunityType.init(rawValue:)),
            workArrangements: dto.workArrangements.compactMap(Opportunity.WorkMode.init(rawValue:)),
            experienceLevel: dto.experienceLevel,
            alertsEnabled: dto.alertsEnabled,
            isPushAllowedByOS: false
        )
    }

    var dto: PreferencesDTO {
        PreferencesDTO(
            preferredRoles: preferredRoles, preferredCompanies: preferredCompanies,
            preferredLocations: preferredLocations, isOpenToAnyLocation: isOpenToAnyLocation,
            opportunityTypes: opportunityTypes.map(\.rawValue), workArrangements: workArrangements.map(\.rawValue),
            experienceLevel: experienceLevel, alertsEnabled: alertsEnabled
        )
    }
}

extension InterviewQuestion {
    /// The same question carrying an on-device AI solution.
    func withAIAnswer(_ text: String) -> InterviewQuestion {
        InterviewQuestion(
            id: id, questionText: questionText, topic: topic, companyName: companyName, role: role,
            difficulty: difficulty, upvotesCount: upvotesCount, isUpvoted: isUpvoted, isSaved: isSaved,
            hint: hint, approach: approach, answer: answer, aiGeneratedAnswer: text,
            hasAIGeneratedSolution: hasAIGeneratedSolution, timeComplexity: timeComplexity,
            spaceComplexity: spaceComplexity, isCommunityReported: isCommunityReported
        )
    }
}

extension Opportunity {
    /// The same opportunity with on-device AI enrichment applied (see DiscoverViewModel.enrichDetail).
    func enriched(_ enrichment: JobEnrichment, candidateSkills: Set<String>) -> Opportunity {
        let skills = enrichment.skills ?? self.skills
        return Opportunity(
            id: id, companyName: companyName, companySymbol: companySymbol, roleTitle: roleTitle, location: location,
            opportunityType: opportunityType, workMode: workMode, salaryRange: salaryRange, experienceYears: experienceYears,
            eligibleGradYears: eligibleGradYears, matchScore: matchScore, recency: recency, cardColor: cardColor,
            isLiked: isLiked, isApplied: isApplied, applicationDate: applicationDate, externalCareersURL: externalCareersURL,
            aboutRole: enrichment.about ?? aboutRole,
            minimumQualifications: enrichment.minimumQualifications ?? minimumQualifications,
            preferredQualifications: enrichment.preferredQualifications ?? preferredQualifications,
            applicantTips: applicantTips,
            responsibilities: enrichment.responsibilities ?? responsibilities,
            skills: skills,
            detectedKeywords: skills.filter { candidateSkills.contains($0.lowercased()) },
            missingKeywords: enrichment.missingKeywords ?? missingKeywords
        )
    }
}

/// What on-device AI added to one job's detail screen; nil fields leave the original as is.
struct JobEnrichment {
    var about: String?
    var minimumQualifications: [String]?
    var preferredQualifications: [String]?
    var responsibilities: [String]?
    var skills: [String]?
    var missingKeywords: [MissingKeyword]?
}
