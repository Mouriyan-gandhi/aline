import SwiftUI
import UserNotifications

/// The toggle itself is real and persists locally (@AppStorage). What's still honestly
/// stubbed: there's no backend push pipeline yet (no APNs device-token registration, no
/// server-side "new matching job" trigger) — see DiscoverView's own notification-bell alert
/// for the same standing note. Turning this on does one genuinely real thing right now:
/// requests system notification permission, so the permission prompt isn't deferred to some
/// future day-one-of-push-infra moment where it'd feel like a surprise.
struct JobAlertsView: View {
    @AppStorage("jobAlertsEnabled") private var jobAlertsEnabled = true
    @State private var authorizationStatus: UNAuthorizationStatus?
    @State private var showSettingsPrompt = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: Binding(
                    get: { jobAlertsEnabled },
                    set: { newValue in
                        jobAlertsEnabled = newValue
                        if newValue { requestPermission() }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Job alerts").font(AlineFont.sfPro(15, weight: .semibold)).foregroundStyle(AlineColor.textPrimary)
                        Text("Get notified about new matching opportunities.")
                            .font(AlineFont.sfPro(12)).foregroundStyle(AlineColor.textSecondary)
                    }
                }
                .tint(AlineColor.primary)
                .padding(14)
                .background(AlineColor.paperWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))

                if let authorizationStatus {
                    statusNote(for: authorizationStatus)
                }

                Text("The actual push pipeline (device registration, server-side delivery when a new job matches you) isn't built yet — this currently just controls the system permission and your local preference.")
                    .font(AlineFont.sfPro(11))
                    .foregroundStyle(AlineColor.textSecondary)
            }
            .padding(20)
        }
        .background(AlineColor.canvas)
        .navigationTitle("Job Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshStatus() }
        .alert("Notifications are off", isPresented: $showSettingsPrompt) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You've previously denied notification permission. Enable it in Settings to actually receive alerts.")
        }
    }

    @ViewBuilder
    private func statusNote(for status: UNAuthorizationStatus) -> some View {
        switch status {
        case .denied:
            Button { showSettingsPrompt = true } label: {
                Label("Notifications are blocked in iOS Settings", systemImage: "exclamationmark.triangle.fill")
            }
            .font(AlineFont.sfPro(12, weight: .semibold))
            .foregroundStyle(.red)
        case .authorized, .provisional:
            Label("System notifications are allowed", systemImage: "checkmark.circle.fill")
                .font(AlineFont.sfPro(12, weight: .semibold))
                .foregroundStyle(AlineColor.primary)
        default:
            EmptyView()
        }
    }

    private func requestPermission() {
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await refreshStatus()
        }
    }

    private func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
}
