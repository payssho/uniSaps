from app.models.style_profile import StyleProfile, default_style_profile
from app.services.style_profile_service import identity_to_canonical_style


def test_default_style_profile_when_skipped():
    p = default_style_profile(skipped=True)
    assert p.goal_wardrobe == 3
    assert p.identity_style == "casual"
    assert p.fashion_comfort == "balanced"
    assert p.onboarding_skipped is True


def test_identity_to_canonical():
    assert identity_to_canonical_style("classic") == "Classe"
    assert identity_to_canonical_style("unknown") == "Decontracte"
