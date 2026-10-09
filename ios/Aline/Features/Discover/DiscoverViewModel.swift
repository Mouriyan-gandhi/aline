import Foundation
import Observation

enum DiscoverLoadState {
    case loading
    case loaded
    case failed(String)
}

@MainActor
@Observable
final class DiscoverViewModel {
    var jobs: [Job] = []
    var state: DiscoverLoadState = .loading
    let profile: CareerProfile
    var preferences: UserPreferences
    /// The user's default ResumeDocument's profile, when one exists — set from the View via
    /// a SwiftData @Query (view models don't get @Query directly), since it can change
    /// anytime the person edits their resume in the Resume tab, not just at load time.
    var resumeProfile: ResumeProfile? {
        didSet { recomputeMatches() }
    }

    // Client-side filtering — all jobs are already loaded in memory (full registry scale is
    // ~1000, trivial to filter in-process), so this doesn't need a backend round-trip. Both
    // are Sets so the filter sheet can multi-select; empty set means "no filter applied."
    var selectedCompanies: Set<String> = []
    var selectedRoles: Set<String> = []

    // Computed once per load()/profile change, not re-derived on every sort comparison or
    // card render. At full registry scale (1000+ jobs), `sorted(by:)` alone calls its
    // comparator O(n log n) times, each invoking both sides — recomputing MatchEngine.match()
    // on demand there (and again per card on every scroll-triggered re-render) means tens of
    // thousands of redundant set-math calls for data that never changes between loads.
    private var matchCache: [String: MatchResult] = [:]

    init(profile: CareerProfile, preferences: UserPreferences = .empty) {
        self.profile = profile
        self.preferences = preferences
    }

    func load() async {
        state = .loading
        do {
            let fetched = try await JobsAPI.fetchJobs()
            // Dedupe by id BEFORE anything else — ForEach(Identifiable) doesn't crash on
            // duplicates the way Dictionary(uniqueKeysWithValues:) does, but silently
            // produces glitchy/undefined row behavior, which is its own bug worth not
            // shipping. Found live: the backend had a real dedup gap (a Workday company
            // publishing the same job through two sitemaps) that produced one.
            var seenIDs: Set<String> = []
            jobs = fetched.filter { seenIDs.insert($0.id).inserted }
            recomputeMatches()
            state = .loaded
        } catch {
            state = .failed("Couldn't reach the backend. Is it running on 127.0.0.1:8000?")
        }
    }

    /// Rebuilds the match cache and re-sorts — split out from load() so changing
    /// resumeProfile/preferences (e.g. the person just finished building their resume, or
    /// edited it) can refresh ranking without a network round-trip.
    private func recomputeMatches() {
        matchCache = jobs.reduce(into: [:]) { cache, job in
            cache[job.id] = MatchEngine.match(
                resumeProfile: resumeProfile, careerProfile: profile, preferences: preferences, job: job
            )
        }
        jobs.sort { job(for: $0).score > job(for: $1).score }
    }

    func job(for job: Job) -> MatchResult {
        matchCache[job.id] ?? MatchEngine.match(
            resumeProfile: resumeProfile, careerProfile: profile, preferences: preferences, job: job
        )
    }

    /// Companies present in the currently loaded jobs, alphabetical — the filter sheet's
    /// company list is always "what's actually in the feed right now," never a stale or
    /// hardcoded list that could show a company with zero current postings.
    var availableCompanies: [String] {
        Array(Set(jobs.map(\.company))).sorted()
    }

    var filteredJobs: [Job] {
        guard !selectedCompanies.isEmpty || !selectedRoles.isEmpty else { return jobs }
        return jobs.filter { job in
            let companyOK = selectedCompanies.isEmpty || selectedCompanies.contains(job.company)
            let roleOK = selectedRoles.isEmpty
                || RoleCategory.all
                    .filter { selectedRoles.contains($0.name) }
                    .contains { $0.matches(title: job.title) }
            return companyOK && roleOK
        }
    }

    var activeFilterCount: Int {
        (selectedCompanies.isEmpty ? 0 : 1) + (selectedRoles.isEmpty ? 0 : 1)
    }

    func clearFilters() {
        selectedCompanies.removeAll()
        selectedRoles.removeAll()
    }
}
