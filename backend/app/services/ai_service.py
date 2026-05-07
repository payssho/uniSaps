"""
Rule-based outfit suggestion engine with color/style/season/weather/material/style-tags
matching and wear-history awareness.

Migrated from the original Flet app and progressively enriched.

Extended with optional image-analysis helpers powered by an external LLM
for extracting richer attributes (couleur, style, matière...) from garment photos.
"""
import logging
import os
import random
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

import requests

logger = logging.getLogger("unisaps.ai")

# ─────────────────────────────────────────────────────────────────────────────
# Couleurs
# ─────────────────────────────────────────────────────────────────────────────

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
    # --- Classe / chic / élégant ---
    "classe": "Classe",
    "classy": "Classe",
    "chic": "Classe",
    "élégant": "Classe",
    "elegant": "Classe",
    "smart": "Classe",
    "habillé": "Classe",
    "habille": "Classe",
    "raffiné": "Classe",
    "raffine": "Classe",
    "tailleur": "Classe",
    "chemise": "Classe",

    # --- Professionnel / bureau ---
    "professionnel": "Professionnel",
    "pro": "Professionnel",
    "bureau": "Professionnel",
    "office": "Professionnel",
    "travail": "Professionnel",
    "meeting": "Professionnel",
    "réunion": "Professionnel",
    "reunion": "Professionnel",
    "entretien": "Professionnel",
    "rdv client": "Professionnel",

    # --- Décontracté / casual / everyday ---
    "casual": "Decontracte",
    "decontracte": "Decontracte",
    "décontracté": "Decontracte",
    "relax": "Decontracte",
    "detente": "Decontracte",
    "détente": "Decontracte",
    "confort": "Decontracte",
    "confortable": "Decontracte",
    "tous les jours": "Decontracte",
    "quotidien": "Decontracte",
    "everyday": "Decontracte",
    "weekend": "Decontracte",
    "brunch": "Decontracte",

    # --- Simple / minimal ---
    "simple": "Simple",
    "sobre": "Simple",
    "minimal": "Simple",
    "minimaliste": "Simple",
    "basique": "Simple",
    "clean": "Simple",
    "epure": "Simple",
    "épuré": "Simple",

    # --- Coloré / fun ---
    "colore": "Colore",
    "coloré": "Colore",
    "couleur": "Colore",
    "couleurs": "Colore",
    "flashy": "Colore",
    "fun": "Colore",
    "punchy": "Colore",
    "vif": "Colore",
    "vives": "Colore",
    "surprends": "Colore",

    # --- Streetwear / urbain ---
    "streetwear": "Streetwear",
    "street": "Streetwear",
    "urban": "Streetwear",
    "urbain": "Streetwear",
    "hoodie": "Streetwear",
    "baggy": "Streetwear",
    "oversize": "Streetwear",
    "oversized": "Streetwear",
    "cargo": "Streetwear",
    "quartier": "Streetwear",

    # --- Sportif ---
    "sport": "Sportif",
    "sportif": "Sportif",
    "football": "Sportif",
    "foot": "Sportif",
    "basket": "Sportif",
    "running": "Sportif",
    "course": "Sportif",
    "gym": "Sportif",
    "entrainement": "Sportif",
    "entraînement": "Sportif",

    # --- Soirée / sortie / fête ---
    "soiree": "Soiree",
    "soirée": "Soiree",
    "fete": "Soiree",
    "fête": "Soiree",
    "party": "Soiree",
    "soir": "Soiree",
    "club": "Soiree",
    "boite": "Soiree",
    "boîte": "Soiree",
    "sortie": "Soiree",
}

REQUIRED_CATS = ["top", "bottom", "shoes"]
OPTIONAL_CATS = ["headwear", "outerwear", "accessory"]
ALL_CATS = REQUIRED_CATS + OPTIONAL_CATS


# ─────────────────────────────────────────────────────────────────────────────
# Mapping style → tags GPT (style_tags / formality)
# ─────────────────────────────────────────────────────────────────────────────

