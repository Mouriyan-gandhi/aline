import SwiftUI
import UniformTypeIdentifiers

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @State private var isPickingFile = false
    let onComplete: (CareerProfile, UserPreferences) -> Void

    var body: some View {
        ZStack {
            AlineColor.canvas.ignoresSafeArea()
            switch viewModel.step {
            case .welcome: WelcomeStep(viewModel: viewModel)
            case .signIn: SignInStep(viewModel: viewModel)
            case .lookingFor: LookingForStep(viewModel: viewModel)
            case .careerStage: CareerStageStep(viewModel: viewModel)
            case .roleInterests: RoleInterestsStep(viewModel: viewModel)
            case .locations: LocationsStep(viewModel: viewModel)
            case .resumeUpload: ResumeUploadStep(viewModel: viewModel, isPickingFile: $isPickingFile)
            case .parsing: ParsingStep()
            case .success: SuccessStep(viewModel: viewModel, onComplete: onComplete)
            }
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
}

// MARK: - Shared decorative background + scaffold

/// The soft teal/lime corner washes behind Welcome/Sign-in — recreated as simple blurred
/// circles rather than downloading the Figma file's decorative wash SVGs, which aren't
/// load-bearing content.
private struct DecorativeWash: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(AlineColor.primary.opacity(0.12))
                    .frame(width: 260, height: 260)
                    .offset(x: geo.size.width - 100, y: -140)
                Circle().fill(AlineColor.badgeHighlight)
                    .frame(width: 180, height: 180)
                    .offset(x: geo.size.width - 60, y: -100)
                Circle().fill(AlineColor.badgeHighlightMuted)
                    .frame(width: 220, height: 220)
                    .offset(x: -80, y: geo.size.height - 180)
                Circle().fill(AlineColor.primary.opacity(0.1))
                    .frame(width: 240, height: 240)
                    .offset(x: 80, y: geo.size.height - 120)
            }
        }
        .ignoresSafeArea()
    }
}

private struct AlineLogoMark: View {
    var size: CGFloat = 120
    var body: some View {
        Image("AlineLogo")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.21, style: .continuous))
    }
}

/// Reusable per-step chrome: back + title header, "STEP X OF 5" progress bar, scrollable
/// content, fixed bottom Continue button — matches every real onboarding step screen's
/// identical structure (confirmed across Looking-for/Career-stage/Role-interests/Locations).
private struct OnboardingStepScaffold<Content: View>: View {
    let title: String
    let stepNumber: Int
    let totalSteps: Int = 5
    var onBack: (() -> Void)?
    var continueTitle: String = "Continue"
    var continueEnabled: Bool = true
    var onContinue: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let onBack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                            Text("Back").font(AlineFont.inter(13, weight: .semibold))
                        }
                        .foregroundStyle(AlineColor.primary)
                    }
                } else {
                    Color.clear.frame(width: 60)
                }
                Spacer()
                Text(title).font(AlineFont.inter(15, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
                Spacer()
                Color.clear.frame(width: 60)
            }
            .padding(.horizontal, 20)
            .frame(height: 54)

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("STEP \(stepNumber) OF \(totalSteps)").font(AlineFont.inter(11, weight: .bold))
                    Spacer()
                    Text("About 2 min").font(AlineFont.inter(11, weight: .medium))
                }
                .foregroundStyle(AlineColor.textPrimary)
                HStack(spacing: 5) {
                    ForEach(1...totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i <= stepNumber ? AlineColor.primary : AlineColor.primary.opacity(0.1))
                            .frame(height: 4)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScrollView {
                content
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }

            VStack(spacing: 10) {
                Button(action: onContinue) {
                    Text(continueTitle).frame(maxWidth: .infinity)
                }
                .buttonStyle(AlinePrimaryButtonStyle())
                .disabled(!continueEnabled)
                .opacity(continueEnabled ? 1 : 0.5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(AlineColor.canvas)
            .overlay(alignment: .top) { Rectangle().fill(AlineColor.cardBorder).frame(height: 1) }
        }
    }
}

