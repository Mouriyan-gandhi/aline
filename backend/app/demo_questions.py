"""
DEMO interview questions — placeholder content so every Interview Prep screen state can be seen
before the real question bank arrives: questions with a full contributor answer, with only a
hint/approach (the app then offers an on-device AI solution), with complexity notes, across
every topic, several companies and roles, and a spread of upvote counts.

All of it is owned by one system account (DEMO_DEVICE_ID), so it's removable in one step:
set SEED_DEMO_QUESTIONS=0 and call remove_demo_questions(), or delete that user's rows.
Seeding runs once at startup and only when no demo questions exist yet.
"""
import os
import uuid
from datetime import datetime, timedelta, timezone

from app.community_db import _connection, get_or_create_user

DEMO_DEVICE_ID = "aline-demo-question-seed"

# (company, role, topic, question, hint, approach, answer, time, space, upvotes)
QUESTIONS = [
    ("Google", "Software Engineer", "Array & DSA",
     "Given an array of integers and a target, return the indices of the two numbers that add up to the target.",
     "You only need one pass if you remember what you've already seen.",
     "Walk the array once, storing each value's index in a hash map. For each number, check whether target - number is already in the map.",
     "func twoSum(_ nums: [Int], _ target: Int) -> [Int] {\n    var seen: [Int: Int] = [:]\n    for (i, n) in nums.enumerated() {\n        if let j = seen[target - n] { return [j, i] }\n        seen[n] = i\n    }\n    return []\n}",
     "O(n)", "O(n)", 214),
    ("Google", "Software Engineer", "Array & DSA",
     "Find the length of the longest substring without repeating characters.",
     "Think sliding window: when does the left edge have to move?",
     "Keep a window [left, right] and the last index of each character. When a repeat appears inside the window, jump left past it.",
     None, "O(n)", "O(min(n, alphabet))", 162),
    ("Google", "Software Engineer", "System Design",
     "Design a URL shortener like bit.ly that handles 100 million new links a month.",
     "Start from read/write ratio and how you'll generate short keys without collisions.",
     "Base62-encode IDs from a distributed ID generator, store key → URL in a key-value store, put a CDN/cache in front for the read-heavy path, and add analytics asynchronously.",
     None, None, None, 98),
    ("Google", "Software Engineer", "Behavioral",
     "Tell me about a time you disagreed with a teammate on a technical decision. What happened?",
     "Use STAR: situation, task, action, result — and show what you learned.",
     None, None, None, None, 57),
    ("Microsoft", "Software Engineer", "Array & DSA",
     "Reverse a singly linked list in place.",
     "You need three pointers: previous, current and next.",
     "Iterate once, pointing each node's next back at the previous node.",
     "func reverse(_ head: ListNode?) -> ListNode? {\n    var prev: ListNode? = nil\n    var curr = head\n    while let node = curr {\n        let next = node.next\n        node.next = prev\n        prev = node\n        curr = next\n    }\n    return prev\n}",
     "O(n)", "O(1)", 131),
    ("Microsoft", "Software Engineer", "Operating Systems",
     "What is the difference between a process and a thread? When would you use each?",
     "Compare memory isolation, creation cost and communication.",
     None,
     "A process has its own address space; threads share their process's memory. Threads are cheaper to create and switch and communicate through shared memory, but need synchronization. Use processes for isolation and fault containment, threads for concurrency within one task.",
     None, None, 74),
    ("Microsoft", "Data Analyst", "Databases",
     "Write a SQL query to find the second highest salary in an Employees table.",
     "What if two people share the highest salary?",
     "Use a subquery for the max, then take the max below it — or DENSE_RANK.",
     "SELECT MAX(salary) AS second_highest\nFROM Employees\nWHERE salary < (SELECT MAX(salary) FROM Employees);",
     None, None, 88),
    ("Amazon", "Software Engineer", "Array & DSA",
     "Given a 2D grid of '1's (land) and '0's (water), count the number of islands.",
     "Each time you find unvisited land, how much of the grid should you mark?",
     "Scan the grid; on each '1', run DFS/BFS to sink the whole island and increment the count.",
     None, "O(rows × cols)", "O(rows × cols)", 176),
    ("Amazon", "Software Engineer", "Behavioral",
     "Describe a time you had to deliver results under a tight deadline. (Leadership Principle: Deliver Results)",
     "Quantify the outcome and say what you de-prioritized.",
     "Pick a story with a measurable result; explain the trade-offs you made and how you kept stakeholders informed.",
     None, None, None, 66),
    ("Amazon", "Backend Engineer", "System Design",
     "Design the order history service for an e-commerce site with millions of daily orders.",
     "Think about access patterns: who reads order history, and how far back?",
     None, None, None, None, 41),
    ("Apple", "Software Engineer", "Core CS",
     "Explain how ARC (Automatic Reference Counting) works and how retain cycles happen.",
     "What happens to the count when two objects hold strong references to each other?",
     "ARC inserts retain/release at compile time. Two objects strongly referencing each other never reach zero; break the cycle with weak or unowned references.",
     None, None, None, 49),
    ("Apple", "iOS / Mobile Engineer", "Core CS",
     "What's the difference between a struct and a class in Swift, and when would you choose each?",
     "Value vs reference semantics.",
     None,
     "Structs are value types (copied on assignment, no inheritance, no deinit); classes are reference types with identity and inheritance. Prefer structs for data models; use classes when you need shared mutable state, identity or Objective-C interop.",
     None, None, 63),
    ("Meta", "Software Engineer", "Array & DSA",
     "Given a binary tree, return its level-order traversal.",
     "Which data structure gives you nodes in the order they were discovered?",
     "BFS with a queue, processing one level's worth of nodes per iteration.",
     None, "O(n)", "O(n)", 102),
    ("Meta", "Product Manager", "Behavioral",
     "How would you improve Instagram Stories for first-time creators?",
     "Define the user, the problem, and how you'd measure success.",
     None, None, None, None, 23),
    ("Flipkart", "Software Engineer", "System Design",
     "Design a flash-sale system that sells 10,000 units to millions of users in seconds without overselling.",
     "Where does the inventory counter live, and how do you protect it from the spike?",
     "Queue requests, decrement inventory atomically in an in-memory store (e.g. Redis DECR), confirm orders asynchronously, and rate-limit at the edge.",
     None, None, None, 85),
    ("Flipkart", "Backend Engineer", "Databases",
     "When would you pick a NoSQL database over a relational one?",
     None, None, None, None, None, 12),
    ("Goldman Sachs", "Software Engineer", "Array & DSA",
     "Find the maximum subarray sum.",
     "Kadane's algorithm: when should you start a new subarray?",
     "Track the best sum ending at each index: either extend the previous subarray or start fresh at this element.",
     "func maxSubArray(_ nums: [Int]) -> Int {\n    var best = nums[0], current = nums[0]\n    for n in nums.dropFirst() {\n        current = max(n, current + n)\n        best = max(best, current)\n    }\n    return best\n}",
     "O(n)", "O(1)", 93),
    ("Goldman Sachs", "Quantitative Analyst", "Core CS",
     "You flip a fair coin until you get two heads in a row. What's the expected number of flips?",
     "Set up equations for the expected flips from each state.",
     None, "6 flips. With E0 from the start and E1 after one head: E0 = 1 + ½E1 + ½E0 and E1 = 1 + ½·0 + ½E0, giving E0 = 6.",
     None, None, 38),
    ("Uber", "Backend Engineer", "Networking",
     "What happens when you type a URL into the browser and press Enter?",
     "Go layer by layer: DNS, TCP, TLS, HTTP, rendering.",
     None, None, None, None, 71),
    ("Uber", "DevOps Engineer", "Networking",
     "Explain the difference between TCP and UDP and give a use case for each.",
     None, None,
     "TCP is connection-oriented with ordered, reliable delivery and congestion control — used for HTTP, databases. UDP is connectionless and unordered with lower overhead — used for video calls, DNS, gaming.",
     None, None, 34),
    ("Nvidia", "AI/ML Engineer", "AI & ML",
     "Explain the bias–variance trade-off and how regularization affects it.",
     "What does an overfit model look like on training vs validation data?",
     "High bias underfits, high variance overfits. Regularization (L1/L2, dropout) adds a penalty that lowers variance at the cost of some bias.",
     None, None, None, 59),
    ("Nvidia", "AI/ML Engineer", "AI & ML",
     "How does self-attention in a transformer work?",
     "Queries, keys and values.",
     None, None, "O(n²·d)", "O(n²)", 47),
    ("Databricks", "Data Analyst", "Databases",
     "Explain the difference between INNER JOIN, LEFT JOIN and FULL OUTER JOIN with an example.",
     None,
     "Draw two small tables and show which rows survive each join.",
     None, None, None, 19),
    ("Infosys", "Software Engineer", "Core CS",
     "What are the four pillars of object-oriented programming?",
     "Encapsulation, abstraction, inheritance, polymorphism — give an example of each.",
     None,
     "Encapsulation hides state behind methods; abstraction exposes only what's needed; inheritance reuses behavior from a parent; polymorphism lets one interface have many implementations.",
     None, None, 28),
    ("TCS", "Software Engineer", "Operating Systems",
     "What is a deadlock and what are the four conditions for it?",
     None, None, None, None, None, 9),
    ("Wells Fargo", "Software Engineer", "Behavioral",
     "Why do you want to work in financial technology?",
     None, None, None, None, None, 4),
    (None, "Software Engineer", "Array & DSA",
     "Detect whether a linked list has a cycle.",
     "Two runners at different speeds.",
     "Floyd's tortoise and hare: a fast pointer moving two steps will meet the slow pointer if there's a cycle.",
     None, "O(n)", "O(1)", 1),
]


