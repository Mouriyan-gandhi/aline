import SwiftUI
import Combine

// MARK: - App Navigation & Tab State
public enum AppTab: Int, CaseIterable, Identifiable {
    case discover = 0
    case resume = 1
    case community = 2
    case profile = 3

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .discover: return "Discover"
        case .resume: return "Resume"
        case .community: return "Community"
        case .profile: return "Profile"
        }
    }

    public var iconName: String {
        switch self {
        case .discover: return "sparkles"
        case .resume: return "text.document"
        case .community: return "person.3"
        case .profile: return "person.crop.circle"
        }
    }
}

public enum NotificationCategory: String, CaseIterable {
    case opportunities = "Opportunity"
    case community = "Community"
}

@MainActor
public final class AppNavigationViewModel: ObservableObject {
    @Published public var currentTab: AppTab = .discover
    @Published public var isAuthenticated: Bool
    @Published public var hasCompletedOnboarding: Bool
    @Published public var currentUserFullName: String
    @Published public var currentUserEmail: String
    @Published public var currentUserPhone: String
    @Published public var showNotificationsSheet: Bool = false
    @Published public var notificationsInitialCategory: NotificationCategory = .opportunities
    @Published public var unreadNotificationsCount: Int = 0 {
        didSet {
            // "Mark all read" zeroes the count; remember that for every notification shown
            if unreadNotificationsCount == 0, oldValue > 0 {
                readNotificationIDs.formUnion(currentNotificationIDs)
            }
        }
    }
    /// Notifications opened one by one, or cleared by "Mark all read" — kept across launches
    @Published public var readNotificationIDs: Set<String> = [] {
        didSet {
            UserDefaults.standard.set(Array(readNotificationIDs.suffix(500)), forKey: "readNotificationIDs")
        }
    }
    /// Activity on the user's posts and comments, newest first
    @Published var communityNotifications: [CommunityNotificationItem] = []
    /// Every notification currently listed (community activity and new matching jobs)
    private var currentNotificationIDs: Set<String> = []

    public var currentUserFirstName: String {
        currentUserFullName.components(separatedBy: " ").first ?? currentUserFullName
    }

    /// Whether a notification that arrived unread still shows its dot
    public func isNotificationUnread(_ id: String, initiallyUnread: Bool) -> Bool {
        initiallyUnread && unreadNotificationsCount > 0 && !readNotificationIDs.contains(id)
    }

    /// Marks one notification read; returns whether it was still unread
    @discardableResult
    public func markNotificationRead(_ id: String, initiallyUnread: Bool) -> Bool {
        let wasUnread = isNotificationUnread(id, initiallyUnread: initiallyUnread)
        readNotificationIDs.insert(id)
        if wasUnread {
            unreadNotificationsCount = max(0, unreadNotificationsCount - 1)
        }
        return wasUnread
    }
    @Published public var targetOpportunity: Opportunity? = nil
    @Published public var targetCommunityPost: DiscussionPost? = nil

    public func openNotifications(category: NotificationCategory = .opportunities) {
        self.notificationsInitialCategory = category
        self.showNotificationsSheet = true
    }

    public init(
        isAuthenticated: Bool? = nil,
        hasCompletedOnboarding: Bool? = nil
    ) {
        let defaults = UserDefaults.standard
        let savedAuth = defaults.bool(forKey: "isAuthenticated")
        let savedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")

        self.isAuthenticated = isAuthenticated ?? savedAuth
        self.hasCompletedOnboarding = hasCompletedOnboarding ?? savedOnboarding
        self.currentUserFullName = defaults.string(forKey: "userFullName") ?? ""
        self.currentUserEmail = defaults.string(forKey: "userEmail") ?? ""
        self.currentUserPhone = defaults.string(forKey: "userPhone") ?? ""
        self.readNotificationIDs = Set(defaults.stringArray(forKey: "readNotificationIDs") ?? [])

        // Automatically sync whenever user profile updates anywhere in the app
        NotificationCenter.default.addObserver(
            forName: .userProfileDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let updated = notification.object as? UserProfile else { return }
            let clean = updated.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { return }
            // Delivered on the main queue (queue: .main above)
            MainActor.assumeIsolated {
                self?.currentUserFullName = clean
            }
        }
    }

