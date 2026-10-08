import SwiftUI

/// Shared structural primitives reused by all three templates — the row shape (leading text,
/// trailing text, both on one baseline) and bullet layout are the same across templates by
/// construction (it's what single-column, ATS-safe resume layout actually looks like); only
/// the font/weight/color applied to them differs per template, which stays owned by each
/// template file, not here.
struct ResumeLineRow: View {
    let leading: Text
    let trailing: Text

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            leading
            Spacer(minLength: 8)
            trailing
        }
    }
}

/// A single bullet line with a hanging indent — the bullet glyph sits in its own fixed-width
/// column so wrapped second lines align under the text, not under the bullet.
///
/// `onSelect`, when provided, makes the whole line tappable — the View Resume screen uses
/// this to drive "Edit with AI" at line granularity (tap a bullet → it becomes the selected
/// text for an AI rewrite) rather than true freeform character-range selection, which would
/// need a from-scratch rich-text engine instead of these composed SwiftUI Text views. Nil in
/// every other context (PDF export, template picker thumbnails) where tapping means nothing.
struct ResumeBullet: View {
    let text: String
    let font: Font
    let color: Color
    let glyph: String
    let indent: CGFloat
    let spacing: CGFloat
    var onSelect: (@MainActor @Sendable (String) -> Void)?

    init(
        _ text: String, font: Font, color: Color, glyph: String = "•",
        indent: CGFloat = 12, spacing: CGFloat = 4, onSelect: (@MainActor @Sendable (String) -> Void)? = nil
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.glyph = glyph
        self.indent = indent
        self.spacing = spacing
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            Text(glyph).font(font).foregroundStyle(color).frame(width: indent, alignment: .leading)
            Text(text).font(font).foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .contentShape(Rectangle())
        .if(onSelect != nil) { view in
            view
                .background(AlineColor.lavenderMist.opacity(0.001)) // keeps full-row tap target without a visible fill
                .onTapGesture { onSelect?(text) }
        }
    }
}

extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition { transform(self) } else { self }
    }
}

extension ResumeProfile {
    /// Dummy preview content — same shape as the "Jake Ryan" reference content, but original
    /// text, used only for template preview thumbnails and SwiftUI previews, never shipped
    /// as a real user's data.
    static let preview = ResumeProfile(
        fullName: "Aarav Sharma",
        phone: "+91 98765 43210",
        email: "aarav.sharma@email.com",
        linkedInURL: "linkedin.com/in/aaravsharma",
        githubURL: "github.com/aaravsharma",
        portfolioURL: "",
        summary: "",
        education: [
            EducationEntry(
                institution: "Indian Institute of Technology, Bombay",
                degree: "B.Tech in Computer Science and Engineering",
                location: "Mumbai, MH",
                dateRange: "Aug 2022 – May 2026",
                detail: "CGPA: 8.9/10"
            )
        ],
        experience: [
            ExperienceEntry(
                title: "Software Engineering Intern",
                organization: "Flipkart",
                location: "Bengaluru, KA",
                dateRange: "May 2025 – Jul 2025",
                bullets: [
                    "Built a REST API in FastAPI serving 50K+ daily requests for the seller analytics dashboard",
                    "Reduced p95 query latency by 38% by adding Redis caching and rewriting two N+1 ORM queries",
                    "Wrote integration tests raising backend coverage from 61% to 84%",
                ]
            )
        ],
        projects: [
            ProjectEntry(
                name: "CampusConnect",
                techStack: "React, Node.js, PostgreSQL, Docker",
                dateRange: "Jan 2025 – Present",
                bullets: [
                    "Built a full-stack event platform used by 1,200+ students across 3 campuses",
                    "Implemented OAuth login and role-based access control for student/organizer accounts",
                ]
            )
        ],
        skillCategories: [
            SkillCategory(label: "Languages", items: ["Python", "Java", "JavaScript", "SQL"]),
            SkillCategory(label: "Frameworks", items: ["React", "FastAPI", "Node.js", "Spring Boot"]),
            SkillCategory(label: "Developer Tools", items: ["Git", "Docker", "AWS", "VS Code"]),
        ]
    )
}
