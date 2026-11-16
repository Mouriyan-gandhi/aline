import SwiftUI

// MARK: - Splash Screen View
/// The launch animation, drawn in SwiftUI around the app logo (the "AppLogo" asset), so it always
/// shows the current logo. Transitions to the welcome screen or the main flow when it finishes (no Skip: it's short).
///
/// 1. A spark twinkles in the dark and arcs up to where the logo's star sits, leaving a pastel trail.
/// 2. The logo tile condenses out of a blur with a soft white glow behind it as the spark lands.
/// 3. A thin pastel ring blooms and slowly turns; a light sweep crosses the tile.
/// 4. "Aline" writes in, then the tagline.
/// 5. The app's light background opens out from the logo and the app takes over.
public struct SplashScreenView: View {
    public let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()
    @State private var hasTriggeredFinish: Bool = false

    private let logoSize: CGFloat = 168
    private let totalDuration: Double = 5.0

    /// Where the star sits in the logo artwork, as a fraction of the image
    private let starInLogo = CGPoint(x: 0.762, y: 0.246)

    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            TimelineView(.animation(paused: hasTriggeredFinish)) { context in
                let elapsed = context.date.timeIntervalSince(startDate)
                scene(at: reduceMotion ? max(elapsed, 3.0) : elapsed)
                    .onChange(of: elapsed >= totalDuration) { _, ended in
                        if ended { finishSplash() }
                    }
            }
        }
        .onAppear {
            startDate = Date()
        }
    }

    private func finishSplash() {
        guard !hasTriggeredFinish else { return }
        hasTriggeredFinish = true
        withAnimation(.easeInOut(duration: 0.35)) {
            onFinished()
        }
    }

    // MARK: Scene at time t (seconds)
    private func scene(at t: Double) -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            let diagonal = hypot(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height * 0.43)
            let exit = ease(t, 4.1, 5.0, .inOut)

            ZStack {
                Color(red: 0.02, green: 0.02, blue: 0.035)

                aurora(at: t, size: size)

                ZStack {
                    stage(at: t)
                        .position(center)

                    wordmark(at: t)
                        .position(x: center.x, y: center.y + logoSize / 2 + 92)
                }
                .scaleEffect(1 + 0.05 * exit)
                .opacity(1 - ease(t, 4.1, 4.6, .out))

                // Hand-over: the app's light background opens out from the logo
                DiscoverBackgroundArtwork()
                    .mask(
                        Circle()
                            .frame(width: diagonal * 1.25 * exit, height: diagonal * 1.25 * exit)
                            .blur(radius: 30 * (1 - exit))
                            .position(center)
                    )
                    .allowsHitTesting(false)
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
    }

    // MARK: Logo stage: glow, ring, tile, light sweep, trail and spark
    private func stage(at t: Double) -> some View {
        let appear = ease(t, 0.1, 0.5, .out)
        let flight = ease(t, 0.5, 1.4, .inOut)
        let logoIn = ease(t, 1.05, 1.9, .out)
        let flare = ease(t, 1.35, 1.8, .out)
        let ringBloom = ease(t, 1.2, 2.2, .out)
        let ringSettle = ease(t, 2.2, 3.1, .inOut)
        let trailFade = ease(t, 1.4, 2.0, .out)
        let sweep = ease(t, 2.1, 2.9, .inOut)

        let stageSide: CGFloat = 300
        let sparkStart = CGPoint(x: -0.62 * logoSize, y: 0.62 * logoSize)
        let sparkControl = CGPoint(x: -0.55 * logoSize, y: -0.42 * logoSize)
        let sparkEnd = CGPoint(x: (starInLogo.x - 0.5) * logoSize, y: (starInLogo.y - 0.5) * logoSize)
        let spark = quad(sparkStart, sparkControl, sparkEnd, flight)
        let twinkle = 1 + 0.12 * sin(t * 9)
        let corner = logoSize * 0.225

        return ZStack {
            // Turning pastel ring
            ZStack {
                Circle()
                    .stroke(Self.pastelRing, lineWidth: 16)
                    .blur(radius: 20)
                    .opacity(0.4)
                Circle()
                    .stroke(Self.pastelRing, lineWidth: 1.2)
                    .opacity(0.85)
            }
            .frame(width: logoSize * 1.62, height: logoSize * 1.62)
            .rotationEffect(.degrees(t * 22))
            .scaleEffect(0.7 + 0.3 * ringBloom)
            .opacity(ringBloom * (1 - 0.4 * ringSettle))
            .allowsHitTesting(false)

            // Soft white glow behind the tile
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.white.opacity(0.5))
                .frame(width: logoSize, height: logoSize)
                .blur(radius: 28)
                .opacity(logoIn * 0.8)
                .allowsHitTesting(false)

            // The logo tile
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
                .overlay(lightSweep(progress: sweep))
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1.2)
                        .allowsHitTesting(false)
                )
                .blur(radius: 16 * (1 - logoIn))
                .scaleEffect(0.86 + 0.14 * logoIn)
                .opacity(logoIn)

            // Pastel trail along the spark's arc
            ZStack {
                SparkArc(start: sparkStart, control: sparkControl, end: sparkEnd)
                    .trim(from: max(0, flight - 0.55), to: flight)
                    .stroke(Self.pastelTrail, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .blur(radius: 7)
                    .opacity(0.7)
                SparkArc(start: sparkStart, control: sparkControl, end: sparkEnd)
                    .trim(from: max(0, flight - 0.55), to: flight)
                    .stroke(Self.pastelTrail, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            .frame(width: stageSide, height: stageSide)
            .opacity(1 - trailFade)
            .allowsHitTesting(false)

            // The spark
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.85), Self.pink.opacity(0.35), .clear],
                            center: .center, startRadius: 0, endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                SparkleShape()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: Self.blue.opacity(0.9), radius: 6)
                    .shadow(color: Self.pink.opacity(0.7), radius: 12)
                    .rotationEffect(.degrees(t * 40))
            }
            .scaleEffect(appear * twinkle * (1 + 1.6 * flare))
            .opacity(appear * (1 - flare))
            .offset(x: spark.x, y: spark.y)
            .allowsHitTesting(false)
        }
        .frame(width: stageSide, height: stageSide)
    }

    /// One diagonal band of light across the tile, like light catching glass
    private func lightSweep(progress: Double) -> some View {
        LinearGradient(
            colors: [.clear, Color.white.opacity(0.6), .clear],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(width: logoSize * 0.35, height: logoSize * 1.8)
        .rotationEffect(.degrees(24))
        .offset(x: logoSize * (-1 + 2 * progress))
        .opacity(progress > 0 && progress < 1 ? 1 : 0)
        .allowsHitTesting(false)
    }

    // MARK: Wordmark
    private func wordmark(at t: Double) -> some View {
        let letters = Array("Aline")
        let tagline = ease(t, 2.55, 3.15, .out)

        return VStack(spacing: 10) {
            HStack(spacing: 7) {
                ForEach(letters.indices, id: \.self) { i in
                    let p = ease(t, 1.95 + 0.09 * Double(i), 2.45 + 0.09 * Double(i), .out)
                    Text(String(letters[i]))
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Color.white.opacity(0.94))
                        .opacity(p)
                        .blur(radius: 6 * (1 - p))
                        .offset(y: 10 * (1 - p))
                }
            }

            Text("REACH WHAT'S NEXT")
                .font(.system(size: 11, weight: .medium))
                .tracking(4)
                .foregroundStyle(Color.white.opacity(0.5))
                .opacity(tagline)
                .offset(y: 6 * (1 - tagline))
        }
    }

    // MARK: Drifting pastel light, in the logo tile's colours
    private func aurora(at t: Double, size: CGSize) -> some View {
        let fadeIn = ease(t, 0.0, 1.6, .out)
        let blobs: [(Color, CGFloat, Double)] = [
            (Self.peach, 300, 0.0),
            (Self.pink, 320, 2.1),
            (Self.blue, 340, 4.2)
        ]
        return ZStack {
            ForEach(blobs.indices, id: \.self) { i in
                let blob = blobs[i]
                Circle()
                    .fill(blob.0)
                    .frame(width: blob.1, height: blob.1)
                    .position(
                        x: size.width * (0.5 + 0.3 * cos(t * 0.3 + blob.2)),
                        y: size.height * (0.45 + 0.3 * sin(t * 0.25 + blob.2))
                    )
                    .blur(radius: 90)
            }
        }
        .frame(width: size.width, height: size.height)
        .opacity(0.17 * fadeIn)
        .allowsHitTesting(false)
    }

    // MARK: Helpers
    private enum Curve { case out, inOut }

    /// Progress 0...1 of t between a and b, with easing
    private func ease(_ t: Double, _ a: Double, _ b: Double, _ curve: Curve) -> Double {
        let x = min(max((t - a) / (b - a), 0), 1)
        switch curve {
        case .out: return 1 - pow(1 - x, 3)
        case .inOut: return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
        }
    }

    /// Point on a quadratic curve at progress p
    private func quad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ p: Double) -> CGPoint {
        let u = 1 - p
        return CGPoint(
            x: u * u * a.x + 2 * u * p * c.x + p * p * b.x,
            y: u * u * a.y + 2 * u * p * c.y + p * p * b.y
        )
    }

    // MARK: Palette (the logo tile's pastels)
    private static let peach = Color(red: 1.0, green: 0.90, blue: 0.80)
    private static let pink = Color(red: 1.0, green: 0.78, blue: 0.90)
    private static let lavender = Color(red: 0.86, green: 0.82, blue: 1.0)
    private static let blue = Color(red: 0.72, green: 0.87, blue: 1.0)

    private static let pastelRing = AngularGradient(
        colors: [peach, pink, lavender, blue, peach],
        center: .center
    )
    private static let pastelTrail = LinearGradient(
        colors: [blue, lavender, pink, peach],
        startPoint: .bottomLeading, endPoint: .topTrailing
    )
}

// MARK: - Four-point sparkle, like the star in the logo
private struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let w = rect.width / 2
        let h = rect.height / 2
        let k: CGFloat = 0.16
        var path = Path()
        path.move(to: CGPoint(x: c.x, y: c.y - h))
        path.addQuadCurve(to: CGPoint(x: c.x + w, y: c.y), control: CGPoint(x: c.x + w * k, y: c.y - h * k))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y + h), control: CGPoint(x: c.x + w * k, y: c.y + h * k))
        path.addQuadCurve(to: CGPoint(x: c.x - w, y: c.y), control: CGPoint(x: c.x - w * k, y: c.y + h * k))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y - h), control: CGPoint(x: c.x - w * k, y: c.y - h * k))
        path.closeSubpath()
        return path
    }
}

// MARK: - The spark's arc, in points relative to the frame's centre
private struct SparkArc: Shape {
    let start: CGPoint
    let control: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.move(to: CGPoint(x: c.x + start.x, y: c.y + start.y))
        path.addQuadCurve(
            to: CGPoint(x: c.x + end.x, y: c.y + end.y),
            control: CGPoint(x: c.x + control.x, y: c.y + control.y)
        )
        return path
    }
}

#Preview("Splash") {
    SplashScreenView(onFinished: {})
}
