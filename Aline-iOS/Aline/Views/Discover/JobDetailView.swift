import SwiftUI

// MARK: - Job Detail View (Full-Page Presentation matching Reference Screenshot)
public struct JobDetailView: View {
    public let opportunity: Opportunity
    @ObservedObject public var viewModel: DiscoverViewModel
    @ObservedObject public var navViewModel: AppNavigationViewModel
    @ObservedObject public var resumeViewModel: ResumeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var selectedTab: DetailTab = .overview
    @State private var showingNotRelevantConfirm: Bool = false
    @State private var showingApplyConfirmation: Bool = false
    /// Set when the user leaves for the company site; asked "Did you apply?" when they come back
    @State private var awaitingApplyCheck: Bool = false
    @State private var showingDidApplyPrompt: Bool = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var isResumeMatchExpanded: Bool = false

    private static let resumeMatchID = "resumeMatchCard"

    /// Skills from the Skills tab that weren't found on the resume
    private var missingSkills: [String] { ResumeViewModel.missingSkills(for: liveOpportunity) }

    private var liveOpportunity: Opportunity {
        viewModel.opportunities.first(where: { $0.id == opportunity.id }) ?? opportunity
    }

    public enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case requirements = "Requirements"
        case responsibilities = "Responsibilities"
        case skills = "Skills"
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Background matching Home Discover Page (Creme base + blurred pastel circles & sparkle stars)
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Top Bar (Consistent Circular Back Button on Left, Circular Heart Like on Right)
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .frame(width: 40, height: 40)
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .alineGlassCircleButton()

                        Spacer()