    /// An account on this device has already finished onboarding (cleared only by Delete Account)
    public var hasExistingAccount: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    public func login(fullName: String, email: String, phone: String, isNewUser: Bool) {
        let cleanName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = cleanName.isEmpty ? "Aarav Sharma" : cleanName
        let resolvedEmail = email.isEmpty ? "aarav.sharma@example.com" : email
        let resolvedPhone = phone.isEmpty ? "+91 99520 86492" : phone

        self.currentUserFullName = resolvedName
        self.currentUserEmail = resolvedEmail
        self.currentUserPhone = resolvedPhone
        // Signing in (returning users skip onboarding) also starts on the Discover dashboard
        self.currentTab = .discover
        self.isAuthenticated = true

        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(resolvedName, forKey: "userFullName")
        UserDefaults.standard.set(resolvedEmail, forKey: "userEmail")
        UserDefaults.standard.set(resolvedPhone, forKey: "userPhone")

        if isNewUser {
            self.hasCompletedOnboarding = false
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        } else {
            self.hasCompletedOnboarding = true
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
    }

    public func completeOnboarding() {
        // Always land on the Discover dashboard, not whichever tab was open before signing out
        self.currentTab = .discover
        self.hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    public func signOut() {
        self.isAuthenticated = false
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
    }

    public func deleteAccount() {
        // Server first: profile, resumes, posts, comments, likes, saves, follows and job marks
        // all go with the identity (see backend delete_account). Then this device forgets it.
        Task { try? await AlineAPI.deleteAccount() }
        DeviceIdentity.reset()

        let defaults = UserDefaults.standard
        for key in [
            "isAuthenticated", "hasCompletedOnboarding", "userFullName", "userEmail", "userPhone",
            "savedLastVisitedQuestionSession", "savedUserProfile", "savedUserAchievements", "savedCareerPreferences",
            "userLocation", "userBio", "userEducation", "userInstitution", "userGraduationYear",
            "userLinkedIn", "userGitHub", "userPortfolio", "readNotificationIDs",
        ] {
            defaults.removeObject(forKey: key)
        }

        self.currentUserFullName = ""
        self.currentUserEmail = ""
        self.currentUserPhone = ""
        self.communityNotifications = []
        self.readNotificationIDs = []
        self.unreadNotificationsCount = 0
        self.hasCompletedOnboarding = false
        self.isAuthenticated = false
    }

    /// Reloads community activity and recounts unread notifications, including new
    /// matching jobs (`opportunityIDs`).
    public func refreshNotifications(opportunityIDs: [String]) async {
        if let items = try? await AlineAPI.notifications() {
            communityNotifications = items.map(CommunityNotificationItem.init(dto:))
        }
        updateUnreadCount(opportunityIDs: opportunityIDs)
    }

    public func updateUnreadCount(opportunityIDs: [String]) {
        currentNotificationIDs = Set(opportunityIDs + communityNotifications.map(\.id))
        let unread = currentNotificationIDs.subtracting(readNotificationIDs).count
        if unread != unreadNotificationsCount {
            unreadNotificationsCount = unread
        }
    }

    public func resetOnboardingForDemo() {
        self.hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Discover & Stacked Card ViewModel
@MainActor
public final class DiscoverViewModel: ObservableObject {
    @Published public var opportunities: [Opportunity] = []
    @Published public var searchQuery: String = ""
    @Published public var selectedFilterTab: FilterTab = .recommended
    @Published public var showFilterSheet: Bool = false
    @Published public var selectedOpportunity: Opportunity? = nil

    // Stacked Card Interaction State
    @Published public var expandedCardId: String? = nil
    /// A fetch is in flight. The first fetch after the backend has been idle can take minutes.
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var lastLoadFailed: Bool = false
    
    // Filters (Matching Figma Design & Multi-Select Search Options)
    @Published public var filterJobType: String = "All"
    @Published public var filterRole: String = "All Roles"
    @Published public var filterLocation: String = "All"
    @Published public var filterWorkMode: String = "All"
    @Published public var filterSkill: String = "All Skills"
    @Published public var filterCompany: String = "All Companies"
    @Published public var filterGradYear: String = "All Years"
    @Published public var filterPostedTime: String = "All"
    @Published public var isMoreFiltersExpanded: Bool = false
    @Published public var filterMinMatch: Int = 80

    // Multi-Select Sets for Search and Select (Roles, Locations, Skills, Companies)
    @Published public var selectedRoles: Set<String> = []
    @Published public var selectedLocations: Set<String> = []
    @Published public var selectedSkills: Set<String> = []
    @Published public var selectedCompanies: Set<String> = []

    public var activeFilterCount: Int {
        var count = 0
        if filterJobType != "All" { count += 1 }
        if filterWorkMode != "All" { count += 1 }
        if filterGradYear != "All Years" { count += 1 }
        if filterPostedTime != "All" { count += 1 }
        count += selectedRoles.count
        if selectedRoles.isEmpty && filterRole != "All Roles" { count += 1 }
        count += selectedLocations.count
        if selectedLocations.isEmpty && filterLocation != "All" { count += 1 }
        count += selectedSkills.count
        if selectedSkills.isEmpty && filterSkill != "All Skills" { count += 1 }
        count += selectedCompanies.count
        if selectedCompanies.isEmpty && filterCompany != "All Companies" { count += 1 }
        return count
    }

    public enum FilterTab: String, CaseIterable {
        case recommended = "Recommended"
        case liked = "Liked"
        case applied = "Applied"
    }

    public var filteredOpportunities: [Opportunity] {
        var list = opportunities

        switch selectedFilterTab {
        case .recommended:
            break
        case .liked:
            list = list.filter { $0.isLiked }
        case .applied:
            list = list.filter { $0.isApplied }
        }

        if !searchQuery.isEmpty {
            list = list.filter {
                $0.roleTitle.localizedCaseInsensitiveContains(searchQuery) ||
                $0.companyName.localizedCaseInsensitiveContains(searchQuery) ||
                $0.skills.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }

        if filterJobType != "All" {
            let target: Opportunity.OpportunityType = filterJobType == "Full Time" ? .fullTime : .internship
            list = list.filter { $0.opportunityType == target }
        }

        if filterWorkMode != "All" {
            let mode = filterWorkMode.lowercased().replacingOccurrences(of: "-", with: "")
            list = list.filter {
                $0.workMode.rawValue.lowercased().replacingOccurrences(of: "-", with: "") == mode
            }
        }

        // Location filtering: multiple selection supported + single string fallback
        let activeLocations = selectedLocations.filter { $0 != "All" && !$0.isEmpty }
        if !activeLocations.isEmpty {
            list = list.filter { opp in
                activeLocations.contains { loc in LocationAliases.matches(loc, jobLocation: opp.location) }
            }
        } else if filterLocation != "All" {
            list = list.filter { LocationAliases.matches(filterLocation, jobLocation: $0.location) }
        }

        // Role filtering: multiple selection supported + single string fallback
        let activeRoles = selectedRoles.filter { $0 != "All Roles" && !$0.isEmpty }
        if !activeRoles.isEmpty {
            list = list.filter { opp in
                activeRoles.contains { role in opp.roleTitle.localizedCaseInsensitiveContains(role) }
            }
        } else if filterRole != "All Roles" {
            list = list.filter { $0.roleTitle.localizedCaseInsensitiveContains(filterRole) }
        }

        // Skill filtering: multiple selection supported + single string fallback
        let activeSkills = selectedSkills.filter { $0 != "All Skills" && !$0.isEmpty }
        if !activeSkills.isEmpty {
            list = list.filter { opp in
                opp.skills.contains { oppSkill in
                    activeSkills.contains { s in oppSkill.localizedCaseInsensitiveContains(s) }
                }
            }
        } else if filterSkill != "All Skills" {
            list = list.filter { $0.skills.contains { $0.localizedCaseInsensitiveContains(filterSkill) } }
        }

        // Company filtering: multiple selection supported + single string fallback
        let activeCompanies = selectedCompanies.filter { $0 != "All Companies" && !$0.isEmpty }
        if !activeCompanies.isEmpty {
            list = list.filter { opp in
                activeCompanies.contains { comp in opp.companyName.localizedCaseInsensitiveContains(comp) }
            }
        } else if filterCompany != "All Companies" {
            list = list.filter { $0.companyName.localizedCaseInsensitiveContains(filterCompany) }
        }

        if filterGradYear != "All Years" {
            list = list.filter { $0.eligibleGradYears.localizedCaseInsensitiveContains(filterGradYear) }
        }

        // Posted Time filter & sorting
        if filterPostedTime == "Recent" {
            list = list.filter { $0.recencyInMinutes <= 7 * 1440 }
            list.sort { $0.recencyInMinutes < $1.recencyInMinutes }
        } else if filterPostedTime == "Newest to Oldest" {
            list.sort { $0.recencyInMinutes < $1.recencyInMinutes }
        } else if filterPostedTime == "Oldest to Newest" {
            list.sort { $0.recencyInMinutes > $1.recencyInMinutes }
        }

        return list
    }

    /// Match score at or above which a job is Recommended (and can trigger a job alert)
    nonisolated public static let recommendedThreshold = 80

    // Every opportunity at 80% match or above
    public var recommendedOpportunities: [Opportunity] {
        filteredOpportunities.filter { $0.matchScore >= Self.recommendedThreshold }
    }

    // Everything below 80% (showing all roles across tech regardless of onboarding choice),
    // with the same search, tab and filters as Recommended
    public var exploreMoreOpportunities: [Opportunity] {
        filteredOpportunities.filter { $0.matchScore < Self.recommendedThreshold }
    }

    public func resetFilters() {
        filterJobType = "All"
        filterRole = "All Roles"
        filterLocation = "All"
        filterWorkMode = "All"
        filterSkill = "All Skills"
        filterCompany = "All Companies"
        filterGradYear = "All Years"
        filterPostedTime = "All"
        filterMinMatch = 80
        selectedRoles.removeAll()
        selectedLocations.removeAll()
        selectedSkills.removeAll()
        selectedCompanies.removeAll()
        searchQuery = ""
    }

    public func toggleLike(for id: String) {
        guard let index = opportunities.firstIndex(where: { $0.id == id }) else { return }
        let liked = !opportunities[index].isLiked
        opportunities[index].isLiked = liked
        if liked { likedIDs.insert(id) } else { likedIDs.remove(id) }
        Task {
            do {
                try await AlineAPI.markJob(id, liked: liked)
            } catch {
                // Not saved — put the heart back the way it was.
                if liked { self.likedIDs.remove(id) } else { self.likedIDs.insert(id) }
                if let i = self.opportunities.firstIndex(where: { $0.id == id }) { self.opportunities[i].isLiked = !liked }
            }
        }
    }

    public func markApplied(for id: String) {
        guard let index = opportunities.firstIndex(where: { $0.id == id }) else { return }
        let now = ISO8601DateFormatter().string(from: Date())
        opportunities[index].isApplied = true
        opportunities[index].applicationDate = "Applied just now"
        appliedAt[id] = now
        Task {
            do {
                try await AlineAPI.markJob(id, applied: true)
            } catch {
                self.appliedAt[id] = nil
                if let i = self.opportunities.firstIndex(where: { $0.id == id }) {
                    self.opportunities[i].isApplied = false
                    self.opportunities[i].applicationDate = nil
                }
            }
        }
    }

    // MARK: Backend feed

    /// Live jobs from /jobs, plus snapshots of liked/applied jobs that have since closed.
    private var jobs: [JobDTO] = []
    private var likedIDs: Set<String> = []
    /// Applied job id → when (ISO 8601)
    private var appliedAt: [String: String] = [:]
    private var candidate = MatchEngine.Candidate(profile: .empty, achievements: [], preferences: .empty)
    private var refreshTask: Task<Void, Never>?
    /// The backend recommender's score for each job (backend/app/recommend.py). The on-device
    /// MatchEngine is only the fallback for jobs without one (offline, before the first fetch).
    private var serverScores: [String: RecommendationDTO] = [:]
    /// Jobs marked "Not relevant" — hidden everywhere in the feed
    private var dismissedIDs: Set<String> = []
    private var recommendationsTask: Task<Void, Never>?

    private static var cacheURL: URL {
        URL.cachesDirectory.appendingPathComponent("jobs-feed.json")
    }
    private static var recommendationsCacheURL: URL {
        URL.cachesDirectory.appendingPathComponent("recommendations.json")
    }

    public init() {
        // Last fetched feed and scores, so the screen isn't empty while a (possibly slow) refresh runs.
        if let data = try? Data(contentsOf: Self.cacheURL),
           let cached = try? JSONDecoder().decode([JobDTO].self, from: data) {
            jobs = cached
        }
        if let data = try? Data(contentsOf: Self.recommendationsCacheURL),
           let cached = try? JSONDecoder().decode(RecommendationsDTO.self, from: data) {
            applyRecommendations(cached)
        }
        rebuild()
        // Profile, preferences or achievements saved on the backend: re-rank
        NotificationCenter.default.addObserver(forName: .profileDidSave, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshRecommendations() }
        }
    }

    private func applyRecommendations(_ recommendations: RecommendationsDTO) {
        serverScores = Dictionary(recommendations.results.map { ($0.jobId, $0) }, uniquingKeysWith: { a, _ in a })
        dismissedIDs = Set(recommendations.dismissedJobIds)
    }

    /// Re-fetches scores only (the feed itself is unchanged). Coalesces bursts of profile saves.
    public func refreshRecommendations() {
        recommendationsTask?.cancel()
        recommendationsTask = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled, let fresh = try? await AlineAPI.recommendations() else { return }
            applyRecommendations(fresh)
            if let data = try? JSONEncoder().encode(fresh) {
                try? data.write(to: Self.recommendationsCacheURL, options: .atomic)
            }
            rebuild()
        }
    }

    /// "Not relevant": hides the job and tells the recommender to show fewer like it.
    public func dismissJob(_ id: String) {
        dismissedIDs.insert(id)
        opportunities.removeAll { $0.id == id }
        Task {
            do {
                try await AlineAPI.setJobDismissed(id, dismissed: true)
                refreshRecommendations()
            } catch {
                dismissedIDs.remove(id)
                rebuild()
            }
        }
    }

    /// Fetches the feed and this device's liked/applied marks. Safe to call repeatedly — a
    /// refresh already in flight is reused.
    public func refresh() {
        guard refreshTask == nil else { return }
        isLoading = true
        refreshTask = Task {
            async let marksResult = try? AlineAPI.jobMarks()
            async let recommendationsResult = try? AlineAPI.recommendations()
            do {
                let fresh = try await AlineAPI.jobs()
                jobs = fresh
                lastLoadFailed = false
                if let data = try? JSONEncoder().encode(fresh) {
                    try? data.write(to: Self.cacheURL, options: .atomic)
                }
            } catch {
                lastLoadFailed = true
            }
            if let marks = await marksResult {
                likedIDs = Set(marks.filter(\.liked).map(\.jobId))
                appliedAt = Dictionary(
                    marks.filter(\.applied).map { ($0.jobId, $0.appliedAt ?? "") }, uniquingKeysWith: { a, _ in a }
                )
                let live = Set(jobs.map(\.id))
                jobs += marks.compactMap(\.job).filter { !live.contains($0.id) }
            }
            if let recommendations = await recommendationsResult {
                applyRecommendations(recommendations)
                if let data = try? JSONEncoder().encode(recommendations) {
                    try? data.write(to: Self.recommendationsCacheURL, options: .atomic)
                }
            }
            rebuild()
            isLoading = false
            refreshTask = nil
            await JobAlerts.notifyNewMatches(opportunities)
        }
    }

    // MARK: Filter options, from the jobs actually in the feed

    /// Role names that appear in real job titles, most common first (seniority and level
    /// markers stripped, so "Senior Software Engineer II" counts toward "Software Engineer").
    @Published public private(set) var roleOptions: [String] = []
    /// Cities jobs are posted in, most common first
    @Published public private(set) var locationOptions: [String] = []
    /// Skills extracted from postings, most common first
    @Published public private(set) var skillOptions: [String] = []
    /// Every company with a job in the feed, A–Z
    @Published public private(set) var companyOptions: [String] = []

    private static let titleNoise: Set<String> = [
        "senior", "sr", "junior", "jr", "lead", "principal", "staff", "associate", "intern", "internship",
        "i", "ii", "iii", "iv", "v", "1", "2", "3", "4", "trainee", "graduate", "entry", "level", "new", "grad",
    ]

    private func rebuildFilterOptions() {
        func ranked(_ values: [String], minimum: Int = 1) -> [String] {
            var counts: [String: (display: String, count: Int)] = [:]
            for value in values where !value.isEmpty {
                let key = value.lowercased()
                counts[key] = (counts[key]?.display ?? value, (counts[key]?.count ?? 0) + 1)
            }
            return counts.values.filter { $0.count >= minimum }.sorted { $0.count > $1.count }.map(\.display)
        }
        roleOptions = ranked(jobs.map { Self.coreRole(from: $0.title) }, minimum: 2)
        locationOptions = ranked(jobs.flatMap { job in
            job.location.components(separatedBy: CharacterSet(charactersIn: ",;/|"))
                .prefix(1)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.lowercased() != "not specified" && $0.lowercased() != "india" }
                .map(LocationAliases.canonical)
        })
        skillOptions = ranked(jobs.flatMap(\.extractedSkills))
        companyOptions = Set(jobs.map(\.company)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// "Senior Software Engineer II, Payments (Backend)" → "Software Engineer"
    static func coreRole(from title: String) -> String {
        var core = title
        for separator in [" - ", " – ", " — ", ",", "(", "|", ":", "/"] {
            if let range = core.range(of: separator) { core = String(core[..<range.lowerBound]) }
        }
        let words = core.split(separator: " ").map(String.init).filter {
            !titleNoise.contains($0.lowercased().trimmingCharacters(in: .punctuationCharacters))
        }
        return words.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Re-scores every job against the latest profile, achievements and career preferences.
    public func updateMatching(profile: UserProfile, achievements: [AchievementItem], preferences: CareerPreferences) {
        candidate = MatchEngine.Candidate(profile: profile, achievements: achievements, preferences: preferences)
        candidateText = Self.describe(profile: profile, achievements: achievements)
        // Keyword gaps were judged against the old profile
        for id in enrichments.keys { enrichments[id]?.missingKeywords = nil }
        keywordChecked.removeAll()
        rebuild()
    }

    // MARK: Job detail enrichment (on-device AI)

    private var enrichments: [String: JobEnrichment] = [:]
    private var summarized: Set<String> = []
    private var keywordChecked: Set<String> = []
    private var candidateText = ""

    /// Called when a job's detail screen opens. Fills Requirements / Responsibilities with the
    /// on-device summarizer when the posting couldn't be split into sections, and finds keywords
    /// the posting wants that the profile doesn't show. Each job is processed once per profile.
    public func enrichDetail(for id: String) async {
        guard OnDeviceAI.isAvailable, let job = jobs.first(where: { $0.id == id }) else { return }

        if !summarized.contains(id), job.minimumQualifications.isEmpty || job.responsibilities.isEmpty {
            summarized.insert(id)
            if let summary = await OnDeviceAI.summarizeJob(title: job.title, description: job.description) {
                var enrichment = enrichments[id] ?? JobEnrichment()
                if !summary.about.isEmpty, job.about.isEmpty || job.about == job.description { enrichment.about = summary.about }
                if job.minimumQualifications.isEmpty, !summary.minimumQualifications.isEmpty { enrichment.minimumQualifications = summary.minimumQualifications }
                if job.preferredQualifications.isEmpty, !summary.preferredQualifications.isEmpty { enrichment.preferredQualifications = summary.preferredQualifications }
                if job.responsibilities.isEmpty, !summary.responsibilities.isEmpty { enrichment.responsibilities = summary.responsibilities }
                let extra = summary.skills.filter { skill in !job.extractedSkills.contains { $0.caseInsensitiveCompare(skill) == .orderedSame } }
                if !extra.isEmpty { enrichment.skills = job.extractedSkills + extra }
                enrichments[id] = enrichment
                applyEnrichment(id)
            }
        }

        if !keywordChecked.contains(id), !candidateText.isEmpty {
            keywordChecked.insert(id)
            let current = opportunities.first { $0.id == id }
            let jobText = ([current?.aboutRole ?? job.about] + (current?.minimumQualifications ?? [])
                + (current?.preferredQualifications ?? []) + (current?.responsibilities ?? [])).joined(separator: "\n")
            if let gaps = await OnDeviceAI.missingKeywords(jobTitle: job.title, jobText: jobText, candidateText: candidateText) {
                var enrichment = enrichments[id] ?? JobEnrichment()
                enrichment.missingKeywords = gaps
                    .filter { !candidateText.localizedCaseInsensitiveContains($0.keyword) }
                    .map { MissingKeyword(keyword: $0.keyword, recommendation: $0.recommendation, placeholderTemplate: $0.example) }
                enrichments[id] = enrichment
                applyEnrichment(id)
            }
        }
    }

    private func applyEnrichment(_ id: String) {
        guard let enrichment = enrichments[id], let index = opportunities.firstIndex(where: { $0.id == id }) else { return }
        opportunities[index] = opportunities[index].enriched(enrichment, candidateSkills: candidate.skills)
    }

    /// The profile as plain text for the keyword comparison.
    static func describe(profile: UserProfile, achievements: [AchievementItem]) -> String {
        var lines = [profile.titleOrStage, profile.education, profile.bio, "Skills: " + profile.skills.joined(separator: ", ")]
        for exp in profile.experiences { lines.append("\(exp.title) at \(exp.company)"); lines += exp.bullets }
        for proj in profile.projects { lines.append("Project \(proj.title) (\(proj.techStack))"); lines += proj.bullets }
        lines += achievements.map { "\($0.title) \($0.issuer) \($0.descriptionText)" }
        return lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.joined(separator: "\n")
    }

    /// Opportunities for the notifications sheet: strong matches posted in the last few days.
    public var newMatchingOpportunities: [Opportunity] {
        opportunities
            .filter { $0.matchScore >= Self.recommendedThreshold && !$0.recency.isEmpty && $0.recencyInMinutes <= 3 * 1440 }
            .sorted { $0.recencyInMinutes < $1.recencyInMinutes }
            .prefix(20)
            .map { $0 }
    }

    private func rebuild() {
        opportunities = jobs
            .filter { !dismissedIDs.contains($0.id) }
            .map { job in
                Opportunity(
                    job: job,
                    match: serverScores[job.id].map {
                        MatchResult(score: $0.score, matchedSkills: $0.matchedSkills, missingSkills: $0.missingSkills)
                    } ?? MatchEngine.match(candidate, job: job),
                    isLiked: likedIDs.contains(job.id),
                    isApplied: appliedAt[job.id] != nil,
                    appliedAt: appliedAt[job.id].flatMap { $0.isEmpty ? nil : $0 }
                )
            }
            .map { opp in enrichments[opp.id].map { opp.enriched($0, candidateSkills: candidate.skills) } ?? opp }
            // Best match first; newest first among equals.
            .sorted { ($0.matchScore, -$0.recencyInMinutes) > ($1.matchScore, -$1.recencyInMinutes) }
        rebuildFilterOptions()
    }
}

// MARK: - Resume & AI Tailoring ViewModel
@MainActor
public final class ResumeViewModel: ObservableObject {
    @Published public var resumes: [ResumeDocument] = []
    @Published public var activeResume: ResumeDocument = .blank()
    @Published public var selectedFilterTab: ResumeFilterTab = .all
    @Published public var searchQuery: String = ""
    @Published public var activeTargetOpportunity: Opportunity? = nil
    /// Job picked via "Tailor Resume with AI"; the dashboard asks which resume to tailor while this is set
    @Published public var tailoringJob: Opportunity? = nil
    
    @Published public var showUploadSheet: Bool = false
    
    // Step 2 & 3: Template Sheet & Full Screen Navigation
    @Published public var showTemplatePickerSheet: Bool = false
    @Published public var pendingSelectedResume: ResumeDocument? = nil
    @Published public var selectedTemplateChoice: ResumeDocument.ResumeTemplate = .standard
    @Published public var shouldNavigateToEditor: Bool = false
    /// Opens the final A4 preview straight from the dashboard's resume menu
    @Published public var shouldNavigateToDirectPreview: Bool = false
    
    // Step 4 & 5: In-Editor Text Selection & AI Session Chat History
    @Published public var selectedSnippetTargetKey: String? = nil // e.g. "proj-0-bullet-0"
    @Published public var selectedSnippetText: String = ""
    @Published public var showAIPanel: Bool = false
    @Published public var userAIInstruction: String = ""
    @Published public var isGeneratingAI: Bool = false
    @Published public var sessionChatMessages: [AIChatMessage] = []
    @Published public var showSavedBanner: Bool = false
    /// Resume point just changed by Apply to Resume; the editor scrolls to it and highlights it briefly
    @Published public var flashedTargetKey: String? = nil
    
    // Step 6: Save & Preview & PDF Download
    @Published public var shouldNavigateToPrintPreview: Bool = false
    @Published public var isDownloadingPDF: Bool = false
    @Published public var hasDownloadedPDF: Bool = false
    @Published public var showDownloadConfirmation: Bool = false
    /// Where the last "Download PDF" was written (Files › On My iPhone › Aline › Resumes)
    @Published public var lastExportedPDF: URL? = nil
    /// An upload being read and structured
    @Published public var isImportingResume: Bool = false
    @Published public var importErrorMessage: String? = nil

    /// The latest profile, for "Build Resume from Profile" and profile-linked resumes
    private var profile: UserProfile = .empty
    private var achievements: [AchievementItem] = []

    public init() {}

    @Published public private(set) var isLoadingResumes: Bool = false

    /// Loads this device's resumes from the backend.
    public func load() async {
        isLoadingResumes = resumes.isEmpty
        defer { isLoadingResumes = false }
        guard let stored = try? await AlineAPI.resumes() else { return }
        resumes = stored.map(\.data.document)
        if !resumes.contains(where: \.isDefault), !resumes.isEmpty {
            resumes[0].isDefault = true
            persist(resumes[0])
        }
        if let current = resumes.first(where: { $0.id == activeResume.id }) ?? resumes.first {
            activeResume = current
        }
    }

    private func persist(_ resume: ResumeDocument) {
        Task { try? await AlineAPI.saveResume(resume) }
    }

    public func setMaster(_ resume: ResumeDocument) {
        for index in resumes.indices {
            let shouldBeDefault = resumes[index].id == resume.id
            guard resumes[index].isDefault != shouldBeDefault else { continue }
            resumes[index].isDefault = shouldBeDefault
            persist(resumes[index])
        }
    }

    public func deleteResume(_ resume: ResumeDocument) {
        guard !resume.isDefault else { return } // master resume cannot be deleted
        resumes.removeAll { $0.id == resume.id }
        Task { try? await AlineAPI.deleteResume(resume.id) }
    }

    /// Everything "Build Resume from Profile" needs: name, education and at least one of
    /// experience or projects, plus skills.
    public var isProfileCompleteForResume: Bool {
        let filled = { (text: String) in !text.trimmingCharacters(in: .whitespaces).isEmpty }
        return filled(profile.name) && filled(profile.education) && filled(profile.institution)
            && !profile.skills.isEmpty && (!profile.experiences.isEmpty || !profile.projects.isEmpty)
    }

    public func buildResumeFromProfile() {
        var resume = ResumeDocument.blank()
        resume.title = profile.name.isEmpty ? "My Resume" : profile.name
        resume.isLinkedToProfile = true
        resume.isDefault = resumes.isEmpty
        resume.cardColor = ResumeRecord.cardPalette[resumes.count % ResumeRecord.cardPalette.count]
        syncResume(&resume, with: profile, achievements: achievements)
        resumes.append(resume)
        persist(resume)
    }

    /// Reads an uploaded PDF, structures it (on-device model when available, heuristics
    /// otherwise) and adds it as a new resume.
    func importResume(from url: URL, onParsed: ((ResumeProfile) -> Void)? = nil) {
        let hasAccess = url.startAccessingSecurityScopedResource()
        let text = PDFTextExtractor.extractText(from: url)
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { $0 }
        let fileName = url.lastPathComponent
        if hasAccess { url.stopAccessingSecurityScopedResource() }

        guard let text, !text.isEmpty else {
            importErrorMessage = "We couldn't read text from that file. Try a PDF exported from a document editor rather than a scan."
            return
        }
        isImportingResume = true
        Task {
            let parsed = await ResumeStructurer.structure(resumeText: text)
            onParsed?(parsed)
            var resume = ResumeDocument(parsed: parsed, fileName: fileName, fileSize: size)
            resume.isDefault = resumes.isEmpty
            resume.cardColor = ResumeRecord.cardPalette[resumes.count % ResumeRecord.cardPalette.count]
            resumes.append(resume)
            persist(resume)
            isImportingResume = false
        }
    }

    public enum ResumeFilterTab: String, CaseIterable {
        case all = "All Resumes"
        case tailored = "Tailored Roles"
        case base = "Master / Default"
    }

    public var filteredResumes: [ResumeDocument] {
        var list = resumes

        switch selectedFilterTab {
        case .all:
            break
        case .tailored:
            list = list.filter { $0.targetCompany != nil && !$0.isDefault }
        case .base:
            list = list.filter { $0.isDefault }
        }

        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchQuery.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(query) ||
                $0.fileName.lowercased().contains(query) ||
                ($0.targetCompany?.lowercased().contains(query) ?? false) ||
                $0.skills.contains { $0.lowercased().contains(query) }
            }
        }

        return list
    }

    /// "Tailor Resume with AI" from a job: back to the dashboard root so the user picks a resume and template
    public func startTailoring(for opp: Opportunity) {
        self.activeTargetOpportunity = opp
        self.tailoringJob = opp
        self.showAIPanel = false
        self.showTemplatePickerSheet = false
        self.shouldNavigateToPrintPreview = false
        self.shouldNavigateToDirectPreview = false
        self.shouldNavigateToEditor = false
    }

    public func cancelTailoring() {
        self.tailoringJob = nil
    }

    public func setTargetOpportunity(_ opp: Opportunity) {
        self.activeTargetOpportunity = opp
        if let matching = resumes.first(where: { $0.targetCompany == opp.companyName }) {
            self.activeResume = matching
        }
    }

    // Step 2: User taps resume -> open template choice sheet with visual previews
    public func selectResumeForEditing(_ resume: ResumeDocument) {
        self.pendingSelectedResume = resume
        self.selectedTemplateChoice = resume.selectedTemplate
        self.showTemplatePickerSheet = true
    }

    // Step 3: Template confirmed -> navigate to full-screen editor
    public func confirmTemplateAndOpenEditor(template: ResumeDocument.ResumeTemplate) {
        guard var resume = pendingSelectedResume else { return }
        resume.selectedTemplate = template
        self.activeResume = resume
        self.showTemplatePickerSheet = false
        // Reset selection state and start session chat
        self.selectedSnippetTargetKey = nil
        self.selectedSnippetText = ""
        self.showAIPanel = false
        self.sessionChatMessages = [
            AIChatMessage(
                sender: .ai,
                text: "AI Assistant ready for \(resume.title). Tap any text in your resume and tell me what you'd like to improve."
            )
        ]
        self.shouldNavigateToEditor = true

        if let job = tailoringJob {
            tailoringJob = nil
            beginTailoringChat(for: job)
        }
    }

    // MARK: Tailoring to a job
    /// Skills the job lists that the resume match didn't detect
    public static func missingSkills(for job: Opportunity) -> [String] {
        job.skills.filter { !job.detectedKeywords.contains($0) }
    }

    /// Hands the job description, missing skills and keywords to the AI chat, then suggests point-by-point rewrites
    private func beginTailoringChat(for job: Opportunity) {
        let skills = Self.missingSkills(for: job)
        let keywords = job.missingKeywords.map(\.keyword)
        var prompt = "Tailor my resume for the \(job.roleTitle) role at \(job.companyName).\n\nJob description: \(job.aboutRole)"
        if !job.responsibilities.isEmpty {
            prompt += "\n\nResponsibilities: " + job.responsibilities.joined(separator: " ")
        }
        if !skills.isEmpty { prompt += "\n\nMissing skills: " + skills.joined(separator: ", ") }
        if !keywords.isEmpty { prompt += "\nMissing keywords: " + keywords.joined(separator: ", ") }

        sessionChatMessages = [AIChatMessage(sender: .user, text: prompt)]
        isGeneratingAI = true

        // Open the chat once the editor has been pushed, then analyze
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.showAIPanel = true
        }
        Task {
            let suggestions = await tailoringSuggestions(for: job, skills: skills)
            sessionChatMessages.append(contentsOf: suggestions)
            isGeneratingAI = false
        }
    }

    private func tailoringSuggestions(for job: Opportunity, skills: [String]) async -> [AIChatMessage] {
        // Every bullet the editor can rewrite, keyed like the editor's selections
        var bullets: [(key: String, text: String)] = []
        for (i, exp) in activeResume.experiences.enumerated() {
            for (j, bullet) in exp.bullets.enumerated() { bullets.append(("exp-\(i)-bullet-\(j)", bullet)) }
        }
        for (i, proj) in activeResume.projects.enumerated() {
            for (j, bullet) in proj.bullets.enumerated() { bullets.append(("proj-\(i)-bullet-\(j)", bullet)) }
        }

        let jobWords = Set((job.aboutRole + " " + job.responsibilities.joined(separator: " ") + " " + job.skills.joined(separator: " "))
            .lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count > 3 })
        func relevance(_ text: String) -> Int {
            Set(text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)).intersection(jobWords).count
        }
        func stem(_ bullet: String) -> String {
            let clause = bullet.split(separator: ";").first.map(String.init) ?? bullet
            return clause.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        }
        func lowerFirst(_ text: String) -> String {
            text.prefix(1).lowercased() + text.dropFirst()
        }

        // Most relevant points first, so each gap lands on a bullet that already fits the role
        var pool = bullets.sorted { relevance($0.text) > relevance($1.text) }
        var messages: [AIChatMessage] = []
        let missingCount = skills.count + job.missingKeywords.count

        let background = DiscoverViewModel.describe(profile: profile, achievements: achievements)
        let resumeText = plainText(of: activeResume)
        let jobText = ([job.aboutRole] + job.minimumQualifications + job.responsibilities).joined(separator: "\n")

        // A summary aimed at this role, from the resume + profile + achievement gallery
        if let summary = await OnDeviceAI.tailoredSummary(
            current: activeResume.summary, role: job.roleTitle, company: job.companyName,
            jobText: jobText, resumeText: resumeText, background: background
        ) {
            messages.append(AIChatMessage(
                sender: .ai,
                text: "Start with your summary — this version leads with what fits \(job.roleTitle):",
                targetKey: "summary",
                originalText: activeResume.summary,
                suggestedRewrite: summary.text,
                reason: summary.note
            ))
        }
        // Profile and achievement items that suit the role but aren't on this resume
        if let highlights = await OnDeviceAI.profileHighlights(
            role: job.roleTitle, company: job.companyName, jobText: jobText, resumeText: resumeText, background: background
        ), !highlights.isEmpty {
            messages.append(AIChatMessage(
                sender: .ai,
                text: "From your profile and achievements, these fit the role but aren't on this resume yet:\n" + highlights.map { "• \($0)" }.joined(separator: "\n")
            ))
        }

        guard missingCount > 0, !pool.isEmpty else {
            messages.append(AIChatMessage(sender: .ai, text: "Your resume already covers the skills and keywords for this role. Select any point if you'd like to sharpen it further."))
            return messages
        }
        messages.append(AIChatMessage(
            sender: .ai,
            text: "I compared your resume with the \(job.roleTitle) role at \(job.companyName). It's missing \(missingCount) of the skills and keywords they ask for, so here are the points I'd update:"
        ))

        for keyword in job.missingKeywords.prefix(2) where !pool.isEmpty {
            let target = pool.removeFirst()
            let rewrite = await OnDeviceAI.tailor(point: target.text, toShow: keyword.keyword, role: job.roleTitle, company: job.companyName, background: background)
            messages.append(AIChatMessage(
                sender: .ai,
                text: "This point is the best place to show \(keyword.keyword). \(rewrite?.note ?? keyword.recommendation)",
                targetKey: target.key,
                originalText: target.text,
                suggestedRewrite: rewrite?.text ?? "\(stem(target.text)); \(lowerFirst(keyword.placeholderTemplate))",
                reason: "Adds the keyword “\(keyword.keyword)” from the job description."
            ))
        }
        for skill in skills.prefix(3) where !pool.isEmpty {
            let target = pool.removeFirst()
            let rewrite = await OnDeviceAI.tailor(point: target.text, toShow: skill, role: job.roleTitle, company: job.companyName, background: background)
            messages.append(AIChatMessage(
                sender: .ai,
                text: "\(job.companyName) lists \(skill) as a core skill. Working it into this point makes the match clear:",
                targetKey: target.key,
                originalText: target.text,
                suggestedRewrite: rewrite?.text ?? "\(stem(target.text)) using \(skill).",
                reason: "Adds the missing skill “\(skill)”. Only apply it if you've actually used \(skill)."
            ))
        }
        return messages
    }

