from fastapi import APIRouter, Depends, UploadFile, File, Query, HTTPException
from ...core.security import get_current_uid
from ...services.storage_service import upload_bytes
from ...core.firebase import get_storage_bucket

router = APIRouter()


@router.post("/image")
async def upload_image(
    file: UploadFile = File(...),
    folder: str = Query(
        "misc",
        description="Storage sub-folder (garments, outfits, profiles, posts)",
    ),
    remove_bg: bool = Query(
        False,
        description="Supprimer l'arrière-plan (uniquement pour garments)",
    ),
    uid: str = Depends(get_current_uid),
):
    data = await file.read()
    ext = file.filename.rsplit(".", 1)[-1].lower() if file.filename and "." in file.filename else "jpg"
    try:
        url = upload_bytes(data, folder, uid, ext, remove_background=remove_bg)
    except Exception as exc:
        err = str(exc)
        if "403" in err or "forbidden" in err.lower():
            raise HTTPException(
                status_code=503,
                detail=(
                    "Le compte de service Firebase n'a pas les droits d'écriture sur "
                    "Firebase Storage. Dans Google Cloud Console → IAM, attribue le rôle "
                    "\"Storage Admin\" (ou \"Storage Object Creator\") au compte de service "
                    "utilisé par le backend. Détail : " + err
                ),
            ) from exc
        raise HTTPException(status_code=500, detail=err) from exc
    return {"url": url}


@router.get("/health/storage")
async def storage_health():
    """Vérifie que le compte de service peut lire et écrire dans Firebase Storage."""
    import uuid as _uuid
    bucket = get_storage_bucket()
    test_path = f"_healthcheck/{_uuid.uuid4().hex}.txt"
    blob = bucket.blob(test_path)
    try:
        blob.upload_from_string(b"ok", content_type="text/plain")
        blob.delete()
        return {
            "storage": "ok",
            "bucket": bucket.name,
        }
    except Exception as exc:
        err = str(exc)
        return {
            "storage": "error",
            "bucket": bucket.name,
            "detail": err,
            "hint": (
                "403 → le compte de service manque du rôle 'Storage Admin' dans Google Cloud Console → IAM. "
                "Images non visibles → le bucket doit aussi avoir la règle IAM "
                "allUsers:roles/storage.objectViewer pour les URLs publiques."
            ),
        }
