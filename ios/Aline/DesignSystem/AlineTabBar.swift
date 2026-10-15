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
/// inset from every edge, with `GlassEffectContainer` + per-tab `glassEffectID` so the
/// selection indicator morphs between tabs instead of just cross-fading. Falls back to a
/// plain floating material capsule on iOS < 26 (deployment target stays 18).
struct AlineTabBar: View {
    @Binding var selected: AlineTab
    @Namespace private var glassNamespace

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 12) {
                    barContent
                }
            } else {
                barContent
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(AlineColor.cardBorder, lineWidth: 1))
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var barContent: some View {
        HStack(spacing: 4) {
            ForEach(AlineTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
    }

    @ViewBuilder
    private func tabButton(_ tab: AlineTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon).font(.system(size: 17, weight: .semibold))
                Text(tab.label).font(AlineFont.sfPro(10, weight: .semibold))
            }
            .foregroundStyle(selected == tab ? .white : AlineColor.textPrimary)
            .frame(width: 64, height: 48)
        }
        .buttonStyle(.plain)
        .modifier(TabGlassModifier(isSelected: selected == tab, namespace: glassNamespace, tab: tab))
    }
}

/// Isolated as its own ViewModifier because the real `glassEffectID` call requires a concrete
/// `Namespace.ID` and an `@available(iOS 26.0, *)` type context that doesn't play well written
/// inline inside a `@ViewBuilder` if/else without repeating the whole label view twice.
private struct TabGlassModifier: ViewModifier {
    let isSelected: Bool
    let namespace: Namespace.ID
    let tab: AlineTab

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.clear)
                            .glassEffect(.regular.tint(AlineColor.primary).interactive(), in: .capsule)
                            .glassEffectID(tab, in: namespace)
                    }
                }
        } else {
            content
                .background(isSelected ? AlineColor.primary : Color.clear, in: .capsule)
        }
    }
}