    // Step 4: Text selected in editor
    public func selectTextForAI(key: String, text: String) {
        self.selectedSnippetTargetKey = key
        self.selectedSnippetText = text
    }

    public func openAIPanel() {
        self.userAIInstruction = ""
        self.showAIPanel = true
    }

    // Step 5: User gives prompt -> AI generates suggestion and appends to session chat
    public func requestAISuggestion() {
        guard !userAIInstruction.trimmingCharacters(in: .whitespaces).isEmpty || !selectedSnippetText.isEmpty else { return }
        let currentPrompt = userAIInstruction.isEmpty ? "Improve phrasing and impact" : userAIInstruction
        let targetKey = selectedSnippetTargetKey ?? "general"
        let targetSnippet = selectedSnippetText

        // Add user message to conversation history
        let userMessage = AIChatMessage(
            sender: .user,
            text: currentPrompt,
            targetKey: targetKey,
            originalText: targetSnippet
        )
        sessionChatMessages.append(userMessage)
        self.userAIInstruction = ""
        // The selection goes with this message; the chip clears like a sent attachment
        self.selectedSnippetText = ""
        self.selectedSnippetTargetKey = nil

        isGeneratingAI = true

        Task {
            // Nothing selected: answer with advice for the whole resume; there's no single point to apply it to
            if targetSnippet.isEmpty {
                let advice = await OnDeviceAI.adviseOnResume(
                    currentPrompt, resumeText: plainText(of: activeResume),
                    background: DiscoverViewModel.describe(profile: profile, achievements: achievements),
                    targetRole: activeTargetOpportunity.map { "\($0.roleTitle) at \($0.companyName)" }
                )
                sessionChatMessages.append(AIChatMessage(
                    sender: .ai,
                    text: advice.map { "\($0)\n\nSelect the point you want changed and I'll write a version you can apply." }
                        ?? OnDeviceAI.unavailableMessage
                ))
                isGeneratingAI = false
                return
            }

            guard let rewrite = await OnDeviceAI.rewrite(
                targetSnippet, instruction: currentPrompt,
                context: activeTargetOpportunity.map { "\($0.roleTitle) at \($0.companyName)" },
                background: DiscoverViewModel.describe(profile: profile, achievements: achievements)
            ) else {
                sessionChatMessages.append(AIChatMessage(
                    sender: .ai,
                    text: OnDeviceAI.isAvailable ? "I couldn't write a version of that point. Try rephrasing the request." : OnDeviceAI.unavailableMessage
                ))
                isGeneratingAI = false
                return
            }
            sessionChatMessages.append(AIChatMessage(
                sender: .ai,
                text: rewrite.note,
                targetKey: targetKey,
                originalText: targetSnippet,
                suggestedRewrite: rewrite.text,
                reason: nil,
                isApplied: false
            ))
            isGeneratingAI = false
        }
    }

