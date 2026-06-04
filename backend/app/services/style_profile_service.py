from app.models.style_profile import StyleProfile

IDENTITY_TO_CANONICAL = {
    "casual": "Decontracte",
    "classic": "Classe",
    "minimal": "Simple",
    "streetwear": "Streetwear",
    "sport": "Sportif",
    "professional": "Professionnel",
    "colorful": "Colore",
    "evening": "Soiree",
}


def identity_to_canonical_style(identity: str) -> str:
    return IDENTITY_TO_CANONICAL.get(identity, "Decontracte")


def dominant_goal_key(profile: StyleProfile) -> str:
    goals = {
        "goal_wardrobe": profile.goal_wardrobe,
        "goal_inspiration": profile.goal_inspiration,
        "goal_refine_style": profile.goal_refine_style,
        "goal_track_wear": profile.goal_track_wear,
    }
    return max(goals, key=goals.get)
