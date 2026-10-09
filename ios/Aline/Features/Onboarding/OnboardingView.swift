import SwiftUI
import UniformTypeIdentifiers

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @State private var isPickingFile = false
    let onComplete: (CareerProfile, UserPreferences) -> Void

    var body: some View {
        ZStack {
            AlineColor.warmCanvas.ignoresSafeArea()
            VStack(spacing: 24) {
                switch viewModel.step {
                case .uploadResume:
                    uploadStep
                case .parsing:
                    parsingStep
                case .confirmRoles:
                    confirmRolesStep
                case .location:
                    locationStep
                case .workMode:
                    workModeStep
                }
            }
            .padding(24)
        }
        .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                if let text = PDFTextExtractor.extractText(from: url), !text.isEmpty {
                    viewModel.resumeText = text
                    viewModel.startParsing()
                } else {
                    viewModel.errorMessage = "Couldn't read text from that PDF. Try pasting it instead."
                }
            case .failure:
                viewModel.errorMessage = "Couldn't open that file."
            }
        }
    }

    private var uploadStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Don't miss")
                .font(AlineFont.display(40))
                .foregroundStyle(AlineColor.inkNavy)
            Text("the right one.")
                .font(AlineFont.displayItalic(40))
                .foregroundStyle(AlineColor.electricCobalt)
            Text("Upload your resume — we'll do the rest.")
                .font(AlineFont.body(16))
                .foregroundStyle(AlineColor.graphite)
            Spacer()

            Button("Upload Resume (PDF)") { isPickingFile = true }
                .buttonStyle(AlinePrimaryButtonStyle())

            TextEditorFallback(text: $viewModel.resumeText) {
                if !viewModel.resumeText.isEmpty {
                    viewModel.startParsing()
                }
            }

            if let error = viewModel.errorMessage {
                Text(error).font(AlineFont.body(13)).foregroundStyle(.red)
            }
        }
    }

    private var parsingStep: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .tint(AlineColor.electricCobalt)
            Text("Reading your resume…")
                .font(AlineFont.body(16))
                .foregroundStyle(AlineColor.graphite)
            Spacer()
        }
    }

    private var confirmRolesStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Based on your profile, these opportunities may fit you:")
                .font(AlineFont.display(22))
                .foregroundStyle(AlineColor.inkNavy)

            ForEach(roleOptions, id: \.self) { role in
                Button {
                    if viewModel.confirmedRoles.contains(role) {
                        viewModel.confirmedRoles.remove(role)
                    } else {
                        viewModel.confirmedRoles.insert(role)
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.confirmedRoles.contains(role) ? "checkmark.square.fill" : "square")
                            .foregroundStyle(AlineColor.electricCobalt)
                        Text(role).font(AlineFont.body(16)).foregroundStyle(AlineColor.charcoal)
                    }
                }
            }

            Spacer()
            Button("Continue") { viewModel.step = .location }
                .buttonStyle(AlinePrimaryButtonStyle())
                .frame(maxWidth: .infinity)
        }
    }

    private var roleOptions: [String] {
        let base = ["Software Engineer", "Backend Engineer", "AI Engineer", "ML Engineer", "Data Engineer", "Frontend Engineer"]
        let fromProfile = viewModel.parsedProfile.inferredRoles
        return Array(Set(base + fromProfile)).sorted()
    }

    private var locationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location").font(AlineFont.display(24)).foregroundStyle(AlineColor.inkNavy)
            ForEach(viewModel.locationOptions, id: \.self) { option in
                Button {
                    viewModel.preferredLocation = option
                } label: {
                    HStack {
                        Image(systemName: viewModel.preferredLocation == option ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(AlineColor.electricCobalt)
                        Text(option).font(AlineFont.body(16)).foregroundStyle(AlineColor.charcoal)
                    }
                }
            }
            Spacer()
            Button("Continue") { viewModel.step = .workMode }
                .buttonStyle(AlinePrimaryButtonStyle())
                .frame(maxWidth: .infinity)
        }
    }

    private var workModeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Work mode").font(AlineFont.display(24)).foregroundStyle(AlineColor.inkNavy)
            ForEach(viewModel.workModeOptions, id: \.self) { option in
                Button {
                    if viewModel.workModes.contains(option) {
                        viewModel.workModes.remove(option)
                    } else {
                        viewModel.workModes.insert(option)
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.workModes.contains(option) ? "checkmark.square.fill" : "square")
                            .foregroundStyle(AlineColor.electricCobalt)
                        Text(option).font(AlineFont.body(16)).foregroundStyle(AlineColor.charcoal)
                    }
                }
            }
            Spacer()
            Button("Done") { onComplete(viewModel.finalProfile(), viewModel.finalPreferences()) }
                .buttonStyle(AlinePrimaryButtonStyle())
                .frame(maxWidth: .infinity)
        }
    }
}

/// Paste-in fallback for the resume text, so onboarding doesn't hard-depend on PDFKit
/// extraction behaving perfectly during the demo.
private struct TextEditorFallback: View {
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("or paste your resume text").font(AlineFont.body(13)).foregroundStyle(AlineColor.stone)
            TextEditor(text: $text)
                .frame(height: 120)
                .padding(8)
                .background(AlineColor.paperWhite)
                .clipShape(RoundedRectangle(cornerRadius: AlineRadius.card))
                .overlay(RoundedRectangle(cornerRadius: AlineRadius.card).stroke(AlineColor.creamBorder))
            if !text.isEmpty {
                Button("Use this text", action: onSubmit)
                    .font(AlineFont.body(14, weight: .medium))
                    .foregroundStyle(AlineColor.electricCobalt)
            }
        }
    }
}
