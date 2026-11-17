import BackgroundTasks
import Foundation
import UserNotifications

/// Opportunity Alerts: a notification when a new job crosses the Recommended threshold.
///
/// Local notifications, not remote push — the matching runs on device (the backend never sees
/// the profile scored against jobs), so the device itself decides what's new and relevant.
/// It checks after every feed refresh in the app, and in the background through a
/// BGAppRefreshTask that iOS runs periodically (timing is up to iOS: typically a few times a
/// day, more often for apps opened regularly).
enum JobAlerts {
    static let refreshTaskID = "com.alineapp3.career.jobrefresh"
    private static let notifiedKey = "jobAlertNotifiedIDs"
    /// Posted with the tapped alert's job id
    static let openJobNotification = Notification.Name("AlineOpenJobFromAlert")

    /// The user's Opportunity Alerts toggle, from the cached career preferences
    static var isEnabled: Bool {
        cachedPreferences?.alertsEnabled ?? true
    }

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Notifies about recommended jobs from the last few days that haven't been alerted before.
    static func notifyNewMatches(_ opportunities: [Opportunity]) async {
        guard isEnabled else { return }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        var notified = Set(UserDefaults.standard.stringArray(forKey: notifiedKey) ?? [])
        let fresh = opportunities.filter {
            $0.matchScore >= DiscoverViewModel.recommendedThreshold && !$0.recency.isEmpty
                && $0.recencyInMinutes <= 3 * 1440 && !notified.contains($0.id)
        }
        guard !fresh.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        if fresh.count <= 3 {
            for opp in fresh {
                let content = UNMutableNotificationContent()
                content.title = "\(opp.matchScore)% match at \(opp.companyName)"
                content.body = "\(opp.roleTitle) · \(opp.location)"
                content.sound = .default
                content.userInfo = ["jobId": opp.id]
                try? await center.add(UNNotificationRequest(identifier: "job-\(opp.id)", content: content, trigger: nil))
            }
        } else {
            let best = fresh.max { $0.matchScore < $1.matchScore }!
            let content = UNMutableNotificationContent()
            content.title = "\(fresh.count) new jobs match your profile"
            content.body = "Top match: \(best.roleTitle) at \(best.companyName) (\(best.matchScore)%)"
            content.sound = .default
            content.userInfo = ["jobId": best.id]
            try? await center.add(UNNotificationRequest(identifier: "jobs-\(UUID().uuidString)", content: content, trigger: nil))
        }
        notified.formUnion(fresh.map(\.id))
        UserDefaults.standard.set(Array(notified.suffix(2000)), forKey: notifiedKey)
    }

    // MARK: Background refresh

    static func registerBackgroundRefresh() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskID, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            scheduleBackgroundRefresh()
            let work = Task { @MainActor in
                await checkInBackground()
                task.setTaskCompleted(success: true)
            }
            task.expirationHandler = { work.cancel() }
        }
    }

    static func scheduleBackgroundRefresh() {
        guard isEnabled else { return }
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3 * 3600)
        Task { try? await BGTaskScheduler.shared.submitTaskRequest(request) }
    }

    /// Fetches the feed and scores it against the profile cached on this device.
    /// Uses the backend's scores for this user (~30 KB gzipped) with the job details already
    /// cached on the device — not the full ~1.8 MB feed — so a background check stays cheap.
    @MainActor
    private static func checkInBackground() async {
        guard isEnabled, let recommendations = try? await AlineAPI.recommendations() else { return }
        let feedURL = URL.cachesDirectory.appendingPathComponent("jobs-feed.json")
        guard let data = try? Data(contentsOf: feedURL),
              let jobs = try? JSONDecoder().decode([JobDTO].self, from: data) else { return }
        let byID = Dictionary(jobs.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let opportunities = recommendations.results.compactMap { rec -> Opportunity? in
            guard let job = byID[rec.jobId] else { return nil }
            return Opportunity(
                job: job, match: MatchResult(score: rec.score, matchedSkills: rec.matchedSkills, missingSkills: rec.missingSkills),
                isLiked: false, isApplied: false, appliedAt: nil
            )
        }
        await notifyNewMatches(opportunities)
    }

    private static var cachedPreferences: CareerPreferences? {
        cached(CareerPreferences.self, key: "savedCareerPreferences")
    }

    private static func cached<T: Decodable>(_ type: T.Type, key: String) -> T? {
        UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }
}

/// Shows alerts while the app is open and routes a tapped alert to its job.
final class JobAlertNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = JobAlertNotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let jobId = response.notification.request.content.userInfo["jobId"] as? String else { return }
        await MainActor.run {
            NotificationCenter.default.post(name: JobAlerts.openJobNotification, object: jobId)
        }
    }
}
