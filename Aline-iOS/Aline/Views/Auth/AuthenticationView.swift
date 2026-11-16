import SwiftUI
import SafariServices

// MARK: - Authentication View
/// Handles Sign In, Create Account with Email OTP Verification, and Direct Apple & Google Sign-In.
/// Matches Aline's native iOS light design system with frosted cards and pastel gradients.
public struct AuthenticationView: View {
    @ObservedObject public var navViewModel: AppNavigationViewModel
    public var onAuthSuccess: ((_ isNewUser: Bool) -> Void)? = nil
    /// Returns to the welcome screen
    public var onBack: (() -> Void)? = nil

    public enum AuthMode: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Create Account"
    }

    @State private var authMode: AuthMode = .signUp

    // Sign Up Fields
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var agreedToTerms: Bool = false
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    // Email OTP Verification Flow
    @State private var isVerifyingOTP: Bool = false
    @State private var otpCode: String = ""
    @State private var expectedOTP: String = "482910"
    @State private var pendingFullName: String = ""
    @State private var pendingEmail: String = ""
    @State private var pendingPhone: String = ""
    @State private var showMailNotificationBanner: Bool = false
    @State private var resendCountdown: Int = 30
    @State private var resendTimerActive: Bool = false
    @FocusState private var isOtpFieldFocused: Bool

    // Google Sign-In Sheet
    @State private var showGoogleAccountSheet: Bool = false

    // Validation & Error
    @State private var errorMessage: String? = nil
    @State private var otpErrorMessage: String? = nil
    @State private var isLoading: Bool = false

    public init(
        navViewModel: AppNavigationViewModel,
        initialMode: AuthMode = .signUp,
        onBack: (() -> Void)? = nil,
        onAuthSuccess: ((_ isNewUser: Bool) -> Void)? = nil
    ) {
        self.navViewModel = navViewModel
        self._authMode = State(initialValue: initialMode)
        self.onBack = onBack
        self.onAuthSuccess = onAuthSuccess
    }

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            if isVerifyingOTP {
                otpVerificationView
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else {
                mainAuthScrollView
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            }

            // Top Simulated Mail Notification Banner
            if showMailNotificationBanner {
                VStack {
                    mailNotificationBannerView
                        .padding(.top, 10)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isVerifyingOTP)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showMailNotificationBanner)
        .sheet(isPresented: $showGoogleAccountSheet, onDismiss: {
            // When user finishes or closes the authentic Google login page, complete login and proceed to onboarding
            let googleName = fullName.isEmpty ? (UserDefaults.standard.string(forKey: "userFullName") ?? "Google User") : fullName
            let googleEmail = email.isEmpty ? (UserDefaults.standard.string(forKey: "userEmail") ?? "user@gmail.com") : email
            // Returning users (signed out, account not deleted) go straight to Discover
            let isNew = !navViewModel.hasExistingAccount
            navViewModel.login(
                fullName: googleName,
                email: googleEmail,
                phone: "+91 99520 86492",
                isNewUser: isNew
            )
            onAuthSuccess?(isNew)
        }) {
            GoogleSafariSignInView()
                .ignoresSafeArea()
        }
    }

    // MARK: - Main Auth Scroll View
    private var mainAuthScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                if let onBack {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .frame(width: 40, height: 40)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .alineGlassCircleButton()
                        .accessibilityLabel("Back")
                        Spacer()
                    }
                    .padding(.horizontal, AlineSpacing.screenInset)
                    .padding(.top, 8)
                }

                // Top App Branding
                headerBrandingView
                    .padding(.top, onBack == nil ? 24 : 0)

                // Main Auth Card
                VStack(alignment: .leading, spacing: 20) {
                    if authMode == .signUp {
                        signUpFormView
                    } else {
                        signInFormView
                    }
                }
                .padding(24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                .padding(.horizontal, AlineSpacing.screenInset)

                // Social Sign In Options
                socialLoginSection
                    .padding(.horizontal, AlineSpacing.screenInset)

                // Switch Mode Prompt
                bottomModeSwitchButton
                    .padding(.bottom, 32)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Header Branding
    private var headerBrandingView: some View {
        VStack(spacing: 8) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

            Text("Aline")
                .font(.system(size: 26, weight: .heavy, design: .default))
                .foregroundColor(AlineTheme.inkPrimary)

            Text("REACH WHAT'S NEXT")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.5)
                .foregroundColor(AlineTheme.inkSecondary)
        }
    }

    // MARK: - Sign Up Form
    private var signUpFormView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create your account")
                    .font(.system(size: 22, weight: .heavy, design: .default))
                    .foregroundColor(AlineTheme.inkPrimary)

                Text("Let's get a few basic details to set up your Aline account.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineSpacing(2)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AlineTheme.accentHeart)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AlineTheme.accentHeart.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Full Name *
            VStack(alignment: .leading, spacing: 6) {
                Text("Full Name *")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AlineTheme.inkPrimary)

                HStack(spacing: 10) {
                    Image(systemName: "person")
                        .foregroundColor(AlineTheme.inkSecondary)
                        .font(.system(size: 14))

                    TextField("Enter your full name", text: $fullName)
                        .font(.system(size: 15))
                        .alineKeyboardDismissal(.next)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.black.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
            }

            // Email Address *
            VStack(alignment: .leading, spacing: 6) {
                Text("Email Address *")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AlineTheme.inkPrimary)

                HStack(spacing: 10) {
                    Image(systemName: "envelope")
                        .foregroundColor(AlineTheme.inkSecondary)
                        .font(.system(size: 14))

                    TextField("Enter your email address", text: $email)
                        .font(.system(size: 15))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .alineKeyboardDismissal(.next)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.black.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
            }

            // Password *
            VStack(alignment: .leading, spacing: 6) {
                Text("Password *")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AlineTheme.inkPrimary)

                HStack(spacing: 10) {
                    Image(systemName: "lock")
                        .foregroundColor(AlineTheme.inkSecondary)
                        .font(.system(size: 14))

                    SecureField("Create a password", text: $password)
                        .font(.system(size: 15))
                        .alineKeyboardDismissal(.next)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.black.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
            }

            // Confirm Password *
            VStack(alignment: .leading, spacing: 6) {
                Text("Confirm Password *")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AlineTheme.inkPrimary)

                HStack(spacing: 10) {
                    Image(systemName: "lock.shield")
                        .foregroundColor(AlineTheme.inkSecondary)
                        .font(.system(size: 14))

                    SecureField("Re-enter your password", text: $confirmPassword)
                        .font(.system(size: 15))
                        .alineKeyboardDismissal(.done)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.black.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
            }

            // Terms agreement: a black tick, as in the rest of the app
            Button {
                withAnimation(AlineTheme.fastSpring) {
                    agreedToTerms.toggle()
                    if agreedToTerms, errorMessage?.contains("Terms") == true { errorMessage = nil }
                }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(agreedToTerms ? AlineTheme.pillDark : Color.white)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(agreedToTerms ? AlineTheme.pillDark : Color.black.opacity(0.25), lineWidth: 1.5)
                        if agreedToTerms {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: 22, height: 22)

                    Text("By creating an account, I agree to the Terms of Service and Privacy Policy.")
                        .font(.system(size: 13))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(agreedToTerms ? [.isButton, .isSelected] : .isButton)
            .padding(.top, 4)

            // Create Account Action Button (Sends OTP)
            Button {
                handleCreateAccountInitiation()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Create Account")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .alineGlassCapsule(selected: true)
            }
            .buttonStyle(.plain)
            .opacity(agreedToTerms ? 1 : 0.45)
            .padding(.top, 2)
        }
    }

    // MARK: - Sign In Form
    private var signInFormView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.system(size: 22, weight: .heavy, design: .default))
                    .foregroundColor(AlineTheme.inkPrimary)

                Text("Sign in to your Aline account to continue reaching what's next.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineSpacing(2)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AlineTheme.accentHeart)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AlineTheme.accentHeart.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Email Address
            VStack(alignment: .leading, spacing: 6) {
                Text("Email Address")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AlineTheme.inkPrimary)

                HStack(spacing: 10) {
                    Image(systemName: "envelope")
                        .foregroundColor(AlineTheme.inkSecondary)
                        .font(.system(size: 14))

                    TextField("Enter your email address", text: $email)
                        .font(.system(size: 15))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .alineKeyboardDismissal(.next)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.black.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Password")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    Spacer()

                    Button {
                        errorMessage = "Password reset link sent to \(email.isEmpty ? "your email" : email)"
                    } label: {
                        Text("Forgot?")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    Image(systemName: "lock")
                        .foregroundColor(AlineTheme.inkSecondary)
                        .font(.system(size: 14))

                    SecureField("Enter your password", text: $password)
                        .font(.system(size: 15))
                        .alineKeyboardDismissal(.done)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.black.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
            }

            // Sign In Action Button
            Button {
                handleSignIn()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Sign In")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .alineGlassCapsule(selected: true)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
    }

    // MARK: - Social Login Section
    private var socialLoginSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.black.opacity(0.10))
                    .frame(height: 1)

                Text("or continue with")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AlineTheme.inkSecondary)

                Rectangle()
                    .fill(Color.black.opacity(0.10))
                    .frame(height: 1)
            }
            .padding(.vertical, 4)

            // Continue with Apple (Directly opens onboarding)
            Button {
                handleAppleSignIn()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18))
                        .foregroundColor(.white)

                    Text("Continue with Apple")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)

            // Continue with Google (Opens Google Account Selector & Add Account)
            Button {
                handleGoogleSignIn()
            } label: {
                HStack(spacing: 12) {
                    GoogleBrandIcon()
                        .frame(width: 18, height: 18)

                    Text("Continue with Google")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Bottom Mode Switch Button
    private var bottomModeSwitchButton: some View {
        Button {
            withAnimation(AlineTheme.fastSpring) {
                authMode = (authMode == .signUp) ? .signIn : .signUp
                errorMessage = nil
            }
        } label: {
            HStack(spacing: 4) {
                Text(authMode == .signUp ? "Already have an account?" : "Don't have an account?")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)

                Text(authMode == .signUp ? "Sign In" : "Sign Up")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Email OTP Verification View
    private var otpVerificationView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Top Navigation Back
                HStack {
                    Button {
                        withAnimation(AlineTheme.fastSpring) {
                            isVerifyingOTP = false
                            otpCode = ""
                            otpErrorMessage = nil
                            showMailNotificationBanner = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Back")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(AlineTheme.inkPrimary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, AlineSpacing.screenInset)
                .padding(.top, 16)

                // OTP Main Card
                VStack(spacing: 22) {
                    // Envelope Header Icon
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.94, green: 0.96, blue: 0.72)) // Soft Aline pastel lime
                            .frame(width: 72, height: 72)

                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 32))
                            .foregroundColor(Color(red: 0.18, green: 0.40, blue: 0.22))
                    }
                    .padding(.top, 6)

                    VStack(spacing: 8) {
                        Text("Verify your email")
                            .font(.system(size: 24, weight: .heavy, design: .default))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Text("We've sent a 6-digit confirmation code to\n")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AlineTheme.inkSecondary)
                        + Text(pendingEmail)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                    }
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                    if let err = otpErrorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AlineTheme.accentHeart)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(AlineTheme.accentHeart.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    // 6 OTP Digit Boxes
                    otpBoxesView
                        .padding(.vertical, 4)

                    // Verify & Continue Action Button
                    Button {
                        handleConfirmOTP()
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Confirm & Log In")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            Capsule()
                                .fill(otpCode.count == 6 ? AlineTheme.pillDark : Color.gray.opacity(0.35))
                        )
                    }
                    .disabled(otpCode.count != 6)
                    .buttonStyle(.plain)

                    // Resend Timer & Action
                    HStack(spacing: 4) {
                        Text("Didn't receive the email?")
                            .font(.system(size: 13))
                            .foregroundColor(AlineTheme.inkSecondary)

                        if resendCountdown > 0 {
                            Text("Resend in \(resendCountdown)s")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AlineTheme.inkMuted)
                        } else {
                            Button("Resend Code") {
                                sendNewOTP()
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                .padding(.horizontal, AlineSpacing.screenInset)
            }
        }
        .onAppear {
            isOtpFieldFocused = true
            startResendTimer()
        }
    }

    // MARK: - OTP 6-Box Grid
    private var otpBoxesView: some View {
        ZStack {
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    let char = digitAt(index: index)
                    let isCurrent = otpCode.count == index

                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.025))
                            .frame(width: 44, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        isCurrent ? Color.black : (char.isEmpty ? Color.black.opacity(0.12) : Color.black.opacity(0.35)),
                                        lineWidth: isCurrent ? 2 : 1
                                    )
                            )

                        Text(char)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                    }
                }
            }

            // Hidden text field for smooth typing
            TextField("", text: $otpCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isOtpFieldFocused)
                .accentColor(.clear)
                .foregroundColor(.clear)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: otpCode) { newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > 6 {
                        otpCode = String(filtered.prefix(6))
                    } else {
                        otpCode = filtered
                    }
                    if otpCode.count == 6 {
                        otpErrorMessage = nil
                    }
                }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isOtpFieldFocused = true
        }
    }

    private func digitAt(index: Int) -> String {
        guard index < otpCode.count else { return "" }
        let idx = otpCode.index(otpCode.startIndex, offsetBy: index)
        return String(otpCode[idx])
    }

    // MARK: - Simulated Mail Notification Banner
    private var mailNotificationBannerView: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)

                Image(systemName: "envelope.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Mail")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Text("· now")
                        .font(.system(size: 11))
                        .foregroundColor(AlineTheme.inkSecondary)
                    Spacer()
                }

                Text("Aline Security: Your code is \(expectedOTP)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AlineTheme.inkPrimary)
            }

            Button("Autofill") {
                otpCode = expectedOTP
                withAnimation {
                    showMailNotificationBanner = false
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.blue))
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.14), radius: 16, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Actions
    private func handleCreateAccountInitiation() {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            errorMessage = "Please enter your full name."
            return
        }
        if trimmedEmail.isEmpty || !trimmedEmail.contains("@") {
            errorMessage = "Please enter a valid email address."
            return
        }
        if password.isEmpty || password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            return
        }
        if !agreedToTerms {
            errorMessage = "Please agree to the Terms of Service and Privacy Policy."
            return
        }

        errorMessage = nil
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isLoading = false
            // Phone isn't asked at sign-up any more
            let formattedPhone = ""

            self.pendingFullName = trimmedName
            self.pendingEmail = trimmedEmail
            self.pendingPhone = formattedPhone

            // Generate 6-digit OTP code
            sendNewOTP()

            withAnimation(AlineTheme.fastSpring) {
                self.isVerifyingOTP = true
            }
        }
    }

    private func sendNewOTP() {
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        self.expectedOTP = code
        self.otpCode = ""
        self.otpErrorMessage = nil

        // Trigger in-app simulated email banner
        withAnimation {
            self.showMailNotificationBanner = true
        }

        // Hide banner after 5.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            withAnimation {
                self.showMailNotificationBanner = false
            }
        }

        startResendTimer()
    }

    private func startResendTimer() {
        self.resendCountdown = 30
        guard !resendTimerActive else { return }
        resendTimerActive = true

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if resendCountdown > 0 {
                resendCountdown -= 1
            } else {
                resendTimerActive = false
                timer.invalidate()
            }
        }
    }

    private func handleConfirmOTP() {
        let trimmed = otpCode.trimmingCharacters(in: .whitespacesAndNewlines)
        // Allow either the exact sent code or any 6 digits for user testing convenience
        if trimmed != expectedOTP && trimmed.count != 6 {
            otpErrorMessage = "Invalid code. Please enter the 6-digit code sent to your email."
            return
        }

        otpErrorMessage = nil
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isLoading = false
            // Successfully verified! Log in as new user -> leads directly to Onboarding
            navViewModel.login(
                fullName: pendingFullName,
                email: pendingEmail,
                phone: pendingPhone,
                isNewUser: true
            )
            onAuthSuccess?(true)
        }
    }

    private func handleSignIn() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            errorMessage = "Please enter your email address."
            return
        }
        if password.isEmpty {
            errorMessage = "Please enter your password."
            return
        }

        errorMessage = nil
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isLoading = false
            let existingName = UserDefaults.standard.string(forKey: "userFullName") ?? "Aarav Sharma"
            let existingPhone = UserDefaults.standard.string(forKey: "userPhone") ?? "+91 99520 86492"
            navViewModel.login(
                fullName: existingName,
                email: trimmedEmail,
                phone: existingPhone,
                isNewUser: false
            )
            onAuthSuccess?(false)
        }
    }

    private func handleAppleSignIn() {
        // As requested: "fo now in apople i want you to direly open the onboarding screen"
        let name = fullName.isEmpty ? (UserDefaults.standard.string(forKey: "userFullName") ?? "Aarav Sharma") : fullName
        // A returning user keeps the email already on this device
        let appleEmail = email.isEmpty
            ? (UserDefaults.standard.string(forKey: "userEmail") ?? "aarav.apple@icloud.com")
            : email
        // New on this device -> onboarding; returning (signed out, not deleted) -> Discover
        let isNew = !navViewModel.hasExistingAccount
        navViewModel.login(
            fullName: name,
            email: appleEmail,
            phone: "+91 99520 86492",
            isNewUser: isNew
        )
        onAuthSuccess?(isNew)
    }

    private func handleGoogleSignIn() {
        // As requested: "directly link the google to the open google and the add account that actually happens"
        showGoogleAccountSheet = true
    }
}

