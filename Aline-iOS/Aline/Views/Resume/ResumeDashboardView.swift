import SwiftUI

// MARK: - Resume Main Screen (Clean Document Grid Tiles & Full Interactive AI Workflow)
public struct ResumeDashboardView: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @State private var showingUploadModal: Bool = false
    @State private var showingAddOptions: Bool = false

    // 2-column grid for document tiles
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    // Master resume is always shown first
    private var orderedResumes: [ResumeDocument] {
        var list = viewModel.filteredResumes
        list.sort { r1, r2 in
            if r1.isDefault && !r2.isDefault { return true }
            if !r1.isDefault && r2.isDefault { return false }
            return false
        }
        return list
    }

    private func setMasterResume(_ resume: ResumeDocument) {
        withAnimation(AlineTheme.fastSpring) {
            viewModel.setMaster(resume)
        }
    }

    private func deleteResume(_ resume: ResumeDocument) {
        guard !resume.isDefault else { return } // master resume cannot be deleted
        withAnimation(AlineTheme.fastSpring) {
            viewModel.deleteResume(resume)
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                DiscoverBackgroundArtwork()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AlineSpacing.section) {
                        // Top Header: Title and Add Resume Button
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("RESUMES")
                                    .font(.system(size: 32, weight: .black, design: .default))
                                    .lineSpacing(2)
                                    .foregroundColor(AlineTheme.inkPrimary)
                                Text("Select a document to edit or preview")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.inkSecondary)
                            }

                            Spacer()

                            // Add Resume Icon Button on Top
                            Button {
                                showingAddOptions = true
                            } label: {
                                ZStack {
                                    Color.clear.frame(width: 40, height: 40).alineGlassCircle(selected: false)
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Add new resume")
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        // Came here from "Tailor Resume with AI": ask which resume to tailor for that job
                        if let job = viewModel.tailoringJob {
                            HStack(alignment: .center, spacing: 12) {
                                CompanyLogoBadge(companyName: job.companyName, size: 40, isSquircle: true)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Select the resume you want to tailor")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                    Text("for \(job.roleTitle) at \(job.companyName)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 0)

                                Button {
                                    withAnimation(AlineTheme.fastSpring) {
                                        viewModel.cancelTailoring()
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                        .frame(width: 30, height: 30)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .alineGlassCircleButton()
                                .accessibilityLabel("Cancel tailoring")
                            }
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AlineTheme.borderSubtle, lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 1. Search Bar (Exact shape and style as Discover page, 20pt spacing matching Discover)
                        AlineSearchField("Search resumes", text: $viewModel.searchQuery)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                        // 2. Document Tiles Grid (Master is always shown first; exact screenshot format)
                        if orderedResumes.isEmpty && viewModel.searchQuery.isEmpty && (viewModel.isLoadingResumes || viewModel.isImportingResume) {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .controlSize(.large)
                                    .tint(AlineTheme.inkMuted)
                                Text(viewModel.isImportingResume ? "Reading your resume…" : "Loading your resumes…")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AlineTheme.inkSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        } else if orderedResumes.isEmpty {
                            if !viewModel.searchQuery.isEmpty {
                                // Search Empty State
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 36))
                                        .foregroundColor(AlineTheme.inkSecondary.opacity(0.5))
                                    Text("No resumes found")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                    Text("No resumes match \"\(viewModel.searchQuery)\". Try searching by another keyword or role.")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)

                                    Button {
                                        viewModel.searchQuery = ""
                                    } label: {
                                        Text("Clear Search")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(AlineTheme.inkPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .alineGlassCapsule(selected: false)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 4)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                // 0 Resumes Empty State
                                VStack(spacing: 16) {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 44))
                                        .foregroundColor(AlineTheme.inkSecondary.opacity(0.7))
                                    Text("You don't have any resumes yet")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                    Text("Upload an existing PDF or DOCX document to get started.")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)

                                    Button {
                                        showingUploadModal = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "plus")
                                            Text("Upload Resume")
                                        }
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .alineGlassCapsule(selected: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        } else {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(orderedResumes) { resume in
                                    ResumeDocumentTile(
                                        resume: resume,
                                        onTap: {
                                            viewModel.selectResumeForEditing(resume)
                                        },
                                        onSetMaster: {
                                            setMasterResume(resume)
                                        },
                                        onDelete: {
                                            deleteResume(resume)
                                        },
                                        onPreview: {
                                            viewModel.previewResume(resume)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                        }

                        Spacer(minLength: 120) // Room for floating tab bar
                    }
                }
.scrollDismissesKeyboard(.interactively)
            }
            // Add Resume Options Sheet (Pops up when tapping + button)
            .sheet(isPresented: $showingAddOptions) {
                AddResumeOptionsSheet(
                    onAddResume: {
                        showingAddOptions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showingUploadModal = true
                        }
                    },
                    onBuildFromProfile: {
                        showingAddOptions = false
                        withAnimation(AlineTheme.fastSpring) {
                            viewModel.buildResumeFromProfile()
                        }
                    },
                    isProfileComplete: viewModel.isProfileCompleteForResume
                )
            }
            // Template Selection Sheet (Pops up when tapping a resume - full screen extending to top edge)
            .fullScreenCover(isPresented: $viewModel.showTemplatePickerSheet) {
                TemplateSelectionSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingUploadModal) {
                ResumeUploadModalView(viewModel: viewModel)
            }
            .alert("Couldn't Read Resume", isPresented: Binding(
                get: { viewModel.importErrorMessage != nil },
                set: { if !$0 { viewModel.importErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.importErrorMessage ?? "")
            }
            // Navigation to Separate Full Screen Editor (NOT a sheet)
            .navigationDestination(isPresented: $viewModel.shouldNavigateToEditor) {
                ResumeDocumentEditorView(viewModel: viewModel)
            }
            // Preview straight from a resume's options menu
            .navigationDestination(isPresented: $viewModel.shouldNavigateToDirectPreview) {
                ResumeFullPrintPreviewScreen(viewModel: viewModel)
            }
            .onReceive(NotificationCenter.default.publisher(for: .userProfileDidUpdate)) { notif in
                if let updated = notif.object as? UserProfile {
                    viewModel.syncWithProfile(updated, achievements: nil)
                }
            }
        }
    }
}

// MARK: - Document Tile (Compact, Clean Layout with Refined Document Symbol & 3-Dots Action)
public struct ResumeDocumentTile: View {
    public let resume: ResumeDocument
    public let onTap: () -> Void
    public let onSetMaster: () -> Void
    public let onDelete: () -> Void
    public var onPreview: () -> Void = {}

    @State private var showOptions = false

    private func cleanModifiedDate(_ text: String) -> String {
        text.replacingOccurrences(of: "Modified: ", with: "")
            .replacingOccurrences(of: "Modified ", with: "")
    }

    // Compact popover row: small icon + label, tinted (red for delete)
    private func optionRow(_ title: String, systemImage: String, color: Color, action: (() -> Void)?) -> some View {
        Button {
            showOptions = false
            action?()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Spacer(minLength: 0)
            }
            .foregroundColor(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top Preview Container: Compact (56pt), with refined document emblem, MASTER badge & 3-dots Menu
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 247/255, green: 249/255, blue: 251/255),
                                Color(red: 242/255, green: 245/255, blue: 248/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .overlay(
                        // Refined miniature document sheet representation
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white)
                                .frame(width: 28, height: 34)
                                .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color(red: 26/255, green: 103/255, blue: 116/255).opacity(0.16), lineWidth: 0.8)
                                )

                            Image(systemName: "doc.text.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(red: 26/255, green: 103/255, blue: 116/255))
                        }
                    )

                // Top Actions Header (MASTER badge on left, 3-dots button on right)
                HStack(alignment: .top) {
                    if resume.isDefault {
                        Text("MASTER")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AlineTheme.pillDark)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.10), radius: 2, x: 0, y: 1)
                    }

                    Spacer()

                    // Three Dots Button (opens a compact options popover right next to it)
                    Button {
                        showOptions = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.95))
                                .frame(width: 24, height: 24)
                                .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                            Image(systemName: "ellipsis")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Resume options for \(resume.title)")
                    .popover(isPresented: $showOptions, arrowEdge: .top) {
                        VStack(alignment: .leading, spacing: 0) {
                            if !resume.isDefault {
                                optionRow("Preview", systemImage: "doc.text.magnifyingglass", color: AlineTheme.inkPrimary) {
                                    onPreview()
                                }
                                Divider()
                                optionRow("Set as Master", systemImage: "crown.fill", color: AlineTheme.inkPrimary) {
                                    onSetMaster()
                                }
                                Divider()
                                optionRow("Delete", systemImage: "trash", color: .red) {
                                    onDelete()
                                }
                            } else {
                                optionRow("Preview", systemImage: "doc.text.magnifyingglass", color: AlineTheme.inkPrimary) {
                                    onPreview()
                                }
                                Divider()
                                optionRow("Current Master", systemImage: "crown.fill", color: AlineTheme.inkSecondary, action: nil)
                            }
                        }
                        .frame(width: 170)
                        .presentationCompactAdaptation(.popover)
                    }
                }
                .padding(6)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }

            // Document Title & Upload / Modified Dates (Full title shown across lines without truncation)
            VStack(alignment: .leading, spacing: 3) {
                Text(resume.title)
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 34, alignment: .topLeading)

                Text("Uploaded on • \(resume.uploadDate)")
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineLimit(1)

                Text("Last modified • \(cleanModifiedDate(resume.lastModifiedDate))")
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Template Selection Sheet (Shows Resume in 3 Different Visual Templates)
public struct TemplateSelectionSheet: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var previewTemplate: ResumeDocument.ResumeTemplate = .standard

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                DiscoverBackgroundArtwork()

                VStack(spacing: 0) {
                    // Header: Circular close button (left) + centered title & subtitle
                    ZStack {
                        // Center: Title + Subtitle
                        VStack(spacing: 3) {
                            Text("Select Resume Template")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("Preview your actual resume rendered in 3 distinct layouts")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 48)

                        // Left: the app's standard close button
                        HStack {
                            AlineCloseButton { dismiss() }
                            Spacer()
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                    // 3 Template Selector Tabs
                    HStack(spacing: 8) {
                        ForEach(ResumeDocument.ResumeTemplate.allCases, id: \.self) { template in
                            let isSelected = previewTemplate == template
                            Button {
                                withAnimation(AlineTheme.fastSpring) {
                                    previewTemplate = template
                                    viewModel.selectedTemplateChoice = template
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: templateIcon(template))
                                        .font(.system(size: 12, weight: .bold))
                                    Text(template.rawValue)
                                        .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                                }
                                .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .alineGlassCapsule(selected: isSelected)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                    // Live Rendered Resume Template Preview Paper
                    ScrollView(.vertical, showsIndicators: false) {
                        // One paper per page, so a two-page resume shows both pages in each layout
                        let pages = previewResume.pageSections
                        VStack(spacing: 18) {
                            ForEach(pages.indices, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 0) {
                                    templatePreview
                                }
                                .environment(\.resumePageSections, pages[index])
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                                .overlay(alignment: .bottomTrailing) {
                                    if pages.count > 1 {
                                        ResumePageNumberBadge(label: "\(index + 1)/\(pages.count)")
                                    }
                                }
                                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 90)
                    }
                }
.scrollDismissesKeyboard(.interactively)

                // Bottom Action: Open with Selected Template
                VStack(spacing: 0) {
                    Button {
                        viewModel.confirmTemplateAndOpenEditor(template: previewTemplate)
                    } label: {
                        Text("Open in Editor with \(previewTemplate.rawValue) Layout")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .alineGlassCapsule(selected: true)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                }
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.0), Color.white.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                previewTemplate = viewModel.selectedTemplateChoice
            }
        }
    }

    private var previewResume: ResumeDocument {
        viewModel.pendingSelectedResume ?? viewModel.activeResume
    }

    @ViewBuilder
    private var templatePreview: some View {
        switch previewTemplate {
        case .standard:
            StandardTemplateView(resume: previewResume)
                .padding(20)
        case .professional:
            ProfessionalTemplateView(resume: previewResume)
        case .modern:
            ModernTemplateView(resume: previewResume)
                .padding(18)
        }
    }

    private func templateIcon(_ template: ResumeDocument.ResumeTemplate) -> String {
        switch template {
        case .standard: return "doc.text"
        case .professional: return "briefcase.fill"
        case .modern: return "sparkles"
        }
    }
}

