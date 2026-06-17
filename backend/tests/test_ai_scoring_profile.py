from app.models.style_profile import StyleProfile
from app.services.ai_service import _score_with_profile


def test_audacity_boosts_warm_family():
    g = {"colors": ["rouge"], "pattern": "uni"}
    low = _score_with_profile(g, "Simple", None, [], StyleProfile(audacity=1))
    high = _score_with_profile(g, "Simple", None, [], StyleProfile(audacity=5))
    assert high >= low


def test_goal_wardrobe_boosts_uni_pattern():
    g = {"colors": ["noir"], "pattern": "uni"}
    low = _score_with_profile(g, "Simple", None, [], StyleProfile(goal_wardrobe=1))
    high = _score_with_profile(g, "Simple", None, [], StyleProfile(goal_wardrobe=5))
    assert high >= low
