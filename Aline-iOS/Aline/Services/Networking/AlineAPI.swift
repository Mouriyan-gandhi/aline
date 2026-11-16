import Foundation

/// Every backend endpoint the app uses, one function each. Responses are wire DTOs
/// (APIModels.swift); view models map them to the frontend's models (ModelMapping.swift).
enum AlineAPI {
    private static var deviceID: String { DeviceIdentity.deviceID }

    // MARK: Jobs

    /// A cold backend live-scrapes every company before answering (several minutes on Render's
    /// free tier after it has spun down), so this gets a long timeout.
    static func jobs() async throws -> [JobDTO] {
        try await APIClient.get("jobs", timeout: 480)
    }

    static func jobMarks() async throws -> [JobMarkDTO] {
        try await APIClient.get("jobs/marks", query: APIClient.deviceQuery())
    }

    static func markJob(_ jobID: String, liked: Bool? = nil, applied: Bool? = nil) async throws {
        let body = JobMarkRequest(deviceId: deviceID, liked: liked, applied: applied)
        let _: EmptyResponse = try await APIClient.send("jobs/\(jobID)/mark", method: "PUT", body: body)
    }

    // MARK: Community

    static func identity() async throws -> IdentityDTO {
        try await APIClient.send("community/identity", method: "POST", body: ["device_id": deviceID])
    }

    static func discussions() async throws -> [DiscussionDTO] {
        try await APIClient.get("community/discussions", query: APIClient.deviceQuery([URLQueryItem(name: "sort", value: "newest")]))
    }

    static func discussion(_ id: String) async throws -> DiscussionDetailDTO {
        try await APIClient.get("community/discussions/\(id)", query: APIClient.deviceQuery())
    }

    static func createDiscussion(category: String, company: String?, title: String, body: String, topics: [String]) async throws -> DiscussionDTO {
        let request = CreateDiscussionRequest(deviceId: deviceID, category: category, company: company, title: title, body: body, topics: topics)
        return try await APIClient.send("community/discussions", method: "POST", body: request)
    }

    static func addComment(discussionID: String, body: String, parentID: String? = nil) async throws -> CommentDTO {
        let request = CreateCommentRequest(deviceId: deviceID, body: body, parentId: parentID)
        return try await APIClient.send("community/discussions/\(discussionID)/comments", method: "POST", body: request)
    }

    static func deleteComment(_ commentID: String) async throws {
        try await APIClient.delete("community/comments/\(commentID)", query: APIClient.deviceQuery())
    }

    static func toggleCommentLike(_ commentID: String) async throws -> Bool {
        let response: LikedResponse = try await APIClient.post("community/comments/\(commentID)/like", query: APIClient.deviceQuery())
        return response.liked
    }

    static func toggleLike(discussionID: String) async throws -> Bool {
        let response: LikedResponse = try await APIClient.post("community/discussions/\(discussionID)/like", query: APIClient.deviceQuery())
        return response.liked
    }

    static func toggleSave(discussionID: String) async throws -> Bool {
        let response: SavedResponse = try await APIClient.post("community/discussions/\(discussionID)/save", query: APIClient.deviceQuery())
        return response.saved
    }

    static func share(discussionID: String) async throws -> Int {
        let response: SharesResponse = try await APIClient.post("community/discussions/\(discussionID)/share")
        return response.sharesCount
    }

    static func companies() async throws -> [CompanyCommunityDTO] {
        try await APIClient.get("community/companies", query: APIClient.deviceQuery())
    }

    static func toggleFollow(company: String) async throws -> Bool {
        let encoded = company.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? company
        let response: FollowingResponse = try await APIClient.post("community/following/\(encoded)", query: APIClient.deviceQuery())
        return response.following
    }

    static func notifications() async throws -> [NotificationDTO] {
        try await APIClient.get("community/notifications", query: APIClient.deviceQuery())
    }

    static func sendFeedback(category: String, message: String) async throws {
        let _: EmptyResponse = try await APIClient.send(
            "feedback", method: "POST", body: FeedbackRequest(deviceId: deviceID, category: category, message: message)
        )
    }

    // MARK: Interview questions

    static func interviewQuestions() async throws -> [InterviewQuestionDTO] {
        try await APIClient.get("interview/questions", query: APIClient.deviceQuery())
    }

    static func createQuestion(_ request: CreateQuestionRequest) async throws -> InterviewQuestionDTO {
        try await APIClient.send("interview/questions", method: "POST", body: request)
    }

    static func toggleUpvote(questionID: String) async throws -> Bool {
        let response: UpvotedResponse = try await APIClient.post("interview/questions/\(questionID)/upvote", query: APIClient.deviceQuery())
        return response.upvoted
    }

    static func toggleSave(questionID: String) async throws -> Bool {
        let response: SavedResponse = try await APIClient.post("interview/questions/\(questionID)/save", query: APIClient.deviceQuery())
        return response.saved
    }

    // MARK: Profile

    static func profile() async throws -> ProfileDTO {
        try await APIClient.get("profile", query: APIClient.deviceQuery())
    }

    @discardableResult
    static func updateProfile(_ request: ProfileUpdateRequest) async throws -> ProfileDTO {
        try await APIClient.send("profile", method: "PUT", body: request)
    }

    static func deleteAccount() async throws {
        try await APIClient.delete("profile", query: APIClient.deviceQuery())
    }

    // MARK: Resumes

    static func resumes() async throws -> [StoredResumeDTO] {
        try await APIClient.get("resumes", query: APIClient.deviceQuery())
    }

    static func saveResume(_ resume: ResumeDocument) async throws {
        let request = SaveResumeRequest(deviceId: deviceID, data: ResumeRecord(resume))
        let _: EmptyResponse = try await APIClient.send("resumes/\(resume.id)", method: "PUT", body: request)
    }

    static func deleteResume(_ id: String) async throws {
        try await APIClient.delete("resumes/\(id)", query: APIClient.deviceQuery())
    }
}
