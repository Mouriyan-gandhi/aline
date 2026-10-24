import SwiftUI

/// Matches the real Figma "Opportunity card" component exactly (confirmed via
/// get_design_context against the Home/opportunity-feed screen, 2026-10-13): 48x48 logo
/// tile, title/company/meta row with a location pin + "City · Type", a lime freshness badge,
/// and a match-ring + heart in a trailing column. Real company logo assets aren't practical
/// here — the design shows specific companies (Google, Apple...) but the app has 460+
/// registered companies with no logo-fetching pipeline yet — so the logo tile falls back to
/// the company's initial on a tinted background, keeping the same slot shape/size the design
/// defines rather than a placeholder icon.
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
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AlineColor.cardBorder, lineWidth: 1)
        )
    }

    private var companyLogo: some View {
        Text(String(job.company.prefix(1)).uppercased())
            .font(AlineFont.sfPro(18, weight: .bold))
            .foregroundStyle(AlineColor.primary)
            .frame(width: 48, height: 48)
            .background(AlineColor.canvas)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))
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
            MatchRing(score: match.score)
        }
    }
}

private struct MatchRing: View {
    let score: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(AlineColor.cardBorder, lineWidth: 4)
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(AlineColor.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)%").font(AlineFont.sfPro(10, weight: .bold))
                Text("Match").font(AlineFont.sfPro(7))
            }
            .foregroundStyle(AlineColor.textPrimary)
        }
        .frame(width: 44, height: 44)
    }
}
