import SwiftUI
import SwiftData

/// Replaces the old Milestone 0 placeholder ResumeView. "My resumes" + "Create New Resume,"
/// matching the Figma reference's flow (used for navigation structure only — template visual
/// design is decided independently, see Templates/).
struct ResumeDashboardView: View {
    let careerProfile: CareerProfile

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ResumeDocument.updatedAt, order: .reverse) private var documents: [ResumeDocument]
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("My resumes").font(AlineFont.display(24)).foregroundStyle(AlineColor.inkNavy)
                        Spacer()
                        Button {
                            path.append(ResumeRoute.addResume)
                        } label: {
                            Label("Add Resume", systemImage: "plus")
                        }
                        .font(AlineFont.body(13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(AlineColor.inkNavy)
                        .clipShape(Capsule())
                    }

                    if documents.isEmpty {
                        PaperCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("No resumes yet").font(AlineFont.body(14, weight: .medium)).foregroundStyle(AlineColor.inkNavy)
                                Text("Add your resume to get started, or build one from scratch below.")
                                    .font(AlineFont.body(13)).foregroundStyle(AlineColor.stone)
                            }
                        }
                    } else {
                        ForEach(documents) { doc in
                            Button { path.append(ResumeRoute.detail(doc.id)) } label: {
                                resumeRow(doc)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    PaperCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Tailor your resume with AI", systemImage: "sparkles")
                                .font(AlineFont.body(14, weight: .medium))
                                .foregroundStyle(AlineColor.inkNavy)
                            Text("Strengthen your summary and experience for every opportunity in a few guided steps.")
                                .font(AlineFont.body(13)).foregroundStyle(AlineColor.stone)
                            Button {
                                path.append(ResumeRoute.addResume)
                            } label: {
                                Label("Create New Resume", systemImage: "plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(AlinePrimaryButtonStyle())
                        }
                    }
                }
                .padding(16)
            }
            .background(AlineColor.warmCanvas)
            .navigationDestination(for: ResumeRoute.self) { route in
                switch route {
                case .addResume:
                    AddResumeView(careerProfile: careerProfile, path: $path)
                case .manualEntry:
                    ManualProfileEditorView(initialProfile: .empty, path: $path)
                case .chooseTemplate(let profileID):
                    if let profile = PendingProfileStore.shared.take(profileID) {
                        ChooseTemplateView(profile: profile, path: $path)
                    }
                case .detail(let documentID):
                    if let doc = documents.first(where: { $0.id == documentID }) {
                        ResumeDetailView(document: doc)
                    }
                }
            }
        }
    }

    private func resumeRow(_ doc: ResumeDocument) -> some View {
        PaperCard {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(AlineColor.inkNavy)
                    .frame(width: 32, height: 32)
                    .background(AlineColor.lavenderMist)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.displayName).font(AlineFont.body(14, weight: .medium)).foregroundStyle(AlineColor.inkNavy)
                    Text("Updated \(doc.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(AlineFont.body(12)).foregroundStyle(AlineColor.stone)
                }
                Spacer()
                if doc.isDefault {
                    Text("Default")
                        .font(AlineFont.body(11, weight: .medium))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(AlineColor.lavenderMist)
                        .foregroundStyle(AlineColor.inkNavy)
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.right").foregroundStyle(AlineColor.stone).font(.system(size: 12))
            }
        }
    }
}

enum ResumeRoute: Hashable {
    case addResume
    case manualEntry
    case chooseTemplate(String)
    case detail(String)
}

/// Passing a full ResumeProfile through NavigationPath directly would require it to be
/// Hashable AND hashed into the path's type-erased storage on every push — fine for small
/// structs, unnecessarily heavy for one that can hold a full resume's worth of text. A
/// short-lived in-memory handoff avoids re-encoding/decoding the whole profile through the
/// navigation path machinery for what is, structurally, just "the result of the previous
/// screen," not real app state.
@MainActor
final class PendingProfileStore {
    static let shared = PendingProfileStore()
    private var profiles: [String: ResumeProfile] = [:]

    func store(_ profile: ResumeProfile) -> String {
        let id = UUID().uuidString
        profiles[id] = profile
        return id
    }

    func take(_ id: String) -> ResumeProfile? {
        profiles.removeValue(forKey: id)
    }
}
