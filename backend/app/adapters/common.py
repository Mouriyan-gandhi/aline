import asyncio
import html
import re
from typing import Optional

import httpx

HTTP_TIMEOUT = 15.0
USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)


_TAG_PATTERN = re.compile(r"<[^>]+>")


def html_to_text(raw: str) -> str:
    """Strip markup from a job description before it reaches is_senior_excluded/
    extract_skills — several adapters' description fields are real HTML (Greenhouse's
    `content`, Ashby's `descriptionHtml`, Workday JSON-LD's `description`), not plain text.
    Found live: an href/class attribute like `class="c-link"` word-boundary-matched the
    bare "C" skill — tags must come out before any filter function ever sees this text, not
    just before it's shown to a user (it's never shown to a user — Job has no description
    field — but the filter functions still need clean text to match against).

    Unescape entities FIRST, then strip tags — confirmed live against Greenhouse's actual
    `content` field: its tags themselves arrive entity-encoded ("...&lt;/li&gt;&lt;li&gt;...",
    not real "<li>"), so stripping before unescaping left every tag's literal "&lt;a
    class=...&gt;" text sitting in the string untouched, the exact bug this function exists
    to fix. The reverse-order risk (prose that happens to mention "&lt;b&gt;" getting swept
    up as a fake tag) is the much rarer case in practice."""
    if not raw:
        return ""
    return _TAG_PATTERN.sub(" ", html.unescape(raw))


def normalize_location(loc) -> str:
    if not loc:
        return "Not specified"
    if isinstance(loc, list):
        return ", ".join(str(x) for x in loc if x)
    return str(loc).strip() or "Not specified"


async def request_with_retries(
    client: httpx.AsyncClient,
    method: str,
    url: str,
    *,
    retries: int = 3,
    backoff_seconds: float = 0.5,
    **kwargs,
) -> httpx.Response:
    """
    Some ATS-adjacent endpoints (Workday's internal job-search API in particular) are
    observed to intermittently 400/5xx on otherwise-identical requests — not a real error,
    just flakiness. Retry a few times before giving up, so a transient blip doesn't get
    mistaken for "this source is broken" (the exact ambiguity the plan's source-health
    design calls out).
    """
    last_exc: Optional[Exception] = None
    for attempt in range(retries):
        try:
            resp = await client.request(method, url, timeout=HTTP_TIMEOUT, **kwargs)
            if resp.status_code < 500 and resp.status_code != 400:
                return resp
            if resp.status_code not in (400, 429, 500, 502, 503, 504):
                return resp
            last_exc = httpx.HTTPStatusError(
                f"retryable status {resp.status_code}", request=resp.request, response=resp
            )
        except httpx.HTTPError as exc:
            last_exc = exc
        if attempt < retries - 1:
            await asyncio.sleep(backoff_seconds * (attempt + 1))
    raise last_exc
