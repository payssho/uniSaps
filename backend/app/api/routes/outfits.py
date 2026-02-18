from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from ...core.security import get_current_uid
from ...core.firebase import get_firestore_client
from ...models.outfit import OutfitCreate, OutfitUpdate, OutfitOut

router = APIRouter()


def _col(uid: str):
    return get_firestore_client().collection("users").document(uid).collection("outfits")


@router.get("", response_model=list[OutfitOut])
async def list_outfits(uid: str = Depends(get_current_uid)):
    docs = _col(uid).order_by("created_at", direction="DESCENDING").stream()
    return [OutfitOut(**d.to_dict(), id=d.id) for d in docs]


@router.post("", response_model=OutfitOut, status_code=201)
async def create_outfit(body: OutfitCreate, uid: str = Depends(get_current_uid)):
    garments = body.garments or {
        "headwear": "", "top": "", "outerwear": "",
        "bottom": "", "shoes": "", "accessory": "",
    }
    data = {
        "user_id": uid,
        "name": body.name,
        "garments": garments,
        "created_at": datetime.now().isoformat(),
        "times_worn": 0,
        "last_worn": "",
        "wear_history": [],
        "photo_urls": [],
    }
    ref = _col(uid).add(data)
    doc_id = ref[1].id
    data["id"] = doc_id
    return OutfitOut(**data)


@router.get("/{outfit_id}", response_model=OutfitOut)
async def get_outfit(outfit_id: str, uid: str = Depends(get_current_uid)):
    doc = _col(uid).document(outfit_id).get()
    if not doc.exists:
        raise HTTPException(404, "Outfit introuvable.")
    return OutfitOut(**doc.to_dict(), id=doc.id)


@router.patch("/{outfit_id}", response_model=OutfitOut)
async def update_outfit(outfit_id: str, body: OutfitUpdate, uid: str = Depends(get_current_uid)):
    ref = _col(uid).document(outfit_id)
    if not ref.get().exists:
        raise HTTPException(404, "Outfit introuvable.")
    ref.update(body.model_dump(exclude_none=True))
    return OutfitOut(**ref.get().to_dict(), id=outfit_id)


@router.delete("/{outfit_id}", status_code=204)
async def delete_outfit(outfit_id: str, uid: str = Depends(get_current_uid)):
    ref = _col(uid).document(outfit_id)
    if not ref.get().exists:
        raise HTTPException(404, "Outfit introuvable.")
    ref.delete()
