"""
Point d'entrée Vercel : la fonction est exposée sous /api, donc les requêtes
arrivent avec path /api/health, /api/api/v1/... On retire le préfixe /api pour
que FastAPI reçoive /health et /api/v1/...
"""
from app.main import app as fastapi_app


async def app(scope, receive, send):
    path = scope.get("path", "")
    if path.startswith("/api"):
        scope = dict(scope)
        scope["path"] = path[4:] or "/"  # /api/health -> /health
    await fastapi_app(scope, receive, send)

