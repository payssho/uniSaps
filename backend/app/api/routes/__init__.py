from fastapi import APIRouter
from .users import router as users_router
from .garments import router as garments_router
from .outfits import router as outfits_router
from .posts import router as posts_router
from .ai import router as ai_router
from .upload import router as upload_router
from .friends import router as friends_router

api_router = APIRouter()
api_router.include_router(users_router, prefix="/users", tags=["users"])
api_router.include_router(garments_router, prefix="/garments", tags=["garments"])
api_router.include_router(outfits_router, prefix="/outfits", tags=["outfits"])
api_router.include_router(posts_router, prefix="/posts", tags=["posts"])
api_router.include_router(ai_router, prefix="/ai", tags=["ai"])
api_router.include_router(upload_router, prefix="/upload", tags=["upload"])
api_router.include_router(friends_router, prefix="/friends", tags=["friends"])
