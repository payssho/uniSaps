"""
Rule-based outfit suggestion engine with color/style matching and wear-history awareness.
Migrated from the original Flet app.

Extended with optional image-analysis helpers powered by an external LLM
for extracting richer attributes (couleur, style, matière...) from garment photos.
"""
import os
import random
from datetime import datetime, timedelta
from typing import Any, Dict, List

import requests

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


OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")


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

    If no API key is configured, returns a safe, mostly empty structure
    so that the frontend ne plante pas.
    """
    if not OPENAI_API_KEY:
        return {
            "colors": [],
            "category": "",
            "style_tags": [],
            "formality": "",
            "season": "",
            "pattern": "",
            "material": "",
        }

    # NOTE: This implementation assumes the OpenAI "chat completions" API with
    # a vision-capable model (e.g. gpt-4o or gpt-4.1). Adapt if you use another provider.
    api_url = "https://api.openai.com/v1/chat/completions"

    # Encode image as base64 data URL
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

        # Normaliser un minimum et fournir des valeurs par défaut
        def _as_list(val: Any) -> List[str]:
            if isinstance(val, list):
                return [str(v) for v in val]
            if isinstance(val, str) and val:
                return [val]
            return []

        return {
            "colors": _as_list(parsed.get("colors", [])),
            "category": str(parsed.get("category", "")).strip(),
            "style_tags": _as_list(parsed.get("style_tags", [])),
            "formality": str(parsed.get("formality", "")).strip(),
            "season": str(parsed.get("season", "")).strip(),
            "pattern": str(parsed.get("pattern", "")).strip(),
            "material": str(parsed.get("material", "")).strip(),
        }
    except Exception:
        # En cas d'erreur réseau / parsing, renvoyer une structure vide pour ne pas bloquer le flux
        return {
            "colors": [],
            "category": "",
            "style_tags": [],
            "formality": "",
            "season": "",
            "pattern": "",
            "material": "",
        }
