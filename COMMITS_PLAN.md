# Plan de commits progressifs - uniSaps Migration

## Commit 1 : Setup backend FastAPI
**Fichiers :**
- `backend/requirements.txt`
- `backend/.env.example`
- `backend/.gitignore`
- `backend/app/__init__.py`
- `backend/app/core/__init__.py`
- `backend/app/core/config.py`
- `backend/app/core/firebase.py`
- `backend/app/core/security.py`
- `backend/app/main.py`

**Message :**
```
feat(backend): setup FastAPI avec configuration Firebase et sécurité
```

---

## Commit 2 : Modèles de données backend
**Fichiers :**
- `backend/app/models/__init__.py`
- `backend/app/models/user.py`
- `backend/app/models/garment.py`
- `backend/app/models/outfit.py`
- `backend/app/models/post.py`

**Message :**
```
feat(backend): ajout des modèles Pydantic (User, Garment, Outfit, Post)
```

---

## Commit 3 : Services backend (Storage + AI)
**Fichiers :**
- `backend/app/services/__init__.py`
- `backend/app/services/storage_service.py`
- `backend/app/services/ai_service.py`

**Message :**
```
feat(backend): services de stockage images et suggestions IA
```

---

## Commit 4 : Endpoints Users
**Fichiers :**
- `backend/app/api/__init__.py`
- `backend/app/api/routes/__init__.py`
- `backend/app/api/routes/users.py`

**Message :**
```
feat(backend): endpoints CRUD utilisateurs et gestion streak quotidien
```

---

## Commit 5 : Endpoints Garments
**Fichiers :**
- `backend/app/api/routes/garments.py`

**Message :**
```
feat(backend): endpoints CRUD vêtements par utilisateur
```

---

## Commit 6 : Endpoints Outfits
**Fichiers :**
- `backend/app/api/routes/outfits.py`

**Message :**
```
feat(backend): endpoints CRUD outfits et historique de port
```

---

## Commit 7 : Endpoints Posts + Upload
**Fichiers :**
- `backend/app/api/routes/posts.py`
- `backend/app/api/routes/upload.py`
- `backend/app/api/routes/ai.py`

**Message :**
```
feat(backend): endpoints posts sociaux, upload images et suggestions IA
```

---

## Commit 8 : Setup frontend Flutter (structure + theme)
**Fichiers :**
- `frontend/pubspec.yaml`
- `frontend/.env`
- `frontend/.gitignore`
- `frontend/analysis_options.yaml`
- `frontend/lib/core/constants/app_colors.dart`
- `frontend/lib/core/constants/app_text_styles.dart`
- `frontend/lib/core/constants/categories.dart`
- `frontend/lib/core/theme/app_theme.dart`

**Message :**
```
feat(frontend): setup Flutter avec theme Material 3 et constantes
```

---

## Commit 9 : Modèles de données frontend
**Fichiers :**
- `frontend/lib/models/user_model.dart`
- `frontend/lib/models/garment_model.dart`
- `frontend/lib/models/outfit_model.dart`
- `frontend/lib/models/post_model.dart`

**Message :**
```
feat(frontend): modèles de données Dart (User, Garment, Outfit, Post)
```

---

## Commit 10 : Services Firebase frontend
**Fichiers :**
- `frontend/lib/services/auth_service.dart`
- `frontend/lib/services/firestore_service.dart`
- `frontend/lib/services/storage_service.dart`
- `frontend/lib/services/api_service.dart`
- `frontend/lib/firebase_options.dart`
- `frontend/lib/main.dart`
- `frontend/lib/app.dart`
- `frontend/web/index.html`

**Message :**
```
feat(frontend): services Firebase (Auth, Firestore, Storage) et configuration
```

---

## Commit 11 : Providers Riverpod
**Fichiers :**
- `frontend/lib/providers/auth_provider.dart`
- `frontend/lib/providers/garment_provider.dart`
- `frontend/lib/providers/outfit_provider.dart`
- `frontend/lib/providers/post_provider.dart`

**Message :**
```
feat(frontend): state management Riverpod pour auth, garments, outfits, posts
```

---

## Commit 12 : Écrans d'authentification
**Fichiers :**
- `frontend/lib/core/routes/app_router.dart`
- `frontend/lib/screens/auth/login_screen.dart`
- `frontend/lib/screens/auth/signup_screen.dart`
- `frontend/lib/screens/auth/onboarding_screen.dart`

**Message :**
```
feat(frontend): écrans authentification (login, signup, onboarding)
```

---

## Commit 13 : Widgets réutilisables
**Fichiers :**
- `frontend/lib/widgets/platform_image.dart`
- `frontend/lib/widgets/garment_card.dart`
- `frontend/lib/widgets/outfit_card.dart`
- `frontend/lib/widgets/post_card.dart`
- `frontend/lib/widgets/category_chip.dart`
- `frontend/lib/widgets/stat_card.dart`

**Message :**
```
feat(frontend): widgets réutilisables (cards, chips, images compatibles web)
```

---

## Commit 14 : Écran Dressing
**Fichiers :**
- `frontend/lib/screens/dressing/dressing_screen.dart`
- `frontend/lib/screens/dressing/add_garment_screen.dart`

**Message :**
```
feat(frontend): écran Dressing avec grille catégories et ajout vêtement
```