// MARK: - Template 1: Standard (ATS-Friendly Classic Serif / Jake Ryan Style)
public struct StandardTemplateView: View {
    public let resume: ResumeDocument
    @AppStorage("userFullName") private var userFullName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""
    @AppStorage("userLinkedIn") private var userLinkedIn: String = ""
    @AppStorage("userGitHub") private var userGitHub: String = ""
    @AppStorage("userLocation") private var userLocation: String = ""

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Centered Name & Contact
            VStack(spacing: 4) {
                Text(userFullName)
                    .font(.system(size: 21, weight: .bold, design: .serif))
                    .foregroundColor(Color.black)

                let linkedInDisplay = userLinkedIn.isEmpty ? "linkedin.com/in/\(userFullName.lowercased().replacingOccurrences(of: " ", with: "-"))" : userLinkedIn
                let gitHubDisplay = userGitHub.isEmpty ? "github.com/\(userFullName.lowercased().components(separatedBy: " ").first ?? "user")-dev" : userGitHub

                Text("\(userPhone)  |  \(userEmail)  |  \(linkedInDisplay)  |  \(gitHubDisplay)")
                    .font(.system(size: 8.5, weight: .regular, design: .serif))
                    .foregroundColor(Color.black.opacity(0.85))
            }
            .resumeSection(.header)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 2)

            // Section: EDUCATION
            VStack(alignment: .leading, spacing: 4) {
                Text("EDUCATION")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.black)
                Rectangle().fill(Color.black).frame(height: 0.6)

                VStack(alignment: .leading, spacing: 5) {
                    if !resume.education.isEmpty {
                        ForEach(resume.education) { edu in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(edu.institution)
                                        .font(.system(size: 9.5, weight: .bold, design: .serif))
                                    Spacer()
                                    if !edu.location.isEmpty {
                                        Text(edu.location)
                                            .font(.system(size: 9, design: .serif))
                                    }
                                }
                                HStack {
                                    Text(edu.degree)
                                        .font(.system(size: 9, design: .serif).italic())
                                    Spacer()
                                    if !edu.period.isEmpty {
                                        Text(edu.period)
                                            .font(.system(size: 9, design: .serif).italic())
                                    }
                                }
                                if !edu.details.isEmpty {
                                    Text(edu.details)
                                        .font(.system(size: 8.5, design: .serif))
                                        .foregroundColor(Color.black.opacity(0.8))
                                }
                            }
                        }
                    } else {
                        // No education on this resume: the section stays empty
                        EmptyView()
                    }
                }
            }
            .resumeSection(.education)
            .resumePageBlock()

            // Section: EXPERIENCE
            VStack(alignment: .leading, spacing: 4) {
                Text("EXPERIENCE")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.black)
                Rectangle().fill(Color.black).frame(height: 0.6)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(resume.experiences) { exp in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(exp.role)
                                    .font(.system(size: 9.5, weight: .bold, design: .serif))
                                Spacer()
                                Text(exp.period)
                                    .font(.system(size: 9, design: .serif))
                            }
                            HStack {
                                Text(exp.company)
                                    .font(.system(size: 9, design: .serif).italic())
                                Spacer()
                                if !exp.location.isEmpty {
                                    Text(exp.location)
                                        .font(.system(size: 9, design: .serif).italic())
                                }
                            }
                            ForEach(exp.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("•").font(.system(size: 8.5, design: .serif))
                                    Text(bullet)
                                        .font(.system(size: 8.5, design: .serif))
                                        .lineSpacing(1.5)
                                }
                                .resumePageBlock()
                            }
                        }
                        .resumePageBlock()
                    }
                }
            }
            .resumeSection(.experience)
            .resumePageBlock()

            // Section: PROJECTS
            VStack(alignment: .leading, spacing: 4) {
                Text("PROJECTS")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.black)
                Rectangle().fill(Color.black).frame(height: 0.6)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(resume.projects) { proj in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline) {
                                HStack(spacing: 4) {
                                    Text(proj.title)
                                        .font(.system(size: 9.5, weight: .bold, design: .serif))
                                    Text("|")
                                        .font(.system(size: 9, design: .serif))
                                    Text(proj.techStack)
                                        .font(.system(size: 8.5, design: .serif).italic())
                                        .foregroundColor(Color.black.opacity(0.85))
                                }
                                Spacer()
                                Text("GitHub")
                                    .font(.system(size: 8.5, weight: .medium, design: .serif).italic())
                                    .underline()
                            }
                            ForEach(proj.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("•").font(.system(size: 8.5, design: .serif))
                                    Text(bullet)
                                        .font(.system(size: 8.5, design: .serif))
                                        .lineSpacing(1.5)
                                }
                                .resumePageBlock()
                            }
                        }
                        .resumePageBlock()
                    }
                }
            }
            .resumeSection(.projects)
            .resumePageBlock()

            // Section: ACHIEVEMENTS & CERTIFICATIONS
            if !resume.achievements.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACHIEVEMENTS & CERTIFICATIONS")
                        .font(.system(size: 10.5, weight: .bold, design: .serif))
                        .foregroundColor(Color.black)
                    Rectangle().fill(Color.black).frame(height: 0.6)

                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(resume.achievements, id: \.self) { ach in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•").font(.system(size: 8.5, design: .serif))
                                Text(ach)
                                    .font(.system(size: 8.5, design: .serif))
                                    .lineSpacing(1.5)
                            }
                            .resumePageBlock()
                        }
                    }
                }
                .resumeSection(.achievements)
                .resumePageBlock()
            }

            // Section: TECHNICAL SKILLS
            VStack(alignment: .leading, spacing: 4) {
                Text("TECHNICAL SKILLS")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.black)
                Rectangle().fill(Color.black).frame(height: 0.6)

                // The resume's own skill rows when it has them, otherwise the template's defaults
                Group {
                    if let lines = resume.skillLines {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(lines, id: \.self) { line in
                                Text("\(Text("• \(line.label): ").bold())\(Text(line.values))")
                                    .font(.system(size: 8.5, design: .serif))
                            }
                        }
                    } else {
                        // No grouped skill rows: list the resume's skills as one line
                        if !resume.skills.isEmpty {
                            Text(resume.skills.joined(separator: ", "))
                                .font(.system(size: 8.5, design: .serif))
                        }
                    }
                }
            }
            .resumeSection(.skills)
            .resumePageBlock()

            // Section: SOFT SKILLS (only on resumes that list them)
            if let softSkills = resume.softSkills {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SOFT SKILLS")
                        .font(.system(size: 10.5, weight: .bold, design: .serif))
                        .foregroundColor(Color.black)
                    Rectangle().fill(Color.black).frame(height: 0.6)
                    Text(softSkills.joined(separator: " · "))
                        .font(.system(size: 8.5, design: .serif))
                }
                .resumeSection(.softSkills)
                .resumePageBlock()
            }
        }
        .foregroundColor(Color.black)
    }
}

// MARK: - Template 2: Professional (Two-Column Dark Slate Sidebar / Jason Reed Style)
public struct ProfessionalTemplateView: View {
    public let resume: ResumeDocument
    @AppStorage("userFullName") private var userFullName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""
    @AppStorage("userLinkedIn") private var userLinkedIn: String = ""
    @AppStorage("userLocation") private var userLocation: String = ""

    private let sidebarBg = Color(red: 0.12, green: 0.20, blue: 0.29)
    private let textBlue = Color(red: 0.11, green: 0.46, blue: 0.86)

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // LEFT SIDEBAR (Dark Navy/Slate)
            VStack(alignment: .leading, spacing: 14) {
                // Name at top
                VStack(alignment: .leading, spacing: 3) {
                    Text(userFullName.uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .tracking(0.5)
                }
                .resumeSection(.header)
                .padding(.top, 14)

                // Section: KEY ACHIEVEMENTS (the resume's own achievements; hidden when it has none)
                if !resume.achievements.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("KEY ACHIEVEMENTS")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(0.5)
                        Rectangle().fill(Color.white.opacity(0.35)).frame(height: 0.6)
                    }

                    ForEach(Array(resume.achievements.prefix(4).enumerated()), id: \.offset) { _, achievement in
                        let parts = achievement.components(separatedBy: " — ")
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .top, spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 7.5))
                                    .foregroundColor(.yellow)
                                Text(parts[0])
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            if parts.count > 1 {
                                Text(parts.dropFirst().joined(separator: " — "))
                                    .font(.system(size: 7.2))
                                    .foregroundColor(Color.white.opacity(0.8))
                                    .lineSpacing(1.2)
                            }
                        }
                    }
                }
                .resumeSection(.header)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 14)
            .frame(width: 124)
            .background(sidebarBg)

            // RIGHT MAIN CONTENT (Clean White)
            VStack(alignment: .leading, spacing: 11) {
                // Header Headline & Contact
                VStack(alignment: .leading, spacing: 3) {
                    Text("AI/ML Intern | Full-Stack & Systems Software Engineer")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(textBlue)

                    HStack(spacing: 5) {
                        HStack(spacing: 2) {
                            Text("@")
                                .font(.system(size: 7.2, weight: .bold))
                            Text(userEmail)
                                .font(.system(size: 6.8))
                        }
                        Text("•")
                            .font(.system(size: 6.8))
                        HStack(spacing: 2) {
                            Image(systemName: "link")
                                .font(.system(size: 6.5))
                            Text(userLinkedIn.isEmpty ? "linkedin.com/in/\(userFullName.lowercased().replacingOccurrences(of: " ", with: "-"))" : userLinkedIn)
                                .font(.system(size: 6.8))
                        }
                        Text("•")
                            .font(.system(size: 6.8))
                        HStack(spacing: 2) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 6.5))
                            Text(userLocation)
                                .font(.system(size: 6.8))
                        }
                    }
                    .foregroundColor(Color.gray)
                }
                .resumeSection(.header)
                .padding(.top, 14)

                // Section: SUMMARY
                VStack(alignment: .leading, spacing: 3) {
                    Text("SUMMARY")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color.gray)
                        .tracking(0.5)
                    Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)

                    Text(resume.summary)
                        .font(.system(size: 7.5))
                        .foregroundColor(Color.black.opacity(0.85))
                        .lineSpacing(1.4)
                }
                .resumeSection(.summary)

                // Section: EXPERIENCE
                VStack(alignment: .leading, spacing: 6) {
                    Text("EXPERIENCE")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color.gray)
                        .tracking(0.5)
                    Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)

                    ForEach(resume.experiences) { exp in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(exp.role)
                                    .font(.system(size: 8.2, weight: .bold))
                                    .foregroundColor(Color.black)
                                Spacer()
                                Text(exp.period)
                                    .font(.system(size: 7.2))
                                    .foregroundColor(Color.gray)
                            }
                            HStack {
                                Text(exp.company)
                                    .font(.system(size: 7.8, weight: .bold))
                                    .foregroundColor(textBlue)
                                Spacer()
                                if !exp.location.isEmpty {
                                    Text(exp.location)
                                        .font(.system(size: 7.2))
                                        .foregroundColor(Color.gray)
                                }
                            }
                            ForEach(exp.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 3) {
                                    Text("•").font(.system(size: 7.2)).foregroundColor(Color.gray)
                                    Text(bullet)
                                        .font(.system(size: 7.2))
                                        .foregroundColor(Color.black.opacity(0.85))
                                        .lineSpacing(1.3)
                                }
                            }
                        }
                    }
                }
                .resumeSection(.experience)

                // Section: PROJECTS
                VStack(alignment: .leading, spacing: 6) {
                    Text("PROJECTS")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color.gray)
                        .tracking(0.5)
                    Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)

                    ForEach(resume.projects) { proj in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(proj.title)
                                    .font(.system(size: 8.2, weight: .bold))
                                    .foregroundColor(Color.black)
                                Spacer()
                                Text("GitHub")
                                    .font(.system(size: 7.2, weight: .bold))
                                    .foregroundColor(textBlue)
                            }
                            Text(proj.techStack)
                                .font(.system(size: 7.2, weight: .medium))
                                .foregroundColor(Color.gray)

                            ForEach(proj.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 3) {
                                    Text("•").font(.system(size: 7.2)).foregroundColor(Color.gray)
                                    Text(bullet)
                                        .font(.system(size: 7.2))
                                        .foregroundColor(Color.black.opacity(0.85))
                                        .lineSpacing(1.3)
                                }
                            }
                        }
                    }
                }
                .resumeSection(.projects)

                // Section: SKILLS
                VStack(alignment: .leading, spacing: 3) {
                    Text("SKILLS")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color.gray)
                        .tracking(0.5)
                    Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)

                    Text(resume.skills.joined(separator: " · "))
                        .font(.system(size: 7.2))
                        .foregroundColor(Color.black.opacity(0.85))
                        .lineSpacing(1.3)
                }
                .resumeSection(.skills)

                // Section: SOFT SKILLS (only on resumes that list them)
                if let softSkills = resume.softSkills {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("SOFT SKILLS")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(Color.gray)
                            .tracking(0.5)
                        Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)
                        Text(softSkills.joined(separator: " · "))
                            .font(.system(size: 7.2))
                            .foregroundColor(Color.black.opacity(0.85))
                    }
                    .resumeSection(.softSkills)
                }

                // Section: EDUCATION
                VStack(alignment: .leading, spacing: 4) {
                    Text("EDUCATION")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color.gray)
                        .tracking(0.5)
                    Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)

                    if !resume.education.isEmpty {
                        ForEach(resume.education) { edu in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(edu.degree)
                                        .font(.system(size: 7.8, weight: .bold))
                                        .foregroundColor(Color.black)
                                    Spacer()
                                    if !edu.period.isEmpty {
                                        Text(edu.period)
                                            .font(.system(size: 7.2))
                                            .foregroundColor(Color.gray)
                                    }
                                }
                                HStack {
                                    Text(edu.institution)
                                        .font(.system(size: 7.5, weight: .bold))
                                        .foregroundColor(textBlue)
                                    Spacer()
                                    if !edu.location.isEmpty {
                                        Text(edu.location)
                                            .font(.system(size: 7.2))
                                            .foregroundColor(Color.gray)
                                    }
                                }
                                if !edu.details.isEmpty {
                                    Text(edu.details)
                                        .font(.system(size: 6.8))
                                        .foregroundColor(Color.gray)
                                }
                            }
                        }
                    } else {
                        // No education on this resume: the section stays empty
                        EmptyView()
                    }
                }
                .resumeSection(.education)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 14)
        }
    }
}

// MARK: - Template 3: Modern (Contemporary Blue Accent / Photo Header Style)
public struct ModernTemplateView: View {
    public let resume: ResumeDocument
    @AppStorage("userFullName") private var userFullName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""
    @AppStorage("userLinkedIn") private var userLinkedIn: String = ""
    @AppStorage("userGitHub") private var userGitHub: String = ""
    @AppStorage("userLocation") private var userLocation: String = ""

    private let headerBlue = Color(red: 0.11, green: 0.44, blue: 0.72)

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Name, Contact Icons, and Photo on the right
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(userFullName)
                        .font(.system(size: 21, weight: .bold, design: .default))
                        .foregroundColor(headerBlue)

                    HStack(spacing: 8) {
                        Label(userLocation, systemImage: "mappin.circle.fill")
                        Label(userPhone, systemImage: "phone.fill")
                        Label(userEmail, systemImage: "envelope.fill")
                    }
                    .font(.system(size: 7.5, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.75))

                    let linkedInDisplay = userLinkedIn.isEmpty ? "linkedin.com/in/\(userFullName.lowercased().replacingOccurrences(of: " ", with: "-"))" : userLinkedIn
                    let gitHubDisplay = userGitHub.isEmpty ? "github.com/\(userFullName.lowercased().components(separatedBy: " ").first ?? "user")-dev" : userGitHub

