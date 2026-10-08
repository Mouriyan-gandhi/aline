import SwiftUI

/// The "doesn't have a resume yet, fills the profile himself" path. Plain structured form —
/// same ResumeProfile shape the AI extractor produces, so both paths converge on identical
/// data feeding the same fixed templates.
struct ManualProfileEditorView: View {
    @State var initialProfile: ResumeProfile
    @Binding var path: NavigationPath

    var body: some View {
        Form {
            Section("Contact") {
                TextField("Full name", text: $initialProfile.fullName)
                TextField("Phone", text: $initialProfile.phone)
                TextField("Email", text: $initialProfile.email)
                TextField("LinkedIn URL", text: $initialProfile.linkedInURL)
                TextField("GitHub URL", text: $initialProfile.githubURL)
                TextField("Portfolio URL", text: $initialProfile.portfolioURL)
            }

            Section("Summary (optional)") {
                TextEditor(text: $initialProfile.summary).frame(height: 70)
            }

            Section("Education") {
                ForEach($initialProfile.education) { $entry in
                    educationFields($entry)
                }
                .onDelete { initialProfile.education.remove(atOffsets: $0) }
                Button { initialProfile.education.append(EducationEntry()) } label: {
                    Label("Add education", systemImage: "plus")
                }
            }

            Section("Experience") {
                ForEach($initialProfile.experience) { $entry in
                    experienceFields($entry)
                }
                .onDelete { initialProfile.experience.remove(atOffsets: $0) }
                Button { initialProfile.experience.append(ExperienceEntry()) } label: {
                    Label("Add experience", systemImage: "plus")
                }
            }

            Section("Projects") {
                ForEach($initialProfile.projects) { $entry in
                    projectFields($entry)
                }
                .onDelete { initialProfile.projects.remove(atOffsets: $0) }
                Button { initialProfile.projects.append(ProjectEntry()) } label: {
                    Label("Add project", systemImage: "plus")
                }
            }

            Section("Skills") {
                ForEach($initialProfile.skillCategories) { $category in
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Category (e.g. Languages)", text: $category.label)
                        TextField("Comma-separated, e.g. Python, Java, SQL", text: Binding(
                            get: { category.items.joined(separator: ", ") },
                            set: { category.items = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                        ))
                        .font(AlineFont.body(13))
                    }
                }
                .onDelete { initialProfile.skillCategories.remove(atOffsets: $0) }
                Button { initialProfile.skillCategories.append(SkillCategory()) } label: {
                    Label("Add skill category", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Build Your Resume")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") {
                    let id = PendingProfileStore.shared.store(initialProfile)
                    path.append(ResumeRoute.chooseTemplate(id))
                }
                .fontWeight(.semibold)
            }
        }
    }

    private func educationFields(_ entry: Binding<EducationEntry>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Institution", text: entry.institution)
            TextField("Degree", text: entry.degree)
            HStack {
                TextField("Location", text: entry.location)
                TextField("Dates (e.g. Aug 2022 – May 2026)", text: entry.dateRange)
            }
            TextField("GPA/honors (optional)", text: entry.detail)
        }
        .font(AlineFont.body(14))
    }

    private func experienceFields(_ entry: Binding<ExperienceEntry>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Title", text: entry.title)
            TextField("Organization", text: entry.organization)
            HStack {
                TextField("Location", text: entry.location)
                TextField("Dates", text: entry.dateRange)
            }
            bulletEditor(entry.bullets)
        }
        .font(AlineFont.body(14))
    }

    private func projectFields(_ entry: Binding<ProjectEntry>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Project name", text: entry.name)
            TextField("Tech stack", text: entry.techStack)
            TextField("Dates", text: entry.dateRange)
            bulletEditor(entry.bullets)
        }
        .font(AlineFont.body(14))
    }

    private func bulletEditor(_ bullets: Binding<[String]>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(bullets.wrappedValue.indices, id: \.self) { index in
                TextField("Bullet point", text: Binding(
                    get: { bullets.wrappedValue[index] },
                    set: { bullets.wrappedValue[index] = $0 }
                ))
                .font(AlineFont.body(13))
            }
            Button {
                bullets.wrappedValue.append("")
            } label: {
                Label("Add bullet", systemImage: "plus.circle").font(AlineFont.body(12))
            }
        }
    }
}
