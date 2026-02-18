from pydantic import BaseModel


class GarmentCreate(BaseModel):
    name: str
    brand: str = ""
    color: str = ""
    category: str
    image_url: str = ""


class GarmentUpdate(BaseModel):
    name: str | None = None
    brand: str | None = None
    color: str | None = None
    category: str | None = None
    image_url: str | None = None


class GarmentOut(BaseModel):
    id: str
    user_id: str
    name: str
    brand: str = ""
    color: str = ""
    category: str = ""
    image_url: str = ""
    created_at: str = ""
    times_worn: int = 0
