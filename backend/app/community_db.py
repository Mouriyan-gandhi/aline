"""
SQLite persistence for Community — the app's first feature that actually needs to persist
data (jobs are re-scraped, never stored; Community posts/comments/identities are real user
content that has to survive a backend restart). Plain stdlib sqlite3, no SQLAlchemy/Alembic —
a handful of simple tables doesn't justify that weight, and this stays consistent with the
project's $0-budget, nothing-built-ahead-of-need approach (see the architecture plan's backend
section: Postgres was explicitly deferred until something needed it; this is that something,
but SQLite is still the honest answer at this scale, not Postgres either).

Identity model: there is no real account system yet (no sign-up, no password, no OAuth — the
onboarding "Sign in" buttons are explicitly stubbed, see OnboardingView.swift). Identity is
device-scoped: the iOS client generates a UUID once, persists it locally, and sends it as
`device_id` on every request that needs it. The server maps device_id -> a user row, creating
one (with a system-generated, unique, immutable username) the first time it sees that
device_id. This is a REAL LIMITATION worth stating plainly: a device_id is trivially spoofable
(no auth, no signature) and a reinstalled app loses its identity. Acceptable for an anonymous
community MVP where the worst case of spoofing is "someone posts under a username that isn't
theirs," not an account-takeover or data-leak risk — revisit once real auth exists.

The `users` table is shared by two features, not Community-only despite this module's name:
Community (the anonymous `username`) and Profile (app/profile.py — the real identity fields:
name, education, links). Same device_id, same row, two different concerns — a user's anonymous
community handle and their real profile are deliberately separate columns on one row, matching
the product's own stated rule (see Figma's Edit Profile screen: "Your community posts use your
anonymous identity, not your profile name").
"""
import json
import random
import sqlite3
import uuid
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

DB_PATH = Path(__file__).resolve().parent.parent / "data" / "community.db"

CATEGORIES = [
    "Interview Experience",
    "Work Experience",
    "Recruitment Experience",
    "General Discussion",
]

# The Figma filter sheet's "Topics" chips (fileKey AiSKBBDDO9rIzyUPHmRm98, node 887:20692) —
# a fixed set, same pattern as CATEGORIES, not free-text tags.
TOPICS = ["DSA", "Interview prep", "Work culture", "Salary", "Career advice"]

_ADJECTIVES = [
    "Quiet", "Swift", "Bold", "Calm", "Sharp", "Bright", "Steady", "Clever", "Keen", "Quick",
    "Silent", "Brave", "Gentle", "Fierce", "Nimble", "Wise", "Lucky", "Sunny", "Rapid", "Vivid",
]
_NOUNS = [
    "Falcon", "Otter", "Maple", "Comet", "Harbor", "Ember", "Ridge", "Delta", "Lotus", "Pike",
    "Heron", "Cedar", "Quartz", "Sable", "Wren", "Aspen", "Drift", "Hollow", "Juniper", "Tundra",
]


# Must match the avatar image set names bundled in the iOS app (DiscussionPost.allAvatars).
AVATARS = [
    "avatar_fox", "avatar_owl", "avatar_cat", "avatar_dog", "avatar_bunny",
    "avatar_bear", "avatar_panda", "avatar_redpanda", "avatar_raccoon", "avatar_tiger",
    "avatar_lion", "avatar_koala", "avatar_sloth", "avatar_deer", "avatar_hedgehog",
    "avatar_squirrel", "avatar_otter", "avatar_beaver", "avatar_wolf", "avatar_penguin",
    "avatar_duck", "avatar_chicken", "avatar_frog", "avatar_turtle", "avatar_alligator",
    "avatar_whale", "avatar_dolphin", "avatar_seal", "avatar_octopus", "avatar_axolotl",
    "avatar_fish", "avatar_shark", "avatar_bee", "avatar_butterfly", "avatar_ladybug",
    "avatar_parrot", "avatar_toucan", "avatar_raven", "avatar_flamingo", "avatar_swan",
    "avatar_horse", "avatar_alpaca", "avatar_llama", "avatar_elephant", "avatar_giraffe",
    "avatar_monkey", "avatar_capybara", "avatar_hamster", "avatar_bat", "avatar_dragon",
]


def _generate_username() -> str:
    return f"{random.choice(_ADJECTIVES)}{random.choice(_NOUNS)}{random.randint(100, 999)}"


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


