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
