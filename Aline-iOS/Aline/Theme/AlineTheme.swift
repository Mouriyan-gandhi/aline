import SwiftUI

// MARK: - Aline Design System & Theme
// Strict adherence to Apple Human Interface Guidelines, SF Pro typography & SF Symbols
// Curated pastel color palette inspired by the interactive stacked-card UX

public enum AlineTheme {
    // MARK: - Pastel & Brand Palette
    public static let canvasBackground = Color(red: 0.985, green: 0.982, blue: 0.965) // Light Creme
    public static let surfaceWhite = Color.white

    // Background Palette: Light Yellow · Subtle Pink · Subtle Icy Sky Blue (Lighter)
    public static let bgYellow = Color(red: 0.996, green: 0.980, blue: 0.88)
    public static let bgPink = Color(red: 0.996, green: 0.930, blue: 0.920)
    public static let bgBlue = Color(red: 0.88, green: 0.955, blue: 0.998)

    public static let cardMint = Color(red: 0.82, green: 0.93, blue: 0.85)       // Ola
    public static let cardLavender = Color(red: 0.77, green: 0.82, blue: 0.96)   // Flipkart
    public static let cardPeach = Color(red: 0.95, green: 0.84, blue: 0.82)      // Apple
    public static let cardYellow = Color(red: 0.94, green: 0.93, blue: 0.73)     // Google
    public static let cardSkyBlue = Color(red: 0.83, green: 0.90, blue: 0.98)    // Microsoft / Barclays
    public static let cardCoral = Color(red: 0.98, green: 0.86, blue: 0.80)      // Amazon

    // MARK: - Ink & Neutral Colors
    public static let inkPrimary = Color(red: 0.10, green: 0.10, blue: 0.11)
    public static let inkSecondary = Color(red: 0.38, green: 0.40, blue: 0.44)
    public static let inkMuted = Color(red: 0.62, green: 0.64, blue: 0.68)
    public static let pillDark = Color(red: 0.11, green: 0.11, blue: 0.12)
    public static let borderSubtle = Color.black.opacity(0.08)

    // MARK: - Accent Colors
    public static let accentEmerald = Color(red: 0.15, green: 0.68, blue: 0.38)
    public static let accentHeart = Color(red: 0.96, green: 0.30, blue: 0.40)
    public static let accentAmber = Color(red: 0.95, green: 0.65, blue: 0.15)

    // MARK: - Springs & Animations
    public static let cardSpring = Animation.spring(response: 0.45, dampingFraction: 0.80)
    public static let fastSpring = Animation.spring(response: 0.30, dampingFraction: 0.82)
    public static let tabSpring = Animation.spring(response: 0.38, dampingFraction: 0.78)
}

// MARK: - Spacing Scale (use these everywhere so every screen has the same rhythm)
public enum AlineSpacing {
    /// Horizontal inset of screen content
    public static let screenInset: CGFloat = 24
    /// Gap between major sections on a screen (header block → search → filters → list …)
    public static let section: CGFloat = 20
    /// Gap between a section's title row and its content
    public static let sectionHeader: CGFloat = 12
    /// Gap between cards / rows in a list
    public static let card: CGFloat = 12
}

// MARK: - SF Pro Typography Extensions
public extension Font {
    static let alineHero = Font.system(size: 34, weight: .black, design: .default)
    static let alineTitleLarge = Font.system(size: 26, weight: .heavy, design: .default)
    static let alineTitleMedium = Font.system(size: 20, weight: .bold, design: .default)
    static let alineBodyBold = Font.system(size: 16, weight: .semibold, design: .default)
    static let alineBody = Font.system(size: 15, weight: .regular, design: .default)
    static let alineCallout = Font.system(size: 14, weight: .medium, design: .default)
    static let alineFootnote = Font.system(size: 12, weight: .semibold, design: .default)
    static let alineCaption = Font.system(size: 11, weight: .regular, design: .default)
}
