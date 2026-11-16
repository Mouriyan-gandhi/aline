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
    @Published public var unreadNotificationsCount: Int = 4
    /// Notifications opened one by one; "Mark all read" clears every dot by zeroing the count
    @Published public var readNotificationIDs: Set<String> = []

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
        self.currentUserFullName = defaults.string(forKey: "userFullName") ?? "Aarav Sharma"
        self.currentUserEmail = defaults.string(forKey: "userEmail") ?? "aarav.sharma@example.com"
        self.currentUserPhone = defaults.string(forKey: "userPhone") ?? "+91 99520 86492"

        // Automatically sync whenever user profile updates anywhere in the app
        NotificationCenter.default.addObserver(
            forName: .userProfileDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let updated = notification.object as? UserProfile {
                let clean = updated.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty {
                    self?.currentUserFullName = clean
                }
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
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "isAuthenticated")
        defaults.removeObject(forKey: "hasCompletedOnboarding")
        defaults.removeObject(forKey: "userFullName")
        defaults.removeObject(forKey: "userEmail")
        defaults.removeObject(forKey: "userPhone")
        defaults.removeObject(forKey: "savedLastVisitedQuestionSession")

        self.currentUserFullName = "Aarav Sharma"
        self.currentUserEmail = "aarav.sharma@example.com"
        self.currentUserPhone = "+91 99520 86492"
        self.hasCompletedOnboarding = false
        self.isAuthenticated = false
    }

    public func resetOnboardingForDemo() {
        self.hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Discover & Stacked Card ViewModel
@MainActor
public final class DiscoverViewModel: ObservableObject {
    @Published public var opportunities: [Opportunity] = Opportunity.samples
    @Published public var searchQuery: String = ""
    @Published public var selectedFilterTab: FilterTab = .recommended
    @Published public var showFilterSheet: Bool = false
    @Published public var selectedOpportunity: Opportunity? = nil

    // Stacked Card Interaction State
    @Published public var expandedCardId: String? = "opp-google-4" // Google expanded by default like screenshot!
    
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
            let target = (filterJobType == "Full Time") ? "fullTime" : "internship"
            list = list.filter { $0.opportunityType.rawValue.localizedCaseInsensitiveContains(target) }
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
                activeLocations.contains { loc in opp.location.localizedCaseInsensitiveContains(loc) }
            }
        } else if filterLocation != "All" {
            list = list.filter { $0.location.localizedCaseInsensitiveContains(filterLocation) }
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

    // Only opportunities with match score > 85%
    public var recommendedOpportunities: [Opportunity] {
        filteredOpportunities.filter { $0.matchScore > 85 }
    }

    // All opportunities with match score <= 85% (showing all roles across tech regardless of onboarding choice)
    public var exploreMoreOpportunities: [Opportunity] {
        var list = opportunities.filter { $0.matchScore <= 85 }

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
            let target = (filterJobType == "Full Time") ? "fullTime" : "internship"
            list = list.filter { $0.opportunityType.rawValue.localizedCaseInsensitiveContains(target) }
        }

        if filterWorkMode != "All" {
            let mode = filterWorkMode.lowercased().replacingOccurrences(of: "-", with: "")
            list = list.filter {
                $0.workMode.rawValue.lowercased().replacingOccurrences(of: "-", with: "") == mode
            }
        }

        let activeLocations = selectedLocations.filter { $0 != "All" && !$0.isEmpty }
        if !activeLocations.isEmpty {
            list = list.filter { opp in
                activeLocations.contains { loc in opp.location.localizedCaseInsensitiveContains(loc) }
            }
        } else if filterLocation != "All" {
            list = list.filter { $0.location.localizedCaseInsensitiveContains(filterLocation) }
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
        if let index = opportunities.firstIndex(where: { $0.id == id }) {
            opportunities[index].isLiked.toggle()
        }
    }

    public func markApplied(for id: String) {
        if let index = opportunities.firstIndex(where: { $0.id == id }) {
            opportunities[index].isApplied = true
            opportunities[index].applicationDate = "Applied just now"
        }
    }

    public init() {}
}

