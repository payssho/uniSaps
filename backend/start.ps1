# Script de démarrage du backend uniSaps
Write-Host "Démarrage du backend uniSaps..." -ForegroundColor Cyan
Write-Host ""

# Activer le venv et lancer uvicorn
& .\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
