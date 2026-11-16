import SwiftUI

// MARK: - Keyboard Dismissal
/// Single-line text fields: the return key submits and closes the keyboard.
private struct AlineKeyboardDismissal: ViewModifier {
    let label: SubmitLabel
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .submitLabel(label)
            .onSubmit { isFocused = false }
    }
}

public extension View {
    func alineKeyboardDismissal(_ label: SubmitLabel = .done) -> some View {
        modifier(AlineKeyboardDismissal(label: label))
    }
}

// MARK: - Floating Tab Bar (Custom Glass Navigation Bar)
public struct FloatingTabBar: View {
    @Binding public var currentTab: AppTab
    @Namespace private var tabAnimation

    public init(currentTab: Binding<AppTab>) {
        self._currentTab = currentTab
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = currentTab == tab
                Button {
                    withAnimation(AlineTheme.tabSpring) {
                        currentTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 17, weight: isSelected ? .bold : .medium))

                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary.opacity(0.72))
                    .frame(width: 68, height: 50)
                    .background(
                        Group {
                            if isSelected {
                                Capsule()
                                    .fill(AlineTheme.pillDark)
                                    .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
                                    .matchedGeometryEffect(id: "activeTabBubble", in: tabAnimation)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            ZStack {
                // Frosted ultra-thin glass material with background blur
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .light)

                // Translucent milky white tint for luminous glass depth
                Capsule()
                    .fill(Color.white.opacity(0.85))

                // Refractive specular highlight border
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.70),
                                Color.white.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 7)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Liquid Glass Shape Helpers (iOS 17+ compatible with ultraThinMaterial & native fallback)
@available(iOS 26.0, *)
private func alineGlass(selected: Bool, tint: Color, interactive: Bool) -> Glass {
    var glass = Glass.regular
    if selected { glass = glass.tint(tint) }
    return glass
}

public extension View {
    @ViewBuilder
    func alineGlassCapsule(selected: Bool = false, tint: Color = AlineTheme.pillDark, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            background(selected ? tint : Color.clear, in: Capsule())
                .glassEffect(alineGlass(selected: selected, tint: tint, interactive: interactive), in: Capsule())
        } else {
            background(
                Capsule()
                    .fill(selected ? tint : Color.white.opacity(0.88))
            )
            .overlay(
                Capsule()
                    .stroke(selected ? Color.clear : Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
    }

    @ViewBuilder
    func alineGlassCircle(selected: Bool = false, tint: Color = AlineTheme.pillDark, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            background(selected ? tint : Color.clear, in: Circle())
                .glassEffect(alineGlass(selected: selected, tint: tint, interactive: interactive), in: Circle())
        } else {
            background(
                Circle()
                    .fill(selected ? tint : Color.white.opacity(0.88))
            )
            .overlay(
                Circle()
                    .stroke(selected ? Color.clear : Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
    }

    @ViewBuilder
    func alineGlassCircleButton() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: Circle())
        } else {
            self.background(
                Circle()
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
    }

    @ViewBuilder
    func alineGlassPill() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: Capsule())
        } else {
            self.background(
                Capsule()
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
    }

    @ViewBuilder
    func alineGlassProminentButton() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(AlineTheme.pillDark)
        } else {
            self.buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(AlineTheme.pillDark)
        }
    }
}

// MARK: - Search Field (glass capsule + glass cancel button, compatible with iOS 17+)
public struct AlineSearchField: View {
    public let placeholder: String
    @Binding public var text: String
    @Binding public var isActive: Bool
    /// Puts the cursor in the field as soon as it appears (for search bars revealed by a button)
    public var focusOnAppear: Bool = false
    @FocusState private var focused: Bool

    public init(_ placeholder: String, text: Binding<String>, isActive: Binding<Bool> = .constant(false), focusOnAppear: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self._isActive = isActive
        self.focusOnAppear = focusOnAppear
    }

    public var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AlineTheme.inkSecondary)

                TextField(
                    "",
                    text: $text,
                    prompt: Text(placeholder).foregroundColor(AlineTheme.inkSecondary)
                )
                    .font(.system(size: 16))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .tint(AlineTheme.inkPrimary)
                    .focused($focused)
                    .submitLabel(.search)
                    .onSubmit { focused = false }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AlineTheme.inkMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .alineGlassPill()

            if focused {
                Button {
                    text = ""
                    focused = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AlineTheme.inkPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .alineGlassCircleButton()
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .environment(\.colorScheme, .light)
        .animation(AlineTheme.fastSpring, value: focused)
        .onChange(of: focused) { _, newValue in isActive = newValue }
        .onAppear { if focusOnAppear { focused = true } }
    }
}

// MARK: - Google 4-Color 'G' Canvas View (Matching Official Brand Geometry)
public struct GoogleGView: View {
    public let size: CGFloat
    
    public init(size: CGFloat = 28) {
        self.size = size
    }
    
    public var body: some View {
        Canvas { context, sz in
            let center = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let radius = sz.width * 0.42
            let strokeWidth = sz.width * 0.21
            
            // Red top arc
            var redPath = Path()
            redPath.addArc(center: center, radius: radius, startAngle: .degrees(-45), endAngle: .degrees(-180), clockwise: true)
            context.stroke(redPath, with: .color(Color(red: 0.92, green: 0.26, blue: 0.21)), lineWidth: strokeWidth)
            
            // Yellow bottom-left arc
            var yellowPath = Path()
            yellowPath.addArc(center: center, radius: radius, startAngle: .degrees(-180), endAngle: .degrees(-245), clockwise: true)
            context.stroke(yellowPath, with: .color(Color(red: 0.98, green: 0.74, blue: 0.02)), lineWidth: strokeWidth)
            
            // Green bottom arc
            var greenPath = Path()
            greenPath.addArc(center: center, radius: radius, startAngle: .degrees(-245), endAngle: .degrees(-330), clockwise: true)
            context.stroke(greenPath, with: .color(Color(red: 0.20, green: 0.66, blue: 0.33)), lineWidth: strokeWidth)
            
            // Blue right arc
            var bluePath = Path()
            bluePath.addArc(center: center, radius: radius, startAngle: .degrees(-330), endAngle: .degrees(-360), clockwise: true)
            context.stroke(bluePath, with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)), lineWidth: strokeWidth)
            
            // Blue crossbar
            var barPath = Path()
            barPath.move(to: CGPoint(x: center.x - sz.width * 0.02, y: center.y))
            barPath.addLine(to: CGPoint(x: center.x + radius + strokeWidth * 0.32, y: center.y))
            context.stroke(barPath, with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)), lineWidth: strokeWidth * 0.95)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Company Brand Logo Asset Resolver
/// Logo asset by company name. Matched on the name's leading word(s) — "JPMorgan Chase & Co."
/// → jpmorgan, "Jane Street" → janestreet — not by substring, which mislabels real employers
/// ("Morgan Stanley" isn't JPMorgan, "Motorola" isn't Ola, "Intellect Design" isn't Intel).
private let companyLogoAssets: [String: String] = [
    "apple": "company_apple",
    "google": "company_google",
    "flipkart": "company_flipkart",
    "ola": "company_ola",
    "microsoft": "company_microsoft",
    "meta": "company_meta",
    "facebook": "company_facebook",
    "amazon": "company_amazon",
    "netflix": "company_netflix",
    "spotify": "company_spotify",
    "uber": "company_uber",
    "airbnb": "company_airbnb",
    "swiggy": "company_swiggy",
    "zomato": "company_zomato",
    "cred": "company_cred",
    "razorpay": "company_razorpay",
    "phonepe": "company_phonepe",
    "stripe": "company_stripe",
    "figma": "company_figma",
    "notion": "company_notion",
    "github": "company_github",
    "openai": "company_openai",
    "anthropic": "company_anthropic",
    "databricks": "company_databricks",
    "snowflake": "company_snowflake",
    "nvidia": "company_nvidia",
    "linear": "company_linear",
    "adobe": "company_adobe",
    "canva": "company_canva",
    "atlassian": "company_atlassian",
    "goldman": "company_goldmansachs",
    "jpmorgan": "company_jpmorgan",
    "citadel": "company_citadel",
    "zepto": "company_zepto",
    "janestreet": "company_janestreet",
    "meesho": "company_meesho",
    "groww": "company_groww",
    "zerodha": "company_zerodha",
    "discord": "company_discord",
    "duolingo": "company_duolingo",
    "linkedin": "company_linkedin",
    "salesforce": "company_salesforce",
    "cloudflare": "company_cloudflare",
    "supabase": "company_supabase",
    "vercel": "company_vercel",
    "browserstack": "company_browserstack",
    "retool": "company_retool",
    "hasura": "company_hasura",
    "postman": "company_postman",
    "palantir": "company_palantir",
    "cisco": "company_cisco",
    "intel": "company_intel",
    "amd": "company_amd",
]

public func companyLogoAsset(for companyName: String) -> String? {
    let words = companyName.lowercased()
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { !$0.isEmpty }
    guard let first = words.first else { return nil }
    let candidates = [first, words.prefix(2).joined(), words.prefix(3).joined()]
    return candidates.lazy.compactMap { companyLogoAssets[$0] }.first
}

// MARK: - Company Brand Logo Component (Authentic Image Assets from Reference Sheets)
public struct CompanyLogoBadge: View {
    public let companyName: String
    public let size: CGFloat
    public let isSquircle: Bool

