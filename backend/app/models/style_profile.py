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
VALID_FREQUENCY = {"daily", "weekly", "occasional"}
VALID_SOCIAL = {"friends", "private", "undecided"}
VALID_ARCHETYPE = {"gestionnaire", "explorateur", "apprenti_style"}


class StyleProfile(BaseModel):
    goal_wardrobe: int = Field(ge=1, le=5, default=3)
    goal_inspiration: int = Field(ge=1, le=5, default=3)
    goal_refine_style: int = Field(ge=1, le=5, default=3)
    goal_track_wear: int = Field(ge=1, le=5, default=3)
    identity_style: str = "casual"
    audacity: int = Field(ge=1, le=5, default=3)
    fashion_comfort: str = "balanced"
    preferred_styles: list[str] = Field(default_factory=list)
    usage_frequency: str = "weekly"
    social_intent: str = "undecided"
    archetype: str = "gestionnaire"
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

    @field_validator("preferred_styles")
    @classmethod
    def _preferred_styles(cls, v: list[str]) -> list[str]:
        return [s for s in v if s in VALID_IDENTITY]

    @field_validator("usage_frequency")
    @classmethod
    def _usage_frequency(cls, v: str) -> str:
        return v if v in VALID_FREQUENCY else "weekly"

    @field_validator("social_intent")
    @classmethod
    def _social_intent(cls, v: str) -> str:
        return v if v in VALID_SOCIAL else "undecided"

    @field_validator("archetype")
    @classmethod
    def _archetype(cls, v: str) -> str:
        return v if v in VALID_ARCHETYPE else "gestionnaire"


def default_style_profile(*, skipped: bool = False) -> StyleProfile:
    return StyleProfile(
        onboarding_skipped=skipped,
        updated_at=datetime.now().isoformat(),
    )
