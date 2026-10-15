import Foundation

/// The device-scoped anonymous identity Community posts under — a UUID generated once and
/// persisted locally, sent as `device_id` on every community request. The backend maps this
/// to a system-generated, unique USERNAME THE USER CANNOT CHOOSE OR EDIT (see
/// community_db.py's module docstring for the full identity model and its real limitation: no
/// actual auth yet, so this is spoofable — acceptable for an anonymous-forum MVP, not for
/// anything security-sensitive).
///
/// UserDefaults, not Keychain: this ID is not a secret (it's never used for anything but
/// posting as "Anonymous · <role>" in a community forum), and UserDefaults already matches how
/// onboarding completion/profile data persist elsewhere in this app (see AlineApp.swift's
/// @AppStorage usage). A reinstalled app gets a new identity and a new username — a known,
/// acceptable limitation at this stage, not a bug to silently work around.
enum DeviceIdentity {
    private static let deviceIDKey = "communityDeviceID"

    static var deviceID: String {
        if let existing = UserDefaults.standard.string(forKey: deviceIDKey) {
            return existing
        }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: deviceIDKey)
        return fresh
    }
}
