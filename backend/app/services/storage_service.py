"""Firebase Storage helpers for image upload / delete."""
import uuid
from io import BytesIO
from PIL import Image
from rembg import remove
from ..core.firebase import get_storage_bucket

MAX_SIZE = (800, 800)


def _remove_background(data: bytes) -> bytes:
    """Supprime le background d'une image en utilisant rembg."""
    output = remove(data)
    return output


def _resize(data: bytes, preserve_transparency: bool = False) -> bytes:
    img = Image.open(BytesIO(data))
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
        img.save(buf, format="JPEG", quality=85)
        return buf.getvalue()


def upload_bytes(
    data: bytes,
    folder: str,
    user_id: str,
    extension: str = "jpg",
) -> str:
    # Supprimer le background pour les images de vêtements
    if folder == "garments":
        data = _remove_background(data)
        # Après suppression du background, on utilise PNG pour préserver la transparence
        processed = _resize(data, preserve_transparency=True)
        extension = "png"
    else:
        processed = _resize(data, preserve_transparency=False)
    
    filename = f"{folder}/{user_id}/{uuid.uuid4().hex}.{extension}"
    bucket = get_storage_bucket()
    blob = bucket.blob(filename)
    blob.upload_from_string(processed, content_type=f"image/{extension}")
    blob.make_public()
    return blob.public_url


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