                    HStack(spacing: 8) {
                        Label(linkedInDisplay, systemImage: "link")
                        Label(gitHubDisplay, systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    .font(.system(size: 7.5, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.75))
                }

                Spacer()

                // Profile photo circle (clean placeholder / empty circle with subtle user icon)
                ZStack {
                    Circle()
                        .fill(AlineTheme.canvasBackground)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle().stroke(headerBlue.opacity(0.4), lineWidth: 1.5)
                        )
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(headerBlue.opacity(0.5))
                }
            }
            .resumeSection(.header)
            .padding(.bottom, 2)

            // Section: PROFESSIONAL SUMMARY
            VStack(alignment: .leading, spacing: 3) {
                Text("PROFESSIONAL SUMMARY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(headerBlue)
                Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                Text(resume.summary)
                    .font(.system(size: 8.5))
                    .lineSpacing(1.6)
                    .foregroundColor(Color.black.opacity(0.85))
            }
            .resumeSection(.summary)
            .resumePageBlock()

            // Section: TECHNICAL SKILLS
            VStack(alignment: .leading, spacing: 3) {
                Text("TECHNICAL SKILLS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(headerBlue)
                Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                // The resume's own skill rows when it has them, otherwise the template's defaults
                Group {
                    if let lines = resume.skillLines {
                        VStack(alignment: .leading, spacing: 2.5) {
                            ForEach(lines, id: \.self) { line in
                                Text("\(Text("• \(line.label): ").bold())\(Text(line.values))")
                                    .font(.system(size: 8.5))
                            }
                        }
                    } else {
                        // No grouped skill rows: list the resume's skills as one line
                        if !resume.skills.isEmpty {
                            Text(resume.skills.joined(separator: ", "))
                                .font(.system(size: 8.5))
                        }
                    }
                }
                .foregroundColor(Color.black.opacity(0.85))
            }
            .resumeSection(.skills)
            .resumePageBlock()

            // Section: SOFT SKILLS (only on resumes that list them)
            if let softSkills = resume.softSkills {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SOFT SKILLS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(headerBlue)
                    Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)
                    Text(softSkills.joined(separator: " · "))
                        .font(.system(size: 8.5))
                }
                .resumeSection(.softSkills)
                .resumePageBlock()
            }

            // Section: PROFESSIONAL EXPERIENCE
            VStack(alignment: .leading, spacing: 4) {
                Text("PROFESSIONAL EXPERIENCE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(headerBlue)
                Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(resume.experiences) { exp in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(exp.role)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color.black)
                                Spacer()
                                Text(exp.period)
                                    .font(.system(size: 8.5))
                                    .foregroundColor(Color.black.opacity(0.75))
                            }
                            HStack {
                                Text(exp.company)
                                    .font(.system(size: 8.5).italic())
                                    .foregroundColor(Color.black.opacity(0.85))
                                Spacer()
                                if !exp.location.isEmpty {
                                    Text(exp.location)
                                        .font(.system(size: 8.5).italic())
                                        .foregroundColor(Color.black.opacity(0.75))
                                }
                            }
                            ForEach(exp.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("•").font(.system(size: 8.5))
                                    Text(bullet)
                                        .font(.system(size: 8.5))
                                        .lineSpacing(1.5)
                                        .foregroundColor(Color.black.opacity(0.85))
                                }
                                .resumePageBlock()
                            }
                        }
                        .resumePageBlock()
                    }
                }
            }
            .resumeSection(.experience)
            .resumePageBlock()

            // Section: KEY PROJECTS
            VStack(alignment: .leading, spacing: 4) {
                Text("KEY PROJECTS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(headerBlue)
                Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(resume.projects) { proj in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                HStack(spacing: 4) {
                                    Text(proj.title)
                                        .font(.system(size: 9, weight: .bold))
                                    Text("|")
                                        .font(.system(size: 8.5))
                                    Text(proj.techStack)
                                        .font(.system(size: 8.5).italic())
                                        .foregroundColor(Color.black.opacity(0.75))
                                }
                                Spacer()
                                Text("GitHub")
                                    .font(.system(size: 8.5, weight: .medium).italic())
                                    .foregroundColor(headerBlue)
                                    .underline()
                            }
                            ForEach(proj.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("•").font(.system(size: 8.5))
                                    Text(bullet)
                                        .font(.system(size: 8.5))
                                        .lineSpacing(1.5)
                                        .foregroundColor(Color.black.opacity(0.85))
                                }
                                .resumePageBlock()
                            }
                        }
                        .resumePageBlock()
                    }
                }
            }
            .resumeSection(.projects)
            .resumePageBlock()

            // Section: EDUCATION
            VStack(alignment: .leading, spacing: 4) {
                Text("EDUCATION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(headerBlue)
                Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                VStack(alignment: .leading, spacing: 4) {
                    if !resume.education.isEmpty {
                        ForEach(resume.education) { edu in
                            VStack(alignment: .leading, spacing: 1) {
                                HStack {
                                    Text(edu.institution)
                                        .font(.system(size: 9, weight: .bold))
                                    Spacer()
                                    if !edu.period.isEmpty {
                                        Text(edu.period)
                                            .font(.system(size: 8.5))
                                    }
                                }
                                HStack {
                                    Text(edu.degree)
                                        .font(.system(size: 8.5).italic())
                                    Spacer()
                                    if !edu.location.isEmpty {
                                        Text(edu.location)
                                            .font(.system(size: 8.5).italic())
                                    }
                                }
                                if !edu.details.isEmpty {
                                    Text(edu.details)
                                        .font(.system(size: 8))
                                        .foregroundColor(Color.black.opacity(0.75))
                                }
                            }
                        }
                    } else {
                        // No education on this resume: the section stays empty
                        EmptyView()
                    }
                }
                .foregroundColor(Color.black.opacity(0.85))
            }
            .resumeSection(.education)
            .resumePageBlock()

            // Section: ACHIEVEMENTS & CERTIFICATIONS
            if !resume.achievements.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACHIEVEMENTS & CERTIFICATIONS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(headerBlue)
                    Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(resume.achievements, id: \.self) { ach in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•").font(.system(size: 8.5))
                                Text(ach)
                                    .font(.system(size: 8.5))
                                    .lineSpacing(1.5)
                                    .foregroundColor(Color.black.opacity(0.85))
                            }
                            .resumePageBlock()
                        }
                    }
                }
                .resumeSection(.achievements)
                .resumePageBlock()
            }
        }
    }
}

// MARK: - Resume Document Editor (Separate Full Screen)
public struct ResumeDocumentEditorView: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isRenamingResume: Bool = false
    @State private var editedResumeTitle: String = ""
    @State private var textSelection = ResumeTextSelection()
    @State private var paperWidth: CGFloat = 0
    /// Reset by SwiftUI even when a drag is cancelled, so scrolling never stays locked
    @GestureState private var isHandleDragging = false

    public var body: some View {
        ZStack(alignment: .bottom) {
            DiscoverBackgroundArtwork()
                .contentShape(Rectangle())
                .onTapGesture {
                    textSelection.clear()
                    deselectSnippet()
                }

            ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Notification Banner when Changes Saved & Chat Cleared
                    if viewModel.showSavedBanner {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AlineTheme.accentEmerald)
                            Text("Resume saved! You can keep editing with AI.")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Spacer()
                        }
                        .padding(14)
                        .background(AlineTheme.cardMint)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Instruction Tip Banner (Clean 2-line instruction, slightly smaller font, AI Chat button removed)
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Text("Press and hold a word, then drag the handles to select more text to edit with AI.")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AlineTheme.cardYellow.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                    // Formatted Paper Sheet View in Chosen Template (Editable & Interactive);
                    // a two-page resume gets one paper box per page
                    VStack(spacing: 18) {
                        let pages = viewModel.activeResume.pageSections
                        ForEach(pages.indices, id: \.self) { index in
                            editablePaper
                                .environment(\.resumePageSections, pages[index])
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                                .overlay(alignment: .bottomTrailing) {
                                    if pages.count > 1 {
                                        ResumePageNumberBadge(label: "\(index + 1)/\(pages.count)")
                                    }
                                }
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        }
                    }
                    // Native-style drag handles at both ends of the selection
                    .overlay(alignment: .topLeading) {
                        if let rects = textSelection.handleRects {
                            selectionHandle(at: rects.start, isStart: true)
                            selectionHandle(at: rects.end, isStart: false)
                        }
                    }
                    .environment(\.resumeTextSelection, textSelection)
                    .coordinateSpace(.named(ResumeTextSelection.space))
                    .simultaneousGesture(
                        SpatialTapGesture(coordinateSpace: .local)
                            .onEnded { textSelection.handleTap(at: $0.location) }
                    )
                    .onChange(of: isHandleDragging) { _, active in
                        if !active { textSelection.endDrag() }
                    }
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { paperWidth = $0 }
                    // "Edit with AI" pill above the current text selection
                    .overlay(alignment: .topLeading) {
                        if let rect = textSelection.menuRect {
                            Button {
                                textSelection.editWithAI()
                            } label: {
                                // Clear glass like the native iOS edit menu
                                Text("Edit with AI")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .alineGlassCapsule(selected: false)
                            }
                            .buttonStyle(.plain)
                            .fixedSize()
                            .position(
                                x: min(max(rect.midX, 70), max(paperWidth - 70, 70)),
                                y: rect.minY > 40 ? rect.minY - 22 : rect.maxY + 22
                            )
                            .transition(.opacity)
                        }
                    }
                    .sensoryFeedback(.selection, trigger: textSelection.selectionCount)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Deselect snippet if user taps paper background
                        deselectSnippet()
                    }

                    Spacer(minLength: 120) // Room for bottom Preview button
                }
                .environment(\.resumeFlashedKey, viewModel.flashedTargetKey)
            }
.scrollDismissesKeyboard(.interactively)
            // Hold the page still while a finger drags the selection
            .scrollDisabled(textSelection.isDragging)
            .contentShape(Rectangle())
            .onTapGesture {
                // Deselect snippet if user taps scroll area
                textSelection.clear()
                deselectSnippet()
            }
            // Bring the point the AI just changed into view
            .onChange(of: viewModel.flashedTargetKey) { _, key in
                guard let key else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    scrollProxy.scrollTo(key, anchor: .center)
                }
            }
            }

            // Bottom Sticky Bar: Preview (about 70%) and Edit, which opens the AI chat without a selection
            VStack(spacing: 0) {
                GeometryReader { proxy in
                    HStack(spacing: 10) {
                        Button {
                            deselectSnippet()
                            viewModel.shouldNavigateToPrintPreview = true
                        } label: {
                            Text("Preview")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .alineGlassCapsule(selected: true)
                        }
                        .buttonStyle(.plain)
                        .frame(width: (proxy.size.width - 10) * 0.7)

                        Button {
                            textSelection.clear()
                            viewModel.openAIPanel()
                        } label: {
                            Label("Edit", systemImage: "wand.and.stars")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .alineGlassCapsule(selected: false)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit with AI")
                    }
                }
                .frame(height: 54)
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 16)
            }
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.0), Color.white.opacity(0.95), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if isRenamingResume {
                    HStack(spacing: 6) {
                        TextField("Resume Title", text: $editedResumeTitle)
.alineKeyboardDismissal(.done)
                            .font(.system(size: 15, weight: .bold))
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .frame(maxWidth: 190)
                            .onSubmit {
                                commitRename()
                            }

                        Button {
                            commitRename()
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 17))
                                .foregroundColor(AlineTheme.pillDark)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    VStack(spacing: 2) {
                        Text(viewModel.activeResume.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(1)

                        // Subcaption text under resume name (NO template name inside the resume)
                        Text("\(viewModel.activeResume.selectedTemplate.rawValue) Template")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        editedResumeTitle = viewModel.activeResume.title
                        isRenamingResume = true
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                // Save button in black & white theme, sparkles removed
                Button {
                    withAnimation {
                        commitRename()
                        viewModel.saveDocumentChanges()
                    }
                } label: {
                    Text("Save")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .alineGlassCapsule(selected: true)
                }
                .buttonStyle(.plain)
            }
            // No Liquid Glass platter behind the Save pill
            .sharedBackgroundVisibility(.hidden)
        }
        // Bottom AI Assistant Panel with Full Session Chat Feed
        .sheet(isPresented: $viewModel.showAIPanel) {
            AIAssistantDrawer(viewModel: viewModel)
        }
        // Step 6: Full Page Print Preview
        .navigationDestination(isPresented: $viewModel.shouldNavigateToPrintPreview) {
            ResumeFullPrintPreviewScreen(viewModel: viewModel)
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // Selections spanning several bullets/sections go to the AI panel as one snippet
            textSelection.onSelect = { text in
                viewModel.selectTextForAI(key: "selection", text: text)
            }
            textSelection.onEditWithAI = {
                viewModel.openAIPanel()
            }
        }
        .onDisappear {
            textSelection.clear()
        }
    }

    private func commitRename() {
        let trimmed = editedResumeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            viewModel.activeResume.title = trimmed
            if let idx = viewModel.resumes.firstIndex(where: { $0.id == viewModel.activeResume.id }) {
                viewModel.resumes[idx].title = trimmed
            }
        }
        isRenamingResume = false
    }

    /// The chosen template, editable; shown once per page of the resume
    @ViewBuilder
    private var editablePaper: some View {
        switch viewModel.activeResume.selectedTemplate {
        case .standard:
            EditableStandardTemplateView(viewModel: viewModel)
                .padding(20)
        case .professional:
            EditableProfessionalTemplateView(viewModel: viewModel)
        case .modern:
            EditableModernTemplateView(viewModel: viewModel)
                .padding(18)
        }
    }

    /// Bar-and-knob handle like native text selection; dragging it moves that end of the selection
    private func selectionHandle(at rect: CGRect, isStart: Bool) -> some View {
        VStack(spacing: 0) {
            if isStart {
                Circle().fill(AlineTheme.inkPrimary).frame(width: 9, height: 9)
            }
            Capsule().fill(AlineTheme.inkPrimary).frame(width: 2, height: rect.height + 2)
            if !isStart {
                Circle().fill(AlineTheme.inkPrimary).frame(width: 9, height: 9)
            }
        }
        .frame(width: 36, height: rect.height + 36)
        .contentShape(Rectangle())
        .position(x: isStart ? rect.minX : rect.maxX, y: rect.midY + (isStart ? -4.5 : 4.5))
        .highPriorityGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named(ResumeTextSelection.space))
                .updating($isHandleDragging) { _, active, _ in active = true }
                .onChanged { value in
                    if !textSelection.isDragging { textSelection.beginHandleDrag(start: isStart) }
                    textSelection.dragSelection(to: value.location)
                }
        )
    }

    private func deselectSnippet() {
        if viewModel.selectedSnippetTargetKey != nil {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedSnippetTargetKey = nil
                viewModel.selectedSnippetText = ""
            }
        }
    }
}

// MARK: - Resume Text Selection (Long-Press & Drag Across Any Text, Rows and Sections)
// Every piece of resume text in the editor lays out a transparent, word-by-word twin of itself
// and registers each word's frame here. A long-press on a word selects it; tapping another word
// (in any bullet or section) extends the selection to it, and a double-tap selects a whole bullet.
// The twins draw the highlight and the editor shows an "Edit with AI" pill above it. Tapping
// anywhere outside the selection clears it.
@MainActor
@Observable
public final class ResumeTextSelection {
    /// Coordinate space of the resume paper; every frame here is measured in it
    nonisolated static let space = "resumeTextSelectionPaper"

    /// Called with text spanning several segments (single-segment selections use the segment's own handler)
    @ObservationIgnored var onSelect: (String) -> Void = { _ in }
    @ObservationIgnored var onEditWithAI: () -> Void = {}

    fileprivate struct Segment {
        var words: [String] = []
        var wordFrames: [Int: CGRect] = [:]
        var onRangeSelected: ((String) -> Void)?

        var frame: CGRect { wordFrames.values.reduce(CGRect.null) { $0.union($1) } }
        var lastIndex: Int { max(words.count - 1, 0) }
    }

    @ObservationIgnored private var segments: [UUID: Segment] = [:]
    @ObservationIgnored private var anchor: (id: UUID, range: ClosedRange<Int>)?
    @ObservationIgnored private var focus: (id: UUID, index: Int)?

    /// Selected word indices per segment
    fileprivate private(set) var highlighted: [UUID: ClosedRange<Int>] = [:]
    /// Bounds of the whole selection while the "Edit with AI" pill is showing
    private(set) var menuRect: CGRect?
    /// Bumped on every new selection to drive haptic feedback
    private(set) var selectionCount = 0
    /// True while a finger is dragging the selection (scrolling pauses meanwhile)
    private(set) var isDragging = false

    // MARK: Registration
    fileprivate func register(_ id: UUID, words: [String], onRangeSelected: ((String) -> Void)?) {
        var segment = segments[id] ?? Segment()
        // Word frames can arrive before registration; only drop them when the text itself changed
        if !segment.words.isEmpty, segment.words != words { segment.wordFrames = [:] }
        segment.words = words
        segment.onRangeSelected = onRangeSelected
        segments[id] = segment
    }

    fileprivate func setFrame(_ frame: CGRect, of index: Int, in id: UUID) {
        segments[id, default: Segment()].wordFrames[index] = frame
    }

    fileprivate func unregister(_ id: UUID) {
        segments[id] = nil
        if highlighted[id] != nil { clear() }
    }

    func clear() {
        anchor = nil
        focus = nil
        isDragging = false
        if !highlighted.isEmpty { highlighted = [:] }
        if menuRect != nil { menuRect = nil }
    }

    /// Taps outside the selection clear it; taps on it keep it (and its pill) in place
    func handleTap(at point: CGPoint) {
        guard let menuRect, !menuRect.insetBy(dx: -4, dy: -4).contains(point) else { return }
        // Taps on a word extend the selection instead; the word's own tap handles those
        let onWord = segments.values.contains { $0.wordFrames.values.contains { $0.contains(point) } }
        if !onWord { clear() }
    }

