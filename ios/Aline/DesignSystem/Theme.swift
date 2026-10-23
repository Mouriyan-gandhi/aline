import SwiftUI

/// iOS 26/27 native design system, built on Apple's own semantic color roles plus three brand
/// colors pulled directly from the Aline logo (vivid cyan-blue, soft lavender, sparkle yellow).
/// Generic roles (text, backgrounds, separators) resolve to Apple's semantic `UIColor`-backed
/// colors — `Color(.label)`, `.systemBackground`, etc. — so dark mode and Increase Contrast
/// adapt automatically, for free, rather than hand-maintaining light/dark hex pairs for things
/// that were never actually brand colors. Only the three true brand colors are custom, and they
/// live in Assets.xcassets as Color Sets (light + dark appearance) rather than Swift literals —
/// the only way "Increase Contrast" affects them automatically too.
enum AlineColor {
    /// The logo's vivid cyan-blue. Primary buttons, selected tab/pill glass tint, match ring,
    /// links — the one color that should always read as "this is Aline."
    static let primary = Color("BrandPrimary")
    /// The logo's soft lavender cape. Secondary accent, gradient partner to `primary`,
    /// decorative glass tints.
    static let accent = Color("BrandAccent")
    /// The logo's sparkle yellow. Reserved ONLY for genuine signal moments — a fresh posting,
    /// a standout (>85%) match, the sparkle motif itself — never general UI chrome, so it stays
    /// special rather than becoming "just another color."
    static let spark = Color("BrandSpark")

    /// App background — the canvas cards sit on top of.
    static let canvas = Color(.systemGroupedBackground)
    /// Card/sheet surface — elevated above `canvas`.
    static let paperWhite = Color(.secondarySystemGroupedBackground)
    /// Card/list hairline borders.
    static let cardBorder = Color(.separator)
    /// Text-field / form-input border — a touch more visible than a hairline separator so
    /// inputs read as editable against plain card surfaces.
    static let inputBorder = Color(.opaqueSeparator)
    /// Unselected chip/pill fill — the neutral state brand-colored selection is drawn against.
    static let chipUnselected = Color(.tertiarySystemFill)
    /// Muted icon tint (e.g. the filter/tune icon).
    static let iconMuted = Color.secondary
    /// Primary text. SwiftUI's own native `Color.primary` rather than a `UIColor.label`
    /// bridge — verified live that the UIColor-bridged form rendered visibly washed out
    /// (nowhere near the guaranteed-black status bar text) on this iOS 27 SDK/Simulator
    /// combination, while the native SwiftUI semantic renders correctly at full contrast.
    static let textPrimary = Color.primary
    /// Secondary/metadata text (location, timestamps) — see `textPrimary`'s note.
    static let textSecondary = Color.secondary

    /// "New" / freshness badge fill — `spark` for genuinely new, a separate muted tone for
    /// "still recent but fading." `badgeHighlightMuted` is its own Asset Catalog color rather
    /// than `spark.opacity(_:)` — verified live that a low-alpha yellow blends into a muddy
    /// olive-brown against a dark card in dark mode (it's compositing with whatever's behind
    /// it, which is fine on a light card and wrong on a dark one); a real color with its own
    /// tuned light/dark appearance stays legibly yellow in both.
    static let badgeHighlight = spark.opacity(0.9)
    static let badgeHighlightMuted = Color("BrandSparkMuted")

    // MARK: - Pre-redesign aliases (Phase 2 screens — Resume/Community/Profile — still use
    // these names until their own redesign pass). Repointed to the new semantic/brand tokens
    // so those screens already pick up dark mode and the real brand palette even before their
    // view code is touched directly.
    static let inkNavy = textPrimary
    static let electricCobalt = primary
    static let charcoal = textPrimary
    static let warmCanvas = canvas
    static let creamBorder = cardBorder
    static let graphite = textSecondary
    // SwiftUI has no native `Color.tertiary` (only a `ShapeStyle` of that name, which can't be
    // stored as a `Color`) — approximated from the now-verified-correct native `.secondary`
    // rather than the UIColor-bridged `.tertiaryLabel`, which showed the same washed-out
    // rendering as `.label`/`.secondaryLabel` did before the fix above.
    static let stone = textSecondary.opacity(0.75)
    static let lavenderMist = accent.opacity(0.25)
}

enum AlineRadius {
    static let card: CGFloat = 16
    static let image: CGFloat = 24
}