def seed_demo_questions() -> int:
    if os.environ.get("SEED_DEMO_QUESTIONS", "1") == "0":
        return 0
    user = get_or_create_user(DEMO_DEVICE_ID)
    with _connection() as conn:
        if conn.execute("SELECT 1 FROM interview_questions WHERE user_id = ? LIMIT 1", (user["id"],)).fetchone():
            return 0
        now = datetime.now(timezone.utc)
        for i, (company, role, topic, question, hint, approach, answer, time_c, space_c, upvotes) in enumerate(QUESTIONS):
            conn.execute(
                """
                INSERT INTO interview_questions
                    (id, user_id, company, role, topic, question, difficulty, hint, approach, answer,
                     time_complexity, space_complexity, upvotes_count, created_at)
                VALUES (?, ?, ?, ?, ?, ?, 'General', ?, ?, ?, ?, ?, ?, ?)
                """,
                (str(uuid.uuid4()), user["id"], company, role, topic, question, hint, approach, answer,
                 time_c, space_c, upvotes, (now - timedelta(hours=6 * i)).isoformat()),
            )
    return len(QUESTIONS)


def remove_demo_questions() -> None:
    user = get_or_create_user(DEMO_DEVICE_ID)
    with _connection() as conn:
        ids = [r["id"] for r in conn.execute("SELECT id FROM interview_questions WHERE user_id = ?", (user["id"],))]
        for question_id in ids:
            conn.execute("DELETE FROM question_upvotes WHERE question_id = ?", (question_id,))
            conn.execute("DELETE FROM question_saves WHERE question_id = ?", (question_id,))
        conn.execute("DELETE FROM interview_questions WHERE user_id = ?", (user["id"],))
