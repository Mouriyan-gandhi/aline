import SwiftUI
import SwiftData

/// Job detail answers one question first (spec section 29): should I apply? Match → why →
/// missing → apply. Chunked, not a JD dump (Miller's Law, section 30).
struct JobDetailView: View {
    let job: Job
    let match: MatchResult

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var savedJobs: [SavedJob]
    @State private var askedIfApplied = false

    private var savedJob: SavedJob? {
        savedJobs.first { $0.jobID == job.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                matchSection
                if !match.matchedSkills.isEmpty {
                    whySection
                }
                if !match.missingSkills.isEmpty {
                    missingSection
                }
                if !job.description.isEmpty {
                    descriptionSection
                }
                applyButton
            }
            .padding(16)
        }
        .background(AlineColor.warmCanvas)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleLike()
                } label: {
                    Image(systemName: savedJob != nil ? "heart.fill" : "heart")
                        .foregroundStyle(AlineColor.electricCobalt)
                }
            }
        }
        .alert("Did you apply?", isPresented: $askedIfApplied) {
            Button("Yes") { markApplied() }
            Button("Not yet", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(job.company)
                .font(AlineFont.body(14, weight: .medium))
                .foregroundStyle(AlineColor.stone)
            Text(job.title)
                .font(AlineFont.display(28))
                .foregroundStyle(AlineColor.inkNavy)
            HStack(spacing: 12) {
                Label(job.location, systemImage: "mappin.and.ellipse")
                if let posted = job.postedAt {
                    Label(posted, systemImage: "clock")
                }
            }
            .font(AlineFont.body(13))
            .foregroundStyle(AlineColor.graphite)
        }
    }

    private var matchSection: some View {
        PaperCard {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(match.score)% MATCH")
                        .font(AlineFont.body(16, weight: .medium))
                        .foregroundStyle(AlineColor.electricCobalt)
                    Text("Based on your resume's extracted skills")
                        .font(AlineFont.body(12))
                        .foregroundStyle(AlineColor.stone)
                }
                Spacer()
            }
        }
    }

    private var whySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why you're a match").font(AlineFont.body(15, weight: .medium)).foregroundStyle(AlineColor.inkNavy)
            ForEach(match.matchedSkills, id: \.self) { skill in
                Label(skill, systemImage: "checkmark").foregroundStyle(AlineColor.charcoal)
            }
        }
        .font(AlineFont.body(14))
    }

    private var missingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Potential gaps").font(AlineFont.body(15, weight: .medium)).foregroundStyle(AlineColor.inkNavy)
            ForEach(match.missingSkills, id: \.self) { skill in
                Label(skill, systemImage: "triangle").foregroundStyle(AlineColor.graphite)
            }
        }
        .font(AlineFont.body(14))
    }

    // Collapsed by default, not inline body text — the screen's own doc comment (spec
    // section 29/30) is deliberate: match → why → gaps answers "should I apply?" before
    // anything else. The real JD still needs to be here (people reasonably want to read it
    // before applying, not just a skill tally), it just shouldn't be the first thing shown.
    private var descriptionSection: some View {
        DisclosureGroup("Full job description") {
            Text(job.description)
                .font(AlineFont.body(14))
                .foregroundStyle(AlineColor.charcoal)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
        .font(AlineFont.body(15, weight: .medium))
        .foregroundStyle(AlineColor.inkNavy)
        .tint(AlineColor.electricCobalt)
    }

    private var applyButton: some View {
        Button {
            if let url = URL(string: job.applyURL) {
                openURL(url)
                askedIfApplied = true
            }
        } label: {
            Text("Apply on \(job.company) ↗").frame(maxWidth: .infinity)
        }
        .buttonStyle(AlinePrimaryButtonStyle())
    }

    private func toggleLike() {
        if let existing = savedJob {
            modelContext.delete(existing)
        } else {
            modelContext.insert(SavedJob(job: job))
        }
    }

    private func markApplied() {
        if let existing = savedJob {
            existing.isApplied = true
        } else {
            modelContext.insert(SavedJob(job: job, isApplied: true))
        }
    }
}