enum AlineFont {
    /// SF Pro at a custom base size that still genuinely scales with the user's Dynamic Type
    /// setting — `Font.system(size:weight:)` alone is fixed-pixel and never scales, a real
    /// accessibility gap in the pre-redesign system. Built on `UIFontMetrics` so every existing
    /// call site (`AlineFont.sfPro(16, weight: .semibold)`) keeps its current relative
    /// proportions but now actually grows under Larger Text / accessibility sizes.
    static func sfPro(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let base = UIFont.systemFont(ofSize: size, weight: weight.uiFontWeight)
        return Font(UIFontMetrics(forTextStyle: .body).scaledFont(for: base))
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

private extension Font.Weight {
    /// SwiftUI's `Font.Weight` has no public bridge to `UIFont.Weight` — needed for
    /// `UIFontMetrics` scaling in `AlineFont.sfPro`.
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .black: .black
        case .heavy: .heavy
        case .bold: .bold
        case .semibold: .semibold
        case .medium: .medium
        case .regular: .regular
        case .light: .light
        case .thin: .thin
        case .ultraLight: .ultraLight
        default: .regular
        }
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// Manual linear RGB interpolation toward another color — used by `BrandMeshHero` to derive
    /// in-between mesh-gradient stops from the two brand colors. Built on `UIColor` component
    /// extraction rather than a newer `ShapeStyle.mix`-style API, so it works reliably at this
    /// project's deployment target without an availability gate.
    func lerp(to other: Color, amount: Double) -> Color {
        let a = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let b = UIColor(other).cgColor.components ?? [0, 0, 0, 1]
        func mix(_ i: Int) -> Double {
            let from = Double(i < a.count ? a[i] : a[0])
            let to = Double(i < b.count ? b[i] : b[0])
            return from + (to - from) * amount
        }
        return Color(red: mix(0), green: mix(1), blue: mix(2))
    }
}

/// Reusable card surface — elevated fill, hairline border, matches the real job-card/promo-card
/// pattern seen across the app.
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

/// Primary pill button style — brand fill, flat (color carries the weight, no shadow).
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

/// Small circular icon-button chrome (filter button, notification bell, etc.) — Liquid Glass on
/// iOS 26+, a flat tinted circle with a hairline border on older OS. Pulled out as its own
/// modifier since this exact "floating glass circle" pattern recurs across several toolbar-style
/// icon buttons, not just one screen.
struct GlassCircleBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: .circle)
        } else {
            content
                .background(AlineColor.paperWhite, in: .circle)
                .overlay(Circle().stroke(AlineColor.cardBorder, lineWidth: 1))
        }
    }
}

/// Selected-state chrome for a mode/segment pill (e.g. Discover's Recommended/Liked/Applied
/// row) — the same "glass pill behind the selected control" language as the tab bar's own
/// selected state, so the two recurring selection patterns in the app read as one system.
struct ModePillBackground: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isSelected, #available(iOS 26.0, *) {
            content.glassEffect(.regular.tint(AlineColor.primary).interactive(), in: .capsule)
        } else if isSelected {
            content.background(AlineColor.primary, in: .capsule)
        } else {
            content
                .background(AlineColor.paperWhite, in: .capsule)
                .overlay(Capsule().stroke(AlineColor.cardBorder, lineWidth: 1))
        }
    }
}

/// Shared gradient match-ring, used at small size on job cards and at hero size on Job Detail —
/// one component so both places move together if the match visualization ever changes. The
/// stroke sweeps `primary → accent`, echoing the logo's own gradient treatment, rather than a
/// flat single-color ring.
struct BrandMatchRing: View {
    let score: Int
    var diameter: CGFloat = 44
    var lineWidth: CGFloat = 4
    var showsLabel: Bool = true

    var body: some View {
        ZStack {
            Circle().stroke(AlineColor.cardBorder, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: Double(max(0, min(score, 100))) / 100)
                .stroke(
                    AngularGradient(
                        colors: [AlineColor.primary, AlineColor.accent, AlineColor.primary],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            if showsLabel {
                VStack(spacing: 0) {
                    Text("\(score)%").font(AlineFont.sfPro(diameter * 0.23, weight: .bold))
                    Text("Match").font(AlineFont.sfPro(diameter * 0.16))
                }
                .foregroundStyle(AlineColor.textPrimary)
                .minimumScaleFactor(0.7)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(score) percent match")
    }
}

/// Shared empty/error-state layout — a brand-tinted icon, a title, and a short message —
/// replacing bare `ProgressView`/plain-text gaps with something that still feels designed
/// rather than a blank hole in the layout.
struct BrandEmptyState: View {
    var icon: String = "sparkle"
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AlineColor.primary)
                .frame(width: 56, height: 56)
                .background(AlineColor.primary.opacity(0.1), in: .circle)
            Text(title)
                .font(AlineFont.sfPro(15, weight: .semibold))
                .foregroundStyle(AlineColor.textPrimary)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(AlineFont.sfPro(13))
                    .foregroundStyle(AlineColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
    }
}

/// A soft `primary → accent` mesh, echoing the logo's own glossy gradient treatment — used on
/// hero/banner moments (e.g. Discover's header card) in place of a flat brand-color fill.
/// `MeshGradient` is an iOS 18+ API, safely inside this project's 18.0 deployment target.
struct BrandMeshHero: View {
    var body: some View {
        let c0 = AlineColor.primary
        let c1 = AlineColor.accent
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ],
            colors: [
                c0, c0.lerp(to: c1, amount: 0.35), c1.lerp(to: c0, amount: 0.2),
                c0.lerp(to: .black, amount: 0.08), c0.lerp(to: c1, amount: 0.5), c1,
                c0, c0.lerp(to: c1, amount: 0.65), c1.lerp(to: .white, amount: 0.1),
            ]
        )
    }
}
