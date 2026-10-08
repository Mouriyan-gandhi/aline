import Foundation

/// Deterministic matching — pure set math over structured skills, no model call at all.
/// This is the plan's core cost-control + explainability design (sections 13-14 of the
/// product spec): "why you match" / "what's missing" must be real set operations the user
/// can trust, never an opaque "AI says 94%".
struct MatchResult {
    let score: Int // 0-100
    let matchedSkills: [String]
    let missingSkills: [String]
}

struct MatchEngine {
    static func match(profile: CareerProfile, job: Job) -> MatchResult {
        let profileSkills = Set(profile.skills.map { $0.lowercased() })
        let jobSkills = Set(job.extractedSkills.map { $0.lowercased() })

        guard !jobSkills.isEmpty else {
            // No skills extracted from this JD — neutral score, nothing to explain either way.
            return MatchResult(score: 50, matchedSkills: [], missingSkills: [])
        }

        let matched = jobSkills.intersection(profileSkills)
        let missing = jobSkills.subtracting(profileSkills)

        let score = Int((Double(matched.count) / Double(jobSkills.count) * 100).rounded())

        // Preserve original casing from the job's extracted skills for display.
        let matchedDisplay = job.extractedSkills.filter { matched.contains($0.lowercased()) }
        let missingDisplay = job.extractedSkills.filter { missing.contains($0.lowercased()) }

        return MatchResult(score: score, matchedSkills: matchedDisplay, missingSkills: missingDisplay)
    }
}
