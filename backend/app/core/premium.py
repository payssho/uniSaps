from app.core.errors import api_error
from app.core.firebase import get_firestore_client


def user_account_tier(uid: str) -> str:
    db = get_firestore_client()
    snap = db.collection("users").document(uid).get()
    if not snap.exists:
        return "free"
    return (snap.to_dict() or {}).get("account_tier", "free") or "free"


def require_premium_user(uid: str) -> None:
    tier = user_account_tier(uid).lower()
    if tier not in ("premium", "paid"):
        raise api_error(403, "premium_required")
