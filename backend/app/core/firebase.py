import os
import json
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore, storage, auth

from .config import get_settings

_initialized = False


def init_firebase():
    global _initialized
    if _initialized:
        return
    settings = get_settings()

    # 1) Priorité à la variable d'env pour Vercel / prod
    sa_json = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON")
    if sa_json:
        try:
            data = json.loads(sa_json)
        except json.JSONDecodeError as exc:
            raise RuntimeError(
                "La variable d'environnement FIREBASE_SERVICE_ACCOUNT_JSON n'est pas un JSON valide."
            ) from exc
        cred = credentials.Certificate(data)
    else:
        # 2) Fallback local : lire le fichier serviceAccountKey.json comme avant
        key_path = Path(settings.firebase_service_account_key_path)
        if not key_path.is_absolute():
            backend_dir = Path(__file__).parent.parent.parent  # backend/
            key_path = backend_dir / key_path

        if not key_path.exists():
            raise FileNotFoundError(
                f"Le fichier serviceAccountKey.json est introuvable à: {key_path}\n"
                f"Télécharge-le depuis Firebase Console > Paramètres du projet > Comptes de service\n"
                f"et place-le dans le dossier backend/ OU configure FIREBASE_SERVICE_ACCOUNT_JSON sur Vercel."
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
