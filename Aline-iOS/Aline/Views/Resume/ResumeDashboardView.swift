import SwiftUI

// MARK: - Resume Main Screen (Clean Document Grid Tiles & Full Interactive AI Workflow)
public struct ResumeDashboardView: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @State private var showingUploadModal: Bool = false

    // 2-column grid for document tiles
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(AlineTheme.canvasBackground).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Top Header: Title and Small Add Icon Button
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Resumes")
                                    .font(.system(size: 32, weight: .black, design: .default))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                Text("Select a document to edit or preview")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AlineTheme.inkSecondary)
                            }

                            Spacer()

                            // Small Add Resume Icon Button on Top
                            Button {
                                showingUploadModal = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(AlineTheme.pillDark)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Add new resume")
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        // Clean Document Tiles Grid (No Stack, No List, No Description)
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(viewModel.resumes) { resume in
                                ResumeDocumentTile(
                                    resume: resume,
                                    onTap: {
                                        viewModel.selectResumeForEditing(resume)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 4)

                        Spacer(minLength: 120) // Room for floating tab bar
                    }
                }
            }
            // Template Selection Sheet (Pops up when tapping a resume)
            .sheet(isPresented: $viewModel.showTemplatePickerSheet) {
                TemplateSelectionSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingUploadModal) {
                ResumeUploadModalView(viewModel: viewModel)
            }
            // Navigation to Separate Full Screen Editor (NOT a sheet)
            .navigationDestination(isPresented: $viewModel.shouldNavigateToEditor) {
                ResumeDocumentEditorView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Clean Document Tile (Only Uploaded Date & Modified Date, No Description)
public struct ResumeDocumentTile: View {
    public let resume: ResumeDocument
    public let onTap: () -> Void

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Top Icon & Template Tag
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(resume.cardColor)
                            .frame(width: 44, height: 44)
                        Image(systemName: resume.targetCompanySymbol ?? "doc.text.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                    }

                    Spacer()

                    if resume.isDefault {
                        Text("MASTER")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AlineTheme.pillDark)
                            .clipShape(Capsule())
                    }
                }

                // Resume Title
                Text(resume.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .lineLimit(2)
                    .frame(height: 38, alignment: .topLeading)

                Divider().opacity(0.6)

                // Only Uploaded Date & Modified Date
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text("Uploaded: \(resume.uploadDate)")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(AlineTheme.inkSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("Modified: \(resume.lastModifiedDate)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AlineTheme.inkPrimary.opacity(0.85))
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Selection Sheet (Shows Resume in 3 Different Visual Templates)
public struct TemplateSelectionSheet: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var previewTemplate: ResumeDocument.ResumeTemplate = .standard

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Text("Select Resume Template")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Text("Preview your actual resume rendered in 3 distinct layouts.")
                        .font(.system(size: 13))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)

                // 3 Template Selector Tabs
                HStack(spacing: 8) {
                    ForEach(ResumeDocument.ResumeTemplate.allCases, id: \.self) { template in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                previewTemplate = template
                                viewModel.selectedTemplateChoice = template
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: templateIcon(template))
                                    .font(.system(size: 12, weight: .bold))
                                Text(template.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(previewTemplate == template ? .white : AlineTheme.inkPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(previewTemplate == template ? AlineTheme.pillDark : Color.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(previewTemplate == template ? 0 : 0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 14)
                .padding(.bottom, 12)

                // Live Rendered Resume Template Preview Paper
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        switch previewTemplate {
                        case .standard:
                            StandardTemplateView(resume: viewModel.pendingSelectedResume ?? viewModel.activeResume)
                        case .professional:
                            ProfessionalTemplateView(resume: viewModel.pendingSelectedResume ?? viewModel.activeResume)
                        case .modern:
                            ModernTemplateView(resume: viewModel.pendingSelectedResume ?? viewModel.activeResume)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 5)
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }

                Divider()

                // Bottom Action: Open with Selected Template
                VStack(spacing: 8) {
                    Button {
                        viewModel.confirmTemplateAndOpenEditor(template: previewTemplate)
                    } label: {
                        HStack(spacing: 8) {
                            Text("Open in Editor with \(previewTemplate.rawValue) Layout")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AlineTheme.pillDark)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
            }
            .background(Color(AlineTheme.canvasBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .onAppear {
                previewTemplate = viewModel.selectedTemplateChoice
            }
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

// MARK: - Template 1: Standard (ATS-Friendly Classic Serif / Clean Layout)
public struct StandardTemplateView: View {
    public let resume: ResumeDocument

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Centered Classic Name & Contact
            VStack(spacing: 3) {
                Text("AARAV SHARMA")
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundColor(AlineTheme.inkPrimary)
                Text("Bengaluru, India • aarav.dev • github.com/aarav-dev • +91 98765 43210")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)

            Rectangle().fill(Color.black.opacity(0.8)).frame(height: 1)

            // Section: Summary
            VStack(alignment: .leading, spacing: 4) {
                Text("PROFESSIONAL SUMMARY")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundColor(AlineTheme.inkPrimary)
                Text(resume.summary)
                    .font(.system(size: 10, weight: .regular))
                    .lineSpacing(2.5)
                    .foregroundColor(AlineTheme.inkPrimary.opacity(0.9))
            }

            Rectangle().fill(Color.black.opacity(0.15)).frame(height: 0.5)

            // Section: Experience
            VStack(alignment: .leading, spacing: 8) {
                Text("WORK EXPERIENCE")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundColor(AlineTheme.inkPrimary)

                ForEach(resume.experiences) { exp in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("\(exp.role) — \(exp.company)")
                                .font(.system(size: 10.5, weight: .bold))
                            Spacer()
                            Text(exp.period)
                                .font(.system(size: 9.5, weight: .regular))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }

                        ForEach(exp.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•").font(.system(size: 10, weight: .bold))
                                Text(bullet)
                                    .font(.system(size: 9.5))
                                    .lineSpacing(2)
                            }
                        }
                    }
                }
            }

            Rectangle().fill(Color.black.opacity(0.15)).frame(height: 0.5)

            // Section: Projects
            VStack(alignment: .leading, spacing: 8) {
                Text("TECHNICAL PROJECTS")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundColor(AlineTheme.inkPrimary)

                ForEach(resume.projects) { proj in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(proj.title)
                                .font(.system(size: 10.5, weight: .bold))
                            Spacer()
                            Text(proj.techStack)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        ForEach(proj.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•").font(.system(size: 10, weight: .bold))
                                Text(bullet)
                                    .font(.system(size: 9.5))
                                    .lineSpacing(2)
                            }
                        }
                    }
                }
            }

            Rectangle().fill(Color.black.opacity(0.15)).frame(height: 0.5)

            // Section: Skills
            VStack(alignment: .leading, spacing: 3) {
                Text("CORE SKILLS & TECHNOLOGIES")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundColor(AlineTheme.inkPrimary)
                Text(resume.skills.joined(separator: " • "))
                    .font(.system(size: 9.5))
                    .foregroundColor(AlineTheme.inkSecondary)
            }
        }
    }
}

// MARK: - Template 2: Professional (Slate/Navy Executive Layout)
public struct ProfessionalTemplateView: View {
    public let resume: ResumeDocument

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Executive Header Banner
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text("AARAV SHARMA")
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundColor(AlineTheme.pillDark)
                    Spacer()
                    Text("SOFTWARE ENGINEER")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                HStack(spacing: 8) {
                    Label("Bengaluru", systemImage: "mappin.circle.fill")
                    Label("aarav.dev", systemImage: "globe")
                    Label("github.com/aarav-dev", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(AlineTheme.inkSecondary)
            }
            .padding(.bottom, 6)
            .overlay(
                Rectangle()
                    .fill(AlineTheme.pillDark)
                    .frame(height: 2),
                alignment: .bottom
            )

            // Summary
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Rectangle().fill(AlineTheme.accentEmerald).frame(width: 3, height: 12)
                    Text("EXECUTIVE SUMMARY")
                        .font(.system(size: 10.5, weight: .heavy))
                        .foregroundColor(AlineTheme.pillDark)
                }
                Text(resume.summary)
                    .font(.system(size: 9.5))
                    .lineSpacing(2)
                    .foregroundColor(AlineTheme.inkPrimary)
            }

            // Experience with Left Accent Line
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Rectangle().fill(AlineTheme.accentEmerald).frame(width: 3, height: 12)
                    Text("PROFESSIONAL EXPERIENCE")
                        .font(.system(size: 10.5, weight: .heavy))
                        .foregroundColor(AlineTheme.pillDark)
                }

                ForEach(resume.experiences) { exp in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(exp.role)
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("at \(exp.company)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AlineTheme.accentEmerald)
                            Spacer()
                            Text(exp.period)
                                .font(.system(size: 9))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }

                        ForEach(exp.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 4) {
                                Text("▪").font(.system(size: 8)).foregroundColor(AlineTheme.accentEmerald)
                                Text(bullet)
                                    .font(.system(size: 9.5))
                                    .lineSpacing(2)
                            }
                        }
                    }
                    .padding(.leading, 6)
                }
            }

            // Projects
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Rectangle().fill(AlineTheme.accentEmerald).frame(width: 3, height: 12)
                    Text("ENGINEERING PROJECTS")
                        .font(.system(size: 10.5, weight: .heavy))
                        .foregroundColor(AlineTheme.pillDark)
                }

                ForEach(resume.projects) { proj in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(proj.title)
                                .font(.system(size: 10, weight: .bold))
                            Spacer()
                            Text(proj.techStack)
                                .font(.system(size: 8.5, weight: .semibold))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        ForEach(proj.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 4) {
                                Text("▪").font(.system(size: 8)).foregroundColor(AlineTheme.accentEmerald)
                                Text(bullet)
                                    .font(.system(size: 9.5))
                                    .lineSpacing(2)
                            }
                        }
                    }
                    .padding(.leading, 6)
                }
            }

            // Skills Chips
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Rectangle().fill(AlineTheme.accentEmerald).frame(width: 3, height: 12)
                    Text("COMPETENCIES")
                        .font(.system(size: 10.5, weight: .heavy))
                        .foregroundColor(AlineTheme.pillDark)
                }
                HStack(spacing: 4) {
                    ForEach(resume.skills.prefix(6), id: \.self) { skill in
                        Text(skill)
                            .font(.system(size: 8.5, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
    }
}

// MARK: - Template 3: Modern (Contemporary Tech / Monospace Accents)
public struct ModernTemplateView: View {
    public let resume: ResumeDocument

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Modern Tech Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AARAV SHARMA")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Text("// FULL-STACK & SYSTEMS BUILDER")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("aarav.dev")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    Text("github.com/aarav-dev")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundColor(AlineTheme.inkSecondary)
                }
            }
            .padding(10)
            .background(AlineTheme.cardMint.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Summary
            VStack(alignment: .leading, spacing: 4) {
                Text("[ SUMMARY ]")
                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    .foregroundColor(AlineTheme.inkSecondary)
                Text(resume.summary)
                    .font(.system(size: 9.5))
                    .lineSpacing(2)
            }

            // Experience
            VStack(alignment: .leading, spacing: 8) {
                Text("[ WORK EXPERIENCE ]")
                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    .foregroundColor(AlineTheme.inkSecondary)

                ForEach(resume.experiences) { exp in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("\(exp.role) @ \(exp.company)")
                                .font(.system(size: 10, weight: .bold))
                            Spacer()
                            Text(exp.period)
                                .font(.system(size: 8.5, design: .monospaced))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        ForEach(exp.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 5) {
                                Text("›").font(.system(size: 11, weight: .bold)).foregroundColor(AlineTheme.inkPrimary)
                                Text(bullet)
                                    .font(.system(size: 9.5))
                                    .lineSpacing(2)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.025))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Projects
            VStack(alignment: .leading, spacing: 8) {
                Text("[ PROJECTS ]")
                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    .foregroundColor(AlineTheme.inkSecondary)

                ForEach(resume.projects) { proj in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(proj.title)
                                .font(.system(size: 10, weight: .bold))
                            Spacer()
                            Text(proj.techStack)
                                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        ForEach(proj.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 5) {
                                Text("›").font(.system(size: 11, weight: .bold))
                                Text(bullet)
                                    .font(.system(size: 9.5))
                                    .lineSpacing(2)
                            }
                        }
                    }
                }
            }

            // Skills Pills
            VStack(alignment: .leading, spacing: 4) {
                Text("[ STACK ]")
                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    .foregroundColor(AlineTheme.inkSecondary)
                Text(resume.skills.joined(separator: " • "))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(AlineTheme.inkPrimary)
            }
        }
    }
}

