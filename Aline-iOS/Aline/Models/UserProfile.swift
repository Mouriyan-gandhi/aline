import SwiftUI

// MARK: - User Profile, Career Preferences & Achievement Gallery (Sections 10, 11, 12)
public struct UserProfile: Hashable, Codable {
    public var name: String
    /// Auto-assigned anonymous community handle. Read-only for the user.
    public let username: String
    public var titleOrStage: String
    public var education: String
    public var institution: String
    public var graduationYear: String
    public var location: String
    public var bio: String
    public var skills: [String]
    
    // Links
    public var linkedInURL: String
    public var githubURL: String
    public var portfolioURL: String

    // Work Experience & Projects
    public var experiences: [UserExperience]
    public var projects: [UserProject]
}

public struct UserExperience: Identifiable, Hashable, Codable {
    public let id: String
    public var title: String
    public var company: String
    public var location: String
    public var period: String
    public var bullets: [String]
}

public struct UserProject: Identifiable, Hashable, Codable {
    public let id: String
    public var title: String
    public var period: String
    public var techStack: String
    public var bullets: [String]
}

public struct CareerPreferences: Hashable, Codable {
    public var preferredRoles: [String]
    public var preferredCompanies: [String]
    public var preferredLocations: [String]
    public var isOpenToAnyLocation: Bool
    public var opportunityTypes: [Opportunity.OpportunityType]
    public var workArrangements: [Opportunity.WorkMode]
    public var experienceLevel: String
    public var alertsEnabled: Bool
    public var isPushAllowedByOS: Bool
}

public enum AchievementCategory: String, CaseIterable, Codable {
    case certificates = "Certificates"
    case hackathons = "Hackathons"
    case awards = "Awards"
    case internships = "Internships"
    case courses = "Courses"
    case other = "Other"

    public var iconName: String {
        switch self {
        case .certificates: return "seal.fill"
        case .hackathons: return "trophy.fill"
        case .awards: return "star.fill"
        case .internships: return "briefcase.fill"
        case .courses: return "book.closed.fill"
        case .other: return "sparkles"
        }
    }
}

public struct AchievementItem: Identifiable, Hashable, Codable {
    public let id: String
    public var title: String
    public var issuer: String
    public var category: AchievementCategory
    public var dateEarned: String
    public var descriptionText: String
    public var credentialURL: String?
    public var attachmentName: String?
}

