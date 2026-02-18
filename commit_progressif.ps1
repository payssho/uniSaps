# Script de commits progressifs pour uniSaps
# Execute chaque commit un par un

Write-Host "=== Plan de commits progressifs uniSaps ===" -ForegroundColor Cyan
Write-Host ""

# Commit 1
Write-Host "[1/20] Setup backend FastAPI..." -ForegroundColor Yellow
git add backend/requirements.txt backend/.env.example backend/.gitignore backend/app/core/ backend/app/main.py backend/app/__init__.py
git commit -m 'feat(backend): setup FastAPI avec configuration Firebase et securite'
Write-Host "✓ Commit 1 terminé" -ForegroundColor Green
Write-Host ""

# Commit 2
Write-Host "[2/20] Modèles backend..." -ForegroundColor Yellow
git add backend/app/models/
git commit -m 'feat(backend): ajout des modeles Pydantic (User, Garment, Outfit, Post)'
Write-Host "✓ Commit 2 terminé" -ForegroundColor Green
Write-Host ""

# Commit 3
Write-Host "[3/20] Services backend..." -ForegroundColor Yellow
git add backend/app/services/
git commit -m 'feat(backend): services de stockage images et suggestions IA'
Write-Host "✓ Commit 3 terminé" -ForegroundColor Green
Write-Host ""

# Commit 4
Write-Host "[4/20] Endpoints Users..." -ForegroundColor Yellow
git add backend/app/api/__init__.py backend/app/api/routes/__init__.py backend/app/api/routes/users.py
git commit -m 'feat(backend): endpoints CRUD utilisateurs et gestion streak quotidien'
Write-Host "✓ Commit 4 terminé" -ForegroundColor Green
Write-Host ""

# Commit 5
Write-Host "[5/20] Endpoints Garments..." -ForegroundColor Yellow
git add backend/app/api/routes/garments.py
git commit -m 'feat(backend): endpoints CRUD vetements par utilisateur'
Write-Host "✓ Commit 5 terminé" -ForegroundColor Green
Write-Host ""

# Commit 6
Write-Host "[6/20] Endpoints Outfits..." -ForegroundColor Yellow
git add backend/app/api/routes/outfits.py
git commit -m 'feat(backend): endpoints CRUD outfits et historique de port'
Write-Host "✓ Commit 6 terminé" -ForegroundColor Green
Write-Host ""

# Commit 7
Write-Host "[7/20] Endpoints Posts + Upload + AI..." -ForegroundColor Yellow
git add backend/app/api/routes/posts.py backend/app/api/routes/upload.py backend/app/api/routes/ai.py
git commit -m 'feat(backend): endpoints posts sociaux, upload images et suggestions IA'
Write-Host "✓ Commit 7 terminé" -ForegroundColor Green
Write-Host ""

# Commit 8
Write-Host "[8/20] Setup frontend Flutter..." -ForegroundColor Yellow
git add frontend/pubspec.yaml frontend/.env frontend/.gitignore frontend/analysis_options.yaml frontend/lib/core/
git commit -m 'feat(frontend): setup Flutter avec theme Material 3 et constantes'
Write-Host "✓ Commit 8 terminé" -ForegroundColor Green
Write-Host ""

# Commit 9
Write-Host "[9/20] Modèles frontend..." -ForegroundColor Yellow
git add frontend/lib/models/
git commit -m 'feat(frontend): modeles de donnees Dart (User, Garment, Outfit, Post)'
Write-Host "✓ Commit 9 terminé" -ForegroundColor Green
Write-Host ""

# Commit 10
Write-Host "[10/20] Services Firebase frontend..." -ForegroundColor Yellow
git add frontend/lib/services/ frontend/lib/firebase_options.dart frontend/lib/main.dart frontend/lib/app.dart frontend/web/index.html
git commit -m 'feat(frontend): services Firebase (Auth, Firestore, Storage) et configuration'
Write-Host "✓ Commit 10 terminé" -ForegroundColor Green
Write-Host ""

# Commit 11
Write-Host "[11/20] Providers Riverpod..." -ForegroundColor Yellow
git add frontend/lib/providers/
git commit -m 'feat(frontend): state management Riverpod pour auth, garments, outfits, posts'
Write-Host "✓ Commit 11 terminé" -ForegroundColor Green
Write-Host ""

# Commit 12
Write-Host "[12/20] Écrans authentification..." -ForegroundColor Yellow
git add frontend/lib/core/routes/ frontend/lib/screens/auth/
git commit -m 'feat(frontend): ecrans authentification (login, signup, onboarding)'
Write-Host "✓ Commit 12 terminé" -ForegroundColor Green
Write-Host ""

# Commit 13
Write-Host "[13/20] Widgets réutilisables..." -ForegroundColor Yellow
git add frontend/lib/widgets/
git commit -m 'feat(frontend): widgets reutilisables (cards, chips, images compatibles web)'
Write-Host "✓ Commit 13 terminé" -ForegroundColor Green
Write-Host ""

# Commit 14
Write-Host "[14/20] Écran Dressing..." -ForegroundColor Yellow
git add frontend/lib/screens/dressing/
git commit -m 'feat(frontend): ecran Dressing avec grille categories et ajout vetement'
Write-Host "✓ Commit 14 terminé" -ForegroundColor Green
Write-Host ""

# Commit 15
Write-Host "[15/20] Écran Créations..." -ForegroundColor Yellow
git add frontend/lib/screens/creations/
git commit -m 'feat(frontend): ecran creation d outfits par zones corporelles'
Write-Host "✓ Commit 15 terminé" -ForegroundColor Green
Write-Host ""

# Commit 16
Write-Host "[16/20] Écran Outfits..." -ForegroundColor Yellow
git add frontend/lib/screens/outfits/
git commit -m 'feat(frontend): ecran Outfits (bibliotheque, swipe Tinder, suggestions IA)'
Write-Host "✓ Commit 16 terminé" -ForegroundColor Green
Write-Host ""

# Commit 17
Write-Host "[17/20] Écran Profil..." -ForegroundColor Yellow
git add frontend/lib/screens/profile/
git commit -m 'feat(frontend): ecran Profil avec stats, galerie et gestion compte'
Write-Host "✓ Commit 17 terminé" -ForegroundColor Green
Write-Host ""

# Commit 18
Write-Host "[18/20] Écran Inspiration..." -ForegroundColor Yellow
git add frontend/lib/screens/inspiration/
git commit -m 'feat(frontend): ecran Inspiration avec feed social et publication'
Write-Host "✓ Commit 18 terminé" -ForegroundColor Green
Write-Host ""

# Commit 19
Write-Host "[19/20] Navigation principale..." -ForegroundColor Yellow
git add frontend/lib/screens/home/
git commit -m 'feat(frontend): navigation principale avec bottom bar et ecran Home'
Write-Host "✓ Commit 19 terminé" -ForegroundColor Green
Write-Host ""

# Commit 20
Write-Host "[20/20] Configuration Android..." -ForegroundColor Yellow
git add frontend/android/ frontend/web/manifest.json README.md .gitignore COMMITS_PLAN.md
git commit -m 'chore: configuration Android et documentation projet'
Write-Host "✓ Commit 20 terminé" -ForegroundColor Green
Write-Host ""

Write-Host "=== Tous les commits terminés ! ===" -ForegroundColor Cyan
Write-Host "Utilise 'git log --oneline' pour voir l'historique" -ForegroundColor Gray
