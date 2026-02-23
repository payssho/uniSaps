from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from google.cloud.firestore_v1 import ArrayUnion, ArrayRemove
from ...core.security import get_current_uid
from ...core.firebase import get_firestore_client
from ...models.friend_request import FriendRequestCreate, FriendRequestOut
from ...models.user import UserPublicOut

router = APIRouter()


def _col():
    return get_firestore_client().collection("friend_requests")


def _users():
    return get_firestore_client().collection("users")


@router.post("/request", response_model=FriendRequestOut, status_code=201)
async def send_friend_request(body: FriendRequestCreate, uid: str = Depends(get_current_uid)):
    if body.to_uid == uid:
        raise HTTPException(400, "Impossible de s'ajouter soi-meme.")

    existing = list(
        _col()
        .where("from_uid", "==", uid)
        .where("to_uid", "==", body.to_uid)
        .where("status", "==", "pending")
        .limit(1)
        .stream()
    )
    if existing:
        raise HTTPException(409, "Demande deja envoyee.")

    reverse = list(
        _col()
        .where("from_uid", "==", body.to_uid)
        .where("to_uid", "==", uid)
        .where("status", "==", "pending")
        .limit(1)
        .stream()
    )
    if reverse:
        doc = reverse[0]
        _accept(doc.id, body.to_uid, uid)
        return FriendRequestOut(**doc.to_dict(), id=doc.id, status="accepted")

    from_user = _users().document(uid).get()
    to_user = _users().document(body.to_uid).get()
    from_data = from_user.to_dict() if from_user.exists else {}
    to_data = to_user.to_dict() if to_user.exists else {}

    data = {
        "from_uid": uid,
        "to_uid": body.to_uid,
        "from_username": from_data.get("username", ""),
        "from_photo_url": from_data.get("profile_photo_url", ""),
        "to_username": to_data.get("username", ""),
        "to_photo_url": to_data.get("profile_photo_url", ""),
        "status": "pending",
        "created_at": datetime.now().isoformat(),
    }
    _, ref = _col().add(data)
    data["id"] = ref.id
    return FriendRequestOut(**data)


@router.post("/request/{request_id}/accept", response_model=FriendRequestOut)
async def accept_friend_request(request_id: str, uid: str = Depends(get_current_uid)):
    doc = _col().document(request_id).get()
    if not doc.exists:
        raise HTTPException(404, "Demande introuvable.")
    data = doc.to_dict()
    if data["to_uid"] != uid:
        raise HTTPException(403, "Action non autorisee.")
    if data["status"] != "pending":
        raise HTTPException(400, "Demande deja traitee.")
    _accept(request_id, data["from_uid"], data["to_uid"])
    data["status"] = "accepted"
    data["id"] = request_id
    return FriendRequestOut(**data)


@router.post("/request/{request_id}/reject", response_model=FriendRequestOut)
async def reject_friend_request(request_id: str, uid: str = Depends(get_current_uid)):
    doc = _col().document(request_id).get()
    if not doc.exists:
        raise HTTPException(404, "Demande introuvable.")
    data = doc.to_dict()
    if data["to_uid"] != uid:
        raise HTTPException(403, "Action non autorisee.")
    _col().document(request_id).update({"status": "rejected"})
    data["status"] = "rejected"
    data["id"] = request_id
    return FriendRequestOut(**data)


@router.delete("/request/{request_id}", status_code=204)
async def cancel_friend_request(request_id: str, uid: str = Depends(get_current_uid)):
    doc = _col().document(request_id).get()
    if not doc.exists:
        raise HTTPException(404, "Demande introuvable.")
    data = doc.to_dict()
    if data["from_uid"] != uid:
        raise HTTPException(403, "Action non autorisee.")
    _col().document(request_id).delete()


@router.get("/requests/received", response_model=list[FriendRequestOut])
async def get_received_requests(uid: str = Depends(get_current_uid)):
    docs = (
        _col()
        .where("to_uid", "==", uid)
        .where("status", "==", "pending")
        .order_by("created_at", direction="DESCENDING")
        .stream()
    )
    return [FriendRequestOut(**d.to_dict(), id=d.id) for d in docs]


@router.get("/requests/sent", response_model=list[FriendRequestOut])
async def get_sent_requests(uid: str = Depends(get_current_uid)):
    docs = (
        _col()
        .where("from_uid", "==", uid)
        .where("status", "==", "pending")
        .order_by("created_at", direction="DESCENDING")
        .stream()
    )
    return [FriendRequestOut(**d.to_dict(), id=d.id) for d in docs]


@router.delete("/{friend_uid}", status_code=204)
async def remove_friend(friend_uid: str, uid: str = Depends(get_current_uid)):
    _users().document(uid).update({"friends": ArrayRemove([friend_uid])})
    _users().document(friend_uid).update({"friends": ArrayRemove([uid])})


@router.get("/search", response_model=list[UserPublicOut])
async def search_users(
    q: str = Query("", min_length=1),
    uid: str = Depends(get_current_uid),
):
    lower = q.lower()
    docs = (
        _users()
        .where("username", ">=", lower)
        .where("username", "<", lower + "z")
        .limit(20)
        .stream()
    )
    results = []
    for d in docs:
        data = d.to_dict()
        if data.get("uid") != uid:
            results.append(UserPublicOut(**data))
    return results


def _accept(request_id: str, from_uid: str, to_uid: str):
    db = get_firestore_client()
    batch = db.batch()
    batch.update(_col().document(request_id), {"status": "accepted"})
    batch.update(_users().document(from_uid), {"friends": ArrayUnion([to_uid])})
    batch.update(_users().document(to_uid), {"friends": ArrayUnion([from_uid])})
    batch.commit()