// MARK: - Resume Document Editor (Separate Full Screen)
public struct ResumeDocumentEditorView: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color(AlineTheme.canvasBackground).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Notification Banner when Changes Saved & Chat Cleared
                    if viewModel.showSavedBanner {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AlineTheme.accentEmerald)
                            Text("Resume saved! Edit chat history cleared.")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Spacer()
                        }
                        .padding(14)
                        .background(AlineTheme.cardMint)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Instruction Tip Banner
                    HStack(spacing: 10) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text("Tap any bullet point or summary below to edit it with AI.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Spacer()

                        // Quick AI Chat Drawer Trigger Button
                        Button {
                            viewModel.showAIPanel = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11, weight: .bold))
                                Text("AI Chat")
                                    .font(.system(size: 11, weight: .bold))
                                if !viewModel.sessionChatMessages.isEmpty {
                                    Text("\(viewModel.sessionChatMessages.count)")
                                        .font(.system(size: 9, weight: .black))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.white.opacity(0.3))
                                        .clipShape(Capsule())
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AlineTheme.pillDark)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(AlineTheme.cardYellow.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Formatted Paper Sheet View in Chosen Template
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AARAV SHARMA")
                                .font(viewModel.activeResume.selectedTemplate == .modern ? .system(size: 24, weight: .black, design: .monospaced) : .system(size: 24, weight: .black))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("Template: \(viewModel.activeResume.selectedTemplate.rawValue) • Bengaluru, India • aarav.dev")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }

                        Divider()

                        // Professional Summary
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PROFESSIONAL SUMMARY")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(AlineTheme.inkPrimary)

                            SelectableTextRow(
                                text: viewModel.activeResume.summary,
                                isSelected: viewModel.selectedSnippetTargetKey == "summary",
                                onSelect: {
                                    viewModel.selectTextForAI(key: "summary", text: viewModel.activeResume.summary)
                                },
                                onEditWithAI: {
                                    viewModel.openAIPanel()
                                }
                            )
                        }

                        // Work Experience
                        if !viewModel.activeResume.experiences.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("WORK EXPERIENCE")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(AlineTheme.inkPrimary)

                                ForEach(Array(viewModel.activeResume.experiences.enumerated()), id: \.element.id) { expIdx, exp in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("\(exp.role) — \(exp.company)")
                                                .font(.system(size: 13, weight: .bold))
                                            Spacer()
                                            Text(exp.period)
                                                .font(.system(size: 11))
                                                .foregroundColor(AlineTheme.inkSecondary)
                                        }

                                        ForEach(Array(exp.bullets.enumerated()), id: \.offset) { bIdx, bullet in
                                            let key = "exp-\(expIdx)-bullet-\(bIdx)"
                                            SelectableTextRow(
                                                text: bullet,
                                                isSelected: viewModel.selectedSnippetTargetKey == key,
                                                onSelect: {
                                                    viewModel.selectTextForAI(key: key, text: bullet)
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

                        // Projects Section
                        if !viewModel.activeResume.projects.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("TECHNICAL PROJECTS")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(AlineTheme.inkPrimary)

                                ForEach(Array(viewModel.activeResume.projects.enumerated()), id: \.element.id) { projIdx, proj in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(proj.title)
                                                .font(.system(size: 13, weight: .bold))
                                            Spacer()
                                            Text(proj.techStack)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(AlineTheme.inkSecondary)
                                        }

                                        ForEach(Array(proj.bullets.enumerated()), id: \.offset) { bIdx, bullet in
                                            let key = "proj-\(projIdx)-bullet-\(bIdx)"
                                            SelectableTextRow(
                                                text: bullet,
                                                isSelected: viewModel.selectedSnippetTargetKey == key,
                                                onSelect: {
                                                    viewModel.selectTextForAI(key: key, text: bullet)
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
                    }
                    .padding(22)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 130) // Room for bottom bar
                }
            }

            // Bottom Sticky Bar: Save Changes & Save & Preview PDF
            HStack(spacing: 12) {
                // Save Changes button (commits edits & clears the session chat)
                Button {
                    withAnimation {
                        viewModel.saveDocumentChanges()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Changes")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(AlineTheme.accentEmerald)
                            .shadow(color: AlineTheme.accentEmerald.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)

                // Preview PDF button
                Button {
                    viewModel.shouldNavigateToPrintPreview = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                        Text("Preview PDF")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(AlineTheme.pillDark)
                            .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .navigationTitle(viewModel.activeResume.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    // Quick Save Button in Navigation Bar
                    Button {
                        withAnimation {
                            viewModel.saveDocumentChanges()
                        }
                    } label: {
                        Text("Save")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(AlineTheme.accentEmerald)
                            .clipShape(Capsule())
                    }

                    // AI Assistant Trigger
                    Button {
                        viewModel.showAIPanel = true
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                    }
                }
            }
        }
        // Bottom AI Assistant Panel with Full Session Chat Feed
        .sheet(isPresented: $viewModel.showAIPanel) {
            AIAssistantDrawer(viewModel: viewModel)
        }
        // Step 6: Full Page Print Preview
        .navigationDestination(isPresented: $viewModel.shouldNavigateToPrintPreview) {
            ResumeFullPrintPreviewScreen(viewModel: viewModel)
        }
    }
}

// MARK: - Selectable Text Row with "Edit with AI ✨" Floating Button
public struct SelectableTextRow: View {
    public let text: String
    public let isSelected: Bool
    public let onSelect: () -> Void
    public let onEditWithAI: () -> Void

    public var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                Text(text)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .background(isSelected ? AlineTheme.cardYellow.opacity(0.5) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AlineTheme.pillDark : Color.clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)

            // Attached "Edit with AI ✨" Button when selected
            if isSelected {
                Button(action: onEditWithAI) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                        Text("Edit with AI")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AlineTheme.pillDark)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
                .padding(.trailing, 4)
            }
        }
    }
}

