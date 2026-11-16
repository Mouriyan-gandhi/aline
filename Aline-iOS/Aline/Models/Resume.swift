import SwiftUI

// MARK: - Resume & AI Tailoring Models (Section 6 of Product Guide)
public struct ResumeDocument: Identifiable, Hashable {
    public let id: String
    public var title: String
    public var fileName: String
    public var uploadDate: String
    public var lastModifiedDate: String
    public var fileSize: String
    public var isDefault: Bool
    public var selectedTemplate: ResumeTemplate
    public var cardColor: Color
    public var targetCompany: String?
    public var targetCompanySymbol: String?
    public var matchScore: Int?
    public var optimizationCount: Int
    public var summary: String
    public var experiences: [ResumeExperience]
    public var projects: [ResumeProject]
    public var skills: [String]
    public var education: [ResumeEducation]
    public var achievements: [String]
    /// Sections printed on page 2; nil for single-page resumes
    public var secondPageSections: Set<ResumeSection>? = nil
    /// "Label: values" skill rows; nil keeps the template's default skills block
    public var skillLines: [ResumeSkillLine]? = nil
    /// Shown as a Soft Skills section when present
    public var softSkills: [String]? = nil

    /// Sections on each printed page, in order; [nil] means one page with everything
    public var pageSections: [Set<ResumeSection>?] {
        guard let second = secondPageSections, !second.isEmpty else { return [nil] }
        return [Set(ResumeSection.allCases).subtracting(second), second]
    }

    public enum ResumeTemplate: String, CaseIterable, Codable {
        case standard = "Standard"
        case professional = "Professional"
        case modern = "Modern"

        public var description: String {
            switch self {
            case .standard: return "Clean and straightforward; general applications."
            case .professional: return "Structured and polished; corporate and tech roles."
            case .modern: return "Minimal and contemporary; tech and creative roles."
            }
        }
    }
}

/// Blocks of a resume that can be placed on a page
public enum ResumeSection: String, CaseIterable, Hashable, Sendable {
    case header, summary, education, experience, projects, achievements, skills, softSkills
}

public struct ResumeSkillLine: Hashable, Sendable {
    public var label: String
    public var values: String
    public init(_ label: String, _ values: String) {
        self.label = label
        self.values = values
    }
}

public struct ResumeEducation: Identifiable, Hashable {
    public let id: String
    public var institution: String
    public var degree: String
    public var period: String
    public var location: String
    public var details: String
}

public struct ResumeExperience: Identifiable, Hashable {
    public let id: String
    public var company: String
    public var role: String
    public var period: String
    public var location: String
    public var bullets: [String]
}

public struct ResumeProject: Identifiable, Hashable {
    public let id: String
    public var title: String
    public var techStack: String
    public var bullets: [String]
}

public struct AISuggestion: Identifiable, Hashable {
    public let id: String
    public let targetSection: String
    public let originalText: String
    public let suggestedText: String
    public let reason: String
    public let includesPlaceholders: Bool
    public var isApplied: Bool
}

public struct AIChatMessage: Identifiable, Hashable {
    public let id: String
    public let sender: Sender
    public let text: String
    public let timestamp: String
    public var targetKey: String? // e.g. "proj-0-bullet-0"
    public var originalText: String?
    public var suggestedRewrite: String?
    public var reason: String?
    public var isApplied: Bool

    public enum Sender: String, Hashable {
        case user
        case ai
        case system
    }

    public init(
        id: String = UUID().uuidString,
        sender: Sender,
        text: String,
        timestamp: String = "Just now",
        targetKey: String? = nil,
        originalText: String? = nil,
        suggestedRewrite: String? = nil,
        reason: String? = nil,
        isApplied: Bool = false
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
        self.targetKey = targetKey
        self.originalText = originalText
        self.suggestedRewrite = suggestedRewrite
        self.reason = reason
        self.isApplied = isApplied
    }
}

