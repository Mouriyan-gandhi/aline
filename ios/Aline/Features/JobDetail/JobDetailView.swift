import SwiftUI
import SwiftData

/// Job detail answers one question first (spec section 29): should I apply? Match → why →
/// missing → apply. Chunked, not a JD dump (Miller's Law, section 30) — the raw JD text is
/// never shown directly; it passes through JobSummarizer (on-device Foundation Models, see
/// AI/JobSummarizer.swift) first, and what renders here is four short sections (overview,
/// requirements, responsibilities, skills), not a wall of prose.
struct JobDetailView: View {
    let job: Job
    let match: MatchResult

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var savedJobs: [SavedJob]
    @Query(sort: \ResumeDocument.updatedAt, order: .reverse) private var resumeDocuments: [ResumeDocument]
    @State private var askedIfApplied = false
    @State private var summary: JobSummaryResult?
    @State private var isShowingTailorSheet = false

    private var defaultResumeDocument: ResumeDocument? {
        resumeDocuments.first { $0.isDefault } ?? resumeDocuments.first
    }

    private var savedJob: SavedJob? {
        savedJobs.first { $0.jobID == job.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                matchSection
                summarySection
                if !match.matchedSkills.isEmpty {
                    whySection
                }
                if !match.missingSkills.isEmpty {
                    missingSection
                }
                tailorResumeButton
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
        .sheet(isPresented: $isShowingTailorSheet) {
            if let defaultResumeDocument {
                NavigationStack {
                    ResumeDetailView(document: defaultResumeDocument, targetJob: job)
                }
            } else {
                NoResumeYetView()
            }
        }
        .task(id: job.id) {
            summary = await JobSummarizer.summarize(job: job)
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

    @ViewBuilder
    private var summarySection: some View {
        if job.description.isEmpty {
            EmptyView()
        } else if let summary {
            VStack(alignment: .leading, spacing: 16) {
                summaryBlock(title: "Overview") {
                    Text(summary.overview)
                        .font(AlineFont.body(14))
                        .foregroundStyle(AlineColor.charcoal)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !summary.requirements.isEmpty {
                    summaryBlock(title: "Requirements") {
                        bulletList(summary.requirements)
                    }
                }
                if !summary.responsibilities.isEmpty {
                    summaryBlock(title: "Responsibilities") {
                        bulletList(summary.responsibilities)
                    }
                }
                if !summary.skills.isEmpty {
                    summaryBlock(title: "Skills") {
                        skillChips(summary.skills)
                    }
                }
            }
        } else {
            // Summarizing on-device isn't instant (a few seconds, typically) — show that
            // something's happening rather than a blank gap where the summary will land.
            HStack(spacing: 8) {
                ProgressView().tint(AlineColor.electricCobalt)
                Text("Summarizing the listing…")
                    .font(AlineFont.body(13))
                    .foregroundStyle(AlineColor.stone)
            }
        }
    }

    private func summaryBlock(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(AlineFont.body(12, weight: .medium))
                .foregroundStyle(AlineColor.stone)
            content()
        }
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(AlineColor.electricCobalt)
                        .frame(width: 5, height: 5)
                        .padding(.top, 6)
                    Text(item)
                        .font(AlineFont.body(14))
                        .foregroundStyle(AlineColor.charcoal)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func skillChips(_ skills: [String]) -> some View {
        // Same wrapping-chip presentation as the rest of the app's skill tags (JobCardView)
        // — a job's required skills should look like the same kind of object everywhere.
        FlowLayout(spacing: 6) {
            ForEach(skills, id: \.self) { skill in
                Text(skill)
                    .font(AlineFont.body(12, weight: .medium))
                    .foregroundStyle(AlineColor.inkNavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AlineColor.lavenderMist)
                    .clipShape(Capsule())
            }
        }
    }

    // The JD-driven tailoring entry point: tapping this hands the job's own extracted
    // skills into ResumeDetailView's keyword-gap section (see missingSkills(for:) there) —
    // "that job information is being circulated into the pipeline" is this parameter, not a
    // separate system. Uses the default resume if one exists; if the person has never built
    // one yet, nudges them to the Resume tab rather than failing silently.
    private var tailorResumeButton: some View {
        Button {
            isShowingTailorSheet = true
        } label: {
            Label("Tailor Resume for This Job", systemImage: "sparkles").frame(maxWidth: .infinity)
        }
        .font(AlineFont.body(15, weight: .medium))
        .foregroundStyle(AlineColor.inkNavy)
        .padding(.vertical, 12)
        .overlay(RoundedRectangle(cornerRadius: AlineRadius.card).stroke(AlineColor.creamBorder))
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

private struct NoResumeYetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text").font(.system(size: 36)).foregroundStyle(AlineColor.stone)
            Text("No resume yet").font(AlineFont.body(16, weight: .medium)).foregroundStyle(AlineColor.inkNavy)
            Text("Build a resume in the Resume tab first, then come back here to tailor it for this job.")
                .font(AlineFont.body(14)).foregroundStyle(AlineColor.stone)
                .multilineTextAlignment(.center)
            Button("Got it") { dismiss() }
                .buttonStyle(AlinePrimaryButtonStyle())
        }
        .padding(32)
    }
}
