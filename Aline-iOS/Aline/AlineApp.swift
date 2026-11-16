import SwiftUI
import UserNotifications

@main
struct AlineApp: App {
    init() {
        // Opportunity Alerts: background job checks and tap-to-open (see JobAlerts)
        JobAlerts.registerBackgroundRefresh()
        UNUserNotificationCenter.current().delegate = JobAlertNotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environment(\.colorScheme, .light)
        }
    }
}


