import SwiftUI

/// Spec section 28/65 "Filter Sheet" — company and role filters only for now (location/work
/// mode/skills/match-threshold/posted-date are real Phase 1 items once the backend has a
/// proper filter endpoint; these two are purely client-side against already-loaded jobs).
struct FilterSheetView: View {
    let viewModel: DiscoverViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var companySearch: String = ""

    private var filteredCompanyList: [String] {
        guard !companySearch.isEmpty else { return viewModel.availableCompanies }
        return viewModel.availableCompanies.filter {
            $0.localizedCaseInsensitiveContains(companySearch)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Role") {
                    ForEach(RoleCategory.all) { role in
                        filterRow(
                            label: role.name,
                            isSelected: viewModel.selectedRoles.contains(role.name)
                        ) {
                            toggle(role.name, in: &viewModel.selectedRoles)
                        }
                    }
                }

                Section("Company") {
                    TextField("Search companies", text: $companySearch)
                        .textInputAutocapitalization(.never)
                    ForEach(filteredCompanyList, id: \.self) { company in
                        filterRow(
                            label: company,
                            isSelected: viewModel.selectedCompanies.contains(company)
                        ) {
                            toggle(company, in: &viewModel.selectedCompanies)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") { viewModel.clearFilters() }
                        .disabled(viewModel.activeFilterCount == 0)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .tint(AlineColor.electricCobalt)
    }

    private func filterRow(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(AlineFont.body(15))
                    .foregroundStyle(AlineColor.charcoal)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AlineColor.electricCobalt)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ value: String, in set: inout Set<String>) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
}
