import os
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from pydantic import BaseModel, ValidationError

from ...core.security import get_current_uid
from ...core.firebase import get_firestore_client
from ...core.errors import api_error
from ...models.style_profile import StyleProfile
from ...core.premium import require_premium_user
from ...models.style_profile import default_style_profile
from ...services.ai_service import (
    StylistUnavailableError,
    analyze_garment_image,
    suggest_multiple,
    suggest_stylist_outfits,
)
from ...services.style_profile_service import identity_to_canonical_style

router = APIRouter()


class SuggestStylistRequest(BaseModel):
    count: int = 3
    user_prompt: str = ""
    season_key: Optional[str] = None
    weather_tags: Optional[List[str]] = None


class SuggestRequest(BaseModel):
    style: str = "Simple"
    count: int = 3
    # Contexte du jour fourni par le client (météo + saison) pour
    # rendre le scoring sensible au temps qu'il fait / à la saison.
    season_key: Optional[str] = None
    weather_tags: Optional[List[str]] = None
    style_profile: Optional[Dict[str, Any]] = None


def _parse_style_profile(raw: dict[str, Any]) -> StyleProfile:
    try:
        return StyleProfile.model_validate(raw)
    except ValidationError:
        raise api_error(400, "invalid_style_profile") from None


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

    profile: StyleProfile | None = None
    if body.style_profile is not None:
        profile = _parse_style_profile(body.style_profile)
    else:
        user_snap = db.collection("users").document(uid).get()
        if user_snap.exists:
            raw = (user_snap.to_dict() or {}).get("style_profile")
            if raw:
                profile = _parse_style_profile(raw)

    effective_style = (
        identity_to_canonical_style(profile.identity_style) if profile else body.style
    )

    suggestions = suggest_multiple(
        garments,
        effective_style,
        body.count,
        existing,
        season_key=body.season_key,
        weather_tags=body.weather_tags,
        style_profile=profile,
    )
    return {"suggestions": suggestions}


@router.post("/suggest-stylist")
async def suggest_stylist(
    body: SuggestStylistRequest,
    uid: str = Depends(get_current_uid),
):
    require_premium_user(uid)
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

    user_snap = db.collection("users").document(uid).get()
    raw_profile = (user_snap.to_dict() or {}).get("style_profile") if user_snap.exists else None
    if raw_profile:
        profile = _parse_style_profile(raw_profile)
    else:
        profile = default_style_profile(skipped=True)

    if len(garments) < 2:
        raise api_error(400, "insufficient_garments")

    effective_style = identity_to_canonical_style(profile.identity_style)

    try:
        suggestions = suggest_stylist_outfits(
            garments,
            count=body.count,
            style_profile=profile,
            user_prompt=body.user_prompt,
            season_key=body.season_key,
            weather_tags=body.weather_tags,
        )
        return {"suggestions": suggestions, "fallback": False}
    except StylistUnavailableError:
        classic = suggest_multiple(
            garments,
            effective_style,
            body.count,
            existing,
            season_key=body.season_key,
            weather_tags=body.weather_tags,
            style_profile=profile,
        )
        suggestions = [
            {
                "garments": s,
                "rationale_short": "Look équilibré pour ta garde-robe.",
            }
            for s in classic
        ]
        return {"suggestions": suggestions, "fallback": True}


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
        raise HTTPException(status_code=400, detail="Fichier vide.")

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
