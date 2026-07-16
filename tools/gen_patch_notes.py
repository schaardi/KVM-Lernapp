#!/usr/bin/env python3
"""Erzeugt automatische Patch-Notes aus den Git-Commits seit dem letzten Release.

Wird beim Play-Release genutzt:
  * schreibt die kurze „Was ist neu"-Datei für Google Play
    (distribution/whatsnew/whatsnew-<lang>, max. 500 Zeichen je Sprache), und
  * schreibt ein längeres Changelog (für den GitHub-Release-Text).

Quelle sind die Commit-Betreffzeilen seit dem letzten Tag `v*` (oder alle
Commits, falls es noch keinen Tag gibt). Rein technische Commits (ci/chore/
build/docs/merge) werden herausgefiltert, damit die Notes nutzerlesbar bleiben.

Beispiel:
    python tools/gen_patch_notes.py \
        --out-whatsnew distribution/whatsnew/whatsnew-de-DE \
        --out-changelog build/changelog.md
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

# Commits, die für Endnutzer irrelevant sind, fliegen raus.
SKIP_PREFIX = re.compile(r"^(ci|chore|build|docs|test|refactor|style)(\(|:|\s)", re.I)
SKIP_CONTAINS = re.compile(r"\bmerge\b|Co-Authored-By|Claude-Session", re.I)


def _git(*args: str) -> str:
    out = subprocess.run(["git", *args], cwd=REPO_ROOT, check=True, capture_output=True)
    return out.stdout.decode("utf-8", "replace").strip()


def _last_tag() -> str | None:
    try:
        return _git("describe", "--tags", "--abbrev=0", "--match", "v*")
    except subprocess.CalledProcessError:
        return None


def _commit_subjects(since: str | None) -> list[str]:
    rng = f"{since}..HEAD" if since else "HEAD"
    raw = _git("log", rng, "--no-merges", "--pretty=%s")
    subjects: list[str] = []
    for line in raw.splitlines():
        s = line.strip()
        if not s or SKIP_PREFIX.match(s) or SKIP_CONTAINS.search(s):
            continue
        subjects.append(s)
    # Duplikate (z. B. Reverts) entfernen, Reihenfolge behalten.
    seen: set[str] = set()
    uniq = [s for s in subjects if not (s in seen or seen.add(s))]
    return uniq


def _clean(subject: str) -> str:
    # führendes "type: " entfernen, Ticket-Klammern am Ende kürzen
    s = re.sub(r"^\w+(\([^)]*\))?:\s*", "", subject)
    return s.strip()


def build_notes(max_chars: int) -> tuple[str, str]:
    tag = _last_tag()
    subjects = [_clean(s) for s in _commit_subjects(tag)]
    if not subjects:
        subjects = ["Kleinere Verbesserungen und Fehlerbehebungen."]

    # Langes Changelog (GitHub-Release)
    changelog = "\n".join(f"- {s}" for s in subjects)

    # Kurze Play-Notes: so viele Punkte wie in max_chars passen.
    lines: list[str] = []
    length = 0
    for s in subjects:
        entry = f"• {s}"
        add = len(entry) + (1 if lines else 0)  # + Newline
        if length + add > max_chars:
            break
        lines.append(entry)
        length += add
    if not lines:
        # Erster Punkt zu lang -> hart kürzen.
        lines = [("• " + subjects[0])[: max_chars - 1] + "…"]
    whatsnew = "\n".join(lines)
    return whatsnew, changelog


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Patch-Notes aus Git-Commits erzeugen.")
    ap.add_argument("--out-whatsnew", help="Zieldatei für die kurzen Play-Notes.")
    ap.add_argument("--out-changelog", help="Zieldatei für das lange Changelog.")
    ap.add_argument("--max-chars", type=int, default=500, help="Max. Zeichen für Play (Standard 500).")
    args = ap.parse_args(argv)

    whatsnew, changelog = build_notes(args.max_chars)

    if args.out_whatsnew:
        p = REPO_ROOT / args.out_whatsnew
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(whatsnew + "\n", encoding="utf-8")
        print(f"Play-Notes -> {args.out_whatsnew} ({len(whatsnew)} Zeichen)")
    if args.out_changelog:
        p = REPO_ROOT / args.out_changelog
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(changelog + "\n", encoding="utf-8")
        print(f"Changelog  -> {args.out_changelog}")

    if not args.out_whatsnew and not args.out_changelog:
        print("=== Play (What's new) ===")
        print(whatsnew)
        print("\n=== Changelog ===")
        print(changelog)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
