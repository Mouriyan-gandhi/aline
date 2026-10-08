import Foundation
import SwiftData

@Model
final class SavedJob {
    @Attribute(.unique) var jobID: String
    var company: String
    var title: String
    var location: String
    var applyURL: String
    var isApplied: Bool
    var savedAt: Date

    init(job: Job, isApplied: Bool = false) {
        self.jobID = job.id
        self.company = job.company
        self.title = job.title
        self.location = job.location
        self.applyURL = job.applyURL
        self.isApplied = isApplied
        self.savedAt = Date()
    }
}

/// A saved, structured resume plus which fixed template it's rendered with. Stored as
/// encoded JSON (`profileData`), not as native SwiftData relationships — ResumeProfile's
/// nested arrays-of-structs (education/experience/projects/skillCategories) are exactly the
/// shape SwiftData's own docs call out as unreliable across OS versions when modeled as
/// native relationships; a single JSON blob with a typed computed accessor sidesteps that
/// entirely and is the same pattern CareerProfile already uses for @AppStorage persistence.
@Model
final class ResumeDocument {
    @Attribute(.unique) var id: String
    var displayName: String
    var templateID: String
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date
    private var profileData: Data

    var profile: ResumeProfile {
        get { (try? JSONDecoder().decode(ResumeProfile.self, from: profileData)) ?? .empty }
        set { profileData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init(displayName: String, templateID: String, profile: ResumeProfile, isDefault: Bool = false) {
        self.id = UUID().uuidString
        self.displayName = displayName
        self.templateID = templateID
        self.isDefault = isDefault
        self.createdAt = Date()
        self.updatedAt = Date()
        self.profileData = (try? JSONEncoder().encode(profile)) ?? Data()
    }
}
