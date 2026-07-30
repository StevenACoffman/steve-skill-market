#!/usr/bin/env python3
"""Objective format checks for unconventional-commits eval outputs.

Reads each commit_msg.txt and reports, per subject line:
  - has_type_prefix: does it start with a conventional-commits type token?
  - scope_first: does it start with `<scope>: ` where scope is not a CC type?
  - subject_len: length of the subject line
  - imperative_ish: subject's first word after the scope is not past-tense (-ed) / 3rd-person (-s)
  - blank_line_after_subject: is line 2 blank (when a body exists)?
  - num_commits: number of commit blocks (split on lines of only dashes)
"""
import re
import sys
from pathlib import Path

CC_TYPES = {"feat", "fix", "docs", "style", "refactor", "perf",
            "test", "build", "ci", "chore", "revert"}
# type or type(scope) optionally with ! then colon
CC_RE = re.compile(r"^(" + "|".join(CC_TYPES) + r")(\([^)]*\))?!?:", re.I)
SCOPE_RE = re.compile(r"^([A-Za-z0-9][\w./\-]*)(\([^)]*\))?:\s+\S")


def split_commits(text):
    blocks, cur = [], []
    for line in text.splitlines():
        if set(line.strip()) == {"-"} and len(line.strip()) >= 3:
            if cur:
                blocks.append("\n".join(cur).strip())
                cur = []
        else:
            cur.append(line)
    if cur and "\n".join(cur).strip():
        blocks.append("\n".join(cur).strip())
    return [b for b in blocks if b]


def analyze_block(block):
    lines = block.splitlines()
    subject = lines[0].strip() if lines else ""
    m = SCOPE_RE.match(subject)
    scope = m.group(1) if m else None
    first_word = ""
    if m:
        rest = subject[m.end(2) if m.group(2) else m.end(1):].lstrip(": ").strip()
        first_word = rest.split()[0] if rest else ""
    return {
        "subject": subject,
        "has_type_prefix": bool(CC_RE.match(subject)),
        "scope_first": bool(m) and (scope.lower() not in CC_TYPES),
        "scope": scope,
        "subject_len": len(subject),
        "first_word": first_word,
        "past_or_3rd_person": bool(re.search(r"(ed|s)$", first_word, re.I))
                              and first_word.lower() not in {"address", "access", "process", "focus"},
        "blank_line_after_subject": (len(lines) < 2) or (lines[1].strip() == ""),
    }


def main():
    root = Path(sys.argv[1])
    for f in sorted(root.glob("iteration-*/eval-*/*/outputs/commit_msg.txt")):
        rel = f.relative_to(root)
        text = f.read_text()
        blocks = split_commits(text)
        print(f"\n=== {rel}  ({len(blocks)} commit block(s)) ===")
        for i, b in enumerate(blocks):
            a = analyze_block(b)
            print(f"  [{i}] {a['subject']!r}")
            print(f"      type_prefix={a['has_type_prefix']} scope_first={a['scope_first']} "
                  f"scope={a['scope']} len={a['subject_len']} "
                  f"first_word={a['first_word']!r} looks_past/3rd={a['past_or_3rd_person']} "
                  f"blank_after={a['blank_line_after_subject']}")


if __name__ == "__main__":
    main()
