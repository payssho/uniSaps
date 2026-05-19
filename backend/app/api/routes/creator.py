from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from ...core.security import get_current_uid
from ...core.firebase import get_firestore_client

router = APIRouter()

CREATOR_ACTIVATION_CODE = "CREATOR2026"
SUBSCRIPTION_DAYS = 30


class ActivateSubscriptionBody(BaseModel):
    activation_code: str


class SubscriptionStatusOut(BaseModel):
    account_type: str = "user"
    creator_subscription_status: str = "inactive"
    creator_subscription_expires_at: str = ""


@router.post("/activate-subscription", response_model=SubscriptionStatusOut)
async def activate_subscription(
    body: ActivateSubscriptionBody,
    uid: str = Depends(get_current_uid),
):
    code = body.activation_code.strip().upper().replace(" ", "")
    if code != CREATOR_ACTIVATION_CODE:
        raise HTTPException(400, "Code d'activation invalide.")

    db = get_firestore_client()
    ref = db.collection("users").document(uid)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(404, "Utilisateur introuvable.")

    expires = (datetime.utcnow() + timedelta(days=SUBSCRIPTION_DAYS)).isoformat()
    updates = {
        "account_type": "creator",
        "creator_subscription_status": "active",
        "creator_subscription_expires_at": expires,
    }
    ref.update(updates)
    data = {**snap.to_dict(), **updates}
    return SubscriptionStatusOut(
        account_type=data.get("account_type", "creator"),
        creator_subscription_status=data.get("creator_subscription_status", "active"),
        creator_subscription_expires_at=expires,
    )


@router.get("/subscription-status", response_model=SubscriptionStatusOut)
async def subscription_status(uid: str = Depends(get_current_uid)):
    db = get_firestore_client()
    snap = db.collection("users").document(uid).get()
    if not snap.exists:
        raise HTTPException(404, "Utilisateur introuvable.")
    data = snap.to_dict()
    return SubscriptionStatusOut(
        account_type=data.get("account_type", "user"),
        creator_subscription_status=data.get("creator_subscription_status", "inactive"),
        creator_subscription_expires_at=data.get("creator_subscription_expires_at", ""),
    )
