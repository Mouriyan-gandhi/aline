import PDFKit

/// Resume PDF → text that keeps the layout a reader relies on.
///
/// `PDFPage.string` alone loses it: table cells run together ("Degree Institute/Board CGPA
/// Year B.Tech. …") and two-column resumes interleave both columns line by line. This rebuilds
/// the text from each character's position on the page instead:
/// - characters are grouped into lines by baseline, then ordered left to right
/// - a wide horizontal gap inside a line becomes " | " (a table cell or a right-aligned date)
/// - when the page has a consistent vertical gutter (a two-column layout), the left column is
///   read in full before the right one
enum PDFTextExtractor {
    static func extractText(from url: URL) -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        var pages: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let text = layoutText(of: page) ?? page.string ?? ""
            pages.append(text)
        }
        let text = pages.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    private struct Glyph {
        let character: Character
        let rect: CGRect
    }

    private struct Line {
        var glyphs: [Glyph]
        var midY: CGFloat
        var height: CGFloat
        var minX: CGFloat { glyphs.first?.rect.minX ?? 0 }
        var maxX: CGFloat { glyphs.map(\.rect.maxX).max() ?? 0 }
    }

    private static func layoutText(of page: PDFPage) -> String? {
        let bounds = page.bounds(for: .mediaBox)
        // PDFKit's own line detection (it accounts for font metrics); character positions are
        // only used for spacing inside a line. Per-glyph boxes can't group lines on their own:
        // they're ink boxes, so "i" and "g" sit at different heights than their neighbours.
        guard let all = page.selection(for: bounds) else { return nil }
        var lines: [Line] = []
        for selection in all.selectionsByLine() {
            var glyphs: [Glyph] = []
            for r in 0..<selection.numberOfTextRanges(on: page) {
                let range = selection.range(at: r, on: page)
                guard range.location != NSNotFound else { continue }
                for i in range.location..<(range.location + range.length) {
                    // Text and position from the same one-character selection, so they always
                    // agree (characterBounds(at:) indexes don't line up with page.string's)
                    guard let single = page.selection(for: NSRange(location: i, length: 1)),
                          let text = single.string, let character = text.first else { continue }
                    let rect = single.bounds(for: page)
                    if character.isWhitespace || character.isNewline || rect.width <= 0 { continue }
                    // A line's text ranges can overlap by one character at their boundary
                    if let last = glyphs.last, last.character == character, abs(last.rect.minX - rect.minX) < 0.5 { continue }
                    glyphs.append(Glyph(character: character, rect: rect))
                }
            }
            guard !glyphs.isEmpty else { continue }
            let lineBounds = selection.bounds(for: page)
            lines.append(Line(glyphs: glyphs, midY: lineBounds.midY, height: max(lineBounds.height, 1)))
        }
        guard lines.count >= 3 else { return nil }

        // Cells of one table row can come back as separate lines: merge lines on the same baseline
        lines.sort { $0.midY > $1.midY }
        var merged: [Line] = []
        for line in lines {
            if let last = merged.last, abs(last.midY - line.midY) < min(last.height, line.height) * 0.5 {
                merged[merged.count - 1].glyphs += line.glyphs
            } else {
                merged.append(line)
            }
        }
        for i in merged.indices { merged[i].glyphs.sort { $0.rect.minX < $1.rect.minX } }

        if let gutter = columnGutter(merged, pageWidth: bounds.width) {
            let left = merged.compactMap { line -> Line? in
                let g = line.glyphs.filter { $0.rect.midX < gutter }
                return g.isEmpty ? nil : Line(glyphs: g, midY: line.midY, height: line.height)
            }
            let right = merged.compactMap { line -> Line? in
                let g = line.glyphs.filter { $0.rect.midX >= gutter }
                return g.isEmpty ? nil : Line(glyphs: g, midY: line.midY, height: line.height)
            }
            return (left.map(render) + [""] + right.map(render)).joined(separator: "\n")
        }
        return merged.map(render).joined(separator: "\n")
    }

    /// Text of one line: a normal gap is a space, a wide one is a cell break.
    private static func render(_ line: Line) -> String {
        let widths = line.glyphs.map(\.rect.width).sorted()
        let typical = widths[widths.count / 2]
        var text = ""
        var previous: Glyph?
        for glyph in line.glyphs {
            if let previous {
                let gap = glyph.rect.minX - previous.rect.maxX
                if gap > typical * 2.2 {
                    text += " | "
                } else if gap > typical * 0.22 {
                    text += " "
                }
            }
            text.append(glyph.character)
            previous = glyph
        }
        return text
    }

    /// x of a vertical gutter that splits most lines in two, if the page has one.
    private static func columnGutter(_ lines: [Line], pageWidth: CGFloat) -> CGFloat? {
        guard lines.count >= 12, pageWidth > 0 else { return nil }
        let bins = 100
        var covered = [Int](repeating: 0, count: bins)
        for line in lines {
            for glyph in line.glyphs {
                let start = max(0, Int(glyph.rect.minX / pageWidth * CGFloat(bins)))
                let end = min(bins - 1, Int(glyph.rect.maxX / pageWidth * CGFloat(bins)))
                if start <= end { for b in start...end { covered[b] += 1 } }
            }
        }
        // Lines with text on both sides of a candidate gutter
        func twoSided(_ x: CGFloat) -> Int {
            lines.filter { $0.minX < x - 10 && $0.maxX > x + 10 }.count
        }
        let lineCount = lines.count
        var best: (bin: Int, score: Int)?
        // A few full-width lines (the name banner, a section rule) may cross the gutter
        for bin in 25...75 where covered[bin] <= max(1, lineCount / 20) {
            let x = CGFloat(bin) / CGFloat(bins) * pageWidth
            let score = twoSided(x)
            if score >= lineCount * 3 / 10, score > (best?.score ?? 0) {
                best = (bin, score)
            }
        }
        guard let best else { return nil }
        return CGFloat(best.bin) / CGFloat(bins) * pageWidth
    }
}
