import SwiftUI

/// Milestone 0 placeholder — the resume dashboard, tailoring, and 3 ATS-parseability-first
/// templates are real Phase 1 work (plan "Build order"), not something to fake tonight. This
/// shows the real skills just extracted from the uploaded resume, honestly labeled.
struct ResumeView: View {
    let profile: CareerProfile

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Master Resume").font(AlineFont.display(26)).foregroundStyle(AlineColor.inkNavy)

                    PaperCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Extracted skills").font(AlineFont.body(14, weight: .medium)).foregroundStyle(AlineColor.graphite)
                            WrapChips(items: profile.skills)
                        }
                    }

                    Text("Tailoring, ATS scoring, and PDF export land in Phase 1.")
                        .font(AlineFont.body(13))
                        .foregroundStyle(AlineColor.stone)
                }
                .padding(16)
            }
            .background(AlineColor.warmCanvas)
        }
    }
}

private struct WrapChips: View {
    let items: [String]
    var body: some View {
        if items.isEmpty {
            Text("No skills extracted yet.").font(AlineFont.body(13)).foregroundStyle(AlineColor.stone)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
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
}
