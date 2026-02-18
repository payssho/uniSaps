from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from ...core.security import get_current_uid
from ...core.firebase import get_firestore_client
from ...models.garment import GarmentCreate, GarmentUpdate, GarmentOut

router = APIRouter()


def _col(uid: str):
    return get_firestore_client().collection("users").document(uid).collection("garments")


@router.get("", response_model=list[GarmentOut])
async def list_garments(
    category: str = Query("", description="Filter by category"),
    uid: str = Depends(get_current_uid),
):
    q = _col(uid)
    if category:
        q = q.where("category", "==", category)
    docs = q.stream()
    return [GarmentOut(**d.to_dict(), id=d.id) for d in docs]


@router.post("", response_model=GarmentOut, status_code=201)
async def create_garment(body: GarmentCreate, uid: str = Depends(get_current_uid)):
    data = body.model_dump()
    data["user_id"] = uid
    data["created_at"] = datetime.now().isoformat()
    data["times_worn"] = 0
    ref = _col(uid).add(data)
    doc_id = ref[1].id
    data["id"] = doc_id
    return GarmentOut(**data)


@router.get("/{garment_id}", response_model=GarmentOut)
async def get_garment(garment_id: str, uid: str = Depends(get_current_uid)):
    doc = _col(uid).document(garment_id).get()
    if not doc.exists:
        raise HTTPException(404, "Vetement introuvable.")
    return GarmentOut(**doc.to_dict(), id=doc.id)


@router.patch("/{garment_id}", response_model=GarmentOut)
async def update_garment(garment_id: str, body: GarmentUpdate, uid: str = Depends(get_current_uid)):
    ref = _col(uid).document(garment_id)
    if not ref.get().exists:
        raise HTTPException(404, "Vetement introuvable.")
    ref.update(body.model_dump(exclude_none=True))
    return GarmentOut(**ref.get().to_dict(), id=garment_id)


@router.delete("/{garment_id}", status_code=204)
async def delete_garment(garment_id: str, uid: str = Depends(get_current_uid)):
    ref = _col(uid).document(garment_id)
    if not ref.get().exists:
        raise HTTPException(404, "Vetement introuvable.")
    ref.delete()
