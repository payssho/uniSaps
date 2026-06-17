from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException

from app.core.premium import require_premium_user, user_account_tier


def _mock_snap(exists: bool, data: dict | None = None):
    snap = MagicMock()
    snap.exists = exists
    snap.to_dict.return_value = data or {}
    return snap


@patch("app.core.premium.get_firestore_client")
def test_user_account_tier_missing_doc(mock_db):
    mock_db.return_value.collection.return_value.document.return_value.get.return_value = (
        _mock_snap(False)
    )
    assert user_account_tier("uid-1") == "free"


@patch("app.core.premium.get_firestore_client")
def test_user_account_tier_premium(mock_db):
    mock_db.return_value.collection.return_value.document.return_value.get.return_value = (
        _mock_snap(True, {"account_tier": "premium"})
    )
    assert user_account_tier("uid-1") == "premium"


@patch("app.core.premium.get_firestore_client")
def test_require_premium_user_allows_premium(mock_db):
    mock_db.return_value.collection.return_value.document.return_value.get.return_value = (
        _mock_snap(True, {"account_tier": "paid"})
    )
    require_premium_user("uid-1")


@patch("app.core.premium.get_firestore_client")
def test_require_premium_user_blocks_free(mock_db):
    mock_db.return_value.collection.return_value.document.return_value.get.return_value = (
        _mock_snap(True, {"account_tier": "free"})
    )
    with pytest.raises(HTTPException) as exc:
        require_premium_user("uid-1")
    assert exc.value.status_code == 403
    assert exc.value.detail == {"error_code": "premium_required"}