public extension UserProfile {
    static let sample = UserProfile(
        name: "Aarav Sharma",
        username: "quiet_falcon_4821",
        titleOrStage: "3rd Year CS (AI & ML) · CGPA 9.77",
        education: "B.Tech in Computer Science & Engineering (AI & ML)",
        institution: "SRM Institute of Science and Technology",
        graduationYear: "2028",
        location: "Chennai, India",
        bio: "Third-year B.Tech Computer Science undergraduate specializing in Artificial Intelligence and Machine Learning at SRM Institute of Science and Technology, with a CGPA of 9.77/10. Experienced in translating stakeholder requirements into deployed technical solutions across AI/ML, full-stack, and systems projects.",
        skills: [
            "Python", "Java", "Swift", "SwiftUI", "C++", "C", "FastAPI", "React", "Electron", "Flutter",
            "SQLite", "Firebase", "MySQL", "MongoDB", "Data Structures", "Algorithms",
            "Machine Learning", "NLP", "Computer Vision", "RAG", "Local LLMs", "Selenium", "Git", "Figma"
        ],
        linkedInURL: "linkedin.com/in/aarav-cs",
        githubURL: "github.com/aarav-dev",
        portfolioURL: "aarav.dev",
        // Oldest first: the newest entry is the last one, and the profile shows it on top
        experiences: [
            UserExperience(
                id: "exp-eduskill",
                title: "AI/ML Intern",
                company: "EduSkill (Google AI-ML Virtual Program)",
                location: "Virtual",
                period: "Jan 2026 – Mar 2026",
                bullets: [
                    "Built a visual product search engine using object detection and image classification, achieving 80%+ retrieval accuracy across 1,000+ SKUs.",
                    "Completed 40+ hours of structured AI/ML curriculum, earning AICTE EduSkill certification."
                ]
            ),
            UserExperience(
                id: "exp-tagros",
                title: "AI/ML Intern",
                company: "Tagros Chemicals India Pvt. Ltd.",
                location: "Chennai, Onsite",
                period: "Jun 2026",
                bullets: [
                    "Designed and deployed to production a cross-platform desktop IT support assistant (React, Electron, FastAPI, SQLite); implemented unit-tested ticket-escalation logic and ensured 100% on-device data processing for reliability and privacy.",
                    "Built an automated QR code validation pipeline (Python, Pandas, Selenium) to process Excel-based product data at scale, replacing manual workflows and eliminating data-entry errors."
                ]
            ),
            UserExperience(
                id: "exp-apple-infosys",
                title: "iOS Student Developer",
                company: "Apple & Infosys Student Developer Program",
                location: "Bengaluru, India",
                period: "Jul 2026 – Present",
                bullets: [
                    "Undergoing structured training in Swift and SwiftUI for native iOS development; applying knowledge by building hands-on projects and navigating new frameworks and codebases independently.",
                    "Engineered interactive mobile user flows adhering to Apple Human Interface Guidelines with smooth spring animations and offline caching."
                ]
            )
        ],
        projects: [
            UserProject(
                id: "proj-educhain",
                title: "EduChain",
                period: "Feb 2025 – Present",
                techStack: "Hyperledger Fabric, Python, SHA-256, AI/ML",
                bullets: [
                    "Established a credential verification system on Hyperledger Fabric using SHA-256 hashing, eliminating fraudulent credential claims in testing.",
                    "Architected a skill-analysis engine that evaluates GitHub portfolios and generates personalized career roadmaps, reducing manual HR screening time by 50% across 3 pilot companies.",
                    "Pitched to judges and industry stakeholders at Horizon 2025, winning First Place in the Pitch Perfect Ideathon."
                ]
            ),
            UserProject(
                id: "proj-quantum",
                title: "Quantum Quest",
                period: "Mar 2025",
                techStack: "Python, FastAPI, Qiskit, MediaPipe, AR/VR, React",
                bullets: [
                    "Constructed an interactive quantum computing platform using Qiskit and FastAPI for real-time circuit simulation and visualization, featuring a gamified drag-and-drop circuit builder with multi-qubit support and 3D Bloch sphere visualization.",
                    "Integrated gesture-based controls (MediaPipe) and AR/VR modules for immersive quantum exploration.",
                    "Simulated core quantum workflows including Bell State, Quantum Teleportation, Grover’s Algorithm, and Quantum Fourier Transform."
                ]
            ),
            UserProject(
                id: "proj-labbuddy",
                title: "LabBuddy",
                period: "Jan 2026 – Apr 2026",
                techStack: "Flutter, Firebase, Google OAuth, QR Code API · Team of 4",
                bullets: [
                    "Launched a mobile application to digitize lab access, slot booking, and attendance management across engineering labs, implementing a three-role system (students, admins, wardens) with role-based dashboards.",
                    "Configured QR-based attendance with session tracking, custom duration booking, and admin-controlled exit approvals, plus real-time notifications.",
                    "Secured access via Google OAuth restricted to institutional credentials."
                ]
            ),
            UserProject(
                id: "proj-qrlink",
                title: "QR Link – Arqivo",
                period: "Jun 2026",
                techStack: "Python, Pandas, Flask, Selenium · Tagros Chemicals",
                bullets: [
                    "Automated Excel-based product data ingestion to generate unique verification QR links at scale; built a web dashboard preventing duplicate generation across the product team.",
                    "Integrated error recovery and automated schema validation for batch spreadsheet uploads."
                ]
            ),
            UserProject(
                id: "proj-it-helpdesk",
                title: "IT Helpdesk Chatbot",
                period: "May 2026 – Jun 2026",
                techStack: "FastAPI, React, Electron, SQLite, SQLAlchemy, Ollama, RAG",
                bullets: [
                    "Designed and developed a backend system using FastAPI and SQLite to manage ticket data, incorporating unit testing to validate core ticket-escalation logic and ensure reliable software.",
                    "Implemented RAG-based troubleshooting over a 170+ entry FAQ knowledge base using Ollama for private, on-device AI processing, with an admin dashboard for ticket analytics."
                ]
            )
        ]
    )
}

