import SwiftUI

/// The 3 fixed templates, decided against real industry standard (not the Figma reference,
/// which was for flow/screens only — see each template file's own doc comment for the
/// reasoning behind its specific design). All three share one structural rule applied for
/// ATS-parseability: single column, no tables, no embedded graphics. Only typography, color,
/// and section-heading treatment differ between them — which is also what keeps all three
/// safe from the "spacing drifts/breaks" problem fixed-template selection exists to prevent:
/// one shared ResumeProfile data shape, three fixed renderers, nothing user-adjustable at
/// the layout level.
enum ResumeTemplateID: String, CaseIterable, Identifiable, Codable {
    case standard
    case professional
    case modern

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: "Standard"
        case .professional: "Professional"
        case .modern: "Modern"
        }
    }

    var tagline: String {
        switch self {
        case .standard: "Clean and straightforward"
        case .professional: "Structured and polished"
        case .modern: "Minimal and contemporary"
        }
    }

    var bestFor: String {
        switch self {
        case .standard: "General applications"
        case .professional: "Corporate & tech roles"
        case .modern: "Startups & product roles"
        }
    }

    @ViewBuilder
    func view(profile: ResumeProfile, scale: CGFloat = 1.0, onSelectText: (@MainActor @Sendable (String) -> Void)? = nil) -> some View {
        switch self {
        case .standard: StandardResumeTemplate(profile: profile, scale: scale, onSelectText: onSelectText)
        case .professional: ProfessionalResumeTemplate(profile: profile, scale: scale, onSelectText: onSelectText)
        case .modern: ModernResumeTemplate(profile: profile, scale: scale, onSelectText: onSelectText)
        }
    }
}
