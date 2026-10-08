import SwiftUI
import UniformTypeIdentifiers

/// Covers both paths the product direction calls for: "if he is already having his resume,
/// he can just click on that" (use the resume already parsed at onboarding, or upload/paste
/// a new one) vs. "if he is not having his resume, he has to fill out the profile section by
/// himself" (start from scratch → ManualProfileEditorView). Either path ends the same way:
/// a structured ResumeProfile handed to ChooseTemplateView.
struct AddResumeView: View {
    let careerProfile: CareerProfile
    @Binding var path: NavigationPath

    @State private var isPickingFile = false
    @State private var pastedText = ""
    @State private var isStructuring = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Add Resume").font(AlineFont.display(24)).foregroundStyle(AlineColor.inkNavy)
                Text("Upload a resume to start tailoring it with AI.")
                    .font(AlineFont.body(14)).foregroundStyle(AlineColor.graphite)

                if isStructuring {
                    HStack(spacing: 10) {
                        ProgressView().tint(AlineColor.electricCobalt)
                        Text("Reading your resume…").font(AlineFont.body(14)).foregroundStyle(AlineColor.stone)
                    }
                    .padding(.top, 20)
                } else {
                    if !careerProfile.rawResumeText.isEmpty {
                        Button {
                            structure(text: careerProfile.rawResumeText)
                        } label: {
                            Label("Use the resume you uploaded earlier", systemImage: "doc.text")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AlinePrimaryButtonStyle())
                    }

                    Button {
                        isPickingFile = true
                    } label: {
                        Label("Upload a different resume (PDF)", systemImage: "arrow.up.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .font(AlineFont.body(15, weight: .medium))
                    .foregroundStyle(AlineColor.inkNavy)
                    .padding(.vertical, 12)
                    .overlay(RoundedRectangle(cornerRadius: AlineRadius.card).stroke(AlineColor.creamBorder))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("or paste your resume text").font(AlineFont.body(13)).foregroundStyle(AlineColor.stone)
                        TextEditor(text: $pastedText)
                            .frame(height: 140)
                            .padding(8)
                            .background(AlineColor.paperWhite)
                            .clipShape(RoundedRectangle(cornerRadius: AlineRadius.card))
                            .overlay(RoundedRectangle(cornerRadius: AlineRadius.card).stroke(AlineColor.creamBorder))
                        if !pastedText.isEmpty {
                            Button("Use this text") { structure(text: pastedText) }
                                .font(AlineFont.body(14, weight: .medium))
                                .foregroundStyle(AlineColor.electricCobalt)
                        }
                    }

                    Divider().padding(.vertical, 4)

                    Button {
                        path.append(ResumeRoute.manualEntry)
                    } label: {
                        Text("Don't have a resume yet? Build one from scratch")
                            .font(AlineFont.body(14, weight: .medium))
                            .foregroundStyle(AlineColor.electricCobalt)
                    }

                    if let errorMessage {
                        Text(errorMessage).font(AlineFont.body(13)).foregroundStyle(.red)
                    }
                }
            }
            .padding(16)
        }
        .background(AlineColor.warmCanvas)
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                if let text = PDFTextExtractor.extractText(from: url), !text.isEmpty {
                    structure(text: text)
                } else {
                    errorMessage = "Couldn't read text from that PDF. Try pasting it instead."
                }
            case .failure:
                errorMessage = "Couldn't open that file."
            }
        }
    }

    private func structure(text: String) {
        errorMessage = nil
        isStructuring = true
        Task {
            let profile = await ResumeStructurer.structure(resumeText: text)
            await MainActor.run {
                isStructuring = false
                if profile == .empty {
                    errorMessage = "Couldn't extract your resume automatically — try building from scratch instead."
                    return
                }
                let id = PendingProfileStore.shared.store(profile)
                path.append(ResumeRoute.chooseTemplate(id))
            }
        }
    }
}