@contextmanager
def _connection():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db() -> None:
    with _connection() as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                device_id TEXT UNIQUE NOT NULL,
                username TEXT UNIQUE NOT NULL,
                role_title TEXT,
                created_at TEXT NOT NULL,
                name TEXT,
                education TEXT,
                institution TEXT,
                specialization TEXT,
                graduation_year INTEGER,
                career_stage TEXT,
                linkedin TEXT,
                github TEXT,
                portfolio TEXT,
                skills TEXT,
                experience TEXT,
                projects TEXT
            );

            CREATE TABLE IF NOT EXISTS discussions (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL REFERENCES users(id),
                category TEXT NOT NULL,
                company TEXT,
                title TEXT NOT NULL,
                body TEXT NOT NULL,
                created_at TEXT NOT NULL,
                likes_count INTEGER NOT NULL DEFAULT 0,
                comments_count INTEGER NOT NULL DEFAULT 0,
                topics TEXT NOT NULL DEFAULT '[]'
            );

            CREATE TABLE IF NOT EXISTS comments (
                id TEXT PRIMARY KEY,
                discussion_id TEXT NOT NULL REFERENCES discussions(id),
                user_id TEXT NOT NULL REFERENCES users(id),
                body TEXT NOT NULL,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS likes (
                user_id TEXT NOT NULL REFERENCES users(id),
                discussion_id TEXT NOT NULL REFERENCES discussions(id),
                PRIMARY KEY (user_id, discussion_id)
            );

            -- Distinct from likes: a bookmark is "save for later," not an engagement signal —
            -- matches the Figma design's separate bookmark icon on every discussion card.
            CREATE TABLE IF NOT EXISTS saved_posts (
                user_id TEXT NOT NULL REFERENCES users(id),
                discussion_id TEXT NOT NULL REFERENCES discussions(id),
                created_at TEXT NOT NULL,
                PRIMARY KEY (user_id, discussion_id)
            );

            CREATE TABLE IF NOT EXISTS followed_companies (
                user_id TEXT NOT NULL REFERENCES users(id),
                company TEXT NOT NULL,
                created_at TEXT NOT NULL,
                PRIMARY KEY (user_id, company)
            );

            CREATE TABLE IF NOT EXISTS feedback (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL REFERENCES users(id),
                category TEXT NOT NULL,
                message TEXT NOT NULL,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS comment_likes (
                user_id TEXT NOT NULL REFERENCES users(id),
                comment_id TEXT NOT NULL REFERENCES comments(id),
                created_at TEXT NOT NULL,
                PRIMARY KEY (user_id, comment_id)
            );

            -- Interview Questions (Community tab's Interview Prep) — community-contributed, same
            -- device identity as discussions. Answer/hint/approach are only ever what the
            -- contributor wrote; nothing is pre-filled server-side.
            CREATE TABLE IF NOT EXISTS interview_questions (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL REFERENCES users(id),
                company TEXT,
                role TEXT,
                topic TEXT NOT NULL,
                question TEXT NOT NULL,
                difficulty TEXT NOT NULL DEFAULT 'General',
                hint TEXT,
                approach TEXT,
                answer TEXT,
                time_complexity TEXT,
                space_complexity TEXT,
                upvotes_count INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS question_upvotes (
                user_id TEXT NOT NULL REFERENCES users(id),
                question_id TEXT NOT NULL REFERENCES interview_questions(id),
                created_at TEXT NOT NULL,
                PRIMARY KEY (user_id, question_id)
            );

            CREATE TABLE IF NOT EXISTS question_saves (
                user_id TEXT NOT NULL REFERENCES users(id),
                question_id TEXT NOT NULL REFERENCES interview_questions(id),
                created_at TEXT NOT NULL,
                PRIMARY KEY (user_id, question_id)
            );

            -- Resumes are opaque JSON documents the app owns the shape of (sections, template,
            -- tailoring target) — the server only stores and returns them per identity.
            CREATE TABLE IF NOT EXISTS resumes (
                id TEXT NOT NULL,
                user_id TEXT NOT NULL REFERENCES users(id),
                data TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                PRIMARY KEY (user_id, id)
            );

            -- Liked / applied jobs. job_json is a snapshot of the job at the time it was marked,
            -- so the Liked/Applied lists still show a posting after it closes and drops out of
            -- the live /jobs feed.
            CREATE TABLE IF NOT EXISTS job_marks (
                user_id TEXT NOT NULL REFERENCES users(id),
                job_id TEXT NOT NULL,
                liked INTEGER NOT NULL DEFAULT 0,
                applied INTEGER NOT NULL DEFAULT 0,
                applied_at TEXT,
                job_json TEXT,
                updated_at TEXT NOT NULL,
                PRIMARY KEY (user_id, job_id)
            );

            CREATE INDEX IF NOT EXISTS idx_discussions_category ON discussions(category);
            CREATE INDEX IF NOT EXISTS idx_comments_discussion ON comments(discussion_id);
            CREATE INDEX IF NOT EXISTS idx_questions_company ON interview_questions(company);
            """
        )
        # CREATE TABLE IF NOT EXISTS doesn't add columns to a users table that already existed
        # on disk from before the profile fields were added — a real DB file from the earlier
        # Community-only schema exists in this project right now. ALTER TABLE ADD COLUMN is the
        # lightweight equivalent of a migration at this scale (no Alembic, see module docstring).
        existing_columns = {row["name"] for row in conn.execute("PRAGMA table_info(users)")}
        profile_columns = {
            "name": "TEXT", "education": "TEXT", "institution": "TEXT", "specialization": "TEXT",
            "graduation_year": "INTEGER", "career_stage": "TEXT",
            "linkedin": "TEXT", "github": "TEXT", "portfolio": "TEXT",
            # JSON-encoded as TEXT — these are lists/objects, not scalar columns. See profile.py
            # for the encode/decode boundary (the DB layer stores opaque strings; profile.py is
            # where "list[ExperienceEntry]" becomes real structure again).
            "skills": "TEXT", "experience": "TEXT", "projects": "TEXT",
            # Added for the final frontend's profile screen: headline line under the name,
            # location, bio, the achievement gallery and career preferences (both JSON).
            "headline": "TEXT", "location": "TEXT", "bio": "TEXT",
            "achievements": "TEXT", "preferences": "TEXT",
            # Community avatar key — one of AVATARS, assigned once like the username.
            "avatar": "TEXT",
        }
        for column, sql_type in profile_columns.items():
            if column not in existing_columns:
                conn.execute(f"ALTER TABLE users ADD COLUMN {column} {sql_type}")

        existing_discussion_columns = {row["name"] for row in conn.execute("PRAGMA table_info(discussions)")}
        if "topics" not in existing_discussion_columns:
            conn.execute("ALTER TABLE discussions ADD COLUMN topics TEXT NOT NULL DEFAULT '[]'")
        if "shares_count" not in existing_discussion_columns:
            conn.execute("ALTER TABLE discussions ADD COLUMN shares_count INTEGER NOT NULL DEFAULT 0")

        existing_comment_columns = {row["name"] for row in conn.execute("PRAGMA table_info(comments)")}
        if "parent_id" not in existing_comment_columns:
            conn.execute("ALTER TABLE comments ADD COLUMN parent_id TEXT")
        if "likes_count" not in existing_comment_columns:
            conn.execute("ALTER TABLE comments ADD COLUMN likes_count INTEGER NOT NULL DEFAULT 0")

        # Likes predate notifications; "liked your post" needs to know when.
        existing_like_columns = {row["name"] for row in conn.execute("PRAGMA table_info(likes)")}
        if "created_at" not in existing_like_columns:
            conn.execute("ALTER TABLE likes ADD COLUMN created_at TEXT")


def get_or_create_user(device_id: str, role_title: Optional[str] = None) -> sqlite3.Row:
    with _connection() as conn:
        row = conn.execute("SELECT * FROM users WHERE device_id = ?", (device_id,)).fetchone()
        if row:
            if not row["avatar"]:
                # Users created before avatars existed get one on first sight, then keep it.
                conn.execute("UPDATE users SET avatar = ? WHERE id = ?", (random.choice(AVATARS), row["id"]))
                row = conn.execute("SELECT * FROM users WHERE id = ?", (row["id"],)).fetchone()
            return row

        # Collision is astronomically unlikely (20 * 20 * 900 ≈ 360k combinations) but the
        # unique constraint is the real guarantee — retry on the rare clash rather than trust
        # the odds alone.
        for _ in range(10):
            username = _generate_username()
            try:
                user_id = str(uuid.uuid4())
                conn.execute(
                    "INSERT INTO users (id, device_id, username, role_title, created_at, avatar) VALUES (?, ?, ?, ?, ?, ?)",
                    (user_id, device_id, username, role_title, _now(), random.choice(AVATARS)),
                )
                return conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
            except sqlite3.IntegrityError:
                continue
        raise RuntimeError("Could not generate a unique username after 10 attempts")


def create_discussion(
    user_id: str, category: str, company: Optional[str], title: str, body: str,
    topics: Optional[list[str]] = None,
) -> str:
    discussion_id = str(uuid.uuid4())
    with _connection() as conn:
        conn.execute(
            "INSERT INTO discussions (id, user_id, category, company, title, body, created_at, topics) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (discussion_id, user_id, category, company, title.strip(), body.strip(), _now(), json.dumps(topics or [])),
        )
    return discussion_id


def list_discussions(
    category: Optional[str], sort: str, viewer_user_id: Optional[str],
    companies: Optional[list[str]] = None,
    only_saved: bool = False,
    topics: Optional[list[str]] = None,
) -> list[dict]:
    order_by = {
        "newest": "d.created_at DESC",
        "liked": "d.likes_count DESC, d.created_at DESC",
        # No real relevance signal exists yet (no view counts, no personalization) — rather
        # than fabricate one, "relevant" is an honest proxy: engagement (likes + comments)
        # first, recency as the tiebreaker. Documented here so it's never mistaken for a
        # real ranking model.
        "relevant": "(d.likes_count + d.comments_count) DESC, d.created_at DESC",
    }.get(sort, "d.created_at DESC")

    conditions = []
    params: list = [viewer_user_id or "", viewer_user_id or ""]
    if category:
        conditions.append("d.category = ?")
        params.append(category)
    if companies:
        placeholders = ", ".join("?" for _ in companies)
        conditions.append(f"d.company IN ({placeholders})")
        params.extend(companies)
    if only_saved:
        conditions.append("EXISTS (SELECT 1 FROM saved_posts sp WHERE sp.discussion_id = d.id AND sp.user_id = ?)")
        params.append(viewer_user_id or "")
    if topics:
        placeholders = ", ".join("?" for _ in topics)
        conditions.append(f"EXISTS (SELECT 1 FROM json_each(d.topics) je WHERE je.value IN ({placeholders}))")
        params.extend(topics)

    where_clause = f"WHERE {' AND '.join(conditions)}" if conditions else ""
    query = f"""
        SELECT d.*, u.username, u.role_title, u.avatar,
               EXISTS(SELECT 1 FROM likes l WHERE l.discussion_id = d.id AND l.user_id = ?) AS liked_by_me,
               EXISTS(SELECT 1 FROM saved_posts sp WHERE sp.discussion_id = d.id AND sp.user_id = ?) AS saved_by_me
        FROM discussions d
        JOIN users u ON u.id = d.user_id
        {where_clause}
        ORDER BY {order_by}
    """

    with _connection() as conn:
        rows = conn.execute(query, params).fetchall()
    return [dict(row) for row in rows]


def get_discussion(discussion_id: str, viewer_user_id: Optional[str]) -> Optional[dict]:
    with _connection() as conn:
        row = conn.execute(
            """
            SELECT d.*, u.username, u.role_title, u.avatar,
                   EXISTS(SELECT 1 FROM likes l WHERE l.discussion_id = d.id AND l.user_id = ?) AS liked_by_me,
                   EXISTS(SELECT 1 FROM saved_posts sp WHERE sp.discussion_id = d.id AND sp.user_id = ?) AS saved_by_me
            FROM discussions d
            JOIN users u ON u.id = d.user_id
            WHERE d.id = ?
            """,
            (viewer_user_id or "", viewer_user_id or "", discussion_id),
        ).fetchone()
        if row is None:
            return None
        comments = conn.execute(
            """
            SELECT c.*, u.username, u.role_title, u.avatar,
                   EXISTS(SELECT 1 FROM comment_likes cl WHERE cl.comment_id = c.id AND cl.user_id = ?) AS liked_by_me
            FROM comments c
            JOIN users u ON u.id = c.user_id
            WHERE c.discussion_id = ?
            ORDER BY c.created_at ASC
            """,
            (viewer_user_id or "", discussion_id),
        ).fetchall()
    result = dict(row)
    result["comments"] = [dict(c) for c in comments]
    return result


def add_comment(discussion_id: str, user_id: str, body: str, parent_id: Optional[str] = None) -> Optional[sqlite3.Row]:
    """`parent_id` makes this a reply. Replies are one level deep, like the app's thread UI —
    a reply to a reply attaches to the top-level comment it sits under."""
    comment_id = str(uuid.uuid4())
    created_at = _now()
    with _connection() as conn:
        exists = conn.execute("SELECT 1 FROM discussions WHERE id = ?", (discussion_id,)).fetchone()
        if not exists:
            return None
        if parent_id:
            parent = conn.execute(
                "SELECT id, parent_id FROM comments WHERE id = ? AND discussion_id = ?", (parent_id, discussion_id)
            ).fetchone()
            if parent is None:
                return None
            parent_id = parent["parent_id"] or parent["id"]
        conn.execute(
            "INSERT INTO comments (id, discussion_id, user_id, body, created_at, parent_id) VALUES (?, ?, ?, ?, ?, ?)",
            (comment_id, discussion_id, user_id, body.strip(), created_at, parent_id),
        )
        conn.execute(
            "UPDATE discussions SET comments_count = comments_count + 1 WHERE id = ?",
            (discussion_id,),
        )
        return conn.execute(
            """
            SELECT c.*, u.username, u.role_title, u.avatar, 0 AS liked_by_me FROM comments c
            JOIN users u ON u.id = c.user_id WHERE c.id = ?
            """,
            (comment_id,),
        ).fetchone()


def toggle_like(discussion_id: str, user_id: str) -> Optional[bool]:
    """Returns the new liked state, or None if the discussion doesn't exist."""
    with _connection() as conn:
        exists = conn.execute("SELECT 1 FROM discussions WHERE id = ?", (discussion_id,)).fetchone()
        if not exists:
            return None
        already_liked = conn.execute(
            "SELECT 1 FROM likes WHERE discussion_id = ? AND user_id = ?", (discussion_id, user_id)
        ).fetchone()
        if already_liked:
            conn.execute(
                "DELETE FROM likes WHERE discussion_id = ? AND user_id = ?", (discussion_id, user_id)
            )
            conn.execute(
                "UPDATE discussions SET likes_count = likes_count - 1 WHERE id = ?", (discussion_id,)
            )
            return False
        conn.execute(
            "INSERT INTO likes (user_id, discussion_id, created_at) VALUES (?, ?, ?)", (user_id, discussion_id, _now())
        )
        conn.execute(
            "UPDATE discussions SET likes_count = likes_count + 1 WHERE id = ?", (discussion_id,)
        )
        return True


# MARK: - Profile (shares the users table — see module docstring)

PROFILE_FIELDS = [
    "name", "education", "institution", "specialization",
    "graduation_year", "career_stage", "linkedin", "github", "portfolio",
    "skills", "experience", "projects",
    "headline", "location", "bio", "achievements", "preferences",
]


def update_profile(device_id: str, fields: dict) -> sqlite3.Row:
    """`fields` is a dict of PROFILE_FIELDS -> new value; keys not present are left untouched
    (a PATCH-like partial update), matching how EditProfileView sends only its own form
    fields — it was never responsible for role_title/username, those belong to Community."""
    user = get_or_create_user(device_id)
    updates = {k: v for k, v in fields.items() if k in PROFILE_FIELDS}
    if not updates:
        return user
    set_clause = ", ".join(f"{k} = ?" for k in updates)
    with _connection() as conn:
        conn.execute(f"UPDATE users SET {set_clause} WHERE id = ?", (*updates.values(), user["id"]))
        return conn.execute("SELECT * FROM users WHERE id = ?", (user["id"],)).fetchone()


def delete_account(device_id: str) -> None:
    """Full cascade delete — "delete my account" means actually forgetting everything tied to
    this identity, not leaving orphaned discussions/comments behind with a dangling user_id.
    No-op if the device_id has no user row (nothing to delete)."""
    with _connection() as conn:
        user = conn.execute("SELECT id FROM users WHERE device_id = ?", (device_id,)).fetchone()
        if not user:
            return
        user_id = user["id"]
        discussion_ids = [r["id"] for r in conn.execute("SELECT id FROM discussions WHERE user_id = ?", (user_id,))]
        for discussion_id in discussion_ids:
            conn.execute(
                "DELETE FROM comment_likes WHERE comment_id IN (SELECT id FROM comments WHERE discussion_id = ?)",
                (discussion_id,),
            )
            conn.execute("DELETE FROM likes WHERE discussion_id = ?", (discussion_id,))
            conn.execute("DELETE FROM saved_posts WHERE discussion_id = ?", (discussion_id,))
            conn.execute("DELETE FROM comments WHERE discussion_id = ?", (discussion_id,))
        conn.execute("DELETE FROM discussions WHERE user_id = ?", (user_id,))
        # Own comments elsewhere: their replies and likes go with them, and the counts they
        # contributed to on other people's posts come back down.
        own_comments = conn.execute("SELECT id, discussion_id FROM comments WHERE user_id = ?", (user_id,)).fetchall()
        for comment in own_comments:
            _delete_comment_tree(conn, comment["id"], comment["discussion_id"])
        conn.execute(
            "UPDATE discussions SET likes_count = likes_count - 1 "
            "WHERE id IN (SELECT discussion_id FROM likes WHERE user_id = ?)", (user_id,),
        )
        conn.execute(
            "UPDATE comments SET likes_count = likes_count - 1 "
            "WHERE id IN (SELECT comment_id FROM comment_likes WHERE user_id = ?)", (user_id,),
        )
        conn.execute("DELETE FROM comment_likes WHERE user_id = ?", (user_id,))
        conn.execute(
            "UPDATE interview_questions SET upvotes_count = upvotes_count - 1 "
            "WHERE id IN (SELECT question_id FROM question_upvotes WHERE user_id = ?)", (user_id,),
        )
        conn.execute("DELETE FROM question_upvotes WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM question_saves WHERE user_id = ?", (user_id,))
        own_questions = [r["id"] for r in conn.execute("SELECT id FROM interview_questions WHERE user_id = ?", (user_id,))]
        for question_id in own_questions:
            conn.execute("DELETE FROM question_upvotes WHERE question_id = ?", (question_id,))
            conn.execute("DELETE FROM question_saves WHERE question_id = ?", (question_id,))
        conn.execute("DELETE FROM interview_questions WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM resumes WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM job_marks WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM likes WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM saved_posts WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM followed_companies WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM feedback WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM users WHERE id = ?", (user_id,))


# MARK: - Saved posts (bookmarks)

def toggle_saved_post(device_id: str, discussion_id: str) -> Optional[bool]:
    user = get_or_create_user(device_id)
    with _connection() as conn:
        exists = conn.execute("SELECT 1 FROM discussions WHERE id = ?", (discussion_id,)).fetchone()
        if not exists:
            return None
        already_saved = conn.execute(
            "SELECT 1 FROM saved_posts WHERE user_id = ? AND discussion_id = ?", (user["id"], discussion_id)
        ).fetchone()
        if already_saved:
            conn.execute(
                "DELETE FROM saved_posts WHERE user_id = ? AND discussion_id = ?", (user["id"], discussion_id)
            )
            return False
        conn.execute(
            "INSERT INTO saved_posts (user_id, discussion_id, created_at) VALUES (?, ?, ?)",
            (user["id"], discussion_id, _now()),
        )
        return True


def list_saved_post_ids(device_id: str) -> list[str]:
    user = get_or_create_user(device_id)
    with _connection() as conn:
        rows = conn.execute(
            "SELECT discussion_id FROM saved_posts WHERE user_id = ? ORDER BY created_at DESC", (user["id"],)
        ).fetchall()
    return [r["discussion_id"] for r in rows]


# MARK: - Followed companies

def toggle_followed_company(device_id: str, company: str) -> bool:
    user = get_or_create_user(device_id)
    with _connection() as conn:
        already_following = conn.execute(
            "SELECT 1 FROM followed_companies WHERE user_id = ? AND company = ?", (user["id"], company)
        ).fetchone()
        if already_following:
            conn.execute(
                "DELETE FROM followed_companies WHERE user_id = ? AND company = ?", (user["id"], company)
            )
            return False
        conn.execute(
            "INSERT INTO followed_companies (user_id, company, created_at) VALUES (?, ?, ?)",
            (user["id"], company, _now()),
        )
        return True


def list_followed_companies(device_id: str) -> list[str]:
    user = get_or_create_user(device_id)
    with _connection() as conn:
        rows = conn.execute(
            "SELECT company FROM followed_companies WHERE user_id = ? ORDER BY company ASC", (user["id"],)
        ).fetchall()
    return [r["company"] for r in rows]


# MARK: - Feedback

def create_feedback(device_id: str, category: str, message: str) -> str:
    user = get_or_create_user(device_id)
    feedback_id = str(uuid.uuid4())
    with _connection() as conn:
        conn.execute(
            "INSERT INTO feedback (id, user_id, category, message, created_at) VALUES (?, ?, ?, ?, ?)",
            (feedback_id, user["id"], category, message.strip(), _now()),
        )
    return feedback_id


# MARK: - Comment replies, likes, deletion

def _delete_comment_tree(conn: sqlite3.Connection, comment_id: str, discussion_id: str) -> int:
    """Deletes a comment and (for a top-level comment) its replies; returns how many rows went,
    so the discussion's comments_count stays equal to what's actually there."""
    ids = [comment_id] + [
        r["id"] for r in conn.execute("SELECT id FROM comments WHERE parent_id = ?", (comment_id,))
    ]
    placeholders = ", ".join("?" for _ in ids)
    conn.execute(f"DELETE FROM comment_likes WHERE comment_id IN ({placeholders})", ids)
    deleted = conn.execute(f"DELETE FROM comments WHERE id IN ({placeholders})", ids).rowcount
    conn.execute(
        "UPDATE discussions SET comments_count = MAX(0, comments_count - ?) WHERE id = ?", (deleted, discussion_id)
    )
    return deleted


def delete_comment(comment_id: str, user_id: str) -> Optional[bool]:
    """None = no such comment; False = not this user's comment (only authors can delete)."""
    with _connection() as conn:
        row = conn.execute("SELECT user_id, discussion_id FROM comments WHERE id = ?", (comment_id,)).fetchone()
        if row is None:
            return None
        if row["user_id"] != user_id:
            return False
        _delete_comment_tree(conn, comment_id, row["discussion_id"])
        return True


def toggle_comment_like(comment_id: str, user_id: str) -> Optional[bool]:
    with _connection() as conn:
        if not conn.execute("SELECT 1 FROM comments WHERE id = ?", (comment_id,)).fetchone():
            return None
        if conn.execute(
            "SELECT 1 FROM comment_likes WHERE comment_id = ? AND user_id = ?", (comment_id, user_id)
        ).fetchone():
            conn.execute("DELETE FROM comment_likes WHERE comment_id = ? AND user_id = ?", (comment_id, user_id))
            conn.execute("UPDATE comments SET likes_count = likes_count - 1 WHERE id = ?", (comment_id,))
            return False
        conn.execute(
            "INSERT INTO comment_likes (user_id, comment_id, created_at) VALUES (?, ?, ?)", (user_id, comment_id, _now())
        )
        conn.execute("UPDATE comments SET likes_count = likes_count + 1 WHERE id = ?", (comment_id,))
        return True


def increment_share(discussion_id: str) -> Optional[int]:
    with _connection() as conn:
        if not conn.execute("SELECT 1 FROM discussions WHERE id = ?", (discussion_id,)).fetchone():
            return None
        conn.execute("UPDATE discussions SET shares_count = shares_count + 1 WHERE id = ?", (discussion_id,))
        return conn.execute("SELECT shares_count FROM discussions WHERE id = ?", (discussion_id,)).fetchone()[0]


# MARK: - Company communities

def company_stats() -> dict[str, dict]:
    """{company: {"followers": n, "posts": n}} for every company anyone follows or posted about."""
    stats: dict[str, dict] = {}
    with _connection() as conn:
        for r in conn.execute("SELECT company, COUNT(*) AS n FROM followed_companies GROUP BY company"):
            stats.setdefault(r["company"], {"followers": 0, "posts": 0})["followers"] = r["n"]
        for r in conn.execute(
            "SELECT company, COUNT(*) AS n FROM discussions WHERE company IS NOT NULL AND company != '' GROUP BY company"
        ):
            stats.setdefault(r["company"], {"followers": 0, "posts": 0})["posts"] = r["n"]
    return stats


# MARK: - Notifications (derived from activity, nothing stored)

def list_notifications(user_id: str, limit: int = 60) -> list[dict]:
    """Activity on this user's posts and comments by OTHER people, plus new posts in companies
    they follow — newest first. Read/unread is tracked on the device, not here."""
    with _connection() as conn:
        rows = conn.execute(
            """
            SELECT * FROM (
            SELECT 'comment:' || c.id AS id, 'commented_on_post' AS kind, c.discussion_id AS post_id,
                   c.body AS snippet, c.created_at AS created_at, u.username AS actor, u.avatar AS actor_avatar
            FROM comments c JOIN discussions d ON d.id = c.discussion_id JOIN users u ON u.id = c.user_id
            WHERE d.user_id = :me AND c.user_id != :me AND c.parent_id IS NULL

            UNION ALL
            SELECT 'reply:' || r.id, 'replied_to_comment', r.discussion_id, r.body, r.created_at, u.username, u.avatar
            FROM comments r JOIN comments p ON p.id = r.parent_id JOIN users u ON u.id = r.user_id
            WHERE p.user_id = :me AND r.user_id != :me

            UNION ALL
            SELECT 'postlike:' || l.discussion_id || ':' || l.user_id, 'liked_post', l.discussion_id, '',
                   l.created_at, u.username, u.avatar
            FROM likes l JOIN discussions d ON d.id = l.discussion_id JOIN users u ON u.id = l.user_id
            WHERE d.user_id = :me AND l.user_id != :me AND l.created_at IS NOT NULL

            UNION ALL
            SELECT 'commentlike:' || cl.comment_id || ':' || cl.user_id, 'liked_comment', c.discussion_id, c.body,
                   cl.created_at, u.username, u.avatar
            FROM comment_likes cl JOIN comments c ON c.id = cl.comment_id JOIN users u ON u.id = cl.user_id
            WHERE c.user_id = :me AND cl.user_id != :me

            UNION ALL
            SELECT 'post:' || d.id, 'new_post', d.id, '', d.created_at, u.username, u.avatar
            FROM discussions d JOIN users u ON u.id = d.user_id
            JOIN followed_companies f ON f.company = d.company AND f.user_id = :me
            WHERE d.user_id != :me AND d.created_at >= f.created_at
            )
            ORDER BY created_at DESC
            LIMIT :limit
            """,
            {"me": user_id, "limit": limit},
        ).fetchall()
    return [dict(r) for r in rows]


# MARK: - Interview questions

def list_questions(
    viewer_user_id: Optional[str], companies: Optional[list[str]] = None, roles: Optional[list[str]] = None,
    topics: Optional[list[str]] = None, only_saved: bool = False,
) -> list[dict]:
    conditions, params = [], [viewer_user_id or "", viewer_user_id or "", viewer_user_id or ""]
    if companies:
        conditions.append(f"LOWER(q.company) IN ({', '.join('?' for _ in companies)})")
        params.extend(c.lower() for c in companies)
    if roles:
        conditions.append(f"LOWER(q.role) IN ({', '.join('?' for _ in roles)})")
        params.extend(r.lower() for r in roles)
    if topics:
        conditions.append(f"q.topic IN ({', '.join('?' for _ in topics)})")
        params.extend(topics)
    if only_saved:
        conditions.append("EXISTS (SELECT 1 FROM question_saves s WHERE s.question_id = q.id AND s.user_id = ?)")
        params.append(viewer_user_id or "")
    where = f"WHERE {' AND '.join(conditions)}" if conditions else ""
    with _connection() as conn:
        rows = conn.execute(
            f"""
            SELECT q.*,
                   EXISTS(SELECT 1 FROM question_upvotes v WHERE v.question_id = q.id AND v.user_id = ?) AS upvoted_by_me,
                   EXISTS(SELECT 1 FROM question_saves s WHERE s.question_id = q.id AND s.user_id = ?) AS saved_by_me,
                   (q.user_id = ?) AS is_mine
            FROM interview_questions q
            {where}
            ORDER BY q.upvotes_count DESC, q.created_at DESC
            """,
            params,
        ).fetchall()
    return [dict(r) for r in rows]


def create_question(user_id: str, fields: dict) -> dict:
    question_id = str(uuid.uuid4())
    with _connection() as conn:
        conn.execute(
            """
            INSERT INTO interview_questions
                (id, user_id, company, role, topic, question, difficulty, hint, approach, answer,
                 time_complexity, space_complexity, upvotes_count, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
            """,
            (
                question_id, user_id, fields.get("company"), fields.get("role"), fields["topic"],
                fields["question"].strip(), fields.get("difficulty") or "General", fields.get("hint"),
                fields.get("approach"), fields.get("answer"), fields.get("time_complexity"),
                fields.get("space_complexity"), _now(),
            ),
        )
        # The contributor's own upvote, so the count and the "upvoted" state agree from the start.
        conn.execute(
            "INSERT INTO question_upvotes (user_id, question_id, created_at) VALUES (?, ?, ?)", (user_id, question_id, _now())
        )
    return next(q for q in list_questions(user_id) if q["id"] == question_id)


def toggle_question_upvote(question_id: str, user_id: str) -> Optional[bool]:
    with _connection() as conn:
        if not conn.execute("SELECT 1 FROM interview_questions WHERE id = ?", (question_id,)).fetchone():
            return None
        if conn.execute(
            "SELECT 1 FROM question_upvotes WHERE question_id = ? AND user_id = ?", (question_id, user_id)
        ).fetchone():
            conn.execute("DELETE FROM question_upvotes WHERE question_id = ? AND user_id = ?", (question_id, user_id))
            conn.execute("UPDATE interview_questions SET upvotes_count = upvotes_count - 1 WHERE id = ?", (question_id,))
            return False
        conn.execute(
            "INSERT INTO question_upvotes (user_id, question_id, created_at) VALUES (?, ?, ?)", (user_id, question_id, _now())
        )
        conn.execute("UPDATE interview_questions SET upvotes_count = upvotes_count + 1 WHERE id = ?", (question_id,))
        return True


def toggle_question_save(question_id: str, user_id: str) -> Optional[bool]:
    with _connection() as conn:
        if not conn.execute("SELECT 1 FROM interview_questions WHERE id = ?", (question_id,)).fetchone():
            return None
        if conn.execute(
            "SELECT 1 FROM question_saves WHERE question_id = ? AND user_id = ?", (question_id, user_id)
        ).fetchone():
            conn.execute("DELETE FROM question_saves WHERE question_id = ? AND user_id = ?", (question_id, user_id))
            return False
        conn.execute(
            "INSERT INTO question_saves (user_id, question_id, created_at) VALUES (?, ?, ?)", (user_id, question_id, _now())
        )
        return True


# MARK: - Resumes

def list_resumes(user_id: str) -> list[dict]:
    with _connection() as conn:
        rows = conn.execute(
            "SELECT id, data, created_at, updated_at FROM resumes WHERE user_id = ? ORDER BY created_at ASC", (user_id,)
        ).fetchall()
    return [dict(r) for r in rows]


def upsert_resume(user_id: str, resume_id: str, data: str) -> dict:
    now = _now()
    with _connection() as conn:
        conn.execute(
            """
            INSERT INTO resumes (id, user_id, data, created_at, updated_at) VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(user_id, id) DO UPDATE SET data = excluded.data, updated_at = excluded.updated_at
            """,
            (resume_id, user_id, data, now, now),
        )
        row = conn.execute(
            "SELECT id, data, created_at, updated_at FROM resumes WHERE user_id = ? AND id = ?", (user_id, resume_id)
        ).fetchone()
    return dict(row)


def delete_resume(user_id: str, resume_id: str) -> bool:
    with _connection() as conn:
        return conn.execute("DELETE FROM resumes WHERE user_id = ? AND id = ?", (user_id, resume_id)).rowcount > 0


# MARK: - Liked / applied jobs

def list_job_marks(user_id: str) -> list[dict]:
    with _connection() as conn:
        rows = conn.execute(
            "SELECT job_id, liked, applied, applied_at, job_json FROM job_marks "
            "WHERE user_id = ? AND (liked = 1 OR applied = 1) ORDER BY updated_at DESC",
            (user_id,),
        ).fetchall()
    return [dict(r) for r in rows]


def set_job_mark(user_id: str, job_id: str, job_json: Optional[str], liked: Optional[bool] = None,
                 applied: Optional[bool] = None) -> dict:
    now = _now()
    with _connection() as conn:
        existing = conn.execute(
            "SELECT liked, applied, applied_at, job_json FROM job_marks WHERE user_id = ? AND job_id = ?", (user_id, job_id)
        ).fetchone()
        new_liked = int(liked) if liked is not None else (existing["liked"] if existing else 0)
        new_applied = int(applied) if applied is not None else (existing["applied"] if existing else 0)
        applied_at = (existing["applied_at"] if existing else None)
        if applied is True and not applied_at:
            applied_at = now
        if applied is False:
            applied_at = None
        snapshot = job_json or (existing["job_json"] if existing else None)
        conn.execute(
            """
            INSERT INTO job_marks (user_id, job_id, liked, applied, applied_at, job_json, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(user_id, job_id) DO UPDATE SET liked = excluded.liked, applied = excluded.applied,
                applied_at = excluded.applied_at, job_json = excluded.job_json, updated_at = excluded.updated_at
            """,
            (user_id, job_id, new_liked, new_applied, applied_at, snapshot, now),
        )
    return {"job_id": job_id, "liked": bool(new_liked), "applied": bool(new_applied), "applied_at": applied_at}