    // MARK: Gestures
    fileprivate func selectWord(in id: UUID, at index: Int) {
        anchor = (id, index...index)
        focus = nil
        selectionCount += 1
        updateSelection()
        presentMenu()
    }

    /// With a selection showing, tapping another word extends the selection up to it
    fileprivate func extendSelection(to index: Int, in id: UUID) {
        guard anchor != nil else { return }
        focus = (id, index)
        updateSelection()
        presentMenu()
    }

    fileprivate func selectAll(in id: UUID) {
        guard let segment = segments[id], !segment.words.isEmpty else { return }
        anchor = (id, 0...segment.lastIndex)
        focus = nil
        selectionCount += 1
        updateSelection()
        presentMenu()
    }

    // MARK: Dragging
    /// Dragging a handle moves that end of the selection to the word under the finger
    func dragSelection(to point: CGPoint) {
        guard anchor != nil, let word = word(near: point) else { return }
        if !isDragging { isDragging = true }
        menuRect = nil
        if focus?.id != word.id || focus?.index != word.index {
            focus = word
            updateSelection()
        }
    }

    /// Dragging the start handle keeps the end fixed, so the end becomes the anchor
    func beginHandleDrag(start: Bool) {
        guard let ends = selectionEnds else { return }
        let fixed = start ? ends.end : ends.start
        let moving = start ? ends.start : ends.end
        anchor = (fixed.id, fixed.index...fixed.index)
        focus = moving
    }

    func endDrag() {
        isDragging = false
        if !highlighted.isEmpty { presentMenu() }
    }

    /// First and last selected word, in reading order
    private var selectionEnds: (start: (id: UUID, index: Int), end: (id: UUID, index: Int))? {
        let ordered = orderedSegments().filter { highlighted[$0] != nil }
        guard let first = ordered.first, let last = ordered.last,
              let firstRange = highlighted[first], let lastRange = highlighted[last] else { return nil }
        return ((first, firstRange.lowerBound), (last, lastRange.upperBound))
    }

    /// Frames of the first and last selected words, where the drag handles sit
    var handleRects: (start: CGRect, end: CGRect)? {
        guard let ends = selectionEnds,
              let start = segments[ends.start.id]?.wordFrames[ends.start.index],
              let end = segments[ends.end.id]?.wordFrames[ends.end.index] else { return nil }
        return (start, end)
    }

    /// The word under `point`, or the closest one (nearest line first, then nearest along it)
    private func word(near point: CGPoint) -> (id: UUID, index: Int)? {
        var best: (id: UUID, index: Int)?
        var bestScore = CGFloat.greatestFiniteMagnitude
        for (id, segment) in segments {
            for (index, frame) in segment.wordFrames where index < segment.words.count {
                let dy = max(frame.minY - point.y, 0, point.y - frame.maxY)
                let dx = max(frame.minX - point.x, 0, point.x - frame.maxX)
                let score = dy * 4 + dx
                if score < bestScore {
                    bestScore = score
                    best = (id, index)
                }
            }
        }
        return best
    }

    func editWithAI() {
        let text = selectedText
        guard !text.isEmpty else { return }
        if highlighted.count == 1, let id = highlighted.keys.first, let handler = segments[id]?.onRangeSelected {
            handler(text)
        } else {
            onSelect(text)
        }
        onEditWithAI()
        clear()
    }

    // MARK: Selection model
    /// Segments in reading order: top to bottom, left to right within a line
    private func orderedSegments() -> [UUID] {
        let visible = segments.filter { !$0.value.wordFrames.isEmpty }
        let byTop = visible.sorted { $0.value.frame.minY < $1.value.frame.minY }
        var lines: [[(id: UUID, frame: CGRect)]] = []
        var lineBottom: CGFloat = -.greatestFiniteMagnitude
        for (id, segment) in byTop {
            let frame = segment.frame
            if !lines.isEmpty, frame.minY < lineBottom - 2 {
                lines[lines.count - 1].append((id, frame))
                lineBottom = max(lineBottom, frame.maxY)
            } else {
                lines.append([(id, frame)])
                lineBottom = frame.maxY
            }
        }
        return lines.flatMap { $0.sorted { $0.frame.minX < $1.frame.minX }.map(\.id) }
    }

    private func updateSelection() {
        guard let anchor, let anchorSegment = segments[anchor.id] else { return clear() }
        var result: [UUID: ClosedRange<Int>] = [:]

        if let focus, focus.id != anchor.id, let focusSegment = segments[focus.id] {
            let ordered = orderedSegments()
            guard let a = ordered.firstIndex(of: anchor.id),
                  let f = ordered.firstIndex(of: focus.id) else { return }
            // Only include segments in the same column(s) as the ends of the selection
            let ends = anchorSegment.frame.union(focusSegment.frame)
            for id in ordered[min(a, f)...max(a, f)] {
                guard let segment = segments[id], !segment.words.isEmpty else { continue }
                if id == anchor.id {
                    result[id] = a < f ? anchor.range.lowerBound...segment.lastIndex : 0...anchor.range.upperBound
                } else if id == focus.id {
                    result[id] = a < f ? 0...focus.index : focus.index...segment.lastIndex
                } else {
                    let frame = segment.frame
                    guard frame.maxX > ends.minX, frame.minX < ends.maxX else { continue }
                    result[id] = 0...segment.lastIndex
                }
            }
        } else {
            var range = anchor.range
            if let focus {
                range = min(range.lowerBound, focus.index)...max(range.upperBound, focus.index)
            }
            result[anchor.id] = range
        }
        highlighted = result
    }

    private var selectedText: String {
        let ordered = orderedSegments()
        return highlighted
            .sorted { (ordered.firstIndex(of: $0.key) ?? 0) < (ordered.firstIndex(of: $1.key) ?? 0) }
            .compactMap { id, range in
                guard let words = segments[id]?.words, range.upperBound < words.count else { return nil }
                return words[range].joined().trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .joined(separator: "\n")
    }

    // MARK: Edit pill
    private func presentMenu() {
        let rect = highlighted.reduce(CGRect.null) { rect, item in
            guard let frames = segments[item.key]?.wordFrames else { return rect }
            return item.value.reduce(rect) { $0.union(frames[$1] ?? .null) }
        }
        menuRect = rect.isNull ? nil : rect
    }
}

extension EnvironmentValues {
    @Entry var resumeTextSelection: ResumeTextSelection? = nil
}

// MARK: - Resume Font (Template Typography Shared by Text and Its Selection Twin)
public struct ResumeFont: Equatable, Sendable {
    public var size: CGFloat
    public var isSerif: Bool = false
    public var weight: Font.Weight = .regular
    public var italic: Bool = false

    public var font: Font {
        let base = Font.system(size: size, weight: weight, design: isSerif ? .serif : .default)
        return italic ? base.italic() : base
    }

    var bold: ResumeFont {
        var copy = self
        copy.weight = .bold
        return copy
    }
}

/// Builds the font for a resume Text and its `.resumeSelectable` twin so both lay out identically
private func resumeUIFont(size: CGFloat, isSerif: Bool = false, weight: Font.Weight = .regular, italic: Bool = false) -> ResumeFont {
    ResumeFont(size: size, isSerif: isSerif, weight: weight, italic: italic)
}

// MARK: - Word Tokens
/// Splits text where SwiftUI may wrap it: after spaces, hyphens and dashes. Tokens keep their
/// trailing whitespace so joining a range gives back the original text.
private func resumeWordTokens(_ text: String) -> [String] {
    let breakAfter: Set<Character> = ["-", "–", "—"]
    var tokens: [String] = []
    var current = ""
    var previous: Character?
    for character in text {
        if let previous, !character.isWhitespace,
           previous.isWhitespace || breakAfter.contains(previous) {
            tokens.append(current)
            current = ""
        }
        current.append(character)
        previous = character
    }
    if !current.isEmpty { tokens.append(current) }
    return tokens
}

// MARK: - Word Flow Layout (Wraps Words the Way Text Does)
private struct ResumeWordFlowLayout: Layout {
    let lineSpacing: CGFloat
    /// Width of the space each token may carry, which can hang past the line end like in Text
    let trailingSpace: CGFloat
    let hasTrailingSpace: [Bool]

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal: proposal, subviews: subviews)
        return CGSize(width: proposal.width ?? rows.width, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, origin) in rows.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (origins: [CGPoint], width: CGFloat, height: CGFloat) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let lineHeight = sizes.map(\.height).max() ?? 0
        let maxWidth = proposal.width ?? .infinity
        // A Text sized to one line never wraps, even if word widths add up a hair wider
        let singleLine = (proposal.height ?? .infinity) < lineHeight * 1.6

        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var widest: CGFloat = 0
        for (index, size) in sizes.enumerated() {
            let visibleWidth = size.width - (hasTrailingSpace[index] ? trailingSpace : 0)
            if !singleLine, x > 0, x + visibleWidth > maxWidth + 0.5 {
                x = 0
                y += lineHeight + lineSpacing
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width
            widest = max(widest, x)
        }
        return (origins, widest, sizes.isEmpty ? 0 : y + lineHeight)
    }
}

// MARK: - Selectable Twin (Transparent Word Layout Over a SwiftUI Text)
private struct ResumeSelectableTwin: View {
    let selection: ResumeTextSelection
    let text: String
    let font: ResumeFont
    let boldPrefix: String?
    let lineSpacing: CGFloat
    let onRangeSelected: ((String) -> Void)?

    @State private var id = UUID()

    private var tokens: [String] { resumeWordTokens(text) }

    /// Character offset where each token starts, to bold the tokens inside `boldPrefix`
    private func tokenStarts(_ tokens: [String]) -> [Int] {
        var starts: [Int] = []
        var offset = 0
        for token in tokens {
            starts.append(offset)
            offset += token.count
        }
        return starts
    }

    var body: some View {
        let tokens = tokens
        let boldLength = boldPrefix.flatMap { text.hasPrefix($0) ? $0.count : nil } ?? 0
        let starts = tokenStarts(tokens)
        let selected = selection.highlighted[id]

        ResumeWordFlowLayout(
            lineSpacing: lineSpacing,
            trailingSpace: font.size * 0.25,
            hasTrailingSpace: tokens.map { $0.last?.isWhitespace ?? false }
        ) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { index, token in
                Text(token)
                    .font(starts[index] < boldLength ? font.bold.font : font.font)
                    .foregroundStyle(.clear)
                    .fixedSize()
                    .background {
                        if selected?.contains(index) == true {
                            Rectangle()
                                .fill(AlineTheme.cardSkyBlue)
                                .blendMode(.multiply)
                        }
                    }
                    .contentShape(Rectangle())
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .named(ResumeTextSelection.space))
                    } action: { frame in
                        selection.setFrame(frame, of: index, in: id)
                    }
                    // Taps and a simultaneous long-press never claim the touch, so swipes over text still scroll
                    .onTapGesture(count: 2) {
                        selection.selectAll(in: id)
                    }
                    .onTapGesture {
                        selection.extendSelection(to: index, in: id)
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.35)
                            .onEnded { _ in selection.selectWord(in: id, at: index) }
                    )
            }
        }
        .onAppear {
            selection.register(id, words: tokens, onRangeSelected: onRangeSelected)
        }
        .onChange(of: text) {
            selection.register(id, words: resumeWordTokens(text), onRangeSelected: onRangeSelected)
        }
        .onDisappear {
            selection.unregister(id)
        }
        .accessibilityHidden(true)
    }
}

private struct ResumeSelectableModifier: ViewModifier {
    @Environment(\.resumeTextSelection) private var selection
    let text: String
    let font: ResumeFont
    let boldPrefix: String?
    let lineSpacing: CGFloat
    let onRangeSelected: ((String) -> Void)?

    func body(content: Content) -> some View {
        content.overlay(alignment: .topLeading) {
            if let selection {
                ResumeSelectableTwin(
                    selection: selection,
                    text: text,
                    font: font,
                    boldPrefix: boldPrefix,
                    lineSpacing: lineSpacing,
                    onRangeSelected: onRangeSelected
                )
            }
        }
    }
}

extension View {
    /// Makes this Text selectable in the resume editor. `text` and `font` must match what the Text renders.
    func resumeSelectable(_ text: String, font: ResumeFont, boldPrefix: String? = nil, lineSpacing: CGFloat = 0, onRangeSelected: ((String) -> Void)? = nil) -> some View {
        modifier(ResumeSelectableModifier(text: text, font: font, boldPrefix: boldPrefix, lineSpacing: lineSpacing, onRangeSelected: onRangeSelected))
    }
}

// MARK: - Selectable Text Row (Bullet / Summary Paragraph)
public struct SelectableTextRow: View {
    public let text: String
    public var hasBullet: Bool = true
    public var bulletSymbol: String = "•"
    public var font: Font = .system(size: 12.5, weight: .regular)
    public var uiFont: ResumeFont = ResumeFont(size: 11)
    public var textColor: Color = AlineTheme.inkPrimary
    public var uiTextColor: Color = .black
    /// Which resume point this is (e.g. "exp-0-bullet-1"); used to scroll to it and flash it after an AI edit
    public var rowKey: String? = nil
    public let isSelected: Bool
    public var onRangeSelected: ((String) -> Void)? = nil
    public let onSelect: () -> Void
    public let onEditWithAI: () -> Void

    @Environment(\.resumeFlashedKey) private var flashedKey

    public var body: some View {
        HStack(alignment: .top, spacing: 4) {
            if hasBullet {
                Text(bulletSymbol)
                    .font(font.bold())
                    .foregroundColor(textColor)
                    .padding(.top, 1)
            }
            // SwiftUI Text — identical rendering to preview templates
            Text(text)
                .font(font)
                .foregroundColor(textColor)
                .lineSpacing(1.5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .resumeSelectable(text, font: uiFont, lineSpacing: 1.5, onRangeSelected: onRangeSelected)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
        .background {
            // Brief highlight on a point the AI just rewrote
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(AlineTheme.accentAmber.opacity(0.28))
                .opacity(rowKey != nil && flashedKey == rowKey ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: flashedKey)
                .allowsHitTesting(false)
        }
        .id(rowKey)
    }
}

extension EnvironmentValues {
    /// Resume point to highlight right after Apply to Resume
    @Entry var resumeFlashedKey: String? = nil
}

// MARK: - Editable Standard Template View
public struct EditableStandardTemplateView: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @AppStorage("userFullName") private var userFullName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""
    @AppStorage("userLinkedIn") private var userLinkedIn: String = ""
    @AppStorage("userGitHub") private var userGitHub: String = ""
    @AppStorage("userLocation") private var userLocation: String = ""

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Centered Name & Contact
            VStack(spacing: 4) {
                Text(userFullName)
                    .font(.system(size: 21, weight: .bold, design: .serif))
                    .foregroundColor(Color.black)
                    .resumeSelectable(userFullName, font: resumeUIFont(size: 21, isSerif: true, weight: .bold))

                let linkedInDisplay = userLinkedIn.isEmpty ? "linkedin.com/in/\(userFullName.lowercased().replacingOccurrences(of: " ", with: "-"))" : userLinkedIn
                let gitHubDisplay = userGitHub.isEmpty ? "github.com/\(userFullName.lowercased().components(separatedBy: " ").first ?? "user")-dev" : userGitHub
                let contactLine = "\(userPhone)  |  \(userEmail)  |  \(linkedInDisplay)  |  \(gitHubDisplay)"

                Text(contactLine)
                    .font(.system(size: 8.5, weight: .regular, design: .serif))
                    .foregroundColor(Color.black.opacity(0.85))
                    .resumeSelectable(contactLine, font: resumeUIFont(size: 8.5, isSerif: true))
            }
            .resumeSection(.header)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 2)

