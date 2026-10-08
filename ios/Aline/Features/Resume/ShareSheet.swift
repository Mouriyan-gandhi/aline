import SwiftUI

/// iOS's actual equivalent of a browser "download" — hands the file to Save to Files,
/// AirDrop, Mail, etc. Used for "Download PDF."
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
