import SwiftUI

/// The job card must never become a dashboard (spec section 22): what, where, why care, how
/// fresh. Nothing more.
struct JobCardView: View {
    let job: Job
    let match: MatchResult

    var body: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(job.company)
                            .font(AlineFont.body(13, weight: .medium))
                            .foregroundStyle(AlineColor.stone)
                        Text(job.title)
                            .font(AlineFont.display(20))
                            .foregroundStyle(AlineColor.inkNavy)
                    }
                    Spacer()
                    MatchRing(score: match.score)
                }

                HStack(spacing: 12) {
                    Label(job.location, systemImage: "mappin.and.ellipse")
                    if !job.department.isEmpty {
                        Label(job.department, systemImage: "folder")
                    }
                }
                .font(AlineFont.body(13))
                .foregroundStyle(AlineColor.graphite)

                if !match.matchedSkills.isEmpty {
                    SkillChips(skills: Array(match.matchedSkills.prefix(4)))
                }
            }
        }
    }
}

private struct MatchRing: View {
    let score: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(AlineColor.creamBorder, lineWidth: 4)
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(AlineColor.electricCobalt, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(AlineFont.body(13, weight: .medium))
                .foregroundStyle(AlineColor.inkNavy)
        }
        .frame(width: 44, height: 44)
    }
}

private struct SkillChips: View {
    let skills: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(skills, id: \.self) { skill in
                Text(skill)
                    .font(AlineFont.body(12, weight: .medium))
                    .foregroundStyle(AlineColor.inkNavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AlineColor.lavenderMist)
                    .clipShape(Capsule())
            }
        }
    }
}
