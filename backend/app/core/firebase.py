import firebase_admin
from firebase_admin import credentials, firestore, storage, auth
from .config import get_settings

_initialized = False


def init_firebase():
    global _initialized
    if _initialized:
        return
    settings = get_settings()
    cred = credentials.Certificate(settings.firebase_service_account_key_path)
    firebase_admin.initialize_app(cred, {
        "storageBucket": settings.firebase_storage_bucket,
    })
    _initialized = True


def get_firestore_client():
    init_firebase()
    return firestore.client()


def get_storage_bucket():
    init_firebase()
    return storage.bucket()


def verify_id_token(id_token: str) -> dict:
    """Verify a Firebase ID token and return the decoded claims."""
    init_firebase()
    return auth.verify_id_token(id_token)