// MARK: - Aarav Sharma's full resume data (based on real content)
private let aaravEducation: [ResumeEducation] = [
    ResumeEducation(
        id: "edu-1",
        institution: "SRM Institute of Science and Technology",
        degree: "B.Tech in Computer Science (AI & ML)",
        period: "2024 – 2028",
        location: "Chennai",
        details: "Coursework: Data Structures, OOP, DBMS, Operating Systems, Machine Learning, Artificial Intelligence · CGPA: 9.77/10"
    ),
    ResumeEducation(
        id: "edu-2",
        institution: "Chinmaya Vidyalaya",
        degree: "CBSE XII",
        period: "",
        location: "Chennai",
        details: "94% · X – 95.6%"
    )
]

private let aaravExperiences: [ResumeExperience] = [
    ResumeExperience(
        id: "exp-1",
        company: "Tagros Chemicals India Pvt. Ltd.",
        role: "AI/ML Intern",
        period: "Jun 2026 — Chennai, Onsite",
        location: "Chennai, Onsite",
        bullets: [
            "Designed and deployed to production a cross-platform desktop IT support assistant (React, Electron, FastAPI, SQLite); implemented unit-tested ticket-escalation logic and ensured 100% on-device data processing for reliability and privacy.",
            "Built a QR code validation pipeline (Python, Pandas, Selenium) to process Excel-based product data at scale; collaborated with operations stakeholders to replace manual workflows and eliminate data-entry errors across the product team."
        ]
    ),
    ResumeExperience(
        id: "exp-2",
        company: "EduSkill – Google AI-ML Virtual Program",
        role: "AI/ML Intern",
        period: "Jan 2026 – Mar 2026",
        location: "Virtual",
        bullets: [
            "Built a visual product search engine applying object detection and image classification; achieved 80%+ retrieval accuracy across 1,000+ SKUs by independently researching and evaluating model architectures."
        ]
    ),
    ResumeExperience(
        id: "exp-3",
        company: "Apple & Infosys Student Developer Program",
        role: "iOS Student Developer",
        period: "Jul 2026 – Present",
        location: "",
        bullets: [
            "Undergoing structured training in Swift and SwiftUI for native iOS development; applying knowledge by building hands-on projects and navigating new frameworks and codebases independently."
        ]
    )
]

private let aaravProjects: [ResumeProject] = [
    ResumeProject(
        id: "proj-1",
        title: "IT Helpdesk Chatbot",
        techStack: "FastAPI, React, Electron, SQLite, SQLAlchemy, Ollama, RAG",
        bullets: [
            "Designed and developed a backend system using FastAPI and SQLite to manage ticket data, incorporating unit testing to validate core ticket-escalation logic and ensure reliable software.",
            "Implemented RAG-based troubleshooting over a 170+ entry FAQ knowledge base using Ollama for private, on-device AI processing, with an admin dashboard for ticket analytics."
        ]
    ),
    ResumeProject(
        id: "proj-2",
        title: "LabBuddy",
        techStack: "Flutter, Firebase, Google OAuth, QR Code API · Team of 4",
        bullets: [
            "Built a cross-platform mobile app for lab booking and attendance with a three-role access system; collaborated via GitHub PRs and design discussions across a 4-person team.",
            "Integrated QR-based attendance and Google OAuth restricted to institutional credentials for secure, role-based access."
        ]
    ),
    ResumeProject(
        id: "proj-3",
        title: "QR Link – Arqivo",
        techStack: "Python, Pandas, Flask, Selenium · Tagros Chemicals",
        bullets: [
            "Automated Excel-based product data ingestion to generate unique verification QR links at scale; built a web dashboard preventing duplicate generation across the product team."
        ]
    ),
    ResumeProject(
        id: "proj-4",
        title: "EduChain",
        techStack: "Hyperledger Fabric, SHA-256 · Team project",
        bullets: [
            "Built a credential verification system on Hyperledger Fabric with SHA-256 hashing; pitched to judges and stakeholders at a competitive ideathon, winning first place.",
            "Designed a skill-analysis engine evaluating GitHub portfolios to generate career roadmaps, reducing HR screening time by 50% across 3 pilot companies."
        ]
    ),
    ResumeProject(
        id: "proj-5",
        title: "Quantum Quest",
        techStack: "Python, FastAPI, Qiskit, MediaPipe, AR/VR, React",
        bullets: [
            "Constructed an interactive quantum computing platform using Qiskit and FastAPI for real-time circuit simulation and visualization, featuring a gamified drag-and-drop circuit builder with multi-qubit support and 3D Bloch sphere visualization.",
            "Integrated gesture-based controls (MediaPipe) and AR/VR modules for immersive quantum exploration.",
            "Simulated core quantum workflows including Bell State, Quantum Teleportation, Grover’s Algorithm, and Quantum Fourier Transform."
        ]
    )
]

