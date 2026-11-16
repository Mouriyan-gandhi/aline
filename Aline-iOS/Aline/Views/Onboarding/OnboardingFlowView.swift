import SwiftUI
import UniformTypeIdentifiers

// MARK: - 5-Step Onboarding Flow (Matching Discover Feed Design System)
public struct OnboardingFlowView: View {
    @ObservedObject public var navViewModel: AppNavigationViewModel
    @State private var currentStep: Int = 1

    // Step 1: Opportunity Goal
    // Nothing is preselected: the user makes every choice themselves
    @State private var opportunityGoal: String = ""

    // Step 2: Career Stage & Expected Graduation Year
    @State private var careerStage: String = ""
    @State private var graduationYear: String = ""

    private static let graduationYearAnchor = "graduationYearPicker"

    // Step 3: Role Interests (Search & Select, Max 3)
    @State private var roleSearchText: String = ""
    @State private var selectedRoles: Set<String> = []
    @State private var showMaxRolesWarning: Bool = false

    // Step 4: Locations (Pills + Search & Choose Another Location)
    @State private var locationSearchText: String = ""
    @State private var isShowingChooseAnotherLocation: Bool = false
    @State private var visibleLocations: [String] = ["Bengaluru", "Hyderabad", "Chennai", "Mumbai", "Pune", "Delhi NCR"]
    @State private var selectedLocations: Set<String> = []
    @State private var openToAnyLocation: Bool = false

    // Step 5: Resume Upload
    @State private var uploadedResumeName: String? = nil
    @State private var uploadedResumeSize: String? = nil
    @State private var showFileImporter: Bool = false

    // Master Catalog of Roles
    let allAvailableRoles = [
        "Software Engineering",
        "Data Science",
        "AI / ML",
        "Data Analyst",
        "Data Scientist",
        "Backend Development",
        "Frontend Development",
        "Mobile Development",
        "Cloud / DevOps",
        "Cybersecurity",
        "Product Management",
        "UI/UX Design",
        "Embedded Systems",
        "Quality Assurance"
    ]

    // Master Catalog of Searchable Cities
    struct LocationItem: Identifiable, Hashable {
        var id: String { city }
        let city: String
        let region: String
    }

