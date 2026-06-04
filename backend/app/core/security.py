from fastapi import Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from .errors import api_error
from .firebase import verify_id_token

bearer_scheme = HTTPBearer()


async def get_current_uid(
    cred: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> str:
    """Extract and verify Firebase UID from the Authorization header."""
    try:
        decoded = verify_id_token(cred.credentials)
        return decoded["uid"]
    except Exception:
        raise api_error(status.HTTP_401_UNAUTHORIZED, "invalid_firebase_token")
