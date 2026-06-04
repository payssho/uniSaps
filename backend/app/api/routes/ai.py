import os
from typing import List, Optional

from fastapi import APIRouter, Depends, File, UploadFile
from pydantic import BaseModel

from app.core.errors import api_error
from ...core.security import get_current_uid
from ...core.firebase import get_firestore_client
from ...services.ai_service import suggest_multiple, analyze_garment_image

router = APIRouter()


class SuggestRequest(BaseModel):
    style: str = "Simple"
    count: int = 3
    # Contexte du jour fourni par le client (météo + saison) pour
    # rendre le scoring sensible au temps qu'il fait / à la saison.
    season_key: Optional[str] = None
    weather_tags: Optional[List[str]] = None


@router.post("/suggest")
async def suggest_outfits(body: SuggestRequest, uid: str = Depends(get_current_uid)):
    db = get_firestore_client()

    garments_snap = db.collection("users").document(uid).collection("garments").stream()
    garments = []
    for d in garments_snap:
        g = d.to_dict()
        g["id"] = d.id
        garments.append(g)

    outfits_snap = db.collection("users").document(uid).collection("outfits").stream()
    existing = []
    for d in outfits_snap:
        o = d.to_dict()
        o["id"] = d.id
        existing.append(o)

    suggestions = suggest_multiple(
        garments,
        body.style,
        body.count,
        existing,
        season_key=body.season_key,
        weather_tags=body.weather_tags,
    )
    return {"suggestions": suggestions}


@router.post("/analyze-garment")
async def analyze_garment(
    file: UploadFile = File(...),
    uid: str = Depends(get_current_uid),  # Auth pour rester cohérent même si non utilisé
):
    """
    Analyse une photo de vêtement avec un modèle de vision (LLM).

    Retourne des attributs structurés (couleurs, catégorie, style_tags, etc.)
    qui seront ensuite stockés côté client dans Firestore avec le vêtement.
    """
    content = await file.read()
    if not content:
        raise api_error(400, "empty_file")

    result = analyze_garment_image(content, file.filename or "garment.jpg")
    return result


@router.get("/health")
async def ai_health():
    """Diagnostic rapide : indique si la clé Gemini est configurée côté serveur.

    Volontairement public (pas de uid requis) pour pouvoir vérifier depuis
    n'importe quel client. On ne renvoie JAMAIS la clé : juste un booléen.
    """
    has_key = bool(os.getenv("GEMINI_API_KEY"))
    masked = ""
    raw = os.getenv("GEMINI_API_KEY") or ""
    if raw:
        masked = f"{raw[:6]}…{raw[-4:]}" if len(raw) > 12 else "configured"
    return {
        "gemini_key_configured": has_key,
        "gemini_key_preview": masked,
    }
