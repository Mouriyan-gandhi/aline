import SwiftUI

/// Template 3 — "Modern." Still single-column/ATS-safe like the other two; differentiated
/// through whitespace and weight contrast rather than rules or color blocks — light section
/// labels, generous spacing, a restrained electric-cobalt touch only on the name. Best suited
/// to product/startup-leaning applications where a slightly less formal read is appropriate.
struct ModernResumeTemplate: View {
    let profile: ResumeProfile
    var scale: CGFloat = 1.0
    var onSelectText: (@MainActor @Sendable (String) -> Void)?

    private var nameSize: CGFloat { 24 * scale }
    private var contactSize: CGFloat { 9 * scale }
    private var headingSize: CGFloat { 10 * scale }
    private var bodySize: CGFloat { 9.5 * scale }
    private var sectionSpacing: CGFloat { 16 * scale }
    private var entrySpacing: CGFloat { 10 * scale }
    private var bulletSpacing: CGFloat { 3 * scale }

    private var bodyFont: Font { .custom("Inter", size: bodySize) }
    private var bodyColor: Color { AlineColor.graphite }
    private var accent: Color { AlineColor.electricCobalt }

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            header

            if !profile.summary.isEmpty {
                Text(profile.summary).font(bodyFont).foregroundStyle(bodyColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !profile.experience.isEmpty {
                section("Experience") {
                    VStack(alignment: .leading, spacing: entrySpacing) {
                        ForEach(profile.experience) { entry in
                            VStack(alignment: .leading, spacing: 2 * scale) {
                                ResumeLineRow(
                                    leading: Text(entry.title).font(.custom("Inter", size: bodySize)).fontWeight(.semibold),
                                    trailing: Text(entry.dateRange).font(.custom("Inter", size: contactSize)).foregroundStyle(AlineColor.stone)
                                )
                                .foregroundStyle(AlineColor.charcoal)
                                Text("\(entry.organization)   —   \(entry.location)")
                                    .font(.custom("Inter", size: contactSize))
                                    .foregroundStyle(AlineColor.stone)
                                VStack(alignment: .leading, spacing: bulletSpacing) {
                                    ForEach(entry.bullets, id: \.self) { bullet in
                                        ResumeBullet(bullet, font: bodyFont, color: bodyColor, glyph: "—", indent: 14, onSelect: onSelectText)
                                    }
                                }
                                .padding(.top, 3 * scale)
                            }
                        }
                    }
                }
            }

            if !profile.projects.isEmpty {
                section("Projects") {
                    VStack(alignment: .leading, spacing: entrySpacing) {
                        ForEach(profile.projects) { entry in
                            VStack(alignment: .leading, spacing: 2 * scale) {
                                ResumeLineRow(
                                    leading: Text(entry.name).font(.custom("Inter", size: bodySize)).fontWeight(.semibold)
                                        .foregroundStyle(AlineColor.charcoal),
                                    trailing: Text(entry.dateRange).font(.custom("Inter", size: contactSize)).foregroundStyle(AlineColor.stone)
                                )
                                if !entry.techStack.isEmpty {
                                    Text(entry.techStack)
                                        .font(.custom("Inter", size: contactSize))
                                        .foregroundStyle(AlineColor.stone)
                                }
                                VStack(alignment: .leading, spacing: bulletSpacing) {
                                    ForEach(entry.bullets, id: \.self) { bullet in
                                        ResumeBullet(bullet, font: bodyFont, color: bodyColor, glyph: "—", indent: 14, onSelect: onSelectText)
                                    }
                                }
                                .padding(.top, 3 * scale)
                            }
                        }
                    }
                }
            }

            if !profile.education.isEmpty {
                section("Education") {
                    VStack(alignment: .leading, spacing: entrySpacing) {
                        ForEach(profile.education) { entry in
                            VStack(alignment: .leading, spacing: 2 * scale) {
                                ResumeLineRow(
                                    leading: Text(entry.institution).font(.custom("Inter", size: bodySize)).fontWeight(.semibold)
                                        .foregroundStyle(AlineColor.charcoal),
                                    trailing: Text(entry.dateRange).font(.custom("Inter", size: contactSize)).foregroundStyle(AlineColor.stone)
                                )
                                Text("\(entry.degree)   —   \(entry.location)")
                                    .font(.custom("Inter", size: contactSize))
                                    .foregroundStyle(AlineColor.stone)
                                if !entry.detail.isEmpty {
                                    Text(entry.detail).font(bodyFont).foregroundStyle(bodyColor)
                                }
                            }
                        }
                    }
                }
            }

            if !profile.skillCategories.isEmpty {
                section("Skills") {
                    VStack(alignment: .leading, spacing: 6 * scale) {
                        ForEach(profile.skillCategories) { category in
                            VStack(alignment: .leading, spacing: 2 * scale) {
                                Text(category.label.uppercased())
                                    .font(.custom("Inter", size: contactSize)).fontWeight(.medium)
                                    .foregroundStyle(AlineColor.stone)
                                    .tracking(0.8)
                                Text(category.items.joined(separator: ", "))
                                    .font(bodyFont)
                                    .foregroundStyle(AlineColor.charcoal)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: ResumePage.contentWidth, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6 * scale) {
            Text(profile.fullName.isEmpty ? "Your Name" : profile.fullName)
                .font(.custom("Inter", size: nameSize)).fontWeight(.light)
                .foregroundStyle(accent)
            if !profile.contactLine.isEmpty {
                Text(profile.contactLine)
                    .font(.custom("Inter", size: contactSize))
                    .foregroundStyle(AlineColor.stone)
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8 * scale) {
            Text(title.uppercased())
                .font(.custom("Inter", size: headingSize)).fontWeight(.medium)
                .foregroundStyle(AlineColor.stone)
                .tracking(1.5)
            content()
        }
    }
}

#Preview {
    ScrollView {
        ModernResumeTemplate(profile: .preview)
            .padding(ResumePage.margin)
            .frame(width: ResumePage.width)
            .background(Color.white)
    }
}
