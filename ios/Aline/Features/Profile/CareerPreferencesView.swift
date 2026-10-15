import SwiftUI

/// Matches the Figma Settings entry "Career preferences" — editing the same
/// lookingFor/careerStage/preferredRoles/preferredLocations onboarding originally asked for,
/// now reachable without re-running onboarding. Writes to the SAME @AppStorage key
/// ("userPreferencesData") AlineApp owns — @AppStorage's change notification isn't scoped to
/// one property-wrapper instance, so saving here propagates back up through AlineApp ->
/// RootTabView -> DiscoverView/ProfileView automatically, no manual callback plumbing needed.
struct CareerPreferencesView: View {
    @AppStorage("userPreferencesData") private var preferencesData: Data = Data()
    @Environment(\.dismiss) private var dismiss

    @State private var lookingFor: LookingFor = .fullTime
    @State private var careerStage: CareerStage?
    @State private var selectedRoles: Set<String> = []
    @State private var roleSearchText: String = ""
    @State private var selectedLocations: Set<String> = []
    @State private var openToAnyLocation = false
    @State private var hasLoaded = false

    private var roleChoices: [OnboardingRoleInterest] {
        guard !roleSearchText.isEmpty else { return OnboardingRoleInterest.all }
        return OnboardingRoleInterest.all.filter { $0.label.localizedCaseInsensitiveContains(roleSearchText) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                section("What are you looking for?") {
                    ForEach(LookingFor.allCases, id: \.self) { option in
                        selectableRow(title: option.rawValue, subtitle: option.subtitle, isSelected: lookingFor == option) {
                            lookingFor = option
                        }
                    }
                }

                section("Career stage") {
                    ForEach(CareerStage.allCases, id: \.self) { stage in
                        selectableRow(title: stage.rawValue, subtitle: stage.subtitle, isSelected: careerStage == stage) {
                            careerStage = stage
                        }
                    }
                }

                section("Role interests · up to 3") {
                    TextField("Search roles", text: $roleSearchText)
                        .font(AlineFont.sfPro(14))
                        .padding(.horizontal, 13).padding(.vertical, 10)
                        .background(AlineColor.paperWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AlineColor.inputBorder, lineWidth: 1))
                    FlowLayout(spacing: 8) {
                        ForEach(roleChoices) { interest in
                            chip(label: interest.label, isSelected: selectedRoles.contains(interest.label)) {
                                toggleRole(interest.label)
                            }
                        }
                    }
                    Text("\(selectedRoles.count)/3 selected").font(AlineFont.sfPro(11)).foregroundStyle(AlineColor.textSecondary)
                }

                section("Preferred locations") {
                    chip(label: "Open to any location", isSelected: openToAnyLocation) {
                        openToAnyLocation = true
                        selectedLocations = []
                    }
                    FlowLayout(spacing: 8) {
                        ForEach(OnboardingRoleInterest.preferredLocationChoices, id: \.self) { location in
                            chip(label: location, isSelected: selectedLocations.contains(location)) {
                                openToAnyLocation = false
                                if selectedLocations.contains(location) {
                                    selectedLocations.remove(location)
                                } else {
                                    selectedLocations.insert(location)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(AlineColor.canvas)
        .navigationTitle("Career Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button { save() } label: {
                Text("Save Changes").frame(maxWidth: .infinity)
            }
            .buttonStyle(AlinePrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AlineColor.canvas)
        }
        .onAppear { loadIfNeeded() }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(AlineFont.sfPro(16, weight: .bold)).foregroundStyle(AlineColor.textPrimary)
            content()
        }
    }

    private func selectableRow(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AlineFont.sfPro(14, weight: .semibold)).foregroundStyle(AlineColor.textPrimary)
                    Text(subtitle).font(AlineFont.sfPro(12)).foregroundStyle(AlineColor.textSecondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(AlineColor.primary)
                } else {
                    Image(systemName: "circle").foregroundStyle(AlineColor.inputBorder)
                }
            }
            .padding(12)
            .background(AlineColor.paperWhite)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(isSelected ? AlineColor.primary : AlineColor.cardBorder, lineWidth: isSelected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }

    private func chip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AlineFont.sfPro(12, weight: .semibold))
                .foregroundStyle(isSelected ? .white : AlineColor.textPrimary)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(isSelected ? AlineColor.primary : AlineColor.chipUnselected)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func toggleRole(_ label: String) {
        if selectedRoles.contains(label) {
            selectedRoles.remove(label)
        } else if selectedRoles.count < 3 {
            selectedRoles.insert(label)
        }
    }

    private func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        guard let decoded = try? JSONDecoder().decode(UserPreferences.self, from: preferencesData) else { return }
        lookingFor = decoded.lookingFor
        careerStage = decoded.careerStage
        selectedRoles = decoded.preferredRoles
        selectedLocations = decoded.preferredLocations
        openToAnyLocation = decoded.preferredLocations.isEmpty
    }

    private func save() {
        let updated = UserPreferences(
            lookingFor: lookingFor, careerStage: careerStage,
            preferredRoles: selectedRoles,
            preferredLocations: openToAnyLocation ? [] : selectedLocations
        )
        preferencesData = (try? JSONEncoder().encode(updated)) ?? Data()
        dismiss()
    }
}
