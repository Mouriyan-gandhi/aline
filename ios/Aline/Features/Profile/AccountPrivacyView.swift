import SwiftUI
import SwiftData

/// Matches the Figma "Account & privacy" + "Delete account confirmation" screens. The delete
/// flow is real, not a stub: it calls DELETE /profile (full cascade on the backend — see
/// community_db.py's delete_account), then clears everything local too (resumes, liked/applied
/// jobs, onboarding state) so "delete my account" actually means what it says rather than
/// leaving local SwiftData orphaned.
struct AccountPrivacyView: View {
    let viewModel: ProfileViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var resumeDocuments: [ResumeDocument]
    @Query private var savedJobs: [SavedJob]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("careerProfileData") private var careerProfileData: Data = Data()
    @AppStorage("userPreferencesData") private var userPreferencesData: Data = Data()

    @State private var isShowingDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your identity").font(AlineFont.sfPro(16, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
                    Text("Community username").font(AlineFont.sfPro(12)).foregroundStyle(AlineColor.textSecondary)
                    Text(viewModel.profile.username.isEmpty ? "Not created yet" : viewModel.profile.username)
                        .font(AlineFont.sfPro(14, weight: .semibold))
                        .foregroundStyle(AlineColor.textPrimary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AlineColor.paperWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))

                Text("There's no account system with sign-up/sign-in yet (see onboarding's sign-in buttons, which are intentionally stubbed) — your identity here is scoped to this device. \"Delete account\" below removes your profile and everything you've posted in Community from the backend, and clears your local data on this device.")
                    .font(AlineFont.sfPro(12))
                    .foregroundStyle(AlineColor.textSecondary)

                if let errorMessage {
                    Text(errorMessage).font(AlineFont.sfPro(13)).foregroundStyle(.red)
                }

                Button {
                    isShowingDeleteConfirm = true
                } label: {
                    if isDeleting {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Delete Account").frame(maxWidth: .infinity)
                    }
                }
                .font(AlineFont.sfPro(15, weight: .semibold))
                .foregroundStyle(.red)
                .padding(.vertical, 12)
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.red, lineWidth: 1))
                .disabled(isDeleting)
            }
            .padding(20)
        }
        .background(AlineColor.canvas)
        .navigationTitle("Account & Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete your account?", isPresented: $isShowingDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your profile, resumes stored on this device, and every discussion/comment you've posted in Community. This can't be undone.")
        }
    }

    private func deleteAccount() {
        isDeleting = true
        errorMessage = nil
        Task {
            do {
                try await ProfileAPI.deleteAccount()
                for doc in resumeDocuments { modelContext.delete(doc) }
                for job in savedJobs { modelContext.delete(job) }
                careerProfileData = Data()
                userPreferencesData = Data()
                hasCompletedOnboarding = false
                // hasCompletedOnboarding flipping to false sends the person back to the
                // welcome screen on its own (AlineApp's own if/else), so no explicit
                // navigation is needed from here.
            } catch {
                errorMessage = "Couldn't delete your account — check the backend is running and try again."
                isDeleting = false
            }
        }
    }
}