    /// The resume as plain text, for the assistant's whole-resume answers.
    private func plainText(of resume: ResumeDocument) -> String {
        var lines = [resume.summary]
        lines += resume.education.map { "\($0.degree), \($0.institution) \($0.period)" }
        for exp in resume.experiences { lines.append("\(exp.role) at \(exp.company) (\(exp.period))"); lines += exp.bullets }
        for proj in resume.projects { lines.append("Project: \(proj.title) [\(proj.techStack)]"); lines += proj.bullets }
        lines.append("Skills: " + resume.skills.joined(separator: ", "))
        lines += resume.achievements
        return lines.filter { !$0.isEmpty }.joined(separator: "\n")
    }

    // Step 6: Apply specific suggestion from chat history into the resume
    public func applyChatSuggestion(messageId: String) {
        guard let index = sessionChatMessages.firstIndex(where: { $0.id == messageId }),
              let rewrite = sessionChatMessages[index].suggestedRewrite,
              let key = sessionChatMessages[index].targetKey else { return }

        if key.starts(with: "proj-") {
            let parts = key.split(separator: "-")
            if parts.count >= 4, let projIdx = Int(parts[1]), let bulletIdx = Int(parts[3]) {
                if activeResume.projects.indices.contains(projIdx),
                   activeResume.projects[projIdx].bullets.indices.contains(bulletIdx) {
                    activeResume.projects[projIdx].bullets[bulletIdx] = rewrite
                }
            }
        } else if key.starts(with: "exp-") {
            let parts = key.split(separator: "-")
            if parts.count >= 4, let expIdx = Int(parts[1]), let bulletIdx = Int(parts[3]) {
                if activeResume.experiences.indices.contains(expIdx),
                   activeResume.experiences[expIdx].bullets.indices.contains(bulletIdx) {
                    activeResume.experiences[expIdx].bullets[bulletIdx] = rewrite
                }
            }
        } else if key == "summary" {
            activeResume.summary = rewrite
        }

        // Mark this message as applied (the Apply button itself shows the confirmation)
        sessionChatMessages[index].isApplied = true

        // Lower the chat so the resume is visible, then flash the point that changed
        showAIPanel = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.flashedTargetKey = key
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
            if self.flashedTargetKey == key { self.flashedTargetKey = nil }
        }
    }

    // Step 7: Save document changes -> commit to resumes and CLEAR THE CHAT
    public func saveDocumentChanges() {
        if let idx = resumes.firstIndex(where: { $0.id == activeResume.id }) {
            resumes[idx] = activeResume
            resumes[idx].lastModifiedDate = "Just now"
            persist(resumes[idx])
        }
        // Keep the session chat so the user can carry on refining after saving
        self.sessionChatMessages.append(AIChatMessage(sender: .system, text: "Changes saved to resume"))
        self.showSavedBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.showSavedBanner = false
        }
    }

    public func downloadResumePDF() {
        isDownloadingPDF = true
        hasDownloadedPDF = false
        // Let the button show "Preparing PDF..." before rendering blocks the main thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let url = try? ResumePDFExporter.export(self.activeResume)
            self.lastExportedPDF = url
            self.isDownloadingPDF = false
            self.hasDownloadedPDF = url != nil
            // Navigate to download confirmation screen
            self.showDownloadConfirmation = url != nil
        }
    }

    public func previewResume(_ resume: ResumeDocument) {
        self.activeResume = resume
        self.shouldNavigateToDirectPreview = true
    }

    public func returnToResumeDashboard() {
        self.showDownloadConfirmation = false
        self.shouldNavigateToDirectPreview = false
        self.shouldNavigateToPrintPreview = false
        self.shouldNavigateToEditor = false
        self.hasDownloadedPDF = false
        self.isDownloadingPDF = false
    }

    /// Profile edits flow into resumes built from the profile; uploaded and tailored resumes
    /// keep their own content.
    public func syncWithProfile(_ profile: UserProfile, achievements: [AchievementItem]? = nil) {
        self.profile = profile
        if let achievements { self.achievements = achievements }
        for i in resumes.indices where resumes[i].isLinkedToProfile {
            let before = resumes[i]
            syncResume(&resumes[i], with: profile, achievements: achievements)
            if resumes[i] != before { persist(resumes[i]) }
        }
        if activeResume.isLinkedToProfile, let current = resumes.first(where: { $0.id == activeResume.id }) {
            activeResume = current
        }
    }

    private func syncResume(_ resume: inout ResumeDocument, with profile: UserProfile, achievements: [AchievementItem]?) {
        let safeName = profile.name.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
        if !profile.name.isEmpty {
            resume.title = profile.name
            resume.fileName = safeName.isEmpty ? "Resume.pdf" : "\(safeName)_Resume.pdf"
        }
        resume.summary = profile.bio
        if !profile.institution.isEmpty || !profile.education.isEmpty {
            let period = profile.graduationYear.isEmpty ? "" :
                (profile.graduationYear.contains("–") || profile.graduationYear.contains("-") ? profile.graduationYear : "Class of \(profile.graduationYear)")
            resume.education = [ResumeEducation(
                id: resume.education.first?.id ?? "edu-primary",
                institution: profile.institution,
                degree: profile.education,
                period: period,
                location: profile.location,
                details: profile.titleOrStage
            )]
        }
        resume.skills = profile.skills
        resume.skillLines = profile.skills.isEmpty ? nil : [ResumeSkillLine("Core Skills", profile.skills.joined(separator: ", "))]
        // Newest entry is last on the profile; resumes list newest first
        resume.experiences = profile.experiences.reversed().map { exp in
            ResumeExperience(
                id: exp.id, company: exp.company, role: exp.title, period: exp.period, location: exp.location,
                bullets: exp.bullets.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
        }
        resume.projects = profile.projects.reversed().map { proj in
            ResumeProject(
                id: proj.id, title: proj.title, techStack: proj.techStack,
                bullets: proj.bullets.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
        }
        if let achItems = achievements {
            resume.achievements = achItems.map { item in
                item.issuer.isEmpty ? item.title : "\(item.title) — \(item.issuer)"
            }
        }
    }
}

// MARK: - Community ViewModel
@MainActor
public final class CommunityViewModel: ObservableObject {
    public enum CommunitySubFeed: String, CaseIterable {
        case forYou = "For You"
        case following = "Following"
    }

    @Published public var posts: [DiscussionPost] = []
    @Published public var companies: [CompanyCommunity] = []
    @Published public var selectedSubFeed: CommunitySubFeed = .forYou
    @Published public var selectedCategory: DiscussionType? = nil
    @Published public var activeCompanyFilter: String? = nil
    @Published public var showCreatePostSheet: Bool = false
    @Published public var showAllTrendingSheet: Bool = false
    @Published public var showSavedPostsSheet: Bool = false
    @Published public var searchQuery: String = ""
    /// The signed-in user's anonymous community handle, assigned by the backend
    @Published public private(set) var username: String = ""

    public var savedPosts: [DiscussionPost] {
        posts.filter { $0.isSaved }
    }

    public var trendingPosts: [DiscussionPost] {
        posts.sorted { $0.likesCount > $1.likesCount }
    }

    public var followedCompanies: [CompanyCommunity] {
        companies.filter { $0.isFollowing }
    }

    public var moreCompaniesToFollow: [CompanyCommunity] {
        companies.filter { !$0.isFollowing }
    }

    public var filteredPosts: [DiscussionPost] {
        var list = posts
        if let cat = selectedCategory {
            list = list.filter { $0.type == cat }
        }
        if let comp = activeCompanyFilter {
            list = list.filter { $0.companyName == comp }
        }
        if !searchQuery.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.fullContent.localizedCaseInsensitiveContains(searchQuery) ||
                $0.topics.contains { $0.localizedCaseInsensitiveContains(searchQuery) } ||
                ($0.companyName?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
                $0.authorName.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return list
    }

    public var postsForFollowedCompanies: [DiscussionPost] {
        let followedNames = Set(followedCompanies.map { $0.name.lowercased() })
        return filteredPosts.filter { post in
            guard let comp = post.companyName?.lowercased() else { return false }
            return followedNames.contains(comp)
        }
    }

    /// Loads identity, the feed and company communities from the backend.
    public func load() async {
        if let identity = try? await AlineAPI.identity() {
            username = identity.username
            if let avatar = identity.avatar { DiscussionPost.currentUserAvatar = avatar }
        }
        async let feed = try? AlineAPI.discussions()
        async let communities = try? AlineAPI.companies()
        if let feed = await feed {
            // Keep threads already opened, so a refresh doesn't blank an open discussion
            let loaded = Dictionary(uniqueKeysWithValues: posts.filter(\.commentsLoaded).map { ($0.id, $0.comments) })
            posts = feed.map { dto in
                var post = DiscussionPost(dto: dto)
                if let comments = loaded[dto.id] {
                    post.comments = comments
                    post.commentsLoaded = true
                }
                return post
            }
        }
        if let communities = await communities {
            companies = communities.map(CompanyCommunity.init(dto:))
        }
    }

    /// Fetches one discussion's full comment thread.
    public func loadComments(for postId: String) async {
        guard let detail = try? await AlineAPI.discussion(postId) else { return }
        let fresh = DiscussionPost(detail: detail)
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index] = fresh
        } else {
            posts.insert(fresh, at: 0)
        }
    }

    /// Threads for every post with comments — My Comments needs them all.
    public func loadAllComments() async {
        for post in posts where !post.commentsLoaded && post.totalCommentsCount > 0 {
            await loadComments(for: post.id)
        }
    }

    public func createPost(type: DiscussionType, company: String?, title: String, content: String, topics: [String]) {
        Task {
            guard let dto = try? await AlineAPI.createDiscussion(
                category: type.rawValue, company: company, title: title, body: content, topics: topics
            ) else { return }
            var post = DiscussionPost(dto: dto)
            post.commentsLoaded = true
            posts.insert(post, at: 0)
        }
    }

    public func toggleFollowCompany(name: String) {
        if let index = companies.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            companies[index].isFollowing.toggle()
        } else {
            companies.append(CompanyCommunity(
                id: "comp-\(name.lowercased())", name: name, symbol: "building.2.fill", memberCount: "1 member",
                description: "Discussions, interview advice, and updates for \(name).", isFollowing: true
            ))
        }
        Task {
            guard let following = try? await AlineAPI.toggleFollow(company: name),
                  let index = companies.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) else { return }
            companies[index].isFollowing = following
        }
    }

    public func isFollowing(companyName: String?) -> Bool {
        guard let name = companyName, !name.isEmpty else { return false }
        return companies.first(where: { $0.name.lowercased() == name.lowercased() })?.isFollowing ?? false
    }

    public func toggleLike(for postId: String) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        posts[index].isLiked.toggle()
        posts[index].likesCount += posts[index].isLiked ? 1 : -1
        Task {
            guard let liked = try? await AlineAPI.toggleLike(discussionID: postId),
                  let i = posts.firstIndex(where: { $0.id == postId }), posts[i].isLiked != liked else { return }
            posts[i].isLiked = liked
            posts[i].likesCount += liked ? 1 : -1
        }
    }

    public func toggleSave(for postId: String) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        posts[index].isSaved.toggle()
        Task {
            guard let saved = try? await AlineAPI.toggleSave(discussionID: postId),
                  let i = posts.firstIndex(where: { $0.id == postId }) else { return }
            posts[i].isSaved = saved
        }
    }

    public func addComment(to postId: String, text: String) {
        guard !text.isEmpty else { return }
        Task {
            guard let dto = try? await AlineAPI.addComment(discussionID: postId, body: text),
                  let index = posts.firstIndex(where: { $0.id == postId }) else { return }
            posts[index].comments.append(DiscussionComment(dto: dto))
            posts[index].serverCommentsCount = (posts[index].serverCommentsCount ?? 0) + 1
        }
    }

    public func addReply(to postId: String, commentId: String, text: String) {
        guard !text.isEmpty else { return }
        Task {
            guard let dto = try? await AlineAPI.addComment(discussionID: postId, body: text, parentID: commentId),
                  let postIndex = posts.firstIndex(where: { $0.id == postId }) else { return }
            // Replies are one level deep: the backend files a reply-to-a-reply under its top-level comment
            let parentId = dto.parentId ?? commentId
            if let commentIndex = posts[postIndex].comments.firstIndex(where: { $0.id == parentId }) {
                posts[postIndex].comments[commentIndex].replies.append(DiscussionComment(dto: dto))
            }
            posts[postIndex].serverCommentsCount = (posts[postIndex].serverCommentsCount ?? 0) + 1
        }
    }

    public func toggleLikeComment(postId: String, commentId: String) {
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else { return }
        if let commentIndex = posts[postIndex].comments.firstIndex(where: { $0.id == commentId }) {
            posts[postIndex].comments[commentIndex].isLiked.toggle()
            posts[postIndex].comments[commentIndex].likesCount += posts[postIndex].comments[commentIndex].isLiked ? 1 : -1
        } else {
            for (cIndex, comment) in posts[postIndex].comments.enumerated() {
                if let rIndex = comment.replies.firstIndex(where: { $0.id == commentId }) {
                    posts[postIndex].comments[cIndex].replies[rIndex].isLiked.toggle()
                    posts[postIndex].comments[cIndex].replies[rIndex].likesCount += posts[postIndex].comments[cIndex].replies[rIndex].isLiked ? 1 : -1
                    break
                }
            }
        }
        Task { _ = try? await AlineAPI.toggleCommentLike(commentId) }
    }

    public func incrementShare(for postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].sharesCount += 1
        }
        Task { _ = try? await AlineAPI.share(discussionID: postId) }
    }

    public func deleteComment(postId: String, commentId: String) {
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else { return }
        var removed = 0
        if let commentIndex = posts[postIndex].comments.firstIndex(where: { $0.id == commentId }) {
            removed = 1 + posts[postIndex].comments[commentIndex].replies.count
            posts[postIndex].comments.remove(at: commentIndex)
        } else {
            for cIndex in 0..<posts[postIndex].comments.count {
                if let rIndex = posts[postIndex].comments[cIndex].replies.firstIndex(where: { $0.id == commentId }) {
                    posts[postIndex].comments[cIndex].replies.remove(at: rIndex)
                    removed = 1
                    break
                }
            }
        }
        posts[postIndex].serverCommentsCount = max(0, (posts[postIndex].serverCommentsCount ?? 0) - removed)
        Task { try? await AlineAPI.deleteComment(commentId) }
    }

    public init() {}
}

