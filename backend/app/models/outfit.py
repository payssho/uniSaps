from pydantic import BaseModel


class OutfitCreate(BaseModel):
    name: str
    garments: dict[str, str] = {}


class OutfitUpdate(BaseModel):
    name: str | None = None
    garments: dict[str, str] | None = None
    times_worn: int | None = None
    last_worn: str | None = None
    photo_urls: list[str] | None = None


class OutfitOut(BaseModel):
    id: str
    user_id: str
    name: str
    garments: dict[str, str] = {}
    created_at: str = ""
    times_worn: int = 0
    last_worn: str = ""
    wear_history: list[str] = []
    photo_urls: list[str] = []