// MARK: - AI Assistant Drawer (Multi-Turn Chat History Until Saved)
public struct AIAssistantDrawer: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss

    let quickChips = [
        "Mention Hash Map and data structures",
        "Add measurable metrics (32% faster)",
        "Make it more concise & impactful",
        "Lead with strong action verbs"
    ]

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Session Banner
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AlineTheme.accentEmerald)
                    Text("Session Chat: changes remain until you save")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Spacer()

                    // Save Changes Button (commits & clears the chat)
                    Button {
                        withAnimation {
                            viewModel.saveDocumentChanges()
                        }
                    } label: {
                        Text("Save Changes")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AlineTheme.accentEmerald)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AlineTheme.cardMint.opacity(0.5))

                // Targeted Snippet Card (if any text is selected)
                if !viewModel.selectedSnippetText.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SELECTED FOR REFINEMENT:")
                                .font(.system(size: 9.5, weight: .heavy))
                                .foregroundColor(AlineTheme.inkSecondary)
                            Text(viewModel.selectedSnippetText)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Button {
                            viewModel.selectedSnippetText = ""
                            viewModel.selectedSnippetTargetKey = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                // Chat Message Feed (Shows full chat until user saves)
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 14) {
                            if viewModel.sessionChatMessages.isEmpty {
                                // Empty state after saving
                                VStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(AlineTheme.accentEmerald)
                                    Text("Changes Saved!")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                    Text("Chat history was cleared upon saving. Tap any text on your resume or enter a prompt below to start a new refinement session.")
                                        .font(.system(size: 12))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                }
                                .padding(.top, 40)
                                .padding(.bottom, 20)
                            } else {
                                ForEach(viewModel.sessionChatMessages) { message in
                                    AIChatMessageRow(message: message, onApply: {
                                        withAnimation {
                                            viewModel.applyChatSuggestion(messageId: message.id)
                                        }
                                    })
                                    .id(message.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewModel.sessionChatMessages.count) { _, _ in
                        if let last = viewModel.sessionChatMessages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Bottom Input Area: Quick Chips + Composer
                VStack(spacing: 8) {
                    // Quick suggestion chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(quickChips, id: \.self) { chip in
                                Button {
                                    viewModel.userAIInstruction = chip
                                    viewModel.requestAISuggestion()
                                } label: {
                                    Text(chip)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AlineTheme.inkPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Prompt Input Field and Send Button
                    HStack(spacing: 8) {
                        TextField("Ask AI to change, improve, or quantify...", text: $viewModel.userAIInstruction)
                            .font(.system(size: 14))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.black.opacity(0.1), lineWidth: 1))

                        Button {
                            viewModel.requestAISuggestion()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(AlineTheme.pillDark)
                                    .frame(width: 42, height: 42)
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
                .background(Color(AlineTheme.canvasBackground))
            }
            .background(Color(AlineTheme.canvasBackground).ignoresSafeArea())
            .navigationTitle("Edit with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
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
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(message.text)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(AlineTheme.pillDark)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        if let orig = message.originalText, !orig.isEmpty {
                            Text("Target: \"\(orig.prefix(40))...\"")
                                .font(.system(size: 9.5))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                    }
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
                    .foregroundColor(AlineTheme.accentEmerald)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AlineTheme.cardMint)
                    .clipShape(Capsule())
                    Spacer()
                }

            case .ai:
                // AI Response & Suggestion Card (Aligned Left)
                HStack(alignment: .top, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AlineTheme.pillDark)
                            .frame(width: 28, height: 28)
                        Image(systemName: "sparkles")
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
                                    HStack(spacing: 4) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.orange)
                                        Text(reason)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(AlineTheme.inkSecondary)
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
                                            Text("Applied to Document ✓")
                                        } else {
                                            Image(systemName: "arrow.down.doc.fill")
                                            Text("Apply to Resume")
                                        }
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(message.isApplied ? Color.gray.opacity(0.8) : AlineTheme.accentEmerald)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .disabled(message.isApplied)
                            }
                            .padding(12)
                            .background(AlineTheme.cardMint.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
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
        ZStack(alignment: .bottom) {
            Color(AlineTheme.canvasBackground).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // High-Fidelity Paper Simulation
                    VStack(alignment: .leading, spacing: 18) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AARAV SHARMA")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text("Bengaluru, India • aarav.dev • github.com/aarav-dev • +91 98765 43210")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }

                        Divider()

                        // Summary
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PROFESSIONAL SUMMARY")
                                .font(.system(size: 12, weight: .heavy))
                            Text(viewModel.activeResume.summary)
                                .font(.system(size: 12))
                                .lineSpacing(3)
                        }

                        // Experience
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WORK EXPERIENCE")
                                .font(.system(size: 12, weight: .heavy))
                            ForEach(viewModel.activeResume.experiences) { exp in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("\(exp.role) — \(exp.company)")
                                            .font(.system(size: 12, weight: .bold))
                                        Spacer()
                                        Text(exp.period).font(.system(size: 11))
                                    }
                                    ForEach(exp.bullets, id: \.self) { bullet in
                                        Text("• \(bullet)")
                                            .font(.system(size: 11))
                                            .lineSpacing(2)
                                    }
                                }
                            }
                        }

                        // Projects
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PROJECTS")
                                .font(.system(size: 12, weight: .heavy))
                            ForEach(viewModel.activeResume.projects) { proj in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(proj.title).font(.system(size: 12, weight: .bold))
                                        Spacer()
                                        Text(proj.techStack).font(.system(size: 10, weight: .semibold))
                                    }
                                    ForEach(proj.bullets, id: \.self) { bullet in
                                        Text("• \(bullet)")
                                            .font(.system(size: 11))
                                            .lineSpacing(2)
                                    }
                                }
                            }
                        }

                        // Skills
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SKILLS")
                                .font(.system(size: 12, weight: .heavy))
                            Text(viewModel.activeResume.skills.joined(separator: " • "))
                                .font(.system(size: 11))
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.black.opacity(0.1), radius: 14, x: 0, y: 6)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer(minLength: 120)
                }
            }

            // Bottom Sticky Download PDF Button
            VStack {
                Button {
                    viewModel.downloadResumePDF()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isDownloadingPDF {
                            ProgressView().tint(.white)
                            Text("Preparing High-Res PDF...")
                        } else if viewModel.hasDownloadedPDF {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Downloaded Successfully ✓")
                        } else {
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Download PDF (\(viewModel.activeResume.fileSize))")
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(viewModel.hasDownloadedPDF ? AlineTheme.accentEmerald : AlineTheme.pillDark)
                            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isDownloadingPDF)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("Final PDF Preview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Resume Upload Modal
public struct ResumeUploadModalView: View {
    @ObservedObject public var viewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.black.opacity(0.18), style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .frame(height: 200)

                    VStack(spacing: 12) {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Text("Select PDF or DOCX file")
                            .font(.system(size: 16, weight: .bold))
                        Text("Maximum 50 MB. Your resume remains private.")
                            .font(.system(size: 12))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Button {
                    dismiss()
                } label: {
                    Text("Browse Files on iPhone")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AlineTheme.pillDark)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationTitle("Add Resume")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
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