                        // "Not relevant": hides the job and steers recommendations away from similar ones
                        Button {
                            showingNotRelevantConfirm = true
                        } label: {
                            Image(systemName: "hand.thumbsdown")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .frame(width: 40, height: 40)
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .alineGlassCircleButton()
                        .accessibilityLabel("Not relevant")

                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                viewModel.toggleLike(for: liveOpportunity.id)
                            }
                        } label: {
                            Image(systemName: liveOpportunity.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(liveOpportunity.isLiked ? .red : AlineTheme.inkPrimary)
                                .frame(width: 40, height: 40)
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .alineGlassCircleButton()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Company Logo (Squircle) + Bold Company Name Near Logo + Match Score Badge
                    HStack(alignment: .center, spacing: 14) {
                        CompanyLogoBadge(companyName: liveOpportunity.companyName, size: 68, isSquircle: true)

                        Text(liveOpportunity.companyName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Spacer()

                        Text("\(liveOpportunity.matchScore)% Match")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(liveOpportunity.matchBadgeForegroundColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(liveOpportunity.matchBadgeBackgroundColor)
                            )
                    }
                    .padding(.horizontal, 24)

                    // Role Title (Left-Aligned)
                    VStack(alignment: .leading, spacing: 6) {
                        let displayTitle = liveOpportunity.roleTitle.hasSuffix(".") ? liveOpportunity.roleTitle : "\(liveOpportunity.roleTitle)."
                        Text(displayTitle)
                            .font(.system(size: 28, weight: .heavy, design: .default))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 24)


                    // Subheadings / Tabs with Active Underline Indicator Bar (Overview, Requirements, Responsibilities, Skills)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(DetailTab.allCases, id: \.self) { tab in
                                let isSelected = selectedTab == tab
                                Button {
                                    withAnimation(AlineTheme.fastSpring) {
                                        selectedTab = tab
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(tab.rawValue)
                                            .font(.system(size: 16, weight: isSelected ? .bold : .semibold))
                                            .foregroundColor(AlineTheme.inkPrimary)

                                        if isSelected {
                                            Capsule()
                                                .fill(Color.black)
                                                .frame(height: 3)
                                        } else {
                                            Capsule()
                                                .fill(Color.clear)
                                                .frame(height: 3)
                                        }
                                    }
                                    .fixedSize()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 4)

                    // Tab Content (No enclosing white cards - clean typography on Creme Pastel Artwork)
                    VStack(alignment: .leading, spacing: 22) {
                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .requirements:
                            requirementsContent
                        case .responsibilities:
                            responsibilitiesContent
                        case .skills:
                            skillsContent
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                    Spacer(minLength: 120) // Room for sticky Apply button
                }
            }
.scrollDismissesKeyboard(.interactively)
            // Opening Resume Match brings the whole card into view
            .onChange(of: isResumeMatchExpanded) { _, expanded in
                guard expanded else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(AlineTheme.fastSpring) {
                        proxy.scrollTo(Self.resumeMatchID, anchor: .top)
                    }
                }
            }
            }

            // Sticky Bottom Action Bar with "Apply on Company Site"
            VStack(spacing: 0) {
                VStack {
                    Button {
                        // Don't assume they applied: ask when they come back from the company site
                        if let url = URL(string: liveOpportunity.externalCareersURL) {
                            awaitingApplyCheck = true
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if liveOpportunity.isApplied {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            Text(liveOpportunity.isApplied ? "Applied" : "Apply on Company Site")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .alineGlassCapsule(selected: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .black.opacity(0.7), location: 0.25),
                                    .init(color: .black, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .ignoresSafeArea(edges: .bottom)
                )
            }
            .ignoresSafeArea(.keyboard)
        }
        // Back from the company site: ask whether they actually applied
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && awaitingApplyCheck {
                awaitingApplyCheck = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showingDidApplyPrompt = true
                }
            }
        }
        // On-device AI: sections for postings that couldn't be split, and keyword gaps vs. the profile
        .task(id: opportunity.id) { await viewModel.enrichDetail(for: opportunity.id) }
        .confirmationDialog("Not relevant for you?", isPresented: $showingNotRelevantConfirm, titleVisibility: .visible) {
            Button("Hide this job", role: .destructive) {
                viewModel.dismissJob(liveOpportunity.id)
                dismiss()
            }
        } message: {
            Text("We'll hide it and show you fewer roles like it.")
        }
        .alert(applyPromptTitle, isPresented: $showingDidApplyPrompt) {
            Button("Yes, I applied") {
                withAnimation(AlineTheme.fastSpring) {
                    viewModel.markApplied(for: liveOpportunity.id)
                }
            }
            Button("Not yet", role: .cancel) {}
        } message: {
            Text("We'll move \(liveOpportunity.roleTitle) at \(liveOpportunity.companyName) to your Applied list.")
        }
    }

    private var applyPromptTitle: String {
        liveOpportunity.opportunityType == .internship
            ? "Did you apply for this internship?"
            : "Did you apply for this job?"
    }

    // MARK: - Overview Content (Matching Reference Screenshot)
    @ViewBuilder
    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // About the Role
            VStack(alignment: .leading, spacing: 10) {
                Text("About the Role")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)

                Text(liveOpportunity.aboutRole)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AlineTheme.inkPrimary.opacity(0.85))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .opacity(0.25)
                .padding(.vertical, 4)

            // Metadata Rows (Location, Job Type, Work Mode, Eligible Graduates; company is already in the header)
            VStack(spacing: 14) {
                metadataRow(title: "Location", value: liveOpportunity.location)
                metadataRow(title: "Job Type", value: liveOpportunity.opportunityType.rawValue)
                metadataRow(title: "Work Mode", value: liveOpportunity.workMode.rawValue)
                metadataRow(title: "Eligible Graduates", value: liveOpportunity.eligibleGradYears)
            }

            // Red/Coral Resume Match Box with Missing Keywords (Matching Reference Screenshot)
            resumeMatchCoralCard
        }
    }

    // MARK: - Metadata Row Helper
    private func metadataRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AlineTheme.inkPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
        }
    }

    // MARK: - Red/Coral Resume Match & Missing Keywords Box (Matching User Image)
    @ViewBuilder
    private var resumeMatchCoralCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(AlineTheme.fastSpring) {
                    isResumeMatchExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    // Document Icon Badge (Darker coral squircle)
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(JobSkillChip.missingIconFill)
                            .frame(width: 44, height: 44)

                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 20))
                            .foregroundColor(JobSkillChip.missingText)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Resume Match")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Text(matchSummary)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isResumeMatchExpanded ? 180 : 0))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
            }
            .buttonStyle(.plain)

            // Missing Skills & Keywords Details (Shown when tapped/expanded)
            if isResumeMatchExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if !missingSkills.isEmpty {
                        Text("Missing Skills:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)

                        SkillChipFlow(spacing: 8) {
                            ForEach(missingSkills, id: \.self) { skill in
                                JobSkillChip(title: skill, isMatched: false)
                            }
                        }
                        .padding(.bottom, 4)
                    }

                    if !liveOpportunity.missingKeywords.isEmpty {
                    Text("Missing Keywords to Add:")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    ForEach(liveOpportunity.missingKeywords) { kw in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(JobSkillChip.missingText)
                                Text(kw.keyword)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                            }
                            Text(kw.recommendation)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.70))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    }

                    Button {
                        dismiss()
                        // Resume tab asks which resume to tailor, then hands this job to the AI chat
                        resumeViewModel.startTailoring(for: liveOpportunity)
                        withAnimation(AlineTheme.tabSpring) {
                            navViewModel.currentTab = .resume
                        }
                    } label: {
                        Text("Tailor Resume with AI")
                            .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .alineGlassCapsule(selected: true)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(JobSkillChip.missingCardFill) // Same soft red family as the missing skill chips, a touch lighter
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(JobSkillChip.missingCardBorder, lineWidth: 1)
                .allowsHitTesting(false)
        )
        .id(Self.resumeMatchID)
    }

    private var matchSummary: String {
        let skills = missingSkills.count
        let keywords = liveOpportunity.missingKeywords.count
        func plural(_ n: Int, _ word: String) -> String { "\(n) missing \(word)\(n == 1 ? "" : "s")" }
        switch (skills, keywords) {
        case (0, 0): return "Your resume covers this role"
        case (_, 0): return "We found \(plural(skills, "skill"))"
        case (0, _): return "We found \(plural(keywords, "keyword"))"
        default: return "We found \(plural(skills, "skill")) and \(plural(keywords, "keyword"))"
        }
    }

    // MARK: - Requirements Content
    @ViewBuilder
    private var requirementsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Minimum Qualifications
            VStack(alignment: .leading, spacing: 12) {
                Text("Minimum Qualifications")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)

                ForEach(liveOpportunity.minimumQualifications, id: \.self) { qual in
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text(qual)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AlineTheme.inkPrimary.opacity(0.85))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // Preferred Qualifications
            if !liveOpportunity.preferredQualifications.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferred Qualifications")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    ForEach(liveOpportunity.preferredQualifications, id: \.self) { pref in
                        HStack(alignment: .top, spacing: 10) {
                            Text("•")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                            Text(pref)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(AlineTheme.inkPrimary.opacity(0.85))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

        }
    }

    // MARK: - Responsibilities Content
    @ViewBuilder
    private var responsibilitiesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Key Responsibilities")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)

                ForEach(liveOpportunity.responsibilities, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Text(item)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AlineTheme.inkPrimary.opacity(0.85))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: - Skills Content
    @ViewBuilder
    private var skillsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Target Technical Skills")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)

                // Left-aligned chips that wrap like text, all one line high
                SkillChipFlow(spacing: 8) {
                    ForEach(liveOpportunity.skills, id: \.self) { skill in
                        JobSkillChip(title: skill, isMatched: liveOpportunity.detectedKeywords.contains(skill))
                    }
                }

                // Legend for the two chip colors
                HStack(spacing: 14) {
                    legendItem(color: Color.black.opacity(0.18), text: "On your profile")
                    legendItem(color: JobSkillChip.missingText, text: "Missing")
                }
                .padding(.top, 2)
            }
        }
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AlineTheme.inkSecondary)
        }
    }
}

