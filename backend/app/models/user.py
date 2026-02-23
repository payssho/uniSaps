from pydantic import BaseModel
from typing import List


class TutorialState(BaseModel):
    dressing: bool = False
    creations: bool = False
    outfits: bool = False
    profile: bool = False
    inspiration: bool = False


class UserCreate(BaseModel):
    username: str
    display_name: str = ""
    profile_photo_url: str = ""


class UserUpdate(BaseModel):
    username: str | None = None
    display_name: str | None = None
    profile_photo_url: str | None = None
    tutorial_seen: TutorialState | None = None
    daily_outfit_id: str | None = None
    daily_outfit_date: str | None = None
    daily_photo_url: str | None = None
    current_streak: int | None = None
    best_streak: int | None = None
    is_private: bool | None = None


class UserOut(BaseModel):
    uid: str
    email: str = ""
    username: str = ""
    display_name: str = ""
    profile_photo_url: str = ""
    created_at: str = ""
    tutorial_seen: TutorialState = TutorialState()
    current_streak: int = 0
    best_streak: int = 0
    daily_outfit_id: str = ""
    daily_outfit_date: str = ""
    daily_photo_url: str = ""
    is_new_user: bool = True
    is_private: bool = False
    friends: List[str] = []


class UserPublicOut(BaseModel):
    uid: str
    username: str = ""
    display_name: str = ""
    profile_photo_url: str = ""
    is_private: bool = False
    friends: List[str] = []