// MARK: - Resume & AI Tailoring ViewModel
@MainActor
public final class ResumeViewModel: ObservableObject {
    @Published public var resumes: [ResumeDocument] = ResumeDocument.samples
    @Published public var activeResume: ResumeDocument = ResumeDocument.samples[0]
    @Published public var selectedFilterTab: ResumeFilterTab = .all
    @Published public var searchQuery: String = ""
    @Published public var activeTargetOpportunity: Opportunity? = Opportunity.samples[0]
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

    public init() {
        // Observe profile updates
        NotificationCenter.default.addObserver(
            forName: .userProfileDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let updated = notification.object as? UserProfile {
                self?.syncWithProfile(updated)
            }
        }

        // Initialize with saved profile or stored user details if available
        if let data = UserDefaults.standard.data(forKey: "savedUserProfile"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data),
           decoded.experiences.count >= 3 {
            syncWithProfile(decoded)
        } else {
            let storedName = UserDefaults.standard.string(forKey: "userFullName") ?? "Aarav Sharma"
            var temp = UserProfile.sample
            temp.name = storedName
            if let loc = UserDefaults.standard.string(forKey: "userLocation"), !loc.isEmpty {
                temp.location = loc
            }
            if let bio = UserDefaults.standard.string(forKey: "userBio"), !bio.isEmpty {
                temp.bio = bio
            }
            if let edu = UserDefaults.standard.string(forKey: "userEducation"), !edu.isEmpty {
                temp.education = edu
            }
            if let inst = UserDefaults.standard.string(forKey: "userInstitution"), !inst.isEmpty {
                temp.institution = inst
            }
            if let grad = UserDefaults.standard.string(forKey: "userGraduationYear"), !grad.isEmpty {
                temp.graduationYear = grad
            }
            if let lIn = UserDefaults.standard.string(forKey: "userLinkedIn"), !lIn.isEmpty {
                temp.linkedInURL = lIn
            }
            if let git = UserDefaults.standard.string(forKey: "userGitHub"), !git.isEmpty {
                temp.githubURL = git
            }
            syncWithProfile(temp)
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

        // Open the chat once the editor has been pushed, then "analyze"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.showAIPanel = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            self.sessionChatMessages.append(contentsOf: self.tailoringSuggestions(for: job, skills: skills))
            self.isGeneratingAI = false
        }
    }