// MARK: - Interview Prep ViewModel
@MainActor
public final class InterviewPrepViewModel: ObservableObject {
    @Published public var questions: [InterviewQuestion] = []
    
    // Multiple selection support (Items 3 & 4)
    @Published public var selectedCompanies: Set<String> = []
    @Published public var selectedRoles: Set<String> = []
    @Published public var selectedTopics: Set<QuestionTopic> = []
    
    @Published public var searchQuery: String = ""
    @Published public var isSearchActive: Bool = false
    @Published public var revealedHints: Set<String> = []
    @Published public var revealedApproaches: Set<String> = []
    @Published public var revealedSolutions: Set<String> = []
    @Published public var isGeneratingAISolution: [String: Bool] = [:]
    
    @Published public var showContributeSheet: Bool = false
    @Published public var showAllCompaniesSheet: Bool = false
    @Published public var showAllRolesSheet: Bool = false
    @Published public var showAllTopicsSheet: Bool = false
    @Published public var showFilteredResultsScreen: Bool = false
    @Published public var showSavedQuestionsSheet: Bool = false
    @Published public var lastVisitedSession: LastVisitedQuestionSession? = nil

    public var savedQuestions: [InterviewQuestion] {
        questions.filter { $0.isSaved }
    }

    // MARK: - 3-Step Guided Drill-Down Wizard Workflows
    public enum WizardEntryFacet: String, Codable {
        case company // 1. Company -> 2. Role -> 3. Topic -> Questions
        case role    // 1. Role -> 2. Company -> 3. Topic -> Questions
        case topic   // 1. Topic -> 2. Role -> 3. Company -> Questions
    }

