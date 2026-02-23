from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException
from ...core.security import get_current_uid
from ...core.firebase import get_firestore_client
from ...models.user import UserCreate, UserUpdate, UserOut

router = APIRouter()


@router.post("", response_model=UserOut, status_code=201)
async def create_user(body: UserCreate, uid: str = Depends(get_current_uid)):
    db = get_firestore_client()
    doc_ref = db.collection("users").document(uid)
    now = datetime.now().isoformat()
    data = {
        "uid": uid,
        "email": "",
        "username": body.username,
        "display_name": body.display_name,
        "profile_photo_url": body.profile_photo_url,
        "created_at": now,
        "tutorial_seen": {"dressing": False, "creations": False, "outfits": False, "profile": False, "inspiration": False},
        "current_streak": 0,
        "best_streak": 0,
        "daily_outfit_id": "",
        "daily_outfit_date": "",
        "daily_photo_url": "",
        "is_new_user": False,
        "is_private": False,
        "friends": [],
    }
    doc_ref.set(data)
    return UserOut(**data)


@router.get("/me", response_model=UserOut)
async def get_me(uid: str = Depends(get_current_uid)):
    db = get_firestore_client()
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        raise HTTPException(404, "Utilisateur introuvable.")
    return UserOut(**doc.to_dict())


@router.patch("/me", response_model=UserOut)
async def update_me(body: UserUpdate, uid: str = Depends(get_current_uid)):
    db = get_firestore_client()
    ref = db.collection("users").document(uid)
    updates = body.model_dump(exclude_none=True)
    if "tutorial_seen" in updates:
        updates["tutorial_seen"] = updates["tutorial_seen"].model_dump() if hasattr(updates["tutorial_seen"], "model_dump") else updates["tutorial_seen"]
    ref.update(updates)
    return UserOut(**ref.get().to_dict())


@router.post("/me/daily-check", response_model=UserOut)
async def daily_check(uid: str = Depends(get_current_uid)):
    """Check and reset daily outfit, update streak."""
    db = get_firestore_client()
    ref = db.collection("users").document(uid)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(404, "Utilisateur introuvable.")
    data = snap.to_dict()
    today = date.today().isoformat()
    last_date = data.get("daily_outfit_date", "")

    if last_date == today:
        return UserOut(**data)

    updates: dict = {"daily_outfit_id": "", "daily_photo_url": ""}

    if last_date:
        yesterday = (date.today().replace(day=date.today().day)).isoformat()
        try:
            from datetime import timedelta
            yesterday = (date.today() - timedelta(days=1)).isoformat()
        except Exception:
            pass
        if last_date == yesterday and data.get("daily_outfit_id"):
            updates["current_streak"] = data.get("current_streak", 0) + 1
            updates["best_streak"] = max(data.get("best_streak", 0), updates["current_streak"])
        elif last_date != yesterday:
            updates["current_streak"] = 0

    updates["daily_outfit_date"] = today
    ref.update(updates)
    data.update(updates)
    return UserOut(**data)
