import SwiftUI
import SwiftData

struct ProfileView: View {
    let profile: CareerProfile
    @Query(sort: \SavedJob.savedAt, order: .reverse) private var savedJobs: [SavedJob]

    var body: some View {
        NavigationStack {
            List {
                Section("Career profile") {
                    LabeledContent("Skills", value: "\(profile.skills.count) extracted")
                    LabeledContent("Roles", value: profile.inferredRoles.joined(separator: ", "))
                }

                Section("Liked") {
                    let liked = savedJobs.filter { !$0.isApplied }
                    if liked.isEmpty {
                        Text("No liked jobs yet.").foregroundStyle(AlineColor.stone)
                    } else {
                        ForEach(liked) { saved in
                            VStack(alignment: .leading) {
                                Text(saved.title).font(AlineFont.body(14, weight: .medium))
                                Text(saved.company).font(AlineFont.body(12)).foregroundStyle(AlineColor.stone)
                            }
                        }
                    }
                }

                Section("Applied") {
                    let applied = savedJobs.filter { $0.isApplied }
                    if applied.isEmpty {
                        Text("No applications tracked yet.").foregroundStyle(AlineColor.stone)
                    } else {
                        ForEach(applied) { saved in
                            VStack(alignment: .leading) {
                                Text(saved.title).font(AlineFont.body(14, weight: .medium))
                                Text(saved.company).font(AlineFont.body(12)).foregroundStyle(AlineColor.stone)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