# Mots-clés que GPT-4o renvoie typiquement dans `style_tags` et qui matchent
# nos styles canoniques. Tout match donne un bonus de score sur la pièce.
STYLE_TAGS_AFFINITY: dict[str, set[str]] = {
    "Simple":        {"minimaliste", "minimal", "basique", "clean", "epure", "sobre"},
    "Colore":        {"coloré", "colore", "vif", "fun", "graphique", "flashy"},
    "Classe":        {"chic", "élégant", "elegant", "raffiné", "raffine", "habillé"},
    "Professionnel": {"business", "business_casual", "tailoring", "tailleur", "bureau", "formel"},
    "Decontracte":   {"casual", "décontracté", "decontracte", "everyday", "weekend"},
    "Streetwear":    {"streetwear", "urbain", "urban", "hoodie", "baggy", "oversize", "oversized", "cargo", "skate"},
    "Sportif":       {"sport", "sportif", "athleisure", "running", "gym", "training"},
    "Soiree":        {"soiree", "soirée", "club", "party", "festif"},
}

# Niveau de "formel" estimé pour chaque style (échelle 0..4).
STYLE_FORMALITY_TARGET: dict[str, int] = {
    "Sportif": 0,
    "Streetwear": 1,
    "Decontracte": 1,
    "Simple": 2,
    "Colore": 2,
    "Classe": 3,
    "Soiree": 3,
    "Professionnel": 4,
}

# Mapping libre du `formality` retourné par GPT vers cette échelle.
FORMALITY_LEVEL: dict[str, int] = {
    "sportif": 0,
    "sport": 0,
    "casual": 1,
    "décontracté": 1,
    "decontracte": 1,
    "everyday": 1,
    "smart_casual": 2,
    "smart casual": 2,
    "business_casual": 3,
    "business casual": 3,
    "soirée": 3,
    "soiree": 3,
    "formel": 4,
    "formal": 4,
    "business": 4,
}

# Matières cohérentes par météo (clés WeatherTagKeys).
MATERIAL_BY_WEATHER: dict[str, set[str]] = {
    "cold":  {"laine", "wool", "cuir", "leather", "denim", "synthetique", "synthétique"},
    "mild":  {"coton", "denim", "lin", "synthetique", "synthétique"},
    "warm":  {"coton", "lin", "linen", "soie", "silk"},
    "hot":   {"lin", "linen", "coton", "soie", "silk"},
    "rain":  {"synthetique", "synthétique", "cuir", "leather"},
    "drizzle": {"synthetique", "synthétique"},
    "snow":  {"laine", "wool", "synthetique", "synthétique", "cuir", "leather"},
    "thunderstorm": {"synthetique", "synthétique"},
}

# Saisons (clés cohérentes avec SeasonKeys côté front).
ALL_SEASONS = ["winter", "spring", "summer", "autumn"]

# Mapping de la valeur "season" renvoyée par GPT vers nos clés stables.
SEASON_FROM_GPT: dict[str, set[str]] = {
    "winter":      {"hiver", "winter"},
    "spring":      {"printemps", "spring"},
    "summer":      {"été", "ete", "summer"},
    "autumn":      {"automne", "autumn", "fall"},
    "_all":        {"toute_saison", "toute saison", "all_seasons", "all seasons"},
    "_midseason":  {"mi-saison", "mi saison", "midseason", "mid_season"},
}


OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")


# ─────────────────────────────────────────────────────────────────────────────
# Helpers de normalisation
# ─────────────────────────────────────────────────────────────────────────────

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


