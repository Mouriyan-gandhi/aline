import SwiftUI

/// Matches the real Figma "Community · Filter bottom sheet" (fileKey AiSKBBDDO9rIzyUPHmRm98,
/// node 887:20692, pulled 2026-10-13) exactly: "Filter discussions" + "Reset", a "Discussion
/// type" checkbox list, "Topics" chips, "Sort by" chips, teal "Apply Filters" button. Same
/// visual language as Discover's FilterSheetView (that one was itself adapted from this same
/// design), but this is the real thing it was standing in for — Community's own filter sheet,
/// not a borrowed pattern.
///
/// The Figma also shows a "Role" dropdown ("All roles") between Discussion type and Topics —
/// deliberately left out here: discussions only carry a free-text `role_title` from whoever
/// posted them (their own self-described role at signup), not a controlled vocabulary, so
/// filtering by it would either silently miss near-duplicates ("SDE" vs "Software Engineer")
/// or require inventing a canonical role list with nothing backing it. Not faked.
struct CommunityFilterSheetView: View {
    let viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                discussionTypeSection
                topicsSection
                sortSection
            }
            .padding(.horizontal, 23)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .safeAreaInset(edge: .bottom) {
            applyButton
                .padding(.horizontal, 23)
                .padding(.vertical, 12)
                .background(AlineColor.canvas)
        }
        .background(AlineColor.canvas)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationDetents([.fraction(0.75), .large])
    }

    private var header: some View {
        HStack {
            Text("Filter discussions")
                .font(AlineFont.sfPro(20, weight: .bold))
                .foregroundStyle(AlineColor.textPrimary)
            Spacer()
            Button("Reset") {
                viewModel.selectedCategory = nil
                viewModel.selectedTopics = []
            }
            .font(AlineFont.sfPro(12))
            .foregroundStyle(AlineColor.primary)
            .disabled(viewModel.activeFilterCount == 0)
        }
    }

    private var discussionTypeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Discussion type")
                .font(AlineFont.sfPro(13, weight: .bold))
                .foregroundStyle(AlineColor.textPrimary)
            checkboxRow(label: "All discussion types", isSelected: viewModel.selectedCategory == nil) {
                viewModel.selectedCategory = nil
            }
            ForEach(DiscussionCategory.allCases) { category in
                checkboxRow(label: category.rawValue, isSelected: viewModel.selectedCategory == category) {
                    viewModel.selectedCategory = (viewModel.selectedCategory == category) ? nil : category
                }
            }
        }
    }

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Topics")
                .font(AlineFont.sfPro(13, weight: .bold))
                .foregroundStyle(AlineColor.textPrimary)
            FlowLayout(spacing: 7) {
                ForEach(DiscussionTopic.allCases) { topic in
                    chip(
                        label: topic.rawValue,
                        isSelected: viewModel.selectedTopics.contains(topic)
                    ) {
                        if viewModel.selectedTopics.contains(topic) {
                            viewModel.selectedTopics.remove(topic)
                        } else {
                            viewModel.selectedTopics.insert(topic)
                        }
                    }
                }
            }
        }
    }

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sort by")
                .font(AlineFont.sfPro(13, weight: .bold))
                .foregroundStyle(AlineColor.textPrimary)
            HStack(spacing: 8) {
                ForEach(DiscussionSort.allCases) { option in
                    chip(label: option.label, isSelected: viewModel.sort == option) {
                        viewModel.sort = option
                    }
                }
            }
        }
    }

    private func checkboxRow(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isSelected ? AlineColor.primary : AlineColor.paperWhite)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(isSelected ? AlineColor.primary : AlineColor.inputBorder, lineWidth: 1)
                        )
                        .frame(width: 17, height: 17)
                    if isSelected {
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                    }
                }
                Text(label).font(AlineFont.sfPro(12)).foregroundStyle(AlineColor.textPrimary)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func chip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AlineFont.sfPro(11, weight: .semibold))
                .foregroundStyle(isSelected ? .white : AlineColor.textPrimary)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(isSelected ? AlineColor.primary : AlineColor.chipUnselected)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : AlineColor.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var applyButton: some View {
        Button {
            Task { await viewModel.load() }
            dismiss()
        } label: {
            Text("Apply Filters")
                .font(AlineFont.sfPro(15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .background(AlineColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