// MARK: - Authentic Google Web Sign-In View via SFSafariViewController
public struct GoogleSafariSignInView: UIViewControllerRepresentable {
    public let url: URL

    public init(
        url: URL = URL(string: "https://accounts.google.com/ServiceLogin?service=accountsettings&continue=https://myaccount.google.com")!
    ) {
        self.url = url
    }

    public func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.dismissButtonStyle = .done
        return vc
    }

    public func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Google Brand Icon (Geometric 4-color G)
public struct GoogleBrandIcon: View {
    public init() {}

    /// The real multicolour Google "G" from the asset catalog
    public var body: some View {
        Image("company_google")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .scaleEffect(1.25) // the artwork has a white margin; trim it so the G fills the frame
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - Welcome Screen (after the splash, before sign-in)
/// Logo and name top-left, a carousel of what Aline does, then Google / Apple / Create account.
public struct WelcomeView: View {
    @ObservedObject public var navViewModel: AppNavigationViewModel
    public let onCreateAccount: () -> Void
    public let onSignIn: () -> Void
    public var onAuthSuccess: ((_ isNewUser: Bool) -> Void)? = nil

    @State private var page: Int = 0
    @State private var showGoogleSheet: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        navViewModel: AppNavigationViewModel,
        onCreateAccount: @escaping () -> Void,
        onSignIn: @escaping () -> Void,
        onAuthSuccess: ((_ isNewUser: Bool) -> Void)? = nil
    ) {
        self.navViewModel = navViewModel
        self.onCreateAccount = onCreateAccount
        self.onSignIn = onSignIn
        self.onAuthSuccess = onAuthSuccess
    }

    public var body: some View {
        ZStack {
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo + name, top left
                HStack(spacing: 10) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    Text("Aline")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Spacer()
                }
                .padding(.horizontal, AlineSpacing.screenInset)
                .padding(.top, 8)
                .accessibilityElement(children: .combine)

                // Feature carousel
                // The last page is a copy of the first, so the loop always moves forward
                TabView(selection: $page) {
                    ForEach(0...WelcomeFeature.all.count, id: \.self) { index in
                        let feature = WelcomeFeature.all[index % WelcomeFeature.all.count]
                        WelcomeFeatureSlide(feature: feature, isActive: page == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                .onChange(of: page) { _, newPage in
                    // Landed on the copy: once the slide finishes, swap to the real first page without animation
                    guard newPage == WelcomeFeature.all.count else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) { page = 0 }
                    }
                }

                pageDots
                    .padding(.bottom, 22)

                authButtons
                    .padding(.horizontal, AlineSpacing.screenInset)
                    .padding(.bottom, 12)
            }
        }
        .environment(\.colorScheme, .light)
        // Auto-advance; restarts whenever the page changes, so a manual swipe gets the full time too
        .task(id: page) {
            try? await Task.sleep(for: .seconds(4.5))
            guard !Task.isCancelled, !reduceMotion else { return }
            guard page < WelcomeFeature.all.count else { return }
            withAnimation(.easeInOut(duration: 0.5)) {
                page += 1
            }
        }
        .sheet(isPresented: $showGoogleSheet, onDismiss: {
            let isNew = !navViewModel.hasExistingAccount
            navViewModel.login(
                fullName: UserDefaults.standard.string(forKey: "userFullName") ?? "Google User",
                email: UserDefaults.standard.string(forKey: "userEmail") ?? "user@gmail.com",
                phone: "+91 99520 86492",
                isNewUser: isNew
            )
            onAuthSuccess?(isNew)
        }) {
            GoogleSafariSignInView()
                .ignoresSafeArea()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            let current = page % WelcomeFeature.all.count
            ForEach(WelcomeFeature.all.indices, id: \.self) { index in
                Capsule()
                    .fill(index == current ? AlineTheme.inkPrimary : AlineTheme.inkPrimary.opacity(0.18))
                    .frame(width: index == current ? 20 : 7, height: 7)
                    .animation(AlineTheme.fastSpring, value: current)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Feature \(page % WelcomeFeature.all.count + 1) of \(WelcomeFeature.all.count)")
    }

    private var authButtons: some View {
        VStack(spacing: 12) {
            Button {
                showGoogleSheet = true
            } label: {
                HStack(spacing: 12) {
                    GoogleBrandIcon()
                        .frame(width: 18, height: 18)
                    Text("Continue with Google")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().stroke(Color.black.opacity(0.12), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)

            Button {
                let isNew = !navViewModel.hasExistingAccount
                navViewModel.login(
                    fullName: UserDefaults.standard.string(forKey: "userFullName") ?? "Aarav Sharma",
                    email: UserDefaults.standard.string(forKey: "userEmail") ?? "aarav.apple@icloud.com",
                    phone: "+91 99520 86492",
                    isNewUser: isNew
                )
                onAuthSuccess?(isNew)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18))
                    Text("Continue with Apple")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(Color.black))
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Rectangle().fill(Color.black.opacity(0.10)).frame(height: 1)
                Text("or")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AlineTheme.inkSecondary)
                Rectangle().fill(Color.black.opacity(0.10)).frame(height: 1)
            }
            .padding(.vertical, 2)

            Button(action: onCreateAccount) {
                Text("Create an account")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .alineGlassCapsule()
            }
            .buttonStyle(.plain)

            Button(action: onSignIn) {
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(AlineTheme.inkSecondary)
                    Text("Sign in")
                        .fontWeight(.bold)
                        .foregroundColor(AlineTheme.inkPrimary)
                }
                .font(.system(size: 14))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Welcome carousel content
struct WelcomeFeature: Identifiable {
    enum Art { case discover, resume, interview, community, achievements }
    let id: Int
    let art: Art
    let eyebrow: String
    let title: String
    let detail: String

    static let all: [WelcomeFeature] = [
        WelcomeFeature(id: 0, art: .discover, eyebrow: "DISCOVER",
                       title: "Find roles that fit you",
                       detail: "Jobs, internships and hiring drives straight from company career pages, matched to your profile."),
        WelcomeFeature(id: 1, art: .resume, eyebrow: "RESUME",
                       title: "Tailor every resume",
                       detail: "Check your resume against a job description, spot missing skills, and build a polished one."),
        WelcomeFeature(id: 2, art: .interview, eyebrow: "INTERVIEW PREP",
                       title: "Know what they ask",
                       detail: "Browse real technical and behavioural questions candidates were asked, plus their interview experiences."),
        WelcomeFeature(id: 3, art: .community, eyebrow: "COMMUNITY",
                       title: "Learn from people who've been there",
                       detail: "Share interview stories and talk about companies and roles with fellow candidates."),
        WelcomeFeature(id: 4, art: .achievements, eyebrow: "ACHIEVEMENT GALLERY",
                       title: "Keep every win in one place",
                       detail: "Certificates, hackathon wins, awards and course completions, ready to show.")
    ]
}

struct WelcomeFeatureSlide: View {
    let feature: WelcomeFeature
    let isActive: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 8)
            WelcomeFeatureArt(art: feature.art, animate: appeared)
                .frame(height: 250)

            VStack(spacing: 8) {
                Text(feature.eyebrow)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2.5)
                    .foregroundColor(AlineTheme.inkSecondary)
                Text(feature.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(feature.detail)
                    .font(.system(size: 15))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            Spacer(minLength: 8)
        }
        .onAppear { if isActive { appeared = true } }
        .onChange(of: isActive) { _, active in
            if active {
                appeared = false
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { appeared = true }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { appeared = true }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Small illustrations built from mini versions of Aline's own cards
struct WelcomeFeatureArt: View {
    let art: WelcomeFeature.Art
    let animate: Bool

    private static let peach = Color(red: 1.0, green: 0.89, blue: 0.80)
    private static let pink = Color(red: 1.0, green: 0.86, blue: 0.93)
    private static let blue = Color(red: 0.77, green: 0.89, blue: 0.98)
    private static let mint = Color(red: 0.84, green: 0.95, blue: 0.88)

    var body: some View {
        ZStack {
            // Soft pastel halo behind every illustration
            Circle()
                .fill(LinearGradient(colors: [Self.peach, Self.pink, Self.blue], startPoint: .topTrailing, endPoint: .bottomLeading))
                .frame(width: 230, height: 230)
                .blur(radius: 30)
                .opacity(0.8)

            switch art {
            case .discover: discover
            case .resume: resume
            case .interview: interview
            case .community: community
            case .achievements: achievements
            }
        }
        .accessibilityHidden(true)
    }

    // Two job cards fanning out
    private var discover: some View {
        ZStack {
            jobCard(company: "Apple", role: "iOS Engineer Intern", match: 88, tint: Self.blue)
                .rotationEffect(.degrees(animate ? -8 : 0))
                .offset(x: animate ? -26 : 0, y: animate ? -18 : 0)
            jobCard(company: "Google", role: "Software Engineer", match: 93, tint: Self.mint)
                .rotationEffect(.degrees(animate ? 5 : 0))
                .offset(x: animate ? 22 : 0, y: animate ? 22 : 0)
        }
    }

    private func jobCard(company: String, role: String, match: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                CompanyLogoBadge(companyName: company, size: 30, isSquircle: true)
                Text(company).font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .fixedSize()
                Spacer()
                Text("\(match)% Match")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.12, green: 0.55, blue: 0.30))
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(tint))
            }
            Text(role).font(.system(size: 15, weight: .bold))
            Capsule().fill(AlineTheme.pillDark).frame(height: 28)
                .overlay(Text("View Details").font(.system(size: 11, weight: .bold)).foregroundColor(.white))
        }
        .foregroundColor(AlineTheme.inkPrimary)
        .padding(14)
        .frame(width: 210)
        .background(miniCardBackground)
    }

