from app.core.errors import api_error


def test_api_error_returns_error_code_dict():
    exc = api_error(404, "garment_not_found")
    assert exc.status_code == 404
    assert exc.detail == {"error_code": "garment_not_found"}
