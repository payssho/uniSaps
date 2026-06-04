from datetime import datetime

from pydantic import BaseModel, Field, field_validator

VALID_IDENTITY = {
    "casual",
    "classic",
    "minimal",
    "streetwear",
    "sport",
    "professional",
    "colorful",
    "evening",
}
VALID_COMFORT = {"beginner", "balanced", "confident"}


class StyleProfile(BaseModel):
    goal_wardrobe: int = Field(ge=1, le=5, default=3)
    goal_inspiration: int = Field(ge=1, le=5, default=3)
    goal_refine_style: int = Field(ge=1, le=5, default=3)
    goal_track_wear: int = Field(ge=1, le=5, default=3)
    identity_style: str = "casual"
    audacity: int = Field(ge=1, le=5, default=3)
    fashion_comfort: str = "balanced"
    onboarding_skipped: bool = False
    updated_at: str = ""

    @field_validator("identity_style")
    @classmethod
    def _identity(cls, v: str) -> str:
        return v if v in VALID_IDENTITY else "casual"

    @field_validator("fashion_comfort")
    @classmethod
    def _comfort(cls, v: str) -> str:
        return v if v in VALID_COMFORT else "balanced"


def default_style_profile(*, skipped: bool = False) -> StyleProfile:
    return StyleProfile(
        onboarding_skipped=skipped,
        updated_at=datetime.now().isoformat(),
    )
