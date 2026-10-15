import Foundation

/// job.postedAt is whatever the source ATS platform sends, passed through close to verbatim
/// by each backend adapter — confirmed live (2026-10-13) to vary by platform: Greenhouse/
/// SmartRecruiters/Ashby send ISO8601 (with or without fractional seconds), Workday's
/// sitemap adapter sends a plain "yyyy-MM-dd" date, and Amazon sends a long-form date string
/// ("July 16, 2026"). Previously the UI interpolated this raw string directly into the
/// freshness badge ("New · 1788425813778" when Lever's epoch-millisecond createdAt leaked
/// through unconverted) — fixed at the source in lever.py, but the UI still needs to parse
/// whatever format actually arrives rather than assume one, and degrade to hiding the badge
/// (never show unparseable text) if a future adapter sends something new.
extension Job {
    private nonisolated(unsafe) static let isoWithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private nonisolated(unsafe) static let isoPlain = ISO8601DateFormatter()

    private nonisolated(unsafe) static let plainDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private nonisolated(unsafe) static let longForm: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var postedDate: Date? {
        guard let postedAt, !postedAt.isEmpty else { return nil }
        return Self.isoWithFractional.date(from: postedAt)
            ?? Self.isoPlain.date(from: postedAt)
            ?? Self.plainDate.date(from: postedAt)
            ?? Self.longForm.date(from: postedAt)
    }

    /// "New" inside 3 days (the lime badge's intent per the Figma source), otherwise a plain
    /// relative string ("2 weeks ago") in the same badge — nil (never shown) when the date
    /// can't be parsed at all, rather than falling back to raw source text.
    var freshnessLabel: String? {
        guard let postedDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: postedDate, to: Date()).day ?? 0
        if days <= 3 { return "New" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: postedDate, relativeTo: Date())
    }

    /// "Posted 3 days ago" / "Posted today" style line for the detail screen — nil when
    /// unparseable, same reasoning as freshnessLabel.
    var postedRelativeDescription: String? {
        guard let postedDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: postedDate, relativeTo: Date())
    }
}
