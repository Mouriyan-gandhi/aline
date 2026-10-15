import SwiftUI

/// Matches the Figma "Feedback and problem form" screen. Submits to POST /feedback — real
/// durable storage (see backend/app/feedback.py), not a form that silently discards input.
/// There's no triage/notification pipeline on top of it yet (no email, no Slack) — that's an
/// honest, stated limitation, not hidden behind a success message that implies more than it
/// delivers.
struct HelpFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var category = "Bug report"
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var didSubmit = false

    private let categories = ["Bug report", "Feature request", "Something else"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if didSubmit {
                    confirmationCard
                } else {
                    Text("What's this about?").font(AlineFont.sfPro(13, weight: .semibold)).foregroundStyle(AlineColor.textPrimary)
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { option in
                            Button { category = option } label: {
                                Text(option)
                                    .font(AlineFont.sfPro(12, weight: .semibold))
                                    .foregroundStyle(category == option ? .white : AlineColor.textPrimary)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(category == option ? AlineColor.primary : AlineColor.chipUnselected)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Tell us more").font(AlineFont.sfPro(13, weight: .semibold)).foregroundStyle(AlineColor.textPrimary)
                    TextEditor(text: $message)
                        .frame(minHeight: 160)
                        .padding(8)
                        .background(AlineColor.paperWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AlineColor.inputBorder, lineWidth: 1))

                    if let errorMessage {
                        Text(errorMessage).font(AlineFont.sfPro(13)).foregroundStyle(.red)
                    }

                    Button {
                        submit()
                    } label: {
                        if isSubmitting { ProgressView().tint(.white) } else { Text("Submit") }
                    }
                    .buttonStyle(AlinePrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(isSubmitting || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(20)
        }
        .background(AlineColor.canvas)
        .navigationTitle("Help & Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var confirmationCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 36)).foregroundStyle(AlineColor.primary)
            Text("Thanks — we've got it.").font(AlineFont.sfPro(16, weight: .semibold)).foregroundStyle(AlineColor.textPrimary)
            Text("There's no automatic reply yet, but this was saved and attributed to your account.")
                .font(AlineFont.sfPro(13)).foregroundStyle(AlineColor.textSecondary)
                .multilineTextAlignment(.center)
            Button("Done") { dismiss() }
                .buttonStyle(AlinePrimaryButtonStyle())
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func submit() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                try await CommunityAPI.submitFeedback(category: category, message: message)
                didSubmit = true
            } catch {
                errorMessage = "Couldn't submit — check the backend is running and try again."
            }
            isSubmitting = false
        }
    }
}
