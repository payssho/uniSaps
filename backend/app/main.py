from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from .core.config import get_settings
from .core.firebase import init_firebase
from .api.routes import api_router

settings = get_settings()

app = FastAPI(
    title="uniSaps API",
    version="1.0.0",
    description="Backend API pour l'application uniSaps - Outfit Manager",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")


@app.on_event("startup")
async def startup():
    init_firebase()


@app.get("/health")
async def health():
    return {"status": "ok"}


_PRIVACY_HTML = Path(__file__).resolve().parent / "static" / "privacy_fr.html"
_ACCOUNT_DELETION_HTML = (
    Path(__file__).resolve().parent / "static" / "account_deletion_fr.html"
)


@app.get("/privacy", response_class=HTMLResponse)
async def privacy_policy_fr():
    """Page publique pour la Play Console (politique de confidentialité)."""
    if not _PRIVACY_HTML.is_file():
        return HTMLResponse(
            content="<p>Politique de confidentialité indisponible.</p>",
            status_code=503,
        )
    return HTMLResponse(
        content=_PRIVACY_HTML.read_text(encoding="utf-8"),
        headers={"Cache-Control": "public, max-age=3600"},
    )


@app.get("/account-deletion", response_class=HTMLResponse)
async def account_deletion_fr():
    """Page publique pour Play Console (suppression de compte)."""
    if not _ACCOUNT_DELETION_HTML.is_file():
        return HTMLResponse(
            content="<p>Page de suppression de compte indisponible.</p>",
            status_code=503,
        )
    return HTMLResponse(
        content=_ACCOUNT_DELETION_HTML.read_text(encoding="utf-8"),
        headers={"Cache-Control": "public, max-age=3600"},
    )