def _normalize_garment_seasons(g: dict) -> set[str]:
    """Renvoie l'ensemble des saisons concernées par une pièce.
    - support de l'ancien champ string `season` (GPT)
    - support d'une liste éventuelle `seasons`
    - vide => pas de contrainte (compatible toutes saisons).
    """
    raw_list = g.get("seasons")
    candidates: list[str] = []
    if isinstance(raw_list, list):
        candidates.extend(str(x).lower() for x in raw_list)
    raw_single = g.get("season")
    if raw_single:
        candidates.append(str(raw_single).lower())

    out: set[str] = set()
    for c in candidates:
        c = c.strip()
        if not c:
            continue
        for key, aliases in SEASON_FROM_GPT.items():
            if c in aliases:
                if key == "_all":
                    out.update(ALL_SEASONS)
                elif key == "_midseason":
                    out.update({"spring", "autumn"})
                else:
                    out.add(key)
                break
    return out  # vide => "compatible toutes saisons"


def _formality_level(formality: str) -> Optional[int]:
    if not formality:
        return None
    key = formality.lower().strip()
    return FORMALITY_LEVEL.get(key)


def _style_tag_bonus(style_tags: list[str], style: str) -> int:
    """+2 si au moins un tag GPT colle au style demandé."""
    if not style_tags:
        return 0
    targets = STYLE_TAGS_AFFINITY.get(style, set())
    for t in style_tags:
        if t and t.lower().strip() in targets:
            return 2
    return 0


def _formality_bonus(formality: str, style: str) -> int:
    """+2 si formality GPT proche du style, -2 si très éloignée."""
    target = STYLE_FORMALITY_TARGET.get(style)
    lvl = _formality_level(formality)
    if target is None or lvl is None:
        return 0
    diff = abs(lvl - target)
    if diff == 0:
        return 2
    if diff == 1:
        return 1
    if diff >= 3:
        return -2
    return 0


def _season_bonus(g: dict, season_key: Optional[str]) -> int:
    """+2 si la pièce déclare la saison du jour, -3 si elle ne la déclare pas
    explicitement et qu'elle déclare uniquement d'autres saisons (saisonnier mismatch).
    Vide => 0 (passe-partout)."""
    if not season_key:
        return 0
    seasons = _normalize_garment_seasons(g)
    if not seasons:
        return 0
    if season_key in seasons:
        return 2
    return -3


def _weather_material_bonus(g: dict, weather_tags: list[str]) -> int:
    """+1 par tag météo cohérent avec la matière (max +2)."""
    if not weather_tags:
        return 0
    material = str(g.get("material") or "").lower().strip()
    if not material:
        return 0
    score = 0
    for tag in weather_tags:
        ok_set = MATERIAL_BY_WEATHER.get(tag, set())
        if material in ok_set:
            score += 1
    return min(score, 2)


def _pattern_bonus(g: dict, style: str) -> int:
    """Bonus discret par pattern selon le style (les pièces motivées sont
    moins adaptées au "Professionnel" / "Simple" et inversement.)"""
    pattern = str(g.get("pattern") or "").lower().strip()
    if not pattern or pattern == "uni":
        return 0
    flashy = pattern in {"motif", "fleuri", "graphique", "rayures", "carreaux"}
    if not flashy:
        return 0
    if style in {"Colore", "Streetwear", "Soiree"}:
        return 1
    if style in {"Professionnel", "Simple", "Classe"}:
        return -1
    return 0


def _score(
    g: dict,
    style: str,
    season_key: Optional[str],
    weather_tags: List[str],
) -> int:
    """Score d'une pièce vs (style, saison, météo) en agrégeant tous les signaux."""
    color = ""
    colors = g.get("colors")
    if isinstance(colors, list) and colors:
        color = str(colors[0])
    if not color:
        color = str(g.get("color") or "")
    family = _color_family(color)

    base = STYLE_WEIGHTS.get(style, {}).get(family, 1)
    base += _style_tag_bonus(g.get("style_tags") or [], style)
    base += _formality_bonus(str(g.get("formality") or ""), style)
    base += _season_bonus(g, season_key)
    base += _weather_material_bonus(g, weather_tags)
    base += _pattern_bonus(g, style)
    return base


# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

