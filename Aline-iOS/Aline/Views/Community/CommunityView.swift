import SwiftUI

// MARK: - Community & Interview Prep View (Sections 8 & 9 of Product Guide)
public struct CommunityView: View {
    @ObservedObject public var communityViewModel: CommunityViewModel
    @ObservedObject public var prepViewModel: InterviewPrepViewModel
    @State private var selectedSegment: CommunitySegment = .discussions
    @State private var selectedPost: DiscussionPost? = nil
    @State private var selectedQuestion: InterviewQuestion? = nil

    public enum CommunitySegment: String, CaseIterable {
        case discussions = "Discussions"
        case interviewQuestions = "Interview Prep"
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color(AlineTheme.canvasBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header & Segmented Pill Switcher
                VStack(spacing: 14) {
                    HStack {
                        Text(selectedSegment == .discussions ? "Community" : "Interview Hub")
                            .font(.alineTitleLarge)
                            .foregroundColor(AlineTheme.inkPrimary)
                        Spacer()

                        Button {
                            if selectedSegment == .discussions {
                                communityViewModel.showCreatePostSheet = true
                            } else {
                                prepViewModel.showContributeSheet = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(AlineTheme.pillDark)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Segment Switcher (Discussions vs Interview Prep)
                    HStack(spacing: 8) {
                        ForEach(CommunitySegment.allCases, id: \.self) { segment in
                            let isSelected = selectedSegment == segment
                            Button {
                                withAnimation(AlineTheme.fastSpring) {
                                    selectedSegment = segment
                                }
                            } label: {
                                Text(segment.rawValue)
                                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? AlineTheme.pillDark : Color.white)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 12)

                // Body content based on active segment
                ScrollView(.vertical, showsIndicators: false) {
                    if selectedSegment == .discussions {
                        discussionsContent
                    } else {
                        interviewPrepContent
                    }
                }
            }
        }
        .sheet(item: $selectedPost) { post in
            DiscussionDetailView(post: post, viewModel: communityViewModel)
        }
        .sheet(item: $selectedQuestion) { question in
            InterviewQuestionDetailView(question: question, viewModel: prepViewModel)
        }
        .sheet(isPresented: $communityViewModel.showCreatePostSheet) {
            CreateDiscussionPostView(viewModel: communityViewModel)
        }
        .sheet(isPresented: $prepViewModel.showContributeSheet) {
            ContributeQuestionModalView(viewModel: prepViewModel)
        }
    }

    // MARK: - Discussions Feed Section
    @ViewBuilder
    private var discussionsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Category Chips (Interview Exp, Work Exp, etc.)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        communityViewModel.selectedCategory = nil
                    } label: {
                        Text("All Discussions")
                            .font(.system(size: 13, weight: communityViewModel.selectedCategory == nil ? .bold : .medium))
                            .foregroundColor(communityViewModel.selectedCategory == nil ? .white : AlineTheme.inkPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(communityViewModel.selectedCategory == nil ? AlineTheme.pillDark : Color.white))
                    }

                    ForEach(DiscussionType.allCases, id: \.self) { type in
                        let isSelected = communityViewModel.selectedCategory == type
                        Button {
                            communityViewModel.selectedCategory = isSelected ? nil : type
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: type.iconName)
                                    .font(.system(size: 11))
                                Text(type.rawValue)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            }
                            .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(isSelected ? AlineTheme.pillDark : Color.white))
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Discussions List
            VStack(spacing: 14) {
                ForEach(communityViewModel.filteredPosts) { post in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(post.type.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AlineTheme.inkSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.05))
                                .clipShape(Capsule())

                            if let company = post.companyName {
                                Text("• \(company)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                            }

                            Spacer()

                            Text(post.timeAgo)
                                .font(.system(size: 11))
                                .foregroundColor(AlineTheme.inkMuted)
                        }

                        Text(post.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Text(post.excerpt)
                            .font(.system(size: 13))
                            .foregroundColor(AlineTheme.inkSecondary)
                            .lineLimit(2)

                        HStack {
                            Button {
                                communityViewModel.toggleLike(for: post.id)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                        .foregroundColor(post.isLiked ? AlineTheme.accentHeart : AlineTheme.inkSecondary)
                                    Text("\(post.likesCount)")
                                }
                                .font(.system(size: 12, weight: .semibold))
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "bubble.right")
                                Text("\(post.comments.count) Comments")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AlineTheme.inkSecondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPost = post
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 120)
        }
    }

    // MARK: - Interview Prep Section
    @ViewBuilder
    private var interviewPrepContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Topics Grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        prepViewModel.selectedTopic = nil
                    } label: {
                        Text("All Topics")
                            .font(.system(size: 13, weight: prepViewModel.selectedTopic == nil ? .bold : .medium))
                            .foregroundColor(prepViewModel.selectedTopic == nil ? .white : AlineTheme.inkPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(prepViewModel.selectedTopic == nil ? AlineTheme.pillDark : Color.white))
                    }

