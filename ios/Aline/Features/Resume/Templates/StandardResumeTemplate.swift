import SwiftUI

/// Template 1 — "Standard." Structurally modeled on "Jake's Resume," the open-source
/// single-column format that's become the de facto ATS-safe baseline in tech hiring (no
/// tables, no columns, no graphics — exactly what the plan's "3 ATS-parseability-first
/// templates" requirement calls for). Plain, dense, no color — the safest possible choice
/// for a generic application where you don't know what's parsing it on the other end.
struct StandardResumeTemplate: View {
    let profile: ResumeProfile
    var scale: CGFloat = 1.0
    /// See ResumeBullet's doc comment — tap-to-select for "Edit with AI." Nil outside the
    /// View Resume screen (PDF export, thumbnails).
    var onSelectText: (@MainActor @Sendable (String) -> Void)?

    private var nameSize: CGFloat { 22 * scale }
    private var contactSize: CGFloat { 9.5 * scale }
    private var headingSize: CGFloat { 11 * scale }
    private var bodySize: CGFloat { 9.5 * scale }
    private var sectionSpacing: CGFloat { 10 * scale }
    private var entrySpacing: CGFloat { 7 * scale }
    private var bulletSpacing: CGFloat { 2.5 * scale }

    private var bodyFont: Font { .custom("Inter", size: bodySize) }
    private var bodyColor: Color { AlineColor.charcoal }

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            header

            if !profile.education.isEmpty {
                section("EDUCATION") {
                    VStack(alignment: .leading, spacing: entrySpacing) {
                        ForEach(profile.education) { entry in
                            VStack(alignment: .leading, spacing: 1 * scale) {
                                ResumeLineRow(
                                    leading: Text(entry.institution).font(.custom("Inter", size: bodySize)).fontWeight(.semibold),
                                    trailing: Text(entry.location).font(bodyFont)
                                )
                                ResumeLineRow(
                                    leading: Text(entry.degree).font(bodyFont).italic(),
                                    trailing: Text(entry.dateRange).font(bodyFont).italic()
                                )
                                if !entry.detail.isEmpty {
                                    Text(entry.detail).font(bodyFont)
                                }
                            }
                            .foregroundStyle(bodyColor)
                        }
                    }
                }
            }

            if !profile.experience.isEmpty {
                section("EXPERIENCE") {
                    VStack(alignment: .leading, spacing: entrySpacing) {
                        ForEach(profile.experience) { entry in
                            VStack(alignment: .leading, spacing: 1 * scale) {
                                ResumeLineRow(
                                    leading: Text(entry.title).font(.custom("Inter", size: bodySize)).fontWeight(.semibold),
                                    trailing: Text(entry.dateRange).font(bodyFont).italic()
                                )
                                ResumeLineRow(
                                    leading: Text(entry.organization).font(bodyFont).italic(),
                                    trailing: Text(entry.location).font(bodyFont).italic()
                                )
                                .foregroundStyle(bodyColor.opacity(0.85))
                                VStack(alignment: .leading, spacing: bulletSpacing) {
                                    ForEach(entry.bullets, id: \.self) { bullet in
                                        ResumeBullet(bullet, font: bodyFont, color: bodyColor, onSelect: onSelectText)
                                    }
                                }
                                .padding(.top, 2 * scale)
                            }
                            .foregroundStyle(bodyColor)
                        }
                    }
                }
            }

            if !profile.projects.isEmpty {
                section("PROJECTS") {
                    VStack(alignment: .leading, spacing: entrySpacing) {
                        ForEach(profile.projects) { entry in
                            VStack(alignment: .leading, spacing: 1 * scale) {
                                ResumeLineRow(
                                    leading: (
                                        Text(entry.name).fontWeight(.semibold)
                                        + Text(entry.techStack.isEmpty ? "" : "  |  \(entry.techStack)").italic()
                                    )
                                    .font(bodyFont),
                                    trailing: Text(entry.dateRange).font(bodyFont).italic()
                                )
                                VStack(alignment: .leading, spacing: bulletSpacing) {
                                    ForEach(entry.bullets, id: \.self) { bullet in
                                        ResumeBullet(bullet, font: bodyFont, color: bodyColor, onSelect: onSelectText)
                                    }
                                }
                                .padding(.top, 2 * scale)
                            }
                            .foregroundStyle(bodyColor)
                        }
                    }
                }
            }

            if !profile.skillCategories.isEmpty {
                section("TECHNICAL SKILLS") {
                    VStack(alignment: .leading, spacing: 2 * scale) {
                        ForEach(profile.skillCategories) { category in
                            (
                                Text("\(category.label): ").fontWeight(.semibold)
                                + Text(category.items.joined(separator: ", "))
                            )
                            .font(bodyFont)
                            .foregroundStyle(bodyColor)
                        }
                    }
                }
            }
        }
        .frame(width: ResumePage.contentWidth, alignment: .leading)
    }

    private var header: some View {
        VStack(spacing: 3 * scale) {
            Text(profile.fullName.isEmpty ? "Your Name" : profile.fullName)
                .font(.custom("Inter", size: nameSize)).fontWeight(.semibold)
                .foregroundStyle(AlineColor.charcoal)
            if !profile.contactLine.isEmpty {
                Text(profile.contactLine)
                    .font(.custom("Inter", size: contactSize))
                    .foregroundStyle(AlineColor.graphite)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 3 * scale) {
            Text(title)
                .font(.custom("Inter", size: headingSize)).fontWeight(.semibold)
                .foregroundStyle(AlineColor.charcoal)
                .padding(.bottom, 1 * scale)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(AlineColor.charcoal).frame(height: 0.75)
                }
            content()
        }
    }
}

#Preview {
    ScrollView {
        StandardResumeTemplate(profile: .preview)
            .padding(ResumePage.margin)
            .frame(width: ResumePage.width)
            .background(Color.white)
    }
}
