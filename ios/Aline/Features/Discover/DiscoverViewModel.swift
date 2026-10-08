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

    init(profile: CareerProfile) {
        self.profile = profile
    }

    func load() async {
        state = .loading
        do {
            let fetched = try await JobsAPI.fetchJobs()
            jobs = fetched.sorted { job(for: $0).score > job(for: $1).score }
            state = .loaded
        } catch {
            state = .failed("Couldn't reach the backend. Is it running on 127.0.0.1:8000?")
        }
    }

    func job(for job: Job) -> MatchResult {
        MatchEngine.match(profile: profile, job: job)
    }
}
