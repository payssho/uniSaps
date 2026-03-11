from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from pydantic import BaseModel
from ...core.security import get_current_uid
from ...core.firebase import get_firestore_client
from ...services.ai_service import suggest_multiple, analyze_garment_image

router = APIRouter()


class SuggestRequest(BaseModel):
    style: str = "Simple"
    count: int = 3


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

    suggestions = suggest_multiple(garments, body.style, body.count, existing)
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
        raise HTTPException(status_code=400, detail="Fichier vide.")

    result = analyze_garment_image(content, file.filename or "garment.jpg")
    return result
