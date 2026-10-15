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

            CREATE INDEX IF NOT EXISTS idx_discussions_category ON discussions(category);
            CREATE INDEX IF NOT EXISTS idx_comments_discussion ON comments(discussion_id);
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
        }
        for column, sql_type in profile_columns.items():
            if column not in existing_columns:
                conn.execute(f"ALTER TABLE users ADD COLUMN {column} {sql_type}")

        existing_discussion_columns = {row["name"] for row in conn.execute("PRAGMA table_info(discussions)")}
        if "topics" not in existing_discussion_columns:
            conn.execute("ALTER TABLE discussions ADD COLUMN topics TEXT NOT NULL DEFAULT '[]'")


def get_or_create_user(device_id: str, role_title: Optional[str] = None) -> sqlite3.Row:
    with _connection() as conn:
        row = conn.execute("SELECT * FROM users WHERE device_id = ?", (device_id,)).fetchone()
        if row:
            return row

        # Collision is astronomically unlikely (20 * 20 * 900 ≈ 360k combinations) but the
        # unique constraint is the real guarantee — retry on the rare clash rather than trust
        # the odds alone.
        for _ in range(10):
            username = _generate_username()
            try:
                user_id = str(uuid.uuid4())
                conn.execute(
                    "INSERT INTO users (id, device_id, username, role_title, created_at) VALUES (?, ?, ?, ?, ?)",
                    (user_id, device_id, username, role_title, _now()),
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
        SELECT d.*, u.username, u.role_title,
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
            SELECT d.*, u.username, u.role_title,
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
            SELECT c.*, u.username, u.role_title
            FROM comments c
            JOIN users u ON u.id = c.user_id
            WHERE c.discussion_id = ?
            ORDER BY c.created_at ASC
            """,
            (discussion_id,),
        ).fetchall()
    result = dict(row)
    result["comments"] = [dict(c) for c in comments]
    return result


def add_comment(discussion_id: str, user_id: str, body: str) -> Optional[sqlite3.Row]:
    comment_id = str(uuid.uuid4())
    created_at = _now()
    with _connection() as conn:
        exists = conn.execute("SELECT 1 FROM discussions WHERE id = ?", (discussion_id,)).fetchone()
        if not exists:
            return None
        conn.execute(
            "INSERT INTO comments (id, discussion_id, user_id, body, created_at) VALUES (?, ?, ?, ?, ?)",
            (comment_id, discussion_id, user_id, body.strip(), created_at),
        )
        conn.execute(
            "UPDATE discussions SET comments_count = comments_count + 1 WHERE id = ?",
            (discussion_id,),
        )
        return conn.execute(
            """
            SELECT c.*, u.username, u.role_title FROM comments c
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
            "INSERT INTO likes (user_id, discussion_id) VALUES (?, ?)", (user_id, discussion_id)
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
            conn.execute("DELETE FROM likes WHERE discussion_id = ?", (discussion_id,))
            conn.execute("DELETE FROM saved_posts WHERE discussion_id = ?", (discussion_id,))
            conn.execute("DELETE FROM comments WHERE discussion_id = ?", (discussion_id,))
        conn.execute("DELETE FROM discussions WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM comments WHERE user_id = ?", (user_id,))
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