private struct SelectableCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? AlineColor.primary : AlineColor.cardBorder, lineWidth: isSelected ? 1.5 : 2)
                        .background(Circle().fill(isSelected ? AlineColor.primary : .clear))
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AlineFont.inter(14, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
                    Text(subtitle).font(AlineFont.inter(12, weight: .medium)).foregroundStyle(AlineColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(isSelected ? AlineColor.primary.opacity(0.1) : AlineColor.paperWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? AlineColor.primary : AlineColor.cardBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Welcome

private struct WelcomeStep: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            DecorativeWash()
            VStack(spacing: 18) {
                Spacer()
                AlineLogoMark(size: 120)
                Text("Welcome to\nAline")
                    .multilineTextAlignment(.center)
                    .font(AlineFont.inter(36, weight: .bold))
                    .foregroundStyle(Color(hex: 0x06394A))
                Text("Your career. Our opportunities.\nLet's build what's next.")
                    .multilineTextAlignment(.center)
                    .font(AlineFont.inter(16))
                    .foregroundStyle(Color(hex: 0x548BA0))
                Spacer()
                Button("Get Started") { viewModel.step = .signIn }
                    .buttonStyle(AlinePrimaryButtonStyle())
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Sign in

private struct SignInStep: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            DecorativeWash()
            VStack(spacing: 14) {
                Spacer().frame(height: 60)
                AlineLogoMark(size: 100)
                Text("Welcome to Aline")
                    .font(AlineFont.inter(28, weight: .bold))
                    .foregroundStyle(Color(hex: 0x06394A))
                Text("Log in to explore opportunities, build your profile\nand take the next step in your career.")
                    .multilineTextAlignment(.center)
                    .font(AlineFont.inter(15))
                    .foregroundStyle(Color(hex: 0x548BA0))
                    .padding(.top, 4)

                VStack(spacing: 12) {
                    // Sign in with Apple/Google need real OAuth + a backend account system,
                    // neither of which exists yet — rather than build a fake flow that looks
                    // done but isn't, every option here advances onboarding directly (same as
                    // the real flow structurally, auth just isn't wired to anything real yet).
                    authButton("Continue with Google", systemImage: "g.circle.fill", filled: false)
                    authButton("Continue with Apple", systemImage: "apple.logo", filled: true)

                    HStack {
                        Rectangle().fill(Color(hex: 0xD3E2E6)).frame(height: 1)
                        Text("OR").font(AlineFont.inter(12, weight: .bold)).foregroundStyle(Color(hex: 0x548BA0))
                        Rectangle().fill(Color(hex: 0xD3E2E6)).frame(height: 1)
                    }
                    .padding(.vertical, 6)

                    authButton("Continue with Email", systemImage: "envelope.fill", filled: false)
                }
                .padding(.top, 10)

                Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                    .font(AlineFont.inter(11.5))
                    .foregroundStyle(Color(hex: 0x548BA0))
                    .multilineTextAlignment(.center)
                    .padding(.top, 14)
                Spacer()
            }
            .padding(.horizontal, 30)
        }
    }

    private func authButton(_ title: String, systemImage: String, filled: Bool) -> some View {
        Button {
            viewModel.step = .lookingFor
        } label: {
            HStack {
                Image(systemName: systemImage)
                Spacer()
                Text(title).font(AlineFont.inter(14, weight: .bold))
                Spacer()
                Image(systemName: "arrow.right")
            }
            .foregroundStyle(filled ? .white : Color(hex: 0x07536A))
            .padding(.horizontal, 19)
            .frame(height: 60)
            .background(filled ? Color(hex: 0x10141D) : AlineColor.paperWhite)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(filled ? Color.clear : Color(hex: 0xDFE8EB), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 1: Looking for

private struct LookingForStep: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepScaffold(
            title: "Looking for", stepNumber: 1,
            onBack: { viewModel.step = .signIn },
            onContinue: { viewModel.step = .careerStage }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What are you looking for?").font(AlineFont.inter(22, weight: .heavy))
                    Text("Choose one option to personalize your experience")
                        .font(AlineFont.inter(14, weight: .medium)).foregroundStyle(AlineColor.textSecondary)
                }
                .foregroundStyle(AlineColor.textPrimary)

                VStack(spacing: 10) {
                    ForEach(LookingFor.allCases, id: \.self) { option in
                        SelectableCard(
                            title: option.rawValue, subtitle: option.subtitle,
                            isSelected: viewModel.lookingFor == option
                        ) { viewModel.lookingFor = option }
                    }
                }
            }
        }
    }
}

// MARK: - Step 2: Career stage

private struct CareerStageStep: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepScaffold(
            title: "Career stage", stepNumber: 2,
            onBack: { viewModel.step = .lookingFor },
            continueEnabled: viewModel.careerStage != nil,
            onContinue: { viewModel.step = .roleInterests }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How would you describe your current stage?").font(AlineFont.inter(24, weight: .heavy))
                    Text("Choose the option that best describes you.")
                        .font(AlineFont.inter(13)).foregroundStyle(AlineColor.textSecondary)
                }
                .foregroundStyle(AlineColor.textPrimary)

                VStack(spacing: 10) {
                    ForEach(CareerStage.allCases, id: \.self) { option in
                        SelectableCard(
                            title: option.rawValue, subtitle: option.subtitle,
                            isSelected: viewModel.careerStage == option
                        ) { viewModel.careerStage = option }
                    }
                }
            }
        }
    }
}