// MARK: - Job Skill Chip (soft grey when it is on the user's profile, mild red when it is missing)
private struct JobSkillChip: View {
    let title: String
    let isMatched: Bool

    static let missingText = Color(red: 0.65, green: 0.18, blue: 0.20)
    // Solid soft reds, so the tint doesn't shift over the page's yellow-to-blue background
    static let missingFill = Color(red: 0.97, green: 0.85, blue: 0.85)
    static let missingCardFill = Color(red: 0.99, green: 0.91, blue: 0.91)
    static let missingCardBorder = Color(red: 0.65, green: 0.18, blue: 0.20).opacity(0.20)
    static let missingIconFill = Color(red: 0.96, green: 0.80, blue: 0.80)
    static let matchedFill = Color.black.opacity(0.05)

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isMatched ? AlineTheme.inkPrimary : Self.missingText)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isMatched ? Self.matchedFill : Self.missingFill)
            )
    }
}

// MARK: - Skill Chip Flow (chips sit side by side and wrap to the next line like text)
private struct SkillChipFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [(indices: [Int], y: CGFloat, width: CGFloat, height: CGFloat)] {
        var rows: [(indices: [Int], y: CGFloat, width: CGFloat, height: CGFloat)] = []
        var current: [Int] = []
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var y: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !current.isEmpty, rowWidth + spacing + size.width > width {
                rows.append((current, y, rowWidth, rowHeight))
                y += rowHeight + spacing
                current = []
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += (current.isEmpty ? 0 : spacing) + size.width
            rowHeight = max(rowHeight, size.height)
            current.append(index)
        }
        if !current.isEmpty { rows.append((current, y, rowWidth, rowHeight)) }
        return rows
    }
}

// MARK: - Previews
#Preview("Job Detail - Ola Intern") {
    JobDetailView(
        opportunity: .previewSample,
        viewModel: DiscoverViewModel(),
        navViewModel: AppNavigationViewModel(),
        resumeViewModel: ResumeViewModel()
    )
}

#Preview("Job Detail - Google") {
    JobDetailView(
        opportunity: .previewSample,
        viewModel: DiscoverViewModel(),
        navViewModel: AppNavigationViewModel(),
        resumeViewModel: ResumeViewModel()
    )
}