---

## Commit 15 : Écran Créations
**Fichiers :**
- `frontend/lib/screens/creations/creation_screen.dart`

**Message :**
```
feat(frontend): écran création d'outfits par zones corporelles
```

---

## Commit 16 : Écran Outfits
**Fichiers :**
- `frontend/lib/screens/outfits/outfits_screen.dart`

**Message :**
```
feat(frontend): écran Outfits (bibliothèque, swipe Tinder, suggestions IA)
```

---

## Commit 17 : Écran Profil
**Fichiers :**
- `frontend/lib/screens/profile/profile_screen.dart`

**Message :**
```
feat(frontend): écran Profil avec stats, galerie et gestion compte
```

---

## Commit 18 : Écran Inspiration
**Fichiers :**
- `frontend/lib/screens/inspiration/inspiration_screen.dart`

**Message :**
```
feat(frontend): écran Inspiration avec feed social et publication
```

---

## Commit 19 : Navigation principale et Home
**Fichiers :**
- `frontend/lib/screens/home/home_screen.dart`

**Message :**
```
feat(frontend): navigation principale avec bottom bar et écran Home
```

---

## Commit 20 : Configuration Android et Firebase
**Fichiers :**
- `frontend/android/app/build.gradle`
- `frontend/android/build.gradle`
- `frontend/android/settings.gradle`
- `frontend/android/gradle.properties`
- `frontend/android/app/src/main/AndroidManifest.xml`
- `frontend/web/manifest.json`
- `README.md`

**Message :**
```
chore: configuration Android et documentation projet
```

---

## Ordre d'exécution recommandé :

```bash
# 1. Backend setup
git add backend/requirements.txt backend/.env.example backend/.gitignore backend/app/core/ backend/app/main.py backend/app/__init__.py
git commit -m "feat(backend): setup FastAPI avec configuration Firebase et sécurité"

# 2. Backend models
git add backend/app/models/
git commit -m "feat(backend): ajout des modèles Pydantic (User, Garment, Outfit, Post)"

# 3. Backend services
git add backend/app/services/
git commit -m "feat(backend): services de stockage images et suggestions IA"

# 4. Backend endpoints Users
git add backend/app/api/__init__.py backend/app/api/routes/__init__.py backend/app/api/routes/users.py
git commit -m "feat(backend): endpoints CRUD utilisateurs et gestion streak quotidien"

# 5. Backend endpoints Garments
git add backend/app/api/routes/garments.py
git commit -m "feat(backend): endpoints CRUD vêtements par utilisateur"

# 6. Backend endpoints Outfits
git add backend/app/api/routes/outfits.py
git commit -m "feat(backend): endpoints CRUD outfits et historique de port"

# 7. Backend endpoints Posts + Upload + AI
git add backend/app/api/routes/posts.py backend/app/api/routes/upload.py backend/app/api/routes/ai.py
git commit -m "feat(backend): endpoints posts sociaux, upload images et suggestions IA"

# 8. Frontend setup
git add frontend/pubspec.yaml frontend/.env frontend/.gitignore frontend/analysis_options.yaml frontend/lib/core/
git commit -m "feat(frontend): setup Flutter avec theme Material 3 et constantes"

# 9. Frontend models
git add frontend/lib/models/
git commit -m "feat(frontend): modèles de données Dart (User, Garment, Outfit, Post)"

# 10. Frontend services
git add frontend/lib/services/ frontend/lib/firebase_options.dart frontend/lib/main.dart frontend/lib/app.dart frontend/web/index.html
git commit -m "feat(frontend): services Firebase (Auth, Firestore, Storage) et configuration"

# 11. Frontend providers
git add frontend/lib/providers/
git commit -m "feat(frontend): state management Riverpod pour auth, garments, outfits, posts"

# 12. Frontend auth screens
git add frontend/lib/core/routes/ frontend/lib/screens/auth/
git commit -m "feat(frontend): écrans authentification (login, signup, onboarding)"

# 13. Frontend widgets
git add frontend/lib/widgets/
git commit -m "feat(frontend): widgets réutilisables (cards, chips, images compatibles web)"

# 14. Frontend Dressing
git add frontend/lib/screens/dressing/
git commit -m "feat(frontend): écran Dressing avec grille catégories et ajout vêtement"

# 15. Frontend Créations
git add frontend/lib/screens/creations/
git commit -m "feat(frontend): écran création d'outfits par zones corporelles"

# 16. Frontend Outfits
git add frontend/lib/screens/outfits/
git commit -m "feat(frontend): écran Outfits (bibliothèque, swipe Tinder, suggestions IA)"

# 17. Frontend Profil
git add frontend/lib/screens/profile/
git commit -m "feat(frontend): écran Profil avec stats, galerie et gestion compte"

# 18. Frontend Inspiration
git add frontend/lib/screens/inspiration/
git commit -m "feat(frontend): écran Inspiration avec feed social et publication"

# 19. Frontend Home
git add frontend/lib/screens/home/
git commit -m "feat(frontend): navigation principale avec bottom bar et écran Home"

# 20. Configuration finale
git add frontend/android/ frontend/web/manifest.json README.md .gitignore
git commit -m "chore: configuration Android et documentation projet"
```
