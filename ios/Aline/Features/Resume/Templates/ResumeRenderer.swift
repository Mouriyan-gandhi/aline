import SwiftUI
import UIKit

/// Turns a fixed template + profile into pixels — both for the auto-fit "zoom" the view
/// screen uses (per the product direction: zoom isn't just a viewer convenience, it scales
/// content density to keep the resume on one page) and for the actual PDF export.
/// MainActor-isolated because SwiftUI's ImageRenderer is itself MainActor-bound.
@MainActor
enum ResumeRenderer {
    /// Natural rendered height in points at a given scale — width is always fixed at
    /// ResumePage.contentWidth (every template frames itself to that width), so only height
    /// varies with content/scale.
    static func measuredHeight(templateID: ResumeTemplateID, profile: ResumeProfile, scale: CGFloat) -> CGFloat {
        let renderer = ImageRenderer(content: templateID.view(profile: profile, scale: scale))
        renderer.scale = 2 // measurement precision only, independent of export resolution
        guard let cgImage = renderer.cgImage else { return .greatestFiniteMagnitude }
        return CGFloat(cgImage.height) / renderer.scale
    }

    /// Largest scale in [floor, 1.0] that keeps the content on one A4 page, stepping down
    /// from full size. Falls back to `floor` if nothing fits — exportPDF then spills onto a
    /// second page rather than silently losing content below the fold.
    static func autoFitScale(
        templateID: ResumeTemplateID, profile: ResumeProfile, floor: CGFloat = 0.78
    ) -> CGFloat {
        var scale: CGFloat = 1.0
        while scale > floor {
            if measuredHeight(templateID: templateID, profile: profile, scale: scale) <= ResumePage.contentHeight {
                return scale
            }
            scale -= 0.02
        }
        return floor
    }

    /// Renders to PDF, one or more A4 pages. Pagination (when content exceeds one page even
    /// at the scale passed in) slices the single rendered image at page-height boundaries —
    /// robust and simple for the dominant case this product targets (one-page, early-career
    /// resumes). In the rare case content still spills past a page, a bullet could in
    /// principle be visually split at the page break, the same tradeoff a naive browser print
    /// makes — a known, documented limitation, not a silent correctness bug.
    static func exportPDF(templateID: ResumeTemplateID, profile: ResumeProfile, scale: CGFloat) -> Data? {
        let renderer = ImageRenderer(content: templateID.view(profile: profile, scale: scale))
        renderer.scale = 3 // print-quality export resolution

        guard let fullImage = renderer.cgImage else { return nil }
        let pixelsPerPoint = renderer.scale
        let fullHeightPoints = CGFloat(fullImage.height) / pixelsPerPoint
        let pageCount = max(1, Int((fullHeightPoints / ResumePage.contentHeight).rounded(.up)))

        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: ResumePage.width, height: ResumePage.height)
        )
        return pdfRenderer.pdfData { context in
            for page in 0..<pageCount {
                context.beginPage()
                let sliceYPoints = CGFloat(page) * ResumePage.contentHeight
                let sliceHeightPoints = min(ResumePage.contentHeight, fullHeightPoints - sliceYPoints)
                guard sliceHeightPoints > 0 else { continue }

                let sliceRectPixels = CGRect(
                    x: 0,
                    y: sliceYPoints * pixelsPerPoint,
                    width: CGFloat(fullImage.width),
                    height: sliceHeightPoints * pixelsPerPoint
                )
                guard let sliceImage = fullImage.cropping(to: sliceRectPixels) else { continue }

                let drawRect = CGRect(
                    x: ResumePage.margin, y: ResumePage.margin,
                    width: ResumePage.contentWidth, height: sliceHeightPoints
                )
                UIImage(cgImage: sliceImage, scale: pixelsPerPoint, orientation: .up).draw(in: drawRect)
            }
        }
    }
}