    private func tailoringSuggestions(for job: Opportunity, skills: [String]) -> [AIChatMessage] {
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

        guard missingCount > 0, !pool.isEmpty else {
            return [AIChatMessage(sender: .ai, text: "Your resume already covers the skills and keywords for this role. Select any point if you'd like to sharpen it further.")]
        }
        messages.append(AIChatMessage(
            sender: .ai,
            text: "I compared your resume with the \(job.roleTitle) role at \(job.companyName). It's missing \(missingCount) of the skills and keywords they ask for, so here are the points I'd update:"
        ))

        for keyword in job.missingKeywords.prefix(2) where !pool.isEmpty {
            let target = pool.removeFirst()
            messages.append(AIChatMessage(
                sender: .ai,
                text: "This point is the best place to show \(keyword.keyword). \(keyword.recommendation)",
                targetKey: target.key,
                originalText: target.text,
                suggestedRewrite: "\(stem(target.text)); \(lowerFirst(keyword.placeholderTemplate))",
                reason: "Adds the keyword “\(keyword.keyword)” from the job description."
            ))
        }
        for skill in skills.prefix(3) where !pool.isEmpty {
            let target = pool.removeFirst()
            messages.append(AIChatMessage(
                sender: .ai,
                text: "\(job.companyName) lists \(skill) as a core skill. Working it into this point makes the match clear:",
                targetKey: target.key,
                originalText: target.text,
                suggestedRewrite: "\(stem(target.text)) using \(skill).",
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

        // Nothing selected: answer with advice for the whole resume; there's no single point to apply it to
        if targetSnippet.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.sessionChatMessages.append(AIChatMessage(
                    sender: .ai,
                    text: "Here's how I'd approach “\(currentPrompt)” across your resume:\n• Open each point with a strong action verb.\n• Put a number on every outcome: %, users, time saved.\n• Keep the projects most relevant to your target role at the top.\n\nSelect the point you want changed and I'll write a version you can apply."
                ))
                self.isGeneratingAI = false
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let promptLower = currentPrompt.lowercased()
            var enhanced = targetSnippet.isEmpty ? "Engineered high-performance systems processing 50+ telemetry streams with 99.9% uptime." : targetSnippet
            var reply = "I tightened the phrasing so the technical impact comes through more clearly."
            
            if promptLower.contains("hash") || promptLower.contains("data structure") || promptLower.contains("dsa") {
                enhanced = "Architected a low-latency telemetry ingestion service for 50+ nodes; leveraged a concurrent Hash Map and worker queue to decrease query response latency by 32%."
                reply = "Done. I worked the Hash Map in as the core data structure and put a number on the latency win."
            } else if promptLower.contains("metric") || promptLower.contains("impact") {
                enhanced = "Spearheaded distributed pipeline overhaul, elevating query processing throughput by 32% across 50+ connected nodes."
                reply = "I added concrete metrics so the impact is measurable at a glance."
            } else if promptLower.contains("concise") {
                enhanced = "Built real-time telemetry service for 50+ IoT nodes, optimizing query latency by 32%."
                reply = "Here's a tighter version that keeps the core achievement."
            } else {
                enhanced = "Engineered real-time telemetry pipelines for 50+ IoT nodes; optimized PostgreSQL queries and indexing to improve dashboard load times by 32%."
                reply = "I led with a stronger action verb and quantified the scale of the system."
            }
            
            let aiMessage = AIChatMessage(
                sender: .ai,
                text: reply,
                targetKey: targetKey,
                originalText: targetSnippet,
                suggestedRewrite: enhanced,
                reason: nil,
                isApplied: false
            )
            self.sessionChatMessages.append(aiMessage)
            self.isGeneratingAI = false
        }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isDownloadingPDF = false
            self.hasDownloadedPDF = true
            // Navigate to download confirmation screen
            self.showDownloadConfirmation = true
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

    public func syncWithProfile(_ profile: UserProfile, achievements: [AchievementItem]? = nil) {
        for i in resumes.indices {
            syncResume(&resumes[i], with: profile, achievements: achievements)
        }
        syncResume(&activeResume, with: profile, achievements: achievements)
    }

    private func syncResume(_ resume: inout ResumeDocument, with profile: UserProfile, achievements: [AchievementItem]?) {
        let safeName = profile.name.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")

        // Dynamic Name Updates
        if !profile.name.isEmpty {
            if resume.id == "res-two-page" || resume.title == "Aarav Sharma" || resume.title == "Aditya Sharma" {
                resume.title = profile.name
                if !safeName.isEmpty {
                    resume.fileName = "\(safeName)_Resume.pdf"
                }
            } else if resume.id == "res-default" {
                if !safeName.isEmpty {
                    resume.fileName = "Master_\(safeName)_Resume.pdf"
                }
            }
        }

        // 1. Summary
        if !profile.bio.isEmpty {
            resume.summary = profile.bio
        }

        // 2. Education
        if !profile.institution.isEmpty || !profile.education.isEmpty {
            let primaryEdu = ResumeEducation(
                id: resume.education.first?.id ?? "edu-primary",
                institution: profile.institution.isEmpty ? (resume.education.first?.institution ?? "SRM Institute of Science and Technology") : profile.institution,
                degree: profile.education.isEmpty ? (resume.education.first?.degree ?? "B.Tech in Computer Science (AI & ML)") : profile.education,
                period: profile.graduationYear.isEmpty ? (resume.education.first?.period ?? "2024 – 2028") : (profile.graduationYear.contains("–") || profile.graduationYear.contains("-") ? profile.graduationYear : "Class of \(profile.graduationYear)"),
                location: profile.location.isEmpty ? (resume.education.first?.location ?? "Chennai, India") : profile.location,
                details: profile.titleOrStage.isEmpty ? (resume.education.first?.details ?? "Coursework: Data Structures, OOP, DBMS, Operating Systems, Machine Learning, Artificial Intelligence · CGPA: 9.77/10") : profile.titleOrStage
            )
            if resume.education.isEmpty {
                resume.education = [primaryEdu]
            } else {
                resume.education[0] = primaryEdu
            }
        }

        // 3. Skills
        if !profile.skills.isEmpty {
            resume.skills = profile.skills
            if resume.skillLines == nil || resume.id != "res-two-page" {
                resume.skillLines = [
                    ResumeSkillLine("Core Skills", profile.skills.joined(separator: ", "))
                ]
            }
        }

        // 4. Experiences (if user has custom profile experiences, and preserve specialized two-page sample)
        if !profile.experiences.isEmpty && resume.id != "res-two-page" {
            resume.experiences = profile.experiences.map { exp in
                ResumeExperience(
                    id: exp.id,
                    company: exp.company,
                    role: exp.title,
                    period: exp.period,
                    location: exp.location,
                    bullets: exp.bullets.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                )
            }
        }

        // 5. Projects (if user has custom profile projects, and preserve specialized two-page sample)
        if !profile.projects.isEmpty && resume.id != "res-two-page" {
            resume.projects = profile.projects.map { proj in
                ResumeProject(
                    id: proj.id,
                    title: proj.title,
                    techStack: proj.techStack,
                    bullets: proj.bullets.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                )
            }
        }

        // 6. Achievements
        if let achItems = achievements, !achItems.isEmpty {
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

    @Published public var posts: [DiscussionPost] = DiscussionPost.samples
    @Published public var companies: [CompanyCommunity] = CompanyCommunity.samples
    @Published public var selectedSubFeed: CommunitySubFeed = .forYou
    @Published public var selectedCategory: DiscussionType? = nil
    @Published public var activeCompanyFilter: String? = nil
    @Published public var showCreatePostSheet: Bool = false
    @Published public var showAllTrendingSheet: Bool = false
    @Published public var showSavedPostsSheet: Bool = false
    @Published public var searchQuery: String = ""

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

    public func toggleFollowCompany(name: String) {
        if let index = companies.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            companies[index].isFollowing.toggle()
        } else {
            let newComp = CompanyCommunity(
                id: "comp-\(name.lowercased())",
                name: name,
                symbol: "building.2.fill",
                memberCount: "10.5K members",
                description: "Discussions, interview advice, and updates for \(name).",
                isFollowing: true
            )
            companies.append(newComp)
        }
    }

    public func isFollowing(companyName: String?) -> Bool {
        guard let name = companyName, !name.isEmpty else { return false }
        return companies.first(where: { $0.name.lowercased() == name.lowercased() })?.isFollowing ?? false
    }

    public func toggleLike(for postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLiked.toggle()
            posts[index].likesCount += posts[index].isLiked ? 1 : -1
        }
    }

    public func toggleSave(for postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isSaved.toggle()
        }
    }

    public func addComment(to postId: String, text: String) {
        guard !text.isEmpty, let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        let newComment = DiscussionComment(
            id: UUID().uuidString,
            authorName: DiscussionPost.currentUserName,
            authorRole: "",
            timeAgo: "Just now",
            text: text,
            likesCount: 0,
            isLiked: false,
            avatarImageName: DiscussionPost.currentUserAvatar
        )
        posts[index].comments.append(newComment)
    }

    public func addReply(to postId: String, commentId: String, text: String) {
        guard !text.isEmpty, let postIndex = posts.firstIndex(where: { $0.id == postId }) else { return }
        if let commentIndex = posts[postIndex].comments.firstIndex(where: { $0.id == commentId }) {
            let newReply = DiscussionComment(
                id: UUID().uuidString,
                authorName: DiscussionPost.currentUserName,
                authorRole: "",
                timeAgo: "Just now",
                text: text,
                likesCount: 0,
                isLiked: false,
                avatarImageName: DiscussionPost.currentUserAvatar
            )
            posts[postIndex].comments[commentIndex].replies.append(newReply)
        }
    }

    public func toggleLikeComment(postId: String, commentId: String) {
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else { return }
        if let commentIndex = posts[postIndex].comments.firstIndex(where: { $0.id == commentId }) {
            posts[postIndex].comments[commentIndex].isLiked.toggle()
            posts[postIndex].comments[commentIndex].likesCount += posts[postIndex].comments[commentIndex].isLiked ? 1 : -1
            return
        }
        for (cIndex, comment) in posts[postIndex].comments.enumerated() {
            if let rIndex = comment.replies.firstIndex(where: { $0.id == commentId }) {
                posts[postIndex].comments[cIndex].replies[rIndex].isLiked.toggle()
                posts[postIndex].comments[cIndex].replies[rIndex].likesCount += posts[postIndex].comments[cIndex].replies[rIndex].isLiked ? 1 : -1
                return
            }
        }
    }

    public func incrementShare(for postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].sharesCount += 1
        }
    }

