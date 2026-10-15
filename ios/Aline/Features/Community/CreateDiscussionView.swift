import SwiftUI

/// Minimal compose flow — category + optional company + title + body, posted under the
/// device's system-generated username (see DeviceIdentity.swift). The real Figma flow splits
/// this into a "Select type" screen followed by 4 near-identical per-category compose screens
/// (Create Discussion · General/Recruitment/Work/Interview Experience) — functionally the same
/// form with a pre-selected category, so this single view with a category picker covers all
/// four without 4 near-duplicate SwiftUI files.
struct CreateDiscussionView: View {
    let viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var category: DiscussionCategory = .generalDiscussion
    @State private var company: String = ""
    @State private var title: String = ""
    @State private var postBody: String = ""
    @State private var selectedTopics: Set<DiscussionTopic> = []
    @State private var isPosting = false
    @State private var errorMessage: String?

    private var canPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !postBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Discussion type") {
                    Picker("Category", selection: $category) {
                        ForEach(DiscussionCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("Company · Optional") {
                    TextField("e.g. Google", text: $company)
                        .textInputAutocapitalization(.words)
                }
                Section("Title") {
                    TextField("Give your post a clear title", text: $title)
                }
                Section("Your story") {
                    TextEditor(text: $postBody)
                        .frame(minHeight: 160)
                }
                Section("Topics · Optional") {
                    FlowLayout(spacing: 7) {
                        ForEach(DiscussionTopic.allCases) { topic in
                            Button {
                                if selectedTopics.contains(topic) {
                                    selectedTopics.remove(topic)
                                } else {
                                    selectedTopics.insert(topic)
                                }
                            } label: {
                                Text(topic.rawValue)
                                    .font(AlineFont.sfPro(11, weight: .semibold))
                                    .foregroundStyle(selectedTopics.contains(topic) ? .white : AlineColor.textPrimary)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(selectedTopics.contains(topic) ? AlineColor.primary : AlineColor.chipUnselected)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red).font(.footnote)
                    }
                }
            }
            .navigationTitle("New Discussion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        post()
                    } label: {
                        if isPosting { ProgressView() } else { Text("Post").fontWeight(.semibold) }
                    }
                    .disabled(!canPost || isPosting)
                }
            }
            .tint(AlineColor.primary)
        }
    }

    private func post() {
        isPosting = true
        errorMessage = nil
        Task {
            do {
                try await viewModel.createDiscussion(
                    category: category,
                    company: company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : company,
                    title: title, body: postBody, topics: selectedTopics.map(\.rawValue)
                )
                dismiss()
            } catch {
                errorMessage = "Couldn't post — check the backend is running and try again."
            }
            isPosting = false
        }
    }
}
