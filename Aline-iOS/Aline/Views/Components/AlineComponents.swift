import SwiftUI

// MARK: - Floating Bottom Navigation Bar (Transparent Glassmorphism)
public struct FloatingTabBar: View {
    @Binding public var currentTab: AppTab
    @Namespace private var tabAnimation

    public init(currentTab: Binding<AppTab>) {
        self._currentTab = currentTab
    }

    public var body: some View {
        HStack(spacing: 12) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = currentTab == tab
                Button {
                    withAnimation(AlineTheme.tabSpring) {
                        currentTab = tab
                    }
                } label: {
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(AlineTheme.pillDark)
                                .frame(width: 46, height: 46)
                                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
                                .matchedGeometryEffect(id: "activeTabBubble", in: tabAnimation)
                        }

                        Image(systemName: tab.iconName)
                            .font(.system(size: 20, weight: isSelected ? .bold : .semibold))
                            .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary.opacity(0.75))
                            .frame(width: 46, height: 46)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Frosted ultra-thin glass material with background blur
                Capsule()
                    .fill(.ultraThinMaterial)

                // Translucent milky white tint for crystal glass depth
                Capsule()
                    .fill(Color.white.opacity(0.65))

                // Refractive specular highlight border
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.92),
                                Color.white.opacity(0.40),
                                Color.black.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 6)
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

// MARK: - Company Brand Logo Component (White Circle with Authentic Company Icon)
public struct CompanyLogoBadge: View {
    public let companyName: String
    public let size: CGFloat
    public let isSquircle: Bool

    public init(companyName: String, size: CGFloat = 48, isSquircle: Bool = false) {
        self.companyName = companyName
        self.size = size
        self.isSquircle = isSquircle
    }

    public var body: some View {
        ZStack {
            if isSquircle {
                RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                    .fill(Color.white)
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            }

            iconContent
        }
    }

