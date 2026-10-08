import SwiftUI
import SwiftData

/// View/Edit Resume, matching the product direction: tap a line in View Resume to select it
/// for "Edit with AI" (line-granularity, not freeform character-range selection — see
/// ResumeBullet's doc comment for why), zoom +/- that scales content density (not just a
/// viewer convenience — it's the mechanism that keeps the resume on one page), Save, and
/// Download PDF. `targetJob`, when set (arrived here from a job's "Tailor for this job"
/// entry point), adds the missing-keyword-gap section.
struct ResumeDetailView: View {
    @Bindable var document: ResumeDocument
    var targetJob: Job? = nil

    @Environment(\.modelContext) private var modelContext

    private enum Mode { case view, edit }
    @State private var mode: Mode = .view

    @State private var baselineScale: CGFloat = 1.0
    @State private var hasComputedBaseline = false
    @State private var zoomStep: Int = 0
    @State private var measuredHeight: CGFloat = ResumePage.contentHeight

    @State private var selectedText: String?
    @State private var promptText = ""
    @State private var aiSuggestion: String?
    @State private var isGenerating = false

    @State private var missingKeywordSuggestions: [KeywordSuggestion] = []
    @State private var isLoadingKeywordSuggestions = false

    @State private var pdfData: Data?
    @State private var isShowingShareSheet = false
    @State private var isExporting = false

    private var templateID: ResumeTemplateID { ResumeTemplateID(rawValue: document.templateID) ?? .standard }

    private var effectiveScale: CGFloat {
        max(0.5, min(1.3, baselineScale + CGFloat(zoomStep) * 0.1))
    }

