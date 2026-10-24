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
    @State private var showingApplyConfirmation: Bool = false
    @State private var isResumeMatchExpanded: Bool = false

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

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Top Bar (Chevron '<' on Left, Heart Like on Right)
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .frame(width: 44, height: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                viewModel.toggleLike(for: liveOpportunity.id)
                            }
                        } label: {
                            Image(systemName: liveOpportunity.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(liveOpportunity.isLiked ? .red : AlineTheme.inkPrimary)
                                .frame(width: 44, height: 44, alignment: .trailing)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
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

                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                            Text("\(liveOpportunity.matchScore)% Match")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(Color(red: 0.12, green: 0.58, blue: 0.32))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.90, green: 0.97, blue: 0.92))
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

                    // Info Chips Row (Location, Opportunity Type, Work Mode, Salary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            WhitePillChip(icon: "mappin", text: liveOpportunity.location)
                            WhitePillChip(icon: "briefcase", text: liveOpportunity.opportunityType.rawValue)
                            WhitePillChip(icon: "building.2", text: liveOpportunity.workMode.rawValue)
                            WhitePillChip(icon: "dollarsign", text: liveOpportunity.salaryRange)
                        }
                        .padding(.horizontal, 24)
                    }

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

            // Sticky Bottom Action Bar with "Apply on Company Site ↗"
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.97, blue: 0.95).opacity(0.0),
                        Color(red: 0.98, green: 0.97, blue: 0.95).opacity(0.85),
                        Color(red: 0.98, green: 0.97, blue: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 24)

                VStack {
                    Button {
                        viewModel.markApplied(for: liveOpportunity.id)
                        showingApplyConfirmation = true
                        if let url = URL(string: liveOpportunity.externalCareersURL) {
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(liveOpportunity.isApplied ? "Applied on \(liveOpportunity.applicationDate ?? "Today")" : "Apply on Company Site")
                                .font(.system(size: 16, weight: .bold))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(Color.black)
                                .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(Color(red: 0.98, green: 0.97, blue: 0.95))
            }
            .ignoresSafeArea(.keyboard)
        }
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

            // Metadata Rows (Company, Location, Job Type, Work Mode, Eligible Graduates)
            VStack(spacing: 14) {
                metadataRow(title: "Company", value: liveOpportunity.companyName)
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
                            .fill(Color(red: 0.96, green: 0.72, blue: 0.73))
                            .frame(width: 44, height: 44)

                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.65, green: 0.18, blue: 0.20))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Resume Match")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)

                        let count = liveOpportunity.missingKeywords.count
                        Text(count == 1 ? "We found 1 missing keyword" : "We found \(count) missing keywords")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }

                    Spacer()

                    Image(systemName: isResumeMatchExpanded ? "chevron.up" : "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
            }
            .buttonStyle(.plain)

            // Missing Keywords Details (Shown when tapped/expanded or in detail tabs)
            if isResumeMatchExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Missing Keywords to Add:")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.65, green: 0.18, blue: 0.20))

                    ForEach(liveOpportunity.missingKeywords) { kw in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.78, green: 0.20, blue: 0.22))
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

                    Button {
                        dismiss()
                        resumeViewModel.setTargetOpportunity(opportunity)
                        withAnimation(AlineTheme.tabSpring) {
                            navViewModel.currentTab = .resume
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .bold))
                            Text("Tailor Resume with AI")
                                .font(.system(size: 13, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.99, green: 0.86, blue: 0.86)) // Exact red/coral pastel from user screenshot
        )
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

            // Resume Match & Missing Keywords in Red/Coral format
            resumeMatchCoralCard
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

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 8)], spacing: 8) {
                    ForEach(liveOpportunity.skills, id: \.self) { skill in
                        SkillTagView(
                            title: skill,
                            isHighlighted: liveOpportunity.detectedKeywords.contains(skill)
                        )
                    }
                }
            }

            // Resume Match & Missing Keywords in Red/Coral format
            resumeMatchCoralCard
        }
    }
}

// MARK: - Previews
#Preview("Job Detail - Ola Intern") {
    JobDetailView(
        opportunity: Opportunity.samples.first(where: { $0.companyName == "Ola" }) ?? Opportunity.samples[0],
        viewModel: DiscoverViewModel(),
        navViewModel: AppNavigationViewModel(),
        resumeViewModel: ResumeViewModel()
    )
}

#Preview("Job Detail - Google") {
    JobDetailView(
        opportunity: Opportunity.samples.first(where: { $0.companyName == "Google" }) ?? Opportunity.samples[0],
        viewModel: DiscoverViewModel(),
        navViewModel: AppNavigationViewModel(),
        resumeViewModel: ResumeViewModel()
    )
}
