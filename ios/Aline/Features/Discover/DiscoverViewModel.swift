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

    // Client-side filtering — all jobs are already loaded in memory (full registry scale is
    // ~1000, trivial to filter in-process), so this doesn't need a backend round-trip. Both
    // are Sets so the filter sheet can multi-select; empty set means "no filter applied."
    var selectedCompanies: Set<String> = []
    var selectedRoles: Set<String> = []

    // Computed once per load(), not re-derived on every sort comparison or card render.
    // At full registry scale (1000+ jobs), `sorted(by:)` alone calls its comparator
    // O(n log n) times, each invoking both sides — recomputing MatchEngine.match() on
    // demand there (and again per card on every scroll-triggered re-render) means tens of
    // thousands of redundant set-math calls for data that never changes after load.
    private var matchCache: [String: MatchResult] = [:]

    init(profile: CareerProfile) {
        self.profile = profile
    }

    func load() async {
        state = .loading
        do {
            let fetched = try await JobsAPI.fetchJobs()
            // NOT Dictionary(uniqueKeysWithValues:) — that hard-crashes the app on any
            // duplicate id. Found live: the backend had a real dedup gap (a Workday company
            // publishing the same job through two sitemaps) that produced one, and crashed
            // every launch until fixed server-side. Fixed at the source too, but a single
            // malformed record from any future adapter bug should never be able to take the
            // whole app down — last-value-wins on a duplicate is the correct fallback.
            matchCache = fetched.reduce(into: [:]) { cache, job in
                cache[job.id] = MatchEngine.match(profile: profile, job: job)
            }
            // Dedupe by id — ForEach(Identifiable) doesn't crash on duplicates like the
            // dictionary above did, but silently produces glitchy/undefined row behavior,
            // which is its own bug worth not shipping.
            var seenIDs: Set<String> = []
            let deduped = fetched.filter { seenIDs.insert($0.id).inserted }
            jobs = deduped.sorted { job(for: $0).score > job(for: $1).score }
            state = .loaded
        } catch {
            state = .failed("Couldn't reach the backend. Is it running on 127.0.0.1:8000?")
        }
    }

    func job(for job: Job) -> MatchResult {
        matchCache[job.id] ?? MatchEngine.match(profile: profile, job: job)
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