            // Section: EDUCATION
            VStack(alignment: .leading, spacing: 4) {
                Text("EDUCATION")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.black)
                    .resumeSelectable("EDUCATION", font: resumeUIFont(size: 10.5, isSerif: true, weight: .bold))
                Rectangle().fill(Color.black).frame(height: 0.6)

                VStack(alignment: .leading, spacing: 5) {
                    if !viewModel.activeResume.education.isEmpty {
                        ForEach(viewModel.activeResume.education) { edu in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(edu.institution)
                                        .font(.system(size: 9.5, weight: .bold, design: .serif))
                                        .resumeSelectable(edu.institution, font: resumeUIFont(size: 9.5, isSerif: true, weight: .bold))
                                    Spacer()
                                    if !edu.location.isEmpty {
                                        Text(edu.location)
                                            .font(.system(size: 9, design: .serif))
                                            .resumeSelectable(edu.location, font: resumeUIFont(size: 9, isSerif: true))
                                    }
                                }
                                HStack {
                                    Text(edu.degree)
                                        .font(.system(size: 9, design: .serif).italic())
                                        .resumeSelectable(edu.degree, font: resumeUIFont(size: 9, isSerif: true, italic: true))
                                    Spacer()
                                    if !edu.period.isEmpty {
                                        Text(edu.period)
                                            .font(.system(size: 9, design: .serif).italic())
                                            .resumeSelectable(edu.period, font: resumeUIFont(size: 9, isSerif: true, italic: true))
                                    }
                                }
                                if !edu.details.isEmpty {
                                    Text(edu.details)
                                        .font(.system(size: 8.5, design: .serif))
                                        .foregroundColor(Color.black.opacity(0.8))
                                        .resumeSelectable(edu.details, font: resumeUIFont(size: 8.5, isSerif: true))
                                }
                            }
                        }
                    } else {
                        // No education on this resume: the section stays empty
                        EmptyView()
                    }
                }
            }
            .resumeSection(.education)

            // Section: PROFESSIONAL SUMMARY (if present)
            if !viewModel.activeResume.summary.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PROFESSIONAL SUMMARY")
                        .font(.system(size: 10.5, weight: .bold, design: .serif))
                        .foregroundColor(Color.black)
                        .resumeSelectable("PROFESSIONAL SUMMARY", font: resumeUIFont(size: 10.5, isSerif: true, weight: .bold))
                    Rectangle().fill(Color.black).frame(height: 0.6)

                    SelectableTextRow(
                        text: viewModel.activeResume.summary,
                        hasBullet: false,
                        font: .system(size: 8.5, design: .serif),
                        uiFont: resumeUIFont(size: 8.5, isSerif: true),
                        textColor: Color.black.opacity(0.85),
                        uiTextColor: .black,
                        rowKey: "summary",
                        isSelected: viewModel.selectedSnippetTargetKey == "summary",
                        onRangeSelected: { rangeText in
                            viewModel.selectTextForAI(key: "summary", text: rangeText)
                        },
                        onSelect: {
                            toggleSnippet(key: "summary", text: viewModel.activeResume.summary)
                        },
                        onEditWithAI: {
                            viewModel.openAIPanel()
                        }
                    )
                }
                .resumeSection(.summary)
            }

            // Section: EXPERIENCE
            VStack(alignment: .leading, spacing: 4) {
                Text("EXPERIENCE")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.black)
                    .resumeSelectable("EXPERIENCE", font: resumeUIFont(size: 10.5, isSerif: true, weight: .bold))
                Rectangle().fill(Color.black).frame(height: 0.6)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(viewModel.activeResume.experiences.enumerated()), id: \.element.id) { expIdx, exp in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(exp.role)
                                    .font(.system(size: 9.5, weight: .bold, design: .serif))
                                    .resumeSelectable(exp.role, font: resumeUIFont(size: 9.5, isSerif: true, weight: .bold))
                                Spacer()
                                Text(exp.period)
                                    .font(.system(size: 9, design: .serif))
                                    .resumeSelectable(exp.period, font: resumeUIFont(size: 9, isSerif: true))
                            }
                            HStack {
                                Text(exp.company)
                                    .font(.system(size: 9, design: .serif).italic())
                                    .resumeSelectable(exp.company, font: resumeUIFont(size: 9, isSerif: true, italic: true))
                                Spacer()
                                if !exp.location.isEmpty {
                                    Text(exp.location)
                                        .font(.system(size: 9, design: .serif).italic())
                                        .resumeSelectable(exp.location, font: resumeUIFont(size: 9, isSerif: true, italic: true))
                                }
                            }
                            ForEach(Array(exp.bullets.enumerated()), id: \.offset) { bIdx, bullet in
                                let key = "exp-\(expIdx)-bullet-\(bIdx)"
                                SelectableTextRow(
                                    text: bullet,
                                    hasBullet: true,
                                    bulletSymbol: "•",
                                    font: .system(size: 8.5, design: .serif),
                                    uiFont: resumeUIFont(size: 8.5, isSerif: true),
                                    textColor: Color.black,
                                    uiTextColor: .black,
                                    rowKey: key,
                                    isSelected: viewModel.selectedSnippetTargetKey == key,
                                    onRangeSelected: { rangeText in
                                        viewModel.selectTextForAI(key: key, text: rangeText)
                                    },
                                    onSelect: {
                                        toggleSnippet(key: key, text: bullet)
                                    },
                                    onEditWithAI: {
                                        viewModel.openAIPanel()
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .resumeSection(.experience)

            // Section: PROJECTS
            VStack(alignment: .leading, spacing: 4) {
                Text("PROJECTS")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.black)
                    .resumeSelectable("PROJECTS", font: resumeUIFont(size: 10.5, isSerif: true, weight: .bold))
                Rectangle().fill(Color.black).frame(height: 0.6)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(viewModel.activeResume.projects.enumerated()), id: \.element.id) { projIdx, proj in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline) {
                                HStack(spacing: 4) {
                                    Text(proj.title)
                                        .font(.system(size: 9.5, weight: .bold, design: .serif))
                                        .resumeSelectable(proj.title, font: resumeUIFont(size: 9.5, isSerif: true, weight: .bold))
                                    Text("|")
                                        .font(.system(size: 9, design: .serif))
                                        .resumeSelectable("|", font: resumeUIFont(size: 9, isSerif: true))
                                    Text(proj.techStack)
                                        .font(.system(size: 8.5, design: .serif).italic())
                                        .foregroundColor(Color.black.opacity(0.85))
                                        .resumeSelectable(proj.techStack, font: resumeUIFont(size: 8.5, isSerif: true, italic: true))
                                }
                                Spacer()
                                Text("GitHub")
                                    .font(.system(size: 8.5, weight: .medium, design: .serif).italic())
                                    .underline()
                                    .resumeSelectable("GitHub", font: resumeUIFont(size: 8.5, isSerif: true, weight: .medium, italic: true))
                            }
                            ForEach(Array(proj.bullets.enumerated()), id: \.offset) { bIdx, bullet in
                                let key = "proj-\(projIdx)-bullet-\(bIdx)"
                                SelectableTextRow(
                                    text: bullet,
                                    hasBullet: true,
                                    bulletSymbol: "•",
                                    font: .system(size: 8.5, design: .serif),
                                    uiFont: resumeUIFont(size: 8.5, isSerif: true),
                                    textColor: Color.black,
                                    uiTextColor: .black,
                                    rowKey: key,
                                    isSelected: viewModel.selectedSnippetTargetKey == key,
                                    onRangeSelected: { rangeText in
                                        viewModel.selectTextForAI(key: key, text: rangeText)
                                    },
                                    onSelect: {
                                        toggleSnippet(key: key, text: bullet)
                                    },
                                    onEditWithAI: {
                                        viewModel.openAIPanel()
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .resumeSection(.projects)

            // Section: ACHIEVEMENTS & CERTIFICATIONS
            if !viewModel.activeResume.achievements.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACHIEVEMENTS & CERTIFICATIONS")
                        .font(.system(size: 10.5, weight: .bold, design: .serif))
                        .foregroundColor(Color.black)
                        .resumeSelectable("ACHIEVEMENTS & CERTIFICATIONS", font: resumeUIFont(size: 10.5, isSerif: true, weight: .bold))
                    Rectangle().fill(Color.black).frame(height: 0.6)

                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(Array(viewModel.activeResume.achievements.enumerated()), id: \.offset) { achIdx, ach in
                            let key = "ach-\(achIdx)"
                            SelectableTextRow(
                                text: ach,
                                hasBullet: true,
                                bulletSymbol: "•",
                                font: .system(size: 8.5, design: .serif),
                                uiFont: resumeUIFont(size: 8.5, isSerif: true),
                                textColor: Color.black,
                                uiTextColor: .black,
                                rowKey: key,
                                isSelected: viewModel.selectedSnippetTargetKey == key,
                                onRangeSelected: { rangeText in
                                    viewModel.selectTextForAI(key: key, text: rangeText)
                                },
                                onSelect: {
                                    toggleSnippet(key: key, text: ach)
                                },
                                onEditWithAI: {
                                    viewModel.openAIPanel()
                                }
                            )
                        }
                    }
                }
                .resumeSection(.achievements)
            }

            // Section: TECHNICAL SKILLS
            VStack(alignment: .leading, spacing: 4) {
                Text("TECHNICAL SKILLS")
                    .font(.system(size: 10.5, weight: .bold, design: .serif))
                    .foregroundColor(Color.black)
                    .resumeSelectable("TECHNICAL SKILLS", font: resumeUIFont(size: 10.5, isSerif: true, weight: .bold))
                Rectangle().fill(Color.black).frame(height: 0.6)

                // The resume's own skill rows when it has them, otherwise the template's defaults
                Group {
                    if let lines = viewModel.activeResume.skillLines {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(lines, id: \.self) { line in
                                Text("\(Text("• \(line.label): ").bold())\(Text(line.values))")
                                    .font(.system(size: 8.5, design: .serif))
                                    .resumeSelectable("• \(line.label): \(line.values)", font: resumeUIFont(size: 8.5, isSerif: true), boldPrefix: "• \(line.label): ")
                            }
                        }
                    } else {
                        // No grouped skill rows: list the resume's skills as one line
                        if !viewModel.activeResume.skills.isEmpty {
                            Text(viewModel.activeResume.skills.joined(separator: ", "))
                                .font(.system(size: 8.5, design: .serif))
                                .resumeSelectable(viewModel.activeResume.skills.joined(separator: ", "), font: resumeUIFont(size: 8.5, isSerif: true))
                        }
                    }
                }
            }
            .resumeSection(.skills)

            // Section: SOFT SKILLS (only on resumes that list them)
            if let softSkills = viewModel.activeResume.softSkills {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SOFT SKILLS")
                        .font(.system(size: 10.5, weight: .bold, design: .serif))
                        .foregroundColor(Color.black)
                        .resumeSelectable("SOFT SKILLS", font: resumeUIFont(size: 10.5, isSerif: true, weight: .bold))
                    Rectangle().fill(Color.black).frame(height: 0.6)
                    Text(softSkills.joined(separator: " · "))
                        .font(.system(size: 8.5, design: .serif))
                        .resumeSelectable(softSkills.joined(separator: " · "), font: resumeUIFont(size: 8.5, isSerif: true))
                }
                .resumeSection(.softSkills)
            }
        }
        .foregroundColor(Color.black)
    }

    private func toggleSnippet(key: String, text: String) {
        if viewModel.selectedSnippetTargetKey == key {
            viewModel.selectedSnippetTargetKey = nil
            viewModel.selectedSnippetText = ""
        } else {
            viewModel.selectTextForAI(key: key, text: text)
        }
    }
}

