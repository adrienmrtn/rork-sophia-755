#!/usr/bin/env python3
"""Bulk machine-translation transport shared by the content pipelines.

Why this exists: ``deep_translator``'s Google client calls
``translate.googleapis.com``, which answers **HTTP 429** from data-centre IP
ranges — every pipeline run dies before it starts. The Chrome-extension
dictionary endpoint on ``clients5.google.com`` is the same translation engine,
is not throttled the same way, and takes a POST body carrying many ``q=``
fields, so a whole batch costs one round trip instead of one per string.

Alignment is the thing to get right: a batch of N strings must come back as N
strings, in order. When it does not, the batch is split and retried rather than
trusted — a silently misaligned batch would attach the wrong translation to
every row after the first bad one.

Usage:
    from mt_backend import translate_batch, translate_one
    translate_batch(["Hello", "Goodbye"], target="da")          # -> [str, str]
    translate_one("Hello", target="ru")                          # -> str
"""

from __future__ import annotations

import json
import re
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

from serbian_script import repair_sentinels, to_latin

GOOGLE = "https://clients5.google.com/translate_a/t?client=dict-chrome-ex"
LINGVA = "https://lingva.ml/api/v1"
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"

# Per request: the endpoint handled 100 items / ~135 KB in testing. Stay under.
MAX_ITEMS = 80
MAX_BYTES = 90_000

# One string longer than this is sent alone; anything longer still is split by
# the callers, which already chunk on sentence boundaries.
SOLO_BYTES = 20_000

_LOCK = threading.Lock()
_last_call = [0.0]
_MIN_INTERVAL = 0.05  # politeness floor, shared across threads

HAS_LETTER = re.compile(r"[^\W\d_]", re.UNICODE)

# This endpoint sprinkles zero-width spaces into its output — Danish alone came
# back with 4,334 of them across the catalog, always as a "\u200b\u200b" pair
# after a preposition. They are invisible but they corrupt search, word counts
# and diffing, so they are scrubbed before a translation is ever returned.
# ZWJ (U+200D) is deliberately left alone: it is load-bearing in emoji sequences.
INVISIBLE = re.compile("[\u200b\u200c\u00ad\ufeff\u2060]")


def _clean(text: str) -> str:
    if not INVISIBLE.search(text):
        return text
    # Collapse only the runs the removal itself created, so a translation that
    # legitimately carried a double space keeps it.
    return re.sub(r"[ \t]{2,}", " ", INVISIBLE.sub("", text)).strip()


def _pace() -> None:
    with _LOCK:
        wait = _MIN_INTERVAL - (time.time() - _last_call[0])
        if wait > 0:
            time.sleep(wait)
        _last_call[0] = time.time()


def _post(texts: list[str], target: str, source: str, timeout: int) -> list[str]:
    body = "&".join("q=" + urllib.parse.quote(t) for t in texts).encode("utf-8")
    url = f"{GOOGLE}&sl={source}&tl={target}"
    request = urllib.request.Request(
        url,
        data=body,
        headers={
            "User-Agent": USER_AGENT,
            "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
        },
    )
    _pace()
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = json.loads(response.read().decode("utf-8"))
    # One q comes back as ["text"]; many as ["a", "b", ...]. A nested list shows
    # up when the endpoint splits a segment — flatten it before aligning.
    if isinstance(payload, str):
        payload = [payload]
    flat: list[str] = []
    for item in payload:
        if isinstance(item, list):
            flat.append(_clean("".join(str(x) for x in item)))
        else:
            flat.append(_clean(str(item)))
    return flat


def _lingva_one(text: str, target: str, source: str, timeout: int) -> str | None:
    url = f"{LINGVA}/{source}/{target}/{urllib.parse.quote(text, safe='')}"
    try:
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        _pace()
        with urllib.request.urlopen(request, timeout=timeout) as response:
            value = json.loads(response.read().decode("utf-8")).get("translation")
            return _clean(value) if isinstance(value, str) else value
    except Exception:  # noqa: BLE001
        return None


