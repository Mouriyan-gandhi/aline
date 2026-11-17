import QuickLookThumbnailing
import SwiftUI

/// The attached certificate itself (first page of a PDF, or the image), fetched from the
/// backend if it isn't on this device yet. Falls back to the file-type badge.
struct AttachmentThumbnail: View {
    let item: AchievementItem
    var height: CGFloat = 220

    @State private var image: UIImage?
    @State private var finished = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: height)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
            } else if finished {
                AchievementFileIcon(item: item, size: 84)
            } else {
                ProgressView()
                    .frame(height: 84)
            }
        }
        .task(id: item.attachmentName) { await load() }
    }

    private func load() async {
        defer { finished = true }
        guard let name = item.attachmentName,
              let url = await AttachmentStore.localURL(forAchievement: item.id, filename: name) else { return }
        let request = QLThumbnailGenerator.Request(
            fileAt: url, size: CGSize(width: 600, height: height * 2), scale: UIScreen.main.scale, representationTypes: .thumbnail
        )
        image = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request).uiImage
    }
}
