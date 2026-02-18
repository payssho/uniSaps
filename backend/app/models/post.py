from pydantic import BaseModel


class GarmentRef(BaseModel):
    name: str = ""
    brand: str = ""


class PostCreate(BaseModel):
    image_url: str
    outfit_id: str = ""
    garment_refs: list[GarmentRef] = []
    caption: str = ""


class PostOut(BaseModel):
    id: str
    user_id: str
    username: str = ""
    user_photo_url: str = ""
    image_url: str = ""
    outfit_id: str = ""
    garment_refs: list[GarmentRef] = []
    caption: str = ""
    likes: int = 0
    liked_by: list[str] = []
    created_at: str = ""
