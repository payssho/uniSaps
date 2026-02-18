from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
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
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token Firebase invalide ou expire.",
        )
