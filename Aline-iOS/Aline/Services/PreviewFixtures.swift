#if DEBUG
import SwiftUI

// One placeholder of each model, for Xcode canvas previews only — compiled into debug builds
// and never referenced by app code, so nothing here can appear in the running app.

extension Opportunity {
    static let previewSample = Opportunity(
        id: "preview-job",
        companyName: "Company",
        companySymbol: "building.2.fill",
        roleTitle: "Software Engineer Intern",
        location: "Bengaluru, India",
        opportunityType: .internship,
        workMode: .hybrid,
        salaryRange: "",
        experienceYears: "Freshers",
        eligibleGradYears: "2027",
        matchScore: 88,
        recency: "2h ago",
        cardColor: AlineTheme.cardMint,
        isLiked: false,
        isApplied: false,
        applicationDate: nil,
        externalCareersURL: "https://example.com",
        aboutRole: "Preview text describing the role.",
        minimumQualifications: ["Preview qualification"],
        preferredQualifications: [],
        applicantTips: [],
        responsibilities: ["Preview responsibility"],
        skills: ["Swift", "Python"],
        detectedKeywords: ["Swift"],
        missingKeywords: []
    )
}

extension DiscussionPost {
    static let previewSample = DiscussionPost(
        id: "preview-post",
        type: .interviewExperience,
        authorName: "preview_user",
        companyName: "Company",
        timeAgo: "2h ago",
        title: "Preview discussion title",
        excerpt: "Preview excerpt.",
        fullContent: "Preview discussion body."
    )
}

extension InterviewQuestion {
    static let previewSample = InterviewQuestion(
        id: "preview-question",
        questionText: "Preview interview question?",
        topic: .dsa,
        companyName: "Company",
        role: "Software Engineer",
        difficulty: "General",
        upvotesCount: 1,
        isUpvoted: false,
        isSaved: false,
        hint: nil,
        approach: nil
    )
}
#endif