private let aaravSkills: [String] = [
    "Python", "Java", "JavaScript", "C", "Swift",
    "FastAPI", "Flask", "REST APIs", "SQL", "SQLAlchemy", "SQLite", "MySQL", "MongoDB", "Firebase",
    "React", "Electron", "Flutter", "HTML", "CSS",
    "Data Structures & Algorithms", "OOP", "Unit Testing", "Code Review", "Git/GitHub",
    "Supervised Learning", "NLP", "Computer Vision", "RAG", "Local LLMs", "Model Deployment", "Ollama",
    "Selenium", "Figma", "AI-assisted Development (Copilot / LLM tooling)"
]

private let aaravAchievements: [String] = [
    "Selected Participant – JPMorgan Chase Code for Good 2026, Bangalore (15,000+ applicants)",
    "Winner – Pitch Perfect Ideathon, Horizon 2025 (EduChain)",
    "6th Place – Track 4 – QTHack04 – Visual Simulation Hackathon on Classical & Quantum Technology",
    "Top 50 / 800+ Teams – Smart India Hackathon Internal Round, SRM 2025",
    "Participant – PALS InnoWAH 2026 Cluster Finals (IIT Alumni) · Guidewire Hackathon",
    "Certification – HTML & CSS In-Depth, Meta (Coursera) · Java (Basic), HackerRank"
]

public extension ResumeDocument {
    static let samples: [ResumeDocument] = [
        ResumeDocument(
            id: "res-google",
            title: "Google SDE Tailored",
            fileName: "Google_SDE_Tailored.pdf",
            uploadDate: "Just now",
            lastModifiedDate: "Modified 5m ago",
            fileSize: "296 KB",
            isDefault: false,
            selectedTemplate: .standard,
            cardColor: AlineTheme.cardYellow,
            targetCompany: "Google",
            targetCompanySymbol: "g.circle.fill",
            matchScore: 88,
            optimizationCount: 3,
            summary: "Computer Science undergraduate (Class of 2028) with strong foundations in data structures, algorithms, object-oriented design, and mobile app architecture. Experienced in building production-grade AI/ML and full-stack applications.",
            experiences: aaravExperiences,
            projects: aaravProjects,
            skills: aaravSkills,
            education: aaravEducation,
            achievements: aaravAchievements
        ),
        ResumeDocument(
            id: "res-apple",
            title: "Apple iOS Specialist",
            fileName: "Apple_iOS_Tailored.pdf",
            uploadDate: "Yesterday",
            lastModifiedDate: "Modified 2h ago",
            fileSize: "278 KB",
            isDefault: false,
            selectedTemplate: .modern,
            cardColor: AlineTheme.cardPeach,
            targetCompany: "Apple",
            targetCompanySymbol: "apple.logo",
            matchScore: 92,
            optimizationCount: 2,
            summary: "Computer Science undergraduate (Class of 2028) with strong foundations in data structures, algorithms, object-oriented design, and mobile app architecture. Experienced in building production-grade AI/ML and full-stack applications.",
            experiences: aaravExperiences,
            projects: aaravProjects,
            skills: aaravSkills,
            education: aaravEducation,
            achievements: aaravAchievements
        ),
        ResumeDocument(
            id: "res-default",
            title: "Master Tech Resume",
            fileName: "Master_Aarav_Resume.pdf",
            uploadDate: "12 Oct 2026",
            lastModifiedDate: "1 day ago",
            fileSize: "284 KB",
            isDefault: true,
            selectedTemplate: .standard,
            cardColor: AlineTheme.cardMint,
            targetCompany: "General Roles",
            targetCompanySymbol: "briefcase.fill",
            matchScore: 95,
            optimizationCount: 1,
            summary: "Computer Science undergraduate (Class of 2028) with strong foundations in data structures, algorithms, object-oriented design, and mobile app architecture. Experienced in building production-grade AI/ML and full-stack applications.",
            experiences: aaravExperiences,
            projects: aaravProjects,
            skills: aaravSkills,
            education: aaravEducation,
            achievements: aaravAchievements
        ),
        ResumeDocument(
            id: "res-barclays",
            title: "Barclays Enterprise",
            fileName: "Barclays_Enterprise_Resume.pdf",
            uploadDate: "20 Sep 2026",
            lastModifiedDate: "3 days ago",
            fileSize: "312 KB",
            isDefault: false,
            selectedTemplate: .professional,
            cardColor: AlineTheme.cardLavender,
            targetCompany: "Barclays",
            targetCompanySymbol: "building.columns.fill",
            matchScore: 84,
            optimizationCount: 0,
            summary: "Computer Science undergraduate (Class of 2028) with strong foundations in data structures, algorithms, object-oriented design, and mobile app architecture. Experienced in building production-grade AI/ML and full-stack applications.",
            experiences: aaravExperiences,
            projects: aaravProjects,
            skills: aaravSkills,
            education: aaravEducation,
            achievements: aaravAchievements
        ),
        // Two-page sample: only this resume prints on two A4 pages
        twoPageSample
    ]
}

