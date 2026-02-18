from pydantic import BaseModel


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
