import Foundation
import Observation

/// Owned once by RootTabView and shared via environment — both ProfileView and
/// ResumeDashboardView need the SAME loaded profile state (the latter to gate resume creation
/// without an extra network round-trip on every tap), not two independent copies that could
/// disagree about whether the profile is complete.
@MainActor
@Observable
final class ProfileViewModel {
    var profile: UserProfileData = .empty
    var isLoaded = false
    var errorMessage: String?

    func load() async {
        do {
            profile = try await ProfileAPI.fetch()
            isLoaded = true
        } catch {
            errorMessage = "Couldn't reach the backend. Is it running on 127.0.0.1:8000?"
        }
    }

    @discardableResult
    func save(_ updated: UserProfileData) async -> Bool {
        do {
            profile = try await ProfileAPI.update(updated)
            return true
        } catch {
            errorMessage = "Couldn't save — check the backend is running and try again."
            return false
        }
    }
}