    let searchableCities: [LocationItem] = [
        LocationItem(city: "Kochi", region: "Kerala, India"),
        LocationItem(city: "Gurugram", region: "Haryana, India"),
        LocationItem(city: "Noida", region: "Uttar Pradesh, India"),
        LocationItem(city: "Ahmedabad", region: "Gujarat, India"),
        LocationItem(city: "Kolkata", region: "West Bengal, India"),
        LocationItem(city: "Chandigarh", region: "Punjab, India"),
        LocationItem(city: "Jaipur", region: "Rajasthan, India"),
        LocationItem(city: "Coimbatore", region: "Tamil Nadu, India"),
        LocationItem(city: "Indore", region: "Madhya Pradesh, India"),
        LocationItem(city: "Goa", region: "India"),
        LocationItem(city: "Remote", region: "Everywhere")
    ]

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Background matching Discover Home Screen (Creme base + soft blurred pastel radial circles)
            DiscoverBackgroundArtwork()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar (Back Arrow '<' on Left)
                HStack {
                    if currentStep > 1 {
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                currentStep -= 1
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Back")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(AlineTheme.inkPrimary)
                            .frame(height: 36)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(width: 60, height: 36)
                    }

                    Spacer()

                    if currentStep < 5 {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .alineGlassCapsule(selected: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 6)

                // Step Indicator & 5-Segment Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("STEP \(currentStep) OF 5")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.6)
                            .foregroundColor(AlineTheme.inkPrimary)

                        Spacer()

                        Text("About 2 min")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }

                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { step in
                            Capsule()
                                .fill(step <= currentStep ? Color.black : Color.black.opacity(0.12))
                                .frame(height: 3.5)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Main Scrollable Step Content
                ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        switch currentStep {
                        case 1:
                            step1GoalView
                        case 2:
                            step2CareerStageView
                        case 3:
                            step3RolesView
                        case 4:
                            step4LocationsView
                        case 5:
                            step5ResumeView
                        default:
                            EmptyView()
                        }

                        Spacer(minLength: 110) // Room for sticky bottom button
                        // Scroll target: aiming at the very end keeps the year card clear of the Continue bar
                        Color.clear.frame(height: 1).id(Self.graduationYearAnchor)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                }
                .scrollDismissesKeyboard(.interactively)
                // Picking 3rd or 4th year reveals the graduation year below, so bring it into view
                .onChange(of: careerStage) { _, stage in
                    guard stage == "3rd year student" || stage == "4th year student" else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeInOut(duration: 0.45)) {
                            scrollProxy.scrollTo(Self.graduationYearAnchor, anchor: .bottom)
                        }
                    }
                }
                }

                Spacer(minLength: 0)
            }

            // Bottom Sticky Bar with Continue Button (Matches Discover Feed Action Buttons)
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.97, blue: 0.95).opacity(0.0),
                        Color(red: 0.98, green: 0.97, blue: 0.95).opacity(0.85),
                        Color(red: 0.98, green: 0.97, blue: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)

                VStack {
                    Button {
                        guard canContinue else { return }
                        if currentStep < 5 {
                            withAnimation(AlineTheme.fastSpring) {
                                currentStep += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentStep == 5 ? "Explore Opportunities" : "Continue")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .alineGlassCapsule(selected: true)
                    }
                    .buttonStyle(.plain)
                    .opacity(canContinue ? 1 : 0.4)
                    .disabled(!canContinue)
                    .animation(AlineTheme.fastSpring, value: canContinue)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .background(Color(red: 0.98, green: 0.97, blue: 0.95))
            }
            .ignoresSafeArea(.keyboard)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    let hasAccess = url.startAccessingSecurityScopedResource()
                    defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }

                    uploadedResumeName = url.lastPathComponent
                    if let resources = try? url.resourceValues(forKeys: [.fileSizeKey]),
                       let size = resources.fileSize {
                        let mb = Double(size) / (1024.0 * 1024.0)
                        uploadedResumeSize = String(format: "%.1f MB · Uploaded", mb)
                    } else {
                        uploadedResumeSize = "PDF · Uploaded"
                    }
                }
            case .failure:
                break
            }
        }
    }

    /// Whether the current step has been answered, so Continue can move on
    private var canContinue: Bool {
        switch currentStep {
        case 1: return !opportunityGoal.isEmpty
        case 2:
            guard !careerStage.isEmpty else { return false }
            let isStudent = careerStage == "3rd year student" || careerStage == "4th year student"
            return !isStudent || !graduationYear.isEmpty
        case 3: return !selectedRoles.isEmpty
        case 4: return openToAnyLocation || !selectedLocations.isEmpty
        default: return true // resume upload is optional
        }
    }

    private func completeOnboarding() {
        withAnimation(AlineTheme.fastSpring) {
            navViewModel.completeOnboarding()
        }
    }

    // MARK: - Step 1: Goal
    @ViewBuilder
    private var step1GoalView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What are you\nlooking for?")
                    .font(.system(size: 26, weight: .heavy, design: .default))
                    .foregroundColor(AlineTheme.inkPrimary)

                Text("We'll prioritize roles and opportunities that match your immediate target.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineSpacing(3)
            }

            VStack(spacing: 12) {
                onboardingSelectionRow(
                    title: "Internship",
                    subtitle: "Short-term hands-on roles",
                    isSelected: opportunityGoal == "Internship"
                ) {
                    opportunityGoal = "Internship"
                }

                onboardingSelectionRow(
                    title: "Full-Time Job",
                    subtitle: "Permanent positions for graduates",
                    isSelected: opportunityGoal == "Full-Time Job"
                ) {
                    opportunityGoal = "Full-Time Job"
                }

                onboardingSelectionRow(
                    title: "Both",
                    subtitle: "Open to internships and full-time",
                    isSelected: opportunityGoal == "Both"
                ) {
                    opportunityGoal = "Both"
                }
            }
        }
    }

    // MARK: - Step 2: Career Stage (Conditional Expected Graduation Year)
    @ViewBuilder
    private var step2CareerStageView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Where are you\nin your career?")
                    .font(.system(size: 26, weight: .heavy, design: .default))
                    .foregroundColor(AlineTheme.inkPrimary)

                Text("This helps us suggest roles tailored for your eligibility and experience.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineSpacing(3)
            }

            VStack(spacing: 12) {
                ForEach(["3rd year student", "4th year student", "Recent graduate", "Working professional"], id: \.self) { stage in
                    onboardingSelectionRow(
                        title: stage,
                        subtitle: nil,
                        isSelected: careerStage == stage
                    ) {
                        withAnimation(AlineTheme.fastSpring) {
                            careerStage = stage
                        }
                    }
                }
            }

            // Graduation Year ONLY visible if 3rd year or 4th year student
            let isCollegeStudent = careerStage == "3rd year student" || careerStage == "4th year student"
            if isCollegeStudent {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Expected Graduation Year")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .padding(.top, 8)

                    // Calendar-style card: page through years with the arrows, tap one to pick it
                    GraduationYearPicker(selection: $graduationYear)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Step 3: Role Interests (Search and Select, Max 3)
    @ViewBuilder
    private var step3RolesView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What roles interest you?")
                    .font(.system(size: 26, weight: .heavy, design: .default))
                    .foregroundColor(AlineTheme.inkPrimary)

                Text("Pick up to three roles. We'll use them to explain why each opportunity could be a strong fit.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineSpacing(3)
            }

            // Search Bar (Matching Discover Screen Search Bar)
            AlineSearchField("Search roles", text: $roleSearchText)

            // Selection Count Chip
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("\(selectedRoles.count) selected")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(selectedRoles.isEmpty ? AlineTheme.inkPrimary : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(selectedRoles.isEmpty ? Color.white : Color.black)
                )
                .overlay(
                    Capsule().stroke(Color.black.opacity(selectedRoles.isEmpty ? 0.12 : 0), lineWidth: 1)
                )

                Text("Maximum 3 roles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AlineTheme.inkSecondary)

                Spacer()
            }

            let trimmedRoleQuery = roleSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

            // Filtered Roles when Searching
            if !trimmedRoleQuery.isEmpty {
                let matching = allAvailableRoles.filter { $0.localizedCaseInsensitiveContains(trimmedRoleQuery) }

                HStack {
                    Text("Matching roles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                    Spacer()
                    Text("\(matching.count) results")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AlineTheme.inkSecondary)
                }

                if matching.isEmpty {
                    Text("No roles found matching \"\(trimmedRoleQuery)\"")
                        .font(.system(size: 13))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 10) {
                        ForEach(matching, id: \.self) { role in
                            let isSelected = selectedRoles.contains(role)
                            roleSelectionCard(role: role, isSelected: isSelected) {
                                toggleRoleSelection(role: role)
                            }
                        }
                    }
                }

                // If user selected 3 roles, show reminder and selected roles card list
                if selectedRoles.count >= 3 {
                    Text("You've selected 3 roles. Remove one below to choose another.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AlineTheme.inkSecondary)
                        .padding(.top, 4)

                    HStack {
                        Text("Your selected roles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Spacer()
                        Text("Tap × to remove")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }

                    VStack(spacing: 8) {
                        ForEach(Array(selectedRoles).sorted(), id: \.self) { role in
                            HStack {
                                Text(role)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.black)

                                Button {
                                    withAnimation(AlineTheme.fastSpring) {
                                        _ = selectedRoles.remove(role)
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                        .frame(width: 24, height: 24)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                }
            } else {
                // Full List when search is empty
                VStack(spacing: 10) {
                    ForEach(allAvailableRoles, id: \.self) { role in
                        let isSelected = selectedRoles.contains(role)
                        roleSelectionCard(role: role, isSelected: isSelected) {
                            toggleRoleSelection(role: role)
                        }
                    }
                }
            }
        }
    }

    private func roleSelectionCard(role: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(role)
                    .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(AlineTheme.inkPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.black)
                } else {
                    Circle()
                        .stroke(Color.black.opacity(0.18), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.black : Color.black.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func toggleRoleSelection(role: String) {
        withAnimation(AlineTheme.fastSpring) {
            if selectedRoles.contains(role) {
                _ = selectedRoles.remove(role)
            } else if selectedRoles.count < 3 {
                selectedRoles.insert(role)
            }
        }
    }

    // MARK: - Step 4: Locations (Pills, Search, and Open to Any Location)
    @ViewBuilder
    private var step4LocationsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Where are you\nopen to working?")
                    .font(.system(size: 26, weight: .heavy, design: .default))
                    .foregroundColor(AlineTheme.inkPrimary)

                Text("We'll prioritize these preferences and surface exceptional nearby opportunities.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineSpacing(3)
            }

            // Section Header: SELECT LOCATIONS
            HStack {
                Text("SELECT LOCATIONS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(AlineTheme.inkSecondary)

                Spacer()

                if openToAnyLocation {
                    Text("Specific cities disabled")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AlineTheme.inkSecondary)
                } else {
                    Text("\(selectedLocations.count) selected")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AlineTheme.inkPrimary)
                }
            }

            // Location Pills in Flow Layout
            FlowLayout(spacing: 8) {
                ForEach(visibleLocations, id: \.self) { loc in
                    let isSelected = selectedLocations.contains(loc)
                    Button {
                        if !openToAnyLocation {
                            withAnimation(AlineTheme.fastSpring) {
                                if isSelected {
                                    _ = selectedLocations.remove(loc)
                                } else {
                                    selectedLocations.insert(loc)
                                }
                            }
                        }
                    } label: {
                        Text(loc)
                            .font(.system(size: 13, weight: isSelected && !openToAnyLocation ? .bold : .semibold))
                            .foregroundColor(openToAnyLocation ? AlineTheme.inkMuted : (isSelected ? .white : AlineTheme.inkPrimary))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(openToAnyLocation ? Color.white.opacity(0.5) : (isSelected ? Color.black : Color.white))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(openToAnyLocation ? 0.04 : (isSelected ? 0 : 0.08)), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(isSelected && !openToAnyLocation ? 0.12 : 0.02), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(openToAnyLocation)
                }
            }

            // + Choose Another Location Button
            Button {
                withAnimation(AlineTheme.fastSpring) {
                    isShowingChooseAnotherLocation.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Choose another location")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(openToAnyLocation ? AlineTheme.inkMuted : AlineTheme.inkPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .disabled(openToAnyLocation)

            // Choose Another Location Expandable Search Card
            if isShowingChooseAnotherLocation && !openToAnyLocation {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Choose another location")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                        Spacer()
                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                isShowingChooseAnotherLocation = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    AlineSearchField("Search city", text: $locationSearchText)

                    let query = locationSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    let matchedCities = searchableCities.filter {
                        query.isEmpty || $0.city.localizedCaseInsensitiveContains(query) || $0.region.localizedCaseInsensitiveContains(query)
                    }

                    VStack(spacing: 0) {
                        ForEach(matchedCities.prefix(4)) { item in
                            Button {
                                withAnimation(AlineTheme.fastSpring) {
                                    if !visibleLocations.contains(item.city) {
                                        visibleLocations.append(item.city)
                                    }
                                    selectedLocations.insert(item.city)
                                    locationSearchText = ""
                                    isShowingChooseAnotherLocation = false
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.black)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.city)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(AlineTheme.inkPrimary)
                                        Text(item.region)
                                            .font(.system(size: 11))
                                            .foregroundColor(AlineTheme.inkSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: selectedLocations.contains(item.city) ? "checkmark.circle.fill" : "plus.circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.black)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)

                            if item != matchedCities.prefix(4).last {
                                Divider().opacity(0.08)
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Open to Any Location: same white row with the tick on the right as every other onboarding choice
            onboardingSelectionRow(
                title: "Open to any location",
                subtitle: openToAnyLocation ? "Turn this off to choose specific cities." : nil,
                isSelected: openToAnyLocation
            ) {
                withAnimation(AlineTheme.fastSpring) {
                    openToAnyLocation.toggle()
                }
            }
        }
    }

    // MARK: - Step 5: Resume Upload
    @ViewBuilder
    private var step5ResumeView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Have a resume?")
                    .font(.system(size: 26, weight: .heavy, design: .default))
                    .foregroundColor(AlineTheme.inkPrimary)

                Text("Upload it and we'll personalize your opportunities and application preparation.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AlineTheme.inkSecondary)
                    .lineSpacing(3)
            }

            // Big Dashed Dropzone Card (Matching User Screenshot)
            VStack(spacing: 14) {
                if let name = uploadedResumeName {
                    // Uploaded State
                    VStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(red: 0.90, green: 0.96, blue: 0.90))
                                .frame(width: 60, height: 60)

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Color(red: 0.15, green: 0.65, blue: 0.35))
                        }

                        Text(name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineLimit(1)

                        Text(uploadedResumeSize ?? "PDF · Ready to parse")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(AlineTheme.inkSecondary)

                        Button {
                            withAnimation(AlineTheme.fastSpring) {
                                uploadedResumeName = nil
                                uploadedResumeSize = nil
                            }
                        } label: {
                            Text("Remove / Replace")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.red.opacity(0.85))
                                .padding(.top, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 24)
                } else {
                    // Default Upload State
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(red: 0.94, green: 0.96, blue: 0.72)) // Soft pastel yellow/lime
                                .frame(width: 60, height: 60)

                            Image(systemName: "arrow.up.doc.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.18, green: 0.40, blue: 0.22))
                        }

                        Text("Drop your resume here")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Text("PDF or DOCX · Up to 5 MB")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AlineTheme.inkSecondary)

                        Button {
                            showFileImporter = true
                        } label: {
                            Text("Upload Resume")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .alineGlassCapsule(selected: true)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 26)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        Color.black.opacity(0.12),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )

            // Privacy Guarantee Banner (Matching Screenshot)
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.18, green: 0.50, blue: 0.28))
                    .padding(.top, 1)

                Text("Your resume stays private. Aline uses it only to improve your profile and opportunity recommendations.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .lineSpacing(3)

                Spacer()
            }
            .padding(16)
            .background(
                Color(red: 0.94, green: 0.96, blue: 0.78) // Light pastel yellow/mint
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Skip for Now Button
            if uploadedResumeName == nil {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .alineGlassCapsule(selected: false)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Shared Option Selection Row (Matching Discover Clean Card Style)
    private func onboardingSelectionRow(
        title: String,
        subtitle: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(AlineTheme.inkPrimary)

                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 13))
                            .foregroundColor(AlineTheme.inkSecondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.black)
                } else {
                    Circle()
                        .stroke(Color.black.opacity(0.18), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.black : Color.black.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews
#Preview("Onboarding Flow Canvas") {
    let nav = AppNavigationViewModel()
    nav.hasCompletedOnboarding = false
    return OnboardingFlowView(navViewModel: nav)
}

// MARK: - Graduation Year Picker (calendar-style card)
/// Nine years per page in a 3 × 3 grid, ‹ › to move between pages, the chosen year filled black.
struct GraduationYearPicker: View {
    @Binding var selection: String
    @State private var pageStart: Int

    private static let pageSize = 9
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    private let firstAllowed: Int
    private let lastAllowed: Int

    init(selection: Binding<String>) {
        self._selection = selection
        let thisYear = Calendar.current.component(.year, from: Date())
        firstAllowed = thisYear - 9
        lastAllowed = thisYear + 17
        // Open on the page that holds the current choice, starting from this year
        let selected = Int(selection.wrappedValue) ?? thisYear
        let offset = (selected - thisYear).quotientRoundedDown(by: Self.pageSize) * Self.pageSize
        self._pageStart = State(initialValue: thisYear + offset)
    }

    private var years: [Int] { Array(pageStart..<(pageStart + Self.pageSize)) }
    private var canGoBack: Bool { pageStart - Self.pageSize >= firstAllowed }
    private var canGoForward: Bool { pageStart + Self.pageSize <= lastAllowed }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                pageButton("chevron.left", enabled: canGoBack) { pageStart -= Self.pageSize }
                Spacer()
                Text("\(String(pageStart)) – \(String(pageStart + Self.pageSize - 1))")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AlineTheme.inkPrimary)
                    .contentTransition(.numericText())
                Spacer()
                pageButton("chevron.right", enabled: canGoForward) { pageStart += Self.pageSize }
            }

            Divider()

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(years, id: \.self) { year in
                    let isSelected = selection == String(year)
                    Button {
                        withAnimation(AlineTheme.fastSpring) { selection = String(year) }
                    } label: {
                        Text(String(year))
                            .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Capsule().fill(isSelected ? AlineTheme.pillDark : Color.clear))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                }
            }

            Divider()

            Text(selection.isEmpty ? "Pick the year you'll graduate" : "Class of \(selection)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AlineTheme.inkSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    private func pageButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(AlineTheme.fastSpring) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AlineTheme.inkPrimary)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .alineGlassCircleButton()
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .accessibilityLabel(icon == "chevron.left" ? "Earlier years" : "Later years")
    }
}

private extension Int {
    /// Floor division that also works for negative numbers
    func quotientRoundedDown(by divisor: Int) -> Int {
        let q = self / divisor
        return (self % divisor != 0 && (self < 0) != (divisor < 0)) ? q - 1 : q
    }
}
