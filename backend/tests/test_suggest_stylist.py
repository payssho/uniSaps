import sys
from unittest.mock import MagicMock

import pytest

from app.models.style_profile import StyleProfile
from app.services.ai_service import (
    StylistUnavailableError,
    _parse_stylist_response,
    _validate_garment_ids,
    suggest_stylist_outfits,
)


def test_validate_garment_ids_rejects_unknown():
    allowed = {"g1", "g2"}
    outfits = [
        {"garments": {"top": "g1", "bottom": "g99"}, "rationale_short": "Test."}
    ]
    out = _validate_garment_ids(outfits, allowed)
    assert out[0]["garments"]["bottom"] == ""


def test_validate_garment_ids_truncates_rationale():
    allowed = {"g1"}
    long_text = "x" * 200
    outfits = [{"garments": {"top": "g1"}, "rationale_short": long_text}]
    out = _validate_garment_ids(outfits, allowed)
    assert len(out[0]["rationale_short"]) == 120


def test_parse_stylist_response():
    raw = (
        '{"suggestions":[{"garments":{"top":"g1"},'
        '"rationale_short":"Look sobre."}]}'
    )
    out = _parse_stylist_response(raw)
    assert len(out) == 1
    assert out[0]["rationale_short"] == "Look sobre."


def test_suggest_stylist_outfits_raises_without_api_key(monkeypatch):
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    garments = [{"id": "g1", "category": "top", "colors": ["noir"]}]
    profile = StyleProfile()
    with pytest.raises(StylistUnavailableError):
        suggest_stylist_outfits(
            garments,
            count=2,
            style_profile=profile,
        )


def test_suggest_stylist_outfits_mock_gemini(monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "test-key")
    mock_response = MagicMock()
    mock_response.text = (
        '{"suggestions":['
        '{"garments":{"top":"g1","bottom":"g2","shoes":"g3"},'
        '"rationale_short":"Look sobre et équilibré."},'
        '{"garments":{"top":"g2","bottom":"g1","shoes":"g3"},'
        '"rationale_short":"Contraste maîtrisé."}'
        "]}"
    )
    mock_instance = MagicMock()
    mock_instance.generate_content.return_value = mock_response
    mock_genai = MagicMock()
    mock_genai.GenerativeModel.return_value = mock_instance
    mock_genai.types.GenerationConfig = MagicMock()

    garments = [
        {"id": "g1", "category": "top", "colors": ["noir"], "style_tags": []},
        {"id": "g2", "category": "bottom", "colors": ["beige"], "style_tags": []},
        {"id": "g3", "category": "shoes", "colors": ["blanc"], "style_tags": []},
    ]
    profile = StyleProfile(fashion_comfort="confident")

    monkeypatch.setitem(sys.modules, "google.generativeai", mock_genai)
    out = suggest_stylist_outfits(
        garments,
        count=2,
        style_profile=profile,
        user_prompt="bureau",
        season_key="winter",
        weather_tags=["cold"],
    )

    assert len(out) == 2
    allowed = {"g1", "g2", "g3"}
    for suggestion in out:
        for garment_id in suggestion["garments"].values():
            if garment_id:
                assert garment_id in allowed
        assert len(suggestion["rationale_short"]) <= 120
