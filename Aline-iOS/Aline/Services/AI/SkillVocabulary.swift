import Foundation

/// Shared with the backend's SKILL_VOCABULARY concept (backend/app/filters.py) so resume
/// skills and job-extracted skills are directly comparable strings in MatchEngine.
enum SkillVocabulary {
    static let all = [
        "Python", "Java", "JavaScript", "TypeScript", "Swift", "Kotlin", "C++", "C", "Go", "Rust",
        "React", "Angular", "Vue", "Node.js", "FastAPI", "Django", "Flask", "Spring", "Spring Boot",
        "AWS", "GCP", "Azure", "Docker", "Kubernetes", "SQL", "PostgreSQL", "MySQL", "MongoDB",
        "Redis", "Machine Learning", "Deep Learning", "TensorFlow", "PyTorch", "NLP",
        "Computer Vision", "Data Structures", "Algorithms", "REST API", "GraphQL", "CI/CD", "Git",
        "Linux", "Android", "iOS", "HTML", "CSS", "SwiftUI", "UIKit", "Spark", "Hadoop", "Kafka",
        "Terraform", "Jenkins", "GitHub Actions", "Microservices", "System Design", "DSA",
        "Pandas", "NumPy", "Scikit-learn", "LLM", "Generative AI", "GraphDB", "Elasticsearch",
    ]
}
