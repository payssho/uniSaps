from fastapi import APIRouter, Depends, UploadFile, File, Query
from ...core.security import get_current_uid
from ...services.storage_service import upload_bytes

router = APIRouter()


@router.post("/image")
async def upload_image(
    file: UploadFile = File(...),
    folder: str = Query("misc", description="Storage sub-folder (garments, outfits, profiles, posts)"),
    uid: str = Depends(get_current_uid),
):
    data = await file.read()
    ext = file.filename.rsplit(".", 1)[-1].lower() if file.filename and "." in file.filename else "jpg"
    url = upload_bytes(data, folder, uid, ext)
    return {"url": url}