def suggest_outfit(
    garments: list[dict],
    style: str = "Simple",
    existing_outfits: list[dict] | None = None,
    season_key: Optional[str] = None,
    weather_tags: Optional[List[str]] = None,
) -> dict[str, str]:
    """Propose une combinaison une-par-catégorie.

    Args:
        garments:      pièces du dressing (avec attrs IA optionnels)
        style:         style libre (mappé vers un canonique)
        existing_outfits: pour pénaliser les pièces récemment portées
        season_key:    'winter' | 'spring' | 'summer' | 'autumn' (optionnel)
        weather_tags:  liste de tags météo du jour (clear, rain, cold, ...)
    """
    resolved = _resolve_style(style) if style not in STYLE_WEIGHTS else style
    weather = list(weather_tags or [])

    by_cat: dict[str, list[dict]] = {}
    for g in garments:
        by_cat.setdefault(g.get("category", ""), []).append(g)

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
            key=lambda g: (
                _score(g, resolved, season_key, weather)
                + (-2 if g.get("id") in recently_worn else 0)
            ),
            reverse=True,
        )
        top = scored[: max(1, len(scored) // 2)]
        suggestion[cat] = random.choice(top).get("id", "")

    if resolved in ("Simple", "Decontracte", "Professionnel"):
        for cat in OPTIONAL_CATS:
            if random.random() < 0.5:
                suggestion[cat] = ""

    # En cas de météo "cold/rain/snow", on s'assure qu'une outerwear est gardée si dispo.
    if any(t in {"cold", "rain", "snow", "thunderstorm"} for t in weather):
        if "outerwear" in by_cat and by_cat["outerwear"] and not suggestion.get("outerwear"):
            scored_out = sorted(
                by_cat["outerwear"],
                key=lambda g: _score(g, resolved, season_key, weather),
                reverse=True,
            )
            suggestion["outerwear"] = scored_out[0].get("id", "")

    return suggestion


def suggest_multiple(
    garments: list[dict],
    style: str = "Simple",
    count: int = 5,
    existing_outfits: list[dict] | None = None,
    season_key: Optional[str] = None,
    weather_tags: Optional[List[str]] = None,
) -> list[dict[str, str]]:
    results: list[dict[str, str]] = []
    seen: set[tuple] = set()
    attempts = 0
    while len(results) < count and attempts < count * 3:
        s = suggest_outfit(
            garments,
            style,
            existing_outfits,
            season_key=season_key,
            weather_tags=weather_tags,
        )
        key = tuple(sorted(s.items()))
        if key not in seen:
            seen.add(key)
            results.append(s)
        attempts += 1
    return results


# ─────────────────────────────────────────────────────────────────────────────
# Vision (analyse d'une photo de vêtement) — OpenAI GPT-4o-mini
# ─────────────────────────────────────────────────────────────────────────────

def analyze_garment_image(image_bytes: bytes, filename: str = "garment.jpg") -> Dict[str, Any]:
    """
    Analyze a garment photo using an external vision-capable LLM (e.g. OpenAI GPT-4o).

    Returns a dict with:
      - colors: List[str]           # couleurs détectées (principale + éventuelles secondaires)
      - category: str               # 'top', 'bottom', 'shoes', 'outerwear', 'headwear', 'accessory'
      - style_tags: List[str]       # ex: ['chic', 'streetwear', 'minimaliste']
      - formality: str              # 'casual', 'formel', 'soirée', ...
      - season: str                 # 'été', 'hiver', 'mi-saison', ...
      - pattern: str                # 'uni', 'rayures', 'carreaux', ...
      - material: str               # 'coton', 'denim', 'cuir', ...

    Si la clé API n'est pas configurée, renvoie une structure vide pour que le frontend
    ne plante pas, et on log un warning explicite (utile pour debug en prod).
    """
    if not OPENAI_API_KEY:
        logger.warning(
            "[analyze_garment_image] OPENAI_API_KEY is not set — falling back to empty result."
        )
        return {
            "colors": [],
            "category": "",
            "style_tags": [],
            "formality": "",
            "season": "",
            "pattern": "",
            "material": "",
        }

    api_url = "https://api.openai.com/v1/chat/completions"

    import base64

    b64 = base64.b64encode(image_bytes).decode("ascii")
    data_url = f"data:image/jpeg;base64,{b64}"

    system_prompt = (
        "Tu es un assistant de mode qui analyse UNE SEULE pièce vestimentaire sur une photo. "
        "Réponds STRICTEMENT au format JSON suivant, sans texte autour :\n\n"
        "{\n"
        '  "colors": ["couleur_principale", "autre_couleur_eventuelle"],\n'
        '  "category": "top|bottom|shoes|outerwear|headwear|accessory",\n'
        '  "style_tags": ["streetwear", "chic", "minimaliste", ...],\n'
        '  "formality": "casual|formel|soirée|sportif|business_casual",\n'
        '  "season": "été|hiver|mi-saison|toute_saison",\n'
        '  "pattern": "uni|rayures|carreaux|motif|fleuri|graphique",\n'
        '  "material": "coton|denim|laine|cuir|synthétique|soie|lin|autre"\n'
        "}\n\n"
        "- IMPORTANT pour \"colors\" : utilise uniquement des noms de couleurs en français compatibles avec une palette de mode, "
        "par exemple parmi : Noir, Blanc, Gris, Gris clair, Gris foncé, Beige, Camel, Marron, Marron clair, Marron foncé, "
        "Bleu, Bleu clair, Bleu foncé, Bleu marine, Bleu ciel, Bleu turquoise, Rouge, Rouge foncé, Rouge bordeaux, "
        "Rose, Rose poudré, Rose fuchsia, Vert, Vert clair, Vert foncé, Vert menthe, Vert kaki, Jaune, Jaune moutarde, "
        "Orange, Orange corail, Violet, Violet foncé, Lavande, Bordeaux, Navy, Khaki, Olive, Sable, Crème, Ivoire, "
        "Écru, Taupe, Charbon, Anthracite, Nude, Pêche, Corail, Saumon, Terracotta, Rouille, Brique, Caramel, Cognac, "
        "Champagne, Doré, Cuivre, Bronze, Argent, Métallique, Multicolore. "
        "Si tu hésites entre plusieurs variantes proches, choisis la plus basique (ex: 'Bleu', 'Rouge', 'Vert').\n\n"
        "Si tu hésites sur d'autres valeurs, choisis la plus probable, mais garde le JSON valide."
    )

    payload: Dict[str, Any] = {
        "model": "gpt-4o-mini",
        "messages": [
            {"role": "system", "content": system_prompt},
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "Analyse ce vêtement."},
                    {
                        "type": "image_url",
                        "image_url": {"url": data_url},
                    },
                ],
            },
        ],
        "temperature": 0.2,
        "response_format": {"type": "json_object"},
    }

    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json",
    }

    try:
        resp = requests.post(api_url, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        content = data["choices"][0]["message"]["content"]
        # content is already JSON thanks to response_format
        import json

        parsed: Dict[str, Any] = json.loads(content)

        def _as_list(val: Any) -> List[str]:
            if isinstance(val, list):
                return [str(v) for v in val]
            if isinstance(val, str) and val:
                return [val]
            return []

        result = {
            "colors": _as_list(parsed.get("colors", [])),
            "category": str(parsed.get("category", "")).strip(),
            "style_tags": _as_list(parsed.get("style_tags", [])),
            "formality": str(parsed.get("formality", "")).strip(),
            "season": str(parsed.get("season", "")).strip(),
            "pattern": str(parsed.get("pattern", "")).strip(),
            "material": str(parsed.get("material", "")).strip(),
        }
        logger.info(
            "[analyze_garment_image] ok filename=%s colors=%s category=%s",
            filename,
            result.get("colors"),
            result.get("category"),
        )
        return result
    except Exception as e:
        logger.exception(
            "[analyze_garment_image] FAILED filename=%s err=%s", filename, e
        )
        return {
            "colors": [],
            "category": "",
            "style_tags": [],
            "formality": "",
            "season": "",
            "pattern": "",
            "material": "",
        }
