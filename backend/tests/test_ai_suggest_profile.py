from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.core.security import get_current_uid
from app.main import app

client = TestClient(app)

VALID_PROFILE = {
    "goal_wardrobe": 3,
    "goal_inspiration": 3,
    "goal_refine_style": 3,
    "goal_track_wear": 3,
    "identity_style": "classic",
    "audacity": 3,
    "fashion_comfort": "balanced",
    "onboarding_skipped": False,
    "updated_at": "",
}


def _empty_stream():
    return iter([])


def _mock_firestore(*, user_data: dict | None = None):
    db = MagicMock()
    user_doc = MagicMock()
    user_doc.collection.return_value.stream.side_effect = _empty_stream
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


@patch("app.api.routes.ai.suggest_multiple")
@patch("app.api.routes.ai.get_firestore_client")
def test_suggest_uses_firestore_style_profile(mock_db, mock_suggest, auth_client):
    mock_db.return_value = _mock_firestore(
        user_data={"style_profile": VALID_PROFILE},
    )
    mock_suggest.return_value = []

    response = auth_client.post(
        "/api/v1/ai/suggest",
        json={"style": "Simple", "count": 2},
        headers={"Authorization": "Bearer test"},
    )

    assert response.status_code == 200
    mock_suggest.assert_called_once()
    assert mock_suggest.call_args[0][1] == "Classe"
    assert mock_suggest.call_args.kwargs["style_profile"] is not None
    assert mock_suggest.call_args.kwargs["style_profile"].identity_style == "classic"


@patch("app.api.routes.ai.suggest_multiple")
@patch("app.api.routes.ai.get_firestore_client")
def test_suggest_body_style_profile_overrides_style(mock_db, mock_suggest, auth_client):
    mock_db.return_value = _mock_firestore()
    mock_suggest.return_value = []

    response = auth_client.post(
        "/api/v1/ai/suggest",
        json={
            "style": "Streetwear",
            "count": 1,
            "style_profile": VALID_PROFILE,
        },
        headers={"Authorization": "Bearer test"},
    )

    assert response.status_code == 200
    mock_suggest.assert_called_once()
    assert mock_suggest.call_args[0][1] == "Classe"


@patch("app.api.routes.ai.get_firestore_client")
def test_suggest_invalid_style_profile_returns_400(mock_db, auth_client):
    mock_db.return_value = _mock_firestore()

    response = auth_client.post(
        "/api/v1/ai/suggest",
        json={"style_profile": {"goal_wardrobe": "not-a-number"}},
        headers={"Authorization": "Bearer test"},
    )

    assert response.status_code == 400
    assert response.json()["detail"] == {"error_code": "invalid_style_profile"}
