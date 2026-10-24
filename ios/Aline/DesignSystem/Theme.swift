import SwiftUI

/// Design tokens pulled directly from the real Figma file (fileKey AiSKBBDDO9rIzyUPHmRm98),
/// replacing the earlier "Officevibe" placeholder system built before the actual designs were
/// available. Confirmed from the Home/opportunity-feed screen's real get_design_context
/// output (2026-10-13) — more tokens get added here as more screens are pulled, not invented
/// ahead of time. The brand color is a teal, not blue, and primary text is plain black, not a
/// navy ink tone — both different from the placeholder system's guesses.
enum AlineColor {
    /// The one accent color — primary buttons, active nav/tab state, links, match-ring fill.
    static let primary = Color(hex: 0x236E80)
    /// App background.
    static let canvas = Color(hex: 0xFAF9F7)
    static let paperWhite = Color(hex: 0xFFFFFF)
    /// Card/input hairline borders.
    static let cardBorder = Color(hex: 0xE7E6E2)
    /// "New" / freshness badge fill — confirmed at two opacities in real use (0.9 and 0.6);
    /// expose both rather than picking one arbitrarily.
    static let badgeHighlight = Color(hex: 0xE8FD96).opacity(0.9)
    static let badgeHighlightMuted = Color(hex: 0xE8FD96).opacity(0.6)
    /// Muted icon tint (e.g. the filter/tune icon).
    static let iconMuted = Color(hex: 0x737A7A)
    /// Primary text — plain black in the real designs, not the placeholder system's navy.
    static let textPrimary = Color.black
    /// Secondary/metadata text (location, timestamps) — provisional until confirmed against
    /// more screens; visually close to the real design's secondary gray but not yet pulled
    /// from a token/style definition directly.
    static let textSecondary = Color(hex: 0x6B6B6B)
    /// Text-field / form-input hairline border — slightly darker than `cardBorder` so inputs
    /// read as editable against plain card surfaces.
    static let inputBorder = Color(hex: 0xD8D6D1)
    /// Unselected chip fill (topic/filter/role chips) — the neutral state `primary` selection
    /// is drawn against.
    static let chipUnselected = Color(hex: 0xF0EFEB)

    // MARK: - Deprecated placeholder-system aliases (being phased out screen by screen)
    // Kept temporarily so screens not yet rebuilt from Figma still compile; remove once every
    // call site below has been migrated to the tokens above.
    static let inkNavy = textPrimary
    static let electricCobalt = primary
    static let charcoal = textPrimary
    static let warmCanvas = canvas
    static let creamBorder = cardBorder
    static let graphite = textSecondary
    static let stone = Color(hex: 0x969696)
    static let lavenderMist = badgeHighlightMuted
}

enum AlineRadius {
    static let card: CGFloat = 16
    static let image: CGFloat = 24
}

enum AlineFont {
    /// SF Pro — Apple's system font, used for nearly everything in the real designs
    /// (headings and body alike). This is `San Francisco`, SwiftUI's `.system()` default — no
    /// custom font file needed, unlike the placeholder system's New York + bundled Inter.
    static func sfPro(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Inter — confirmed in real use only for a handful of small/secondary text elements
    /// (badge counts, opportunity counts, search placeholder), not primary headings. Kept
    /// bundled from the placeholder system for these specific cases.
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Inter", size: size).weight(weight)
    }

    // MARK: - Deprecated placeholder-system aliases
    static func display(_ size: CGFloat) -> Font { sfPro(size, weight: .semibold) }
    static func displayItalic(_ size: CGFloat) -> Font { sfPro(size, weight: .semibold).italic() }
    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font { sfPro(size, weight: weight) }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// Reusable card surface — white fill, hairline border, matches the real job-card/promo-card
/// pattern seen across the Figma file.
struct PaperCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(AlineColor.paperWhite)
            .clipShape(RoundedRectangle(cornerRadius: AlineRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AlineRadius.card, style: .continuous)
                    .stroke(AlineColor.cardBorder, lineWidth: 1)
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

/// Primary pill button style — brand teal fill, flat (color carries the weight, no shadow).
struct AlinePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AlineFont.sfPro(16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AlineColor.primary)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Floating action button style built on real Liquid Glass (iOS 26+): a genuinely discrete,
/// circular glass surface, tinted with the brand color and `.interactive()` so it responds to
/// touch the way system glass controls do. Liquid Glass only reads as "glass" over a shape
/// that's visually separated from its surroundings — flush/edge-to-edge glass just looks like
/// a flat tinted fill — so this is always used floating over content (e.g. Community's compose
/// button), never flush against an edge. Falls back to a plain tinted-material circle on
/// iOS < 26 since the deployment target is 18.
struct GlassFABStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                configuration.label
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .glassEffect(.regular.tint(AlineColor.primary).interactive(), in: .circle)
            } else {
                configuration.label
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(AlineColor.primary, in: .circle)
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            }
        }
        .scaleEffect(configuration.isPressed ? 0.93 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
