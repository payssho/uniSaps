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
    result = []
    for d in docs:
        doc_data = d.to_dict()
        # Migration depuis l'ancien format (color: str) vers le nouveau (colors: List[str])
        if "colors" not in doc_data and "color" in doc_data:
            doc_data["colors"] = [doc_data["color"]] if doc_data["color"] else []
        elif "colors" not in doc_data:
            doc_data["colors"] = []
        # Assurer que color existe pour compatibilité
        if "color" not in doc_data and doc_data.get("colors"):
            doc_data["color"] = doc_data["colors"][0] if doc_data["colors"] else ""
        elif "color" not in doc_data:
            doc_data["color"] = ""
        result.append(GarmentOut(**doc_data, id=d.id))
    return result


@router.post("", response_model=GarmentOut, status_code=201)
async def create_garment(body: GarmentCreate, uid: str = Depends(get_current_uid)):
    data = body.model_dump()
    # Si color est fourni mais pas colors, convertir
    if not data.get("colors") and data.get("color"):
        data["colors"] = [data["color"]]
    # Assurer que color contient la première couleur pour compatibilité
    if data.get("colors") and not data.get("color"):
        data["color"] = data["colors"][0] if data["colors"] else ""
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
    doc_data = doc.to_dict()
    # Migration depuis l'ancien format
    if "colors" not in doc_data and "color" in doc_data:
        doc_data["colors"] = [doc_data["color"]] if doc_data["color"] else []
    elif "colors" not in doc_data:
        doc_data["colors"] = []
    # Assurer que color existe pour compatibilité
    if "color" not in doc_data and doc_data.get("colors"):
        doc_data["color"] = doc_data["colors"][0] if doc_data["colors"] else ""
    elif "color" not in doc_data:
        doc_data["color"] = ""
    return GarmentOut(**doc_data, id=doc.id)


@router.patch("/{garment_id}", response_model=GarmentOut)
async def update_garment(garment_id: str, body: GarmentUpdate, uid: str = Depends(get_current_uid)):
    ref = _col(uid).document(garment_id)
    if not ref.get().exists:
        raise HTTPException(404, "Vetement introuvable.")
    update_data = body.model_dump(exclude_none=True)
    # Si color est fourni mais pas colors, convertir
    if "color" in update_data and "colors" not in update_data:
        update_data["colors"] = [update_data["color"]]
    # Si colors est fourni mais pas color, utiliser la première couleur
    if "colors" in update_data and "color" not in update_data:
        update_data["color"] = update_data["colors"][0] if update_data["colors"] else ""
    ref.update(update_data)
    doc_data = ref.get().to_dict()
    # Migration depuis l'ancien format
    if "colors" not in doc_data and "color" in doc_data:
        doc_data["colors"] = [doc_data["color"]] if doc_data["color"] else []
    elif "colors" not in doc_data:
        doc_data["colors"] = []
    # Assurer que color existe pour compatibilité
    if "color" not in doc_data and doc_data.get("colors"):
        doc_data["color"] = doc_data["colors"][0] if doc_data["colors"] else ""
    elif "color" not in doc_data:
        doc_data["color"] = ""
    return GarmentOut(**doc_data, id=garment_id)


@router.delete("/{garment_id}", status_code=204)
async def delete_garment(garment_id: str, uid: str = Depends(get_current_uid)):
    ref = _col(uid).document(garment_id)
    if not ref.get().exists:
        raise HTTPException(404, "Vetement introuvable.")
    ref.delete()