    public init(companyName: String, size: CGFloat = 48, isSquircle: Bool = true) {
        self.companyName = companyName
        self.size = size
        self.isSquircle = isSquircle
    }

    public var body: some View {
        if let assetName = companyLogoAsset(for: companyName) {
            ZStack {
                if isSquircle {
                    Image(assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                } else {
                    Image(assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                }
            }
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        } else {
            let lower = companyName.lowercased().replacingOccurrences(of: " ", with: "")
            if lower.contains("tcs") || lower.contains("tata") {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .fill(Color.white)
                        .frame(width: size, height: size)
                        .overlay(
                            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                    Text("tcs")
                        .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                        .foregroundColor(Color(white: 0.22))
                }
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            } else if lower.contains("infosys") {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .fill(Color.white)
                        .frame(width: size, height: size)
                        .overlay(
                            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                    Text("Infosys")
                        .font(.system(size: size * 0.24, weight: .heavy, design: .default))
                        .foregroundColor(Color(red: 0.05, green: 0.44, blue: 0.78))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color(red: 0.05, green: 0.44, blue: 0.78).opacity(0.4), lineWidth: 0.8)
                        )
                }
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            } else if lower.contains("wells") {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .fill(Color(red: 0.78, green: 0.08, blue: 0.12))
                        .frame(width: size, height: size)
                    VStack(spacing: 0.5) {
                        Text("WELLS")
                            .font(.system(size: size * 0.19, weight: .black, design: .serif))
                        Text("FARGO")
                            .font(.system(size: size * 0.19, weight: .black, design: .serif))
                    }
                    .foregroundColor(.white)
                }
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            } else {
                // Fallback for unlisted companies
                ZStack {
                    if isSquircle {
                        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                            .fill(Color.white)
                            .frame(width: size, height: size)
                            .overlay(
                                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                    } else {
                        Circle()
                            .fill(Color.white)
                            .frame(width: size, height: size)
                            .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
                    }

                    Text(String(companyName.prefix(1)).uppercased())
                        .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            }
        }
    }
}

// MARK: - Stacked Opportunity Card (Matching Screenshot Format)
public struct StackedOpportunityCard: View {
    public let opportunity: Opportunity
    public let isExpanded: Bool
    public let isHighlighted: Bool
    public let onSelect: () -> Void
    public let onOpenDetail: () -> Void
    public let onLike: () -> Void

