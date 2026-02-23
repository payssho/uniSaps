import firebase_admin
from firebase_admin import credentials, firestore, storage, auth
from pathlib import Path
from .config import get_settings

_initialized = False


def init_firebase():
    global _initialized
    if _initialized:
        return
    settings = get_settings()
    
    # Résoudre le chemin du fichier serviceAccountKey.json
    # Chercher dans le dossier backend/ d'abord
    key_path = Path(settings.firebase_service_account_key_path)
    if not key_path.is_absolute():
        # Si c'est un chemin relatif, chercher dans le dossier backend/
        backend_dir = Path(__file__).parent.parent.parent  # Remonter de app/core/ vers backend/
        key_path = backend_dir / key_path
    
    if not key_path.exists():
        raise FileNotFoundError(
            f"Le fichier serviceAccountKey.json est introuvable à: {key_path}\n"
            f"Télécharge-le depuis Firebase Console > Paramètres du projet > Comptes de service\n"
            f"et place-le dans le dossier backend/"
        )
    
    cred = credentials.Certificate(str(key_path))
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
