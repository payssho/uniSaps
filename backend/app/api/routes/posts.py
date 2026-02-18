from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from google.cloud.firestore_v1 import ArrayUnion, ArrayRemove, Increment
from ...core.security import get_current_uid
from ...core.firebase import get_firestore_client
from ...models.post import PostCreate, PostOut

router = APIRouter()


def _col():
    return get_firestore_client().collection("posts")


@router.get("", response_model=list[PostOut])
async def list_posts(limit: int = Query(50, le=100)):
    docs = _col().order_by("created_at", direction="DESCENDING").limit(limit).stream()
    return [PostOut(**d.to_dict(), id=d.id) for d in docs]


@router.get("/mine", response_model=list[PostOut])
async def my_posts(uid: str = Depends(get_current_uid)):
    docs = _col().where("user_id", "==", uid).order_by("created_at", direction="DESCENDING").stream()
    return [PostOut(**d.to_dict(), id=d.id) for d in docs]


@router.post("", response_model=PostOut, status_code=201)
async def create_post(body: PostCreate, uid: str = Depends(get_current_uid)):
    db = get_firestore_client()
    user_doc = db.collection("users").document(uid).get()
    user_data = user_doc.to_dict() if user_doc.exists else {}

    data = {
        "user_id": uid,
        "username": user_data.get("username", ""),
        "user_photo_url": user_data.get("profile_photo_url", ""),
        "image_url": body.image_url,
        "outfit_id": body.outfit_id,
        "garment_refs": [r.model_dump() for r in body.garment_refs],
        "caption": body.caption,
        "likes": 0,
        "liked_by": [],
        "created_at": datetime.now().isoformat(),
    }
    ref = _col().add(data)
    data["id"] = ref[1].id
    return PostOut(**data)


@router.post("/{post_id}/toggle-like")
async def toggle_like(post_id: str, uid: str = Depends(get_current_uid)):
    ref = _col().document(post_id)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(404, "Post introuvable.")
    liked_by = snap.to_dict().get("liked_by", [])
    if uid in liked_by:
        ref.update({"liked_by": ArrayRemove([uid]), "likes": Increment(-1)})
        return {"liked": False}
    else:
        ref.update({"liked_by": ArrayUnion([uid]), "likes": Increment(1)})
        return {"liked": True}


@router.delete("/{post_id}", status_code=204)
async def delete_post(post_id: str, uid: str = Depends(get_current_uid)):
    ref = _col().document(post_id)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(404, "Post introuvable.")
    if snap.to_dict().get("user_id") != uid:
        raise HTTPException(403, "Action non autorisee.")
    ref.delete()
