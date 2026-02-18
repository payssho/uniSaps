"""
Rule-based outfit suggestion engine with color/style matching and wear-history awareness.
Migrated from the original Flet app.
"""
import random
from datetime import datetime, timedelta

COLOR_FAMILIES: dict[str, list[str]] = {
    "neutral": [
        "noir", "blanc", "gris", "beige", "creme",
        "black", "white", "gray", "grey", "beige", "cream", "navy",
    ],
    "warm": [
        "rouge", "orange", "jaune", "marron", "bordeaux",
        "red", "orange", "yellow", "brown", "burgundy", "coral", "terracotta",
    ],
    "cool": [
        "bleu", "vert", "violet", "turquoise",
        "blue", "green", "purple", "teal", "mint", "lavender",
    ],
    "pastel": [
        "rose", "lavande", "peche", "menthe",
        "pink", "lavender", "peach", "mint", "baby blue",
    ],
}

STYLE_WEIGHTS: dict[str, dict[str, int]] = {
    "Simple":        {"neutral": 3, "cool": 1, "warm": 0, "pastel": 1},
    "Colore":        {"warm": 3, "cool": 2, "pastel": 2, "neutral": 0},
    "Classe":        {"neutral": 3, "cool": 2, "warm": 1, "pastel": 0},
    "Professionnel": {"neutral": 4, "cool": 2, "warm": 0, "pastel": 0},
    "Decontracte":   {"neutral": 2, "warm": 2, "cool": 2, "pastel": 1},
    "Streetwear":    {"neutral": 2, "warm": 2, "cool": 1, "pastel": 0},
    "Sportif":       {"neutral": 2, "cool": 2, "warm": 1, "pastel": 0},
    "Soiree":        {"neutral": 1, "warm": 2, "cool": 2, "pastel": 1},
}

PROMPT_MAP: dict[str, str] = {
    "classe": "Classe", "chic": "Classe", "elegant": "Classe",
    "professionnel": "Professionnel", "pro": "Professionnel", "bureau": "Professionnel",
    "casual": "Decontracte", "decontracte": "Decontracte", "relax": "Decontracte", "brunch": "Decontracte",
    "simple": "Simple", "minimaliste": "Simple",
    "colore": "Colore", "couleur": "Colore",
    "streetwear": "Streetwear", "street": "Streetwear", "urban": "Streetwear",
    "sport": "Sportif", "sportif": "Sportif",
    "soiree": "Soiree", "fete": "Soiree",
    "surprends": "Colore",
}

REQUIRED_CATS = ["top", "bottom", "shoes"]
OPTIONAL_CATS = ["headwear", "outerwear", "accessory"]
ALL_CATS = REQUIRED_CATS + OPTIONAL_CATS


def _color_family(color: str) -> str:
    low = color.lower().strip()
    for family, names in COLOR_FAMILIES.items():
        if any(n in low for n in names):
            return family
    return "neutral"


def _resolve_style(prompt: str) -> str:
    low = prompt.lower().strip()
    for kw, style in PROMPT_MAP.items():
        if kw in low:
            return style
    return "Decontracte"


def _score(color: str, style: str) -> int:
    family = _color_family(color)
    return STYLE_WEIGHTS.get(style, {}).get(family, 1)


def suggest_outfit(
    garments: list[dict],
    style: str = "Simple",
    existing_outfits: list[dict] | None = None,
) -> dict[str, str]:
    resolved = _resolve_style(style) if style not in STYLE_WEIGHTS else style

    by_cat: dict[str, list[dict]] = {}
    for g in garments:
        by_cat.setdefault(g["category"], []).append(g)

    recently_worn: set[str] = set()
    if existing_outfits:
        cutoff = (datetime.now() - timedelta(days=7)).isoformat()
        for o in existing_outfits:
            if o.get("last_worn", "") > cutoff:
                gids = [v for v in o.get("garments", {}).values() if v]
                recently_worn.update(gids)

    suggestion: dict[str, str] = {c: "" for c in ALL_CATS}

    for cat in ALL_CATS:
        available = by_cat.get(cat, [])
        if not available:
            continue

        scored = sorted(
            available,
            key=lambda g: _score(g.get("color", ""), resolved) + (-2 if g["id"] in recently_worn else 0),
            reverse=True,
        )
        top = scored[: max(1, len(scored) // 2)]
        suggestion[cat] = random.choice(top)["id"]

    if resolved in ("Simple", "Decontracte", "Professionnel"):
        for cat in OPTIONAL_CATS:
            if random.random() < 0.5:
                suggestion[cat] = ""

    return suggestion


def suggest_multiple(
    garments: list[dict],
    style: str = "Simple",
    count: int = 5,
    existing_outfits: list[dict] | None = None,
) -> list[dict[str, str]]:
    results: list[dict[str, str]] = []
    seen: set[tuple] = set()
    attempts = 0
    while len(results) < count and attempts < count * 3:
        s = suggest_outfit(garments, style, existing_outfits)
        key = tuple(sorted(s.items()))
        if key not in seen:
            seen.add(key)
            results.append(s)
        attempts += 1
    return results
