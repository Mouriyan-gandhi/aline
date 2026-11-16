import SwiftUI

/// Renders a resume to a real PDF file — the same templates and page layout as the in-app A4
/// preview (ResumeA4SheetView): each of the resume's own pages fitted onto one A4 sheet by
/// widening then scaling, or, for very long single-page content, consecutive A4 slices.
///
/// Files are written to the app's Documents/Resumes folder, which the Files app shows under
/// "On My iPhone › Aline" (UIFileSharingEnabled + LSSupportsOpeningDocumentsInPlace).
@MainActor
enum ResumePDFExporter {
    // Same geometry as ResumeA4SheetView.
    private static let baseWidth: CGFloat = 400
    private static let aspect: CGFloat = 1.4142
    private static let pageMargin: CGFloat = 16
    private static let maxPagesOnOneSheet: CGFloat = 3.2
    private static var baseHeight: CGFloat { baseWidth * aspect }
    private static var sliceHeight: CGFloat { baseHeight - pageMargin * 2 }
    /// A4 in PDF points.
    private static let a4 = CGSize(width: 595.2, height: 841.8)

    static var folder: URL {
        URL.documentsDirectory.appendingPathComponent("Resumes", isDirectory: true)
    }

    static func export(_ resume: ResumeDocument) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let name = resume.fileName.isEmpty ? "Resume.pdf" : resume.fileName
        let url = folder.appendingPathComponent(name.hasSuffix(".pdf") ? name : name + ".pdf")

        var mediaBox = CGRect(origin: .zero, size: a4)
        guard let pdf = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        for page in pages(for: resume) {
            let renderer = ImageRenderer(content: page)
            renderer.proposedSize = ProposedViewSize(width: baseWidth, height: baseHeight)
            pdf.beginPDFPage(nil)
            pdf.scaleBy(x: a4.width / baseWidth, y: a4.height / baseHeight)
            renderer.render { _, draw in draw(pdf) }
            pdf.endPDFPage()
        }
        pdf.closePDF()
        return url
    }

    /// Every printed page as a 400 × 566 white sheet.
    private static func pages(for resume: ResumeDocument) -> [AnyView] {
        let sectionPages = resume.pageSections
        let fullHeight = height(of: content(resume, sections: nil), width: baseWidth)
        let fitsOnSheets = sectionPages.count > 1
            || resume.selectedTemplate == .professional
            || fullHeight <= sliceHeight * maxPagesOnOneSheet

        if fitsOnSheets {
            // Widen so text shrinks evenly but still spans the sheet, sized for the fullest page.
            let tallest = sectionPages.map { height(of: content(resume, sections: $0), width: baseWidth) }.max() ?? fullHeight
            var width = tallest > sliceHeight ? baseWidth * (tallest / sliceHeight).squareRoot() : baseWidth
            let widenedTallest = sectionPages.map { height(of: content(resume, sections: $0), width: width) }.max() ?? 0
            let scaledHeight = widenedTallest * baseWidth / width
            if scaledHeight > sliceHeight {
                width *= (scaledHeight / sliceHeight).squareRoot()
            }
            let shrink = baseWidth / width
            return sectionPages.map { sections in
                let rendered = height(of: content(resume, sections: sections), width: width)
                let squeeze = rendered * shrink > sliceHeight ? sliceHeight / (rendered * shrink) : 1
                return AnyView(sheet(
                    content(resume, sections: sections)
                        .frame(width: width)
                        .fixedSize(horizontal: false, vertical: true)
                        .scaleEffect(shrink * squeeze, anchor: .top)
                        .frame(width: baseWidth, height: sliceHeight, alignment: .top)
                        .clipped()
                ))
            }
        }

        var starts: [CGFloat] = [0]
        while fullHeight - starts.last! > sliceHeight {
            starts.append(starts.last! + sliceHeight)
        }
        return starts.map { start in
            AnyView(sheet(
                content(resume, sections: nil)
                    .frame(width: baseWidth)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: -start)
                    .frame(width: baseWidth, height: min(sliceHeight, fullHeight - start), alignment: .top)
                    .clipped()
            ))
        }
    }

    private static func sheet(_ page: some View) -> some View {
        page
            .padding(.vertical, pageMargin)
            .frame(width: baseWidth, height: baseHeight, alignment: .top)
            .background(Color.white)
            .environment(\.colorScheme, .light)
    }

    /// The template itself, as ResumeA4SheetView.pageContent draws it.
    @ViewBuilder
    private static func content(_ resume: ResumeDocument, sections: Set<ResumeSection>?) -> some View {
        Group {
            switch resume.selectedTemplate {
            case .standard:
                StandardTemplateView(resume: resume).padding(.horizontal, 14)
            case .professional:
                ProfessionalTemplateView(resume: resume)
            case .modern:
                ModernTemplateView(resume: resume).padding(.horizontal, 14)
            }
        }
        .environment(\.resumePageSections, sections)
    }

    private static func height(of view: some View, width: CGFloat) -> CGFloat {
        let renderer = ImageRenderer(content: view.frame(width: width).fixedSize(horizontal: false, vertical: true))
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        var size = CGSize.zero
        renderer.render { renderedSize, _ in size = renderedSize }
        return size.height
    }
}
