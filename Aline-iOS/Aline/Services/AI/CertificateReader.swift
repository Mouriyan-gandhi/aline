import Foundation
import FoundationModels
import ImageIO
import Vision

/// A certificate file (PDF or photo/screenshot) → the Achievement form's fields, so attaching
/// the certificate fills the form instead of the user retyping it.
///
/// Text comes from the PDF itself, or from Vision OCR for images; the on-device model then
/// reads title/issuer/date/folder. Without Apple Intelligence, keyword heuristics fill what
/// they can (well-known issuers, dates, the first prominent line as the title).
enum CertificateReader {
    struct Fields {
        var title = ""
        var issuer = ""
        var date: Date?
        var category: AchievementCategory?
        var description = ""
        var credentialURL = ""
    }

    static func read(_ url: URL) async -> Fields {
        guard let text = await text(of: url), !text.isEmpty else { return Fields() }
        var fields = Fields()
        fields.credentialURL = link(in: text)
        if let model = await readWithModel(text) {
            fields.title = model.title
            fields.issuer = model.issuer
            fields.date = parseDate(model.date)
            fields.category = AchievementCategory(rawValue: model.category)
            fields.description = model.description
        }
        let fallback = heuristics(text)
        if fields.title.isEmpty { fields.title = fallback.title }
        if fields.issuer.isEmpty { fields.issuer = fallback.issuer }
        if fields.date == nil { fields.date = fallback.date }
        if fields.category == nil { fields.category = fallback.category }
        return fields
    }

    // MARK: Text

    private static func text(of url: URL) async -> String? {
        if url.pathExtension.lowercased() == "pdf" {
            return PDFTextExtractor.extractText(from: url)
        }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let lines = (request.results as? [VNRecognizedTextObservation] ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            do {
                try VNImageRequestHandler(cgImage: image).perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    private static func link(in text: String) -> String {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return "" }
        let links = detector.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap(\.url)
            .filter { $0.scheme != "mailto" }
        // Verification links over plain homepages
        let verify = links.first { url in ["verify", "credential", "cert", "badge", "validate"].contains { url.absoluteString.lowercased().contains($0) } }
        return (verify ?? links.first)?.absoluteString ?? ""
    }

    // MARK: Model

    @Generable
    struct CertificateModel {
        @Guide(description: "What was earned, e.g. 'Programming in Java', 'AWS Certified Cloud Practitioner', 'Winner — Smart India Hackathon 2025'. Not the person's name, not the issuer.")
        var title: String
        @Guide(description: "Who issued it, e.g. 'NPTEL (IIT Kharagpur)', 'Coursera', 'Amazon Web Services', 'Google'")
        var issuer: String
        @Guide(description: "Date it was issued or completed, as written (e.g. '17 November 2025' or 'Jul–Oct 2025'). Empty if none.")
        var date: String
        @Guide(description: "Exactly one of: Certificates, Hackathons, Awards, Internships, Courses, Other")
        var category: String
        @Guide(description: "One short sentence about what was achieved, with any score, grade or rank stated, e.g. 'Completed the 12-week course with a score of 84% (Elite + Silver).' Never include the person's name. Empty if nothing beyond the title.")
        var description: String
    }

    private static func readWithModel(_ text: String) async -> CertificateModel? {
        guard OnDeviceAI.isAvailable else { return nil }
        let session = LanguageModelSession(instructions: """
        You read the text of a certificate, award or completion letter (extracted from a PDF or \
        a photo, so it may be out of order or contain OCR mistakes) and report what it certifies. \
        Copy names as written; never invent a score, date or issuer.
        """)
        return try? await session.respond(
            to: "Certificate text:\n\(String(text.prefix(3000)))", generating: CertificateModel.self
        ).content
    }

    // MARK: Heuristics

    private static let issuers = [
        "NPTEL", "Coursera", "Udemy", "edX", "Amazon Web Services", "AWS", "Google Cloud", "Google", "Microsoft",
        "Meta", "IBM", "Oracle", "Cisco", "HackerRank", "LeetCode", "GeeksforGeeks", "Infosys Springboard",
        "Great Learning", "Simplilearn", "Udacity", "freeCodeCamp", "LinkedIn Learning", "Salesforce", "NVIDIA",
        "Smart India Hackathon", "Devfolio", "Unstop", "MongoDB", "Red Hat", "CompTIA", "Kaggle",
    ]

    private static func heuristics(_ text: String) -> Fields {
        var fields = Fields()
        let lower = text.lowercased()
        fields.issuer = issuers.first { lower.contains($0.lowercased()) } ?? ""
        // "awarded to" is on nearly every certificate, so it doesn't make something an award
        let awardText = lower.replacingOccurrences(of: "awarded to", with: "").replacingOccurrences(of: "is awarded", with: "")
        fields.category = lower.contains("hackathon") || lower.contains("ideathon") ? .hackathons
            : lower.contains("internship") ? .internships
            : lower.contains("course") || lower.contains("nptel") || lower.contains("coursera") || lower.contains("udemy") ? .courses
            : awardText.contains("winner") || awardText.contains("award") || awardText.contains("prize") || awardText.contains(" rank") ? .awards
            : .certificates

        // Title: the first prominent line that isn't boilerplate or a person's name line
        let skip = ["certificate", "this is to certify", "certify that", "presented to", "awarded to", "has successfully",
                    "completed", "date", "signature", "director", "coordinator", "id:", "verify", "http", "www."]
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        if let index = lines.firstIndex(where: { $0.lowercased().contains("course") || $0.lowercased().contains("for completing") || $0.lowercased().contains("in recognition") }),
           index + 1 < lines.count, !lines[index + 1].isEmpty {
            fields.title = lines[index + 1]
        }
        if fields.title.isEmpty {
            fields.title = lines.first { line in
                line.count >= 6 && line.count <= 80 && !skip.contains { line.lowercased().contains($0) }
                    && line.lowercased() != fields.issuer.lowercased()
            } ?? ""
        }

        if let range = text.range(of: #"\b(\d{1,2}(st|nd|rd|th)?\s+)?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?,?\s+(\d{1,2},?\s+)?(19|20)\d{2}\b"#, options: .regularExpression) {
            fields.date = parseDate(String(text[range]))
        } else if let range = text.range(of: #"\b\d{1,2}[/-]\d{1,2}[/-](19|20)\d{2}\b"#, options: .regularExpression) {
            fields.date = parseDate(String(text[range]))
        }
        return fields
    }

    static func parseDate(_ raw: String) -> Date? {
        let text = raw.replacingOccurrences(of: #"(\d)(st|nd|rd|th)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        let formats = ["d MMMM yyyy", "d MMM yyyy", "MMMM d yyyy", "MMM d yyyy", "MMMM yyyy", "MMM yyyy",
                       "dd/MM/yyyy", "dd-MM-yyyy", "yyyy-MM-dd", "yyyy"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: text) { return date }
        }
        // "Jul–Oct 2025": the end month
        if let range = text.range(of: #"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(19|20)\d{2}"#, options: .regularExpression) {
            formatter.dateFormat = "MMM yyyy"
            return formatter.date(from: String(text[range]).replacingOccurrences(of: #"([A-Za-z]{3})[a-z]*"#, with: "$1", options: .regularExpression))
        }
        return nil
    }
}
