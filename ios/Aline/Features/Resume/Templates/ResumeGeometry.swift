import SwiftUI

/// Fixed page geometry every template renders at — A4, not US Letter, since the whole
/// target audience is India-based (per the plan's audience definition). Margins are generous
/// enough to read comfortably but tight enough to keep content density close to what real
/// one-page resumes use.
enum ResumePage {
    static let width: CGFloat = 595
    static let height: CGFloat = 842
    static let margin: CGFloat = 40
    static var contentWidth: CGFloat { width - margin * 2 }
    static var contentHeight: CGFloat { height - margin * 2 }
}
