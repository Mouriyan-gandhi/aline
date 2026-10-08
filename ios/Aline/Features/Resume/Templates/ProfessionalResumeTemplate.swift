import SwiftUI

/// Template 2 — "Professional." Same single-column, ATS-safe structure as Standard (no
/// sidebar, no multi-column — a two-column layout was the original design reference, but
/// real ATS parsers routinely scramble multi-column reading order, which would actively
/// hurt the person using it; not worth the visual novelty). Differentiated instead through
/// a bolder header treatment and the app's own Ink Navy accent — reads as "designed" without
/// touching anything that affects parseability.
struct ProfessionalResumeTemplate: View {
    let profile: ResumeProfile
    var scale: CGFloat = 1.0
    var onSelectText: (@MainActor @Sendable (String) -> Void)?

    private var nameSize: CGFloat { 25 * scale }
    private var contactSize: CGFloat { 9.5 * scale }
    private var headingSize: CGFloat { 11.5 * scale }
    private var bodySize: CGFloat { 9.5 * scale }
    private var sectionSpacing: CGFloat { 12 * scale }
    private var entrySpacing: CGFloat { 8 * scale }
    private var bulletSpacing: CGFloat { 2.5 * scale }

    private var bodyFont: Font { .custom("Inter", size: bodySize) }
    private var bodyColor: Color { AlineColor.charcoal }
    private var accent: Color { AlineColor.inkNavy }

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
                            VStack(alignment: .leading, spacing: 1 * scale) {
                                ResumeLineRow(
                                    leading: Text(entry.title).font(.custom("Inter", size: bodySize + 0.5)).fontWeight(.bold),
                                    trailing: Text(entry.dateRange).font(bodyFont).foregroundStyle(AlineColor.stone)
                                )
                                ResumeLineRow(
                                    leading: Text(entry.organization).font(bodyFont).fontWeight(.medium).foregroundStyle(accent),
                                    trailing: Text(entry.location).font(bodyFont).foregroundStyle(AlineColor.stone)
                                )
                                VStack(alignment: .leading, spacing: bulletSpacing) {
                                    ForEach(entry.bullets, id: \.self) { bullet in
                                        ResumeBullet(bullet, font: bodyFont, color: bodyColor, glyph: "▸", onSelect: onSelectText)
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
                            VStack(alignment: .leading, spacing: 1 * scale) {
                                ResumeLineRow(
                                    leading: (
                                        Text(entry.name).fontWeight(.bold)
                                        + Text(entry.techStack.isEmpty ? "" : "  ·  \(entry.techStack)")
                                            .foregroundColor(AlineColor.stone)
                                    )
                                    .font(.custom("Inter", size: bodySize + 0.5)),
                                    trailing: Text(entry.dateRange).font(bodyFont).foregroundStyle(AlineColor.stone)
                                )
                                VStack(alignment: .leading, spacing: bulletSpacing) {
                                    ForEach(entry.bullets, id: \.self) { bullet in
                                        ResumeBullet(bullet, font: bodyFont, color: bodyColor, glyph: "▸", onSelect: onSelectText)
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
                            VStack(alignment: .leading, spacing: 1 * scale) {
                                ResumeLineRow(
                                    leading: Text(entry.institution).font(.custom("Inter", size: bodySize + 0.5)).fontWeight(.bold),
                                    trailing: Text(entry.dateRange).font(bodyFont).foregroundStyle(AlineColor.stone)
                                )
                                ResumeLineRow(
                                    leading: Text(entry.degree).font(bodyFont).foregroundStyle(accent),
                                    trailing: Text(entry.location).font(bodyFont).foregroundStyle(AlineColor.stone)
                                )
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
                    VStack(alignment: .leading, spacing: 3 * scale) {
                        ForEach(profile.skillCategories) { category in
                            (
                                Text("\(category.label)  ").fontWeight(.bold).foregroundColor(accent)
                                + Text(category.items.joined(separator: " · ")).foregroundColor(bodyColor)
                            )
                            .font(bodyFont)
                        }
                    }
                }
            }
        }
        .frame(width: ResumePage.contentWidth, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5 * scale) {
            Text(profile.fullName.isEmpty ? "Your Name" : profile.fullName)
                .font(.custom("Inter", size: nameSize)).fontWeight(.bold)
                .foregroundStyle(accent)
            if !profile.contactLine.isEmpty {
                Text(profile.contactLine)
                    .font(.custom("Inter", size: contactSize))
                    .foregroundStyle(AlineColor.graphite)
            }
            Rectangle().fill(accent).frame(height: 2 * scale)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4 * scale) {
            HStack(spacing: 6 * scale) {
                Rectangle().fill(accent).frame(width: 3 * scale, height: headingSize * 0.8)
                Text(title.uppercased())
                    .font(.custom("Inter", size: headingSize)).fontWeight(.bold)
                    .foregroundStyle(accent)
                    .tracking(0.5)
            }
            content()
        }
    }
}

#Preview {
    ScrollView {
        ProfessionalResumeTemplate(profile: .preview)
            .padding(ResumePage.margin)
            .frame(width: ResumePage.width)
            .background(Color.white)
    }
}
