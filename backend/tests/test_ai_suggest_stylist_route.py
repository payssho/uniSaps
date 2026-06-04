from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.core.security import get_current_uid
from app.main import app
from app.services.ai_service import StylistUnavailableError

client = TestClient(app)

GARMENT_A = {"id": "g1", "category": "top", "colors": ["blue"]}
GARMENT_B = {"id": "g2", "category": "bottom", "colors": ["black"]}


def _doc(doc_id: str, data: dict):
    snap = MagicMock()
    snap.id = doc_id
    snap.to_dict.return_value = {k: v for k, v in data.items() if k != "id"}
    return snap


def _mock_firestore(*, user_data: dict | None = None, garments: list[dict] | None = None):
    db = MagicMock()
    user_doc = MagicMock()

    garment_docs = [
        _doc(g["id"], g) for g in (garments or [])
    ]

    def collection_side_effect(name: str):
        coll = MagicMock()
        if name == "garments":
            coll.stream.return_value = iter(garment_docs)
        elif name == "outfits":
            coll.stream.return_value = iter([])
        return coll

    user_doc.collection.side_effect = collection_side_effect
    db.collection.return_value.document.return_value = user_doc

    user_snap = MagicMock()
    user_snap.exists = user_data is not None
    user_snap.to_dict.return_value = user_data or {}
    user_doc.get.return_value = user_snap
    return db


@pytest.fixture
def auth_client():
    app.dependency_overrides[get_current_uid] = lambda: "uid-test"
    yield client
    app.dependency_overrides.clear()


@patch("app.api.routes.ai.require_premium_user")
@patch("app.api.routes.ai.suggest_stylist_outfits")
@patch("app.api.routes.ai.get_firestore_client")
def test_suggest_stylist_premium_returns_suggestions(
    mock_db, mock_stylist, mock_premium, auth_client
):
    mock_premium.return_value = None
    mock_db.return_value = _mock_firestore(
        user_data={"account_tier": "premium"},
        garments=[GARMENT_A, GARMENT_B],
    )
    mock_stylist.return_value = [
        {
            "garments": {"top": "g1", "bottom": "g2", "shoes": "g1"},
            "rationale_short": "Harmonie bleu et noir.",
        }
    ]

    response = auth_client.post(
        "/api/v1/ai/suggest-stylist",
        json={"count": 1, "user_prompt": "soirée"},
        headers={"Authorization": "Bearer test"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["fallback"] is False
    assert len(data["suggestions"]) == 1
    assert data["suggestions"][0]["rationale_short"] == "Harmonie bleu et noir."
    mock_stylist.assert_called_once()


@patch("app.core.premium.get_firestore_client")
def test_suggest_stylist_free_user_returns_403(mock_db, auth_client):
    user_snap = MagicMock()
    user_snap.exists = True
    user_snap.to_dict.return_value = {"account_tier": "free"}
    mock_db.return_value.collection.return_value.document.return_value.get.return_value = (
        user_snap
    )

    response = auth_client.post(
        "/api/v1/ai/suggest-stylist",
        json={"count": 2},
        headers={"Authorization": "Bearer test"},
    )

    assert response.status_code == 403
    assert response.json()["detail"] == {"error_code": "premium_required"}


@patch("app.api.routes.ai.require_premium_user")
@patch("app.api.routes.ai.suggest_multiple")
@patch("app.api.routes.ai.suggest_stylist_outfits")
@patch("app.api.routes.ai.get_firestore_client")
def test_suggest_stylist_fallback_on_unavailable(
    mock_db, mock_stylist, mock_multiple, mock_premium, auth_client
):
    mock_premium.return_value = None
    mock_db.return_value = _mock_firestore(
        user_data={"account_tier": "premium"},
        garments=[GARMENT_A, GARMENT_B],
    )
    mock_stylist.side_effect = StylistUnavailableError("no_api_key")
    mock_multiple.return_value = [
        {"top": "g1", "bottom": "g2", "shoes": "g1"},
    ]

    response = auth_client.post(
        "/api/v1/ai/suggest-stylist",
        json={"count": 1},
        headers={"Authorization": "Bearer test"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["fallback"] is True
    assert data["suggestions"][0]["garments"]["top"] == "g1"
    assert data["suggestions"][0]["rationale_short"] == "Look équilibré pour ta garde-robe."
    mock_multiple.assert_called_once()