    public func deleteComment(postId: String, commentId: String) {
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else { return }
        if let commentIndex = posts[postIndex].comments.firstIndex(where: { $0.id == commentId }) {
            posts[postIndex].comments.remove(at: commentIndex)
            return
        }
        for cIndex in 0..<posts[postIndex].comments.count {
            if let rIndex = posts[postIndex].comments[cIndex].replies.firstIndex(where: { $0.id == commentId }) {
                posts[postIndex].comments[cIndex].replies.remove(at: rIndex)
                return
            }
        }
    }

    public init() {}
}

// MARK: - Interview Prep ViewModel
@MainActor
public final class InterviewPrepViewModel: ObservableObject {
    @Published public var questions: [InterviewQuestion] = InterviewQuestion.samples
    
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
        } else if let comp = wizardSelectedCompany {
            // When topic was skipped: make sure all topics for this company are covered!
            let roleToUse = wizardSelectedRole ?? "Software Engineer"
            let topicsCovered = Set(list.map { $0.topic })
            for t in QuestionTopic.allCases {
                if !topicsCovered.contains(t) {
                    list.append(contentsOf: generateMockQuestionsForCombo(company: comp, role: roleToUse, topic: t))
                }
            }
        }
        if !wizardSearchQuery.isEmpty {
            list = list.filter {
                $0.questionText.localizedCaseInsensitiveContains(wizardSearchQuery) ||
                ($0.companyName?.localizedCaseInsensitiveContains(wizardSearchQuery) ?? false) ||
                ($0.role?.localizedCaseInsensitiveContains(wizardSearchQuery) ?? false) ||
                $0.topic.rawValue.localizedCaseInsensitiveContains(wizardSearchQuery)
            }
        }
        // If empty, synthesize realistic practice questions for this combo
        if list.isEmpty {
            let comp = wizardSelectedCompany ?? "Google"
            let role = wizardSelectedRole ?? "Software Engineer"
            let topicsToUse = !wizardSelectedTopics.isEmpty ? Array(wizardSelectedTopics) : (wizardSelectedTopic != nil ? [wizardSelectedTopic!] : QuestionTopic.allCases)
            var synthesized: [InterviewQuestion] = []
            for t in topicsToUse {
                synthesized.append(contentsOf: generateMockQuestionsForCombo(company: comp, role: role, topic: t))
            }
            return synthesized
        }
        return list
    }

    private func generateMockQuestionsForCombo(company: String, role: String, topic: QuestionTopic) -> [InterviewQuestion] {
        let q1Text: String
        let q2Text: String
        let q3Text: String

        switch topic {
        case .dsa:
            q1Text = "Given a stream of real-time events at \(company), design an optimal data structure to return the top K most frequent items in the last 15 minutes."
            q2Text = "Implement an algorithm to detect cyclic dependencies in a large-scale service graph used by \(role) teams at \(company)."
            q3Text = "Find the median of two sorted arrays of server telemetry data with an optimal O(log(min(N, M))) runtime complexity."
        case .systemDesign:
            q1Text = "Design a low-latency, globally distributed notification and messaging system for \(company)'s \(role) infrastructure."
            q2Text = "Architect a scalable rate limiter that can handle 10 million RPS with sub-millisecond response times across multiple geographic regions."
            q3Text = "Design a distributed key-value store with configurable consistency levels (tunable CAP theorem) tailored for \(company)."
        case .coreCS:
            q1Text = "Explain how the operating system handles virtual memory page faults and translation lookaside buffers (TLB) during heavy concurrent execution."
            q2Text = "How do mutexes, semaphores, and reader-writer locks differ in low-level thread synchronization for \(role) roles?"
            q3Text = "Walk through the TCP 3-way handshake and describe how TCP congestion control algorithms (like BBR or Cubic) function at \(company)."
        case .dbms:
            q1Text = "Compare B+ Trees and LSM Trees for write-heavy storage workloads at \(company), explaining trade-offs in compaction and read amplification."
            q2Text = "How do distributed databases achieve ACID transactions across shards using Two-Phase Commit (2PC) and Paxos/Raft consensus?"
            q3Text = "Explain database indexing strategies, cover indexes, and query execution plan optimization for high-throughput relational databases."
        case .networking:
            q1Text = "What happens from a networking perspective when a client sends a secure HTTPS request to \(company)'s API gateway?"
            q2Text = "Explain the differences between HTTP/2 multiplexing, HTTP/3 QUIC over UDP, and head-of-line blocking."
            q3Text = "How does BGP anycast routing direct global user traffic to the closest \(company) edge points of presence?"
        case .behavioral:
            q1Text = "Tell me about a time you had a strong technical disagreement with a senior engineer or product manager at work. How did you resolve it?"
            q2Text = "Describe a situation where a production service you built failed unexpectedly. How did you diagnose, mitigate, and conduct the post-mortem?"
            q3Text = "Why do you want to join \(company) as a \(role), and how does your past experience align with our engineering culture?"
        case .os:
            q1Text = "Explain context switching overhead and how CFS (Completely Fair Scheduler) prioritizes tasks under high CPU load at \(company)."
            q2Text = "How do Linux namespaces and cgroups form the foundation of container isolation in modern \(role) workflows?"
            q3Text = "Detail memory management differences between stack and heap allocation, and how memory leaks are profiled in production."
        case .aiMl:
            q1Text = "How would you design a low-latency recommendation engine pipeline serving personalized feeds for \(company) users?"
            q2Text = "Explain techniques to mitigate hallucinations and evaluate factual accuracy in production LLM inference pipelines."
            q3Text = "Discuss trade-offs between dense retrieval (vector embeddings) and sparse retrieval (BM25) for high-recall search systems."
        @unknown default:
            q1Text = "Explain your core engineering philosophy and technical approach for high-impact problems at \(company)."
            q2Text = "Walk through an architecture you designed as a \(role) that scaled successfully under high traffic."
            q3Text = "How do you evaluate system trade-offs between latency, throughput, and operational complexity?"
        }

        return [
            InterviewQuestion(
                id: "\(company)-\(role)-\(topic.rawValue)-q1",
                questionText: q1Text,
                topic: topic,
                companyName: company,
                role: role,
                difficulty: "General",
                upvotesCount: 38,
                isUpvoted: false,
                isSaved: false,
                hint: "Think about edge conditions, time-versus-space trade-offs, and breakdown into modular constraints.",
                approach: "Clarify inputs/outputs first, outline a brute-force approach, then optimize bottleneck operations using appropriate data structures.",
                answer: "// Production-ready approach for \(company) \(role):\n1. Define input invariants\n2. Maintain a min-heap or sliding hash map\n3. Evict stale elements incrementally\n4. Return the consolidated result in optimal linearithmic time.",
                aiGeneratedAnswer: nil,
                hasAIGeneratedSolution: true,
                timeComplexity: "O(N log K)",
                spaceComplexity: "O(K)",
                isCommunityReported: true
            ),
            InterviewQuestion(
                id: "\(company)-\(role)-\(topic.rawValue)-q2",
                questionText: q2Text,
                topic: topic,
                companyName: company,
                role: role,
                difficulty: "General",
                upvotesCount: 29,
                isUpvoted: false,
                isSaved: false,
                hint: "Consider how concurrency and state distribution affect the scalability of your approach.",
                approach: "Formulate the solution using state machines or topological traversal, noting how failure domains are isolated.",
                answer: "// Algorithmic Blueprint:\n- Represent states as directed nodes\n- Use DFS with 3-color cycle detection (White, Gray, Black)\n- Return cycle trace if back-edge is encountered.",
                aiGeneratedAnswer: nil,
                hasAIGeneratedSolution: true,
                timeComplexity: "O(V + E)",
                spaceComplexity: "O(V)",
                isCommunityReported: true
            ),
            InterviewQuestion(
                id: "\(company)-\(role)-\(topic.rawValue)-q3",
                questionText: q3Text,
                topic: topic,
                companyName: company,
                role: role,
                difficulty: "General",
                upvotesCount: 45,
                isUpvoted: false,
                isSaved: false,
                hint: "Focus on communication protocols, fault tolerance, and clear ownership boundaries.",
                approach: "Structure your response with clear trade-offs, mentioning monitoring, metrics, and automated rollback strategies.",
                answer: "// Architectural Summary:\n- End-to-end telemetry monitoring\n- Circuit breaker pattern to prevent cascading failures\n- Graceful degradation under spike load.",
                aiGeneratedAnswer: nil,
                hasAIGeneratedSolution: true,
                timeComplexity: "O(1) amortized",
                spaceComplexity: "O(1)",
                isCommunityReported: true
            )
        ]
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
        if let index = questions.firstIndex(where: { $0.id == questionId }) {
            questions[index].isUpvoted.toggle()
            questions[index].upvotesCount += questions[index].isUpvoted ? 1 : -1
        }
    }

    public func toggleUpvote(for question: InterviewQuestion) {
        if let index = questions.firstIndex(where: { $0.id == question.id }) {
            questions[index].isUpvoted.toggle()
            questions[index].upvotesCount += questions[index].isUpvoted ? 1 : -1
        } else {
            var updated = question
            updated.isUpvoted.toggle()
            updated.upvotesCount += updated.isUpvoted ? 1 : -1
            questions.insert(updated, at: 0)
        }
    }

    public func toggleSave(for questionId: String) {
        if let index = questions.firstIndex(where: { $0.id == questionId }) {
            questions[index].isSaved.toggle()
        }
    }

    public func toggleSave(for question: InterviewQuestion) {
        if let index = questions.firstIndex(where: { $0.id == question.id }) {
            questions[index].isSaved.toggle()
        } else {
            var updated = question
            updated.isSaved.toggle()
            questions.insert(updated, at: 0)
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

    public func generateAISolution(for id: String) {
        isGeneratingAISolution[id] = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
            guard let self = self else { return }
            self.isGeneratingAISolution[id] = false
            self.revealedSolutions.insert(id)
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
        let hasProvidedAnswer = !(answer?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        
        let aiAnswer: String? = hasProvidedAnswer ? nil : """
        Aline AI Optimal Solution & Walkthrough:
        
        1. Core Intuition:
        Identify the optimal time and space trade-off for \(topic.rawValue) problems asked at \(company).
        
        2. Framework:
        • Initialize state tracking (e.g. hash map / dynamic programming table).
        • Handle boundary edge cases (null inputs, single elements, negative values).
        • Apply two-pointer or sliding window traversal to achieve optimal complexity.
        
        3. Implementation Verification:
        All test suites passed with 100% test coverage against standard competitive edge cases.
        """

        let newQuestion = InterviewQuestion(
            id: UUID().uuidString,
            questionText: questionText,
            topic: topic,
            companyName: company.isEmpty ? "General" : company,
            role: role.isEmpty ? "Software Engineer" : role,
            difficulty: difficulty,
            upvotesCount: 1,
            isUpvoted: true,
            isSaved: false,
            hint: (hint?.isEmpty ?? true) ? "Break the problem down into smaller subproblems. Consider what data structure provides O(1) lookups." : hint,
            approach: (approach?.isEmpty ?? true) ? "Recommended Framework: Use greedy iteration with early exit termination when the target condition is satisfied." : approach,
            answer: hasProvidedAnswer ? answer : nil,
            aiGeneratedAnswer: aiAnswer,
            hasAIGeneratedSolution: !hasProvidedAnswer,
            timeComplexity: "O(N) Time",
            spaceComplexity: "O(1) Auxiliary Space",
            isCommunityReported: true
        )
        
        questions.insert(newQuestion, at: 0)
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
}

// MARK: - Profile & Preferences ViewModel
@MainActor
public final class ProfileViewModel: ObservableObject {
    @Published public var profile: UserProfile = UserProfile.sample
    @Published public var preferences: CareerPreferences = CareerPreferences.sample
    @Published public var achievements: [AchievementItem] = AchievementItem.samples
    @Published public var showEditProfileSheet: Bool = false
    @Published public var showPreferencesSheet: Bool = false
    @Published public var showAddAchievementSheet: Bool = false
    @Published public var selectedAchievement: AchievementItem? = nil

    public var onProfileUpdated: ((UserProfile) -> Void)? = nil

    public init() {
        if let data = UserDefaults.standard.data(forKey: "savedUserProfile"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data),
           decoded.experiences.count >= 3 {
            self.profile = decoded
        } else {
            let name = UserDefaults.standard.string(forKey: "userFullName") ?? "Aarav Sharma"
            var sample = UserProfile.sample
            sample.name = name
            self.profile = sample
            if let encoded = try? JSONEncoder().encode(sample) {
                UserDefaults.standard.set(encoded, forKey: "savedUserProfile")
            }
        }

        if let achData = UserDefaults.standard.data(forKey: "savedUserAchievements"),
           let decodedAch = try? JSONDecoder().decode([AchievementItem].self, from: achData),
           decodedAch.count >= 3 {
            self.achievements = decodedAch
        } else {
            self.achievements = AchievementItem.samples
            if let encoded = try? JSONEncoder().encode(AchievementItem.samples) {
                UserDefaults.standard.set(encoded, forKey: "savedUserAchievements")
            }
        }
    }

    public func syncWithStoredUser() {
        if let name = UserDefaults.standard.string(forKey: "userFullName"), !name.isEmpty {
            self.profile.name = name
        }
        if let loc = UserDefaults.standard.string(forKey: "userLocation"), !loc.isEmpty {
            self.profile.location = loc
        }
        if let bio = UserDefaults.standard.string(forKey: "userBio"), !bio.isEmpty {
            self.profile.bio = bio
        }
    }

    public func deleteAchievement(id: String) {
        achievements.removeAll { $0.id == id }
        saveAchievements()
        NotificationCenter.default.post(name: .userProfileDidUpdate, object: profile)
    }

    public func achievements(in category: AchievementCategory) -> [AchievementItem] {
        achievements.filter { $0.category == category }
    }

    public func upsertAchievement(_ item: AchievementItem) {
        if let index = achievements.firstIndex(where: { $0.id == item.id }) {
            achievements[index] = item
        } else {
            achievements.insert(item, at: 0)
        }
        saveAchievements()
        NotificationCenter.default.post(name: .userProfileDidUpdate, object: profile)
    }

    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "savedUserAchievements")
        }
    }

    public func updateProfile(_ updated: UserProfile) {
        profile = updated
        // Persist key fields to UserDefaults for @AppStorage bindings
        UserDefaults.standard.set(updated.name, forKey: "userFullName")
        UserDefaults.standard.set(updated.location, forKey: "userLocation")
        UserDefaults.standard.set(updated.bio, forKey: "userBio")
        UserDefaults.standard.set(updated.education, forKey: "userEducation")
        UserDefaults.standard.set(updated.institution, forKey: "userInstitution")
        UserDefaults.standard.set(updated.graduationYear, forKey: "userGraduationYear")
        UserDefaults.standard.set(updated.linkedInURL, forKey: "userLinkedIn")
        UserDefaults.standard.set(updated.githubURL, forKey: "userGitHub")
        UserDefaults.standard.set(updated.portfolioURL, forKey: "userPortfolio")

        if let encoded = try? JSONEncoder().encode(updated) {
            UserDefaults.standard.set(encoded, forKey: "savedUserProfile")
        }

        onProfileUpdated?(updated)
        NotificationCenter.default.post(name: .userProfileDidUpdate, object: updated)
    }

    public func updatePreferences(_ updated: CareerPreferences) {
        preferences = updated
    }
}
