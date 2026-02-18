"""Firebase Storage helpers for image upload / delete."""
import uuid
from io import BytesIO
from PIL import Image
from ..core.firebase import get_storage_bucket

MAX_SIZE = (800, 800)


def _resize(data: bytes) -> bytes:
    img = Image.open(BytesIO(data))
    img.thumbnail(MAX_SIZE, Image.LANCZOS)
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
    resized = _resize(data)
    filename = f"{folder}/{user_id}/{uuid.uuid4().hex}.{extension}"
    bucket = get_storage_bucket()
    blob = bucket.blob(filename)
    blob.upload_from_string(resized, content_type=f"image/{extension}")
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
