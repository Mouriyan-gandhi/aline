import SwiftUI

enum AlineTab: CaseIterable {
    case discover, resume, community, profile

    var label: String {
        switch self {
        case .discover: "Discover"
        case .resume: "Resume"
        case .community: "Community"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .discover: "sparkles"
        case .resume: "doc.text"
        case .community: "person.3"
        case .profile: "person.crop.circle"
        }
    }
}

/// Rebuilt as a genuinely floating Liquid Glass bar (iOS 26+). The earlier version was an
/// edge-to-edge `.ultraThinMaterial` strip flush with the screen bottom — pinned to the safe
/// area with no margin, no distinct shape, so there was nothing for the glass effect to read
/// against; it just looked like a plain translucent fill. Liquid Glass only reads as glass
/// over a shape that's visually discrete from its surroundings, so this is now a capsule
/// inset from every edge. (An earlier version of this file wrapped the bar in
/// `GlassEffectContainer` with per-tab `glassEffectID`s for a morphing selection indicator —
/// verified live on-device/simulator to render the selected tab's glass capsule as an
/// oversized circle detached from the bar instead of a pill behind just that tab, so that's
/// been dropped in favor of applying `glassEffect` directly to a fixed-size shape, which
/// renders correctly.) Falls back to a plain floating material capsule on iOS < 26
/// (deployment target stays 18).
struct AlineTabBar: View {
    @Binding var selected: AlineTab
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AlineTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(AlineColor.cardBorder, lineWidth: 1))
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private static let selectionFeedback = UISelectionFeedbackGenerator()

    /// `AlineFont.sfPro` scales from `UIFontMetrics`' own trait collection directly, not from
    /// SwiftUI's `dynamicTypeSize` environment — so capping that environment value here has no
    /// effect on these labels (verified live: labels kept truncating to 2-3 letters regardless).
    /// The actual fix is the standard iOS pattern for compact chrome: drop the text label
    /// entirely at accessibility sizes and show a slightly larger icon alone, the same thing
    /// Apple's own `UITabBar` does automatically.
    private var showsLabel: Bool { !dynamicTypeSize.isAccessibilitySize }

    @ViewBuilder
    private func tabButton(_ tab: AlineTab) -> some View {
        Button {
            guard selected != tab else { return }
            Self.selectionFeedback.selectionChanged()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon).font(.system(size: showsLabel ? 17 : 20, weight: .semibold))
                if showsLabel {
                    Text(tab.label).font(AlineFont.sfPro(10, weight: .semibold))
                }
            }
            .foregroundStyle(selected == tab ? .white : AlineColor.textPrimary)
            .frame(width: 64, height: 48)
            .background {
                if selected == tab {
                    selectedBackground
                }
            }
            .accessibilityLabel(tab.label)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var selectedBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .frame(width: 64, height: 48)
                .glassEffect(.regular.tint(AlineColor.primary).interactive(), in: .capsule)
        } else {
            Capsule().fill(AlineColor.primary).frame(width: 64, height: 48)
        }
    }
}