    // A resume with a missing-skill chip being added
    private var resume: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                Capsule().fill(AlineTheme.inkPrimary).frame(width: 90, height: 9)
                Capsule().fill(AlineTheme.inkMuted.opacity(0.5)).frame(width: 130, height: 6)
                Divider().padding(.vertical, 2)
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(i == 1 ? Self.mint : AlineTheme.inkMuted.opacity(0.28))
                        .frame(width: [150, 140, 120, 135][i], height: 7)
                }
                Divider().padding(.vertical, 2)
                ForEach(0..<2, id: \.self) { i in
                    Capsule().fill(AlineTheme.inkMuted.opacity(0.28)).frame(width: [145, 110][i], height: 7)
                }
            }
            .padding(18)
            .frame(width: 190, height: 220, alignment: .topLeading)
            .background(miniCardBackground)

            Text("+ Kubernetes")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.70, green: 0.20, blue: 0.25))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(Color(red: 0.99, green: 0.91, blue: 0.91)))
                .overlay(Capsule().stroke(Color(red: 0.93, green: 0.70, blue: 0.72), lineWidth: 1))
                .offset(x: animate ? 92 : 40, y: animate ? -62 : -40)
                .opacity(animate ? 1 : 0)

            HStack(spacing: 4) {
                Text("82%").foregroundColor(AlineTheme.inkSecondary)
                Image(systemName: "arrow.right").font(.system(size: 9, weight: .bold))
                Text("94% match").foregroundColor(AlineTheme.inkPrimary)
            }
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(Color.white))
            .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
            .offset(x: animate ? -84 : -40, y: animate ? 82 : 60)
            .opacity(animate ? 1 : 0)
        }
    }

    // A question card with topics and a solution tick
    private var interview: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    chip("Amazon", filled: false)
                    chip("System Design", filled: true)
                }
                Text("How would you design a URL shortener?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Label("Solution", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(Self.mint))
                    Spacer()
                    Text("Asked in 2026").font(.system(size: 11, weight: .semibold)).foregroundColor(AlineTheme.inkSecondary)
                }
            }
            .padding(16)
            .frame(width: 240)
            .background(miniCardBackground)

            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 22))
                .foregroundColor(Color(red: 0.95, green: 0.65, blue: 0.15))
                .padding(12)
                .background(Circle().fill(Color.white))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .offset(x: 112, y: -78)
                .scaleEffect(animate ? 1 : 0.4)
                .opacity(animate ? 1 : 0)
        }
    }

    private func chip(_ text: String, filled: Bool) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(AlineTheme.inkPrimary)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Capsule().fill(filled ? Self.blue : Color.black.opacity(0.05)))
    }

    // Two people talking about an interview
    private var community: some View {
        VStack(spacing: 12) {
            bubble(avatar: "avatar_owl", name: "algo_Owl", text: "Just cleared the Google onsite. Happy to share my prep!", leading: true)
                .offset(x: animate ? -14 : 0)
            bubble(avatar: "avatar_beaver", name: "You", text: "Yes please! How long did you practise DSA?", leading: false)
                .offset(x: animate ? 14 : 0)
            HStack(spacing: 5) {
                Image(systemName: "hand.thumbsup.fill")
                Text("128")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(AlineTheme.inkPrimary)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Color.white))
            .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
            .opacity(animate ? 1 : 0)
        }
    }

    private func bubble(avatar: String, name: String, text: String, leading: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if leading { avatarImage(avatar) }
            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(.system(size: 11, weight: .bold)).foregroundColor(AlineTheme.inkSecondary)
                Text(text).font(.system(size: 13, weight: .medium)).foregroundColor(AlineTheme.inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(width: 190, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(leading ? Color.white : Self.pink)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
            if !leading { avatarImage(avatar) }
        }
    }

    private func avatarImage(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: 34, height: 34)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    // A fan of certificate / trophy tiles
    private var achievements: some View {
        ZStack {
            achievementTile(icon: "graduationcap.fill", title: "Course", tint: Self.blue)
                .rotationEffect(.degrees(animate ? -14 : 0))
                .offset(x: animate ? -78 : 0, y: animate ? 14 : 0)
            achievementTile(icon: "rosette", title: "Certificate", tint: Self.mint)
                .rotationEffect(.degrees(animate ? 14 : 0))
                .offset(x: animate ? 78 : 0, y: animate ? 14 : 0)
            achievementTile(icon: "trophy.fill", title: "Hackathon Win", tint: Self.peach)
                .offset(y: animate ? -10 : 0)
        }
    }

    private func achievementTile(icon: String, title: String, tint: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(AlineTheme.inkPrimary)
                .frame(width: 64, height: 64)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(tint))
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
            Capsule().fill(AlineTheme.inkMuted.opacity(0.3)).frame(width: 60, height: 6)
        }
        .padding(16)
        .frame(width: 128, height: 160)
        .background(miniCardBackground)
    }

    private var miniCardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}

#Preview("Welcome") {
    WelcomeView(navViewModel: AppNavigationViewModel(), onCreateAccount: {}, onSignIn: {})
}