// MARK: - Step 3: Role interests

private struct RoleInterestsStep: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepScaffold(
            title: "What roles interest you?", stepNumber: 3,
            onBack: { viewModel.step = .careerStage },
            continueEnabled: !viewModel.selectedRoleInterests.isEmpty,
            onContinue: { viewModel.step = .locations }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What roles interest you?").font(AlineFont.inter(24, weight: .heavy))
                    Text("Pick up to three roles. We'll use them to explain why each opportunity could be a strong fit.")
                        .font(AlineFont.inter(13)).foregroundStyle(AlineColor.textSecondary)
                }
                .foregroundStyle(AlineColor.textPrimary)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(AlineColor.textSecondary)
                    TextField("Search roles", text: Binding(
                        get: { viewModel.roleSearchText },
                        set: { viewModel.roleSearchText = $0 }
                    ))
                    .font(AlineFont.inter(13, weight: .medium))
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(AlineColor.paperWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))

                HStack(spacing: 8) {
                    Text("\(viewModel.selectedRoleInterests.count) selected")
                        .font(AlineFont.inter(11, weight: .bold))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(AlineColor.primary.opacity(0.1))
                        .overlay(Capsule().stroke(AlineColor.primary, lineWidth: 1))
                        .clipShape(Capsule())
                    Text("Maximum 3 roles").font(AlineFont.inter(11, weight: .medium)).foregroundStyle(AlineColor.textSecondary)
                    Spacer()
                }
                .foregroundStyle(AlineColor.textPrimary)

                VStack(spacing: 4) {
                    ForEach(viewModel.roleInterestChoices) { interest in
                        let isSelected = viewModel.selectedRoleInterests.contains(interest.label)
                        Button { viewModel.toggleRoleInterest(interest.label) } label: {
                            HStack {
                                Text(interest.label)
                                    .font(AlineFont.inter(13, weight: isSelected ? .bold : .semibold))
                                    .foregroundStyle(AlineColor.textPrimary)
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? AlineColor.primary : AlineColor.paperWhite)
                                        .overlay(Circle().stroke(isSelected ? AlineColor.primary : Color(hex: 0xDCE5F0), lineWidth: 1.5))
                                    if isSelected {
                                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                                    }
                                }
                                .frame(width: 22, height: 22)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 11)
                            .background(isSelected ? AlineColor.primary.opacity(0.1) : AlineColor.paperWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(isSelected ? AlineColor.primary : AlineColor.cardBorder, lineWidth: isSelected ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Step 4: Preferred locations

private struct LocationsStep: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepScaffold(
            title: "Preferred locations", stepNumber: 4,
            onBack: { viewModel.step = .roleInterests },
            continueEnabled: !viewModel.selectedLocations.isEmpty || viewModel.openToAnyLocation,
            onContinue: { viewModel.step = .resumeUpload }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Where are you open to working?").font(AlineFont.inter(24, weight: .heavy))
                    Text("We'll prioritize these preferences and surface exceptional nearby opportunities.")
                        .font(AlineFont.inter(11)).foregroundStyle(AlineColor.textSecondary)
                }
                .foregroundStyle(AlineColor.textPrimary)

                VStack(alignment: .leading, spacing: 16) {
                    Text("SELECT LOCATIONS").font(AlineFont.inter(10, weight: .bold)).foregroundStyle(AlineColor.textPrimary)

                    FlowLayout(spacing: 10) {
                        ForEach(OnboardingRoleInterest.preferredLocationChoices, id: \.self) { location in
                            let isSelected = viewModel.selectedLocations.contains(location)
                            Button { viewModel.toggleLocation(location) } label: {
                                Text(location)
                                    .font(AlineFont.inter(11, weight: .bold))
                                    .foregroundStyle(isSelected ? .white : AlineColor.textPrimary)
                                    .padding(.horizontal, 14)
                                    .frame(height: 34)
                                    .background(isSelected ? AlineColor.primary : AlineColor.paperWhite)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(isSelected ? AlineColor.primary : Color(hex: 0xDCE5F0), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        viewModel.selectOpenToAnyLocation()
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.openToAnyLocation ? AlineColor.primary : AlineColor.paperWhite)
                                    .overlay(Circle().stroke(viewModel.openToAnyLocation ? AlineColor.primary : Color(hex: 0xDCE5F0), lineWidth: 1.5))
                                if viewModel.openToAnyLocation {
                                    Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                                }
                            }
                            .frame(width: 20, height: 20)
                            Text("Open to any location")
                                .font(AlineFont.inter(13, weight: .bold))
                                .foregroundStyle(AlineColor.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(AlineColor.paperWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Step 5: Resume (optional)

private struct ResumeUploadStep: View {
    let viewModel: OnboardingViewModel
    @Binding var isPickingFile: Bool

    var body: some View {
        OnboardingStepScaffold(
            title: "Add your resume", stepNumber: 5,
            onBack: { viewModel.step = .locations },
            continueTitle: viewModel.resumeText.isEmpty ? "Skip for now" : "Continue",
            onContinue: {
                if viewModel.resumeText.isEmpty {
                    viewModel.skipResume()
                } else {
                    viewModel.startParsing()
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add your resume").font(AlineFont.inter(24, weight: .heavy))
                    Text("Optional — we'll extract your skills and experience automatically. You can always add this later.")
                        .font(AlineFont.inter(13)).foregroundStyle(AlineColor.textSecondary)
                }
                .foregroundStyle(AlineColor.textPrimary)

                Button { isPickingFile = true } label: {
                    Text("Upload Resume (PDF)").frame(maxWidth: .infinity)
                }
                .buttonStyle(AlinePrimaryButtonStyle())

                VStack(alignment: .leading, spacing: 8) {
                    Text("or paste your resume text").font(AlineFont.inter(13)).foregroundStyle(AlineColor.textSecondary)
                    TextEditor(text: Binding(get: { viewModel.resumeText }, set: { viewModel.resumeText = $0 }))
                        .frame(height: 140)
                        .padding(8)
                        .background(AlineColor.paperWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AlineColor.cardBorder, lineWidth: 1))
                }

                if let error = viewModel.errorMessage {
                    Text(error).font(AlineFont.inter(13)).foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - Parsing

private struct ParsingStep: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView().tint(AlineColor.primary)
            Text("Reading your resume…").font(AlineFont.inter(16)).foregroundStyle(AlineColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Success

private struct SuccessStep: View {
    let viewModel: OnboardingViewModel
    let onComplete: (CareerProfile, UserPreferences) -> Void

    var body: some View {
        ZStack {
            DecorativeWash()
            VStack(spacing: 18) {
                Spacer()
                ZStack {
                    Circle().fill(AlineColor.badgeHighlight).frame(width: 96, height: 96)
                    Image(systemName: "checkmark").font(.system(size: 36, weight: .bold)).foregroundStyle(AlineColor.primary)
                }
                Text("You're all set!")
                    .font(AlineFont.inter(28, weight: .bold))
                    .foregroundStyle(Color(hex: 0x06394A))
                Text("We've tailored your feed based on what you told us.\nLet's find your next opportunity.")
                    .multilineTextAlignment(.center)
                    .font(AlineFont.inter(15))
                    .foregroundStyle(Color(hex: 0x548BA0))
                Spacer()
                Button("Start Exploring") {
                    onComplete(viewModel.finalProfile(), viewModel.finalPreferences())
                }
                .buttonStyle(AlinePrimaryButtonStyle())
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 30)
        }
    }
}
