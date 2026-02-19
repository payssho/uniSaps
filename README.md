# uniSaps - Outfit Manager

Application mobile de gestion de garde-robe avec Flutter (frontend) et FastAPI (backend).

## Architecture

```
uniSaps/
├── frontend/          # Application Flutter (Dart)
│   ├── lib/
│   │   ├── core/          # Theme, couleurs, constantes, routes
│   │   ├── models/        # Modeles de donnees (User, Garment, Outfit, Post)
│   │   ├── services/      # Services Firebase (Auth, Firestore, Storage) + API
│   │   ├── providers/     # State management Riverpod
│   │   ├── screens/       # Ecrans par feature
│   │   ├── widgets/       # Composants reutilisables
│   │   ├── main.dart      # Point d'entree
│   │   └── app.dart       # Configuration MaterialApp
│   ├── android/           # Configuration Android native
│   └── pubspec.yaml       # Dependances Flutter
│
├── backend/           # API FastAPI (Python)
│   ├── app/
│   │   ├── core/          # Config, Firebase init, securite
│   │   ├── api/routes/    # Endpoints REST
│   │   ├── models/        # Schemas Pydantic
│   │   └── services/      # IA, Storage
│   ├── requirements.txt   # Dependances Python
│   └── .env               # Variables d'environnement
│
└── _legacy/           # Ancien code Flet (archive)
```

## Stack technique

| Composant | Technologie |
|-----------|-------------|
| Frontend mobile | Flutter 3.24+ / Dart 3.5+ |
| State management | Riverpod |
| Routing | go_router |
| Backend API | FastAPI (Python 3.11+) |
| Auth | Firebase Authentication |
| Base de donnees | Cloud Firestore |
| Stockage images | Firebase Storage |
| IA suggestions | Python rule-based (backend) |
| Suppression background | rembg (IA) |

## Fonctionnalites

- **Dressing** : Photographier et cataloguer ses vetements par categorie
  - Suppression automatique du background des images via rembg (IA)
- **Creations** : Composer des outfits en assignant des vetements a chaque zone corporelle
- **Outfits** : Choisir son outfit du jour (bibliotheque, swipe Tinder, suggestions IA)
- **Profil** : Statistiques, galerie photo, streak quotidien
- **Inspiration** : Feed social, publier ses looks, likes

## Installation

### Pre-requis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.24
- [Python](https://www.python.org/) >= 3.11
- Projet [Firebase](https://console.firebase.google.com/) configure
- Android Studio (pour l'emulateur) ou un telephone Android

### 1. Flutter SDK

Telecharger et installer Flutter :
```bash
# Verifier l'installation
flutter doctor
```

### 2. Firebase

1. Creer un projet sur [Firebase Console](https://console.firebase.google.com/)
2. Activer **Authentication** (provider Email/Password)
3. Activer **Cloud Firestore** (mode test ou regles personnalisees)
4. Activer **Firebase Storage**
5. Ajouter une app Android :
   - Package name : `com.unisaps.app`
   - Telecharger `google-services.json`
   - Le placer dans `frontend/android/app/`
6. Generer la config Firebase pour Flutter :
   ```bash
   # Installer FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Depuis le dossier frontend/
   flutterfire configure --project=unisaps-3ad84
   ```

### 3. Backend

```bash
cd backend

# Creer un environnement virtuel
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # macOS/Linux

# Installer les dependances
pip install -r requirements.txt

# Copier le serviceAccountKey.json dans backend/
# (telecharger depuis Firebase Console > Project Settings > Service accounts)

# Configurer .env (deja pre-rempli)

# Lancer le serveur
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Le backend sera accessible sur `http://localhost:8000`.
Documentation API Swagger : `http://localhost:8000/docs`

**Note :** Lors de l'installation des dépendances, `rembg` téléchargera automatiquement un modèle d'IA pour la suppression du background. Ce processus peut prendre quelques minutes lors de la première utilisation.

### 4. Frontend Flutter

```bash
cd frontend

# Installer les dependances
flutter pub get

# Lancer sur un emulateur ou appareil connecte
flutter run

# Lancer en mode debug avec hot reload
flutter run --debug
```

### 5. Tester sur telephone Android

```bash
# Via USB (mode developpeur active sur le telephone)
flutter run

# OU generer un APK de debug
flutter build apk --debug
# L'APK sera dans frontend/build/app/outputs/flutter-apk/app-debug.apk
```

## Build APK (release)

```bash
cd frontend

# Build release
flutter build apk --release

# Le fichier est dans :
# build/app/outputs/flutter-apk/app-release.apk
```

Pour publier sur le Play Store :
```bash
# Build App Bundle (format requis par le Play Store)
flutter build appbundle --release
# build/app/outputs/bundle/release/app-release.aab
```

## Structure Firestore

```
users (collection)
  └── {uid} (document)
      ├── email, username, display_name, profile_photo_url
      ├── tutorial_seen, current_streak, best_streak
      ├── daily_outfit_id, daily_outfit_date, daily_photo_url
      ├── garments (sous-collection)
      │   └── {garment_id}
      │       ├── name, brand, color, category
      │       ├── image_url, created_at, times_worn
      └── outfits (sous-collection)
          └── {outfit_id}
              ├── name, garments (map), created_at
              ├── times_worn, last_worn, wear_history, photo_urls

posts (collection)
  └── {post_id}
      ├── user_id, username, user_photo_url
      ├── image_url, outfit_id, garment_refs
      ├── caption, likes, liked_by, created_at
```

## Structure Storage

```
garments/{user_id}/{filename}
outfits/{user_id}/{filename}
profiles/{user_id}/{filename}
posts/{user_id}/{filename}
```

## Endpoints API (Backend)

| Methode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/v1/users` | Creer un utilisateur |
| GET | `/api/v1/users/me` | Profil utilisateur |
| PATCH | `/api/v1/users/me` | Modifier le profil |
| POST | `/api/v1/users/me/daily-check` | Reset quotidien / streak |
| GET | `/api/v1/garments` | Lister les vetements |
| POST | `/api/v1/garments` | Ajouter un vetement |
| GET/PATCH/DELETE | `/api/v1/garments/{id}` | CRUD vetement |
| GET | `/api/v1/outfits` | Lister les outfits |
| POST | `/api/v1/outfits` | Creer un outfit |
| GET/PATCH/DELETE | `/api/v1/outfits/{id}` | CRUD outfit |
| GET | `/api/v1/posts` | Feed des posts |
| POST | `/api/v1/posts` | Publier un post |
| POST | `/api/v1/posts/{id}/toggle-like` | Like/Unlike |
| POST | `/api/v1/ai/suggest` | Suggestions IA |
| POST | `/api/v1/upload/image` | Upload d'image |

Tous les endpoints (sauf `/health`) necessitent un token Firebase dans le header `Authorization: Bearer <token>`.
