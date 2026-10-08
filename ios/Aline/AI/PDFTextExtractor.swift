import PDFKit

enum PDFTextExtractor {
    static func extractText(from url: URL) -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        var text = ""
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            text += page.string ?? ""
            text += "\n"
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
