"""Firebase Storage helpers for image upload / delete."""
import time
import uuid
from io import BytesIO
from PIL import Image, ImageOps
# rembg désactivé : dépassement de la limite 500 MB des Lambdas Vercel.
# from rembg import remove
from ..core.firebase import get_storage_bucket

# Taille max pour limiter stockage et bande passante (coûts Firebase)
MAX_SIZE = (600, 600)
IMAGE_QUALITY = 78


def _remove_background(data: bytes) -> bytes:
    """Supprime le background d'une image en utilisant rembg.
    Désactivé sur Vercel (rembg dépasse 500 MB). En prod, on renvoie l'image telle quelle."""
    return data


def _resize(data: bytes, preserve_transparency: bool = False) -> bytes:
    img = Image.open(BytesIO(data))
    # Corriger l'orientation selon les métadonnées EXIF (photos prises en portrait/paysage)
    try:
        img = ImageOps.exif_transpose(img)
    except Exception:
        # Si pas d'EXIF ou erreur, on continue avec l'image telle quelle
        pass
    img.thumbnail(MAX_SIZE, Image.LANCZOS)
    
    # Si on préserve la transparence (pour les vêtements sans background)
    if preserve_transparency:
        if img.mode != "RGBA":
            img = img.convert("RGBA")
        buf = BytesIO()
        img.save(buf, format="PNG")
        return buf.getvalue()
    else:
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")
        buf = BytesIO()
        img.save(buf, format="JPEG", quality=IMAGE_QUALITY)
        return buf.getvalue()


def upload_bytes(
    data: bytes,
    folder: str,
    user_id: str,
    extension: str = "jpg",
    remove_background: bool = False,
) -> str:
    # Pour les vêtements : on peut choisir de supprimer ou non le fond.
    # rembg désactivé sur Vercel (dépasse 500 MB) → remove_background ignoré, on resize en JPEG.
    if folder == "garments" and remove_background:
        data = _remove_background(data)  # no-op sans rembg
    processed = _resize(data, preserve_transparency=False)
    extension = "jpg"  # toujours JPEG sans rembg (PNG réservé au cas où rembg serait réactivé)

    filename = f"{folder}/{user_id}/{uuid.uuid4().hex}.{extension}"
    bucket = get_storage_bucket()
    # GCS attend en général image/jpeg, pas image/jpg (MIME non standard).
    mime = "image/jpeg" if extension in ("jpg", "jpeg") else f"image/{extension}"

    for attempt in range(3):
        blob = bucket.blob(filename)
        blob.cache_control = "public, max-age=31536000"
        try:
            blob.upload_from_string(processed, content_type=mime)
            return blob.public_url
        except Exception as e:
            err = str(e).lower()
            transient = any(
                token in err
                for token in (
                    "403",
                    "forbidden",
                    "429",
                    "503",
                    "502",
                    "500",
                    "timeout",
                    "unavailable",
                    "deadline exceeded",
                    "connection reset",
                    "broken pipe",
                )
            )
            if attempt < 2 and transient:
                time.sleep(0.65 * (attempt + 1))
                continue
            raise


def delete_image(url: str):
    if not url:
        return
    bucket = get_storage_bucket()
    prefix = f"https://storage.googleapis.com/{bucket.name}/"
    if url.startswith(prefix):
        path = url[len(prefix):]
        blob = bucket.blob(path)
        if blob.exists():
            blob.delete()
