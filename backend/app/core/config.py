from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Valeurs par défaut raisonnables pour éviter les buckets vides en prod.
    # Elles peuvent être surchargées par les variables d'environnement
    # FIREBASE_PROJECT_ID et FIREBASE_STORAGE_BUCKET (recommandé sur Vercel).
    firebase_project_id: str = "unisaps-3ad84"
    firebase_storage_bucket: str = "unisaps-3ad84.firebasestorage.app"
    firebase_service_account_key_path: str = "serviceAccountKey.json"
    cors_origins: list[str] = ["*"]

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
