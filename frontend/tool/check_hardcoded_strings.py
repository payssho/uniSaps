#!/usr/bin/env python3
"""Fail if new accented/French UI literals appear outside allowlist."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"
ALLOWLIST = {
    "lib/core/constants/categories.dart",
    "lib/l10n/domain_l10n.dart",
}
ACCENT = re.compile(r"[àâäéèêëïîôùûüçÀÂÄÉÈÊËÏÎÔÙÛÜÇ]")
PAT = re.compile(
    r"(?:Text|hintText|tooltip|label)\s*\(?\s*['\"]([^'\"]{3,})['\"]"
)

violations = []
for path in sorted(ROOT.rglob("*.dart")):
    rel = path.relative_to(ROOT.parent).as_posix()
    if "generated/" in rel or rel in ALLOWLIST:
        continue
    for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if ".l10n." in line:
            continue
        for m in PAT.finditer(line):
            if ACCENT.search(m.group(1)):
                violations.append(f"{rel}:{i}: {m.group(1)[:60]}")

if violations:
    print("Hardcoded French/accented UI strings found:")
    print("\n".join(violations[:50]))
    if len(violations) > 50:
        print(f"... and {len(violations) - 50} more")
    sys.exit(1)
print("i18n check passed")
