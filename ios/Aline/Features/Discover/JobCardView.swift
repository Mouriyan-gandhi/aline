import SwiftUI

/// Matches the real Figma "Opportunity card" layout (48x48 logo tile, title/company/meta row
/// with a location pin + "City · Type", a freshness badge, and a match-ring + heart in a
/// trailing column), restyled for the iOS 26/27 brand refresh: a soft elevation shadow instead
/// of a flat hairline border, a gradient match ring, and the brand sparkle color reserved for
/// the freshness badge and standout (>85%) matches. Real company logo assets aren't practical
/// here — the app has 460+ registered companies with no logo-fetching pipeline yet — so the
/// logo tile falls back to the company's initial on a brand-tinted background.
struct JobCardView: View {
    let job: Job
    let match: MatchResult
    var isLiked: Bool = false
    var onToggleLike: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            companyLogo
            content
            Spacer(minLength: 4)
            scoreAndFavorite
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(height: 96)
        .background(AlineColor.paperWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }

    private var companyLogo: some View {
        Text(String(job.company.prefix(1)).uppercased())
            .font(AlineFont.sfPro(18, weight: .bold))
            .foregroundStyle(AlineColor.primary)
            .frame(width: 48, height: 48)
            .background(AlineColor.primary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(job.title)
                .font(AlineFont.sfPro(13, weight: .bold))
                .foregroundStyle(AlineColor.textPrimary)
                .lineLimit(1)
            Text(job.company)
                .font(AlineFont.sfPro(12))
                .foregroundStyle(AlineColor.textPrimary)
                .lineLimit(1)
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 10))
                Text(metaLine)
                    .font(AlineFont.sfPro(10))
            }
            .foregroundStyle(AlineColor.textPrimary)
            if let freshnessLabel = job.freshnessLabel {
                Text(freshnessLabel)
                    .font(AlineFont.sfPro(10, weight: .medium))
                    .foregroundStyle(AlineColor.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(freshnessLabel == "New" ? AlineColor.badgeHighlight : AlineColor.badgeHighlightMuted)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metaLine: String {
        let city = job.location.split(separator: ",").first.map(String.init) ?? job.location
        return "\(city) · Full-time"
    }

    private var scoreAndFavorite: some View {
        VStack(spacing: 10) {
            Button {
                onToggleLike?()
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundStyle(isLiked ? AlineColor.primary : AlineColor.textPrimary)
            }
            .buttonStyle(.plain)
            ZStack(alignment: .topTrailing) {
                BrandMatchRing(score: match.score, diameter: 44, lineWidth: 4)
                // A standout match earns the brand's sparkle signal — same "this is special"
                // meaning as the freshness badge, reserved for genuinely high matches (>85%)
                // rather than shown on every card.
                if match.score > 85 {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AlineColor.spark)
                        .offset(x: 3, y: -3)
                }
            }
        }
    }
}
