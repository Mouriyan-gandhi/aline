import SwiftUI

// MARK: - Comprehensive 100+ Opportunities Dataset (Realistic Tech & Internships)
public extension Opportunity {
    static let dataset: [Opportunity] = [
        Opportunity(
            id: "opp-ola-1",
            companyName: "Ola",
            companySymbol: "circle.circle.fill",
            roleTitle: "Autonomous Mobility Systems Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 93,
            recency: "Just now",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.ola.com",
            aboutRole: "Develop edge sensor fusion, perception pipelines, and real-time path planning for next-generation electric and autonomous vehicles.",
            minimumQualifications: [
                "Pursuing Computer Science, Robotics, or Electrical Engineering.",
                "Strong proficiency in C++ and Python.",
                "Understanding of ROS/ROS2, sensor telemetry, and Kalman filters.",
            ],
            preferredQualifications: [
                "Prior robotics competition or autonomous driving simulation project.",
                "Experience with embedded Linux environments.",
            ],
            applicantTips: [
                "Highlight low-latency perception and obstacle detection pipelines.",
            ],
            responsibilities: [
                "Implement real-time obstacle avoidance algorithms.",
                "Test sensor fusion models on high-fidelity simulation benches.",
            ],
            skills: [
                "C++",
                "Python",
                "ROS2",
                "Computer Vision",
                "Sensor Fusion",
                "Linux",
            ],
            detectedKeywords: [
                "C++",
                "Python",
                "Linux",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Sensor Telemetry",
                    recommendation: "Detail throughput latency benchmarks.",
                    placeholderTemplate: "Optimized LiDAR-camera point cloud calibration to 12ms pipeline latency."
                ),
            ]
        ),
        Opportunity(
            id: "opp-flipkart-2",
            companyName: "Flipkart",
            companySymbol: "cart.fill",
            roleTitle: "Software Development Engineer (Backend)",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹75k - ₹1.0L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.flipkart.com",
            aboutRole: "Build scalable distributed architectures powering India's premier e-commerce ecosystem. Handle high-throughput microservices during Big Billion Days.",
            minimumQualifications: [
                "Degree in Computer Science or related field (Graduating in 2027 or 2028).",
                "Strong foundations in Java or Go, Spring Boot, and SQL databases.",
            ],
            preferredQualifications: [
                "Knowledge of Kafka, Redis caching, or message queue workflows.",
            ],
            applicantTips: [
                "Highlight high-traffic handling and database normalization principles.",
            ],
            responsibilities: [
                "Develop fault-tolerant REST APIs and gRPC services.",
                "Optimize relational database queries and cache strategies.",
            ],
            skills: [
                "Java",
                "Spring Boot",
                "Kafka",
                "MySQL",
                "Redis",
                "Microservices",
            ],
            detectedKeywords: [
                "Java",
                "MySQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Distributed Caching",
                    recommendation: "Clarify how cache hit ratios were improved.",
                    placeholderTemplate: "Implemented Redis cache layer reducing database load by 42%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-apple-3",
            companyName: "Apple",
            companySymbol: "apple.logo",
            roleTitle: "iOS Software Engineer Intern",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹95k - ₹1.3L / mo",
            experienceYears: "Interns",
            eligibleGradYears: "2027 – 2028",
            matchScore: 95,
            recency: "Just now",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.apple.com",
            aboutRole: "Join the team creating tactile, fluid native iOS experiences. Work on Swift, SwiftUI, gesture engines, and performance profiling across Apple hardware.",
            minimumQualifications: [
                "Pursuing degree in Computer Science or Software Engineering.",
                "Proficiency in Swift, SwiftUI, and iOS application lifecycle.",
                "Passion for intuitive micro-interactions and high framerate UI.",
            ],
            preferredQualifications: [
                "Published app on the App Store or open-source Swift package.",
                "Understanding of Swift Concurrency (async/await) and Apple HIG.",
            ],
            applicantTips: [
                "Ensure code samples emphasize clarity, safety, and attention to tactile UI.",
            ],
            responsibilities: [
                "Develop user-facing features using native SwiftUI.",
                "Profile memory footprints and maintain a consistent 120Hz ProMotion framerate.",
            ],
            skills: [
                "Swift",
                "SwiftUI",
                "iOS",
                "SF Symbols",
                "Concurrency",
                "Instruments",
                "Git",
            ],
            detectedKeywords: [
                "Swift",
                "SwiftUI",
                "Git",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Instruments Profiling",
                    recommendation: "Highlight frame rate optimization.",
                    placeholderTemplate: "Diagnosed UI stutters using Xcode Instruments to achieve 120fps fluid scrolling."
                ),
            ]
        ),
        Opportunity(
            id: "opp-google-4",
            companyName: "Google",
            companySymbol: "g.circle.fill",
            roleTitle: "Software Development Engineer Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers (0 yrs)",
            eligibleGradYears: "2027 – 2028",
            matchScore: 92,
            recency: "Just now",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.google.com",
            aboutRole: "As a Software Engineering Intern at Google, you will develop core infrastructure and distributed services alongside senior engineers scaling to billions of global users.",
            minimumQualifications: [
                "Enrolled in Computer Science or related degree graduating in 2027-2028.",
                "Proficiency in C++, Java, Python, or Go.",
                "Strong data structures and algorithms fundamentals.",
            ],
            preferredQualifications: [
                "Prior open-source contribution or systems project.",
                "Familiarity with Unix/Linux environments.",
            ],
            applicantTips: [
                "Focus on algorithmic complexity trade-offs in project descriptions.",
            ],
            responsibilities: [
                "Design, develop, test, and deploy software services.",
                "Write clean, performant, and maintainable code.",
                "Participate in design discussions and peer code reviews.",
            ],
            skills: [
                "C++",
                "Python",
                "Data Structures",
                "Algorithms",
                "Distributed Systems",
                "Linux",
            ],
            detectedKeywords: [
                "C++",
                "Python",
                "Algorithms",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "System Design",
                    recommendation: "Add an example of architecture trade-off.",
                    placeholderTemplate: "Designed [component] balancing latency vs throughput."
                ),
                MissingKeyword(
                    keyword: "Data Structures",
                    recommendation: "Explicitly name data structures used.",
                    placeholderTemplate: "Implemented [Trie / Hash Map] reducing lookup latency by 30%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-ola-5",
            companyName: "Ola",
            companySymbol: "circle.circle.fill",
            roleTitle: "Battery Management Systems Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "2h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.ola.com",
            aboutRole: "Engineer high-safety firmware, state-of-charge estimation, and thermal runaway prevention algorithms for Ola Gigafactory EV battery packs.",
            minimumQualifications: [
                "Degree in Electrical, Electronics, or Embedded Systems.",
                "Proficiency in Embedded C, CAN bus protocol, and RTOS.",
                "Strong understanding of lithium-ion cell chemistry.",
            ],
            preferredQualifications: [
                "Experience with MATLAB/Simulink state estimators.",
            ],
            applicantTips: [
                "Highlight CAN message parsing and fail-safe watchdog implementations.",
            ],
            responsibilities: [
                "Develop battery cell balancing firmware.",
                "Simulate thermal dissipation profiles under fast-charging loads.",
            ],
            skills: [
                "Embedded C",
                "CAN Bus",
                "RTOS",
                "MATLAB",
                "State Estimation",
                "Hardware Debugging",
            ],
            detectedKeywords: [
                "Embedded C",
                "CAN Bus",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Safety Watchdog",
                    recommendation: "Highlight reliability standards.",
                    placeholderTemplate: "Architected ISO 26262 compliant cell thermal cutoff watchdog."
                ),
            ]
        ),
        Opportunity(
            id: "opp-ola-6",
            companyName: "Ola",
            companySymbol: "circle.circle.fill",
            roleTitle: "Data Science & Routing Algorithms Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 82,
            recency: "5h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.ola.com",
            aboutRole: "Optimize dynamic pricing, cab dispatch matching, and geospatial ETA routing across millions of daily rides.",
            minimumQualifications: [
                "Degree in Computer Science, Math, or Operations Research.",
                "Proficiency in Python, SQL, and graph optimization algorithms.",
                "Experience with geospatial libraries (H3, Shapely, GeoPandas).",
            ],
            preferredQualifications: [
                "Experience with reinforcement learning or dynamic dispatch queuing.",
            ],
            applicantTips: [
                "Quantify wait time or route efficiency improvement.",
            ],
            responsibilities: [
                "Build dispatch clustering models reducing idle driver deadhead miles.",
                "Analyze urban traffic graph bottlenecks.",
            ],
            skills: [
                "Python",
                "SQL",
                "Graph Theory",
                "H3",
                "Operations Research",
                "Machine Learning",
            ],
            detectedKeywords: [
                "Python",
                "SQL",
                "Graph Theory",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Dispatch Efficiency",
                    recommendation: "Highlight ETA metric improvements.",
                    placeholderTemplate: "Improved driver dispatch matching reducing customer wait times by 14.2%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-ola-7",
            companyName: "Ola",
            companySymbol: "circle.circle.fill",
            roleTitle: "Software Development Engineer Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 91,
            recency: "1d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.ola.com",
            aboutRole: "Scale Ola Consumer App backend and high-throughput booking microservices handling peak commuter demand.",
            minimumQualifications: [
                "Degree in Computer Science or IT.",
                "Proficiency in Java, Go, or Python.",
                "Understanding of distributed caching (Redis), Kafka streaming, and MySQL.",
            ],
            preferredQualifications: [
                "Experience with high-throughput distributed microservices.",
            ],
            applicantTips: [
                "Include concurrency and cache consistency strategies.",
            ],
            responsibilities: [
                "Develop ride booking event streaming services.",
                "Optimize database query latency for peak surge traffic.",
            ],
            skills: [
                "Java",
                "Go",
                "Kafka",
                "Redis",
                "Distributed Systems",
                "MySQL",
            ],
            detectedKeywords: [
                "Java",
                "Kafka",
                "Redis",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Peak Throughput",
                    recommendation: "Detail surge scalability.",
                    placeholderTemplate: "Handled 50,000 requests/sec with 99.9% uptime during peak surge hours."
                ),
            ]
        ),
        Opportunity(
            id: "opp-flipkart-8",
            companyName: "Flipkart",
            companySymbol: "cart.fill",
            roleTitle: "Big Data Platform Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "2d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.flipkart.com",
            aboutRole: "Develop petabyte-scale data ingestion and analytics pipelines processing daily customer clicks and search queries.",
            minimumQualifications: [
                "Proficiency in Java, Scala, or Python.",
                "Understanding of Apache Spark, Hadoop, HDFS, and Hive.",
            ],
            preferredQualifications: [
                "Experience with cloud data warehouses and Parquet compression.",
            ],
            applicantTips: [
                "Discuss batch processing efficiency and partition pruning.",
            ],
            responsibilities: [
                "Optimize daily Spark ETL jobs processing 50TB+ of clickstream data.",
                "Build automated schema validation and anomaly alerts.",
            ],
            skills: [
                "Scala",
                "Java",
                "Apache Spark",
                "Hadoop",
                "SQL",
                "Big Data",
            ],
            detectedKeywords: [
                "Java",
                "SQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Spark Optimization",
                    recommendation: "State ETL execution time decrease.",
                    placeholderTemplate: "Tuned Spark memory executor allocation reducing nightly batch runtime from 3.5 hours to 1.2 hours."
                ),
            ]
        ),
        Opportunity(
            id: "opp-flipkart-9",
            companyName: "Flipkart",
            companySymbol: "cart.fill",
            roleTitle: "Supply Chain Optimization Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 89,
            recency: "3d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.flipkart.com",
            aboutRole: "Design mathematical route planning and inventory placement models for hundreds of regional fulfillment hubs.",
            minimumQualifications: [
                "Degree in CS, Operations Research, or Industrial Engineering.",
                "Proficiency in Python and mixed-integer linear programming (OR-Tools / PuLP).",
            ],
            preferredQualifications: [
                "Understanding of vehicle routing problems and demand forecasting.",
            ],
            applicantTips: [
                "Showcase mathematical formulation and cost reduction metrics.",
            ],
            responsibilities: [
                "Formulate multi-warehouse inventory allocation algorithms.",
                "Analyze truck fill-rate telemetry to optimize regional transport routes.",
            ],
            skills: [
                "Python",
                "Optimization",
                "OR-Tools",
                "Algorithms",
                "Supply Chain",
                "Analytics",
            ],
            detectedKeywords: [
                "Python",
                "Algorithms",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Routing Optimization",
                    recommendation: "State fuel or transit cost saved.",
                    placeholderTemplate: "Formulated vehicle routing solver reducing regional dispatch transit costs by 14%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-flipkart-10",
            companyName: "Flipkart",
            companySymbol: "cart.fill",
            roleTitle: "Android Engineer",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 78,
            recency: "4d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.flipkart.com",
            aboutRole: "Deliver snappy product browse, live order tracking, and vernacular voice search experiences on the Flipkart Android app.",
            minimumQualifications: [
                "Proficiency in Kotlin, Coroutines, and MVVM architecture.",
                "Understanding of RecyclerView viewholder caching and image loading optimizations.",
            ],
            preferredQualifications: [
                "Experience with Glide/Coil and app cold startup reduction.",
            ],
            applicantTips: [
                "Highlight low-end device optimization and smooth scrolling.",
            ],
            responsibilities: [
                "Build modularized shopping cart and payment screens.",
                "Profile memory footprint to ensure zero OOM crashes on 2GB RAM phones.",
            ],
            skills: [
                "Kotlin",
                "Android",
                "Coroutines",
                "MVVM",
                "Image Caching",
                "App Performance",
            ],
            detectedKeywords: [
                "Kotlin",
                "Android",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Memory Optimization",
                    recommendation: "Detail OOM crash reduction.",
                    placeholderTemplate: "Optimized bitmap memory recycling eliminating out-of-memory crashes on low-end Android devices."
                ),
            ]
        ),
        Opportunity(
            id: "opp-apple-11",
            companyName: "Apple",
            companySymbol: "apple.logo",
            roleTitle: "Machine Learning Systems Intern",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹90k - ₹1.25L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 89,
            recency: "4h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: true,
            applicationDate: "11 days ago",
            externalCareersURL: "https://careers.apple.com",
            aboutRole: "Optimize on-device neural network execution on Apple Silicon Neural Engine (ANE) using CoreML and MLX.",
            minimumQualifications: [
                "Strong foundation in C++, Python, and computer architecture.",
                "Understanding of neural network quantization, pruning, and low-level matrix ops.",
            ],
            preferredQualifications: [
                "Hands-on experience with Apple Silicon MLX or CoreML.",
                "Knowledge of Metal Performance Shaders (MPS).",
            ],
            applicantTips: [
                "Detail memory bandwidth optimizations on embedded devices.",
            ],
            responsibilities: [
                "Profile on-device model latency and memory footprints.",
                "Implement custom Metal compute shaders for novel layer types.",
            ],
            skills: [
                "CoreML",
                "MLX",
                "Metal",
                "C++",
                "Python",
                "Neural Networks",
                "Apple Silicon",
            ],
            detectedKeywords: [
                "Python",
                "C++",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "On-Device ML",
                    recommendation: "Mention quantization benchmarks.",
                    placeholderTemplate: "Quantized models to 4-bit achieving 2.4x inference speedup on-device."
                ),
            ]
        ),
        Opportunity(
            id: "opp-apple-12",
            companyName: "Apple",
            companySymbol: "apple.logo",
            roleTitle: "Hardware-Software Integration Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹85k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 80,
            recency: "1d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.apple.com",
            aboutRole: "Bridge embedded firmware, drivers, and user space software for Apple sensor and display sub-systems.",
            minimumQualifications: [
                "Pursuing EE, CE, or CS degree.",
                "Proficiency in C, C++, and low-level debugging with oscilloscopes/logic analyzers.",
                "Understanding of I2C, SPI, UART protocols.",
            ],
            preferredQualifications: [
                "Experience writing device drivers or RTOS programming.",
            ],
            applicantTips: [
                "Highlight board bring-up and hardware interface experience.",
            ],
            responsibilities: [
                "Write automated validation suites for hardware protocols.",
                "Debug sensor timing issues under high thermal loads.",
            ],
            skills: [
                "Embedded C",
                "C++",
                "RTOS",
                "Device Drivers",
                "Hardware Debugging",
                "SPI/I2C",
            ],
            detectedKeywords: [
                "Embedded C",
                "C++",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Firmware Debugging",
                    recommendation: "Add specific interface tested.",
                    placeholderTemplate: "Validated sensor telemetry over SPI with zero packet drop."
                ),
            ]
        ),
        Opportunity(
            id: "opp-apple-13",
            companyName: "Apple",
            companySymbol: "apple.logo",
            roleTitle: "UI/UX Prototyper",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "Design/Tech",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "2d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.apple.com",
            aboutRole: "Craft high-fidelity, interactive spatial and touch prototypes exploring future interaction concepts on iOS and iPadOS.",
            minimumQualifications: [
                "Skill in both interactive design and rapid code prototyping (SwiftUI / Origami / WebGL).",
                "Impeccable eye for typography, easing curves, and spatial rhythm.",
            ],
            preferredQualifications: [
                "Experience building fluid gesture animations in SwiftUI.",
            ],
            applicantTips: [
                "Show working video clips and code snippets of custom gesture transitions.",
            ],
            responsibilities: [
                "Prototype novel navigation models and tactile spring interactions.",
                "Partner closely with designers and human interface engineers.",
            ],
            skills: [
                "SwiftUI",
                "Prototyping",
                "Interaction Design",
                "Animation Curves",
                "Figma",
                "Apple HIG",
            ],
            detectedKeywords: [
                "SwiftUI",
                "Figma",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Animation Curves",
                    recommendation: "Quantify gesture responsiveness.",
                    placeholderTemplate: "Engineered interactive spring gesture tracking at 120Hz."
                ),
            ]
        ),
        Opportunity(
            id: "opp-google-14",
            companyName: "Google",
            companySymbol: "g.circle.fill",
            roleTitle: "Product Design Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹75k - ₹1.0L / mo",
            experienceYears: "Design students",
            eligibleGradYears: "2027 – 2028",
            matchScore: 83,
            recency: "2h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.google.com",
            aboutRole: "Help shape the future of user experiences across Google products through intuitive interaction design, design systems, and rapid prototyping.",
            minimumQualifications: [
                "Pursuing degree in Human-Computer Interaction, Design, or related field.",
                "Proficiency in Figma, prototyping tools, and design system governance.",
                "Portfolio demonstrating user-centered problem solving.",
            ],
            preferredQualifications: [
                "Experience conducting usability tests.",
                "Basic understanding of HTML/CSS/SwiftUI constraints.",
            ],
            applicantTips: [
                "Showcase design journey from problem definition through iterations to final outcome.",
            ],
            responsibilities: [
                "Design high-fidelity user flows and interactive prototypes.",
                "Collaborate with researchers and PMs to translate insights into intuitive UI.",
            ],
            skills: [
                "Figma",
                "UI/UX",
                "Design Systems",
                "Prototyping",
                "User Research",
                "Interaction Design",
            ],
            detectedKeywords: [
                "Figma",
                "Design Systems",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "User Testing",
                    recommendation: "Include usability test metrics.",
                    placeholderTemplate: "Conducted usability testing with [X] users yielding [Y]% improvement."
                ),
            ]
        ),
        Opportunity(
            id: "opp-google-15",
            companyName: "Google",
            companySymbol: "g.circle.fill",
            roleTitle: "Cloud Solutions Architect Intern",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 84,
            recency: "5h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.google.com",
            aboutRole: "Work with Google Cloud customers to design robust, cost-effective, and secure cloud migration and microservices architectures on GCP.",
            minimumQualifications: [
                "Pursuing Computer Science, IT, or Electrical Engineering degree.",
                "Understanding of networking, cloud computing, and containerization (Docker/K8s).",
                "Strong communication and technical writing skills.",
            ],
            preferredQualifications: [
                "Google Cloud Associate Cloud Engineer certification or coursework.",
                "Hands-on projects with Kubernetes or Terraform.",
            ],
            applicantTips: [
                "Highlight distributed networking and scalability principles.",
            ],
            responsibilities: [
                "Build proof-of-concept deployments on Google Cloud.",
                "Create reference architectures for containerized microservices.",
            ],
            skills: [
                "GCP",
                "Kubernetes",
                "Docker",
                "Cloud Architecture",
                "Terraform",
                "Networking",
            ],
            detectedKeywords: [
                "Docker",
                "GCP",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Kubernetes",
                    recommendation: "Highlight cluster orchestration experience.",
                    placeholderTemplate: "Managed multi-node deployments with Kubernetes."
                ),
            ]
        ),
        Opportunity(
            id: "opp-google-16",
            companyName: "Google",
            companySymbol: "g.circle.fill",
            roleTitle: "Machine Learning Research Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹95k - ₹1.4L / mo",
            experienceYears: "B.Tech/M.Tech",
            eligibleGradYears: "2027 – 2028",
            matchScore: 76,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.google.com",
            aboutRole: "Conduct foundational and applied research in large multimodal models, efficient fine-tuning, and transformer architectures alongside Google DeepMind and Research teams.",
            minimumQualifications: [
                "Enrolled in CS, AI, Math, or related STEM degree.",
                "Deep proficiency in PyTorch, JAX, or TensorFlow.",
                "Solid mathematical grounding in linear algebra, probability, and optimization.",
            ],
            preferredQualifications: [
                "Publications or preprints in top conferences (NeurIPS, ICML, CVPR, ICLR).",
                "Experience with LLM fine-tuning techniques (LoRA, RLHF).",
            ],
            applicantTips: [
                "Link GitHub repos and cite mathematical formulation.",
            ],
            responsibilities: [
                "Train and evaluate experimental model architectures.",
                "Implement novel loss functions and attention optimizations.",
            ],
            skills: [
                "PyTorch",
                "JAX",
                "Transformers",
                "Deep Learning",
                "LLMs",
                "Linear Algebra",
            ],
            detectedKeywords: [
                "PyTorch",
                "Deep Learning",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Model Optimization",
                    recommendation: "Explain inference speedup.",
                    placeholderTemplate: "Optimized transformer inference by [X]% using quantization."
                ),
            ]
        ),
        Opportunity(
            id: "opp-google-17",
            companyName: "Google",
            companySymbol: "g.circle.fill",
            roleTitle: "Technical Program Manager Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹70k - ₹95k / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 81,
            recency: "2d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.google.com",
            aboutRole: "Drive cross-functional technical programs bridging engineering, product, and operations across global teams.",
            minimumQualifications: [
                "Pursuing Engineering or dual degree with management interest.",
                "Demonstrated leadership in technical clubs or projects.",
                "Strong analytical and risk-mitigation mindset.",
            ],
            preferredQualifications: [
                "Agile / Scrum methodology familiarity.",
                "Experience managing timelines and technical deliverables.",
            ],
            applicantTips: [
                "Quantify project impact and team coordination.",
            ],
            responsibilities: [
                "Define milestones, track cross-team dependencies, and manage release roadmaps.",
                "Facilitate technical syncs and architectural reviews.",
            ],
            skills: [
                "Project Management",
                "Agile",
                "Technical Roadmapping",
                "Jira",
                "Cross-functional Leadership",
            ],
            detectedKeywords: [
                "Project Management",
                "Agile",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Metrics Tracking",
                    recommendation: "Add measurable outcomes.",
                    placeholderTemplate: "Delivered sprint milestones on time with zero release blockers."
                ),
            ]
        ),
        Opportunity(
            id: "opp-microsoft-18",
            companyName: "Microsoft",
            companySymbol: "window.vertical.closed",
            roleTitle: "Software Engineer Intern - Azure Core",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 81,
            recency: "1h ago",
            cardColor: AlineTheme.cardSkyBlue,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.microsoft.com",
            aboutRole: "Develop hyperscale distributed virtualization, storage, and networking services running across global Azure data centers.",
            minimumQualifications: [
                "Enrolled in Computer Science or related degree graduating in 2027-2028.",
                "Proficiency in C++, C#, or Rust.",
                "Solid grasp of OS fundamentals, multithreading, and network sockets.",
            ],
            preferredQualifications: [
                "Familiarity with distributed consensus (Raft, Paxos).",
                "Hands-on cloud engineering experience.",
            ],
            applicantTips: [
                "Highlight low-level systems programming and lock-free concurrency.",
            ],
            responsibilities: [
                "Implement resilient microservices handling thousands of requests per second.",
                "Debug distributed latency spikes and thread contention issues.",
            ],
            skills: [
                "C#",
                "C++",
                "Azure",
                "Distributed Systems",
                "Multithreading",
                "OS Internals",
            ],
            detectedKeywords: [
                "C++",
                "Distributed Systems",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Concurrency",
                    recommendation: "Specify thread-safe patterns used.",
                    placeholderTemplate: "Eliminated deadlocks by adopting lock-free queues and atomic operations."
                ),
            ]
        ),
        Opportunity(
            id: "opp-microsoft-19",
            companyName: "Microsoft",
            companySymbol: "window.vertical.closed",
            roleTitle: "SDE Intern - Microsoft Teams",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 87,
            recency: "3h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.microsoft.com",
            aboutRole: "Build modern collaborative real-time calling, screen sharing, and messaging features used by hundreds of millions daily.",
            minimumQualifications: [
                "CS/IT degree pursuing students.",
                "Proficiency in TypeScript, React, or C++.",
                "Understanding of WebSockets, WebRTC, or media streaming pipelines.",
            ],
            preferredQualifications: [
                "Experience building high-performance web or desktop client applications.",
            ],
            applicantTips: [
                "Detail bundle size optimizations and memory management.",
            ],
            responsibilities: [
                "Build interactive client UI and real-time syncing mechanisms.",
                "Write automated unit and end-to-end integration tests.",
            ],
            skills: [
                "TypeScript",
                "React",
                "WebRTC",
                "C++",
                "WebSockets",
                "State Management",
            ],
            detectedKeywords: [
                "TypeScript",
                "React",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Real-Time Sync",
                    recommendation: "Mention message latency metrics.",
                    placeholderTemplate: "Engineered WebSocket sync protocol reducing packet arrival lag by 28%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-microsoft-20",
            companyName: "Microsoft",
            companySymbol: "window.vertical.closed",
            roleTitle: "Data & Applied Scientist Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 79,
            recency: "1d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.microsoft.com",
            aboutRole: "Build Copilot intelligent assistance models, semantic search rankers, and automated code completion engines.",
            minimumQualifications: [
                "Strong foundation in Machine Learning, NLP, and Statistical Modeling.",
                "Proficiency in Python, PyTorch, and SQL.",
            ],
            preferredQualifications: [
                "Familiarity with transformer fine-tuning, RAG pipelines, and vector databases.",
            ],
            applicantTips: [
                "Discuss embedding models and retrieval accuracy benchmarks.",
            ],
            responsibilities: [
                "Evaluate LLM prompt variations and benchmark hallucination rates.",
                "Fine-tune contextual ranking models for enterprise search.",
            ],
            skills: [
                "Python",
                "PyTorch",
                "NLP",
                "RAG",
                "Vector Search",
                "Transformers",
                "SQL",
            ],
            detectedKeywords: [
                "Python",
                "NLP",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Vector Search",
                    recommendation: "Include search precision metrics.",
                    placeholderTemplate: "Implemented hybrid vector retrieval improving recall@10 by 18%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-microsoft-21",
            companyName: "Microsoft",
            companySymbol: "window.vertical.closed",
            roleTitle: "Security Engineering Intern",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "3d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.microsoft.com",
            aboutRole: "Identify vulnerabilities, implement cryptographically secure protocols, and safeguard enterprise identity frameworks.",
            minimumQualifications: [
                "Understanding of OWASP Top 10, network security, and cryptography.",
                "Proficiency in Python, C#, or Go for security tooling and scripting.",
            ],
            preferredQualifications: [
                "Bug bounty discoveries or CTF competition participation.",
            ],
            applicantTips: [
                "Detail penetration testing methodology and threat modeling.",
            ],
            responsibilities: [
                "Conduct static and dynamic security assessments on microservices.",
                "Build automated vulnerability scanning scripts.",
            ],
            skills: [
                "Security",
                "Cryptography",
                "Penetration Testing",
                "Python",
                "OAuth",
                "Cloud Security",
            ],
            detectedKeywords: [
                "Security",
                "Python",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Vulnerability Mitigation",
                    recommendation: "Add specific CVE or security fix.",
                    placeholderTemplate: "Remediated critical authentication bypass vulnerability in API gateway."
                ),
            ]
        ),
        Opportunity(
            id: "opp-meta-22",
            companyName: "Meta",
            companySymbol: "m.circle.fill",
            roleTitle: "Software Engineer Intern - Infrastructure",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹95k - ₹1.35L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "Just now",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: true,
            applicationDate: "22 days ago",
            externalCareersURL: "https://careers.meta.com",
            aboutRole: "Work on custom high-efficiency databases, distributed caching (Memcached), and traffic routing pipelines powering Instagram and WhatsApp.",
            minimumQualifications: [
                "Pursuing Computer Science, Computer Engineering, or related degree.",
                "Expertise in C++, Python, or Rust.",
                "Deep understanding of algorithms and memory management.",
            ],
            preferredQualifications: [
                "Experience contributing to open-source systems software.",
                "Knowledge of Linux kernel tracing (eBPF).",
            ],
            applicantTips: [
                "Highlight cache hit ratios and scale of operations.",
            ],
            responsibilities: [
                "Write multi-threaded C++ services processing petabytes of network traffic.",
                "Profile CPU branch mispredictions and memory cache misses.",
            ],
            skills: [
                "C++",
                "Distributed Systems",
                "Linux",
                "Caching",
                "Algorithms",
                "Concurrency",
            ],
            detectedKeywords: [
                "C++",
                "Algorithms",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Cache Optimization",
                    recommendation: "Quantify cache performance improvement.",
                    placeholderTemplate: "Tuned eviction policies in memory cache elevating hit rate by 14%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-meta-23",
            companyName: "Meta",
            companySymbol: "m.circle.fill",
            roleTitle: "AI Research Intern - FAIR",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹1.0L - ₹1.5L / mo",
            experienceYears: "B.Tech/M.Tech",
            eligibleGradYears: "2027 – 2028",
            matchScore: 96,
            recency: "6h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.meta.com",
            aboutRole: "Conduct frontier research on open foundational intelligence, vision-language transformers, and LLaMA model architectures.",
            minimumQualifications: [
                "Enrolled in Computer Science, AI, or Computational Mathematics.",
                "Proficiency in PyTorch and distributed training across multi-GPU clusters.",
            ],
            preferredQualifications: [
                "Prior research papers in CVPR, ICCV, NeurIPS, or ACL.",
                "Knowledge of DeepSpeed, Megatron, or FSDP.",
            ],
            applicantTips: [
                "Link GitHub research code and preprint citations.",
            ],
            responsibilities: [
                "Run large-scale training experiments across hundreds of GPUs.",
                "Formulate novel regularization techniques and evaluate benchmarks.",
            ],
            skills: [
                "PyTorch",
                "LLaMA",
                "FSDP",
                "Deep Learning",
                "Distributed Training",
                "Computer Vision",
            ],
            detectedKeywords: [
                "PyTorch",
                "Deep Learning",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Distributed Training",
                    recommendation: "State GPU scale and training speed.",
                    placeholderTemplate: "Managed 64-GPU distributed training using PyTorch FSDP with 92% linear scaling."
                ),
            ]
        ),
        Opportunity(
            id: "opp-meta-24",
            companyName: "Meta",
            companySymbol: "m.circle.fill",
            roleTitle: "Product Design Intern - Reality Labs",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "Design students",
            eligibleGradYears: "2027 – 2028",
            matchScore: 84,
            recency: "1d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.meta.com",
            aboutRole: "Design spatial user interfaces, hand-tracking interactions, and mixed-reality social spaces for Meta Quest and Orion glasses.",
            minimumQualifications: [
                "Strong spatial design sense, 3D interaction concepts, and ergonomic empathy.",
                "Proficiency with Figma, Blender, Unity, or spatial prototyping tools.",
            ],
            preferredQualifications: [
                "Experience designing spatial audio, gestures, or AR overlays.",
            ],
            applicantTips: [
                "Present video recordings of spatial interactions in action.",
            ],
            responsibilities: [
                "Create wireframes and interactive VR/AR interaction flows.",
                "Test physical fatigue and comfort metrics with user research participants.",
            ],
            skills: [
                "Spatial UI",
                "Figma",
                "Unity",
                "3D Design",
                "AR/VR",
                "Interaction Design",
            ],
            detectedKeywords: [
                "Figma",
                "Interaction Design",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Spatial Ergonomics",
                    recommendation: "Explain gesture comfort optimization.",
                    placeholderTemplate: "Iterated hand gesture threshold to reduce user arm fatigue during prolonged sessions."
                ),
            ]
        ),
        Opportunity(
            id: "opp-meta-25",
            companyName: "Meta",
            companySymbol: "m.circle.fill",
            roleTitle: "Android Developer Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 90,
            recency: "2d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.meta.com",
            aboutRole: "Optimize Instagram and WhatsApp Android apps for emerging markets with limited bandwidth and low-end devices.",
            minimumQualifications: [
                "Proficiency in Kotlin, Java, and Android SDK.",
                "Strong understanding of Jetpack Compose, Coroutines, and app startup time.",
            ],
            preferredQualifications: [
                "Experience optimizing APK size, image caching, and battery drain.",
            ],
            applicantTips: [
                "Detail startup time latency reductions and network compression.",
            ],
            responsibilities: [
                "Build modularized Jetpack Compose screens.",
                "Optimize background sync services to consume minimal battery.",
            ],
            skills: [
                "Kotlin",
                "Android",
                "Jetpack Compose",
                "Coroutines",
                "Performance Tuning",
            ],
            detectedKeywords: [
                "Kotlin",
                "Android",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "App Performance",
                    recommendation: "Detail APK size or launch time gain.",
                    placeholderTemplate: "Streamlined asset packaging reducing cold launch duration by 22%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-amazon-26",
            companyName: "Amazon",
            companySymbol: "cart.fill",
            roleTitle: "SDE Intern - AWS Databases",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 77,
            recency: "2h ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.amazon.com",
            aboutRole: "Contribute to the storage engine, replication protocol, and automated failover mechanics behind Amazon DynamoDB and Aurora.",
            minimumQualifications: [
                "Pursuing Computer Science or related engineering degree.",
                "Proficiency in Java, C++, or Rust.",
                "Strong grasp of transactional guarantees, ACID properties, and storage indices.",
            ],
            preferredQualifications: [
                "Understanding of distributed replication (Multi-Paxos / Raft).",
            ],
            applicantTips: [
                "Emphasize deep understanding of B-trees and write-ahead logs.",
            ],
            responsibilities: [
                "Implement low-latency read/write paths for storage nodes.",
                "Write automated stress-testing suites injecting network partitions.",
            ],
            skills: [
                "Java",
                "C++",
                "DynamoDB",
                "AWS",
                "Databases",
                "Distributed Storage",
            ],
            detectedKeywords: [
                "Java",
                "Databases",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Database Indexing",
                    recommendation: "Explain query speedup.",
                    placeholderTemplate: "Engineered composite B-tree index decreasing p99 read latency by 35%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-amazon-27",
            companyName: "Amazon",
            companySymbol: "cart.fill",
            roleTitle: "Applied Scientist Intern - Alexa AI",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.25L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "5h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.amazon.com",
            aboutRole: "Advance conversational dialogue management, intent classification, and streaming speech recognition models on the edge.",
            minimumQualifications: [
                "CS, Speech, or ML degree students.",
                "Proficiency in Python, PyTorch, and NLP modeling.",
            ],
            preferredQualifications: [
                "Hands-on experience with streaming transformer models or Kaldi/Whisper.",
            ],
            applicantTips: [
                "Detail model quantization and latency budgeting.",
            ],
            responsibilities: [
                "Train intent classification models on multilingual conversational corpora.",
                "Optimize inference latency to meet strict voice turn budgets.",
            ],
            skills: [
                "Python",
                "PyTorch",
                "Speech Recognition",
                "NLP",
                "Edge ML",
                "Transformers",
            ],
            detectedKeywords: [
                "Python",
                "NLP",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Intent Classification",
                    recommendation: "Specify classification accuracy.",
                    placeholderTemplate: "Elevated intent recognition accuracy by 8.4% on noisy audio inputs."
                ),
            ]
        ),
        Opportunity(
            id: "opp-amazon-28",
            companyName: "Amazon",
            companySymbol: "cart.fill",
            roleTitle: "Frontend Engineer Intern - Prime Video",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 82,
            recency: "1d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.amazon.com",
            aboutRole: "Build dynamic, high-performance web and smart TV viewing experiences delivering seamless 4K HDR playback and X-Ray metadata.",
            minimumQualifications: [
                "Solid proficiency in JavaScript, TypeScript, React, and CSS architecture.",
                "Understanding of browser rendering pipelines, Web Workers, and media source extensions.",
            ],
            preferredQualifications: [
                "Experience with video streaming protocols (HLS / DASH).",
            ],
            applicantTips: [
                "Highlight memory leak debugging and DOM minimization.",
            ],
            responsibilities: [
                "Implement responsive TV and web interfaces with accessible keyboard navigation.",
                "Profile bundle size and memory usage on constrained TV hardware.",
            ],
            skills: [
                "TypeScript",
                "React",
                "Video Streaming",
                "Web Performance",
                "CSS",
                "HTML5",
            ],
            detectedKeywords: [
                "TypeScript",
                "React",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Web Performance",
                    recommendation: "State bundle size reduction metric.",
                    placeholderTemplate: "Decreased initial page bundle size by 30% through dynamic code-splitting."
                ),
            ]
        ),
        Opportunity(
            id: "opp-amazon-29",
            companyName: "Amazon",
            companySymbol: "cart.fill",
            roleTitle: "Operations Tech Intern",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹70k - ₹95k / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 82,
            recency: "3d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.amazon.com",
            aboutRole: "Build automated computer vision robotics tracking and barcode telemetry systems across automated fulfillment centers.",
            minimumQualifications: [
                "Degree in CS, Mechanical, or Robotics Engineering.",
                "Experience in Python, OpenCV, and IoT sensor integration.",
            ],
            preferredQualifications: [
                "Familiarity with ROS (Robot Operating System) or automated guided vehicles.",
            ],
            applicantTips: [
                "Detail real-world sensor integration projects.",
            ],
            responsibilities: [
                "Deploy edge image classification models on industrial cameras.",
                "Track item routing anomalies across automated conveyor networks.",
            ],
            skills: [
                "Python",
                "OpenCV",
                "Computer Vision",
                "Robotics",
                "IoT",
                "Edge Devices",
            ],
            detectedKeywords: [
                "Python",
                "Computer Vision",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Computer Vision",
                    recommendation: "State detection accuracy or speed.",
                    placeholderTemplate: "Achieved 99.4% package barcode detection accuracy at 60 fps."
                ),
            ]
        ),
        Opportunity(
            id: "opp-netflix-30",
            companyName: "Netflix",
            companySymbol: "tv.fill",
            roleTitle: "Distributed Systems Intern",
            location: "Mumbai, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹90k - ₹1.3L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 80,
            recency: "4h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.netflix.com",
            aboutRole: "Engineer high-availability edge traffic proxying and Open Connect content delivery network services serving 250M+ global members.",
            minimumQualifications: [
                "CS/IT degree candidate graduating in 2027-2028.",
                "Proficiency in Java, Go, or C++.",
                "Deep understanding of HTTP/3, TLS termination, and TCP congestion algorithms.",
            ],
            preferredQualifications: [
                "Knowledge of Envoy proxy or eBPF network telemetry.",
            ],
            applicantTips: [
                "Demonstrate awareness of fault tolerance and chaos engineering.",
            ],
            responsibilities: [
                "Write resilient microservices running across global cloud zones.",
                "Conduct chaos testing simulating sudden AWS availability zone outages.",
            ],
            skills: [
                "Java",
                "Go",
                "CDN",
                "Distributed Systems",
                "Networking",
                "Chaos Engineering",
            ],
            detectedKeywords: [
                "Go",
                "Distributed Systems",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Fault Tolerance",
                    recommendation: "Describe chaos test result.",
                    placeholderTemplate: "Architected automatic failover routing surviving 100% simulated node outages."
                ),
            ]
        ),
        Opportunity(
            id: "opp-netflix-31",
            companyName: "Netflix",
            companySymbol: "tv.fill",
            roleTitle: "UI/Playback Performance Engineer",
            location: "Mumbai, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.netflix.com",
            aboutRole: "Optimize startup latency, buffer stabilization, and playback smoothness across thousands of distinct device profiles.",
            minimumQualifications: [
                "Proficiency in modern JavaScript/TypeScript, React, and browser internals.",
                "Understanding of adaptive bitrate streaming (ABR) and video codecs.",
            ],
            preferredQualifications: [
                "Experience profiling CPU time and layout reflows in Chrome DevTools.",
            ],
            applicantTips: [
                "Show quantitative time-to-first-frame reductions.",
            ],
            responsibilities: [
                "Diagnose playback stutter events and tune buffer refill thresholds.",
                "Build real-time client metric telemetry for playback quality.",
            ],
            skills: [
                "JavaScript",
                "TypeScript",
                "React",
                "Video Streaming",
                "Performance Profiling",
            ],
            detectedKeywords: [
                "JavaScript",
                "TypeScript",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Startup Latency",
                    recommendation: "State playback start time improvement.",
                    placeholderTemplate: "Trimmed media playback initiation delay by 320ms across low-bandwidth connections."
                ),
            ]
        ),
        Opportunity(
            id: "opp-netflix-32",
            companyName: "Netflix",
            companySymbol: "tv.fill",
            roleTitle: "Machine Learning Recommendation Intern",
            location: "Mumbai, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹95k - ₹1.35L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 75,
            recency: "3d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.netflix.com",
            aboutRole: "Design hyper-personalized homepage row ranking, thumbnail personalization, and contextual bandit algorithms.",
            minimumQualifications: [
                "Strong foundation in collaborative filtering, deep recommender models, and reinforcement learning.",
                "Proficiency in Python, PyTorch, and Spark.",
            ],
            preferredQualifications: [
                "Experience running online A/B experiments.",
            ],
            applicantTips: [
                "Highlight ranking evaluation metrics: NDCG, MRR, CTR.",
            ],
            responsibilities: [
                "Train two-tower neural retrieval models for candidate generation.",
                "Deploy real-time bandit rankers optimizing member title discovery.",
            ],
            skills: [
                "Python",
                "PyTorch",
                "Recommender Systems",
                "Spark",
                "A/B Testing",
                "Machine Learning",
            ],
            detectedKeywords: [
                "Python",
                "Machine Learning",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Recommender Systems",
                    recommendation: "State ranking lift metric.",
                    placeholderTemplate: "Elevated recommendation NDCG@10 by 7.2% utilizing two-tower embedding retrieval."
                ),
            ]
        ),
        Opportunity(
            id: "opp-uber-33",
            companyName: "Uber",
            companySymbol: "car.fill",
            roleTitle: "SDE Intern - Core Rider",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 90,
            recency: "3h ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: true,
            applicationDate: "33 days ago",
            externalCareersURL: "https://careers.uber.com",
            aboutRole: "Build geospatial dispatch algorithms and pricing pipelines coordinating millions of concurrent rides and deliveries.",
            minimumQualifications: [
                "CS/IT degree student graduating in 2027-2028.",
                "Proficiency in Go, Java, or Python.",
                "Solid understanding of geospatial indexing (H3 / S2), concurrency, and Redis.",
            ],
            preferredQualifications: [
                "Experience building microservices with high concurrent traffic.",
            ],
            applicantTips: [
                "Discuss geospatial partitioning and low-latency locking.",
            ],
            responsibilities: [
                "Implement routing microservices handling real-time driver coordinates.",
                "Optimize spatial queries to calculate ETAs in under 10 milliseconds.",
            ],
            skills: [
                "Go",
                "Java",
                "Geospatial",
                "H3",
                "Redis",
                "Kafka",
                "Microservices",
            ],
            detectedKeywords: [
                "Go",
                "Redis",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Spatial Indexing",
                    recommendation: "Explain spatial query speedup.",
                    placeholderTemplate: "Indexed geospatial telemetry with Uber H3 reducing query execution time by 44%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-uber-34",
            companyName: "Uber",
            companySymbol: "car.fill",
            roleTitle: "Data Engineer Intern - Marketplace Routing",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 83,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.uber.com",
            aboutRole: "Build scalable data pipelines processing petabytes of real-time GPS traces, surge pricing events, and driver metrics.",
            minimumQualifications: [
                "Strong SQL, Python, and Apache Spark / Flink proficiency.",
                "Understanding of data lakehouses, Delta Lake, and dimensional modeling.",
            ],
            preferredQualifications: [
                "Hands-on experience with Kafka streaming and schema registries.",
            ],
            applicantTips: [
                "Highlight streaming window aggregations and backfill performance.",
            ],
            responsibilities: [
                "Develop low-latency stream processing pipelines in Apache Flink.",
                "Create standardized data marts for marketplace analytics teams.",
            ],
            skills: [
                "SQL",
                "Python",
                "Apache Spark",
                "Apache Flink",
                "Kafka",
                "Data Lakehouse",
            ],
            detectedKeywords: [
                "SQL",
                "Python",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Streaming Aggregation",
                    recommendation: "Quantify stream throughput.",
                    placeholderTemplate: "Processed 50,000+ events per second with sub-second latency in Apache Flink."
                ),
            ]
        ),
        Opportunity(
            id: "opp-uber-35",
            companyName: "Uber",
            companySymbol: "car.fill",
            roleTitle: "Android Engineer Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 89,
            recency: "2d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.uber.com",
            aboutRole: "Build battery-efficient, reliable location tracking and animated map overlays on the Uber Driver and Rider applications.",
            minimumQualifications: [
                "Proficiency in Kotlin, Coroutines, and Android Location APIs.",
                "Understanding of custom canvas drawing, vector animation, and clean architecture.",
            ],
            preferredQualifications: [
                "Experience with background work managers and memory optimization.",
            ],
            applicantTips: [
                "Discuss location jitter smoothing and battery conservation.",
            ],
            responsibilities: [
                "Implement smooth driver vehicle animations on Google Maps SDK.",
                "Tune location sampling frequencies to conserve driver device battery.",
            ],
            skills: [
                "Kotlin",
                "Android",
                "Coroutines",
                "Google Maps SDK",
                "Location Services",
            ],
            detectedKeywords: [
                "Kotlin",
                "Android",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Location Optimization",
                    recommendation: "Detail battery drain reduction.",
                    placeholderTemplate: "Optimized fused location polling reducing background battery consumption by 18%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-airbnb-36",
            companyName: "Airbnb",
            companySymbol: "house.fill",
            roleTitle: "Software Engineer - Guest Experience",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 81,
            recency: "2h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.airbnb.com",
            aboutRole: "Develop immersive search, listing photo tours, and instant booking flows across Airbnb web and mobile platforms.",
            minimumQualifications: [
                "Proficiency in Java, Kotlin, or TypeScript/React.",
                "Strong grasp of component architecture, state management, and API design.",
            ],
            preferredQualifications: [
                "Experience with GraphQL schema design and microservices.",
            ],
            applicantTips: [
                "Showcase attention to user empathy and design system adherence.",
            ],
            responsibilities: [
                "Build accessible, responsive booking and search UI components.",
                "Design robust GraphQL queries with normalized client caching.",
            ],
            skills: [
                "Java",
                "Kotlin",
                "TypeScript",
                "React",
                "GraphQL",
                "UI Components",
            ],
            detectedKeywords: [
                "TypeScript",
                "React",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "GraphQL Optimization",
                    recommendation: "State payload size reduction.",
                    placeholderTemplate: "Consolidated multiple REST calls into a single GraphQL query trimming network payload by 38%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-airbnb-37",
            companyName: "Airbnb",
            companySymbol: "house.fill",
            roleTitle: "Design Systems Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "Design students",
            eligibleGradYears: "2027 – 2028",
            matchScore: 86,
            recency: "1d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.airbnb.com",
            aboutRole: "Contribute to Airbnb's world-renowned Design Language System (DLS), ensuring pixel-perfection, WCAG AAA accessibility, and dark mode consistency.",
            minimumQualifications: [
                "Pursuing Design, HCI, or related field.",
                "Mastery of Figma variables, auto-layout, and token architecture.",
                "Understanding of accessibility guidelines.",
            ],
            preferredQualifications: [
                "Familiarity with React or SwiftUI component implementation.",
            ],
            applicantTips: [
                "Demonstrate multi-platform component token governance.",
            ],
            responsibilities: [
                "Design atomic components and tokens used across iOS, Android, and Web.",
                "Conduct accessibility audits ensuring screen reader compliance.",
            ],
            skills: [
                "Figma",
                "Design Systems",
                "Accessibility (a11y)",
                "Design Tokens",
                "UI Design",
            ],
            detectedKeywords: [
                "Figma",
                "Design Systems",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Accessibility Audit",
                    recommendation: "Add WCAG compliance metric.",
                    placeholderTemplate: "Audited 40+ core components ensuring 100% WCAG 2.1 AA accessibility compliance."
                ),
            ]
        ),
        Opportunity(
            id: "opp-airbnb-38",
            companyName: "Airbnb",
            companySymbol: "house.fill",
            roleTitle: "Backend Engineer - Payments",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹90k - ₹1.25L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 84,
            recency: "3d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.airbnb.com",
            aboutRole: "Build idempotent, secure multi-currency payment checkout and host payout engines operating across 190+ countries.",
            minimumQualifications: [
                "Strong foundation in Java or Kotlin.",
                "Understanding of double-entry ledger systems, ACID transactions, and idempotency keys.",
            ],
            preferredQualifications: [
                "Experience with relational databases (MySQL / PostgreSQL) and message queues.",
            ],
            applicantTips: [
                "Emphasize zero-data-loss guarantees and distributed locking.",
            ],
            responsibilities: [
                "Implement secure payment gateway integrations with automated retry backoffs.",
                "Design audit logs ensuring financial compliance.",
            ],
            skills: [
                "Java",
                "Kotlin",
                "MySQL",
                "Idempotency",
                "Payments",
                "Distributed Transactions",
            ],
            detectedKeywords: [
                "Java",
                "MySQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Idempotency",
                    recommendation: "Describe duplicate payment prevention.",
                    placeholderTemplate: "Implemented Redis distributed lock and idempotency keys preventing duplicate charge transactions."
                ),
            ]
        ),
        Opportunity(
            id: "opp-spotify-39",
            companyName: "Spotify",
            companySymbol: "music.note",
            roleTitle: "Mobile Engineer Intern - Audio Player",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 92,
            recency: "5h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.spotify.com",
            aboutRole: "Work on Spotify's core playback engine, lossless audio decoding, and offline caching across millions of iOS and Android devices.",
            minimumQualifications: [
                "Proficiency in Swift (iOS) or Kotlin (Android), and familiarity with C++.",
                "Understanding of audio buffering, memory caching, and low-latency threads.",
            ],
            preferredQualifications: [
                "Experience with CoreAudio or Android ExoPlayer.",
            ],
            applicantTips: [
                "Detail background audio lifecycle and buffer underrun prevention.",
            ],
            responsibilities: [
                "Implement seamless crossfade transitions between audio tracks.",
                "Optimize offline song storage indexing to minimize disk I/O.",
            ],
            skills: [
                "Swift",
                "Kotlin",
                "C++",
                "Audio Streaming",
                "CoreAudio",
                "ExoPlayer",
            ],
            detectedKeywords: [
                "Swift",
                "Kotlin",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Audio Buffering",
                    recommendation: "Quantify buffer underrun metric.",
                    placeholderTemplate: "Tuned adaptive lookahead audio buffer eliminating playback underruns by 99.2%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-spotify-40",
            companyName: "Spotify",
            companySymbol: "music.note",
            roleTitle: "Data Scientist - Discover Weekly",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.25L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 78,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.spotify.com",
            aboutRole: "Develop graph embedding algorithms and acoustic signal analysis to surface undiscovered indie artists in personalized playlists.",
            minimumQualifications: [
                "Strong statistics and machine learning background.",
                "Proficiency in Python, PyTorch, and BigQuery / SQL.",
            ],
            preferredQualifications: [
                "Experience with graph neural networks (GNNs) or audio spectrogram embeddings.",
            ],
            applicantTips: [
                "Discuss evaluation of serendipity vs familiarity trade-offs.",
            ],
            responsibilities: [
                "Model user music listening co-occurrence graphs using Node2Vec.",
                "Analyze member retention curves across recommended playlist variants.",
            ],
            skills: [
                "Python",
                "PyTorch",
                "SQL",
                "Graph Embeddings",
                "Recommender Systems",
                "Audio ML",
            ],
            detectedKeywords: [
                "Python",
                "SQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Graph Modeling",
                    recommendation: "Detail graph scale and lift.",
                    placeholderTemplate: "Trained graph embedding over 10M+ artist nodes increasing discovery diversity by 14%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-spotify-41",
            companyName: "Spotify",
            companySymbol: "music.note",
            roleTitle: "Backend Engineer - Streaming Infra",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 90,
            recency: "2d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.spotify.com",
            aboutRole: "Build resilient microservices serving billions of metadata queries and managing live lyrics synchronization.",
            minimumQualifications: [
                "Proficiency in Java, Go, or Python.",
                "Understanding of gRPC, protocol buffers, and distributed caching.",
            ],
            preferredQualifications: [
                "Experience building event-driven systems using Apache Kafka.",
            ],
            applicantTips: [
                "Highlight sub-millisecond p99 latency SLA maintenance.",
            ],
            responsibilities: [
                "Write gRPC services with client-side load balancing.",
                "Build automated health checks for high-throughput metadata nodes.",
            ],
            skills: [
                "Java",
                "Go",
                "gRPC",
                "Kafka",
                "Microservices",
                "Distributed Caching",
            ],
            detectedKeywords: [
                "Go",
                "Java",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "gRPC Performance",
                    recommendation: "Mention p99 response time.",
                    placeholderTemplate: "Optimized serialization formats achieving 8ms p99 latency across 10,000 QPS."
                ),
            ]
        ),
        Opportunity(
            id: "opp-stripe-42",
            companyName: "Stripe",
            companySymbol: "creditcard.fill",
            roleTitle: "Software Engineer Intern - Payments Infrastructure",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹95k - ₹1.4L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "1h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.stripe.com",
            aboutRole: "Architect the core payments engine processing billions of dollars daily with five-nines (99.999%) availability.",
            minimumQualifications: [
                "Pursuing Computer Science or related degree graduating in 2027-2028.",
                "Proficiency in Ruby, Java, Go, or Python.",
                "Deep appreciation for correctness, type systems, and fault-tolerance.",
            ],
            preferredQualifications: [
                "Experience with distributed databases (Spanner, CockroachDB).",
            ],
            applicantTips: [
                "Demonstrate obsession with code reliability, testing, and error handling.",
            ],
            responsibilities: [
                "Design robust, self-healing payment gateway adapters.",
                "Write comprehensive unit, integration, and fuzz testing suites.",
            ],
            skills: [
                "Ruby",
                "Go",
                "Java",
                "Distributed Systems",
                "Payments",
                "SQL",
                "Testing",
            ],
            detectedKeywords: [
                "Go",
                "Java",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Fault Tolerance",
                    recommendation: "Add test coverage and resilience metric.",
                    placeholderTemplate: "Implemented automated fuzz testing catching 12 edge cases before production deploy."
                ),
            ]
        ),
        Opportunity(
            id: "opp-stripe-43",
            companyName: "Stripe",
            companySymbol: "creditcard.fill",
            roleTitle: "Developer Productivity Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "1d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.stripe.com",
            aboutRole: "Build ultra-fast remote build caches, static analysis linters, and developer environment tooling used by thousands of Stripe engineers.",
            minimumQualifications: [
                "Proficiency in Go, Rust, or Python.",
                "Understanding of compilers, abstract syntax trees (AST), and CI/CD pipelines.",
            ],
            preferredQualifications: [
                "Experience with Bazel, Docker, or Monorepo toolchains.",
            ],
            applicantTips: [
                "Highlight build duration reductions and caching efficiencies.",
            ],
            responsibilities: [
                "Optimize Bazel remote cache hit rates across automated CI runs.",
                "Build custom linter plugins to enforce internal API safety conventions.",
            ],
            skills: [
                "Go",
                "Rust",
                "Bazel",
                "CI/CD",
                "Developer Tools",
                "Static Analysis",
            ],
            detectedKeywords: [
                "Go",
                "Python",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Build Optimization",
                    recommendation: "Specify build time reduction.",
                    placeholderTemplate: "Optimized monorepo test caching trimming average CI runtime by 45%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-stripe-44",
            companyName: "Stripe",
            companySymbol: "creditcard.fill",
            roleTitle: "Security & Risk Analyst Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 72,
            recency: "3d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: true,
            applicationDate: "44 days ago",
            externalCareersURL: "https://careers.stripe.com",
            aboutRole: "Develop machine learning models and automated rules detecting card-testing fraud, account takeovers, and synthetic identities in real-time.",
            minimumQualifications: [
                "Strong analytical background with Python and SQL.",
                "Knowledge of anomaly detection, random forests, and gradient boosting (XGBoost).",
            ],
            preferredQualifications: [
                "Familiarity with financial crime compliance and risk operations.",
            ],
            applicantTips: [
                "Highlight false positive rate reductions and precision metrics.",
            ],
            responsibilities: [
                "Train real-time scoring models evaluating incoming transaction risk.",
                "Investigate coordinated card-testing fraud rings and deploy counter-measures.",
            ],
            skills: [
                "Python",
                "Machine Learning",
                "XGBoost",
                "Fraud Detection",
                "SQL",
                "Risk Analytics",
            ],
            detectedKeywords: [
                "Python",
                "SQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Fraud Detection",
                    recommendation: "State precision and false positive rate.",
                    placeholderTemplate: "Reduced false-positive fraud declines by 19% while preserving 99.8% detection coverage."
                ),
            ]
        ),
        Opportunity(
            id: "opp-atlassian-45",
            companyName: "Atlassian",
            companySymbol: "arrow.triangle.branch",
            roleTitle: "Software Engineer Intern - Jira Cloud",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 89,
            recency: "4h ago",
            cardColor: AlineTheme.cardSkyBlue,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.atlassian.com",
            aboutRole: "Build real-time board sync, automation rules, and collaborative task tracking in Jira Cloud.",
            minimumQualifications: [
                "CS/IT degree candidate graduating in 2027-2028.",
                "Proficiency in Java, Kotlin, or TypeScript/React.",
                "Understanding of RESTful APIs, distributed caching, and relational databases.",
            ],
            preferredQualifications: [
                "Experience with AWS cloud infrastructure.",
            ],
            applicantTips: [
                "Discuss state synchronization and optimistic UI updates.",
            ],
            responsibilities: [
                "Implement optimistic client updates for drag-and-drop board columns.",
                "Write scalable backend service APIs handling millions of issue transitions.",
            ],
            skills: [
                "Java",
                "Kotlin",
                "TypeScript",
                "React",
                "AWS",
                "Jira",
            ],
            detectedKeywords: [
                "Java",
                "TypeScript",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Optimistic Updates",
                    recommendation: "Detail perceived latency improvement.",
                    placeholderTemplate: "Implemented optimistic UI rendering eliminating perceived drag-and-drop delay."
                ),
            ]
        ),
        Opportunity(
            id: "opp-atlassian-46",
            companyName: "Atlassian",
            companySymbol: "arrow.triangle.branch",
            roleTitle: "Full Stack Intern - Confluence",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 80,
            recency: "1d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.atlassian.com",
            aboutRole: "Advance collaborative real-time rich-text document editing, live cursors, and AI summarizing features.",
            minimumQualifications: [
                "Proficiency in modern TypeScript, React, and Java.",
                "Understanding of operational transforms (OT) or CRDTs for collaborative editing.",
            ],
            preferredQualifications: [
                "Hands-on experience with Prosemirror or rich text frameworks.",
            ],
            applicantTips: [
                "Showcase understanding of conflict resolution in document state.",
            ],
            responsibilities: [
                "Build real-time editor plugins for document templates.",
                "Optimize editor bundle load time and input typing latency.",
            ],
            skills: [
                "TypeScript",
                "React",
                "Java",
                "CRDTs",
                "Rich Text",
                "WebSockets",
            ],
            detectedKeywords: [
                "TypeScript",
                "React",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Collaborative Editing",
                    recommendation: "Describe conflict resolution design.",
                    placeholderTemplate: "Engineered CRDT syncing handling concurrent edits across 20+ simultaneous users."
                ),
            ]
        ),
        Opportunity(
            id: "opp-atlassian-47",
            companyName: "Atlassian",
            companySymbol: "arrow.triangle.branch",
            roleTitle: "Site Reliability Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "2d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.atlassian.com",
            aboutRole: "Maintain high availability, automated rollback pipelines, and observability metrics across Atlassian Cloud.",
            minimumQualifications: [
                "Understanding of Linux, networking, Docker, and Kubernetes.",
                "Proficiency in Python or Go for infrastructure automation.",
            ],
            preferredQualifications: [
                "Experience with Prometheus, Grafana, or OpenTelemetry.",
            ],
            applicantTips: [
                "Highlight Mean Time To Recovery (MTTR) improvements.",
            ],
            responsibilities: [
                "Build automated alert routing and anomaly detection monitors.",
                "Implement canary deployment analysis pipelines.",
            ],
            skills: [
                "Kubernetes",
                "Docker",
                "Python",
                "Go",
                "Observability",
                "Prometheus",
            ],
            detectedKeywords: [
                "Python",
                "Docker",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Observability",
                    recommendation: "State alert noise reduction.",
                    placeholderTemplate: "Refined alerting thresholds reducing pager noise by 35% while retaining critical breach alerts."
                ),
            ]
        ),
        Opportunity(
            id: "opp-adobe-48",
            companyName: "Adobe",
            companySymbol: "a.circle.fill",
            roleTitle: "Computer Vision & AI Intern - Photoshop",
            location: "Noida, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 83,
            recency: "3h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.adobe.com",
            aboutRole: "Develop neural segmentation, generative inpainting, and edge-preserving filter algorithms for Adobe Photoshop and Firefly.",
            minimumQualifications: [
                "Pursuing CS/EE degree with computer vision focus.",
                "Proficiency in C++ and Python.",
                "Familiarity with diffusion models, OpenCV, and GPU shaders.",
            ],
            preferredQualifications: [
                "Publications or demos in computer vision or computational photography.",
            ],
            applicantTips: [
                "Detail algorithmic acceleration with SIMD or CUDA.",
            ],
            responsibilities: [
                "Implement multi-scale edge detection and semantic subject selection.",
                "Accelerate neural network inference using TensorRT and ONNX.",
            ],
            skills: [
                "C++",
                "Python",
                "Computer Vision",
                "OpenCV",
                "Diffusion Models",
                "CUDA",
            ],
            detectedKeywords: [
                "C++",
                "Python",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Computer Vision",
                    recommendation: "Quantify segmentation accuracy.",
                    placeholderTemplate: "Accelerated image mask segmentation by 3.2x using optimized SIMD operations."
                ),
            ]
        ),
        Opportunity(
            id: "opp-adobe-49",
            companyName: "Adobe",
            companySymbol: "a.circle.fill",
            roleTitle: "Web Platform Intern - Acrobat Web",
            location: "Noida, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.adobe.com",
            aboutRole: "Bring high-fidelity PDF rendering, annotation engines, and e-signatures to the modern web browser using WebAssembly.",
            minimumQualifications: [
                "Strong foundation in JavaScript/TypeScript and C/C++.",
                "Familiarity with WebAssembly (Wasm) and HTML5 Canvas API.",
            ],
            preferredQualifications: [
                "Experience debugging memory footprints in high-density web documents.",
            ],
            applicantTips: [
                "Highlight cross-platform rendering fidelity and font rasterization.",
            ],
            responsibilities: [
                "Compile native PDF parsing algorithms to WebAssembly.",
                "Build responsive UI for PDF markups and digital signatures.",
            ],
            skills: [
                "WebAssembly",
                "C++",
                "TypeScript",
                "React",
                "Canvas API",
                "Web Platform",
            ],
            detectedKeywords: [
                "TypeScript",
                "C++",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "WebAssembly",
                    recommendation: "State memory or rendering speedup.",
                    placeholderTemplate: "Compiled PDF rendering engine to Wasm delivering 60fps scrolling on large documents."
                ),
            ]
        ),
        Opportunity(
            id: "opp-adobe-50",
            companyName: "Adobe",
            companySymbol: "a.circle.fill",
            roleTitle: "Creative Cloud iOS Engineer",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 79,
            recency: "3d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.adobe.com",
            aboutRole: "Build Apple Pencil pressure-sensitive drawing pipelines and layer management on Photoshop & Illustrator for iPad.",
            minimumQualifications: [
                "Proficiency in Swift and Apple Pencil APIs (UIEvent.touches).",
                "Understanding of Metal graphics shaders and low-latency touch response.",
            ],
            preferredQualifications: [
                "Experience building drawing or creative apps on iOS.",
            ],
            applicantTips: [
                "Highlight touch latency reduction and stroke smoothing.",
            ],
            responsibilities: [
                "Optimize custom Metal render passes for layered vector canvas.",
                "Implement undo/redo transaction buffers with low memory overhead.",
            ],
            skills: [
                "Swift",
                "Metal",
                "iOS",
                "Apple Pencil",
                "Graphics Programming",
            ],
            detectedKeywords: [
                "Swift",
                "Metal",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Touch Latency",
                    recommendation: "Detail Apple Pencil latency.",
                    placeholderTemplate: "Reduced stylus drawing latency to sub-9ms using predictive touch APIs."
                ),
            ]
        ),
        Opportunity(
            id: "opp-salesforce-51",
            companyName: "Salesforce",
            companySymbol: "cloud.fill",
            roleTitle: "Software Development Intern - Einstein AI",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "2h ago",
            cardColor: AlineTheme.cardSkyBlue,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.salesforce.com",
            aboutRole: "Build conversational enterprise CRM intelligence, automated lead scoring, and workflow summarization agents.",
            minimumQualifications: [
                "Enrolled in Computer Science or IT degree graduating in 2027-2028.",
                "Proficiency in Java, Python, or Apex.",
                "Understanding of machine learning principles and RESTful APIs.",
            ],
            preferredQualifications: [
                "Experience with LLM orchestration frameworks (LangChain / LlamaIndex).",
            ],
            applicantTips: [
                "Emphasize enterprise security and multi-tenant data isolation.",
            ],
            responsibilities: [
                "Integrate LLM API gateways with prompt governance safeguards.",
                "Build microservices calculating real-time sales predictive metrics.",
            ],
            skills: [
                "Java",
                "Python",
                "Machine Learning",
                "Enterprise CRM",
                "REST APIs",
                "Cloud",
            ],
            detectedKeywords: [
                "Java",
                "Python",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "AI Integration",
                    recommendation: "Explain prompt safety and accuracy.",
                    placeholderTemplate: "Designed LLM prompt routing layer with automated PII masking protecting sensitive customer data."
                ),
            ]
        ),
        Opportunity(
            id: "opp-salesforce-52",
            companyName: "Salesforce",
            companySymbol: "cloud.fill",
            roleTitle: "Cloud Platform Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 84,
            recency: "1d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.salesforce.com",
            aboutRole: "Develop multi-tenant database infrastructure and distributed transaction engines running on Hyperforce.",
            minimumQualifications: [
                "Strong foundation in Java, Go, and database internals.",
                "Understanding of tenant routing, read-replicas, and connection poolers.",
            ],
            preferredQualifications: [
                "Experience with AWS or public cloud infrastructure.",
            ],
            applicantTips: [
                "Highlight multi-tenant isolation and connection pooling.",
            ],
            responsibilities: [
                "Implement connection pool managers reducing database socket starvation.",
                "Write automated stress tests simulating peak enterprise loads.",
            ],
            skills: [
                "Java",
                "Go",
                "AWS",
                "Databases",
                "Multi-Tenancy",
                "Distributed Systems",
            ],
            detectedKeywords: [
                "Java",
                "Databases",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Database Scaling",
                    recommendation: "State connection pool efficiency.",
                    placeholderTemplate: "Optimized database connection pooling preventing socket starvation under 5,000 concurrent tenant connections."
                ),
            ]
        ),
        Opportunity(
            id: "opp-salesforce-53",
            companyName: "Salesforce",
            companySymbol: "cloud.fill",
            roleTitle: "UX Research Intern",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹70k - ₹95k / mo",
            experienceYears: "Design students",
            eligibleGradYears: "2027 – 2028",
            matchScore: 83,
            recency: "2d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.salesforce.com",
            aboutRole: "Conduct qualitative and quantitative research uncovering usability barriers in complex enterprise admin dashboards.",
            minimumQualifications: [
                "Pursuing Human-Computer Interaction, Design, or Psychology degree.",
                "Skill in conducting user interviews, card sorting, and surveys.",
            ],
            preferredQualifications: [
                "Familiarity with Figma and usability benchmarking.",
            ],
            applicantTips: [
                "Present synthesized user journey maps and actionable UX recommendations.",
            ],
            responsibilities: [
                "Plan and execute usability testing sessions with enterprise admins.",
                "Synthesize research findings into actionable design enhancements.",
            ],
            skills: [
                "User Research",
                "HCI",
                "Usability Testing",
                "Figma",
                "User Journey",
                "Analytics",
            ],
            detectedKeywords: [
                "User Research",
                "Figma",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Usability Testing",
                    recommendation: "Detail metric improved.",
                    placeholderTemplate: "Identified 4 critical workflow bottlenecks in navigation reducing task completion time by 28%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-linkedin-54",
            companyName: "LinkedIn",
            companySymbol: "link.circle.fill",
            roleTitle: "Machine Learning Intern - Feed Ranking",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹90k - ₹1.3L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 82,
            recency: "3h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.linkedin.com",
            aboutRole: "Train high-throughput deep neural ranking networks predicting user engagement, viral post distribution, and creator growth.",
            minimumQualifications: [
                "Solid foundation in machine learning, statistics, and ranking metrics.",
                "Proficiency in Python, Java, or C++, and PyTorch / TensorFlow.",
            ],
            preferredQualifications: [
                "Familiarity with graph neural networks or multi-task learning.",
            ],
            applicantTips: [
                "Discuss CTR/dwell time optimization and exploration vs exploitation trade-offs.",
            ],
            responsibilities: [
                "Train multi-task neural networks balancing comments, shares, and reactions.",
                "Deploy feature store transformations evaluating thousands of real-time signals.",
            ],
            skills: [
                "Python",
                "PyTorch",
                "Recommender Systems",
                "Deep Learning",
                "Machine Learning",
                "Java",
            ],
            detectedKeywords: [
                "Python",
                "Machine Learning",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Ranking Lift",
                    recommendation: "Detail engagement metric lift.",
                    placeholderTemplate: "Elevated feed engagement CTR by 6.4% utilizing multi-task neural loss functions."
                ),
            ]
        ),
        Opportunity(
            id: "opp-linkedin-55",
            companyName: "LinkedIn",
            companySymbol: "link.circle.fill",
            roleTitle: "SDE Intern - Member Graph",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 90,
            recency: "1d ago",
            cardColor: AlineTheme.cardSkyBlue,
            isLiked: false,
            isApplied: true,
            applicationDate: "55 days ago",
            externalCareersURL: "https://careers.linkedin.com",
            aboutRole: "Architect the massive distributed social graph mapping 1 billion professional members, companies, and skill connections.",
            minimumQualifications: [
                "Proficiency in Java or C++.",
                "Deep understanding of graph traversal algorithms (BFS, Dijkstra), caching, and distributed storage.",
            ],
            preferredQualifications: [
                "Experience with graph databases or distributed key-value stores.",
            ],
            applicantTips: [
                "Highlight distributed cache consistency and traversal performance.",
            ],
            responsibilities: [
                "Implement low-latency 2nd and 3rd degree connection lookup services.",
                "Optimize graph cache eviction to handle viral profile spikes.",
            ],
            skills: [
                "Java",
                "Distributed Systems",
                "Graph Algorithms",
                "Caching",
                "Key-Value Stores",
            ],
            detectedKeywords: [
                "Java",
                "Graph Algorithms",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Graph Traversal",
                    recommendation: "Mention query latency improvement.",
                    placeholderTemplate: "Optimized multi-hop graph neighbor traversal reducing p95 latency from 45ms to 12ms."
                ),
            ]
        ),
        Opportunity(
            id: "opp-linkedin-56",
            companyName: "LinkedIn",
            companySymbol: "link.circle.fill",
            roleTitle: "Backend Systems Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 76,
            recency: "3d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.linkedin.com",
            aboutRole: "Build scalable asynchronous message queues, notification pipelines, and Kafka stream processing jobs.",
            minimumQualifications: [
                "Proficiency in Java or Go.",
                "Strong understanding of distributed messaging, consumer groups, and idempotency.",
            ],
            preferredQualifications: [
                "Hands-on experience with Apache Kafka, Samza, or Flink.",
            ],
            applicantTips: [
                "Emphasize exactly-once processing semantics and backpressure management.",
            ],
            responsibilities: [
                "Build notification dispatcher services capable of delivering millions of alerts per minute.",
                "Monitor and tune Kafka consumer lag.",
            ],
            skills: [
                "Java",
                "Kafka",
                "Distributed Messaging",
                "Streaming",
                "Microservices",
            ],
            detectedKeywords: [
                "Java",
                "Kafka",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Kafka Processing",
                    recommendation: "Specify throughput handled.",
                    placeholderTemplate: "Processed 100M+ daily notifications with zero message duplication using Kafka exactly-once semantics."
                ),
            ]
        ),
        Opportunity(
            id: "opp-github-57",
            companyName: "GitHub",
            companySymbol: "chevron.left.forwardslash.chevron.right",
            roleTitle: "Software Engineer Intern - Copilot Systems",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹95k - ₹1.35L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 95,
            recency: "2h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.github.com",
            aboutRole: "Engineer the high-speed code completion and context synthesis infrastructure powering GitHub Copilot for millions of developers.",
            minimumQualifications: [
                "Proficiency in Ruby, Go, TypeScript, or Rust.",
                "Understanding of tokenization, prompt assembly, and low-latency API proxying.",
            ],
            preferredQualifications: [
                "Familiarity with Language Server Protocol (LSP) and tree-sitter AST parsing.",
            ],
            applicantTips: [
                "Detail token latency budgets and streaming response times.",
            ],
            responsibilities: [
                "Build tree-sitter AST context extractors providing relevant code snippets to models.",
                "Implement streaming WebSocket endpoints delivering completion tokens in real-time.",
            ],
            skills: [
                "Go",
                "TypeScript",
                "Rust",
                "LLMs",
                "Copilot",
                "Tree-Sitter",
                "Developer Tools",
            ],
            detectedKeywords: [
                "Go",
                "TypeScript",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Context Extraction",
                    recommendation: "Mention latency and accuracy.",
                    placeholderTemplate: "Built tree-sitter AST parser extracting pertinent functions within 15ms latency budget."
                ),
            ]
        ),
        Opportunity(
            id: "opp-github-58",
            companyName: "GitHub",
            companySymbol: "chevron.left.forwardslash.chevron.right",
            roleTitle: "Developer Tools Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "1d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.github.com",
            aboutRole: "Advance GitHub Actions runner pipelines, containerized build environments, and developer CLI tooling.",
            minimumQualifications: [
                "Proficiency in Go, C#, or TypeScript.",
                "Understanding of Linux cgroups, namespaces, and Docker container security.",
            ],
            preferredQualifications: [
                "Experience contributing to CLI tools or open source projects.",
            ],
            applicantTips: [
                "Highlight container isolation and fast build provisioning.",
            ],
            responsibilities: [
                "Build lightweight ephemeral runner agents for GitHub Actions.",
                "Add automated security sandboxing for untrusted workflow execution.",
            ],
            skills: [
                "Go",
                "Docker",
                "Linux Internals",
                "GitHub Actions",
                "CI/CD",
                "Developer Tools",
            ],
            detectedKeywords: [
                "Go",
                "Docker",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Container Sandboxing",
                    recommendation: "Detail security boundary design.",
                    placeholderTemplate: "Implemented rootless Docker container execution protecting host runners against privilege escalation."
                ),
            ]
        ),
        Opportunity(
            id: "opp-github-59",
            companyName: "GitHub",
            companySymbol: "chevron.left.forwardslash.chevron.right",
            roleTitle: "Security Operations Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "2d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.github.com",
            aboutRole: "Enhance secret scanning algorithms and automated dependency vulnerability detection (Dependabot).",
            minimumQualifications: [
                "Understanding of regex optimization, entropy calculation, and token formats.",
                "Proficiency in Go or Python.",
            ],
            preferredQualifications: [
                "Familiarity with Git internals and packfile parsing.",
            ],
            applicantTips: [
                "Discuss reducing false positives in automated secret detection.",
            ],
            responsibilities: [
                "Optimize secret scanning pattern matchers running across millions of Git commits.",
                "Build automated PR alert generation for newly published CVEs.",
            ],
            skills: [
                "Go",
                "Python",
                "Git Internals",
                "Security",
                "Secret Scanning",
                "Vulnerability Analysis",
            ],
            detectedKeywords: [
                "Go",
                "Security",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Secret Scanning",
                    recommendation: "Quantify scan speed or false positive reduction.",
                    placeholderTemplate: "Refined entropy analysis filters reducing false-positive secret alerts by 24% across 1M+ commits."
                ),
            ]
        ),
        Opportunity(
            id: "opp-nvidia-60",
            companyName: "Nvidia",
            companySymbol: "eye.fill",
            roleTitle: "Deep Learning Software Intern - CUDA",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹95k - ₹1.4L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 80,
            recency: "1h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.nvidia.com",
            aboutRole: "Write high-performance GPU compute kernels and optimize collective communication primitives in CUDA, cuBLAS, and NCCL.",
            minimumQualifications: [
                "Pursuing CS, EE, or related degree graduating in 2027-2028.",
                "Strong proficiency in C++ and CUDA programming.",
                "Understanding of GPU hardware architecture (SMs, warps, shared memory).",
            ],
            preferredQualifications: [
                "Experience with tensor core programming or FlashAttention kernels.",
            ],
            applicantTips: [
                "Detail FLOPS utilization and memory coalescing benchmarks.",
            ],
            responsibilities: [
                "Write custom CUDA kernels maximizing tensor core compute density.",
                "Optimize all-reduce communication routines across NVLink interconnects.",
            ],
            skills: [
                "CUDA",
                "C++",
                "GPU Architecture",
                "Deep Learning",
                "High Performance Computing",
                "NCCL",
            ],
            detectedKeywords: [
                "CUDA",
                "C++",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Kernel Optimization",
                    recommendation: "State FLOPS utilization gain.",
                    placeholderTemplate: "Authored custom fused CUDA attention kernel achieving 84% theoretical peak TFLOPS."
                ),
            ]
        ),
        Opportunity(
            id: "opp-nvidia-61",
            companyName: "Nvidia",
            companySymbol: "eye.fill",
            roleTitle: "GPU Systems Architecture Intern",
            location: "Pune, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹90k - ₹1.3L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 91,
            recency: "1d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.nvidia.com",
            aboutRole: "Model and simulate next-generation GPU memory hierarchies, HBM interfaces, and L2 cache coherence protocols.",
            minimumQualifications: [
                "Strong foundation in Computer Architecture, SystemC, or C++ simulation.",
                "Understanding of cache coherence, memory controllers, and bus topologies.",
            ],
            preferredQualifications: [
                "Experience using architectural simulators (gem5 / GPGPU-Sim).",
            ],
            applicantTips: [
                "Detail architectural trade-off evaluations in project reports.",
            ],
            responsibilities: [
                "Simulate memory access patterns under heavy transformer workloads.",
                "Identify memory bus bottlenecks and propose prefetching strategies.",
            ],
            skills: [
                "Computer Architecture",
                "C++",
                "SystemC",
                "gem5",
                "Memory Systems",
                "Hardware Simulation",
            ],
            detectedKeywords: [
                "C++",
                "Computer Architecture",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Hardware Simulation",
                    recommendation: "Describe cache miss reduction.",
                    placeholderTemplate: "Simulated adaptive L2 cache bypass reducing memory bus traffic by 16% on matrix multiply benchmarks."
                ),
            ]
        ),
        Opportunity(
            id: "opp-nvidia-62",
            companyName: "Nvidia",
            companySymbol: "eye.fill",
            roleTitle: "Autonomous Vehicles Perception Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹90k - ₹1.35L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 81,
            recency: "2d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.nvidia.com",
            aboutRole: "Develop real-time 3D object detection, camera-LiDAR sensor fusion, and occupancy grid networks running on NVIDIA DRIVE Orin.",
            minimumQualifications: [
                "Proficiency in Python, C++, and PyTorch.",
                "Understanding of 3D computer vision, point clouds, and object tracking.",
            ],
            preferredQualifications: [
                "Experience deploying models using TensorRT on embedded Jetson/DRIVE platforms.",
            ],
            applicantTips: [
                "Show latency numbers and mAP metrics.",
            ],
            responsibilities: [
                "Train bird's-eye-view (BEV) fusion networks on multi-camera feeds.",
                "Optimize neural network layers using TensorRT for sub-30ms real-time inference.",
            ],
            skills: [
                "Computer Vision",
                "TensorRT",
                "C++",
                "Python",
                "Autonomous Driving",
                "Point Clouds",
            ],
            detectedKeywords: [
                "Python",
                "C++",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Edge Deployment",
                    recommendation: "State inference latency and mAP.",
                    placeholderTemplate: "Converted BEV perception network to INT8 TensorRT achieving 26ms frame latency with zero mAP degradation."
                ),
            ]
        ),
        Opportunity(
            id: "opp-openai-63",
            companyName: "OpenAI",
            companySymbol: "sparkles",
            roleTitle: "Research Intern - Post-Training & RL",
            location: "San Francisco / Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹1.4L - ₹2.0L / mo",
            experienceYears: "B.Tech/M.Tech",
            eligibleGradYears: "2027 – 2028",
            matchScore: 98,
            recency: "Just now",
            cardColor: AlineTheme.cardPeach,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.openai.com",
            aboutRole: "Advance frontier reinforcement learning from human and AI feedback (RLHF/RLAIF) to improve reasoning and safety across next-generation models.",
            minimumQualifications: [
                "Pursuing CS, Mathematics, or AI degree.",
                "Deep mathematical and practical mastery of reinforcement learning (PPO, DPO, rejection sampling).",
                "Proficiency in PyTorch and large distributed clusters.",
            ],
            preferredQualifications: [
                "Strong track record of open source ML contributions or competitive programming.",
            ],
            applicantTips: [
                "Link GitHub implementations and benchmark charts.",
            ],
            responsibilities: [
                "Design novel reward model formulations and process-supervised verify algorithms.",
                "Implement scalable distributed rollouts across thousands of accelerators.",
            ],
            skills: [
                "PyTorch",
                "Reinforcement Learning",
                "RLHF",
                "Deep Learning",
                "Transformers",
                "Distributed Systems",
            ],
            detectedKeywords: [
                "PyTorch",
                "Reinforcement Learning",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "RL Optimization",
                    recommendation: "Detail reasoning benchmark gain.",
                    placeholderTemplate: "Implemented process-supervised reward modeling improving mathematical reasoning accuracy by 11.2%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-openai-64",
            companyName: "OpenAI",
            companySymbol: "sparkles",
            roleTitle: "Software Engineer Intern - ChatGPT Core",
            location: "San Francisco / Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹1.2L - ₹1.7L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 78,
            recency: "4h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.openai.com",
            aboutRole: "Build the distributed inference orchestration, streaming token transport, and tool-use systems serving hundreds of millions of weekly active users.",
            minimumQualifications: [
                "Proficiency in Python, Go, or Rust.",
                "Understanding of distributed systems, WebSockets, rate limiters, and server-sent events (SSE).",
            ],
            preferredQualifications: [
                "Experience building high-throughput low-latency APIs.",
            ],
            applicantTips: [
                "Discuss p99 token delivery latency and connection pooling.",
            ],
            responsibilities: [
                "Optimize streaming token pipelines reducing initial response time.",
                "Design resilient tool execution sandboxes for code interpreter and web browsing.",
            ],
            skills: [
                "Python",
                "Go",
                "Rust",
                "Distributed Systems",
                "WebSockets",
                "API Design",
            ],
            detectedKeywords: [
                "Python",
                "Go",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Streaming APIs",
                    recommendation: "State time-to-first-token metric.",
                    placeholderTemplate: "Engineered token streaming pipeline cutting time-to-first-token (TTFT) by 40% across global connections."
                ),
            ]
        ),
        Opportunity(
            id: "opp-openai-65",
            companyName: "OpenAI",
            companySymbol: "sparkles",
            roleTitle: "Systems Infrastructure Intern",
            location: "San Francisco / Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹1.3L - ₹1.8L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 96,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.openai.com",
            aboutRole: "Build fault-tolerant multi-cluster scheduler platforms and high-speed InfiniBand network observability for massive training runs.",
            minimumQualifications: [
                "Proficiency in Go, Rust, or C++.",
                "Deep understanding of Kubernetes scheduling, InfiniBand networking, and Linux kernel fundamentals.",
            ],
            preferredQualifications: [
                "Experience debugging GPU cluster silent data corruption or network fabric packet drops.",
            ],
            applicantTips: [
                "Highlight cluster utilization metrics and checkpoint efficiency.",
            ],
            responsibilities: [
                "Build automated health check systems detecting failing GPU nodes within seconds.",
                "Streamline distributed checkpoint saving to high-speed NVMe arrays.",
            ],
            skills: [
                "Kubernetes",
                "InfiniBand",
                "Go",
                "Rust",
                "GPU Systems",
                "Linux Kernel",
            ],
            detectedKeywords: [
                "Go",
                "Kubernetes",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Cluster Reliability",
                    recommendation: "Specify checkpoint save duration.",
                    placeholderTemplate: "Architected parallel checkpointing pipeline reducing model saving pause from 8 minutes to 45 seconds."
                ),
            ]
        ),
        Opportunity(
            id: "opp-databricks-66",
            companyName: "Databricks",
            companySymbol: "square.3.layers.3d.down.right.fill",
            roleTitle: "Spark & Lakehouse Engine Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹95k - ₹1.35L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 84,
            recency: "2h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: true,
            applicationDate: "66 days ago",
            externalCareersURL: "https://careers.databricks.com",
            aboutRole: "Optimize Apache Spark and Delta Lake vector engine (Photon) written in native C++ for hyper-fast analytical queries.",
            minimumQualifications: [
                "Strong proficiency in C++ and algorithms.",
                "Understanding of vectorized query execution, columnar storage (Parquet), and database optimizers.",
            ],
            preferredQualifications: [
                "Experience with Apache Spark internals or database query engines.",
            ],
            applicantTips: [
                "Discuss SIMD vectorized instructions and memory cache friendliness.",
            ],
            responsibilities: [
                "Implement vectorized filter and aggregation operators in C++.",
                "Optimize Parquet decompression pipelines using AVX-512 instructions.",
            ],
            skills: [
                "C++",
                "Apache Spark",
                "Delta Lake",
                "Vectorized Query Execution",
                "Database Internals",
                "SIMD",
            ],
            detectedKeywords: [
                "C++",
                "Database Internals",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Query Acceleration",
                    recommendation: "Quantify speedup on TPCH benchmarks.",
                    placeholderTemplate: "Optimized columnar aggregation operator delivering 3.4x faster execution on TPCH queries."
                ),
            ]
        ),
        Opportunity(
            id: "opp-databricks-67",
            companyName: "Databricks",
            companySymbol: "square.3.layers.3d.down.right.fill",
            roleTitle: "Distributed ML Systems Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹90k - ₹1.3L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 92,
            recency: "1d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.databricks.com",
            aboutRole: "Build scalable model training and evaluation infrastructure powering Databricks Mosaic AI and MLflow.",
            minimumQualifications: [
                "Proficiency in Python and Go.",
                "Understanding of distributed training frameworks (Ray, PyTorch), MLflow, and model registries.",
            ],
            preferredQualifications: [
                "Experience with Kubernetes and GPU scheduling.",
            ],
            applicantTips: [
                "Highlight distributed training job reliability and artifact versioning.",
            ],
            responsibilities: [
                "Develop distributed Ray workflows for hyperparameter optimization.",
                "Build automated model artifact tracking for enterprise compliance.",
            ],
            skills: [
                "Python",
                "Ray",
                "MLflow",
                "PyTorch",
                "Kubernetes",
                "Distributed Systems",
            ],
            detectedKeywords: [
                "Python",
                "Distributed Systems",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Distributed Training",
                    recommendation: "Detail speedup in hyperparameter search.",
                    placeholderTemplate: "Parallelized model evaluation across 32 Ray workers speeding up tuning runs by 5x."
                ),
            ]
        ),
        Opportunity(
            id: "opp-databricks-68",
            companyName: "Databricks",
            companySymbol: "square.3.layers.3d.down.right.fill",
            roleTitle: "Developer Ecosystem Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 74,
            recency: "3d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.databricks.com",
            aboutRole: "Build modern CLI tools, language SDKs (Python, Go, TypeScript), and VS Code extensions for lakehouse developers.",
            minimumQualifications: [
                "Proficiency in Go, TypeScript, or Python.",
                "Passionate about delightful developer ergonomics and CLI design.",
            ],
            preferredQualifications: [
                "Experience writing VS Code extensions or open-source developer SDKs.",
            ],
            applicantTips: [
                "Showcase intuitive command-line interfaces and clear error messages.",
            ],
            responsibilities: [
                "Build automated language bindings for Databricks REST APIs.",
                "Implement language server autocomplete for Delta Lake SQL in code editors.",
            ],
            skills: [
                "Go",
                "TypeScript",
                "Python",
                "CLI",
                "Developer Tools",
                "VS Code Extensions",
            ],
            detectedKeywords: [
                "Go",
                "TypeScript",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Developer Ergonomics",
                    recommendation: "Explain command execution simplification.",
                    placeholderTemplate: "Authored unified CLI subcommands reducing multi-step deploy scripts into a single automated command."
                ),
            ]
        ),
        Opportunity(
            id: "opp-figma-69",
            companyName: "Figma",
            companySymbol: "f.cursive",
            roleTitle: "Graphics & Canvas Engine Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹95k - ₹1.4L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 95,
            recency: "1h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.figma.com",
            aboutRole: "Write blazing-fast C++ and WebAssembly graphics rendering pipelines delivering 60fps across infinite canvases with tens of thousands of vector layers.",
            minimumQualifications: [
                "CS/Engineering student with strong C++ and graphics foundations.",
                "Understanding of rendering pipelines, 2D vector geometry, clipping, and spatial indices (R-trees).",
            ],
            preferredQualifications: [
                "Experience with WebAssembly, WebGL/WebGPU, or Metal.",
            ],
            applicantTips: [
                "Highlight frame rate stability on heavy multi-thousand layer files.",
            ],
            responsibilities: [
                "Optimize 2D vector path Boolean operations in C++.",
                "Profile GPU draw calls and implement batching to minimize WebGL pipeline stalls.",
            ],
            skills: [
                "C++",
                "WebAssembly",
                "WebGL",
                "Graphics Programming",
                "Vector Math",
                "Algorithms",
            ],
            detectedKeywords: [
                "C++",
                "Graphics Programming",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Canvas Performance",
                    recommendation: "State FPS gain on heavy files.",
                    placeholderTemplate: "Optimized spatial R-tree bounding box culling boosting canvas rendering from 38fps to locked 60fps on 20,000 layer designs."
                ),
            ]
        ),
        Opportunity(
            id: "opp-figma-70",
            companyName: "Figma",
            companySymbol: "f.cursive",
            roleTitle: "Product Design Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Design students",
            eligibleGradYears: "2027 – 2028",
            matchScore: 82,
            recency: "4h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.figma.com",
            aboutRole: "Design next-generation collaborative design and prototyping capabilities used by millions of digital creators worldwide.",
            minimumQualifications: [
                "Deep fluency in Figma, interaction design, and design system architecture.",
                "Strong visual craft, systems thinking, and ability to distill complex workflows into intuitive UI.",
            ],
            preferredQualifications: [
                "Familiarity with web and mobile platform layout constraints.",
            ],
            applicantTips: [
                "Present comprehensive case studies with rationale, micro-interactions, and edge cases.",
            ],
            responsibilities: [
                "Design novel prototyping states, interactive components, and responsive layout controls.",
                "Conduct usability reviews with design leads from leading tech startups.",
            ],
            skills: [
                "Figma",
                "Interaction Design",
                "UI/UX",
                "Design Systems",
                "Prototyping",
                "Visual Craft",
            ],
            detectedKeywords: [
                "Figma",
                "Design Systems",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Design Systems",
                    recommendation: "Describe component scalability.",
                    placeholderTemplate: "Architected modular component hierarchy with auto-layout variants supporting 50+ enterprise layout combinations."
                ),
            ]
        ),
        Opportunity(
            id: "opp-figma-71",
            companyName: "Figma",
            companySymbol: "f.cursive",
            roleTitle: "Real-Time Collaboration Systems Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹90k - ₹1.3L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 93,
            recency: "2d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.figma.com",
            aboutRole: "Advance the multiplayer sync engine, multi-cursor presence, and conflict-free data replication protocols powering real-time design sessions.",
            minimumQualifications: [
                "Proficiency in Rust, C++, or TypeScript.",
                "Deep understanding of operational transforms, CRDTs, and network protocol design.",
            ],
            preferredQualifications: [
                "Experience with WebSockets, WebRTC data channels, or distributed state.",
            ],
            applicantTips: [
                "Detail bandwidth compression and synchronization lag minimization.",
            ],
            responsibilities: [
                "Implement efficient delta encoding for real-time cursor and vector point changes.",
                "Optimize multiplayer server cluster routing for global low latency.",
            ],
            skills: [
                "Rust",
                "TypeScript",
                "CRDTs",
                "WebSockets",
                "Multiplayer",
                "Distributed Systems",
            ],
            detectedKeywords: [
                "Rust",
                "TypeScript",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Multiplayer Sync",
                    recommendation: "Specify sync latency reduction.",
                    placeholderTemplate: "Engineered binary delta compression reducing multiplayer network payload by 52% and sync latency to under 20ms."
                ),
            ]
        ),
        Opportunity(
            id: "opp-notion-72",
            companyName: "Notion",
            companySymbol: "doc.text.fill",
            roleTitle: "Software Engineer Intern - Block Engine",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹90k - ₹1.35L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "3h ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.notion.com",
            aboutRole: "Develop the core block tree data structure, undo/redo history stacks, and rich-text editing experience inside Notion.",
            minimumQualifications: [
                "Strong foundation in TypeScript, React, and data structure modeling.",
                "Understanding of tree manipulation, immutable state, and DOM selection ranges.",
            ],
            preferredQualifications: [
                "Experience building complex text editors or productivity apps.",
            ],
            applicantTips: [
                "Discuss keystroke latency budgeting and offline persistence.",
            ],
            responsibilities: [
                "Implement custom block types with seamless drag-and-drop hierarchy.",
                "Optimize typing latency to ensure instantaneous text rendering under 10ms.",
            ],
            skills: [
                "TypeScript",
                "React",
                "Data Structures",
                "DOM APIs",
                "State Management",
                "Web Performance",
            ],
            detectedKeywords: [
                "TypeScript",
                "React",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Typing Latency",
                    recommendation: "State typing responsiveness improvement.",
                    placeholderTemplate: "Refactored immutable state updates eliminating re-renders and capping keystroke latency at 8ms."
                ),
            ]
        ),
        Opportunity(
            id: "opp-notion-73",
            companyName: "Notion",
            companySymbol: "doc.text.fill",
            roleTitle: "Mobile Engineer Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.25L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 90,
            recency: "1d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.notion.com",
            aboutRole: "Deliver lightning-fast page loading, offline editing, and gesture animations across Notion iOS and Android native apps.",
            minimumQualifications: [
                "Proficiency in Swift (iOS) or Kotlin (Android), and React Native / TypeScript.",
                "Deep understanding of SQLite on-device caching, background synchronization, and native bridges.",
            ],
            preferredQualifications: [
                "Experience profiling mobile memory and launch duration.",
            ],
            applicantTips: [
                "Highlight offline-first architecture and instant app resumes.",
            ],
            responsibilities: [
                "Implement SQLite query indexing for instant page search on mobile.",
                "Build native bridge modules accelerating page transition animations.",
            ],
            skills: [
                "Swift",
                "Kotlin",
                "React Native",
                "SQLite",
                "Mobile Performance",
                "Offline Sync",
            ],
            detectedKeywords: [
                "Swift",
                "TypeScript",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Offline Caching",
                    recommendation: "Detail page load speedup offline.",
                    placeholderTemplate: "Engineered local SQLite page cache delivering instantaneous offline document loads in under 50ms."
                ),
            ]
        ),
        Opportunity(
            id: "opp-notion-74",
            companyName: "Notion",
            companySymbol: "doc.text.fill",
            roleTitle: "AI Workspace Features Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹90k - ₹1.3L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 79,
            recency: "3d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.notion.com",
            aboutRole: "Build intelligent workspace Q&A, automatic meeting note action extraction, and relational database synthesis powered by LLMs.",
            minimumQualifications: [
                "Strong proficiency in TypeScript, Python, and modern AI tool integration.",
                "Understanding of semantic vector search, chunking strategies, and prompt engineering.",
            ],
            preferredQualifications: [
                "Experience with LangChain, Pinecone, or pgvector.",
            ],
            applicantTips: [
                "Detail hallucination prevention and contextual relevance.",
            ],
            responsibilities: [
                "Build multi-page semantic retrieval pipelines answering questions across entire Notion workspaces.",
                "Design streaming UI for generated tables and task summaries.",
            ],
            skills: [
                "TypeScript",
                "Python",
                "Vector Search",
                "LLMs",
                "RAG",
                "Prompt Engineering",
            ],
            detectedKeywords: [
                "TypeScript",
                "Python",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "RAG Accuracy",
                    recommendation: "Quantify retrieval accuracy lift.",
                    placeholderTemplate: "Implemented semantic section chunking elevating workspace Q&A answer precision to 94.6%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-linear-75",
            companyName: "Linear",
            companySymbol: "line.diagonal",
            roleTitle: "Frontend Engineer Intern - Fast UI",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹90k - ₹1.3L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 94,
            recency: "2h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.linear.com",
            aboutRole: "Work on the fastest issue tracking interface on the web. Craft sub-50ms interactions, seamless keyboard shortcuts, and silky smooth animations.",
            minimumQualifications: [
                "Mastery of TypeScript, modern React, and CSS architecture.",
                "Deep empathy for keyboard-driven workflows, micro-interactions, and 60fps animations.",
            ],
            preferredQualifications: [
                "Experience with local-first databases or optimistic client architecture.",
            ],
            applicantTips: [
                "Highlight attention to detail in keyboard navigation and framerate.",
            ],
            responsibilities: [
                "Build custom keyboard command palettes and issue filter views.",
                "Optimize component rendering using custom virtualized list implementations.",
            ],
            skills: [
                "TypeScript",
                "React",
                "Web Performance",
                "Keyboard UX",
                "CSS",
                "Frontend Architecture",
            ],
            detectedKeywords: [
                "TypeScript",
                "React",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Interaction Latency",
                    recommendation: "Specify interaction speedup.",
                    placeholderTemplate: "Engineered keyboard shortcut dispatcher responding in under 12ms across 1,000+ cached issues."
                ),
            ]
        ),
        Opportunity(
            id: "opp-linear-76",
            companyName: "Linear",
            companySymbol: "line.diagonal",
            roleTitle: "Sync Engine & Offline Systems Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹95k - ₹1.35L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 83,
            recency: "1d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.linear.com",
            aboutRole: "Evolve Linear's local-first sync architecture, maintaining an active client database with automated background sync and conflict-free resolution.",
            minimumQualifications: [
                "Proficiency in TypeScript, IndexedDB / SQLite, and WebSockets.",
                "Solid grasp of distributed state, transactional writes, and conflict-free sync.",
            ],
            preferredQualifications: [
                "Experience with client-side databases (RxDB, SQLite Wasm).",
            ],
            applicantTips: [
                "Discuss offline durability and reconciliation algorithms.",
            ],
            responsibilities: [
                "Write transactional write queues surviving browser tab crashes.",
                "Optimize WebSocket binary wire protocols to sync changes in milliseconds.",
            ],
            skills: [
                "TypeScript",
                "WebSockets",
                "IndexedDB",
                "Local-First",
                "Offline Sync",
                "Distributed Systems",
            ],
            detectedKeywords: [
                "TypeScript",
                "WebSockets",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Local-First Sync",
                    recommendation: "Detail offline transaction durability.",
                    placeholderTemplate: "Engineered local IndexedDB write-ahead log guaranteeing zero data loss during offline task creation."
                ),
            ]
        ),
        Opportunity(
            id: "opp-swiggy-77",
            companyName: "Swiggy",
            companySymbol: "bag.fill",
            roleTitle: "SDE Intern - Delivery Logistics",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 90,
            recency: "2h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: true,
            isApplied: true,
            applicationDate: "77 days ago",
            externalCareersURL: "https://careers.swiggy.com",
            aboutRole: "Optimize real-time delivery partner batching, dynamic order assignment, and ETA prediction algorithms across 500+ Indian cities.",
            minimumQualifications: [
                "Pursuing Computer Science or related engineering degree.",
                "Proficiency in Golang, Java, or Python.",
                "Strong understanding of graph algorithms, priority queues, and Redis.",
            ],
            preferredQualifications: [
                "Experience with geospatial calculations and high-concurrency systems.",
            ],
            applicantTips: [
                "Discuss order batching trade-offs between delivery time and partner earnings.",
            ],
            responsibilities: [
                "Write high-throughput microservices allocating orders to nearby delivery partners.",
                "Implement sub-second batching algorithms during peak lunch and dinner hours.",
            ],
            skills: [
                "Go",
                "Java",
                "Algorithms",
                "Redis",
                "Geospatial",
                "Microservices",
            ],
            detectedKeywords: [
                "Go",
                "Redis",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Batching Algorithm",
                    recommendation: "Quantify batching efficiency.",
                    placeholderTemplate: "Implemented order batching heuristic improving delivery partner efficiency by 18% during peak hours."
                ),
            ]
        ),
        Opportunity(
            id: "opp-swiggy-78",
            companyName: "Swiggy",
            companySymbol: "bag.fill",
            roleTitle: "Backend Engineer - Instamart",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 81,
            recency: "1d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.swiggy.com",
            aboutRole: "Build real-time dark store inventory sync, order picking queues, and lightning-fast 10-minute dispatch pipelines.",
            minimumQualifications: [
                "Proficiency in Golang or Java, and PostgreSQL.",
                "Understanding of distributed locking, event-driven architectures, and Kafka.",
            ],
            preferredQualifications: [
                "Familiarity with warehouse management systems or real-time inventory.",
            ],
            applicantTips: [
                "Emphasize inventory accuracy and preventing stockouts.",
            ],
            responsibilities: [
                "Design inventory reservation microservices preventing overselling.",
                "Build automated dark store order routing systems.",
            ],
            skills: [
                "Go",
                "PostgreSQL",
                "Kafka",
                "Microservices",
                "Event-Driven",
                "Distributed Systems",
            ],
            detectedKeywords: [
                "Go",
                "PostgreSQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Inventory Reservation",
                    recommendation: "State overselling prevention metric.",
                    placeholderTemplate: "Engineered atomic database reservation eliminating inventory oversell incidents during flash sales."
                ),
            ]
        ),
        Opportunity(
            id: "opp-swiggy-79",
            companyName: "Swiggy",
            companySymbol: "bag.fill",
            roleTitle: "Data Science Intern - Search & Recs",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 89,
            recency: "3d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.swiggy.com",
            aboutRole: "Build personalized dish recommendations, search typo-tolerance, and dynamic cuisine ranking models.",
            minimumQualifications: [
                "Strong foundation in NLP, machine learning, and ranking.",
                "Proficiency in Python, PyTorch, and Elasticsearch.",
            ],
            preferredQualifications: [
                "Experience with phonetic search (Double Metaphone) and semantic embeddings.",
            ],
            applicantTips: [
                "Detail search conversion rate (CVR) and recall improvements.",
            ],
            responsibilities: [
                "Train semantic search models matching regional food spellings to dishes.",
                "Deploy context-aware restaurant ranking based on weather and time of day.",
            ],
            skills: [
                "Python",
                "Machine Learning",
                "Elasticsearch",
                "NLP",
                "Search",
                "Recommender Systems",
            ],
            detectedKeywords: [
                "Python",
                "NLP",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Search Typo-Tolerance",
                    recommendation: "State search conversion improvement.",
                    placeholderTemplate: "Trained phonetic search matching model lifting restaurant search-to-order conversion by 8.5%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-zomato-80",
            companyName: "Zomato",
            companySymbol: "fork.knife",
            roleTitle: "Backend SDE Intern - Hyperlocal Routing",
            location: "Gurugram, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 77,
            recency: "1h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.zomato.com",
            aboutRole: "Develop real-time rider tracking, dynamic zone boundaries, and delivery time estimations at massive nationwide scale.",
            minimumQualifications: [
                "Degree in CS/IT or related discipline.",
                "Proficiency in Golang, PHP/Laravel, or Python.",
                "Understanding of Redis, MySQL, and socket streaming.",
            ],
            preferredQualifications: [
                "Experience with geospatial databases (PostGIS).",
            ],
            applicantTips: [
                "Discuss real-time socket connections and battery-aware telemetry.",
            ],
            responsibilities: [
                "Build live tracking webhooks communicating with customer apps.",
                "Optimize PostGIS spatial polygon queries for dynamic restaurant delivery zones.",
            ],
            skills: [
                "Go",
                "PostGIS",
                "Redis",
                "MySQL",
                "WebSockets",
                "Microservices",
            ],
            detectedKeywords: [
                "Go",
                "MySQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Geospatial Queries",
                    recommendation: "State query latency decrease.",
                    placeholderTemplate: "Optimized PostGIS spatial index reducing zone validation query time from 60ms to 8ms."
                ),
            ]
        ),
        Opportunity(
            id: "opp-zomato-81",
            companyName: "Zomato",
            companySymbol: "fork.knife",
            roleTitle: "iOS Developer Intern",
            location: "Gurugram, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹75k - ₹1.0L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "2d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.zomato.com",
            aboutRole: "Craft delightful food ordering flows, interactive live food prep tracking, and fluid menu animations in Swift and SwiftUI.",
            minimumQualifications: [
                "Proficiency in Swift and iOS development.",
                "Strong eye for animations, gesture transitions, and clean MVVM patterns.",
            ],
            preferredQualifications: [
                "Experience with Live Activities, Dynamic Island, and push notifications.",
            ],
            applicantTips: [
                "Showcase Live Activities integration and background refresh.",
            ],
            responsibilities: [
                "Build interactive Live Activity widgets displaying real-time delivery progress.",
                "Optimize image loading pipelines on restaurant menus with hundreds of dishes.",
            ],
            skills: [
                "Swift",
                "SwiftUI",
                "iOS",
                "Live Activities",
                "MVVM",
                "Animation",
            ],
            detectedKeywords: [
                "Swift",
                "SwiftUI",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Live Activities",
                    recommendation: "Highlight feature adoption and responsiveness.",
                    placeholderTemplate: "Engineered iOS Live Activity integration providing real-time order countdowns with zero background sync battery penalty."
                ),
            ]
        ),
        Opportunity(
            id: "opp-zomato-82",
            companyName: "Zomato",
            companySymbol: "fork.knife",
            roleTitle: "Machine Learning Intern - Demand Forecasting",
            location: "Gurugram, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 84,
            recency: "4d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.zomato.com",
            aboutRole: "Predict hyperlocal food order surges, rain impact on delivery times, and kitchen prep delay models.",
            minimumQualifications: [
                "Strong foundation in time-series forecasting, LightGBM, and deep learning.",
                "Proficiency in Python, Pandas, and Scikit-Learn.",
            ],
            preferredQualifications: [
                "Experience with feature engineering over spatiotemporal datasets.",
            ],
            applicantTips: [
                "Detail Mean Absolute Error (MAE) improvements over baseline models.",
            ],
            responsibilities: [
                "Train gradient-boosted trees predicting restaurant kitchen preparation times.",
                "Incorporate weather and festival telemetry to adjust rider deployment zones.",
            ],
            skills: [
                "Python",
                "LightGBM",
                "Time Series",
                "Machine Learning",
                "Pandas",
                "Forecasting",
            ],
            detectedKeywords: [
                "Python",
                "Machine Learning",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Demand Forecasting",
                    recommendation: "State forecast error reduction.",
                    placeholderTemplate: "Engineered spatiotemporal time-series model reducing food prep ETA prediction error by 16%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-cred-83",
            companyName: "CRED",
            companySymbol: "shield.fill",
            roleTitle: "Backend Engineer Intern - High Trust Ledger",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 92,
            recency: "3h ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.cred.com",
            aboutRole: "Build immutable financial ledgers, instant credit card bill payments, and bank integration microservices handling billions in volume.",
            minimumQualifications: [
                "Pursuing Computer Science or related degree.",
                "Proficiency in Java, Kotlin, or Go.",
                "Strong foundation in double-entry bookkeeping, transactional integrity, and database isolation levels.",
            ],
            preferredQualifications: [
                "Knowledge of Kafka, Redis, and relational database internals.",
            ],
            applicantTips: [
                "Emphasize zero-tolerance for financial calculation errors and race conditions.",
            ],
            responsibilities: [
                "Develop transactional microservices processing credit card statement settlements.",
                "Implement rigorous invariant testing and automated ledger reconciliation jobs.",
            ],
            skills: [
                "Java",
                "Kotlin",
                "Fintech",
                "PostgreSQL",
                "Kafka",
                "Distributed Systems",
            ],
            detectedKeywords: [
                "Java",
                "Fintech",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Financial Ledger",
                    recommendation: "State data consistency guarantee.",
                    placeholderTemplate: "Architected double-entry transaction ledger with strict database locks guaranteeing 100% mathematical reconciliation."
                ),
            ]
        ),
        Opportunity(
            id: "opp-cred-84",
            companyName: "CRED",
            companySymbol: "shield.fill",
            roleTitle: "Frontend / React Native Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 80,
            recency: "1d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.cred.com",
            aboutRole: "Craft CRED's signature dark-mode aesthetics, neo-brutalist cards, spring physics, and 120Hz gesture reward wheels.",
            minimumQualifications: [
                "Proficiency in React Native, TypeScript, and React Native Reanimated.",
                "Deep appreciation for micro-interactions, haptics, and premium design execution.",
            ],
            preferredQualifications: [
                "Experience with native iOS (Swift) or Android (Kotlin) bridge modules.",
            ],
            applicantTips: [
                "Showcase high-framerate animation demos and gesture fluidity.",
            ],
            responsibilities: [
                "Implement complex gesture-driven reward screens using Reanimated 3 and Skia.",
                "Coordinate tactile haptic feedback with visual state transitions.",
            ],
            skills: [
                "React Native",
                "TypeScript",
                "Reanimated",
                "Skia",
                "Mobile UI",
                "Animations",
            ],
            detectedKeywords: [
                "TypeScript",
                "React Native",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Gesture Performance",
                    recommendation: "State FPS lock during complex gesture.",
                    placeholderTemplate: "Engineered React Native Reanimated gesture wheel maintaining 60fps without bridging delays."
                ),
            ]
        ),
        Opportunity(
            id: "opp-cred-85",
            companyName: "CRED",
            companySymbol: "shield.fill",
            roleTitle: "Security & Fraud Analytics Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "2d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.cred.com",
            aboutRole: "Safeguard high-net-worth member accounts against credential stuffing, SIM swap attacks, and payment anomalies.",
            minimumQualifications: [
                "Strong analytical mind with Python and SQL.",
                "Knowledge of device fingerprinting, behavioral biometrics, and threat detection.",
            ],
            preferredQualifications: [
                "Familiarity with OAuth, JWT security, and hardware token authentication.",
            ],
            applicantTips: [
                "Highlight anomaly detection precision and low false-alarm rates.",
            ],
            responsibilities: [
                "Build automated risk scoring models analyzing login IP velocity and device integrity.",
                "Implement challenge-response step-up authentication for high-value transfers.",
            ],
            skills: [
                "Python",
                "Security",
                "Fraud Detection",
                "Risk Analysis",
                "Authentication",
                "SQL",
            ],
            detectedKeywords: [
                "Python",
                "Security",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Account Security",
                    recommendation: "Quantify compromised login prevention.",
                    placeholderTemplate: "Implemented device fingerprinting model identifying and blocking 99.4% of credential stuffing attempts."
                ),
            ]
        ),
        Opportunity(
            id: "opp-razorpay-86",
            companyName: "Razorpay",
            companySymbol: "bolt.fill",
            roleTitle: "Payments Gateway Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "2h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.razorpay.com",
            aboutRole: "Engineer high-concurrency payment routing engines dynamically switching between acquiring banks to maximize transaction success rates.",
            minimumQualifications: [
                "Degree in CS/IT graduating in 2027 or 2028.",
                "Proficiency in Golang, PHP, or Python.",
                "Solid understanding of transactional integrity, circuit breakers, and Redis.",
            ],
            preferredQualifications: [
                "Understanding of ISO 8583 payment messages, UPI, or card tokenization.",
            ],
            applicantTips: [
                "Detail dynamic routing optimization and failure rate reduction.",
            ],
            responsibilities: [
                "Implement circuit breaker patterns isolating degraded banking partners.",
                "Build automated retry queues for asynchronous payment webhooks.",
            ],
            skills: [
                "Go",
                "Payments",
                "Redis",
                "Distributed Systems",
                "Circuit Breakers",
                "Microservices",
            ],
            detectedKeywords: [
                "Go",
                "Redis",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Dynamic Routing",
                    recommendation: "State payment success rate lift.",
                    placeholderTemplate: "Engineered real-time acquiring bank routing algorithm elevating overall payment success rate by 4.2%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-razorpay-87",
            companyName: "Razorpay",
            companySymbol: "bolt.fill",
            roleTitle: "Banking APIs & Node.js Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 87,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.razorpay.com",
            aboutRole: "Develop modern corporate banking APIs (RazorpayX), automated payroll disbursals, and vendor invoice management.",
            minimumQualifications: [
                "Proficiency in Node.js, TypeScript, and PostgreSQL.",
                "Strong grasp of REST API best practices, idempotency, and OAuth authentication.",
            ],
            preferredQualifications: [
                "Familiarity with banking integration protocols (NEFT/RTGS/IMPS).",
            ],
            applicantTips: [
                "Emphasize security validations and automated regression suites.",
            ],
            responsibilities: [
                "Build webhook notification delivery microservices with exponential backoff.",
                "Implement bulk payout validation queues handling thousands of transfers per second.",
            ],
            skills: [
                "Node.js",
                "TypeScript",
                "PostgreSQL",
                "Banking APIs",
                "Webhooks",
                "Microservices",
            ],
            detectedKeywords: [
                "Node.js",
                "TypeScript",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Webhook Delivery",
                    recommendation: "Quantify delivery reliability.",
                    placeholderTemplate: "Built resilient webhook delivery system processing 5M+ daily events with 99.98% delivery rate."
                ),
            ]
        ),
        Opportunity(
            id: "opp-razorpay-88",
            companyName: "Razorpay",
            companySymbol: "bolt.fill",
            roleTitle: "Infrastructure & Kubernetes Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 76,
            recency: "3d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: true,
            applicationDate: "88 days ago",
            externalCareersURL: "https://careers.razorpay.com",
            aboutRole: "Manage multi-region Kubernetes clusters, service mesh routing (Istio), and Terraform infrastructure as code.",
            minimumQualifications: [
                "Understanding of Docker, Kubernetes, Linux networking, and AWS.",
                "Proficiency in Python or Go for infrastructure automation.",
            ],
            preferredQualifications: [
                "Experience with Helm charts, CI/CD pipelines, and secret managers.",
            ],
            applicantTips: [
                "Discuss cluster autoscaling efficiency and infrastructure security hardening.",
            ],
            responsibilities: [
                "Configure automated horizontal pod autoscaling based on incoming transaction queues.",
                "Implement automated security scanning on Docker images in CI.",
            ],
            skills: [
                "Kubernetes",
                "AWS",
                "Docker",
                "Terraform",
                "Istio",
                "Linux",
            ],
            detectedKeywords: [
                "Docker",
                "Kubernetes",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Cluster Autoscaling",
                    recommendation: "Detail scaling response time.",
                    placeholderTemplate: "Configured custom HPA metrics triggering Kubernetes pod scaling within 18 seconds of traffic spikes."
                ),
            ]
        ),
        Opportunity(
            id: "opp-phonepe-89",
            companyName: "PhonePe",
            companySymbol: "p.circle.fill",
            roleTitle: "UPI Platform Systems Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 91,
            recency: "4h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.phonepe.com",
            aboutRole: "Work on India's highest-volume UPI processing core handling 100M+ daily financial transactions with sub-second response times.",
            minimumQualifications: [
                "CS/IT degree candidate.",
                "Proficiency in Java or C++, and relational databases (MySQL / PostgreSQL).",
                "Deep appreciation for low-latency concurrency, thread pools, and distributed locking.",
            ],
            preferredQualifications: [
                "Knowledge of Aerospike or distributed in-memory data grids.",
            ],
            applicantTips: [
                "Emphasize strict transaction safety and high throughput.",
            ],
            responsibilities: [
                "Design low-latency database connection pooling for UPI switch connections.",
                "Conduct load testing simulating 15,000 transactions per second.",
            ],
            skills: [
                "Java",
                "UPI",
                "Distributed Systems",
                "MySQL",
                "Concurrency",
                "In-Memory DB",
            ],
            detectedKeywords: [
                "Java",
                "Distributed Systems",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "High Throughput",
                    recommendation: "Specify transaction volume handled.",
                    placeholderTemplate: "Optimized Java thread pools handling 12,000 TPS under 200ms round-trip latency."
                ),
            ]
        ),
        Opportunity(
            id: "opp-phonepe-90",
            companyName: "PhonePe",
            companySymbol: "p.circle.fill",
            roleTitle: "High-Volume Data Streaming Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 82,
            recency: "2d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.phonepe.com",
            aboutRole: "Develop real-time data streaming pipelines consuming transaction telemetry for live fraud scoring and merchant analytics.",
            minimumQualifications: [
                "Proficiency in Java, Scala, or Python.",
                "Hands-on experience with Apache Kafka, Spark Streaming, or Flink.",
            ],
            preferredQualifications: [
                "Understanding of stream state management and checkpointing.",
            ],
            applicantTips: [
                "Discuss data deduplication and exactly-once processing.",
            ],
            responsibilities: [
                "Implement streaming stateful aggregations calculating merchant daily sales totals.",
                "Monitor Kafka partition lag and optimize consumer parallelism.",
            ],
            skills: [
                "Kafka",
                "Apache Flink",
                "Java",
                "Streaming",
                "Big Data",
                "Distributed Systems",
            ],
            detectedKeywords: [
                "Java",
                "Kafka",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Stream Processing",
                    recommendation: "Detail throughput and lag.",
                    placeholderTemplate: "Processed 80,000 events/sec in Apache Flink maintaining near-zero consumer lag."
                ),
            ]
        ),
        Opportunity(
            id: "opp-phonepe-91",
            companyName: "PhonePe",
            companySymbol: "p.circle.fill",
            roleTitle: "Information Security Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 86,
            recency: "3d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.phonepe.com",
            aboutRole: "Conduct penetration testing across financial microservices, audit hardware security modules (HSM), and verify RBI compliance.",
            minimumQualifications: [
                "Understanding of financial cybersecurity, OWASP Top 10, and cryptography.",
                "Proficiency in Python or Bash for security automation scripts.",
            ],
            preferredQualifications: [
                "Experience with Burp Suite, Wireshark, and API vulnerability scanning.",
            ],
            applicantTips: [
                "Present threat modeling diagrams and risk remediations.",
            ],
            responsibilities: [
                "Automate API endpoint security scanning in pre-production pipelines.",
                "Conduct dynamic security testing on merchant QR code generation endpoints.",
            ],
            skills: [
                "Security",
                "Penetration Testing",
                "Cryptography",
                "Python",
                "API Security",
                "Fintech",
            ],
            detectedKeywords: [
                "Security",
                "Python",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Penetration Testing",
                    recommendation: "State vulnerability found and patched.",
                    placeholderTemplate: "Identified and patched critical parameter tampering vulnerability in merchant payout API."
                ),
            ]
        ),
        Opportunity(
            id: "opp-zepto-92",
            companyName: "Zepto",
            companySymbol: "bolt.fill",
            roleTitle: "10-Min Dispatch Routing Intern",
            location: "Mumbai, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹70k - ₹95k / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 83,
            recency: "2h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.zepto.com",
            aboutRole: "Design hyper-fast rider assignment algorithms optimizing 10-minute grocery delivery from dark store networks.",
            minimumQualifications: [
                "Degree in CS/IT or Industrial Engineering.",
                "Proficiency in Golang or Python.",
                "Understanding of geospatial indices, shortest path algorithms, and Redis.",
            ],
            preferredQualifications: [
                "Familiarity with simulation models and real-time dispatch.",
            ],
            applicantTips: [
                "Highlight delivery partner safety and travel time reduction.",
            ],
            responsibilities: [
                "Simulate dark store rider queues to minimize store exit delay.",
                "Implement real-time route optimization taking traffic lights into account.",
            ],
            skills: [
                "Go",
                "Python",
                "Algorithms",
                "Redis",
                "Geospatial",
                "Logistics",
            ],
            detectedKeywords: [
                "Go",
                "Algorithms",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Dispatch Optimization",
                    recommendation: "State dispatch time reduction.",
                    placeholderTemplate: "Optimized dark store pickup queue shaving 45 seconds off order dispatch time."
                ),
            ]
        ),
        Opportunity(
            id: "opp-zepto-93",
            companyName: "Zepto",
            companySymbol: "bolt.fill",
            roleTitle: "Inventory Prediction Systems Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 86,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.zepto.com",
            aboutRole: "Forecast hourly fresh grocery perishables demand to minimize food wastage across hundreds of local micro-warehouses.",
            minimumQualifications: [
                "Strong foundation in statistics, machine learning, and time-series modeling.",
                "Proficiency in Python, Pandas, and XGBoost.",
            ],
            preferredQualifications: [
                "Experience analyzing demand volatility and perishable item lifecycles.",
            ],
            applicantTips: [
                "Detail spoilage rate reductions and stock availability metrics.",
            ],
            responsibilities: [
                "Train hourly demand models factoring in weather and local neighborhood demographics.",
                "Build automated reorder alerts for dark store inventory managers.",
            ],
            skills: [
                "Python",
                "Machine Learning",
                "XGBoost",
                "Time Series",
                "Pandas",
                "Inventory",
            ],
            detectedKeywords: [
                "Python",
                "Machine Learning",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Spoilage Reduction",
                    recommendation: "Quantify waste reduction metric.",
                    placeholderTemplate: "Trained hyperlocal perishable forecasting model reducing fresh produce spoilage by 21%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-meesho-94",
            companyName: "Meesho",
            companySymbol: "bag.fill",
            roleTitle: "Growth & Personalization Engineer",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 81,
            recency: "3h ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.meesho.com",
            aboutRole: "Build discovery feeds and gamified social sharing workflows empowering millions of tier-2 and tier-3 Indian shoppers.",
            minimumQualifications: [
                "CS/IT degree candidate.",
                "Proficiency in Java, Python, or Go.",
                "Understanding of recommender systems, A/B testing, and Redis.",
            ],
            preferredQualifications: [
                "Interest in social commerce and vernacular user experiences.",
            ],
            applicantTips: [
                "Highlight user retention metrics and recommendation relevance.",
            ],
            responsibilities: [
                "Build personalized feed candidate generation services.",
                "Design robust A/B test splits measuring conversion across user cohorts.",
            ],
            skills: [
                "Java",
                "Python",
                "Recommender Systems",
                "Redis",
                "A/B Testing",
                "Social Commerce",
            ],
            detectedKeywords: [
                "Java",
                "Python",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Recommendation Lift",
                    recommendation: "Specify conversion lift.",
                    placeholderTemplate: "Implemented collaborative filtering recommendations lifting product click-through rate by 9.3%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-meesho-95",
            companyName: "Meesho",
            companySymbol: "bag.fill",
            roleTitle: "Microservices Platform Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹75k - ₹1.0L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "2d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.meesho.com",
            aboutRole: "Scale backend microservices to handle millions of simultaneous shoppers during festival mega-blockbuster sales.",
            minimumQualifications: [
                "Proficiency in Java or Go, Spring Boot, and MySQL.",
                "Understanding of caching, connection poolers, and asynchronous message queues.",
            ],
            preferredQualifications: [
                "Experience with Docker, Kubernetes, and Kafka.",
            ],
            applicantTips: [
                "Discuss handling traffic spikes with graceful degradation.",
            ],
            responsibilities: [
                "Optimize relational database queries under high concurrent load.",
                "Implement asynchronous event handling for order placement.",
            ],
            skills: [
                "Java",
                "Go",
                "Spring Boot",
                "MySQL",
                "Kafka",
                "Docker",
            ],
            detectedKeywords: [
                "Java",
                "MySQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Microservices Scaling",
                    recommendation: "Detail throughput handled.",
                    placeholderTemplate: "Optimized order creation endpoint handling 8,000 QPS with sub-150ms response times."
                ),
            ]
        ),
        Opportunity(
            id: "opp-groww-96",
            companyName: "Groww",
            companySymbol: "chart.line.uptrend.xyaxis",
            roleTitle: "Stock Trading Systems Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 79,
            recency: "1h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.groww.com",
            aboutRole: "Build low-latency market data streaming feeds, real-time stock ticker graphs, and order placement gateways connecting to NSE/BSE.",
            minimumQualifications: [
                "Degree in CS/IT.",
                "Proficiency in Golang or Java, and WebSockets.",
                "Understanding of high-frequency market data packets, order books, and socket multiplexing.",
            ],
            preferredQualifications: [
                "Interest in stock market mechanics and financial trading.",
            ],
            applicantTips: [
                "Highlight latency minimization and tick data compression.",
            ],
            responsibilities: [
                "Implement streaming WebSocket server broadcasting live stock quotes to millions of active users.",
                "Build automated risk checks ensuring margin requirements before order dispatch.",
            ],
            skills: [
                "Go",
                "WebSockets",
                "Trading Systems",
                "Market Data",
                "Concurrency",
                "Financial Markets",
            ],
            detectedKeywords: [
                "Go",
                "WebSockets",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Market Data Streaming",
                    recommendation: "Specify socket throughput.",
                    placeholderTemplate: "Engineered WebSocket multiplexer broadcasting 50,000 market ticks per second with sub-5ms delay."
                ),
            ]
        ),
        Opportunity(
            id: "opp-groww-97",
            companyName: "Groww",
            companySymbol: "chart.line.uptrend.xyaxis",
            roleTitle: "Mobile Engineer Intern - React Native/Swift",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 87,
            recency: "2d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.groww.com",
            aboutRole: "Deliver fluid interactive candle charts, instant SIP investments, and smooth KYC verification on the Groww mobile app.",
            minimumQualifications: [
                "Proficiency in React Native / TypeScript or native Swift (iOS).",
                "Strong foundation in chart rendering, animation physics, and state management.",
            ],
            preferredQualifications: [
                "Experience profiling mobile frame drops on complex interactive graphs.",
            ],
            applicantTips: [
                "Showcase interactive chart gesture scrubbing and smooth rendering.",
            ],
            responsibilities: [
                "Build custom high-performance candlestick charts rendering thousands of historical data points.",
                "Optimize biometric face authentication flows.",
            ],
            skills: [
                "React Native",
                "Swift",
                "TypeScript",
                "Financial Charts",
                "Mobile UI",
                "Performance",
            ],
            detectedKeywords: [
                "TypeScript",
                "Swift",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Chart Optimization",
                    recommendation: "State chart render frame rate.",
                    placeholderTemplate: "Engineered custom Canvas candle chart rendering 5,000 data points smoothly at 60fps."
                ),
            ]
        ),
        Opportunity(
            id: "opp-zerodha-98",
            companyName: "Zerodha",
            companySymbol: "skew",
            roleTitle: "Kite Platform Trading Engine Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 84,
            recency: "2h ago",
            cardColor: AlineTheme.cardSkyBlue,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.zerodha.com",
            aboutRole: "Work on India's largest discount brokerage platform Kite. Build ultra-minimalist, reliable, high-speed trading architectures.",
            minimumQualifications: [
                "CS/IT degree candidate.",
                "Proficiency in Go, Python, or Rust.",
                "Deep appreciation for minimalist code, zero external bloat, and UNIX philosophy.",
            ],
            preferredQualifications: [
                "Familiarity with PostgreSql, Redis, and low-latency network sockets.",
            ],
            applicantTips: [
                "Highlight simplicity of architecture and robust error handling.",
            ],
            responsibilities: [
                "Build robust order validation microservices handling morning market open volume spikes.",
                "Optimize database connection pooling and query execution plans.",
            ],
            skills: [
                "Go",
                "PostgreSQL",
                "Redis",
                "Trading",
                "UNIX",
                "High Concurrency",
            ],
            detectedKeywords: [
                "Go",
                "PostgreSQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Trading Concurrency",
                    recommendation: "Detail morning market volume handled.",
                    placeholderTemplate: "Engineered order execution queue handling 5M+ orders on market open with zero dropped transactions."
                ),
            ]
        ),
        Opportunity(
            id: "opp-zerodha-99",
            companyName: "Zerodha",
            companySymbol: "skew",
            roleTitle: "Open-Source Infrastructure Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 89,
            recency: "1d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: true,
            applicationDate: "99 days ago",
            externalCareersURL: "https://careers.zerodha.com",
            aboutRole: "Contribute to open-source self-hosted developer tools, telemetry pipelines, and internal developer platforms at Zerodha.",
            minimumQualifications: [
                "Strong proficiency in Go and Python.",
                "Active contributor to open-source software.",
                "Passionate about Linux, self-hosting, and data privacy.",
            ],
            preferredQualifications: [
                "Experience writing clean open-source documentation and tests.",
            ],
            applicantTips: [
                "Link public GitHub contributions and pull requests.",
            ],
            responsibilities: [
                "Contribute to open-source developer tooling and background queue runners.",
                "Improve documentation and automated testing suites.",
            ],
            skills: [
                "Go",
                "Python",
                "Open Source",
                "Linux",
                "Self-Hosting",
                "Developer Tools",
            ],
            detectedKeywords: [
                "Go",
                "Open Source",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Open Source",
                    recommendation: "Highlight active repository contributions.",
                    placeholderTemplate: "Authored and maintained open-source Go utility with 500+ GitHub stars and 100% test coverage."
                ),
            ]
        ),
        Opportunity(
            id: "opp-postman-100",
            companyName: "Postman",
            companySymbol: "paperplane.fill",
            roleTitle: "API Platform Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 78,
            recency: "3h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.postman.com",
            aboutRole: "Evolve the world's leading API client used by 30M+ developers. Advance API mocking, automated testing, and OpenAPI schema validation.",
            minimumQualifications: [
                "Proficiency in Node.js, TypeScript, and modern web standards.",
                "Deep understanding of HTTP specifications, REST, GraphQL, gRPC, and WebSockets.",
            ],
            preferredQualifications: [
                "Experience building developer tools or API testing frameworks.",
            ],
            applicantTips: [
                "Discuss protocol handling and performance profiling.",
            ],
            responsibilities: [
                "Build automated schema validation engines comparing runtime API responses against OpenAPI specs.",
                "Optimize response viewer memory usage for multi-megabyte JSON payloads.",
            ],
            skills: [
                "TypeScript",
                "Node.js",
                "API Design",
                "OpenAPI",
                "GraphQL",
                "gRPC",
            ],
            detectedKeywords: [
                "TypeScript",
                "Node.js",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "API Testing",
                    recommendation: "Detail schema validation speedup.",
                    placeholderTemplate: "Built streaming JSON schema validator checking 500+ endpoints in under 4 seconds in CI pipelines."
                ),
            ]
        ),
        Opportunity(
            id: "opp-postman-101",
            companyName: "Postman",
            companySymbol: "paperplane.fill",
            roleTitle: "Developer Tools & CLI Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "2d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.postman.com",
            aboutRole: "Build Postman CLI and Newman runners integrating API tests into developer CI/CD workflows.",
            minimumQualifications: [
                "Proficiency in Node.js, Go, or TypeScript.",
                "Understanding of CLI design, terminal color rendering, and exit code standards.",
            ],
            preferredQualifications: [
                "Experience integrating testing tools into GitHub Actions or GitLab CI.",
            ],
            applicantTips: [
                "Highlight lightweight binary distribution and fast startup times.",
            ],
            responsibilities: [
                "Implement headless collection runner capabilities in the Postman CLI.",
                "Optimize startup execution time for CI environments.",
            ],
            skills: [
                "TypeScript",
                "Node.js",
                "Go",
                "CLI",
                "CI/CD",
                "Developer Tools",
            ],
            detectedKeywords: [
                "TypeScript",
                "Go",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "CLI Architecture",
                    recommendation: "State execution startup time reduction.",
                    placeholderTemplate: "Compiled lightweight CLI binary cutting startup overhead by 60% in automated CI jobs."
                ),
            ]
        ),
        Opportunity(
            id: "opp-hasura-102",
            companyName: "Hasura",
            companySymbol: "bolt.horizontal.fill",
            roleTitle: "GraphQL Engine Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "2h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.hasura.com",
            aboutRole: "Contribute to Hasura's high-performance distributed GraphQL compilation engine translating GraphQL queries directly into optimized SQL.",
            minimumQualifications: [
                "Strong foundation in compilers, programming languages, and Haskell or Rust.",
                "Deep understanding of SQL generation, abstract syntax trees (AST), and database query planning.",
            ],
            preferredQualifications: [
                "Experience with PostgreSQL or GraphQL specification.",
            ],
            applicantTips: [
                "Highlight compiler optimization and query planning depth.",
            ],
            responsibilities: [
                "Implement AST transformation passes optimizing nested GraphQL relationship queries.",
                "Write automated conformance tests against SQL database engines.",
            ],
            skills: [
                "Haskell",
                "Rust",
                "GraphQL",
                "Compilers",
                "PostgreSQL",
                "SQL Generation",
            ],
            detectedKeywords: [
                "Rust",
                "PostgreSQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Query Compilation",
                    recommendation: "State database query latency improvement.",
                    placeholderTemplate: "Optimized SQL generation pass eliminating redundant subqueries and cutting DB query time by 32% across complex relationships."
                ),
            ]
        ),
        Opportunity(
            id: "opp-hasura-103",
            companyName: "Hasura",
            companySymbol: "bolt.horizontal.fill",
            roleTitle: "Distributed Compiler Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 90,
            recency: "1d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.hasura.com",
            aboutRole: "Build native data connectors bridging GraphQL queries across heterogeneous databases (PostgreSQL, ClickHouse, BigQuery).",
            minimumQualifications: [
                "Proficiency in Rust, Go, or TypeScript.",
                "Understanding of distributed data federation, schema stitching, and query pushdown optimization.",
            ],
            preferredQualifications: [
                "Hands-on experience with ClickHouse or analytical databases.",
            ],
            applicantTips: [
                "Discuss query federation and latency minimization.",
            ],
            responsibilities: [
                "Develop high-throughput data connector for ClickHouse analytical queries.",
                "Optimize schema introspection across multi-database federations.",
            ],
            skills: [
                "Rust",
                "Go",
                "ClickHouse",
                "PostgreSQL",
                "Data Federation",
                "Distributed Systems",
            ],
            detectedKeywords: [
                "Rust",
                "Go",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Data Federation",
                    recommendation: "Detail query federation speedup.",
                    placeholderTemplate: "Engineered analytical pushdown connector querying ClickHouse tables with sub-10ms response times."
                ),
            ]
        ),
        Opportunity(
            id: "opp-browserstack-104",
            companyName: "BrowserStack",
            companySymbol: "laptopcomputer.and.iphone",
            roleTitle: "Cloud Emulation Systems Intern",
            location: "Mumbai, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 73,
            recency: "4h ago",
            cardColor: AlineTheme.cardSkyBlue,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.browserstack.com",
            aboutRole: "Develop real-device cloud streaming infrastructure enabling instant browser testing on thousands of physical iPhones and Android devices.",
            minimumQualifications: [
                "Degree in CS/IT or Electronics.",
                "Proficiency in C++, Python, or Go.",
                "Understanding of video encoding (H.264/WebRTC), USB multiplexing (ADB / libimobiledevice), and device drivers.",
            ],
            preferredQualifications: [
                "Experience with Android/iOS device automation.",
            ],
            applicantTips: [
                "Highlight low-latency screen streaming and interactive touch response.",
            ],
            responsibilities: [
                "Optimize real-time WebRTC frame encoding from mobile device screens.",
                "Build automated health checks resetting test devices to clean states between sessions.",
            ],
            skills: [
                "C++",
                "Python",
                "WebRTC",
                "Android ADB",
                "Device Automation",
                "Cloud Infrastructure",
            ],
            detectedKeywords: [
                "Python",
                "C++",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Device Streaming",
                    recommendation: "State frame latency metric.",
                    placeholderTemplate: "Engineered WebRTC video capture pipeline streaming physical device screen at 60fps with under 35ms latency."
                ),
            ]
        ),
        Opportunity(
            id: "opp-browserstack-105",
            companyName: "BrowserStack",
            companySymbol: "laptopcomputer.and.iphone",
            roleTitle: "Test Automation Infrastructure Intern",
            location: "Mumbai, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 87,
            recency: "2d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.browserstack.com",
            aboutRole: "Scale automated Selenium, Cypress, and Playwright execution engines across massive multi-tenant browser clusters.",
            minimumQualifications: [
                "Proficiency in Java, Node.js, or Python.",
                "Deep understanding of browser automation protocols (WebDriver, Chrome DevTools Protocol).",
            ],
            preferredQualifications: [
                "Experience building distributed test runners in Docker.",
            ],
            applicantTips: [
                "Discuss test flakiness mitigation and browser startup speed.",
            ],
            responsibilities: [
                "Implement Chrome DevTools Protocol proxying for Playwright tests.",
                "Reduce containerized browser boot time to under 800 milliseconds.",
            ],
            skills: [
                "Java",
                "Node.js",
                "Selenium",
                "Playwright",
                "Cypress",
                "Docker",
            ],
            detectedKeywords: [
                "Node.js",
                "Java",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Browser Boot Time",
                    recommendation: "State container startup speedup.",
                    placeholderTemplate: "Pre-warmed browser containers cutting automated test initiation delay by 65%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-goldmansachs-106",
            companyName: "Goldman Sachs",
            companySymbol: "building.columns.fill",
            roleTitle: "Quantitative Analytics Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹1.1L - ₹1.6L / mo",
            experienceYears: "B.Tech/M.Tech",
            eligibleGradYears: "2027 – 2028",
            matchScore: 80,
            recency: "2h ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.goldmansachs.com",
            aboutRole: "Develop stochastic pricing models, volatility surfaces, and risk factor sensitivity calculations for global derivatives desks.",
            minimumQualifications: [
                "Strong mathematical background in stochastic calculus, probability, and linear algebra.",
                "Proficiency in Python, C++, and numerical libraries (NumPy, SciPy).",
            ],
            preferredQualifications: [
                "Experience with Monte Carlo simulations or financial derivatives pricing.",
            ],
            applicantTips: [
                "Demonstrate analytical precision and mathematical rigor in project descriptions.",
            ],
            responsibilities: [
                "Implement Monte Carlo pricing simulations for complex options contracts.",
                "Profile model sensitivity (Greeks) under severe market stress scenarios.",
            ],
            skills: [
                "Python",
                "C++",
                "Quantitative Finance",
                "Monte Carlo",
                "Financial Modeling",
                "Linear Algebra",
            ],
            detectedKeywords: [
                "Python",
                "C++",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Monte Carlo Simulation",
                    recommendation: "State simulation convergence speedup.",
                    placeholderTemplate: "Implemented variance reduction techniques accelerating Monte Carlo pricing convergence by 4x."
                ),
            ]
        ),
        Opportunity(
            id: "opp-goldmansachs-107",
            companyName: "Goldman Sachs",
            companySymbol: "building.columns.fill",
            roleTitle: "Global Markets Engineering Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹95k - ₹1.4L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 92,
            recency: "1d ago",
            cardColor: AlineTheme.cardSkyBlue,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.goldmansachs.com",
            aboutRole: "Build resilient electronic order execution gateways, trade clearing pipelines, and real-time risk validation engines.",
            minimumQualifications: [
                "Degree in Computer Science, Math, or related STEM discipline.",
                "Proficiency in Java or C++, and relational databases.",
            ],
            preferredQualifications: [
                "Understanding of low-latency network architectures and FIX protocol.",
            ],
            applicantTips: [
                "Emphasize strict transaction consistency and auditability.",
            ],
            responsibilities: [
                "Write multi-threaded order routing services with sub-millisecond validation.",
                "Design automated trade reconciliation jobs ensuring regulatory compliance.",
            ],
            skills: [
                "Java",
                "C++",
                "FIX Protocol",
                "Trading Systems",
                "Risk Management",
                "SQL",
            ],
            detectedKeywords: [
                "Java",
                "C++",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Order Execution",
                    recommendation: "State transaction validation speed.",
                    placeholderTemplate: "Engineered multi-threaded pre-trade risk check validating orders in under 800 microseconds."
                ),
            ]
        ),
        Opportunity(
            id: "opp-morganstanley-108",
            companyName: "Morgan Stanley",
            companySymbol: "building.2.fill",
            roleTitle: "Electronic Trading SDE Intern",
            location: "Mumbai, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹1.0L - ₹1.5L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 82,
            recency: "3h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.morganstanley.com",
            aboutRole: "Work on high-frequency algorithmic execution strategies, smart order routers (SOR), and market gateway connections.",
            minimumQualifications: [
                "Pursuing Computer Science or related engineering degree.",
                "Proficiency in C++ or Java.",
                "Solid understanding of multithreading, data structures, and memory caches.",
            ],
            preferredQualifications: [
                "Knowledge of equity and options market microstructure.",
            ],
            applicantTips: [
                "Highlight microsecond-level latency tuning and profiling.",
            ],
            responsibilities: [
                "Implement smart order routing logic minimizing market impact and slippage.",
                "Profile CPU cache misses and optimize data memory layout in C++.",
            ],
            skills: [
                "C++",
                "Java",
                "Algorithmic Trading",
                "Smart Order Routing",
                "Low Latency",
                "Multithreading",
            ],
            detectedKeywords: [
                "C++",
                "Java",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Algorithmic Execution",
                    recommendation: "State execution slippage reduction.",
                    placeholderTemplate: "Implemented volume-weighted average price (VWAP) execution algorithm reducing transaction slippage by 2.8 bps."
                ),
            ]
        ),
        Opportunity(
            id: "opp-morganstanley-109",
            companyName: "Morgan Stanley",
            companySymbol: "building.2.fill",
            roleTitle: "Fixed Income Analytics Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹90k - ₹1.35L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 90,
            recency: "2d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.morganstanley.com",
            aboutRole: "Build yield curve construction algorithms, mortgage-backed security cash flow engines, and credit default risk models.",
            minimumQualifications: [
                "Strong foundation in mathematical modeling, statistics, and financial engineering.",
                "Proficiency in Python and SQL.",
            ],
            preferredQualifications: [
                "Experience with bond pricing or credit risk modeling.",
            ],
            applicantTips: [
                "Showcase quantitative accuracy and interest rate sensitivity modeling.",
            ],
            responsibilities: [
                "Construct zero-coupon yield curves using cubic spline interpolation.",
                "Model credit default swap (CDS) spreads and portfolio value-at-risk (VaR).",
            ],
            skills: [
                "Python",
                "Quantitative Finance",
                "Fixed Income",
                "Risk Modeling",
                "SQL",
                "Statistics",
            ],
            detectedKeywords: [
                "Python",
                "SQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Yield Curve Modeling",
                    recommendation: "Describe model accuracy.",
                    placeholderTemplate: "Implemented cubic spline yield curve interpolation matching market bond prices with sub-1bp residual error."
                ),
            ]
        ),
        Opportunity(
            id: "opp-citadel-110",
            companyName: "Citadel",
            companySymbol: "building.columns.fill",
            roleTitle: "Quantitative Research Intern",
            location: "Singapore / Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹1.5L - ₹2.2L / mo",
            experienceYears: "Math/CS/Physics",
            eligibleGradYears: "2027 – 2028",
            matchScore: 84,
            recency: "Just now",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: true,
            applicationDate: "110 days ago",
            externalCareersURL: "https://careers.citadel.com",
            aboutRole: "Analyze terabytes of granular market tick data, identify statistical market anomalies, and develop predictive alpha signals.",
            minimumQualifications: [
                "Top academic background in Math, Physics, Computer Science, or Statistics.",
                "Expertise in Python, C++, and advanced statistical inference.",
                "Strong intuition for noisy data, time-series, and hypothesis testing.",
            ],
            preferredQualifications: [
                "Competitions or publications in math/stats/ML (Olympiads, Kaggle Grandmaster, Putnam).",
            ],
            applicantTips: [
                "Highlight rigorous out-of-sample backtesting and Sharpe ratio optimizations.",
            ],
            responsibilities: [
                "Formulate novel statistical alpha signals across global equity tick streams.",
                "Backtest predictive signals against historical limit order book data.",
            ],
            skills: [
                "Quantitative Research",
                "Python",
                "C++",
                "Statistics",
                "Machine Learning",
                "Alpha Modeling",
            ],
            detectedKeywords: [
                "Python",
                "C++",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Alpha Modeling",
                    recommendation: "State signal Sharpe ratio and predictive power.",
                    placeholderTemplate: "Developed high-frequency mean-reversion alpha signal achieving 2.8 Sharpe ratio in out-of-sample backtests."
                ),
            ]
        ),
        Opportunity(
            id: "opp-citadel-111",
            companyName: "Citadel",
            companySymbol: "building.columns.fill",
            roleTitle: "Low Latency C++ Trading Systems Intern",
            location: "Singapore / Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹1.4L - ₹2.0L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 97,
            recency: "4h ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.citadel.com",
            aboutRole: "Engineer nanosecond-scale market data decoders, FPGA kernel interfaces, and ultra-low-latency order execution engines.",
            minimumQualifications: [
                "Mastery of modern C++ (C++20), lock-free programming, and CPU architecture.",
                "Understanding of kernel bypass networking (Solarflare OpenOnload), cache hierarchies, and assembly.",
            ],
            preferredQualifications: [
                "Experience writing bare-metal or high-performance C++ code.",
            ],
            applicantTips: [
                "Emphasize nanosecond-level benchmarking and zero-allocation hot paths.",
            ],
            responsibilities: [
                "Write zero-copy packet decoders parsing exchange multicast feeds in nanoseconds.",
                "Eliminate dynamic memory allocations in the core trading execution path.",
            ],
            skills: [
                "C++",
                "Low Latency",
                "Kernel Bypass",
                "Computer Architecture",
                "Lock-Free",
                "Networking",
            ],
            detectedKeywords: [
                "C++",
                "Low Latency",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Zero-Copy Decoding",
                    recommendation: "Specify nanosecond latency benchmark.",
                    placeholderTemplate: "Engineered zero-copy exchange feed decoder processing market ticks with sub-450ns tick-to-trade latency."
                ),
            ]
        ),
        Opportunity(
            id: "opp-janestreet-112",
            companyName: "Jane Street",
            companySymbol: "chart.bar.xaxis",
            roleTitle: "OCaml Software Engineering Intern",
            location: "London / Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹1.5L - ₹2.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 81,
            recency: "1h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.janestreet.com",
            aboutRole: "Build mission-critical trading automation, distributed risk engines, and developer tools using OCaml and functional programming.",
            minimumQualifications: [
                "Pursuing Computer Science, Math, or related degree.",
                "Strong foundation in functional programming (OCaml, Haskell, Scheme, or Scala).",
                "Passion for elegant, type-safe, correct-by-construction systems.",
            ],
            preferredQualifications: [
                "Experience with typed functional languages and compiler design.",
            ],
            applicantTips: [
                "Discuss expressiveness and safety advantages of functional programming.",
            ],
            responsibilities: [
                "Develop automated trading monitors and position risk calculators in OCaml.",
                "Write domain-specific languages and property-based test suites using QuickCheck.",
            ],
            skills: [
                "OCaml",
                "Functional Programming",
                "Type Systems",
                "Trading Systems",
                "Algorithms",
                "Concurrency",
            ],
            detectedKeywords: [
                "OCaml",
                "Functional Programming",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Functional Design",
                    recommendation: "Detail type-safety and bug elimination.",
                    placeholderTemplate: "Modeled trading state machine in OCaml with algebraic data types preventing invalid order transitions at compile-time."
                ),
            ]
        ),
        Opportunity(
            id: "opp-janestreet-113",
            companyName: "Jane Street",
            companySymbol: "chart.bar.xaxis",
            roleTitle: "Quantitative Trading Intern",
            location: "London / Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹1.5L - ₹2.2L / mo",
            experienceYears: "Math/CS/Physics",
            eligibleGradYears: "2027 – 2028",
            matchScore: 97,
            recency: "3h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.janestreet.com",
            aboutRole: "Apply mathematical game theory, probability, and risk intuition to trade global financial instruments in fast-paced simulated and live markets.",
            minimumQualifications: [
                "Outstanding quantitative reasoning, mental math, and probabilistic thinking.",
                "Comfortable evaluating expected value and making decisions under uncertainty.",
            ],
            preferredQualifications: [
                "Experience with probability competitions, poker, or strategy games.",
            ],
            applicantTips: [
                "Demonstrate rapid probabilistic reasoning and calm execution under time pressure.",
            ],
            responsibilities: [
                "Price and trade ETF arbitrage baskets across multi-currency venues.",
                "Evaluate continuous order book dynamics and identify liquidity imbalances.",
            ],
            skills: [
                "Quantitative Trading",
                "Probability",
                "Game Theory",
                "Statistics",
                "Risk Management",
                "Financial Markets",
            ],
            detectedKeywords: [
                "Probability",
                "Statistics",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Probabilistic Pricing",
                    recommendation: "Describe trade execution and expected value.",
                    placeholderTemplate: "Priced complex multi-asset ETF baskets in fast market sessions achieving positive expected value across 98% of simulated cycles."
                ),
            ]
        ),
        Opportunity(
            id: "opp-oracle-114",
            companyName: "Oracle",
            companySymbol: "cylinder.split.1x2.fill",
            roleTitle: "Cloud Infrastructure Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹75k - ₹1.05L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 79,
            recency: "4h ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.oracle.com",
            aboutRole: "Build virtualization, software-defined networking, and high-performance bare-metal compute nodes on Oracle Cloud Infrastructure (OCI).",
            minimumQualifications: [
                "Enrolled in Computer Science or related degree.",
                "Proficiency in Java, C++, or Python.",
                "Understanding of Linux networking, virtualization (KVM), and storage.",
            ],
            preferredQualifications: [
                "Knowledge of Terraform or cloud automation.",
            ],
            applicantTips: [
                "Highlight bare-metal cloud performance and low-latency storage.",
            ],
            responsibilities: [
                "Develop automated provisioning scripts for cloud infrastructure.",
                "Monitor hypervisor performance under high network throughput.",
            ],
            skills: [
                "Java",
                "C++",
                "OCI",
                "Cloud Computing",
                "Virtualization",
                "Linux",
            ],
            detectedKeywords: [
                "Java",
                "Linux",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Virtualization",
                    recommendation: "Detail hypervisor management experience.",
                    placeholderTemplate: "Automated KVM virtual machine provisioning cutting instance spin-up time by 40%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-oracle-115",
            companyName: "Oracle",
            companySymbol: "cylinder.split.1x2.fill",
            roleTitle: "Database Systems Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "2d ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.oracle.com",
            aboutRole: "Contribute to Oracle's Autonomous Database kernel, distributed transaction coordination, and in-memory dual-format processing.",
            minimumQualifications: [
                "Strong foundation in C/C++, SQL, and operating systems.",
                "Understanding of database recovery, locking mechanisms, and query compilation.",
            ],
            preferredQualifications: [
                "Experience with database benchmarking (TPC-C).",
            ],
            applicantTips: [
                "Detail low-level storage optimization and index design.",
            ],
            responsibilities: [
                "Optimize query execution operator trees for in-memory columnar tables.",
                "Implement automated recovery checks for distributed database nodes.",
            ],
            skills: [
                "C++",
                "Oracle DB",
                "SQL",
                "Database Internals",
                "ACID",
                "Concurrency",
            ],
            detectedKeywords: [
                "C++",
                "SQL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Database Recovery",
                    recommendation: "Explain write-ahead logging resilience.",
                    placeholderTemplate: "Implemented automated WAL recovery procedure ensuring zero data loss during crash recovery tests."
                ),
            ]
        ),
        Opportunity(
            id: "opp-cisco-116",
            companyName: "Cisco",
            companySymbol: "network",
            roleTitle: "Network Security Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹75k - ₹1.0L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "2h ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.cisco.com",
            aboutRole: "Develop deep packet inspection algorithms, firewall threat mitigations, and zero-trust identity architectures.",
            minimumQualifications: [
                "Degree in CS, IT, or Telecommunications.",
                "Proficiency in C, C++, or Python.",
                "Deep understanding of TCP/IP stack, BGP/OSPF, and cryptography (TLS/IPsec).",
            ],
            preferredQualifications: [
                "Familiarity with Wireshark and network security analyzers.",
            ],
            applicantTips: [
                "Discuss packet throughput and latency overhead minimization.",
            ],
            responsibilities: [
                "Implement packet filtering logic capable of line-rate multi-gigabit inspection.",
                "Write automated network simulation scripts verifying route convergence.",
            ],
            skills: [
                "C++",
                "Python",
                "TCP/IP",
                "Network Security",
                "Firewalls",
                "Wireshark",
            ],
            detectedKeywords: [
                "C++",
                "Python",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Packet Inspection",
                    recommendation: "State packet throughput inspected.",
                    placeholderTemplate: "Optimized deep packet inspection engine processing 10Gbps line-rate traffic with minimal jitter."
                ),
            ]
        ),
        Opportunity(
            id: "opp-cisco-117",
            companyName: "Cisco",
            companySymbol: "network",
            roleTitle: "Embedded Systems Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹70k - ₹95k / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "3d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.cisco.com",
            aboutRole: "Write low-level firmware and device drivers for high-density enterprise routing hardware and optical switches.",
            minimumQualifications: [
                "Proficiency in C and embedded assembly.",
                "Understanding of memory-mapped I/O, DMA controllers, and interrupt service routines.",
            ],
            preferredQualifications: [
                "Hands-on experience with RTOS (FreeRTOS / VxWorks).",
            ],
            applicantTips: [
                "Detail hardware-software boundary and interrupt latency.",
            ],
            responsibilities: [
                "Develop interrupt handlers for high-speed network ASIC chips.",
                "Implement hardware diagnostics firmware detecting link degradation.",
            ],
            skills: [
                "C",
                "Embedded Systems",
                "RTOS",
                "Device Drivers",
                "Networking",
                "Microcontrollers",
            ],
            detectedKeywords: [
                "C",
                "Embedded Systems",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Interrupt Handling",
                    recommendation: "Specify interrupt service latency.",
                    placeholderTemplate: "Streamlined network ASIC interrupt handler reducing latency to sub-2 microseconds."
                ),
            ]
        ),
        Opportunity(
            id: "opp-intel-118",
            companyName: "Intel",
            companySymbol: "cpu.fill",
            roleTitle: "Systems Software Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 77,
            recency: "3h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.intel.com",
            aboutRole: "Optimize low-level hardware-accelerated machine learning runtimes (OpenVINO) and kernel drivers on Intel Core Ultra and Xeon processors.",
            minimumQualifications: [
                "CS, EE, or CE degree pursuing student.",
                "Strong C++ and Python skills.",
                "Understanding of x86-64 assembly, AVX-512, and CPU instruction pipelining.",
            ],
            preferredQualifications: [
                "Experience with compiler optimizations (LLVM/GCC) or hardware profiling (VTune).",
            ],
            applicantTips: [
                "Detail SIMD instruction vectorization and cache locality.",
            ],
            responsibilities: [
                "Vectorize neural network convolution layers using AVX-512 instructions.",
                "Profile CPU branch prediction penalties using Intel VTune.",
            ],
            skills: [
                "C++",
                "Python",
                "x86 Assembly",
                "OpenVINO",
                "AVX-512",
                "Computer Architecture",
            ],
            detectedKeywords: [
                "C++",
                "Computer Architecture",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "SIMD Vectorization",
                    recommendation: "State inference throughput gain.",
                    placeholderTemplate: "Vectorized tensor matrix multiplication with AVX-512 achieving 2.9x higher inference throughput."
                ),
            ]
        ),
        Opportunity(
            id: "opp-intel-119",
            companyName: "Intel",
            companySymbol: "cpu.fill",
            roleTitle: "Architecture & Firmware Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.1L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "2d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.intel.com",
            aboutRole: "Develop secure boot firmware (UEFI), power management telemetry, and thermal throttling controllers for next-generation silicon.",
            minimumQualifications: [
                "Proficiency in C and assembly.",
                "Understanding of UEFI architecture, ACPI power states, and cryptographic secure boot.",
            ],
            preferredQualifications: [
                "Experience with hardware debugging and logic analyzers.",
            ],
            applicantTips: [
                "Highlight secure boot integrity and power state transitions.",
            ],
            responsibilities: [
                "Write secure UEFI initialization drivers for high-speed PCIe buses.",
                "Implement dynamic power management algorithms maximizing battery life.",
            ],
            skills: [
                "C",
                "UEFI",
                "Firmware",
                "Hardware",
                "Security",
                "Power Management",
            ],
            detectedKeywords: [
                "C",
                "Firmware",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Secure Boot",
                    recommendation: "Detail cryptographic boot chain verification.",
                    placeholderTemplate: "Implemented TPM 2.0 cryptographic signature verification in UEFI firmware securing boot integrity."
                ),
            ]
        ),
        Opportunity(
            id: "opp-amd-120",
            companyName: "AMD",
            companySymbol: "cpu",
            roleTitle: "Silicon Software Intern",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .onSite,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 83,
            recency: "1h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.amd.com",
            aboutRole: "Develop GPU compute drivers (ROCm), open-source kernel modules, and heterogeneous computing runtimes for AMD Instinct accelerators.",
            minimumQualifications: [
                "Degree in CS/EE with focus on computer systems.",
                "Proficiency in C++, C, and Linux kernel programming.",
                "Understanding of GPU compute stacks (HIP, OpenCL, ROCm).",
            ],
            preferredQualifications: [
                "Experience with memory management unit (MMU) page table handling.",
            ],
            applicantTips: [
                "Highlight low-level kernel driver debugging and memory paging.",
            ],
            responsibilities: [
                "Optimize GPU virtual memory page fault handling in Linux kernel drivers.",
                "Write automated benchmark suites for HIP heterogeneous runtimes.",
            ],
            skills: [
                "C++",
                "C",
                "Linux Kernel",
                "ROCm",
                "GPU Computing",
                "Device Drivers",
            ],
            detectedKeywords: [
                "C++",
                "C",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "GPU Kernel Drivers",
                    recommendation: "Quantify memory page fault reduction.",
                    placeholderTemplate: "Tuned GPU virtual memory allocation pool reducing page fault handling overhead by 22%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-amd-121",
            companyName: "AMD",
            companySymbol: "cpu",
            roleTitle: "Compiler Optimization Intern",
            location: "Hyderabad, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 91,
            recency: "1d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: true,
            applicationDate: "121 days ago",
            externalCareersURL: "https://careers.amd.com",
            aboutRole: "Implement machine-specific loop unrolling, vectorization passes, and register allocation optimization inside LLVM for AMD Zen and RDNA architectures.",
            minimumQualifications: [
                "Solid foundation in compiler construction, LLVM infrastructure, and C++.",
                "Understanding of intermediate representations (IR), control flow graphs, and data-flow analysis.",
            ],
            preferredQualifications: [
                "Experience writing custom LLVM optimization passes.",
            ],
            applicantTips: [
                "Discuss instruction scheduling and register pressure trade-offs.",
            ],
            responsibilities: [
                "Implement auto-vectorization passes targeting AMD AVX-512 instructions.",
                "Benchmark generated binary performance across scientific compute benchmarks.",
            ],
            skills: [
                "C++",
                "LLVM",
                "Compilers",
                "Optimization",
                "Assembly",
                "Computer Architecture",
            ],
            detectedKeywords: [
                "C++",
                "Compilers",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "LLVM Optimization",
                    recommendation: "State benchmark runtime improvement.",
                    placeholderTemplate: "Authored custom LLVM loop unrolling pass accelerating dense linear algebra benchmarks by 18%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-vercel-122",
            companyName: "Vercel",
            companySymbol: "triangle.fill",
            roleTitle: "Next.js Framework Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.25L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 80,
            recency: "3h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.vercel.com",
            aboutRole: "Advance the Next.js App Router, React Server Components (RSC) streaming, and Turbopack Rust bundler.",
            minimumQualifications: [
                "Mastery of TypeScript, modern React, and web performance.",
                "Familiarity with Rust, compilers, and AST manipulation.",
            ],
            preferredQualifications: [
                "Deep understanding of server-side rendering, streaming HTML, and edge caching.",
            ],
            applicantTips: [
                "Highlight bundle size optimization and First Contentful Paint (FCP) metrics.",
            ],
            responsibilities: [
                "Build test suites validating React Server Component boundaries and streaming hydration.",
                "Optimize Turbopack incremental module compilation speed in Rust.",
            ],
            skills: [
                "TypeScript",
                "React",
                "Next.js",
                "Rust",
                "Web Performance",
                "Turbopack",
            ],
            detectedKeywords: [
                "TypeScript",
                "React",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Server Component Streaming",
                    recommendation: "Quantify First Contentful Paint improvement.",
                    placeholderTemplate: "Implemented granular React Server Component streaming reducing time to first byte by 35%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-vercel-123",
            companyName: "Vercel",
            companySymbol: "triangle.fill",
            roleTitle: "Edge Compute Platform Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 91,
            recency: "2d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.vercel.com",
            aboutRole: "Engineer global Vercel Edge Network routing, serverless function cold-start reduction, and instant cache invalidation.",
            minimumQualifications: [
                "Proficiency in Go, Rust, or Node.js.",
                "Understanding of V8 isolates, WebAssembly, and CDN edge computing.",
            ],
            preferredQualifications: [
                "Experience building high-speed reverse proxies and caching systems.",
            ],
            applicantTips: [
                "Discuss cold start latency budgeting and edge execution security.",
            ],
            responsibilities: [
                "Optimize V8 isolate spin-up time to achieve sub-5ms cold starts globally.",
                "Build real-time cache purge broadcast mechanisms across global edge points.",
            ],
            skills: [
                "Go",
                "Rust",
                "V8 Isolates",
                "Edge Computing",
                "WebAssembly",
                "CDN",
            ],
            detectedKeywords: [
                "Go",
                "Rust",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Cold Start Optimization",
                    recommendation: "Specify cold start reduction.",
                    placeholderTemplate: "Engineered lightweight V8 isolate pool delivering sub-4ms serverless execution startup globally."
                ),
            ]
        ),
        Opportunity(
            id: "opp-supabase-124",
            companyName: "Supabase",
            companySymbol: "cylinder.fill",
            roleTitle: "Backend Systems Intern - Postgres Core",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 84,
            recency: "4h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.supabase.com",
            aboutRole: "Extend the open-source Firebase alternative: build native Postgres extensions, real-time logical replication filters, and pgvector integrations.",
            minimumQualifications: [
                "Strong proficiency in Elixir, Go, or C.",
                "Deep knowledge of PostgreSQL internals, write-ahead logs (WAL), and logical decoding.",
            ],
            preferredQualifications: [
                "Active open-source contributor to database or backend ecosystems.",
            ],
            applicantTips: [
                "Highlight database extension development and real-time streaming.",
            ],
            responsibilities: [
                "Implement high-throughput Postgres WAL decoding streams in Elixir.",
                "Optimize vector indexing queries for large multimodal embeddings in pgvector.",
            ],
            skills: [
                "PostgreSQL",
                "Elixir",
                "Go",
                "pgvector",
                "Databases",
                "Open Source",
            ],
            detectedKeywords: [
                "PostgreSQL",
                "Go",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Logical Replication",
                    recommendation: "State streaming throughput and latency.",
                    placeholderTemplate: "Engineered Postgres WAL stream decoder processing 25,000 DB change events/sec with sub-20ms broadcast lag."
                ),
            ]
        ),
        Opportunity(
            id: "opp-supabase-125",
            companyName: "Supabase",
            companySymbol: "cylinder.fill",
            roleTitle: "Auth & Security Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 89,
            recency: "1d ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.supabase.com",
            aboutRole: "Advance Supabase GoTrue authentication: passkeys (WebAuthn), SAML enterprise SSO, and fine-grained Row Level Security (RLS) policies.",
            minimumQualifications: [
                "Proficiency in Go and SQL.",
                "Deep understanding of JWT cryptography, OAuth 2.0, WebAuthn, and PostgreSQL RLS.",
            ],
            preferredQualifications: [
                "Experience auditing authentication protocols and cryptographic signatures.",
            ],
            applicantTips: [
                "Detail enterprise compliance and secure token storage.",
            ],
            responsibilities: [
                "Implement WebAuthn passkey registration and biometric login flows in Go.",
                "Build automated RLS query performance linters identifying unindexed policy columns.",
            ],
            skills: [
                "Go",
                "PostgreSQL",
                "Security",
                "OAuth",
                "WebAuthn",
                "Authentication",
            ],
            detectedKeywords: [
                "Go",
                "Security",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Passkey Authentication",
                    recommendation: "Describe security and UX adoption.",
                    placeholderTemplate: "Implemented WebAuthn biometric passkey standard providing phishing-resistant authentication in under 200ms."
                ),
            ]
        ),
        Opportunity(
            id: "opp-canva-126",
            companyName: "Canva",
            companySymbol: "paintpalette.fill",
            roleTitle: "Visual Graphics Systems Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 82,
            recency: "2h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.canva.com",
            aboutRole: "Build modern photo manipulation, vector layout rendering, and generative design tools used by 170M+ monthly creators.",
            minimumQualifications: [
                "Proficiency in TypeScript, WebGL, and modern frontend architecture.",
                "Understanding of computer graphics, color spaces (sRGB/P3), and matrix transforms.",
            ],
            preferredQualifications: [
                "Experience building interactive creative canvas applications.",
            ],
            applicantTips: [
                "Detail 60fps frame rate maintenance under heavy vector loads.",
            ],
            responsibilities: [
                "Implement high-performance GPU shader filters for real-time photo effects.",
                "Build responsive layout grids with automatic typography reflow.",
            ],
            skills: [
                "TypeScript",
                "WebGL",
                "Graphics Programming",
                "Canvas",
                "UI Design",
                "Shaders",
            ],
            detectedKeywords: [
                "TypeScript",
                "WebGL",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "GPU Shaders",
                    recommendation: "State shader rendering speedup.",
                    placeholderTemplate: "Engineered custom WebGL fragment shader processing real-time blur and color adjustments at locked 60fps."
                ),
            ]
        ),
        Opportunity(
            id: "opp-canva-127",
            companyName: "Canva",
            companySymbol: "paintpalette.fill",
            roleTitle: "WebAssembly Rendering Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹90k - ₹1.3L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 91,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.canva.com",
            aboutRole: "Compile native C++ and Rust vector graphics rendering engines to WebAssembly for desktop-grade performance on the web.",
            minimumQualifications: [
                "Strong foundation in C++, Rust, and WebAssembly.",
                "Understanding of memory buffers (SharedArrayBuffer) and multi-threaded Web Workers.",
            ],
            preferredQualifications: [
                "Experience compiling complex native desktop codebases to Wasm.",
            ],
            applicantTips: [
                "Discuss memory allocation efficiency and canvas draw call reduction.",
            ],
            responsibilities: [
                "Optimize multi-threaded WebAssembly rendering pipeline using Web Workers.",
                "Profile memory footprint to ensure smooth tab execution under 100MB RAM.",
            ],
            skills: [
                "WebAssembly",
                "C++",
                "Rust",
                "Web Workers",
                "Graphics",
                "Performance",
            ],
            detectedKeywords: [
                "C++",
                "WebAssembly",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "WebAssembly Threading",
                    recommendation: "Quantify rendering latency reduction.",
                    placeholderTemplate: "Parallelized vector rasterization across 4 WebAssembly workers cutting design render time by 58%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-retool-128",
            companyName: "Retool",
            companySymbol: "macwindow",
            roleTitle: "Full Stack Engineering Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 75,
            recency: "3h ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.retool.com",
            aboutRole: "Build the drag-and-drop internal tool builder powering operations at Amazon, DoorDash, and Brex.",
            minimumQualifications: [
                "Proficiency in TypeScript, React, and Node.js.",
                "Understanding of state management, drag-and-drop canvas layout, and sandboxed code execution.",
            ],
            preferredQualifications: [
                "Experience with SQL databases and REST/GraphQL connectors.",
            ],
            applicantTips: [
                "Emphasize sandbox security and responsive layout flexibility.",
            ],
            responsibilities: [
                "Build custom UI components with bidirectional JavaScript data binding.",
                "Develop secure iframe sandboxing for custom customer script execution.",
            ],
            skills: [
                "TypeScript",
                "React",
                "Node.js",
                "Sandboxing",
                "Internal Tools",
                "SQL",
            ],
            detectedKeywords: [
                "TypeScript",
                "React",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Sandboxed Execution",
                    recommendation: "Describe security isolation design.",
                    placeholderTemplate: "Engineered isolated JavaScript evaluation sandbox safely running untrusted customer code with zero DOM escape vectors."
                ),
            ]
        ),
        Opportunity(
            id: "opp-retool-129",
            companyName: "Retool",
            companySymbol: "macwindow",
            roleTitle: "Cloud Components Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹80k - ₹1.15L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 88,
            recency: "2d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.retool.com",
            aboutRole: "Develop pre-built enterprise components: high-density editable data grids, Kanban boards, and complex charting widgets.",
            minimumQualifications: [
                "Strong proficiency in React, TypeScript, and CSS-in-JS.",
                "Experience building virtualized tables handling 100,000+ data rows with instant filtering.",
            ],
            preferredQualifications: [
                "Familiarity with accessibility and keyboard-first navigation.",
            ],
            applicantTips: [
                "Detail row virtualization algorithms and scrolling responsiveness.",
            ],
            responsibilities: [
                "Implement virtualized data grid with inline cell editing and bulk selection.",
                "Ensure full WCAG 2.1 keyboard accessibility compliance.",
            ],
            skills: [
                "TypeScript",
                "React",
                "Virtualization",
                "Data Grids",
                "CSS",
                "Accessibility",
            ],
            detectedKeywords: [
                "TypeScript",
                "React",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Table Virtualization",
                    recommendation: "State table rendering performance on large datasets.",
                    placeholderTemplate: "Implemented DOM row virtualization rendering 100,000 database rows with zero scroll hitching."
                ),
            ]
        ),
        Opportunity(
            id: "opp-cloudflare-130",
            companyName: "Cloudflare",
            companySymbol: "cloud.sun.fill",
            roleTitle: "Distributed Networking Intern - Workers",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹90k - ₹1.35L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 81,
            recency: "2h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.cloudflare.com",
            aboutRole: "Build high-speed serverless execution engines (Cloudflare Workers) and distributed key-value storage (KV) across 300+ global cities.",
            minimumQualifications: [
                "Proficiency in Rust, C++, or Go.",
                "Deep understanding of V8 isolate architecture, HTTP reverse proxies, and anycast routing.",
            ],
            preferredQualifications: [
                "Experience with eBPF, Linux network stack, or distributed storage.",
            ],
            applicantTips: [
                "Discuss single-millisecond execution overhead and memory safety.",
            ],
            responsibilities: [
                "Optimize V8 isolate memory recycling between incoming HTTP requests.",
                "Develop low-latency consensus protocols for global edge configuration propagation.",
            ],
            skills: [
                "Rust",
                "C++",
                "V8 Isolates",
                "Edge Computing",
                "Distributed Systems",
                "Networking",
            ],
            detectedKeywords: [
                "Rust",
                "C++",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Edge Isolates",
                    recommendation: "Specify isolate startup speed.",
                    placeholderTemplate: "Optimized V8 isolate initialization delivering sub-millisecond execution spin-up globally."
                ),
            ]
        ),
        Opportunity(
            id: "opp-cloudflare-131",
            companyName: "Cloudflare",
            companySymbol: "cloud.sun.fill",
            roleTitle: "DDoS Mitigation & Security Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹90k - ₹1.3L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 92,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.cloudflare.com",
            aboutRole: "Engineer automated real-time DDoS attack detection and kernel-bypass packet drop pipelines handling tens of millions of packets per second.",
            minimumQualifications: [
                "Strong foundation in C, Linux kernel networking, and eBPF / XDP.",
                "Understanding of TCP SYN floods, DNS amplification, and volumetric attacks.",
            ],
            preferredQualifications: [
                "Experience writing eBPF programs loaded directly into the network card driver layer.",
            ],
            applicantTips: [
                "Highlight line-rate packet drops with near-zero CPU overhead.",
            ],
            responsibilities: [
                "Write XDP/eBPF kernel programs inspecting incoming packets at the NIC driver level.",
                "Build automated rate-limiting algorithms dropping attack signatures in sub-seconds.",
            ],
            skills: [
                "C",
                "eBPF",
                "XDP",
                "Linux Networking",
                "DDoS Mitigation",
                "Cybersecurity",
            ],
            detectedKeywords: [
                "C",
                "eBPF",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "eBPF Packet Dropping",
                    recommendation: "Quantify packet drop rate.",
                    placeholderTemplate: "Authored XDP eBPF filter dropping volumetric SYN flood packets at 14 million packets/sec with zero CPU saturation."
                ),
            ]
        ),
        Opportunity(
            id: "opp-palantir-132",
            companyName: "Palantir",
            companySymbol: "circle.hexagongrid.fill",
            roleTitle: "Forward Deployed Software Engineer Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹95k - ₹1.4L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 85,
            recency: "1h ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: true,
            applicationDate: "132 days ago",
            externalCareersURL: "https://careers.palantir.com",
            aboutRole: "Deploy mission-critical data ontology and AI decision-making platforms (Foundry / AIP) directly solving high-stakes enterprise problems.",
            minimumQualifications: [
                "Degree in Computer Science, Math, or Engineering.",
                "Proficiency in Java, TypeScript, or Python.",
                "Passionate about applying software directly to real-world industrial and operational problems.",
            ],
            preferredQualifications: [
                "Strong technical leadership and client-facing communication skills.",
            ],
            applicantTips: [
                "Highlight end-to-end impact and enterprise data transformation.",
            ],
            responsibilities: [
                "Build custom ontology objects and decision automation workflows in Palantir Foundry.",
                "Partner with client engineering leads to integrate legacy transactional databases.",
            ],
            skills: [
                "Java",
                "TypeScript",
                "Python",
                "Data Ontology",
                "Enterprise Systems",
                "Distributed Data",
            ],
            detectedKeywords: [
                "Java",
                "Python",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Ontology Modeling",
                    recommendation: "Detail operational impact delivered.",
                    placeholderTemplate: "Architected operational ontology linking 50+ disparate data sources into a unified real-time analytics hub."
                ),
            ]
        ),
        Opportunity(
            id: "opp-palantir-133",
            companyName: "Palantir",
            companySymbol: "circle.hexagongrid.fill",
            roleTitle: "Foundry Platform Data Intern",
            location: "Bengaluru, India",
            opportunityType: .internship,
            workMode: .hybrid,
            salaryRange: "₹90k - ₹1.3L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 90,
            recency: "2d ago",
            cardColor: AlineTheme.cardSkyBlue,
            isLiked: true,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.palantir.com",
            aboutRole: "Optimize distributed data processing, dataset versioning, and row-level access control pipelines across petabyte-scale data lakes.",
            minimumQualifications: [
                "Proficiency in Java, Scala, or Python.",
                "Understanding of Apache Spark, distributed consensus, and fine-grained data governance.",
            ],
            preferredQualifications: [
                "Hands-on experience with big data transformations and pipeline lineage.",
            ],
            applicantTips: [
                "Discuss branch-based dataset versioning and audit trails.",
            ],
            responsibilities: [
                "Optimize distributed Spark SQL transforms across multi-billion-row tables.",
                "Build automated schema migration and backward-compatibility validators.",
            ],
            skills: [
                "Java",
                "Scala",
                "Apache Spark",
                "Big Data",
                "Data Governance",
                "SQL",
            ],
            detectedKeywords: [
                "Java",
                "Apache Spark",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Spark Transformations",
                    recommendation: "State compute cost and runtime reduction.",
                    placeholderTemplate: "Optimized Spark partition shuffling reducing large dataset join execution time by 48%."
                ),
            ]
        ),
        Opportunity(
            id: "opp-discord-134",
            companyName: "Discord",
            companySymbol: "bubble.left.and.bubble.right.fill",
            roleTitle: "Audio/Video Infrastructure Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹90k - ₹1.35L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 79,
            recency: "3h ago",
            cardColor: AlineTheme.cardMint,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.discord.com",
            aboutRole: "Work on Discord's massive real-time voice and video infrastructure written in Elixir, Rust, and C++.",
            minimumQualifications: [
                "Proficiency in Rust, C++, or Elixir.",
                "Deep understanding of WebRTC, RTP/RTCP packet transport, jitter buffers, and Opus audio codec.",
            ],
            preferredQualifications: [
                "Experience with real-time media streaming or VoIP protocols.",
            ],
            applicantTips: [
                "Highlight packet loss concealment and voice latency minimization.",
            ],
            responsibilities: [
                "Optimize audio packet jitter buffers for packet loss up to 20%.",
                "Build automated voice routing diagnostic monitors across global media relay servers.",
            ],
            skills: [
                "Rust",
                "Elixir",
                "C++",
                "WebRTC",
                "VoIP",
                "Distributed Systems",
            ],
            detectedKeywords: [
                "Rust",
                "C++",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Jitter Buffer Optimization",
                    recommendation: "State voice packet loss resilience.",
                    placeholderTemplate: "Tuned adaptive audio jitter buffer preserving crystal-clear voice clarity across 15% network packet loss."
                ),
            ]
        ),
        Opportunity(
            id: "opp-discord-135",
            companyName: "Discord",
            companySymbol: "bubble.left.and.bubble.right.fill",
            roleTitle: "Core Chat Systems Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.25L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 91,
            recency: "1d ago",
            cardColor: AlineTheme.cardLavender,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.discord.com",
            aboutRole: "Scale Discord's distributed messaging core managing millions of concurrent guild channels and billions of daily chat messages.",
            minimumQualifications: [
                "Proficiency in Elixir / Erlang, Rust, or Python.",
                "Understanding of the Actor model (BEAM), message queues, and ScyllaDB / Cassandra.",
            ],
            preferredQualifications: [
                "Experience handling massive concurrent WebSocket connections.",
            ],
            applicantTips: [
                "Discuss concurrent message fanout and state recovery.",
            ],
            responsibilities: [
                "Build high-throughput message fanout pipelines delivering chat to millions of connected guild members.",
                "Optimize ScyllaDB query performance under viral message spikes.",
            ],
            skills: [
                "Elixir",
                "Rust",
                "ScyllaDB",
                "Actor Model",
                "WebSockets",
                "Concurrency",
            ],
            detectedKeywords: [
                "Rust",
                "WebSockets",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Message Fanout",
                    recommendation: "Specify concurrent connection scale.",
                    placeholderTemplate: "Engineered WebSocket message fanout routing delivering 200,000 messages/sec with sub-10ms delivery latency."
                ),
            ]
        ),
        Opportunity(
            id: "opp-duolingo-136",
            companyName: "Duolingo",
            companySymbol: "character.book.closed.fill",
            roleTitle: "Mobile Learning Experience Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹85k - ₹1.2L / mo",
            experienceYears: "Freshers",
            eligibleGradYears: "2027 – 2028",
            matchScore: 83,
            recency: "2h ago",
            cardColor: AlineTheme.cardYellow,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.duolingo.com",
            aboutRole: "Develop joyful language learning micro-interactions, streak animations, and gamified quiz components on iOS and Android.",
            minimumQualifications: [
                "Proficiency in Swift (iOS) or Kotlin (Android).",
                "Strong eye for character animations, Lottie integration, and game-like progression loops.",
            ],
            preferredQualifications: [
                "Experience building interactive educational or gaming apps.",
            ],
            applicantTips: [
                "Highlight frame rate consistency and interactive sound design.",
            ],
            responsibilities: [
                "Implement custom gesture-driven sentence ordering and pronunciation practice views.",
                "Optimize interactive sound effect synchronization with animated visual rewards.",
            ],
            skills: [
                "Swift",
                "Kotlin",
                "Mobile UI",
                "Lottie",
                "Gamification",
                "Animation",
            ],
            detectedKeywords: [
                "Swift",
                "Kotlin",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Gamified Animations",
                    recommendation: "Detail user engagement or smooth 60fps execution.",
                    placeholderTemplate: "Built interactive streak animation using native spring curves achieving locked 60fps on mobile."
                ),
            ]
        ),
        Opportunity(
            id: "opp-duolingo-137",
            companyName: "Duolingo",
            companySymbol: "character.book.closed.fill",
            roleTitle: "AI Tutoring & NLP Intern",
            location: "Remote",
            opportunityType: .internship,
            workMode: .remote,
            salaryRange: "₹90k - ₹1.3L / mo",
            experienceYears: "0 - 1 years",
            eligibleGradYears: "2027 – 2028",
            matchScore: 92,
            recency: "2d ago",
            cardColor: AlineTheme.cardPeach,
            isLiked: false,
            isApplied: false,
            applicationDate: nil,
            externalCareersURL: "https://careers.duolingo.com",
            aboutRole: "Advance Duolingo Max conversational roleplay and personalized grammar explanation models powered by GPT-4 and custom speech analyzers.",
            minimumQualifications: [
                "Strong foundation in NLP, conversational AI, and speech evaluation.",
                "Proficiency in Python, PyTorch, and prompt engineering.",
            ],
            preferredQualifications: [
                "Familiarity with CEFR language proficiency levels and grammar error correction.",
            ],
            applicantTips: [
                "Discuss pedagogical safety and multilingual accuracy.",
            ],
            responsibilities: [
                "Fine-tune conversational dialogue agents adhering to specific CEFR language levels (A1 to C2).",
                "Build automated grammar correction evaluation benchmarks.",
            ],
            skills: [
                "Python",
                "PyTorch",
                "NLP",
                "LLMs",
                "Educational AI",
                "Speech Evaluation",
            ],
            detectedKeywords: [
                "Python",
                "NLP",
            ],
            missingKeywords: [
                MissingKeyword(
                    keyword: "Grammar Correction",
                    recommendation: "State accuracy on CEFR benchmark.",
                    placeholderTemplate: "Engineered targeted conversational prompt framework boosting CEFR vocabulary alignment to 96.2%."
                ),
            ]
        ),
    ]
}