// MARK: - Editable Professional Template View (Two-Column Dark Slate Sidebar / Jason Reed Style)
public struct EditableProfessionalTemplateView: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @AppStorage("userFullName") private var userFullName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""
    @AppStorage("userLinkedIn") private var userLinkedIn: String = ""
    @AppStorage("userLocation") private var userLocation: String = ""

    private let sidebarBg = Color(red: 0.12, green: 0.20, blue: 0.29)
    private let textBlue = Color(red: 0.11, green: 0.46, blue: 0.86)

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // LEFT SIDEBAR (Dark Navy/Slate)
            VStack(alignment: .leading, spacing: 14) {
                // Name at top
                VStack(alignment: .leading, spacing: 3) {
                    Text(userFullName.uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .tracking(0.5)
                        .resumeSelectable(userFullName.uppercased(), font: resumeUIFont(size: 14, weight: .black))
                }
                .resumeSection(.header)
                .padding(.top, 14)

                // Section: KEY ACHIEVEMENTS (the resume's own achievements; hidden when it has none)
                if !viewModel.activeResume.achievements.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("KEY ACHIEVEMENTS")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(0.5)
                            .resumeSelectable("KEY ACHIEVEMENTS", font: resumeUIFont(size: 8.5, weight: .bold))
                        Rectangle().fill(Color.white.opacity(0.35)).frame(height: 0.6)
                    }

                    ForEach(Array(viewModel.activeResume.achievements.prefix(4).enumerated()), id: \.offset) { _, achievement in
                        let parts = achievement.components(separatedBy: " — ")
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .top, spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 7.5))
                                    .foregroundColor(.yellow)
                                Text(parts[0])
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .resumeSelectable(parts[0], font: resumeUIFont(size: 8, weight: .bold))
                            }
                            if parts.count > 1 {
                                Text(parts.dropFirst().joined(separator: " — "))
                                    .font(.system(size: 7.2))
                                    .foregroundColor(Color.white.opacity(0.8))
                                    .lineSpacing(1.2)
                            }
                        }
                    }
                }
                .resumeSection(.header)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 14)
            .frame(width: 124)
            .background(sidebarBg)

            // RIGHT MAIN CONTENT (Clean White)
            VStack(alignment: .leading, spacing: 11) {
                // Header Headline & Contact
                VStack(alignment: .leading, spacing: 3) {
                    Text("AI/ML Intern | Full-Stack & Systems Software Engineer")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(textBlue)
                        .resumeSelectable("AI/ML Intern | Full-Stack & Systems Software Engineer", font: resumeUIFont(size: 9.5, weight: .bold))

                    HStack(spacing: 5) {
                        HStack(spacing: 2) {
                            Text("@")
                                .font(.system(size: 7.2, weight: .bold))
                                .resumeSelectable("@", font: resumeUIFont(size: 7.2, weight: .bold))
                            Text(userEmail)
                                .font(.system(size: 6.8))
                                .resumeSelectable(userEmail, font: resumeUIFont(size: 6.8))
                        }
                        Text("•")
                            .font(.system(size: 6.8))
                            .resumeSelectable("•", font: resumeUIFont(size: 6.8))
                        HStack(spacing: 2) {
                            Image(systemName: "link")
                                .font(.system(size: 6.5))
                            let lIn = userLinkedIn.isEmpty ? "linkedin.com/in/\(userFullName.lowercased().replacingOccurrences(of: " ", with: "-"))" : userLinkedIn
                            Text(lIn)
                                .font(.system(size: 6.8))
                                .resumeSelectable(lIn, font: resumeUIFont(size: 6.8))
                        }
                        Text("•")
                            .font(.system(size: 6.8))
                            .resumeSelectable("•", font: resumeUIFont(size: 6.8))
                        HStack(spacing: 2) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 6.5))
                            let loc = userLocation
                            Text(loc)
                                .font(.system(size: 6.8))
                                .resumeSelectable(loc, font: resumeUIFont(size: 6.8))
                        }
                    }
                    .foregroundColor(Color.gray)
                }
                .resumeSection(.header)
                .padding(.top, 14)

                // Section: SUMMARY
                VStack(alignment: .leading, spacing: 3) {
                    Text("SUMMARY")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color.gray)
                        .tracking(0.5)
                        .resumeSelectable("SUMMARY", font: resumeUIFont(size: 8.5, weight: .bold))
                    Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)

                    SelectableTextRow(
                        text: viewModel.activeResume.summary,
                        hasBullet: false,
                        font: .system(size: 7.5),
                        uiFont: resumeUIFont(size: 7.5),
                        textColor: Color.black.opacity(0.85),
                        uiTextColor: .black,
                        rowKey: "summary",
                        isSelected: viewModel.selectedSnippetTargetKey == "summary",
                        onRangeSelected: { rangeText in
                            viewModel.selectTextForAI(key: "summary", text: rangeText)
                        },
                        onSelect: {
                            toggleSnippet(key: "summary", text: viewModel.activeResume.summary)
                        },
                        onEditWithAI: {
                            viewModel.openAIPanel()
                        }
                    )
                }
                .resumeSection(.summary)

                // Section: EXPERIENCE
                VStack(alignment: .leading, spacing: 6) {
                    Text("EXPERIENCE")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color.gray)
                        .tracking(0.5)
                        .resumeSelectable("EXPERIENCE", font: resumeUIFont(size: 8.5, weight: .bold))
                    Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)

                    ForEach(Array(viewModel.activeResume.experiences.enumerated()), id: \.element.id) { expIdx, exp in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(exp.role)
                                    .font(.system(size: 8.2, weight: .bold))
                                    .foregroundColor(Color.black)
                                    .resumeSelectable(exp.role, font: resumeUIFont(size: 8.2, weight: .bold))
                                Spacer()
                                Text(exp.period)
                                    .font(.system(size: 7.2))
                                    .foregroundColor(Color.gray)
                                    .resumeSelectable(exp.period, font: resumeUIFont(size: 7.2))
                            }
                            HStack {
                                Text(exp.company)
                                    .font(.system(size: 7.8, weight: .bold))
                                    .foregroundColor(textBlue)
                                    .resumeSelectable(exp.company, font: resumeUIFont(size: 7.8, weight: .bold))
                                Spacer()
                                if !exp.location.isEmpty {
                                    Text(exp.location)
                                        .font(.system(size: 7.2))
                                        .foregroundColor(Color.gray)
                                        .resumeSelectable(exp.location, font: resumeUIFont(size: 7.2))
                                }
                            }
                            ForEach(Array(exp.bullets.enumerated()), id: \.offset) { bIdx, bullet in
                                let key = "exp-\(expIdx)-bullet-\(bIdx)"
                                SelectableTextRow(
                                    text: bullet,
                                    hasBullet: true,
                                    bulletSymbol: "•",
                                    font: .system(size: 7.2),
                                    uiFont: resumeUIFont(size: 7.2),
                                    textColor: Color.black.opacity(0.85),
                                    uiTextColor: .black,
                                    rowKey: key,
                                    isSelected: viewModel.selectedSnippetTargetKey == key,
                                    onRangeSelected: { rangeText in
                                        viewModel.selectTextForAI(key: key, text: rangeText)
                                    },
                                    onSelect: {
                                        toggleSnippet(key: key, text: bullet)
                                    },
                                    onEditWithAI: {
                                        viewModel.openAIPanel()
                                    }
                                )
                            }
                        }
                    }
                }
                .resumeSection(.experience)

                // Section: PROJECTS
                VStack(alignment: .leading, spacing: 6) {
                    Text("PROJECTS")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color.gray)
                        .tracking(0.5)
                        .resumeSelectable("PROJECTS", font: resumeUIFont(size: 8.5, weight: .bold))
                    Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)

                    ForEach(Array(viewModel.activeResume.projects.enumerated()), id: \.element.id) { projIdx, proj in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(proj.title)
                                    .font(.system(size: 8.2, weight: .bold))
                                    .foregroundColor(Color.black)
                                    .resumeSelectable(proj.title, font: resumeUIFont(size: 8.2, weight: .bold))
                                Spacer()
                                Text("GitHub")
                                    .font(.system(size: 7.2, weight: .bold))
                                    .foregroundColor(textBlue)
                                    .resumeSelectable("GitHub", font: resumeUIFont(size: 7.2, weight: .bold))
                            }
                            Text(proj.techStack)
                                .font(.system(size: 7.2, weight: .medium))
                                .foregroundColor(Color.gray)
                                .resumeSelectable(proj.techStack, font: resumeUIFont(size: 7.2, weight: .medium))

                            ForEach(Array(proj.bullets.enumerated()), id: \.offset) { bIdx, bullet in
                                let key = "proj-\(projIdx)-bullet-\(bIdx)"
                                SelectableTextRow(
                                    text: bullet,
                                    hasBullet: true,
                                    bulletSymbol: "•",
                                    font: .system(size: 7.2),
                                    uiFont: resumeUIFont(size: 7.2),
                                    textColor: Color.black.opacity(0.85),
                                    uiTextColor: .black,
                                    rowKey: key,
                                    isSelected: viewModel.selectedSnippetTargetKey == key,
                                    onRangeSelected: { rangeText in
                                        viewModel.selectTextForAI(key: key, text: rangeText)
                                    },
                                    onSelect: {
                                        toggleSnippet(key: key, text: bullet)
                                    },
                                    onEditWithAI: {
                                        viewModel.openAIPanel()
                                    }
                                )
                            }
                        }
                    }
                }
                .resumeSection(.projects)

                // Section: SKILLS
                VStack(alignment: .leading, spacing: 3) {
                    Text("SKILLS")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color.gray)
                        .tracking(0.5)
                        .resumeSelectable("SKILLS", font: resumeUIFont(size: 8.5, weight: .bold))
                    Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)

                    Text(viewModel.activeResume.skills.joined(separator: " · "))
                        .font(.system(size: 7.2))
                        .foregroundColor(Color.black.opacity(0.85))
                        .lineSpacing(1.3)
                        .resumeSelectable(viewModel.activeResume.skills.joined(separator: " · "), font: resumeUIFont(size: 7.2))
                }
                .resumeSection(.skills)

                // Section: SOFT SKILLS (only on resumes that list them)
                if let softSkills = viewModel.activeResume.softSkills {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("SOFT SKILLS")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(Color.gray)
                            .tracking(0.5)
                            .resumeSelectable("SOFT SKILLS", font: resumeUIFont(size: 8.5, weight: .bold))
                        Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)
                        Text(softSkills.joined(separator: " · "))
                            .font(.system(size: 7.2))
                            .foregroundColor(Color.black.opacity(0.85))
                            .resumeSelectable(softSkills.joined(separator: " · "), font: resumeUIFont(size: 7.2))
                    }
                    .resumeSection(.softSkills)
                }

                // Section: EDUCATION
                VStack(alignment: .leading, spacing: 4) {
                    Text("EDUCATION")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color.gray)
                        .tracking(0.5)
                        .resumeSelectable("EDUCATION", font: resumeUIFont(size: 8.5, weight: .bold))
                    Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 0.5)

                    if !viewModel.activeResume.education.isEmpty {
                        ForEach(viewModel.activeResume.education) { edu in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(edu.degree)
                                        .font(.system(size: 7.8, weight: .bold))
                                        .foregroundColor(Color.black)
                                        .resumeSelectable(edu.degree, font: resumeUIFont(size: 7.8, weight: .bold))
                                    Spacer()
                                    if !edu.period.isEmpty {
                                        Text(edu.period)
                                            .font(.system(size: 7.2))
                                            .foregroundColor(Color.gray)
                                            .resumeSelectable(edu.period, font: resumeUIFont(size: 7.2))
                                    }
                                }
                                HStack {
                                    Text(edu.institution)
                                        .font(.system(size: 7.5, weight: .bold))
                                        .foregroundColor(textBlue)
                                        .resumeSelectable(edu.institution, font: resumeUIFont(size: 7.5, weight: .bold))
                                    Spacer()
                                    if !edu.location.isEmpty {
                                        Text(edu.location)
                                            .font(.system(size: 7.2))
                                            .foregroundColor(Color.gray)
                                            .resumeSelectable(edu.location, font: resumeUIFont(size: 7.2))
                                    }
                                }
                                if !edu.details.isEmpty {
                                    Text(edu.details)
                                        .font(.system(size: 6.8))
                                        .foregroundColor(Color.gray)
                                        .resumeSelectable(edu.details, font: resumeUIFont(size: 6.8))
                                }
                            }
                        }
                    } else {
                        // No education on this resume: the section stays empty
                        EmptyView()
                    }
                }
                .resumeSection(.education)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 14)
        }
    }

    private func toggleSnippet(key: String, text: String) {
        if viewModel.selectedSnippetTargetKey == key {
            viewModel.selectedSnippetTargetKey = nil
            viewModel.selectedSnippetText = ""
        } else {
            viewModel.selectTextForAI(key: key, text: text)
        }
    }
}