// MARK: - Two-Page Sample (summary, experience and projects on page 1; achievements and skills on page 2)
private let twoPageExperiences: [ResumeExperience] = [
    ResumeExperience(
        id: "tp-exp-tagros",
        company: "Tagros Chemicals India Pvt. Ltd.",
        role: "AI/ML Intern",
        period: "Jun 2026",
        location: "Chennai, Onsite",
        bullets: [
            "Engineered an automated QR code pipeline (Python, Pandas, Selenium) to validate and process Excel-based product data, replacing a fully manual workflow and reducing data-entry errors.",
            "Built and deployed a fully offline IT Helpdesk AI Assistant powered by a local LLM (Ollama) as a cross-platform desktop app (React, Electron, FastAPI, SQLite), ensuring 100% on-device privacy and reliable support for IT staff."
        ]
    ),
    ResumeExperience(
        id: "tp-exp-eduskill",
        company: "EduSkill (Google AI-ML Virtual Program)",
        role: "AI/ML Intern",
        period: "Jan 2026 – Mar 2026",
        location: "Virtual",
        bullets: [
            "Built a visual product search engine using object detection and image classification, achieving 80%+ retrieval accuracy across a catalog of 1,000+ SKUs.",
            "Completed 40+ hours of structured AI/ML curriculum, earning AICTE EduSkill certification."
        ]
    )
]

private let twoPageProjects: [ResumeProject] = [
    ResumeProject(
        id: "tp-proj-educhain",
        title: "EduChain",
        techStack: "Hyperledger Fabric, Python, SHA-256, AI/ML, Web Development",
        bullets: [
            "Established a credential verification system on Hyperledger Fabric using SHA-256 hashing, eliminating fraudulent credential claims in testing.",
            "Architected a skill-analysis engine that evaluates GitHub portfolios and generates personalized career roadmaps, reducing manual HR screening time by an estimated 50%.",
            "Delivered employer-facing dashboards for verified candidate profiles, supporting faster hiring decisions for 3 pilot companies."
        ]
    ),
    ResumeProject(
        id: "tp-proj-quantum",
        title: "Quantum Quest",
        techStack: "Python, FastAPI, Qiskit, MediaPipe, AR/VR, React",
        bullets: [
            "Constructed an interactive quantum computing platform using Qiskit and FastAPI for real-time circuit simulation and visualization, featuring a gamified drag-and-drop circuit builder with multi-qubit support and 3D Bloch sphere visualization.",
            "Integrated gesture-based controls (MediaPipe) and AR/VR modules for immersive quantum exploration.",
            "Simulated core quantum workflows including Bell State, Quantum Teleportation, Grover’s Algorithm, and Quantum Fourier Transform."
        ]
    ),
    ResumeProject(
        id: "tp-proj-multiagent",
        title: "Intelligent Multi-Agent System for Unauthorized Data Transfer Detection",
        techStack: "Python, Agentic AI, Post-Quantum Cryptography · Ongoing",
        bullets: [
            "Developing a multi-agent AI system to monitor network activity and detect unauthorized data transfers in real time.",
            "Designing specialized agents to analyze system logs and traffic, identifying anomalous file transfer patterns across distributed systems.",
            "Applying Post-Quantum Cryptography to future-proof the monitoring pipeline against emerging security risks."
        ]
    ),
    ResumeProject(
        id: "tp-proj-labbuddy",
        title: "LabBuddy",
        techStack: "Flutter, Firebase, Google OAuth, QR Code API, Figma · Team of 4",
        bullets: [
            "Launched a mobile application to digitize lab access, slot booking, and attendance management across engineering labs, implementing a three-role system (students, admins, wardens) with role-based dashboards.",
            "Configured QR-based attendance with session tracking, custom duration booking, and admin-controlled exit approvals, plus real-time notifications.",
            "Secured access via Google OAuth restricted to institutional credentials."
        ]
    )
]

