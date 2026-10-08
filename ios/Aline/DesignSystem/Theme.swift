import SwiftUI

/// Officevibe-derived design tokens (see plan: "Visual design system"). Warm editorial
/// canvas, two-blue system, New York serif for display + Inter for everything else —
/// free fonts only, no licensing the reference's paid foundry fonts.
enum AlineColor {
    static let inkNavy = Color(hex: 0x0C1754)
    static let electricCobalt = Color(hex: 0x2545FF)
    static let charcoal = Color(hex: 0x171417)
    static let warmCanvas = Color(hex: 0xF9F8F6)
    static let paperWhite = Color(hex: 0xFFFFFF)
    static let creamBorder = Color(hex: 0xF0E9E1)
    static let graphite = Color(hex: 0x222222)
    static let stone = Color(hex: 0x969696)
    static let lavenderMist = Color(hex: 0xEAEBF8)
}

enum AlineRadius {
    static let card: CGFloat = 16
    static let image: CGFloat = 24
}

enum AlineFont {
    /// Display serif with an italic accent — New York, Apple's built-in serif, free.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func displayItalic(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif).italic()
    }

    /// "Inter" is bundled as a single variable-font file (see Resources/Fonts/Inter.ttf);
    /// SwiftUI applies `.weight()` as synthetic styling on top of the font's default instance.
    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .custom("Inter", size: size).weight(weight)
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// Reusable "paper card" surface — flat Officevibe-style card, not Liquid Glass.
/// Liquid Glass stays scoped to system chrome (nav bars/toolbars/sheets) per the plan.
struct PaperCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(AlineColor.paperWhite)
            .clipShape(RoundedRectangle(cornerRadius: AlineRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AlineRadius.card, style: .continuous)
                    .stroke(AlineColor.creamBorder, lineWidth: 1)
            )
    }
}

/// Wrapping row of variable-width chips (e.g. a job's full skill list, which — unlike the
/// fixed 4-skill preview on a job card — can run past one line's width). A plain HStack would
/// just push items off-screen instead of wrapping.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : rowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: origin, proposal: .unspecified)
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Primary pill button style — Electric Cobalt fill, flat (color carries the weight, no shadow).
struct AlinePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AlineFont.body(16, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AlineColor.electricCobalt)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
