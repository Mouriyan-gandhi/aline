import Foundation

enum JobsAPIError: Error {
    case badResponse
}

struct JobsAPI {
    /// Simulator shares the host Mac's network namespace, so localhost reaches the
    /// FastAPI backend directly. A physical device would need the Mac's LAN IP instead —
    /// that's a Phase 1 concern once there's a real deployed backend to point at.
    static let baseURL = URL(string: "http://127.0.0.1:8000")!

    static func fetchJobs() async throws -> [Job] {
        // The backend's cache is instant once warm, but a cold start (or post-TTL refresh)
        // live-scrapes the whole registry. Measured directly at 245 companies (40 of them
        // Workday, via the sitemap+JSON-LD adapter): ~360s. Give real headroom above that —
        // and once deployed to Render's free tier, add ~60s more for its cold-start wake if
        // the service had spun down from inactivity.
        var request = URLRequest(url: baseURL.appendingPathComponent("jobs"))
        request.timeoutInterval = 480

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw JobsAPIError.badResponse
        }
        return try JSONDecoder().decode([Job].self, from: data)
    }
}