public extension CareerPreferences {
    static let sample = CareerPreferences(
        preferredRoles: ["Software Engineering", "AI/ML Engineering", "Mobile Development", "Backend Development"],
        preferredCompanies: ["Google", "Apple", "NVIDIA", "Microsoft", "Tagros"],
        preferredLocations: ["Bengaluru", "Chennai", "Hyderabad"],
        isOpenToAnyLocation: false,
        opportunityTypes: [.internship, .fullTime],
        workArrangements: [.hybrid, .onSite],
        experienceLevel: "Student / Freshers",
        alertsEnabled: true,
        isPushAllowedByOS: true
    )
}

public extension AchievementItem {
    static let samples: [AchievementItem] = [
        AchievementItem(
            id: "ach-1",
            title: "Pitch Perfect Ideathon — Winner",
            issuer: "Horizon 2025 (EduChain)",
            category: .hackathons,
            dateEarned: "Feb 2025",
            descriptionText: "Won 1st place pitching EduChain, a decentralized credential verification system and AI skill-analysis engine built on Hyperledger Fabric.",
            credentialURL: "https://horizon.srmist.edu.in/ideathon/winners",
            attachmentName: "Horizon_Pitch_Winner.pdf"
        ),
        AchievementItem(
            id: "ach-2",
            title: "QTHack04 Quantum Systems — 6th Place",
            issuer: "Track 4 Visual Simulation Hackathon",
            category: .hackathons,
            dateEarned: "Mar 2025",
            descriptionText: "Awarded 6th place for Quantum Quest, an interactive quantum computing simulation and AR platform built with Qiskit and FastAPI.",
            credentialURL: "https://qthack04.devpost.com/submissions",
            attachmentName: "QTHack_Certificate.pdf"
        ),
        AchievementItem(
            id: "ach-3",
            title: "Smart India Hackathon — Top 50 / 800+ Teams",
            issuer: "Ministry of Education & SRMIST",
            category: .hackathons,
            dateEarned: "Oct 2025",
            descriptionText: "Selected in top 50 teams out of 800+ competing teams in the university internal round for AI-driven public safety solutions.",
            credentialURL: nil,
            attachmentName: "SIH_Internal_Round.pdf"
        ),
        AchievementItem(
            id: "ach-4",
            title: "JPMorgan Chase Code for Good 2026",
            issuer: "JPMorgan Chase & Co., Bangalore",
            category: .awards,
            dateEarned: "2026",
            descriptionText: "Selected among top candidates across 15,000+ national applicants to build tech solutions for non-profit social organizations.",
            credentialURL: nil,
            attachmentName: "JPMC_CodeForGood.pdf"
        ),
        AchievementItem(
            id: "ach-5",
            title: "HTML & CSS In-Depth Certification",
            issuer: "Meta (Coursera)",
            category: .certificates,
            dateEarned: "2025",
            descriptionText: "Advanced certification covering modern CSS, responsive layouts, web accessibility standards, and semantic HTML architecture.",
            credentialURL: "https://coursera.org/verify/meta-html-css",
            attachmentName: "Meta_HTML_CSS.pdf"
        ),
        AchievementItem(
            id: "ach-6",
            title: "Java (Basic) Skills Certificate",
            issuer: "HackerRank",
            category: .certificates,
            dateEarned: "2025",
            descriptionText: "Verified proficiency in core Java programming, object-oriented concepts, exception handling, and standard library collections.",
            credentialURL: "https://hackerrank.com/certificates/java-basic",
            attachmentName: "HackerRank_Java.pdf"
        )
    ]
}
