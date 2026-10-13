import SwiftUI

/// The real Figma design's bottom nav is Material 3's standard "Navigation Bar: Vertical
/// items" component — icon above label for every tab, with a filled teal pill indicator
/// behind just the icon (not the label) on the selected tab. Not the plain SwiftUI TabView
/// look (color-only selection, no indicator shape), so this is a custom bar +
/// manual content-switching in RootTabView rather than `.tabItem`.
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

struct AlineTabBar: View {
    @Binding var selected: AlineTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AlineTab.allCases, id: \.self) { tab in
                Button {
                    selected = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 17))
                            .foregroundStyle(selected == tab ? .white : AlineColor.textPrimary)
                            .frame(width: 44, height: 26)
                            .background(selected == tab ? AlineColor.primary : Color.clear)
                            .clipShape(Capsule())
                        Text(tab.label)
                            .font(AlineFont.sfPro(11, weight: .semibold))
                            .foregroundStyle(AlineColor.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(AlineColor.cardBorder).frame(height: 1)
        }
    }
}
