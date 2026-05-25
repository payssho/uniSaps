#!/usr/bin/env python3
"""Extract likely UI strings from Dart files for ARB inventory."""
import re
import json
from pathlib import Path

LIB = Path(__file__).resolve().parent.parent / "lib"
PATTERNS = [
    re.compile(r"Text\s*\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'"),
    re.compile(r'Text\s*\(\s*"([^"\\]*(?:\\.[^"\\]*)*)"'),
    re.compile(r"hintText:\s*'([^']+)'"),
    re.compile(r'label:\s*'([^']+)'"),
    re.compile(r"title:\s*(?:const\s+)?Text\s*\(\s*'([^']+)'"),
    re.compile(r"tooltip:\s*'([^']+)'"),
    re.compile(r"SnackBar\s*\([^)]*content:\s*Text\s*\(\s*'([^']+)'"),
    re.compile(r"Semantics\s*\([^)]*label:\s*'([^']+)'"),
]

def slug(s: str) -> str:
    s = re.sub(r"[^\w\s]", "", s.lower())
    s = re.sub(r"\s+", "_", s.strip())[:48]
    return s or "key"

found = {}
for path in sorted(LIB.rglob("*.dart")):
    if "generated" in str(path) or "l10n" in str(path):
        continue
    text = path.read_text(encoding="utf-8", errors="ignore")
    for pat in PATTERNS:
        for m in pat.finditer(text):
            raw = m.group(1).encode().decode("unicode_escape")
            if len(raw) < 2 or raw.startswith("http"):
                continue
            if re.match(r"^[a-z_]+$", raw):
                continue
            found.setdefault(raw, slug(raw))

print(f"Found {len(found)} unique strings")
for s, k in sorted(found.items(), key=lambda x: x[1])[:80]:
    print(f"  {k}: {s[:60]}")
