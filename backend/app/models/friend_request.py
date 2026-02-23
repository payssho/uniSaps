from pydantic import BaseModel
from typing import List


class FriendRequestCreate(BaseModel):
    to_uid: str


class FriendRequestOut(BaseModel):
    id: str = ""
    from_uid: str = ""
    to_uid: str = ""
    from_username: str = ""
    from_photo_url: str = ""
    to_username: str = ""
    to_photo_url: str = ""
    status: str = "pending"
    created_at: str = ""