    @ViewBuilder
    private var iconContent: some View {
        let name = companyName.lowercased()
        if name.contains("ola") {
            // Ola: Black ring with neon lime/yellow circle and center dot
            ZStack {
                Circle()
                    .stroke(Color.black, lineWidth: size * 0.13)
                    .frame(width: size * 0.62, height: size * 0.62)
                Circle()
                    .fill(Color(red: 0.83, green: 0.91, blue: 0.05)) // Ola neon lime
                    .frame(width: size * 0.36, height: size * 0.36)
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.16, height: size * 0.16)
            }
        } else if name.contains("flipkart") {
            // Flipkart: Yellow shopping bag with blue serif 'f'
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.10, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.85, blue: 0.0)) // Flipkart yellow
                    .frame(width: size * 0.58, height: size * 0.58)
                Text("f")
                    .font(.system(size: size * 0.38, weight: .black, design: .serif))
                    .italic()
                    .foregroundColor(Color(red: 0.16, green: 0.45, blue: 0.94)) // Flipkart blue
                    .offset(x: -size * 0.02, y: -size * 0.02)
            }
        } else if name.contains("apple") {
            // Apple: Black Apple icon
            Image(systemName: "apple.logo")
                .font(.system(size: size * 0.54, weight: .semibold))
                .foregroundColor(.black)
        } else if name.contains("google") {
            // Google: 4-color 'G'
            GoogleGView(size: size * 0.60)
        } else if name.contains("microsoft") {
            Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                GridRow {
                    Rectangle().fill(Color(red: 0.95, green: 0.32, blue: 0.16)).frame(width: size * 0.22, height: size * 0.22)
                    Rectangle().fill(Color(red: 0.49, green: 0.73, blue: 0.08)).frame(width: size * 0.22, height: size * 0.22)
                }
                GridRow {
                    Rectangle().fill(Color(red: 0.02, green: 0.65, blue: 0.93)).frame(width: size * 0.22, height: size * 0.22)
                    Rectangle().fill(Color(red: 1.0, green: 0.73, blue: 0.0)).frame(width: size * 0.22, height: size * 0.22)
                }
            }
        } else if name.contains("meta") || name.contains("facebook") {
            Image(systemName: "infinity")
                .font(.system(size: size * 0.52, weight: .heavy))
                .foregroundColor(Color(red: 0.04, green: 0.40, blue: 0.95))
        } else if name.contains("amazon") {
            VStack(spacing: -size * 0.05) {
                Text("a")
                    .font(.system(size: size * 0.44, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.1, green: 0.12, blue: 0.16))
                Image(systemName: "arrow.right")
                    .font(.system(size: size * 0.16, weight: .black))
                    .foregroundColor(Color(red: 1.0, green: 0.60, blue: 0.0))
                    .rotationEffect(.degrees(12))
            }
        } else if name.contains("netflix") {
            Text("N")
                .font(.system(size: size * 0.60, weight: .black, design: .serif))
                .foregroundColor(Color(red: 0.89, green: 0.04, blue: 0.08))
        } else if name.contains("spotify") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.11, green: 0.84, blue: 0.38))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "waveform")
                    .font(.system(size: size * 0.36, weight: .heavy))
                    .foregroundColor(.black)
            }
        } else if name.contains("uber") {
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("U")
                    .font(.system(size: size * 0.42, weight: .black, design: .default))
                    .foregroundColor(.white)
            }
        } else if name.contains("airbnb") {
            Image(systemName: "triangle.circle.fill")
                .font(.system(size: size * 0.56, weight: .bold))
                .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.40))
        } else if name.contains("swiggy") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.99, green: 0.50, blue: 0.10))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "location.fill")
                    .font(.system(size: size * 0.32, weight: .black))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(135))
            }
        } else if name.contains("zomato") {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .fill(Color(red: 0.89, green: 0.17, blue: 0.22))
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("z")
                    .font(.system(size: size * 0.44, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        } else if name.contains("cred") {
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundColor(.white)
            }
        } else if name.contains("razorpay") {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .fill(Color(red: 0.05, green: 0.35, blue: 0.85))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "bolt.fill")
                    .font(.system(size: size * 0.36, weight: .heavy))
                    .foregroundColor(.white)
            }
        } else if name.contains("phonepe") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.41, green: 0.15, blue: 0.69))
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("पे")
                    .font(.system(size: size * 0.36, weight: .heavy))
                    .foregroundColor(.white)
            }
        } else if name.contains("stripe") {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .fill(Color(red: 0.39, green: 0.36, blue: 0.95))
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("S")
                    .font(.system(size: size * 0.40, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
        } else if name.contains("figma") {
            VStack(spacing: 1) {
                HStack(spacing: 1) {
                    Circle().fill(Color(red: 0.95, green: 0.35, blue: 0.25)).frame(width: size * 0.16, height: size * 0.16)
                    Circle().fill(Color(red: 1.0, green: 0.55, blue: 0.20)).frame(width: size * 0.16, height: size * 0.16)
                }
                HStack(spacing: 1) {
                    Circle().fill(Color(red: 0.65, green: 0.35, blue: 0.95)).frame(width: size * 0.16, height: size * 0.16)
                    Circle().fill(Color(red: 0.10, green: 0.75, blue: 0.95)).frame(width: size * 0.16, height: size * 0.16)
                }
                HStack(spacing: 1) {
                    Circle().fill(Color(red: 0.05, green: 0.80, blue: 0.45)).frame(width: size * 0.16, height: size * 0.16)
                    Spacer().frame(width: size * 0.16)
                }
            }
        } else if name.contains("notion") {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                    .stroke(Color.black, lineWidth: size * 0.04)
                    .frame(width: size * 0.60, height: size * 0.60)
                Text("N")
                    .font(.system(size: size * 0.40, weight: .black, design: .serif))
                    .foregroundColor(.black)
            }
        } else if name.contains("github") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.14, green: 0.16, blue: 0.19))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: size * 0.26, weight: .bold))
                    .foregroundColor(.white)
            }
        } else if name.contains("openai") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.06, green: 0.64, blue: 0.50))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.32, weight: .heavy))
                    .foregroundColor(.white)
            }
        } else if name.contains("anthropic") {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .fill(Color(red: 0.85, green: 0.47, blue: 0.34))
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("A")
                    .font(.system(size: size * 0.40, weight: .black, design: .serif))
                    .foregroundColor(.white)
            }
        } else if name.contains("databricks") {
            Image(systemName: "square.3.layers.3d.down.right.fill")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundColor(Color(red: 1.0, green: 0.22, blue: 0.16))
        } else if name.contains("snowflake") {
            Image(systemName: "snowflake")
                .font(.system(size: size * 0.52, weight: .bold))
                .foregroundColor(Color(red: 0.18, green: 0.68, blue: 0.94))
        } else if name.contains("nvidia") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.46, green: 0.73, blue: 0.0))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "eye.fill")
                    .font(.system(size: size * 0.34, weight: .heavy))
                    .foregroundColor(.white)
            }
        } else if name.contains("linear") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.36, green: 0.38, blue: 0.94))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "line.diagonal")
                    .font(.system(size: size * 0.38, weight: .black))
                    .foregroundColor(.white)
            }
        } else if name.contains("canva") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.0, green: 0.77, blue: 0.86))
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("C")
                    .font(.system(size: size * 0.44, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        } else if name.contains("atlassian") {
            Image(systemName: "triangle.fill")
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundColor(Color(red: 0.0, green: 0.32, blue: 0.84))
        } else if name.contains("adobe") {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .fill(Color(red: 0.90, green: 0.0, blue: 0.0))
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("A")
                    .font(.system(size: size * 0.42, weight: .black, design: .default))
                    .foregroundColor(.white)
            }
        } else if name.contains("goldman") {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .fill(Color(red: 0.12, green: 0.34, blue: 0.58))
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("GS")
                    .font(.system(size: size * 0.32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        } else if name.contains("morgan") {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .fill(Color(red: 0.15, green: 0.20, blue: 0.26))
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("MS")
                    .font(.system(size: size * 0.32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        } else if name.contains("citadel") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.05, green: 0.14, blue: 0.28))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "building.columns.fill")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundColor(.white)
            }
        } else if name.contains("jane street") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.08, green: 0.32, blue: 0.20))
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("JS")
                    .font(.system(size: size * 0.32, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
            }
        } else if name.contains("zepto") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.30, green: 0.05, blue: 0.60))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "bolt.fill")
                    .font(.system(size: size * 0.34, weight: .heavy))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
            }
        } else if name.contains("meesho") {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .fill(Color(red: 0.95, green: 0.18, blue: 0.50))
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("M")
                    .font(.system(size: size * 0.42, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
        } else if name.contains("groww") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.0, green: 0.82, blue: 0.61))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: size * 0.32, weight: .heavy))
                    .foregroundColor(.white)
            }
        } else if name.contains("zerodha") {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .fill(Color(red: 0.22, green: 0.58, blue: 0.94))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "skew")
                    .font(.system(size: size * 0.36, weight: .heavy))
                    .foregroundColor(.white)
            }
        } else if name.contains("discord") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.35, green: 0.40, blue: 0.95))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: size * 0.32, weight: .heavy))
                    .foregroundColor(.white)
            }
        } else if name.contains("duolingo") {
            ZStack {
                Circle()
                    .fill(Color(red: 0.35, green: 0.80, blue: 0.01))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "eyes")
                    .font(.system(size: size * 0.36, weight: .heavy))
                    .foregroundColor(.white)
            }
        } else if name.contains("linkedin") {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .fill(Color(red: 0.04, green: 0.40, blue: 0.76))
                    .frame(width: size * 0.64, height: size * 0.64)
                Text("in")
                    .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        } else if name.contains("salesforce") {
            Image(systemName: "cloud.fill")
                .font(.system(size: size * 0.52, weight: .bold))
                .foregroundColor(Color(red: 0.0, green: 0.63, blue: 0.88))
        } else if name.contains("cloudflare") {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: size * 0.50, weight: .bold))
                .foregroundColor(Color(red: 0.95, green: 0.50, blue: 0.13))
        } else if name.contains("supabase") {
            Image(systemName: "bolt.fill")
                .font(.system(size: size * 0.52, weight: .heavy))
                .foregroundColor(Color(red: 0.24, green: 0.81, blue: 0.56))
        } else if name.contains("vercel") {
            Image(systemName: "triangle.fill")
                .font(.system(size: size * 0.48, weight: .black))
                .foregroundColor(.black)
        } else if name.contains("retool") {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
        } else if name.contains("hasura") {
            Image(systemName: "paperplane.fill")
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.8))
        } else if name.contains("postman") {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.42, blue: 0.22))
                    .frame(width: size * 0.64, height: size * 0.64)
                Image(systemName: "figure.walk")
                    .font(.system(size: size * 0.34, weight: .heavy))
                    .foregroundColor(.white)
            }
        } else if name.contains("palantir") {
            Image(systemName: "circle.circle")
                .font(.system(size: size * 0.52, weight: .black))
                .foregroundColor(.black)
        } else if name.contains("cisco") {
            Image(systemName: "waveform.path")
                .font(.system(size: size * 0.48, weight: .black))
                .foregroundColor(Color(red: 0.11, green: 0.63, blue: 0.84))
        } else if name.contains("intel") {
            Text("intel")
                .font(.system(size: size * 0.26, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.0, green: 0.41, blue: 0.71))
        } else if name.contains("amd") {
            Image(systemName: "chevron.right.2")
                .font(.system(size: size * 0.42, weight: .black))
                .foregroundColor(Color(red: 0.0, green: 0.64, blue: 0.42))
        } else if name.contains("browserstack") {
            Image(systemName: "laptopcomputer.and.iphone")
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.85))
        } else {
            Text(String(companyName.prefix(1)).uppercased())
                .font(.system(size: size * 0.50, weight: .heavy, design: .rounded))
                .foregroundColor(AlineTheme.inkPrimary)
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

                // Match score badge in header (ALWAYS strictly 1 single line)
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(opportunity.matchScore)% Match")
                        .font(.system(size: 11, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.30))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(red: 0.90, green: 0.96, blue: 0.90))
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
                                .background(AlineTheme.pillDark)
                                .clipShape(Capsule())
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
                    color: Color.black.opacity(isHighlighted ? 0.12 : 0.05),
                    radius: isHighlighted ? 12 : 6,
                    x: 0,
                    y: isHighlighted ? 5 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    isHighlighted ? AlineTheme.pillDark : Color.black.opacity(0.08),
                    lineWidth: isHighlighted ? 2.0 : 1.0
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
    public let icon: String
    public let text: String

    public init(icon: String, text: String) {
        self.icon = icon
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.90)
        }
        .foregroundColor(AlineTheme.inkPrimary)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
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
        Group {
            if let uiImage = UIImage(named: "AppLogo") ?? UIImage(contentsOfFile: "/Users/user27/Documents/Aline/Aline/Resources/Assets.xcassets/AppLogo.imageset/logo_1024.png") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "sparkles")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(AlineTheme.inkPrimary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Discover Decorative Canvas Background (Light Blue · Light Yellow · Light Pink Subtle Blurred Circles)
public struct DiscoverBackgroundArtwork: View {
    public init() {}

    // Richer pastel palette colors: Blue, Yellow, Pink
    private let lightBlue = Color(red: 0.76, green: 0.88, blue: 0.98)
    private let lightYellow = Color(red: 1.0, green: 0.93, blue: 0.70)
    private let lightPink = Color(red: 0.98, green: 0.82, blue: 0.88)
    private let canvasCreme = Color(red: 0.988, green: 0.985, blue: 0.972)

    public var body: some View {
        ZStack {
            // Base warm creme canvas
            canvasCreme
                .ignoresSafeArea()

            // Soft, blurred radial ambient circles
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    // 1. Light Blue - Top Left
                    Circle()
                        .fill(lightBlue.opacity(0.62))
                        .frame(width: w * 0.46, height: w * 0.46)
                        .blur(radius: 64)
                        .position(x: w * 0.16, y: h * 0.08)

                    // 2. Light Pink - Top Right
                    Circle()
                        .fill(lightPink.opacity(0.62))
                        .frame(width: w * 0.44, height: w * 0.44)
                        .blur(radius: 66)
                        .position(x: w * 0.86, y: h * 0.14)

                    // 3. Light Yellow - Center Left
                    Circle()
                        .fill(lightYellow.opacity(0.58))
                        .frame(width: w * 0.42, height: w * 0.42)
                        .blur(radius: 62)
                        .position(x: w * 0.12, y: h * 0.38)

                    // 4. Light Blue - Center Right
                    Circle()
                        .fill(lightBlue.opacity(0.60))
                        .frame(width: w * 0.42, height: w * 0.42)
                        .blur(radius: 64)
                        .position(x: w * 0.88, y: h * 0.52)

                    // 5. Light Pink - Mid / Center
                    Circle()
                        .fill(lightPink.opacity(0.60))
                        .frame(width: w * 0.44, height: w * 0.44)
                        .blur(radius: 68)
                        .position(x: w * 0.35, y: h * 0.68)

                    // 6. Light Yellow - Bottom Right
                    Circle()
                        .fill(lightYellow.opacity(0.62))
                        .frame(width: w * 0.46, height: w * 0.46)
                        .blur(radius: 68)
                        .position(x: w * 0.84, y: h * 0.86)

                    // 7. Light Blue - Bottom Left
                    Circle()
                        .fill(lightBlue.opacity(0.60))
                        .frame(width: w * 0.42, height: w * 0.42)
                        .blur(radius: 64)
                        .position(x: w * 0.15, y: h * 0.94)
                }
            }
            .ignoresSafeArea()
        }
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
                                    .background(AlineTheme.pillDark)
                                    .clipShape(Capsule())
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
                            .background(AlineTheme.pillDark)
                            .clipShape(Capsule())
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
                            .background(Color.white)
                            .clipShape(Capsule())
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

            // Floating Navigation Bar
            VStack(alignment: .leading, spacing: 10) {
                Text("Floating Navigation Bar")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AlineTheme.inkSecondary)

                FloatingTabBar(currentTab: .constant(.discover))
            }

            // Sample Opportunity Card
            if let sampleOpp = Opportunity.samples.first {
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



