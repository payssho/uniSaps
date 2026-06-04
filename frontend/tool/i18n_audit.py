#!/usr/bin/env python3
"""Compare hardcoded UI strings against gen_arb CATALOG."""
import importlib.util
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
GEN = Path(__file__).resolve().parent / "gen_arb.py"

spec = importlib.util.spec_from_file_location("gen_arb", GEN)
gen_arb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen_arb)
CATALOG = gen_arb.CATALOG

fr_values = {v[0]: k for k, v in CATALOG.items()}
en_values = {v[1]: k for k, v in CATALOG.items()}

PATTERNS = [
    re.compile(r"Text\s*\(\s*['\"]([^'\"\\]{2,})['\"]"),
    re.compile(r"hintText:\s*['\"]([^'\"\\]{2,})['\"]"),
    re.compile(r"tooltip:\s*['\"]([^'\"\\]{2,})['\"]"),
    re.compile(r"label:\s*['\"]([^'\"\\]{2,})['\"]"),
    re.compile(r"SnackBar\s*\([^)]*content:\s*Text\s*\(\s*['\"]([^'\"\\]{2,})['\"]"),
    re.compile(r"throw Exception\s*\(\s*['\"]([^'\"\\]{2,})['\"]"),
]

SKIP = re.compile(r"^[a-z_]+$|^\d+$|^http")

entries = []
for path in sorted(LIB.rglob("*.dart")):
    if "generated" in path.parts or path.name == "l10n_context.dart":
        continue
    rel = path.relative_to(ROOT)
    for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if ".l10n." in line or "AppLocalizations" in line:
            continue
        for pat in PATTERNS:
            for m in pat.finditer(line):
                text = m.group(1)
                if SKIP.search(text):
                    continue
                key = fr_values.get(text) or en_values.get(text)
                entries.append({
                    "file": str(rel).replace("\\", "/"),
                    "line": i,
                    "text": text,
                    "existing_key": key,
                    "lot": 1 if key else 2,
                })

report = {
    "total": len(entries),
    "lot1_existing_key": sum(1 for e in entries if e["lot"] == 1),
    "lot2_new_key": sum(1 for e in entries if e["lot"] == 2),
    "entries": entries,
}
out = ROOT / "tool" / "i18n_audit_report.json"
out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"Wrote {out}: {report['total']} issues (lot1={report['lot1_existing_key']}, lot2={report['lot2_new_key']})")