private let twoPageAchievements: [String] = [
    "Winner – Pitch Perfect Ideathon, Horizon 2025 (EduChain)",
    "6th Place, Track 4 (Quantum Systems) – QTHack04, University-level Hackathon (Quantum Quest)",
    "Top 50 out of 800+ Teams – Smart India Hackathon (Internal Round), SRM 2025",
    "Participant – PALS InnoWAH 2026 Cluster Finals, SRMIST (IIT Alumni Initiative)",
    "Participant – Guidewire Hackathon (Gig Workers’ Insurance Platform)",
    "Certification – HTML & CSS In-Depth, Meta (Coursera)",
    "Certification – Java (Basic), HackerRank"
]

private let twoPageSkillLines: [ResumeSkillLine] = [
    ResumeSkillLine("Programming Languages", "Python, Java, C++, C"),
    ResumeSkillLine("Web Technologies", "HTML, CSS, JavaScript"),
    ResumeSkillLine("Frameworks & Libraries", "React, Electron, FastAPI, NumPy, Pandas, Scikit-learn"),
    ResumeSkillLine("Databases", "MySQL, SQLite, Firebase, MongoDB"),
    ResumeSkillLine("AI & Machine Learning", "Supervised Learning, NLP, Computer Vision, Multi-Agent Systems, Model Deployment, Local LLMs"),
    ResumeSkillLine("Blockchain & Cryptography", "Hyperledger Fabric, SHA-256 Hashing, Post-Quantum Cryptography (applied)"),
    ResumeSkillLine("Tools & Platforms", "Git, GitHub, VS Code, Figma, Flutter, Selenium, OpenPyXL")
]

public extension ResumeDocument {
    /// Two-page resume (from a sample PDF): page 1 has summary, education, experience and projects;
    /// page 2 has achievements, technical skills and soft skills
    static let twoPageSample = ResumeDocument(
        id: "res-two-page",
        title: "Aarav Sharma",
        fileName: "Aarav_Sharma_Resume.pdf",
        uploadDate: "Today",
        lastModifiedDate: "Just now",
        fileSize: "97 KB",
        isDefault: false,
        selectedTemplate: .standard,
        cardColor: AlineTheme.cardSkyBlue,
        targetCompany: nil,
        targetCompanySymbol: nil,
        matchScore: nil,
        optimizationCount: 0,
        summary: "Third-year B.Tech Computer Science undergraduate specializing in Artificial Intelligence and Machine Learning at SRM Institute of Science and Technology, with a CGPA of 9.77/10. Experienced in translating stakeholder requirements into deployed technical solutions across AI/ML, full-stack, and systems projects, with exposure to cross-functional teamwork, risk identification, and end-to-end delivery from pilot to production-ready outcomes. Strong foundation in problem-solving, communication, and cross-team collaboration to align technical execution with business goals.",
        experiences: twoPageExperiences,
        projects: twoPageProjects,
        skills: twoPageSkillLines.flatMap { $0.values.components(separatedBy: ", ") },
        education: [],
        achievements: twoPageAchievements,
        secondPageSections: [.achievements, .skills, .softSkills],
        skillLines: twoPageSkillLines,
        softSkills: ["Problem Solving", "Communication", "Team Collaboration", "Time Management", "Leadership", "Event Management"]
    )
}
