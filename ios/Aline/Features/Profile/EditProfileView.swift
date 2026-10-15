import SwiftUI
import UniformTypeIdentifiers

/// Matches the real Figma "Profile · Personal info · Edit profile" screen (fileKey
/// AiSKBBDDO9rIzyUPHmRm98, node 1139:2306, pulled 2026-10-13) exactly: Name, Education &
/// career fields (Education/Institution/Specialization/Graduation year + Career stage),
/// optional Professional links, and the design's own footer note about anonymous identity.
///
/// Adds one thing the static design doesn't show but the product direction explicitly asked
/// for: "fill either by uploading resume or by filling it" — an upload affordance at the top
/// that runs the resume through the same on-device ResumeStructurer the Resume tab uses, then
/// pre-fills these fields for the person to review and correct rather than silently trusting
/// the extraction (consistent with how AddResumeView treats a structured resume as a draft,
/// not final truth). Also adds Skills/Work Experience/Projects sections — not in the static
/// Figma screen, but explicitly requested since a resume needs this information and it should
/// live once on the profile, not get re-typed for every new resume (see UserProfileData's
/// seedResumeProfile()).
struct EditProfileView: View {
    let viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var education = ""
    @State private var institution = ""
    @State private var specialization = ""
    @State private var graduationYear = ""
    @State private var careerStage: CareerStage?
    @State private var linkedin = ""
    @State private var github = ""
    @State private var portfolio = ""
    @State private var skills: [String] = []
    @State private var newSkillText = ""
    @State private var experience: [ProfileExperienceEntry] = []
    @State private var projects: [ProfileProjectEntry] = []
    @State private var hasLoadedFormState = false