    @Published public var wizardActive: Bool = false
    @Published public var wizardEntry: WizardEntryFacet = .company
    @Published public var wizardStep: Int = 1 // 1: second facet, 2: third facet, 3: questions results
    @Published public var wizardSelectedCompany: String? = nil
    @Published public var wizardSelectedRole: String? = nil
    @Published public var wizardSelectedTopic: QuestionTopic? = nil
    @Published public var wizardSelectedTopics: Set<QuestionTopic> = []
    @Published public var wizardSearchQuery: String = ""

    public func startWizardFromCompany(_ company: String) {
        wizardEntry = .company
        wizardSelectedCompany = company
        wizardSelectedRole = nil
        wizardSelectedTopic = nil
        wizardSelectedTopics = []
        wizardStep = 1
        wizardSearchQuery = ""
        wizardActive = true
    }

    public func startWizardFromRole(_ role: String) {
        wizardEntry = .role
        wizardSelectedRole = role
        wizardSelectedCompany = nil
        wizardSelectedTopic = nil
        wizardSelectedTopics = []
        wizardStep = 1
        wizardSearchQuery = ""
        wizardActive = true
    }

    public func startWizardFromTopic(_ topic: QuestionTopic) {
        wizardEntry = .topic
        wizardSelectedTopic = topic
        wizardSelectedTopics = [topic]
        wizardSelectedRole = nil
        wizardSelectedCompany = nil
        wizardStep = 1
        wizardSearchQuery = ""
        wizardActive = true
    }