def _translate_aligned(texts: list[str], target: str, source: str, timeout: int) -> list[str]:
    """Translate a batch, splitting on any misalignment rather than trusting it."""
    if not texts:
        return []
    last_error: Exception | None = None
    for attempt in range(5):
        try:
            out = _post(texts, target, source, timeout)
            if len(out) == len(texts) and all(o.strip() for o in out):
                return out
            # One string can come back as several segments when the engine
            # splits on sentence boundaries; the pieces concatenate back.
            if len(texts) == 1 and len(out) > 1 and all(o.strip() for o in out):
                return ["".join(out)]
            break  # misaligned or empty cell — fall through to splitting
        except urllib.error.HTTPError as error:
            last_error = error
            if error.code in (429, 503):
                time.sleep(min(2 ** attempt, 20))
                continue
            time.sleep(min(2 ** attempt, 10))
        except Exception as error:  # noqa: BLE001
            last_error = error
            time.sleep(min(2 ** attempt, 10))

    if len(texts) == 1:
        fallback = _lingva_one(texts[0], target, source, timeout)
        if fallback:
            return [fallback]
        print(
            f"    warn MT kept source ({target}): {texts[0][:60]!r} ({last_error})",
            file=sys.stderr,
        )
        return [texts[0]]

    mid = len(texts) // 2
    return (
        _translate_aligned(texts[:mid], target, source, timeout)
        + _translate_aligned(texts[mid:], target, source, timeout)
    )


def _pack(texts: list[str]) -> list[list[int]]:
    """Groups indices into requests that respect the item and byte ceilings."""
    groups: list[list[int]] = []
    current: list[int] = []
    size = 0
    for index, text in enumerate(texts):
        cost = len(urllib.parse.quote(text)) + 3
        if cost >= SOLO_BYTES:
            if current:
                groups.append(current)
                current, size = [], 0
            groups.append([index])
            continue
        if current and (len(current) >= MAX_ITEMS or size + cost > MAX_BYTES):
            groups.append(current)
            current, size = [], 0
        current.append(index)
        size += cost
    if current:
        groups.append(current)
    return groups


def translate_batch(
    texts: list[str],
    target: str,
    source: str = "en",
    timeout: int = 90,
) -> list[str]:
    """Translates `texts` and returns exactly as many strings, in the same order.

    Blank strings and strings with no letters (numbers, symbols, bare markup)
    are returned untouched rather than sent — MT mangles them and they cost a
    request slot.
    """
    result: list[str | None] = [None] * len(texts)
    sendable: list[int] = []
    for index, text in enumerate(texts):
        if not text or not text.strip() or not HAS_LETTER.search(text):
            result[index] = text
        else:
            sendable.append(index)

    for group in _pack([texts[i] for i in sendable]):
        indices = [sendable[i] for i in group]
        out = _translate_aligned([texts[i] for i in indices], target, source, timeout)
        for index, value in zip(indices, out):
            result[index] = value

    if target.split("-")[0] == "sr":
        # Serbian ships in Latin script; see ``serbian_script`` for why the
        # engine's Cyrillic output is converted rather than kept. The same
        # round trip mangles the callers' ASCII sentinels (ZZXG0ZZ comes back
        # as ZZKSG0ZZ because X has no single Cyrillic letter), so put those
        # back into the shape the restorers match on.
        result = [
            repair_sentinels(to_latin(v)) if isinstance(v, str) else v for v in result
        ]

    return [texts[i] if v is None else v for i, v in enumerate(result)]


def translate_one(text: str, target: str, source: str = "en", timeout: int = 90) -> str:
    return translate_batch([text], target, source, timeout)[0]


class GoogleTranslator:
    """Drop-in stand-in for ``deep_translator.GoogleTranslator``."""

    def __init__(self, source: str = "en", target: str = "en") -> None:
        self.source = source
        self.target = target

    def translate(self, text: str) -> str:
        return translate_one(text, self.target, self.source)

    def translate_batch(self, texts: list[str]) -> list[str]:
        return translate_batch(list(texts), self.target, self.source)


if __name__ == "__main__":
    probe = ["The Renaissance", "Why is the sky blue?", "**Newton** and the [[orbit]]"]
    for code in ("da", "no", "ru", "hr", "sl", "sk", "sr"):
        print(code, translate_batch(probe, code))
