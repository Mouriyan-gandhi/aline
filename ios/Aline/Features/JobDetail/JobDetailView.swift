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
            }
            .padding(16)
            .padding(.bottom, 8)
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
        // Pinned so the primary action (Apply) stays reachable while scrolling a potentially
        // long job description, instead of sitting at the end of the ScrollView where it's
        // only reachable after reading everything — a standard modern-iOS job-app pattern.
        .safeAreaInset(edge: .bottom) {
            actionBar
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
                if let posted = job.postedRelativeDescription {
                    Label(posted, systemImage: "clock")
                }
            }
            .font(AlineFont.body(13))
            .foregroundStyle(AlineColor.graphite)
        }
    }

    /// The app's actual differentiator — explainable match, not a bare job list — so it earns
    /// a real hero moment: a large gradient ring up front, not just a percentage text line.
    private var matchSection: some View {
        PaperCard {
            HStack(alignment: .top, spacing: 16) {
                BrandMatchRing(score: match.score, diameter: 88, lineWidth: 7)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Skills, experience fit, and your stated priorities")
                        .font(AlineFont.body(12))
                        .foregroundStyle(AlineColor.stone)
                    // Both of these are the explanation for components of the score that
                    // aren't the skill chips below — never leave a score component silently
                    // unexplained, same principle the skills why/gaps sections already follow.
                    if let experienceNote = match.experienceNote {
                        Label(experienceNote, systemImage: "clock.badge.checkmark")
                            .font(AlineFont.body(12))
                            .foregroundStyle(AlineColor.graphite)
                    }
                    if let priorityNote = match.priorityNote {
                        Label(priorityNote, systemImage: "mappin.and.ellipse")
                            .font(AlineFont.body(12))
                            .foregroundStyle(AlineColor.graphite)
                    }
                }
            }
        }
    }

    private var whySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why you're a match").font(AlineFont.body(15, weight: .medium)).foregroundStyle(AlineColor.inkNavy)
            FlowLayout(spacing: 6) {
                ForEach(match.matchedSkills, id: \.self) { skill in
                    matchChip(skill, matched: true)
                }
            }
        }
    }

    private var missingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Potential gaps").font(AlineFont.body(15, weight: .medium)).foregroundStyle(AlineColor.inkNavy)
            FlowLayout(spacing: 6) {
                ForEach(match.missingSkills, id: \.self) { skill in
                    matchChip(skill, matched: false)
                }
            }
        }
    }

    /// Checkmark chips in the brand color for matched skills, outline chips for gaps — same
    /// chip language as the job card and resume skill chips, so "a skill" looks like the same
    /// kind of object everywhere in the app.
    private func matchChip(_ skill: String, matched: Bool) -> some View {
        Label(skill, systemImage: matched ? "checkmark" : "circle.dashed")
            .font(AlineFont.body(12, weight: .medium))
            .foregroundStyle(matched ? .white : AlineColor.graphite)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                if matched {
                    Capsule().fill(AlineColor.primary)
                } else {
                    Capsule().stroke(AlineColor.creamBorder, lineWidth: 1)
                }
            }
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

    /// Pinned bottom bar holding both actions — Liquid Glass since this is exactly the
    /// "functional/control layer, always reachable" case the HIG calls out for `glassEffect`,
    /// the same reasoning as the tab bar. Tailor stays a compact icon-only secondary action so
    /// Apply (the actual primary action) keeps the visual weight.
    private var actionBar: some View {
        HStack(spacing: 10) {
            // The JD-driven tailoring entry point: tapping this hands the job's own extracted
            // skills into ResumeDetailView's keyword-gap section (see missingSkills(for:)
            // there). Uses the default resume if one exists; if the person has never built one
            // yet, nudges them to the Resume tab rather than failing silently.
            Button {
                isShowingTailorSheet = true
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AlineColor.primary)
                    .frame(width: 48, height: 48)
            }
            .modifier(GlassCircleBackground())

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
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
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