    public func toggleWizardTopic(_ topic: QuestionTopic) {
        if wizardSelectedTopics.contains(topic) {
            wizardSelectedTopics.remove(topic)
        } else {
            wizardSelectedTopics.insert(topic)
        }
        wizardSelectedTopic = wizardSelectedTopics.first
    }

    public func resetWizard() {
        wizardActive = false
        wizardStep = 1
        wizardSelectedCompany = nil
        wizardSelectedRole = nil
        wizardSelectedTopic = nil
        wizardSelectedTopics.removeAll()
        wizardSearchQuery = ""
    }

    public var wizardFilteredQuestions: [InterviewQuestion] {
        var list = questions
        if let comp = wizardSelectedCompany {
            list = list.filter { q in
                guard let c = q.companyName else { return false }
                return c.localizedCaseInsensitiveContains(comp) || comp.localizedCaseInsensitiveContains(c)
            }
        }
        if let role = wizardSelectedRole {
            list = list.filter { q in
                guard let r = q.role else { return false }
                return r.localizedCaseInsensitiveContains(role) || role.localizedCaseInsensitiveContains(r)
            }
        }
        if !wizardSelectedTopics.isEmpty {
            list = list.filter { wizardSelectedTopics.contains($0.topic) }
        } else if let topic = wizardSelectedTopic {
            list = list.filter { $0.topic == topic }
        }
        if !wizardSearchQuery.isEmpty {
            list = list.filter {
                $0.questionText.localizedCaseInsensitiveContains(wizardSearchQuery) ||
                ($0.companyName?.localizedCaseInsensitiveContains(wizardSearchQuery) ?? false) ||
                ($0.role?.localizedCaseInsensitiveContains(wizardSearchQuery) ?? false) ||
                $0.topic.rawValue.localizedCaseInsensitiveContains(wizardSearchQuery)
            }
        }
        return list
    }

    // Compatibility accessors
    public var selectedCompany: String? {
        get { selectedCompanies.first }
        set {
            if let val = newValue {
                selectedCompanies = [val]
            } else {
                selectedCompanies.removeAll()
            }
        }
    }

    public var selectedRole: String? {
        get { selectedRoles.first }
        set {
            if let val = newValue {
                selectedRoles = [val]
            } else {
                selectedRoles.removeAll()
            }
        }
    }

    public var selectedTopic: QuestionTopic? {
        get { selectedTopics.first }
        set {
            if let val = newValue {
                selectedTopics = [val]
            } else {
                selectedTopics.removeAll()
            }
        }
    }

    public let popularCompanies: [String] = [
        "Google", "Microsoft", "Amazon",
        "Apple", "Meta", "Wells Fargo"
    ]

    public let allCompanies: [String] = [
        "Google", "Microsoft", "Amazon", "Apple",
        "Meta", "TCS", "Infosys", "Wells Fargo",
        "Flipkart", "Netflix", "Uber", "Spotify",
        "Airbnb", "Goldman Sachs", "JPMorgan", "Stripe",
        "Adobe", "Salesforce", "Cisco", "Intel",
        "Nvidia", "Databricks", "Snowflake", "Palantir"
    ]

    public let popularRoles: [String] = [
        "Software Engineer", "Data Analyst", "AI/ML Engineer",
        "Product Manager", "DevOps Engineer"
    ]

    public let allRoles: [String] = [
        "Software Engineer", "Data Analyst", "AI/ML Engineer",
        "Product Manager", "DevOps Engineer", "Backend Engineer",
        "Frontend Engineer", "Full Stack Engineer", "iOS / Mobile Engineer",
        "Cloud Solutions Architect", "Cybersecurity Analyst", "Data Engineer",
        "Quantitative Analyst"
    ]

    public let popularTopics: [QuestionTopic] = [
        .dsa, .systemDesign, .coreCS, .dbms, .networking, .behavioral
    ]

    public var hasActiveFilters: Bool {
        !selectedCompanies.isEmpty || !selectedRoles.isEmpty || !selectedTopics.isEmpty || !searchQuery.isEmpty
    }

    public var activeFilterCount: Int {
        selectedCompanies.count + selectedRoles.count + selectedTopics.count
    }

