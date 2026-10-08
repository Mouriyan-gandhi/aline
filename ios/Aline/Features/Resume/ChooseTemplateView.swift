import SwiftUI
import SwiftData

/// Template selection — the thumbnails render the real template with the person's actual
/// data (scaled down), not a generic mock, so what they pick is what they'll actually get.
struct ChooseTemplateView: View {
    let profile: ResumeProfile
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Query private var existingDocuments: [ResumeDocument]
    @State private var selected: ResumeTemplateID = .standard

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose your resume template")
                    .font(AlineFont.display(22))
                    .foregroundStyle(AlineColor.inkNavy)

                ForEach(ResumeTemplateID.allCases) { template in
                    templateCard(template)
                }

                Text("You can change your template later.")
                    .font(AlineFont.body(12))
                    .foregroundStyle(AlineColor.stone)
                    .frame(maxWidth: .infinity, alignment: .center)

                Button {
                    createDocument()
                } label: {
                    Text("Continue").frame(maxWidth: .infinity)
                }
                .buttonStyle(AlinePrimaryButtonStyle())
            }
            .padding(16)
        }
        .background(AlineColor.warmCanvas)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func templateCard(_ template: ResumeTemplateID) -> some View {
        Button {
            selected = template
        } label: {
            HStack(spacing: 14) {
                thumbnail(template)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Template \(String(format: "%02d", ResumeTemplateID.allCases.firstIndex(of: template)! + 1))")
                        .font(AlineFont.body(11)).foregroundStyle(AlineColor.stone)
                    Text(template.displayName)
                        .font(AlineFont.display(18)).foregroundStyle(AlineColor.inkNavy)
                    Text(template.tagline)
                        .font(AlineFont.body(13)).foregroundStyle(AlineColor.graphite)
                    Text("Best for: \(template.bestFor)")
                        .font(AlineFont.body(12)).foregroundStyle(AlineColor.stone)
                }
                Spacer()
                Image(systemName: selected == template ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected == template ? AlineColor.electricCobalt : AlineColor.creamBorder)
                    .font(.system(size: 20))
            }
            .padding(12)
            .background(AlineColor.paperWhite)
            .clipShape(RoundedRectangle(cornerRadius: AlineRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AlineRadius.card, style: .continuous)
                    .stroke(selected == template ? AlineColor.electricCobalt : AlineColor.creamBorder, lineWidth: selected == template ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func thumbnail(_ template: ResumeTemplateID) -> some View {
        let thumbWidth: CGFloat = 70
        let thumbHeight: CGFloat = 92
        let renderScale = thumbWidth / ResumePage.width

        return template.view(profile: profile, scale: 1.0)
            .frame(width: ResumePage.width, height: ResumePage.height, alignment: .top)
            .background(Color.white)
            .scaleEffect(renderScale, anchor: .topLeading)
            .frame(width: thumbWidth, height: thumbHeight, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(AlineColor.creamBorder))
            .allowsHitTesting(false)
    }

    private func createDocument() {
        let isFirst = existingDocuments.isEmpty
        let name = profile.fullName.isEmpty ? "My Resume" : "\(profile.fullName)'s Resume"
        let document = ResumeDocument(displayName: name, templateID: selected.rawValue, profile: profile, isDefault: isFirst)
        modelContext.insert(document)
        path.append(ResumeRoute.detail(document.id))
    }
}