    public init(
        opportunity: Opportunity,
        isExpanded: Bool = true,
        isHighlighted: Bool = false,
        onSelect: @escaping () -> Void,
        onOpenDetail: @escaping () -> Void,
        onLike: @escaping () -> Void = {}
    ) {
        self.opportunity = opportunity
        self.isExpanded = isExpanded
        self.isHighlighted = isHighlighted
        self.onSelect = onSelect
        self.onOpenDetail = onOpenDetail
        self.onLike = onLike
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Company Logo, Company Name, Spacer, Match % Badge (Guaranteed 1 Line)
            HStack(alignment: .center, spacing: 10) {
                // Branded Company Icon inside crisp white circle
                CompanyLogoBadge(companyName: opportunity.companyName, size: 44)

                // Company Name
                Text(opportunity.companyName)
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 6)

                // Match score badge in header (ALWAYS strictly 1 single line, no sparkle icon)
                Text("\(opportunity.matchScore)% Match")
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(opportunity.matchBadgeForegroundColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(opportunity.matchBadgeBackgroundColor)
                    .clipShape(Capsule())
                    .fixedSize(horizontal: true, vertical: false)
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // When expanded: Hero Role Title (Fixed Height), Non-Cut-Off Chips, Action Row
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    // Role title with locked uniform 42pt height (1 or 2 lines always take exact same space)
                    Text(opportunity.roleTitle)
                        .font(.system(size: 17, weight: .bold, design: .default))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 42, maxHeight: 42, alignment: .topLeading)

                    // Location, Internship & Recency chips (Direct HStack, NO ScrollView to prevent cut-off)
                    HStack(spacing: 6) {
                        let shortLocation = opportunity.location.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? opportunity.location
                        WhitePillChip(icon: "mappin", text: shortLocation)
                        WhitePillChip(icon: "briefcase", text: opportunity.opportunityType.rawValue)
                        WhitePillChip(icon: "clock", text: opportunity.recency.isEmpty ? "Recently" : opportunity.recency)
                        Spacer(minLength: 0)
                    }

                    // Bottom Action Row: View Details & Like button
                    HStack(spacing: 10) {
                        Button {
                            onOpenDetail()
                        } label: {
                            Text("View Details")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .alineGlassCapsule(selected: true)
                        }
                        .buttonStyle(.plain)

                        Button {
                            onLike()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 42, height: 42)
                                    .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
                                    .overlay(
                                        Circle().stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                                Image(systemName: opportunity.isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(opportunity.isLiked ? .red : AlineTheme.inkPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 226)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 6,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    Color.black.opacity(0.08),
                    lineWidth: 1.0
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(AlineTheme.cardSpring) {
                onSelect()
            }
        }
    }
}

// MARK: - Compact Explore Opportunity Card (Small List Card for Explore More Section)
public struct CompactExploreOpportunityCard: View {
    public let opportunity: Opportunity
    public let onOpenDetail: () -> Void

    public init(
        opportunity: Opportunity,
        onOpenDetail: @escaping () -> Void
    ) {
        self.opportunity = opportunity
        self.onOpenDetail = onOpenDetail
    }

    private var shortLocation: String {
        opportunity.location.components(separatedBy: ",").first ?? opportunity.location
    }

    public var body: some View {
        Button {
            onOpenDetail()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Row 1: company (logo + name) on the left, match score on the right
                HStack(spacing: 10) {
                    CompanyLogoBadge(companyName: opportunity.companyName, size: 36, isSquircle: true)

                    Text(opportunity.companyName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text("\(opportunity.matchScore)% Match")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .foregroundColor(opportunity.matchBadgeForegroundColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(opportunity.matchBadgeBackgroundColor)
                        .clipShape(Capsule())
                        .fixedSize(horizontal: true, vertical: false)
                }

                // Row 2: job role, full width so it is never cut off
                // Always reserves two lines, so every card in a list is the same height
                Text(opportunity.roleTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Row 3: quiet meta line
                HStack(spacing: 6) {
                    Text(shortLocation)
                    Text("·")
                    Text(opportunity.opportunityType.rawValue)
                    Text("·")
                    Text(opportunity.recency)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AlineTheme.inkMuted)
                .lineLimit(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1.0)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Explore More cards") {
    ZStack {
        DiscoverBackgroundArtwork()
        VStack(spacing: AlineSpacing.card) {
            ForEach([Opportunity.previewSample]) { opp in
                CompactExploreOpportunityCard(opportunity: opp, onOpenDetail: {})
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - View More Opportunities Card (For Horizontal Scroll)
public struct ViewMoreCard: View {
    public let remainingCount: Int
    public let onTap: () -> Void

    public init(remainingCount: Int, onTap: @escaping () -> Void) {
        self.remainingCount = remainingCount
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AlineTheme.pillDark)
                        .frame(width: 54, height: 54)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 4) {
                    Text("View More")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    if remainingCount > 0 {
                        Text("\(remainingCount)+ Opportunities")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    } else {
                        Text("Explore All Vacancies")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                }

                HStack(spacing: 4) {
                    Text("Browse All")
                        .font(.system(size: 12, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(AlineTheme.inkPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - White Pill Badge (Same color as Card)
public struct WhitePillChip: View {
    public let icon: String?
    public let text: String

    public init(icon: String? = nil, text: String) {
        self.icon = icon
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon = icon, !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.90)
        }
        .foregroundColor(AlineTheme.inkPrimary)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.black.opacity(0.06)))
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Four-Point Sparkle Star Shape
public struct FourPointStar: Shape {
    public var pinch: CGFloat

    public init(pinch: CGFloat = 0.22) {
        self.pinch = pinch
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let w = rect.width / 2
        let h = rect.height / 2

        path.move(to: CGPoint(x: c.x, y: c.y - h))
        path.addQuadCurve(
            to: CGPoint(x: c.x + w, y: c.y),
            control: CGPoint(x: c.x + w * pinch, y: c.y - h * pinch)
        )
        path.addQuadCurve(
            to: CGPoint(x: c.x, y: c.y + h),
            control: CGPoint(x: c.x + w * pinch, y: c.y + h * pinch)
        )
        path.addQuadCurve(
            to: CGPoint(x: c.x - w, y: c.y),
            control: CGPoint(x: c.x - w * pinch, y: c.y + h * pinch)
        )
        path.addQuadCurve(
            to: CGPoint(x: c.x, y: c.y - h),
            control: CGPoint(x: c.x - w * pinch, y: c.y - h * pinch)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - App Logo View (Displays the Official Aline App Icon)
public struct AppLogoView: View {
    public let size: CGFloat

    public init(size: CGFloat = 44) {
        self.size = size
    }

    public var body: some View {
        Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Discover Background Gradient (Top-to-Bottom Light Yellow · Subtle Pink · Subtle Icy Sky Blue)
public struct DiscoverBackgroundArtwork: View {
    public init() {}

    // Subtle pastel palette colors: warm light yellow at top, subtle warm blush in middle, lighter subtle icy sky blue at bottom
    private let lightYellow = Color(red: 0.996, green: 0.980, blue: 0.88)
    private let subtlePink = Color(red: 0.996, green: 0.930, blue: 0.920)
    private let icySkyBlue = Color(red: 0.88, green: 0.955, blue: 0.998)

    public var body: some View {
        LinearGradient(
            stops: [
                .init(color: lightYellow, location: 0.0),
                .init(color: subtlePink, location: 0.40),
                .init(color: icySkyBlue, location: 0.88)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Blended Header Background
/// Paints the exact slice of the Discover page gradient that sits behind this view, so a pinned header
/// covers scrolling content while looking identical to the page (and the status bar area above it).
public struct DiscoverBlendedBackground: View {
    public let screenHeight: CGFloat

    public init(screenHeight: CGFloat) {
        self.screenHeight = screenHeight
    }

    public var body: some View {
        GeometryReader { proxy in
            let top = proxy.frame(in: .global).minY
            LinearGradient(
                stops: [
                    .init(color: AlineTheme.bgYellow, location: 0.0),
                    .init(color: AlineTheme.bgPink, location: 0.40),
                    .init(color: AlineTheme.bgBlue, location: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: proxy.size.width, height: screenHeight)
            .offset(y: -top)
        }
        .clipped()
        .allowsHitTesting(false)
    }
}

// MARK: - Dark Pill Badge (Matching Screenshot)
public struct BlackPillChip: View {
    public let icon: String
    public let text: String

    public init(icon: String, text: String) {
        self.icon = icon
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AlineTheme.pillDark)
        .clipShape(Capsule())
    }
}

// MARK: - Clean Tag View
public struct SkillTagView: View {
    public let title: String
    public var isHighlighted: Bool = false

    public var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isHighlighted ? .white : AlineTheme.inkPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isHighlighted ? AlineTheme.pillDark : Color.black.opacity(0.05))
            )
    }
}

// MARK: - Stacked Resume Card (Matching Discover Card Stack Aesthetic)
public struct StackedResumeCard: View {
    public let resume: ResumeDocument
    public let isExpanded: Bool
    public let onSelect: () -> Void
    public let onTailor: () -> Void
    public let onPreview: () -> Void

    public init(
        resume: ResumeDocument,
        isExpanded: Bool,
        onSelect: @escaping () -> Void,
        onTailor: @escaping () -> Void,
        onPreview: @escaping () -> Void
    ) {
        self.resume = resume
        self.isExpanded = isExpanded
        self.onSelect = onSelect
        self.onTailor = onTailor
        self.onPreview = onPreview
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Row: Folder / Company Icon, Resume Title, and Diagonal Arrow Button
            HStack(alignment: .center) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                        Image(systemName: resume.targetCompanySymbol ?? "doc.text.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(resume.title)
                                .font(.system(size: 20, weight: .bold, design: .default))
                                .foregroundColor(AlineTheme.inkPrimary)

                            if resume.isDefault {
                                Text("DEFAULT")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .alineGlassCapsule(selected: true)
                            }
                        }

                        Text(resume.targetCompany != nil ? "Target: \(resume.targetCompany!)" : resume.lastModifiedDate)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                }

                Spacer()

                Button {
                    onTailor()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, isExpanded ? 14 : 22)

            // Expanded Content: Summary, Chips, and Direct Actions
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Text(resume.summary)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineSpacing(3)
                        .lineLimit(3)

                    // Black Chips row (Template, Size, Match/Optimization)
                    HStack(spacing: 8) {
                        BlackPillChip(icon: "doc.text.image", text: resume.selectedTemplate.rawValue)
                        BlackPillChip(icon: "internaldrive", text: resume.fileSize)
                        if let score = resume.matchScore {
                            BlackPillChip(icon: "sparkles", text: "\(score)% Fit")
                        } else {
                            BlackPillChip(icon: "wand.and.stars", text: "\(resume.optimizationCount) AI Edits")
                        }
                    }

                    // Action Buttons Row
                    HStack(spacing: 10) {
                        Button {
                            onTailor()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Tailor with AI")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .alineGlassCapsule(selected: true)
                        }
                        .buttonStyle(.plain)

                        Button {
                            onPreview()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Preview Document")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(AlineTheme.inkPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .alineGlassCapsule(selected: false)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(resume.cardColor)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(AlineTheme.cardSpring) {
                onSelect()
            }
        }
    }
}

// MARK: - Previews
#Preview("Aline Design System Showcase") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Aline Component Showcase")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(AlineTheme.inkPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Brand Logos
            VStack(alignment: .leading, spacing: 10) {
                Text("Authentic Brand Logos")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AlineTheme.inkSecondary)

                HStack(spacing: 16) {
                    CompanyLogoBadge(companyName: "Google", size: 48)
                    CompanyLogoBadge(companyName: "Ola", size: 48)
                    CompanyLogoBadge(companyName: "Microsoft", size: 48)
                    CompanyLogoBadge(companyName: "Apple", size: 48)
                    CompanyLogoBadge(companyName: "Amazon", size: 48)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Sample Opportunity Card
            if let sampleOpp = [Opportunity.previewSample].first {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Opportunity Stacked Card")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AlineTheme.inkSecondary)

                    StackedOpportunityCard(
                        opportunity: sampleOpp,
                        isExpanded: true,
                        onSelect: {},
                        onOpenDetail: {}
                    )
                }
            }
        }
        .padding(20)
    }
    .background(Color(AlineTheme.canvasBackground).ignoresSafeArea())
}




// MARK: - Close Button (the one ✕ used on every sheet and full-screen page)
/// 40pt glass circle, bold ✕: identical to the Profile sheets' close button
public struct AlineCloseButton: View {
    public let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .alineGlassCircleButton()
        .accessibilityLabel("Close")
    }
}