    @State private var isPickingFile = false
    @State private var isExtracting = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }

    /// Deliberately NOT done in `init` — `viewModel.profile` is still `.empty` at construction
    /// time whenever this view is pushed before RootTabView's background `load()` has
    /// resolved (a real, reproducible race, not a hypothetical one: confirmed live when this
    /// view mounted immediately after its ProfileViewModel was created). @State only reads its
    /// initial value once, so an init-time snapshot can silently show an empty form even
    /// though the real data is one await away. This runs from `.task`, which fires after the
    /// view appears and can await the load itself if it hasn't finished yet.
    private func loadFormState() async {
        guard !hasLoadedFormState else { return }
        if !viewModel.isLoaded {
            await viewModel.load()
        }
        let profile = viewModel.profile
        name = profile.name ?? ""
        education = profile.education ?? ""
        institution = profile.institution ?? ""
        specialization = profile.specialization ?? ""
        graduationYear = profile.graduationYear.map(String.init) ?? ""
        careerStage = profile.careerStage
        linkedin = profile.linkedin ?? ""
        github = profile.github ?? ""
        portfolio = profile.portfolio ?? ""
        skills = profile.skills
        experience = profile.experience
        projects = profile.projects
        hasLoadedFormState = true
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Keep your education and career details up to date.")
                    .font(AlineFont.sfPro(14))
                    .foregroundStyle(AlineColor.textSecondary)

                uploadCard

                field("Name") { TextField("Your full name", text: $name) }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Education & career").font(AlineFont.sfPro(18, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
                    field("Education") { TextField("e.g. B.Tech", text: $education) }
                    field("Institution") { TextField("e.g. SRMIST", text: $institution) }
                    field("Specialization") { TextField("e.g. Computer Science", text: $specialization) }
                    HStack(spacing: 12) {
                        field("Graduation year") {
                            TextField("2026", text: $graduationYear)
                                .keyboardType(.numberPad)
                        }
                        .frame(width: 116)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Career stage").font(AlineFont.sfPro(13, weight: .semibold)).foregroundStyle(AlineColor.textPrimary)
                            Menu {
                                ForEach(CareerStage.allCases, id: \.self) { stage in
                                    Button(stage.rawValue) { careerStage = stage }
                                }
                            } label: {
                                HStack {
                                    Text(careerStage?.rawValue ?? "Select")
                                        .font(AlineFont.sfPro(14))
                                        .foregroundStyle(careerStage == nil ? AlineColor.textSecondary : AlineColor.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down").font(.system(size: 12)).foregroundStyle(AlineColor.iconMuted)
                                }
                                .padding(.horizontal, 13).padding(.vertical, 11)
                                .frame(minHeight: 44)
                                .background(AlineColor.paperWhite)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AlineColor.inputBorder, lineWidth: 1))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                skillsSection
                experienceSection
                projectsSection

                VStack(alignment: .leading, spacing: 14) {
                    Text("Professional links").font(AlineFont.sfPro(18, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
                    Text("All links are optional.").font(AlineFont.sfPro(12)).foregroundStyle(AlineColor.textSecondary)
                    field("LinkedIn · Optional") { TextField("linkedin.com/in/...", text: $linkedin) }
                    field("GitHub · Optional") { TextField("github.com/...", text: $github) }
                    field("Portfolio · Optional") { TextField("yoursite.dev", text: $portfolio) }
                }

                Text("Your community posts use your anonymous identity, not your profile name.")
                    .font(AlineFont.sfPro(12))
                    .foregroundStyle(AlineColor.textSecondary)

                if let errorMessage {
                    Text(errorMessage).font(AlineFont.sfPro(13)).foregroundStyle(.red)
                }
            }
            .padding(20)
        }
        .background(AlineColor.canvas)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button {
                    save()
                } label: {
                    if isSaving { ProgressView().tint(.white) } else { Text("Save Changes") }
                }
                .buttonStyle(AlinePrimaryButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(isSaving)

                Button("Cancel") { dismiss() }
                    .font(AlineFont.sfPro(14, weight: .semibold))
                    .foregroundStyle(AlineColor.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(AlineColor.canvas)
        }
        .task { await loadFormState() }
        .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                if let text = PDFTextExtractor.extractText(from: url), !text.isEmpty {
                    extract(text: text)
                } else {
                    errorMessage = "Couldn't read text from that PDF. Try filling the fields manually instead."
                }
            case .failure:
                errorMessage = "Couldn't open that file."
            }
        }
    }

    private var uploadCard: some View {
        Button {
            isPickingFile = true
        } label: {
            HStack(spacing: 10) {
                if isExtracting {
                    ProgressView().tint(AlineColor.primary)
                } else {
                    Image(systemName: "arrow.up.doc").foregroundStyle(AlineColor.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(isExtracting ? "Reading your resume…" : "Upload resume to autofill")
                        .font(AlineFont.sfPro(14, weight: .semibold))
                        .foregroundStyle(AlineColor.textPrimary)
                    if !isExtracting {
                        Text("We'll fill in what we can find — review before saving.")
                            .font(AlineFont.sfPro(12))
                            .foregroundStyle(AlineColor.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(14)
            .background(AlineColor.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AlineColor.primary.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isExtracting)
    }

    // MARK: - Skills

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Skills").font(AlineFont.sfPro(18, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
            Text("These feed straight into any resume you build from scratch.")
                .font(AlineFont.sfPro(12)).foregroundStyle(AlineColor.textSecondary)
            if !skills.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(skills, id: \.self) { skill in
                        HStack(spacing: 6) {
                            Text(skill).font(AlineFont.sfPro(12))
                            Button { skills.removeAll { $0 == skill } } label: {
                                Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                            }
                        }
                        .foregroundStyle(AlineColor.textPrimary)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(AlineColor.chipUnselected)
                        .clipShape(Capsule())
                    }
                }
            }
            HStack(spacing: 8) {
                TextField("Add a skill", text: $newSkillText)
                    .font(AlineFont.sfPro(14))
                    .padding(.horizontal, 13).padding(.vertical, 9)
                    .background(AlineColor.paperWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AlineColor.inputBorder, lineWidth: 1))
                    .onSubmit(addSkill)
                Button("Add", action: addSkill)
                    .font(AlineFont.sfPro(13, weight: .semibold))
                    .foregroundStyle(AlineColor.primary)
                    .disabled(newSkillText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addSkill() {
        let trimmed = newSkillText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !skills.contains(trimmed) else { return }
        skills.append(trimmed)
        newSkillText = ""
    }

    // MARK: - Work experience

    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Work Experience").font(AlineFont.sfPro(18, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
                Spacer()
                Button {
                    experience.append(ProfileExperienceEntry())
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(AlineColor.primary)
                }
            }
            ForEach($experience) { $entry in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        inlineField("Role", text: $entry.title)
                        inlineField("Company", text: $entry.organization)
                    }
                    HStack {
                        inlineField("Location", text: $entry.location)
                        inlineField("Dates", text: $entry.dateRange)
                    }
                    bulletEditor(bullets: $entry.bullets)
                    removeButton { experience.removeAll { $0.id == entry.id } }
                }
                .padding(12)
                .background(AlineColor.paperWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))
            }
        }
    }

    // MARK: - Projects

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Projects").font(AlineFont.sfPro(18, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
                Spacer()
                Button {
                    projects.append(ProfileProjectEntry())
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(AlineColor.primary)
                }
            }
            ForEach($projects) { $entry in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        inlineField("Project name", text: $entry.name)
                        inlineField("Dates", text: $entry.dateRange)
                    }
                    inlineField("Tech stack", text: $entry.techStack)
                    bulletEditor(bullets: $entry.bullets)
                    removeButton { projects.removeAll { $0.id == entry.id } }
                }
                .padding(12)
                .background(AlineColor.paperWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))
            }
        }
    }

    // MARK: - Shared entry-editor pieces

    private func inlineField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(AlineFont.sfPro(13))
            .padding(.horizontal, 10).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(AlineColor.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(AlineColor.inputBorder, lineWidth: 1))
    }

    private func bulletEditor(bullets: Binding<[String]>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(bullets.indices, id: \.self) { index in
                HStack(spacing: 6) {
                    Text("•").foregroundStyle(AlineColor.textSecondary)
                    TextField("Describe what you did", text: bullets[index])
                        .font(AlineFont.sfPro(13))
                    Button {
                        bullets.wrappedValue.remove(at: index)
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 10)).foregroundStyle(AlineColor.textSecondary)
                    }
                }
            }
            Button {
                bullets.wrappedValue.append("")
            } label: {
                Label("Add bullet", systemImage: "plus").font(AlineFont.sfPro(12))
            }
            .foregroundStyle(AlineColor.primary)
        }
    }

    private func removeButton(action: @escaping () -> Void) -> some View {
        Button(role: .destructive, action: action) {
            Label("Remove", systemImage: "trash").font(AlineFont.sfPro(12))
        }
        .foregroundStyle(.red)
    }

    private func field(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(AlineFont.sfPro(13, weight: .semibold)).foregroundStyle(AlineColor.textPrimary)
            content()
                .font(AlineFont.sfPro(14))
                .foregroundStyle(AlineColor.textPrimary)
                .padding(.horizontal, 13).padding(.vertical, 11)
                .frame(minHeight: 44)
                .background(AlineColor.paperWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AlineColor.inputBorder, lineWidth: 1))
        }
    }

    private func extract(text: String) {
        isExtracting = true
        errorMessage = nil
        Task {
            let resumeProfile = await ResumeStructurer.structure(resumeText: text)
            await MainActor.run {
                isExtracting = false
                if resumeProfile == .empty {
                    errorMessage = "Couldn't extract your resume automatically — try filling the fields manually instead."
                    return
                }
                if name.isEmpty { name = resumeProfile.fullName }
                if let firstEducation = resumeProfile.education.first {
                    if institution.isEmpty { institution = firstEducation.institution }
                    if education.isEmpty { education = firstEducation.degree }
                    if graduationYear.isEmpty {
                        let digits = firstEducation.dateRange.filter(\.isNumber)
                        if digits.count >= 4 { graduationYear = String(digits.suffix(4)) }
                    }
                }
                if linkedin.isEmpty { linkedin = resumeProfile.linkedInURL }
                if github.isEmpty { github = resumeProfile.githubURL }
                if portfolio.isEmpty { portfolio = resumeProfile.portfolioURL }
                if skills.isEmpty {
                    skills = Array(Set(resumeProfile.skillCategories.flatMap(\.items)))
                }
                if experience.isEmpty {
                    experience = resumeProfile.experience.map {
                        ProfileExperienceEntry(title: $0.title, organization: $0.organization, location: $0.location, dateRange: $0.dateRange, bullets: $0.bullets)
                    }
                }
                if projects.isEmpty {
                    projects = resumeProfile.projects.map {
                        ProfileProjectEntry(name: $0.name, techStack: $0.techStack, dateRange: $0.dateRange, bullets: $0.bullets)
                    }
                }
            }
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        var updated = viewModel.profile
        updated.name = name.trimmingCharacters(in: .whitespaces).isEmpty ? nil : name
        updated.education = education.trimmingCharacters(in: .whitespaces).isEmpty ? nil : education
        updated.institution = institution.trimmingCharacters(in: .whitespaces).isEmpty ? nil : institution
        updated.specialization = specialization.trimmingCharacters(in: .whitespaces).isEmpty ? nil : specialization
        updated.graduationYear = Int(graduationYear)
        updated.careerStage = careerStage
        updated.linkedin = linkedin.trimmingCharacters(in: .whitespaces).isEmpty ? nil : linkedin
        updated.github = github.trimmingCharacters(in: .whitespaces).isEmpty ? nil : github
        updated.portfolio = portfolio.trimmingCharacters(in: .whitespaces).isEmpty ? nil : portfolio
        updated.skills = skills
        updated.experience = experience.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty || !$0.organization.isEmpty }
        updated.projects = projects.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }

        Task {
            let success = await viewModel.save(updated)
            isSaving = false
            if success { dismiss() } else { errorMessage = viewModel.errorMessage }
        }
    }
}
