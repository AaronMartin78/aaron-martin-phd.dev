#!/usr/bin/env python3
"""CI validation for BBL edition files (bbl/posts/*.qmd). Stdlib only.

Checks per file:
  frontmatter   - title, date, lang: en present; date matches the filename
  structure     - at least one section (##) and one story (###)
  citations     - every story ends with a Sources list of absolute https links
  language      - body is English (German function-word heuristic)
  no-model-urls - story paragraphs contain no raw URLs (links live in Sources)
  links (--check-links) - every cited URL answers < 400 (HEAD, 10s timeout)

Exit code 0 = all files pass; 1 = failures (printed, one per line).
"""
from __future__ import annotations

import argparse
import re
import sys
import urllib.request
from pathlib import Path

GERMAN = re.compile(
    r"\b(und|nicht|gegen|wurde|dass|beim|spiel|sieg|niederlage)\b", re.IGNORECASE
)
LINK = re.compile(r"\]\((https?://[^)\s]+)\)")
BARE_URL = re.compile(r"(?<!\()https?://\S+")


def head_ok(url: str) -> bool:
    request = urllib.request.Request(url, method="HEAD",
                                     headers={"User-Agent": "edition-check/1"})
    try:
        with urllib.request.urlopen(request, timeout=10) as resp:
            return resp.status < 400
    except Exception:
        return False


def check_file(path: Path, check_links: bool) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")

    front = re.match(r"---\n(.*?)\n---\n", text, re.DOTALL)
    if not front:
        return [f"{path}: no frontmatter"]
    fm = front.group(1)
    for key in ("title:", "date:", "lang: en"):
        if key not in fm:
            errors.append(f"{path}: frontmatter missing {key.rstrip(':')}")
    date_match = re.search(r"date:\s*(\S+)", fm)
    if date_match and date_match.group(1) != path.stem:
        errors.append(f"{path}: frontmatter date {date_match.group(1)} != filename")

    body = text[front.end():]
    if "## " not in body:
        errors.append(f"{path}: no sections")

    stories = re.split(r"\n### ", body)[1:]
    if not stories:
        errors.append(f"{path}: no stories")
    for story in stories:
        headline = story.splitlines()[0].strip()
        if "Sources:" not in story:
            errors.append(f"{path}: story '{headline[:40]}' has no Sources list")
            continue
        prose, _, sources = story.partition("Sources:")
        links = LINK.findall(sources)
        if not links:
            errors.append(f"{path}: story '{headline[:40]}' cites no links")
        if any(not u.startswith("https://") for u in links):
            errors.append(f"{path}: story '{headline[:40]}' has non-https citation")
        if BARE_URL.search(prose) or LINK.search(prose):
            errors.append(f"{path}: story '{headline[:40]}' has URLs in prose")
        if len(GERMAN.findall(prose)) > 2:
            errors.append(f"{path}: story '{headline[:40]}' reads as German")
        if check_links:
            for url in links:
                if not head_ok(url):
                    errors.append(f"{path}: dead link {url}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--check-links", action="store_true")
    args = parser.parse_args()

    all_errors: list[str] = []
    for path in args.files:
        if path.suffix == ".qmd":
            all_errors.extend(check_file(path, args.check_links))
    for error in all_errors:
        print(f"FAIL {error}")
    if not all_errors:
        print(f"OK {len(args.files)} file(s)")
    return 1 if all_errors else 0


if __name__ == "__main__":
    sys.exit(main())
