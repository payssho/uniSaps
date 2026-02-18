from fastapi import APIRouter, Depends
from pydantic import BaseModel
from ...core.security import get_current_uid
from ...core.firebase import get_firestore_client
from ...services.ai_service import suggest_multiple

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