                    ForEach(QuestionTopic.allCases, id: \.self) { topic in
                        let isSelected = prepViewModel.selectedTopic == topic
                        Button {
                            prepViewModel.selectedTopic = isSelected ? nil : topic
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: topic.iconName)
                                    .font(.system(size: 11))
                                Text(topic.rawValue)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            }
                            .foregroundColor(isSelected ? .white : AlineTheme.inkPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(isSelected ? AlineTheme.pillDark : Color.white))
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Questions List
            VStack(spacing: 12) {
                ForEach(prepViewModel.filteredQuestions) { q in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            if let comp = q.companyName {
                                Text(comp)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AlineTheme.inkPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AlineTheme.cardYellow.opacity(0.8))
                                    .clipShape(Capsule())
                            }

                            Text(q.topic.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AlineTheme.inkSecondary)

                            Spacer()

                            Button {
                                prepViewModel.toggleUpvote(for: q.id)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up")
                                    Text("\(q.upvotesCount)")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(q.isUpvoted ? AlineTheme.accentEmerald : AlineTheme.inkSecondary)
                            }
                        }

                        Text(q.questionText)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineSpacing(2)

                        HStack {
                            Text("Tap to reveal Hint & Approach")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AlineTheme.inkSecondary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AlineTheme.inkMuted)
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedQuestion = q
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 120)
        }
    }
}

