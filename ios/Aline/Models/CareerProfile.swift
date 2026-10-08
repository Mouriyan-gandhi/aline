import Foundation

/// The structured result of parsing a resume — on-device, once (spec section 31/45: the
/// structured profile is the source of truth, not the raw PDF).
struct CareerProfile: Codable, Hashable {
    var skills: [String] = []
    var inferredRoles: [String] = []
    var education: String = ""
    var rawResumeText: String = ""

    static let empty = CareerProfile()
}