    public var filteredQuestions: [InterviewQuestion] {
        var list = questions
        if !selectedCompanies.isEmpty {
            list = list.filter { q in
                guard let comp = q.companyName else { return false }
                return selectedCompanies.contains { sel in
                    comp.localizedCaseInsensitiveContains(sel) || sel.localizedCaseInsensitiveContains(comp)
                }
            }
        }
        if !selectedRoles.isEmpty {
            list = list.filter { q in
                guard let r = q.role else { return false }
                return selectedRoles.contains { sel in
                    r.localizedCaseInsensitiveContains(sel) || sel.localizedCaseInsensitiveContains(r)
                }
            }
        }
        if !selectedTopics.isEmpty {
            list = list.filter { selectedTopics.contains($0.topic) }
        }
        if !searchQuery.isEmpty {
            list = list.filter {
                $0.questionText.localizedCaseInsensitiveContains(searchQuery) ||
                ($0.companyName?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
                ($0.role?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
                $0.topic.rawValue.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return list
    }

    public func toggleCompany(_ company: String) {
        if selectedCompanies.contains(company) {
            selectedCompanies.remove(company)
        } else {
            selectedCompanies.insert(company)
        }
    }

    public func selectCompany(_ company: String) {
        toggleCompany(company)
    }

    public func toggleRole(_ role: String) {
        if selectedRoles.contains(role) {
            selectedRoles.remove(role)
        } else {
            selectedRoles.insert(role)
        }
    }

    public func selectRole(_ role: String) {
        toggleRole(role)
    }

    public func toggleTopic(_ topic: QuestionTopic) {
        if selectedTopics.contains(topic) {
            selectedTopics.remove(topic)
        } else {
            selectedTopics.insert(topic)
        }
    }

    public func selectTopic(_ topic: QuestionTopic) {
        toggleTopic(topic)
    }

    public func clearAllFilters() {
        selectedCompanies.removeAll()
        selectedRoles.removeAll()
        selectedTopics.removeAll()
        searchQuery = ""
    }

    public func toggleUpvote(for questionId: String) {
        guard let question = questions.first(where: { $0.id == questionId }) else { return }
        toggleUpvote(for: question)
    }

    public func toggleUpvote(for question: InterviewQuestion) {
        guard let index = questions.firstIndex(where: { $0.id == question.id }) else { return }
        questions[index].isUpvoted.toggle()
        questions[index].upvotesCount += questions[index].isUpvoted ? 1 : -1
        Task {
            guard let upvoted = try? await AlineAPI.toggleUpvote(questionID: question.id),
                  let i = questions.firstIndex(where: { $0.id == question.id }), questions[i].isUpvoted != upvoted else { return }
            questions[i].isUpvoted = upvoted
            questions[i].upvotesCount += upvoted ? 1 : -1
        }
    }

    public func toggleSave(for questionId: String) {
        guard let question = questions.first(where: { $0.id == questionId }) else { return }
        toggleSave(for: question)
    }

    public func toggleSave(for question: InterviewQuestion) {
        guard let index = questions.firstIndex(where: { $0.id == question.id }) else { return }
        questions[index].isSaved.toggle()
        Task {
            guard let saved = try? await AlineAPI.toggleSave(questionID: question.id),
                  let i = questions.firstIndex(where: { $0.id == question.id }) else { return }
            questions[i].isSaved = saved
        }
    }

    public func load() async {
        guard let fetched = try? await AlineAPI.interviewQuestions() else { return }
        // Keep on-device AI solutions already generated this session
        let aiAnswers = Dictionary(uniqueKeysWithValues: questions.compactMap { q in q.aiGeneratedAnswer.map { (q.id, $0) } })
        questions = fetched.map { dto in
            let question = InterviewQuestion(dto: dto)
            return aiAnswers[dto.id].map { question.withAIAnswer($0) } ?? question
        }
    }

    public func toggleHint(for id: String) {
        if revealedHints.contains(id) {
            revealedHints.remove(id)
        } else {
            revealedHints.insert(id)
        }
    }

    public func revealHint(for id: String) {
        revealedHints.insert(id)
    }

    public func toggleApproach(for id: String) {
        if revealedApproaches.contains(id) {
            revealedApproaches.remove(id)
        } else {
            revealedApproaches.insert(id)
        }
    }

    public func revealApproach(for id: String) {
        revealedApproaches.insert(id)
    }

    public func toggleSolution(for id: String) {
        if revealedSolutions.contains(id) {
            revealedSolutions.remove(id)
        } else {
            revealedSolutions.insert(id)
        }
    }

    public func revealSolution(for id: String) {
        revealedSolutions.insert(id)
    }

    /// Writes a solution with the on-device model for a question nobody answered yet. The
    /// detail screen labels it as AI-written; it stays on this device.
    public func generateAISolution(for id: String) {
        guard let question = questions.first(where: { $0.id == id }) else { return }
        isGeneratingAISolution[id] = true
        Task {
            let solution = await OnDeviceAI.solve(
                question: question.questionText, topic: question.topic.rawValue,
                company: question.companyName, role: question.role
            )
            let text = solution.map { "\($0.approach)\n\n\($0.answer)" } ?? OnDeviceAI.unavailableMessage
            if let index = questions.firstIndex(where: { $0.id == id }) {
                questions[index] = questions[index].withAIAnswer(text)
            }
            isGeneratingAISolution[id] = false
            revealedSolutions.insert(id)
        }
    }

    public func addQuestion(
        questionText: String,
        topic: QuestionTopic,
        company: String,
        role: String,
        difficulty: String = "General",
        hint: String?,
        approach: String?,
        answer: String?
    ) {
        let trimmedAnswer = answer?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasProvidedAnswer = !(trimmedAnswer?.isEmpty ?? true)
        // Shown right away (the contribute flow jumps straight to it), replaced by the saved copy
        let placeholderID = "pending-\(UUID().uuidString)"
        let pending = InterviewQuestion(
            id: placeholderID,
            questionText: questionText,
            topic: topic,
            companyName: company.isEmpty ? nil : company,
            role: role.isEmpty ? nil : role,
            difficulty: difficulty,
            upvotesCount: 1,
            isUpvoted: true,
            isSaved: false,
            hint: (hint?.isEmpty ?? true) ? nil : hint,
            approach: (approach?.isEmpty ?? true) ? nil : approach,
            answer: hasProvidedAnswer ? trimmedAnswer : nil,
            aiGeneratedAnswer: nil,
            hasAIGeneratedSolution: !hasProvidedAnswer,
            isCommunityReported: true
        )
        questions.insert(pending, at: 0)

        Task {
            let request = CreateQuestionRequest(
                deviceId: DeviceIdentity.deviceID, question: questionText, topic: topic.rawValue,
                company: pending.companyName, role: pending.role, difficulty: difficulty,
                hint: pending.hint, approach: pending.approach, answer: pending.answer
            )
            guard let saved = try? await AlineAPI.createQuestion(request) else {
                questions.removeAll { $0.id == placeholderID }
                return
            }
            if let index = questions.firstIndex(where: { $0.id == placeholderID }) {
                questions[index] = InterviewQuestion(dto: saved)
            }
        }
    }

    public func recordVisitedQuestion(
        question: InterviewQuestion,
        in questionsList: [InterviewQuestion],
        company: String? = nil,
        role: String? = nil,
        topic: QuestionTopic? = nil
    ) {
        let index = questionsList.firstIndex(where: { $0.id == question.id }) ?? 0
        let resolvedCompany = company ?? question.companyName ?? wizardSelectedCompany
        let resolvedRole = role ?? question.role ?? wizardSelectedRole
        let resolvedTopic = topic ?? question.topic

        let session = LastVisitedQuestionSession(
            questionId: question.id,
            questionText: question.questionText,
            companyName: resolvedCompany,
            role: resolvedRole,
            topic: resolvedTopic,
            questionsList: questionsList,
            questionIndex: index,
            totalQuestions: questionsList.count,
            timestamp: Date()
        )
        self.lastVisitedSession = session

        // Persist to UserDefaults
        if let encoded = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encoded, forKey: "savedLastVisitedQuestionSession")
        }
    }

    public func clearLastVisitedSession() {
        self.lastVisitedSession = nil
        UserDefaults.standard.removeObject(forKey: "savedLastVisitedQuestionSession")
    }

    public init() {
        if let data = UserDefaults.standard.data(forKey: "savedLastVisitedQuestionSession"),
           let decoded = try? JSONDecoder().decode(LastVisitedQuestionSession.self, from: data) {
            self.lastVisitedSession = decoded
        }
        // No saved session means nothing viewed yet, so "Continue from where you left" stays hidden
    }
}

// MARK: - Profile Update Notification
public extension Notification.Name {
    static let userProfileDidUpdate = Notification.Name("AlineUserProfileDidUpdateNotification")
    /// A profile/preferences/achievements change reached the backend (recommendations depend on it)
    static let profileDidSave = Notification.Name("AlineProfileDidSave")
}

// MARK: - Profile & Preferences ViewModel
@MainActor
public final class ProfileViewModel: ObservableObject {
    @Published public var profile: UserProfile = .empty
    @Published public var preferences: CareerPreferences = .empty
    @Published public var achievements: [AchievementItem] = []
    @Published public var showEditProfileSheet: Bool = false
    @Published public var showPreferencesSheet: Bool = false
    @Published public var showAddAchievementSheet: Bool = false
    @Published public var selectedAchievement: AchievementItem? = nil
    /// True once the backend profile has been read at least once this session
    @Published public private(set) var hasLoaded: Bool = false

    public var onProfileUpdated: ((UserProfile) -> Void)? = nil

    public init() {
        // Cached copy, so the profile isn't blank while the backend is reached
        if let data = UserDefaults.standard.data(forKey: "savedUserProfile"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = decoded
        } else {
            profile.name = UserDefaults.standard.string(forKey: "userFullName") ?? ""
        }
        if let data = UserDefaults.standard.data(forKey: "savedUserAchievements"),
           let decoded = try? JSONDecoder().decode([AchievementItem].self, from: data) {
            achievements = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "savedCareerPreferences"),
           let decoded = try? JSONDecoder().decode(CareerPreferences.self, from: data) {
            preferences = decoded
        }
    }

    /// Reads the profile, achievements and preferences from the backend.
    public func load() async {
        guard let dto = try? await AlineAPI.profile() else { return }
        let signedInName = UserDefaults.standard.string(forKey: "userFullName") ?? ""
        var loaded = UserProfile(dto: dto, fallbackName: signedInName)
        if loaded.name.isEmpty { loaded.name = signedInName }
        profile = loaded
        achievements = dto.achievements.map(AchievementItem.init(dto:))
        if let prefs = dto.preferences {
            var updated = CareerPreferences(dto: prefs)
            updated.isPushAllowedByOS = preferences.isPushAllowedByOS
            preferences = updated
        }
        cacheLocally()
        hasLoaded = true
        // A name typed at sign-up that the backend doesn't have yet
        if dto.name == nil, !signedInName.isEmpty {
            var request = ProfileUpdateRequest(deviceId: DeviceIdentity.deviceID)
            request.name = signedInName
            Task { try? await AlineAPI.updateProfile(request) }
        }
        onProfileUpdated?(profile)
    }

    public func syncWithStoredUser() {
        if let name = UserDefaults.standard.string(forKey: "userFullName"), !name.isEmpty, profile.name.isEmpty {
            self.profile.name = name
        }
    }

    private func cacheLocally() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "savedUserProfile")
        }
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "savedUserAchievements")
        }
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "savedCareerPreferences")
        }
        // Keys the resume templates and greeting read through @AppStorage
        let defaults = UserDefaults.standard
        defaults.set(profile.name, forKey: "userFullName")
        defaults.set(profile.location, forKey: "userLocation")
        defaults.set(profile.bio, forKey: "userBio")
        defaults.set(profile.education, forKey: "userEducation")
        defaults.set(profile.institution, forKey: "userInstitution")
        defaults.set(profile.graduationYear, forKey: "userGraduationYear")
        defaults.set(profile.linkedInURL, forKey: "userLinkedIn")
        defaults.set(profile.githubURL, forKey: "userGitHub")
        defaults.set(profile.portfolioURL, forKey: "userPortfolio")
    }

    public func deleteAchievement(id: String) {
        if achievements.contains(where: { $0.id == id && $0.attachmentName != nil }) {
            AttachmentStore.delete(forAchievement: id)
        }
        achievements.removeAll { $0.id == id }
        saveAchievements()
        NotificationCenter.default.post(name: .userProfileDidUpdate, object: profile)
    }

    public func achievements(in category: AchievementCategory) -> [AchievementItem] {
        achievements.filter { $0.category == category }
    }

    public func upsertAchievement(_ item: AchievementItem) {
        if item.attachmentName == nil, achievements.contains(where: { $0.id == item.id && $0.attachmentName != nil }) {
            AttachmentStore.delete(forAchievement: item.id)
        }
        if let index = achievements.firstIndex(where: { $0.id == item.id }) {
            achievements[index] = item
        } else {
            achievements.insert(item, at: 0)
        }
        saveAchievements()
        NotificationCenter.default.post(name: .userProfileDidUpdate, object: profile)
    }

    private func saveAchievements() {
        cacheLocally()
        var request = ProfileUpdateRequest(deviceId: DeviceIdentity.deviceID)
        request.achievements = achievements.map(\.dto)
        save(request)
    }

    /// Saves to the backend, then announces it so recommendations re-rank on the saved profile.
    private func save(_ request: ProfileUpdateRequest) {
        Task {
            if (try? await AlineAPI.updateProfile(request)) != nil {
                NotificationCenter.default.post(name: .profileDidSave, object: nil)
            }
        }
    }

    public func updateProfile(_ updated: UserProfile) {
        profile = updated
        cacheLocally()
        save(updated.updateRequest())

        onProfileUpdated?(updated)
        NotificationCenter.default.post(name: .userProfileDidUpdate, object: updated)
    }

    /// The Opportunity Alerts toggle: asks for notification permission when turned on, and saves.
    public func setJobAlerts(_ enabled: Bool) {
        Task {
            var updated = preferences
            updated.alertsEnabled = enabled
            if enabled {
                updated.isPushAllowedByOS = await JobAlerts.requestPermission()
                JobAlerts.scheduleBackgroundRefresh()
            }
            updatePreferences(updated)
        }
    }

    public func updatePreferences(_ updated: CareerPreferences) {
        preferences = updated
        cacheLocally()
        var request = ProfileUpdateRequest(deviceId: DeviceIdentity.deviceID)
        request.preferences = updated.dto
        save(request)
        onProfileUpdated?(profile)
    }
}