// MARK: - Discussion Detail View
public struct DiscussionDetailView: View {
    public let post: DiscussionPost
    @ObservedObject public var viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newCommentText: String = ""

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(AlineTheme.canvasBackground).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Author header
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(AlineTheme.cardPeach)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "person.fill")
                                    .foregroundColor(AlineTheme.inkPrimary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(post.authorName)
                                    .font(.system(size: 15, weight: .bold))
                                Text("\(post.role ?? "Member") • \(post.timeAgo)")
                                    .font(.system(size: 12))
                                    .foregroundColor(AlineTheme.inkSecondary)
                            }
                            Spacer()
                        }

                        Text(post.title)
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(AlineTheme.inkPrimary)

                        Text(post.fullContent)
                            .font(.system(size: 15))
                            .foregroundColor(AlineTheme.inkPrimary)
                            .lineSpacing(4)

                        Divider().padding(.vertical, 8)

                        // Comments Section
                        Text("Comments (\(post.comments.count))")
                            .font(.system(size: 16, weight: .bold))

                        ForEach(post.comments) { comment in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(comment.authorName)
                                        .font(.system(size: 13, weight: .bold))
                                    Text("• \(comment.timeAgo)")
                                        .font(.system(size: 11))
                                        .foregroundColor(AlineTheme.inkSecondary)
                                    Spacer()
                                }
                                Text(comment.text)
                                    .font(.system(size: 13))
                                    .foregroundColor(AlineTheme.inkPrimary)
                            }
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Spacer(minLength: 90)
                    }
                    .padding(20)
                }

                // Comment Composer Bar
                HStack(spacing: 10) {
                    TextField("Add a question or comment...", text: $newCommentText)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(Capsule())

                    Button {
                        viewModel.addComment(to: post.id, text: newCommentText)
                        newCommentText = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(AlineTheme.pillDark)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .navigationTitle("Discussion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Interview Question Detail View (STAR & Algorithmic Reveal)
public struct InterviewQuestionDetailView: View {
    public let question: InterviewQuestion
    @ObservedObject public var viewModel: InterviewPrepViewModel
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Category & Company Header
                    HStack {
                        if let comp = question.companyName {
                            Text(comp)
                                .font(.system(size: 13, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AlineTheme.cardYellow)
                                .clipShape(Capsule())
                        }
                        Text(question.topic.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AlineTheme.inkSecondary)
                        Spacer()
                    }

                    Text(question.questionText)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(AlineTheme.inkPrimary)
                        .lineSpacing(3)

                    // Reveal Hint Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(AlineTheme.accentAmber)
                            Text("Interview Hint")
                                .font(.system(size: 15, weight: .bold))
                            Spacer()

                            if !viewModel.revealedHints.contains(question.id) {
                                Button("Reveal Hint") {
                                    withAnimation(AlineTheme.fastSpring) {
                                        viewModel.revealHint(for: question.id)
                                    }
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AlineTheme.pillDark)
                            }
                        }

                        if viewModel.revealedHints.contains(question.id) {
                            Text(question.hint)
                                .font(.system(size: 14))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .lineSpacing(3)
                        } else {
                            Text("Think independently first. Tap Reveal Hint for a small nudge without spoiling the complete solution.")
                                .font(.system(size: 12))
                                .foregroundColor(AlineTheme.inkSecondary)
                        }
                    }
                    .padding(18)
                    .background(AlineTheme.cardYellow.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // Reveal Approach Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(AlineTheme.pillDark)
                            Text("Recommended Approach & Framework")
                                .font(.system(size: 15, weight: .bold))
                            Spacer()

                            if !viewModel.revealedApproaches.contains(question.id) {
                                Button("Show Approach") {
                                    withAnimation(AlineTheme.fastSpring) {
                                        viewModel.revealApproach(for: question.id)
                                    }
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AlineTheme.pillDark)
                            }
                        }

                        if viewModel.revealedApproaches.contains(question.id) {
                            Text(question.approach)
                                .font(.system(size: 14))
                                .foregroundColor(AlineTheme.inkPrimary)
                                .lineSpacing(4)

                            if let tc = question.timeComplexity {
                                HStack(spacing: 12) {
                                    Text("Time: \(tc)").font(.system(size: 12, weight: .bold))
                                    if let sc = question.spaceComplexity {
                                        Text("Space: \(sc)").font(.system(size: 12, weight: .bold))
                                    }
                                }
                                .padding(.top, 4)
                                .foregroundColor(AlineTheme.inkSecondary)
                            }
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle("Question Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Create Discussion Post View
public struct CreateDiscussionPostView: View {
    @ObservedObject public var viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var type: DiscussionType = .interviewExperience
    @State private var company: String = "Google"

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Type")) {
                    Picker("Category", selection: $type) {
                        ForEach(DiscussionType.allCases, id: \.self) { Text($0.rawValue) }
                    }
                }
                Section(header: Text("Company")) {
                    TextField("Company Name", text: $company)
                }
                Section(header: Text("Title")) {
                    TextField("E.g. SDE Intern Interview Loop", text: $title)
                }
                Section(header: Text("Experience / Content")) {
                    TextField("Share your experience constructively...", text: $content, axis: .vertical)
                        .lineLimit(5...8)
                }
            }
            .navigationTitle("Share Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publish") {
                        let newPost = DiscussionPost(
                            id: UUID().uuidString,
                            type: type,
                            authorName: "You (Anonymous)",
                            isAnonymous: true,
                            companyName: company,
                            role: "Applicant",
                            timeAgo: "Just now",
                            title: title.isEmpty ? "My Interview Experience" : title,
                            excerpt: content,
                            fullContent: content,
                            topics: [company, type.rawValue],
                            likesCount: 0,
                            isLiked: false,
                            isSaved: false,
                            comments: []
                        )
                        viewModel.posts.insert(newPost, at: 0)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Contribute Question Modal
public struct ContributeQuestionModalView: View {
    @ObservedObject public var viewModel: InterviewPrepViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var questionText: String = ""
    @State private var topic: QuestionTopic = .dsa
    @State private var company: String = "Google"

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Question (Max 100 words)")) {
                    TextField("Enter interview question...", text: $questionText, axis: .vertical)
                        .lineLimit(3...5)
                }
                Section(header: Text("Topic")) {
                    Picker("Topic", selection: $topic) {
                        ForEach(QuestionTopic.allCases, id: \.self) { Text($0.rawValue) }
                    }
                }
                Section(header: Text("Company")) {
                    TextField("Company Name", text: $company)
                }
            }
            .navigationTitle("Contribute Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit for Review") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Community Hub Canvas") {
    CommunityView(
        communityViewModel: CommunityViewModel(),
        prepViewModel: InterviewPrepViewModel()
    )
}

#Preview("Discussion Post Detail") {
    let communityVM = CommunityViewModel()
    let post = communityVM.posts.first ?? DiscussionPost.samples.first!
    return DiscussionDetailView(post: post, viewModel: communityVM)
}

#Preview("Interview Question Detail") {
    let prepVM = InterviewPrepViewModel()
    let q = prepVM.questions.first ?? InterviewQuestion.samples.first!
    return InterviewQuestionDetailView(question: q, viewModel: prepVM)
}

