from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
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