// MARK: - Editable Modern Template View (Contemporary Blue Accent / Photo Header Style)
public struct EditableModernTemplateView: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @AppStorage("userFullName") private var userFullName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""
    @AppStorage("userLinkedIn") private var userLinkedIn: String = ""
    @AppStorage("userGitHub") private var userGitHub: String = ""
    @AppStorage("userLocation") private var userLocation: String = ""

    private let headerBlue = Color(red: 0.11, green: 0.44, blue: 0.72)

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Name, Contact Icons, and Photo on the right
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(userFullName)
                        .font(.system(size: 21, weight: .bold, design: .default))
                        .foregroundColor(headerBlue)
                        .resumeSelectable(userFullName, font: resumeUIFont(size: 21, weight: .bold))

                    let locDisplay = userLocation
                    let linkedInDisplay = userLinkedIn.isEmpty ? "linkedin.com/in/\(userFullName.lowercased().replacingOccurrences(of: " ", with: "-"))" : userLinkedIn
                    let gitHubDisplay = userGitHub.isEmpty ? "github.com/\(userFullName.lowercased().components(separatedBy: " ").first ?? "user")-dev" : userGitHub

                    HStack(spacing: 8) {
                        Label {
                            Text(locDisplay)
                                .resumeSelectable(locDisplay, font: resumeUIFont(size: 7.5, weight: .medium))
                        } icon: {
                            Image(systemName: "mappin.circle.fill")
                        }
                        Label {
                            Text(userPhone)
                                .resumeSelectable(userPhone, font: resumeUIFont(size: 7.5, weight: .medium))
                        } icon: {
                            Image(systemName: "phone.fill")
                        }
                        Label {
                            Text(userEmail)
                                .resumeSelectable(userEmail, font: resumeUIFont(size: 7.5, weight: .medium))
                        } icon: {
                            Image(systemName: "envelope.fill")
                        }
                    }
                    .font(.system(size: 7.5, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.75))

                    HStack(spacing: 8) {
                        Label {
                            Text(linkedInDisplay)
                                .resumeSelectable(linkedInDisplay, font: resumeUIFont(size: 7.5, weight: .medium))
                        } icon: {
                            Image(systemName: "link")
                        }
                        Label {
                            Text(gitHubDisplay)
                                .resumeSelectable(gitHubDisplay, font: resumeUIFont(size: 7.5, weight: .medium))
                        } icon: {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                        }
                    }
                    .font(.system(size: 7.5, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.75))
                }

                Spacer()

                // Profile photo circle (clean placeholder / empty circle with subtle user icon)
                ZStack {
                    Circle()
                        .fill(AlineTheme.canvasBackground)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle().stroke(headerBlue.opacity(0.4), lineWidth: 1.5)
                        )
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(headerBlue.opacity(0.5))
                }
            }
            .resumeSection(.header)
            .padding(.bottom, 2)

            // Section: PROFESSIONAL SUMMARY
            VStack(alignment: .leading, spacing: 3) {
                Text("PROFESSIONAL SUMMARY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(headerBlue)
                    .resumeSelectable("PROFESSIONAL SUMMARY", font: resumeUIFont(size: 10, weight: .bold))
                Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                SelectableTextRow(
                    text: viewModel.activeResume.summary,
                    hasBullet: false,
                    font: .system(size: 8.5),
                    uiFont: resumeUIFont(size: 8.5),
                    textColor: Color.black.opacity(0.85),
                    uiTextColor: .black,
                    rowKey: "summary",
                    isSelected: viewModel.selectedSnippetTargetKey == "summary",
                    onRangeSelected: { rangeText in
                        viewModel.selectTextForAI(key: "summary", text: rangeText)
                    },
                    onSelect: {
                        toggleSnippet(key: "summary", text: viewModel.activeResume.summary)
                    },
                    onEditWithAI: {
                        viewModel.openAIPanel()
                    }
                )
            }
            .resumeSection(.summary)

            // Section: TECHNICAL SKILLS
            VStack(alignment: .leading, spacing: 3) {
                Text("TECHNICAL SKILLS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(headerBlue)
                    .resumeSelectable("TECHNICAL SKILLS", font: resumeUIFont(size: 10, weight: .bold))
                Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                // The resume's own skill rows when it has them, otherwise the template's defaults
                Group {
                    if let lines = viewModel.activeResume.skillLines {
                        VStack(alignment: .leading, spacing: 2.5) {
                            ForEach(lines, id: \.self) { line in
                                Text("\(Text("• \(line.label): ").bold())\(Text(line.values))")
                                    .font(.system(size: 8.5))
                                    .resumeSelectable("• \(line.label): \(line.values)", font: resumeUIFont(size: 8.5), boldPrefix: "• \(line.label): ")
                            }
                        }
                    } else {
                        // No grouped skill rows: list the resume's skills as one line
                        if !viewModel.activeResume.skills.isEmpty {
                            Text(viewModel.activeResume.skills.joined(separator: ", "))
                                .font(.system(size: 8.5))
                                .resumeSelectable(viewModel.activeResume.skills.joined(separator: ", "), font: resumeUIFont(size: 8.5))
                        }
                    }
                }
                .foregroundColor(Color.black.opacity(0.85))
            }
            .resumeSection(.skills)

            // Section: SOFT SKILLS (only on resumes that list them)
            if let softSkills = viewModel.activeResume.softSkills {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SOFT SKILLS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(headerBlue)
                        .resumeSelectable("SOFT SKILLS", font: resumeUIFont(size: 10, weight: .bold))
                    Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)
                    Text(softSkills.joined(separator: " · "))
                        .font(.system(size: 8.5))
                        .resumeSelectable(softSkills.joined(separator: " · "), font: resumeUIFont(size: 8.5))
                }
                .resumeSection(.softSkills)
            }

            // Section: PROFESSIONAL EXPERIENCE
            VStack(alignment: .leading, spacing: 4) {
                Text("PROFESSIONAL EXPERIENCE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(headerBlue)
                    .resumeSelectable("PROFESSIONAL EXPERIENCE", font: resumeUIFont(size: 10, weight: .bold))
                Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(viewModel.activeResume.experiences.enumerated()), id: \.element.id) { expIdx, exp in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(exp.role)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color.black)
                                    .resumeSelectable(exp.role, font: resumeUIFont(size: 9, weight: .bold))
                                Spacer()
                                Text(exp.period)
                                    .font(.system(size: 8.5))
                                    .foregroundColor(Color.black.opacity(0.75))
                                    .resumeSelectable(exp.period, font: resumeUIFont(size: 8.5))
                            }
                            HStack {
                                Text(exp.company)
                                    .font(.system(size: 8.5).italic())
                                    .foregroundColor(Color.black.opacity(0.85))
                                    .resumeSelectable(exp.company, font: resumeUIFont(size: 8.5, italic: true))
                                Spacer()
                                if !exp.location.isEmpty {
                                    Text(exp.location)
                                        .font(.system(size: 8.5).italic())
                                        .foregroundColor(Color.black.opacity(0.75))
                                        .resumeSelectable(exp.location, font: resumeUIFont(size: 8.5, italic: true))
                                }
                            }
                            ForEach(Array(exp.bullets.enumerated()), id: \.offset) { bIdx, bullet in
                                let key = "exp-\(expIdx)-bullet-\(bIdx)"
                                SelectableTextRow(
                                    text: bullet,
                                    hasBullet: true,
                                    bulletSymbol: "•",
                                    font: .system(size: 8.5),
                                    uiFont: resumeUIFont(size: 8.5),
                                    textColor: Color.black.opacity(0.85),
                                    uiTextColor: .black,
                                    rowKey: key,
                                    isSelected: viewModel.selectedSnippetTargetKey == key,
                                    onRangeSelected: { rangeText in
                                        viewModel.selectTextForAI(key: key, text: rangeText)
                                    },
                                    onSelect: {
                                        toggleSnippet(key: key, text: bullet)
                                    },
                                    onEditWithAI: {
                                        viewModel.openAIPanel()
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .resumeSection(.experience)

            // Section: KEY PROJECTS
            VStack(alignment: .leading, spacing: 4) {
                Text("KEY PROJECTS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(headerBlue)
                    .resumeSelectable("KEY PROJECTS", font: resumeUIFont(size: 10, weight: .bold))
                Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(viewModel.activeResume.projects.enumerated()), id: \.element.id) { projIdx, proj in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                HStack(spacing: 4) {
                                    Text(proj.title)
                                        .font(.system(size: 9, weight: .bold))
                                        .resumeSelectable(proj.title, font: resumeUIFont(size: 9, weight: .bold))
                                    Text("|")
                                        .font(.system(size: 8.5))
                                        .resumeSelectable("|", font: resumeUIFont(size: 8.5))
                                    Text(proj.techStack)
                                        .font(.system(size: 8.5).italic())
                                        .foregroundColor(Color.black.opacity(0.75))
                                        .resumeSelectable(proj.techStack, font: resumeUIFont(size: 8.5, italic: true))
                                }
                                Spacer()
                                Text("GitHub")
                                    .font(.system(size: 8.5, weight: .medium).italic())
                                    .foregroundColor(headerBlue)
                                    .underline()
                                    .resumeSelectable("GitHub", font: resumeUIFont(size: 8.5, weight: .medium, italic: true))
                            }
                            ForEach(Array(proj.bullets.enumerated()), id: \.offset) { bIdx, bullet in
                                let key = "proj-\(projIdx)-bullet-\(bIdx)"
                                SelectableTextRow(
                                    text: bullet,
                                    hasBullet: true,
                                    bulletSymbol: "•",
                                    font: .system(size: 8.5),
                                    uiFont: resumeUIFont(size: 8.5),
                                    textColor: Color.black.opacity(0.85),
                                    uiTextColor: .black,
                                    rowKey: key,
                                    isSelected: viewModel.selectedSnippetTargetKey == key,
                                    onRangeSelected: { rangeText in
                                        viewModel.selectTextForAI(key: key, text: rangeText)
                                    },
                                    onSelect: {
                                        toggleSnippet(key: key, text: bullet)
                                    },
                                    onEditWithAI: {
                                        viewModel.openAIPanel()
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .resumeSection(.projects)

            // Section: EDUCATION
            VStack(alignment: .leading, spacing: 4) {
                Text("EDUCATION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(headerBlue)
                    .resumeSelectable("EDUCATION", font: resumeUIFont(size: 10, weight: .bold))
                Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                VStack(alignment: .leading, spacing: 4) {
                    if !viewModel.activeResume.education.isEmpty {
                        ForEach(viewModel.activeResume.education) { edu in
                            VStack(alignment: .leading, spacing: 1) {
                                HStack {
                                    Text(edu.institution)
                                        .font(.system(size: 9, weight: .bold))
                                        .resumeSelectable(edu.institution, font: resumeUIFont(size: 9, weight: .bold))
                                    Spacer()
                                    if !edu.period.isEmpty {
                                        Text(edu.period)
                                            .font(.system(size: 8.5))
                                            .resumeSelectable(edu.period, font: resumeUIFont(size: 8.5))
                                    }
                                }
                                HStack {
                                    Text(edu.degree)
                                        .font(.system(size: 8.5).italic())
                                        .resumeSelectable(edu.degree, font: resumeUIFont(size: 8.5, italic: true))
                                    Spacer()
                                    if !edu.location.isEmpty {
                                        Text(edu.location)
                                            .font(.system(size: 8.5).italic())
                                            .resumeSelectable(edu.location, font: resumeUIFont(size: 8.5, italic: true))
                                    }
                                }
                                if !edu.details.isEmpty {
                                    Text(edu.details)
                                        .font(.system(size: 8))
                                        .foregroundColor(Color.black.opacity(0.75))
                                        .resumeSelectable(edu.details, font: resumeUIFont(size: 8))
                                }
                            }
                        }
                    } else {
                        // No education on this resume: the section stays empty
                        EmptyView()
                    }
                }
                .foregroundColor(Color.black.opacity(0.85))
            }
            .resumeSection(.education)

            // Section: ACHIEVEMENTS & CERTIFICATIONS
            if !viewModel.activeResume.achievements.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACHIEVEMENTS & CERTIFICATIONS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(headerBlue)
                        .resumeSelectable("ACHIEVEMENTS & CERTIFICATIONS", font: resumeUIFont(size: 10, weight: .bold))
                    Rectangle().fill(headerBlue.opacity(0.45)).frame(height: 1)

                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(Array(viewModel.activeResume.achievements.enumerated()), id: \.offset) { achIdx, ach in
                            let key = "ach-\(achIdx)"
                            SelectableTextRow(
                                text: ach,
                                hasBullet: true,
                                bulletSymbol: "•",
                                font: .system(size: 8.5),
                                uiFont: resumeUIFont(size: 8.5),
                                textColor: Color.black.opacity(0.85),
                                uiTextColor: .black,
                                rowKey: key,
                                isSelected: viewModel.selectedSnippetTargetKey == key,
                                onRangeSelected: { rangeText in
                                    viewModel.selectTextForAI(key: key, text: rangeText)
                                },
                                onSelect: {
                                    toggleSnippet(key: key, text: ach)
                                },
                                onEditWithAI: {
                                    viewModel.openAIPanel()
                                }
                            )
                        }
                    }
                }
                .resumeSection(.achievements)
            }
        }
    }

    private func toggleSnippet(key: String, text: String) {
        if viewModel.selectedSnippetTargetKey == key {
            viewModel.selectedSnippetTargetKey = nil
            viewModel.selectedSnippetText = ""
        } else {
            viewModel.selectTextForAI(key: key, text: text)
        }
    }
}

// MARK: - AI Assistant Drawer (Multi-Turn Chat History Until Saved)
public struct AIAssistantDrawer: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        ZStack {
            // Colorful app background (same artwork as Discover & the editor)
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header: Cross Button, Centered Title with Session Caption & Save
                ZStack {
                    VStack(spacing: 2) {
                        Text("Edit with AI")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("Session chat: changes remain until you save")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(AlineTheme.inkSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // Keep clear of the buttons on either side
                    .padding(.horizontal, 82)

                    HStack {
                        AlineCloseButton { dismiss() }

                        Spacer()

                        // Save Button (commits & clears the chat)
                        Button {
                            withAnimation {
                                viewModel.saveDocumentChanges()
                            }
                        } label: {
                            Text("Save")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .fixedSize()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .alineGlassCapsule(selected: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 6)

                // Chat Message Feed (Shows full chat until user saves)
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 14) {
                            if viewModel.sessionChatMessages.isEmpty {
                                // Empty state after saving
                                VStack(spacing: 12) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 30))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                    Text("Start a refinement")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                    Text("Select any text on your resume or enter a prompt below.")
                                        .font(.system(size: 12))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                }
                                .padding(.top, 40)
                                .padding(.bottom, 20)
                            } else {
                                ForEach(Array(viewModel.sessionChatMessages.enumerated()), id: \.element.id) { index, message in
                                    AIChatMessageRow(message: message, onApply: {
                                        // No crossfade: the new text swaps in and the row highlight shows the change
                                        viewModel.applyChatSuggestion(messageId: message.id)
                                    })
                                    .id(message.id)
                                }

                                if viewModel.isGeneratingAI {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .controlSize(.small)
                                        Text("Analyzing your resume…")
                                            .font(.system(size: 12.5, weight: .medium))
                                            .foregroundColor(AlineTheme.inkSecondary)
                                        Spacer()
                                    }
                                    .padding(.leading, 4)
                                    .id("aiTyping")
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
.scrollDismissesKeyboard(.interactively)
                    .onChange(of: viewModel.sessionChatMessages.count) { oldCount, newCount in
                        let messages = viewModel.sessionChatMessages
                        // Several replies at once (job tailoring): start reading from the first of them
                        if newCount - oldCount > 1, messages.indices.contains(oldCount) {
                            withAnimation {
                                proxy.scrollTo(messages[oldCount].id, anchor: .top)
                            }
                        } else if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Bottom Input Area: Composer
                VStack(alignment: .leading, spacing: 8) {
                    // Text picked in the resume rides along with the next message, like a quoted selection
                    selectionChip
                        .padding(.horizontal, 20)

                    // Prompt Input Field and Send Button
                    HStack(spacing: 8) {
                        TextField("Ask AI to change, improve, or quantify...", text: $viewModel.userAIInstruction)
.alineKeyboardDismissal(.done)
                            .font(.system(size: 14))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)

                        Button {
                            viewModel.requestAISuggestion()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(AlineTheme.pillDark)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
                                if viewModel.isGeneratingAI {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isGeneratingAI || (viewModel.userAIInstruction.trimmingCharacters(in: .whitespaces).isEmpty && viewModel.selectedSnippetText.isEmpty))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .padding(.top, 8)
            }
        }
        .presentationDetents([.medium, .large])
        // Keep the resume behind the half-height sheet scrollable
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }

    // Selection chip above the input: a short preview of the picked text, tagged "Selection"
    @ViewBuilder
    private var selectionChip: some View {
        if !viewModel.selectedSnippetText.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.selectedSnippetText)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Label("Selection", systemImage: "text.quote")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(AlineTheme.inkPrimary)
            }
            .padding(.leading, 14)
            .padding(.trailing, 30)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AlineTheme.borderSubtle, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                Button {
                    withAnimation(AlineTheme.fastSpring) {
                        viewModel.selectedSnippetText = ""
                        viewModel.selectedSnippetTargetKey = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove selection")
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

// MARK: - AI Chat Message Row View
public struct AIChatMessageRow: View {
    public let message: AIChatMessage
    public let onApply: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch message.sender {
            case .user:
                // User Prompt Bubble (Aligned Right)
                HStack {
                    Spacer()
                    Text(message.text)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(AlineTheme.pillDark)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

            case .system:
                // System notification (Centered Pill)
                HStack {
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                        Text(message.text)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(AlineTheme.inkPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .alineGlassCapsule(selected: false)
                    Spacer()
                }

            case .ai:
                // AI Response & Suggestion Card (Aligned Left)
                HStack(alignment: .top, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AlineTheme.pillDark)
                            .frame(width: 28, height: 28)
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(message.text)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AlineTheme.inkPrimary)

                        // If AI provided a proposed rewrite
                        if let rewrite = message.suggestedRewrite {
                            VStack(alignment: .leading, spacing: 8) {
                                if let reason = message.reason {
                                    HStack(alignment: .top, spacing: 4) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(AlineTheme.inkPrimary)
                                        Text(reason)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(AlineTheme.inkSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    // Job-tailoring suggestions say which resume point they rewrite
                                    if let original = message.originalText, !original.isEmpty {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("REPLACES THIS POINT")
                                                .font(.system(size: 9.5, weight: .heavy))
                                                .foregroundColor(AlineTheme.inkSecondary)
                                                .tracking(0.4)
                                            Text(original)
                                                .font(.system(size: 11.5, weight: .regular))
                                                .foregroundColor(AlineTheme.inkSecondary)
                                                .lineLimit(3)
                                        }
                                    }
                                }

                                Text(rewrite)
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .lineSpacing(2)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                // Apply Button
                                Button(action: onApply) {
                                    HStack(spacing: 6) {
                                        if message.isApplied {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Applied to Document")
                                        } else {
                                            Text("Apply to Resume")
                                        }
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(message.isApplied ? AlineTheme.inkSecondary : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .alineGlassCapsule(selected: !message.isApplied)
                                }
                                .buttonStyle(.plain)
                                .disabled(message.isApplied)
                            }
                            .padding(12)
                            .background(AlineTheme.canvasBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AlineTheme.borderSubtle, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Full Page Print Preview Screen (Shown Before Downloading)
public struct ResumeFullPrintPreviewScreen: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()

            VStack(spacing: 12) {
                // A4 pages fill the space above the button; swipe between pages, pinch to zoom
                ResumeA4SheetView(resume: viewModel.activeResume)

                Button {
                    viewModel.downloadResumePDF()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isDownloadingPDF {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.doc.fill")
                        }
                        Text(viewModel.isDownloadingPDF ? "Preparing PDF..." : "Download PDF")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .alineGlassCapsule(selected: true, tint: AlineTheme.pillDark)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isDownloadingPDF)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .navigationTitle("Final PDF Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Cancel: back to the main resume dashboard
                AlineCloseButton { viewModel.returnToResumeDashboard() }
                    .accessibilityLabel("Cancel")
            }
            // The cross draws its own glass circle; hide the toolbar's platter behind it
            .sharedBackgroundVisibility(.hidden)
        }
        .navigationDestination(isPresented: $viewModel.showDownloadConfirmation) {
            ResumeDownloadConfirmationScreen(viewModel: viewModel)
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Page Number Badge ("1/2" in a page's bottom-right corner)
struct ResumePageNumberBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(AlineTheme.inkSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(AlineTheme.canvasBackground))
            .padding(8)
            .allowsHitTesting(false)
    }
}

// MARK: - Page Sections (which resume sections a template draws, so each printed page gets its own share)
extension EnvironmentValues {
    /// Sections the template should draw for one printed page; nil draws them all
    @Entry var resumePageSections: Set<ResumeSection>? = nil
}

private struct ResumeSectionVisibility: ViewModifier {
    @Environment(\.resumePageSections) private var pageSections
    let section: ResumeSection

    func body(content: Content) -> some View {
        if pageSections?.contains(section) ?? true {
            content
        }
    }
}

extension View {
    /// Shows this section only on the page that holds it
    func resumeSection(_ section: ResumeSection) -> some View {
        modifier(ResumeSectionVisibility(section: section))
    }
}

// MARK: - Page Blocks (sections, entries and bullets a page break may fall above, never inside)
private struct ResumePageBlockKey: PreferenceKey {
    static let defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    /// Marks a block of resume content that should not be split across A4 pages
    func resumePageBlock() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ResumePageBlockKey.self,
                    value: [proxy.frame(in: .named(ResumeA4SheetView.measureSpace))]
                )
            }
        }
    }
}

// MARK: - A4 Pages (fixed 1 : √2 paper; each of the resume's pages fitted to a sheet, very long content split by height; pinch to zoom)
struct ResumeA4SheetView: View {
    let resume: ResumeDocument

    static let measureSpace = "resumeA4Measure"

    /// Width the templates were designed at; pages are laid out at this size, then scaled to the screen.
    private let baseWidth: CGFloat = 400
    private let aspect: CGFloat = 1.4142
    /// Top and bottom paper margin on every page
    private let pageMargin: CGFloat = 16
    /// A resume up to this many pages long is shrunk onto one sheet; longer documents get real pages
    private let maxPagesOnOneSheet: CGFloat = 3.2

    @State private var contentHeight: CGFloat = 0
    @State private var blocks: [CGRect] = []
    /// Per printed page: content height at the base width, at the first widened guess, and as rendered
    @State private var pageBaseHeights: [Int: CGFloat] = [:]
    @State private var pageWidenedHeights: [Int: CGFloat] = [:]
    @State private var pageRenderedHeights: [Int: CGFloat] = [:]
    @State private var currentPage: Int? = 0
    @State private var zoom: CGFloat = 1
    @State private var committedZoom: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var committedPan: CGSize = .zero

    private var baseHeight: CGFloat { baseWidth * aspect }
    /// Height of resume content that fits on one page between the margins
    private var sliceHeight: CGFloat { baseHeight - pageMargin * 2 }

    /// The resume's own pages (a two-page resume lists which sections go on page 2)
    private var sectionPages: [Set<ResumeSection>?] { resume.pageSections }

    /// Each of the resume's pages is fitted onto its own A4 sheet; only very long single-page
    /// content is split by height instead. The sidebar layout can never be split.
    private var fitsOnSheets: Bool {
        sectionPages.count > 1
            || resume.selectedTemplate == .professional
            || contentHeight <= sliceHeight * maxPagesOnOneSheet
    }

    /// Places a page may break: the top of a block that directly follows another block,
    /// so a heading never ends a page apart from the bullets under it
    private var breakPoints: [CGFloat] {
        let bottoms = blocks.map(\.maxY)
        return blocks.map(\.minY)
            .filter { top in bottoms.contains { $0 <= top && $0 >= top - 14 } }
            .sorted()
    }

    /// Content offset where each page starts; breaks go above the last block that still fits
    private var pageStarts: [CGFloat] {
        guard !fitsOnSheets, contentHeight > sliceHeight else { return [0] }
        let breakPoints = breakPoints
        var starts: [CGFloat] = [0]
        var start: CGFloat = 0
        while contentHeight - start > sliceHeight {
            let limit = start + sliceHeight
            let next = breakPoints.last { $0 > start + 1 && $0 <= limit } ?? limit
            starts.append(next)
            start = next
        }
        return starts
    }

    var body: some View {
        let starts = pageStarts
        let count = fitsOnSheets ? sectionPages.count : starts.count

        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { index in
                        let start = fitsOnSheets ? 0 : starts[index]
                        let end = index + 1 < starts.count ? starts[index + 1] : contentHeight
                        pageCard(index, count: count, start: start, length: end - start, available: proxy.size)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentPage)
            // While zoomed in, one-finger drags pan the page instead of flipping pages
            .scrollDisabled(committedZoom > 1)
            .simultaneousGesture(magnify)
            .gesture(panDrag, isEnabled: committedZoom > 1)
            .onTapGesture(count: 2) {
                withAnimation(AlineTheme.fastSpring) {
                    if committedZoom > 1 { resetZoom() } else { setZoom(2.5) }
                }
            }
            .onChange(of: currentPage) { resetZoom() }
        }
        .background(measurement)
    }

    /// Hidden layouts that decide where the pages break
    private var measurement: some View {
        ZStack(alignment: .topLeading) {
            pageContent(nil)
                .frame(width: baseWidth)
                .fixedSize(horizontal: false, vertical: true)
                .coordinateSpace(.named(Self.measureSpace))
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
                .backgroundPreferenceValue(ResumePageBlockKey.self) { frames in
                    Color.clear.onChange(of: frames, initial: true) {
                        blocks = frames
                    }
                }

            if fitsOnSheets {
                ForEach(sectionPages.indices, id: \.self) { index in
                    pageContent(sectionPages[index])
                        .frame(width: baseWidth)
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { pageBaseHeights[index] = $0 }
                    pageContent(sectionPages[index])
                        .frame(width: firstWidth)
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { pageWidenedHeights[index] = $0 }
                }
            }
        }
        .hidden()
        .allowsHitTesting(false)
    }

    /// One A4 page scaled to fit the space, with its page number in the bottom-right corner
    private func pageCard(_ index: Int, count: Int, start: CGFloat, length: CGFloat, available: CGSize) -> some View {
        let fitWidth = available.width - 20
        let fitHeight = available.height - 16
        let scale = max(min(fitWidth / baseWidth, fitHeight / baseHeight), 0.1)
        let isCurrent = index == (currentPage ?? 0)

        return page(index, start: start, length: length)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: baseWidth * scale, height: baseHeight * scale, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .overlay(alignment: .bottomTrailing) {
                ResumePageNumberBadge(label: "\(index + 1)/\(count)")
            }
            .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 8)
            .scaleEffect(isCurrent ? zoom : 1)
            .offset(isCurrent ? pan : .zero)
    }

    /// Page `index` on white A4 paper: one of the resume's own pages fitted to the sheet,
    /// or for very long content the slice from `start`
    @ViewBuilder
    private func page(_ index: Int, start: CGFloat, length: CGFloat) -> some View {
        Group {
            if fitsOnSheets {
                fittedPage(index)
            } else {
                pageContent(nil)
                    .frame(width: baseWidth)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: -start)
                    .frame(width: baseWidth, height: max(length, 0), alignment: .top)
                    .clipped()
                    .padding(.vertical, pageMargin)
                    .frame(width: baseWidth, height: baseHeight, alignment: .top)
            }
        }
        .background(Color.white)
    }

    /// Content is laid out wider and scaled down, so it shrinks evenly and still spans the sheet's width.
    /// Every page uses the same width, sized for the fullest page, so text is the same size throughout.
    /// First guess from the heights at the base width…
    private var firstWidth: CGFloat {
        let tallest = pageBaseHeights.values.max() ?? contentHeight
        guard tallest > sliceHeight else { return baseWidth }
        return baseWidth * (tallest / sliceHeight).squareRoot()
    }

    /// …then refined from the heights measured at that guess
    private var fitWidth: CGFloat {
        guard let tallest = pageWidenedHeights.values.max(), tallest > 0 else { return firstWidth }
        let scaledHeight = tallest * baseWidth / firstWidth
        guard scaledHeight > sliceHeight else { return firstWidth }
        return firstWidth * (scaledHeight / sliceHeight).squareRoot()
    }

    private func fittedPage(_ index: Int) -> some View {
        let shrink = baseWidth / fitWidth
        let rendered = pageRenderedHeights[index] ?? 0
        // Final squeeze for anything the widening didn't absorb
        let squeeze = rendered * shrink > sliceHeight ? sliceHeight / (rendered * shrink) : 1
        return pageContent(sectionPages[index])
            .frame(width: fitWidth)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { pageRenderedHeights[index] = $0 }
            .scaleEffect(shrink * squeeze, anchor: .top)
            .frame(width: baseWidth, height: sliceHeight, alignment: .top)
            .clipped()
            .padding(.vertical, pageMargin)
            .frame(width: baseWidth, height: baseHeight, alignment: .top)
    }

    private var magnify: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(max(committedZoom * value.magnification, 1), 4)
            }
            .onEnded { _ in
                withAnimation(AlineTheme.fastSpring) {
                    if zoom <= 1.05 { resetZoom() } else { setZoom(zoom) }
                }
            }
    }

    private var panDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                pan = CGSize(
                    width: committedPan.width + value.translation.width,
                    height: committedPan.height + value.translation.height
                )
            }
            .onEnded { _ in committedPan = pan }
    }

    private func setZoom(_ value: CGFloat) {
        zoom = value
        committedZoom = value
    }

    private func resetZoom() {
        setZoom(1)
        pan = .zero
        committedPan = .zero
    }

    /// Templates without their own top/bottom padding; the page margins supply it.
    /// `sections` limits the template to one of the resume's pages (nil draws everything).
    private func pageContent(_ sections: Set<ResumeSection>?) -> some View {
        Group {
            switch resume.selectedTemplate {
            case .standard:
                StandardTemplateView(resume: resume)
                    .padding(.horizontal, 14)
            case .professional:
                ProfessionalTemplateView(resume: resume)
            case .modern:
                ModernTemplateView(resume: resume)
                    .padding(.horizontal, 14)
            }
        }
        .environment(\.resumePageSections, sections)
    }
}

// MARK: - Download Confirmation Screen (Checkmark + Auto-Redirect)
public struct ResumeDownloadConfirmationScreen: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var countdown: Int = 3
    @State private var timer: Timer? = nil
    @State private var animateCheckmark: Bool = false

    // Same greens as the "93% Match" chips
    private static let mint = Color(red: 0.88, green: 0.96, blue: 0.90)
    private static let deepGreen = Color(red: 0.12, green: 0.58, blue: 0.30)

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()

            VStack(spacing: 24) {
                Spacer()

                // Animated checkmark in the app's own "match" greens (mint fill, deep green tick)
                ZStack {
                    Circle()
                        .fill(Self.mint.opacity(0.55))
                        .frame(width: 124, height: 124)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                        .opacity(animateCheckmark ? 1.0 : 0.0)

                    Circle()
                        .fill(Self.mint)
                        .frame(width: 88, height: 88)
                        .overlay(Circle().stroke(Self.deepGreen.opacity(0.25), lineWidth: 1.5))
                        .shadow(color: Self.deepGreen.opacity(0.18), radius: 14, x: 0, y: 6)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.3)
                        .opacity(animateCheckmark ? 1.0 : 0.0)

                    Image(systemName: "checkmark")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundColor(Self.deepGreen)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.0)
                }

                Text("PDF Downloaded")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .opacity(animateCheckmark ? 1.0 : 0.0)

                Text("Redirecting to dashboard in \(countdown)s...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .opacity(animateCheckmark ? 1.0 : 0.0)

                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            timer?.invalidate()
            timer = nil
            viewModel.returnToResumeDashboard()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateCheckmark = true
            }
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startCountdown() {
        // Back to the dashboard after 3 seconds
        countdown = 3
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer?.invalidate()
                timer = nil
                // Reset states and navigate back to dashboard
                Task { @MainActor in viewModel.returnToResumeDashboard() }
            }
        }
    }
}

