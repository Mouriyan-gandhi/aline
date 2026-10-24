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

@MainActor
public final class AppNavigationViewModel: ObservableObject {
    @Published public var currentTab: AppTab = .discover
    @Published public var hasCompletedOnboarding: Bool = true
    @Published public var showNotificationsSheet: Bool = false
    @Published public var unreadNotificationsCount: Int = 2

    public init() {}
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
}

// MARK: - Resume & AI Tailoring ViewModel
@MainActor
public final class ResumeViewModel: ObservableObject {
    @Published public var resumes: [ResumeDocument] = ResumeDocument.samples
    @Published public var activeResume: ResumeDocument = ResumeDocument.samples[0]
    @Published public var selectedFilterTab: ResumeFilterTab = .all
    @Published public var searchQuery: String = ""
    @Published public var activeTargetOpportunity: Opportunity? = Opportunity.samples[0]
    
    @Published public var showUploadSheet: Bool = false
    
    // Step 2 & 3: Template Sheet & Full Screen Navigation
    @Published public var showTemplatePickerSheet: Bool = false
    @Published public var pendingSelectedResume: ResumeDocument? = nil
    @Published public var selectedTemplateChoice: ResumeDocument.ResumeTemplate = .standard
    @Published public var shouldNavigateToEditor: Bool = false
    
    // Step 4 & 5: In-Editor Text Selection & AI Session Chat History
    @Published public var selectedSnippetTargetKey: String? = nil // e.g. "proj-0-bullet-0"
    @Published public var selectedSnippetText: String = ""
    @Published public var showAIPanel: Bool = false
    @Published public var userAIInstruction: String = ""
    @Published public var isGeneratingAI: Bool = false
    @Published public var sessionChatMessages: [AIChatMessage] = []
    @Published public var showSavedBanner: Bool = false
    
    // Step 6: Save & Preview & PDF Download
    @Published public var shouldNavigateToPrintPreview: Bool = false
    @Published public var isDownloadingPDF: Bool = false
    @Published public var hasDownloadedPDF: Bool = false

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

        isGeneratingAI = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let promptLower = currentPrompt.lowercased()
            var enhanced = targetSnippet.isEmpty ? "Engineered high-performance systems processing 50+ telemetry streams with 99.9% uptime." : targetSnippet
            var reason = "Refined phrasing for maximum technical impact and clarity."
            
            if promptLower.contains("hash") || promptLower.contains("data structure") || promptLower.contains("dsa") {
                enhanced = "Architected a low-latency telemetry ingestion service for 50+ nodes; leveraged a concurrent Hash Map and worker queue to decrease query response latency by 32%."
                reason = "Explicitly integrated Hash Map data structure and quantified latency reduction."
            } else if promptLower.contains("metric") || promptLower.contains("impact") {
                enhanced = "Spearheaded distributed pipeline overhaul, elevating query processing throughput by 32% across 50+ connected nodes."
                reason = "Added quantified business and performance impact metrics."
            } else if promptLower.contains("concise") {
                enhanced = "Built real-time telemetry service for 50+ IoT nodes, optimizing query latency by 32%."
                reason = "Streamlined phrasing while preserving core achievements."
            } else {
                enhanced = "Engineered real-time telemetry pipelines for 50+ IoT nodes; optimized PostgreSQL queries and indexing to improve dashboard load times by 32%."
                reason = "Strengthened technical action verbs and quantified system scale."
            }
            
            let aiMessage = AIChatMessage(
                sender: .ai,
                text: "Here is a tailored revision for your resume:",
                targetKey: targetKey,
                originalText: targetSnippet,
                suggestedRewrite: enhanced,
                reason: reason,
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

        // Mark this message as applied
        sessionChatMessages[index].isApplied = true

        // Append system notification to chat
        let confirmMsg = AIChatMessage(
            sender: .system,
            text: "Change applied to resume document ✓"
        )
        sessionChatMessages.append(confirmMsg)

        if selectedSnippetTargetKey == key {
            self.selectedSnippetText = rewrite
        }
    }

    // Step 7: Save document changes -> commit to resumes and CLEAR THE CHAT
    public func saveDocumentChanges() {
        if let idx = resumes.firstIndex(where: { $0.id == activeResume.id }) {
            resumes[idx] = activeResume
            resumes[idx].lastModifiedDate = "Just now"
        }
        // Once saved, the session chat is gone as requested
        self.sessionChatMessages.removeAll()
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.hasDownloadedPDF = false
            }
        }
    }
}

// MARK: - Community ViewModel
@MainActor
public final class CommunityViewModel: ObservableObject {
    @Published public var posts: [DiscussionPost] = DiscussionPost.samples
    @Published public var companies: [CompanyCommunity] = CompanyCommunity.samples
    @Published public var selectedCategory: DiscussionType? = nil
    @Published public var activeCompanyFilter: String? = nil
    @Published public var showCreatePostSheet: Bool = false
    @Published public var searchQuery: String = ""

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
                $0.topics.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }
        return list
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
            authorName: "You",
            authorRole: "3rd Year CS Student",
            timeAgo: "Just now",
            text: text,
            likesCount: 0,
            isLiked: false
        )
        posts[index].comments.append(newComment)
    }
}

// MARK: - Interview Prep ViewModel
@MainActor
public final class InterviewPrepViewModel: ObservableObject {
    @Published public var questions: [InterviewQuestion] = InterviewQuestion.samples
    @Published public var selectedTopic: QuestionTopic? = nil
    @Published public var selectedCompany: String? = nil
    @Published public var searchQuery: String = ""
    @Published public var revealedHints: Set<String> = []
    @Published public var revealedApproaches: Set<String> = []
    @Published public var showContributeSheet: Bool = false

    public var filteredQuestions: [InterviewQuestion] {
        var list = questions
        if let topic = selectedTopic {
            list = list.filter { $0.topic == topic }
        }
        if let company = selectedCompany {
            list = list.filter { $0.companyName == company }
        }
        if !searchQuery.isEmpty {
            list = list.filter {
                $0.questionText.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return list
    }

    public func toggleUpvote(for questionId: String) {
        if let index = questions.firstIndex(where: { $0.id == questionId }) {
            questions[index].isUpvoted.toggle()
            questions[index].upvotesCount += questions[index].isUpvoted ? 1 : -1
        }
    }

    public func toggleSave(for questionId: String) {
        if let index = questions.firstIndex(where: { $0.id == questionId }) {
            questions[index].isSaved.toggle()
        }
    }

    public func revealHint(for id: String) {
        revealedHints.insert(id)
    }

    public func revealApproach(for id: String) {
        revealedApproaches.insert(id)
    }
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

    public func deleteAchievement(id: String) {
        achievements.removeAll { $0.id == id }
    }
}