    var body: some View {
        VStack(spacing: 0) {
            modePicker
            switch mode {
            case .view: viewResume
            case .edit: editResume
            }
        }
        .background(AlineColor.warmCanvas)
        .navigationTitle(document.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: save).font(AlineFont.body(14, weight: .medium))
            }
        }
        .task {
            guard !hasComputedBaseline else { return }
            baselineScale = ResumeRenderer.autoFitScale(templateID: templateID, profile: document.profile)
            hasComputedBaseline = true
        }
        .task(id: effectiveScale) {
            measuredHeight = ResumeRenderer.measuredHeight(templateID: templateID, profile: document.profile, scale: effectiveScale)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let pdfData { ShareSheet(items: [pdfData]) }
        }
    }

    // MARK: - Mode picker

    private var modePicker: some View {
        HStack(spacing: 8) {
            modeButton("View Resume", systemImage: "doc.text", isOn: mode == .view) { mode = .view }
            modeButton("Edit Resume", systemImage: "pencil", isOn: mode == .edit) { mode = .edit }
        }
        .padding(12)
    }

    private func modeButton(_ title: String, systemImage: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AlineFont.body(14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isOn ? AlineColor.inkNavy : AlineColor.paperWhite)
                .foregroundStyle(isOn ? .white : AlineColor.inkNavy)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AlineColor.creamBorder, lineWidth: isOn ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - View Resume

    private var viewResume: some View {
        VStack(spacing: 0) {
            ScrollView {
                pageSurface
                    .scaleEffect(displayFitScale, anchor: .top)
                    .frame(
                        width: ResumePage.width * displayFitScale,
                        height: (measuredHeight + ResumePage.margin * 2) * displayFitScale
                    )
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            }
            zoomControls
            exportButton
        }
    }

    private var pageSurface: some View {
        templateID.view(profile: document.profile, scale: effectiveScale) { text in
            selectedText = text
            promptText = ""
            aiSuggestion = nil
            mode = .edit
        }
        .padding(ResumePage.margin)
        .frame(width: ResumePage.width, alignment: .top)
        .background(Color.white)
    }

    private var displayFitScale: CGFloat {
        let targetWidth = UIScreen.main.bounds.width - 32
        return min(1, targetWidth / ResumePage.width)
    }

    private var zoomControls: some View {
        HStack(spacing: 20) {
            Button { zoomStep = max(zoomStep - 1, -3) } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            Text("\(Int(effectiveScale * 100))%").font(AlineFont.body(13)).foregroundStyle(AlineColor.stone)
            Button { zoomStep = min(zoomStep + 1, 3) } label: {
                Image(systemName: "plus.magnifyingglass")
            }
        }
        .font(.system(size: 18))
        .foregroundStyle(AlineColor.inkNavy)
        .padding(.vertical, 8)
    }

    private var exportButton: some View {
        Button(action: exportPDF) {
            if isExporting {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                Label("Download PDF", systemImage: "arrow.down.doc").frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(AlinePrimaryButtonStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .disabled(isExporting)
    }

    private func exportPDF() {
        isExporting = true
        Task {
            let data = ResumeRenderer.exportPDF(templateID: templateID, profile: document.profile, scale: effectiveScale)
            await MainActor.run {
                isExporting = false
                guard let data else { return }
                pdfData = data
                isShowingShareSheet = true
            }
        }
    }

    // MARK: - Edit Resume

    private var editResume: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ask AI for a specific improvement.")
                    .font(AlineFont.body(13)).foregroundStyle(AlineColor.stone)

                if let selectedText {
                    selectedTextCard(selectedText)
                    promptBox
                } else {
                    noSelectionCard
                }

                if let aiSuggestion {
                    suggestionCard(aiSuggestion)
                }

                if let targetJob {
                    Divider()
                    keywordGapSection(targetJob)
                }
            }
            .padding(16)
        }
    }

    private func selectedTextCard(_ text: String) -> some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundStyle(AlineColor.electricCobalt)
                    Text("AI Assistant").font(AlineFont.body(14, weight: .medium)).foregroundStyle(AlineColor.inkNavy)
                }
                Divider()
                Text("SELECTED TEXT").font(AlineFont.body(11, weight: .medium)).foregroundStyle(AlineColor.stone)
                Text("\u{201C}\(text)\u{201D}")
                    .font(AlineFont.body(13)).italic().foregroundStyle(AlineColor.charcoal)
            }
        }
    }

    private var promptBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR PROMPT").font(AlineFont.body(11, weight: .medium)).foregroundStyle(AlineColor.stone)
            TextEditor(text: $promptText)
                .frame(height: 80)
                .padding(8)
                .background(AlineColor.paperWhite)
                .clipShape(RoundedRectangle(cornerRadius: AlineRadius.card))
                .overlay(RoundedRectangle(cornerRadius: AlineRadius.card).stroke(AlineColor.creamBorder))

            Button(action: submitPrompt) {
                if isGenerating {
                    ProgressView().tint(.white).frame(maxWidth: .infinity)
                } else {
                    Label("Submit Prompt", systemImage: "arrow.up.circle.fill").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(AlinePrimaryButtonStyle())
            .disabled(promptText.trimmingCharacters(in: .whitespaces).isEmpty || isGenerating)

            VStack(alignment: .leading, spacing: 6) {
                Text("TRY ASKING").font(AlineFont.body(11, weight: .medium)).foregroundStyle(AlineColor.stone)
                quickPrompt("Make it more concise")
                quickPrompt("Add measurable impact")
            }
        }
    }

    private func quickPrompt(_ text: String) -> some View {
        Button {
            promptText = text
            submitPrompt()
        } label: {
            HStack {
                Text("\u{201C}\(text)\u{201D}").font(AlineFont.body(13)).foregroundStyle(AlineColor.inkNavy)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(AlineColor.stone)
            }
            .padding(10)
            .background(AlineColor.lavenderMist.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func submitPrompt() {
        guard let selectedText, !promptText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isGenerating = true
        aiSuggestion = nil
        Task {
            let result = await ResumeAIEditor.rewrite(selectedText: selectedText, instruction: promptText)
            await MainActor.run {
                isGenerating = false
                aiSuggestion = result
            }
        }
    }

    private func suggestionCard(_ suggestion: String) -> some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundStyle(AlineColor.electricCobalt)
                    Text("AI Suggestion").font(AlineFont.body(14, weight: .medium)).foregroundStyle(AlineColor.inkNavy)
                }
                Text(suggestion).font(AlineFont.body(14)).foregroundStyle(AlineColor.charcoal)
                HStack(spacing: 10) {
                    Button {
                        UIPasteboard.general.string = suggestion
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc").frame(maxWidth: .infinity)
                    }
                    .font(AlineFont.body(14, weight: .medium))
                    .foregroundStyle(AlineColor.inkNavy)
                    .padding(.vertical, 10)
                    .overlay(RoundedRectangle(cornerRadius: AlineRadius.card).stroke(AlineColor.creamBorder))

                    Button {
                        applySuggestion(suggestion)
                    } label: {
                        Label("Apply to Resume", systemImage: "checkmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AlinePrimaryButtonStyle())
                }
            }
        }
    }

    private func applySuggestion(_ suggestion: String) {
        guard let selectedText else { return }
        var profile = document.profile
        var replaced = false

        if profile.summary == selectedText {
            profile.summary = suggestion
            replaced = true
        }
        if !replaced {
            outer: for i in profile.experience.indices {
                if let bi = profile.experience[i].bullets.firstIndex(of: selectedText) {
                    profile.experience[i].bullets[bi] = suggestion
                    replaced = true
                    break outer
                }
            }
        }
        if !replaced {
            outer: for i in profile.projects.indices {
                if let bi = profile.projects[i].bullets.firstIndex(of: selectedText) {
                    profile.projects[i].bullets[bi] = suggestion
                    replaced = true
                    break outer
                }
            }
        }

        guard replaced else { return }
        document.profile = profile
        document.updatedAt = Date()
        self.selectedText = suggestion
        self.aiSuggestion = nil
        self.promptText = ""
    }

    private var noSelectionCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundStyle(AlineColor.electricCobalt)
                    Text("AI Assistant").font(AlineFont.body(14, weight: .medium)).foregroundStyle(AlineColor.inkNavy)
                }
                Text("Ready to help you improve your resume.").font(AlineFont.body(13)).foregroundStyle(AlineColor.stone)
                Text("Tap any bullet in View Resume to select it, or pick one below.")
                    .font(AlineFont.body(12)).foregroundStyle(AlineColor.stone)

                ForEach(editableTargets, id: \.self) { target in
                    Button {
                        selectedText = target
                        promptText = ""
                        aiSuggestion = nil
                    } label: {
                        Text(target).font(AlineFont.body(13)).foregroundStyle(AlineColor.inkNavy)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(AlineColor.lavenderMist.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var editableTargets: [String] {
        var items: [String] = []
        if !document.profile.summary.isEmpty { items.append(document.profile.summary) }
        for exp in document.profile.experience { items.append(contentsOf: exp.bullets) }
        for proj in document.profile.projects { items.append(contentsOf: proj.bullets) }
        return items
    }

    // MARK: - JD keyword gap (arrived here via a job's "Tailor for this job")

    private func keywordGapSection(_ job: Job) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tailor for: \(job.title) at \(job.company)")
                .font(AlineFont.body(14, weight: .medium)).foregroundStyle(AlineColor.inkNavy)

            let missing = missingSkills(for: job)
            if missing.isEmpty {
                Text("Your resume already covers every skill this listing mentions.")
                    .font(AlineFont.body(13)).foregroundStyle(AlineColor.stone)
            } else if isLoadingKeywordSuggestions {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Finding ways to work these in…").font(AlineFont.body(13)).foregroundStyle(AlineColor.stone)
                }
            } else if missingKeywordSuggestions.isEmpty {
                Button {
                    loadKeywordSuggestions(job: job, missing: missing)
                } label: {
                    Label("Suggest keyword improvements", systemImage: "sparkles").frame(maxWidth: .infinity)
                }
                .buttonStyle(AlinePrimaryButtonStyle())
            } else {
                PaperCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Missing resume keywords · \(missingKeywordSuggestions.count) suggestions to review")
                            .font(AlineFont.body(12, weight: .medium)).foregroundStyle(AlineColor.stone)
                        ForEach(missingKeywordSuggestions) { suggestion in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.keyword).font(AlineFont.body(13, weight: .semibold)).foregroundStyle(AlineColor.inkNavy)
                                Text(suggestion.targetSectionHint).font(AlineFont.body(11)).foregroundStyle(AlineColor.stone)
                                Text(suggestion.suggestedBulletText).font(AlineFont.body(13)).foregroundStyle(AlineColor.charcoal)
                                Button("Apply to Resume") { applyKeywordSuggestion(suggestion) }
                                    .font(AlineFont.body(12, weight: .medium))
                                    .foregroundStyle(AlineColor.electricCobalt)
                            }
                            Divider()
                        }
                        Text("Only add skills and experience that are accurate. Confirm any highlighted details before applying.")
                            .font(AlineFont.body(11)).italic().foregroundStyle(AlineColor.stone)
                    }
                }
            }
        }
    }

    private func missingSkills(for job: Job) -> [String] {
        let resumeSkills = Set(document.profile.skillCategories.flatMap(\.items).map { $0.lowercased() })
        return job.extractedSkills.filter { !resumeSkills.contains($0.lowercased()) }
    }

    private func loadKeywordSuggestions(job: Job, missing: [String]) {
        isLoadingKeywordSuggestions = true
        Task {
            let result = await ResumeAIEditor.suggestMissingKeywords(profile: document.profile, missingSkills: missing, jobTitle: job.title)
            await MainActor.run {
                isLoadingKeywordSuggestions = false
                missingKeywordSuggestions = result
            }
        }
    }

    private func applyKeywordSuggestion(_ suggestion: KeywordSuggestion) {
        var profile = document.profile
        if let idx = profile.experience.firstIndex(where: {
            suggestion.targetSectionHint.localizedCaseInsensitiveContains($0.organization)
                || suggestion.targetSectionHint.localizedCaseInsensitiveContains($0.title)
        }) {
            profile.experience[idx].bullets.append(suggestion.suggestedBulletText)
        } else if let idx = profile.projects.firstIndex(where: {
            suggestion.targetSectionHint.localizedCaseInsensitiveContains($0.name)
        }) {
            profile.projects[idx].bullets.append(suggestion.suggestedBulletText)
        } else if !profile.experience.isEmpty {
            profile.experience[0].bullets.append(suggestion.suggestedBulletText)
        }
        document.profile = profile
        document.updatedAt = Date()
        missingKeywordSuggestions.removeAll { $0.id == suggestion.id }
    }

    // MARK: - Save

    private func save() {
        document.updatedAt = Date()
        try? modelContext.save()
    }
}