// MARK: - Add Resume Options Sheet (Triggered by + button)
public struct AddResumeOptionsSheet: View {
    public let onAddResume: () -> Void
    public let onBuildFromProfile: () -> Void
    /// Building from the profile needs a filled-in profile; otherwise the sheet explains why not
    public var isProfileComplete: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var showProfileIncompleteAlert: Bool = false

    public var body: some View {
        NavigationStack {
            ZStack {
                AlineTheme.canvasBackground
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    // Header: cross button beside the title, matching the Discover filter sheet
                    HStack(alignment: .center, spacing: 12) {
                        AlineCloseButton { dismiss() }

                        Text("Add Resume")
                            .font(.system(size: 24, weight: .heavy, design: .default))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Options list
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CHOOSE AN OPTION")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AlineTheme.inkSecondary)
                            .tracking(0.6)

                        // Option 1: Add Resume (Upload file)
                        Button {
                            dismiss()
                            onAddResume()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AlineTheme.pillDark)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "arrow.up.doc.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Add Resume")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                    Text("Upload a PDF or DOCX file")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AlineTheme.inkSecondary.opacity(0.6))
                            }
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)

                        // Option 2: Build Resume from Profile (Requires complete profile)
                        Button {
                            if isProfileComplete {
                                dismiss()
                                onBuildFromProfile()
                            } else {
                                showProfileIncompleteAlert = true
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AlineTheme.pillDark)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "person.crop.rectangle.stack.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Build Resume from Profile")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                    Text("Generate from your Aline profile")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AlineTheme.inkSecondary.opacity(0.6))
                            }
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .alert("Complete Your Profile", isPresented: $showProfileIncompleteAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Building a resume from your profile requires 100% profile completion. Please complete your profile details first.")
            }
        }
        .presentationDetents([.fraction(0.38), .medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Resume Upload Modal (Plain background, circular xmark header)
public struct ResumeUploadModalView: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker: Bool = false

    public var body: some View {
        NavigationStack {
            ZStack {
                AlineTheme.canvasBackground
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header: Circular cross button + centered title
                    ZStack {
                        VStack(spacing: 3) {
                            Text("Upload Resume")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("Select a PDF or DOCX file to analyze")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        .padding(.horizontal, 48)

                        HStack {
                            AlineCloseButton { dismiss() }
                            Spacer()
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                    // Upload dropzone
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white)

                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, dash: [6]))

                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AlineTheme.pillDark.opacity(0.06))
                                    .frame(width: 54, height: 54)
                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AlineTheme.inkPrimary)
                            }

                            Text("Select PDF or DOCX file")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("Maximum 50 MB. Your resume remains private.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                    }
                    .frame(height: 190)
                    .padding(.horizontal, 20)

                    Button {
                        showingFilePicker = true
                    } label: {
                        Text("Browse Files on iPhone")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .alineGlassCapsule(selected: true)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.fraction(0.50), .medium])
        .presentationDragIndicator(.visible)
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.pdf]) { result in
            if case .success(let url) = result {
                viewModel.importResume(from: url)
                dismiss()
            }
        }
    }
}

// MARK: - Previews
#Preview("Resume Dashboard Tiles") {
    ResumeDashboardView(viewModel: ResumeViewModel())
}

#Preview("Resume Template Selection") {
    let vm = ResumeViewModel()
    if let first = vm.resumes.first {
        vm.selectResumeForEditing(first)
    }
    return TemplateSelectionSheet(viewModel: vm)
}

#Preview("Resume Document Editor") {
    let vm = ResumeViewModel()
    if let first = vm.resumes.first {
        vm.selectResumeForEditing(first)
        vm.confirmTemplateAndOpenEditor(template: .standard)
    }
    return NavigationStack {
        ResumeDocumentEditorView(viewModel: vm)
    }
}

#Preview("Resume Full Print Preview") {
    let vm = ResumeViewModel()
    if let first = vm.resumes.first {
        vm.selectResumeForEditing(first)
        vm.confirmTemplateAndOpenEditor(template: .modern)
    }
    return NavigationStack {
        ResumeFullPrintPreviewScreen(viewModel: vm)
    }
}


