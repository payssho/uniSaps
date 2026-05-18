# uniSaps - Outfit Manager

Application mobile de gestion de garde-robe avec Flutter (frontend) et FastAPI (backend).

## Architecture

```
uniSaps/
├── frontend/          # Application Flutter (Dart)
│   ├── lib/
│   │   ├── core/          # Theme, routes, constantes (couleurs, météo, catégories)
│   │   ├── models/        # User, Garment, Outfit, Post, météo…
│   │   ├── services/      # Firebase, API Vercel, météo Open-Meteo
│   │   ├── providers/     # State management Riverpod
│   │   ├── screens/       # Auth, Dressing, Outfits, Inspo, Profil, météo
│   │   ├── widgets/       # Composants réutilisables
│   │   ├── main.dart
│   │   └── app.dart
│   ├── test/              # Tests unitaires (models, providers, services)
│   └── pubspec.yaml
│
├── backend/           # API FastAPI (Python), déployée sur Vercel
│   ├── app/api/routes/
│   └── LANCE_BACKEND.md   # Guide de démarrage local
│
└── _legacy/           # Ancien code Flet (archive)
```

Voir aussi [frontend/README.md](frontend/README.md) pour le détail du client Flutter.

## Stack technique

| Composant | Technologie |
|-----------|-------------|
| Frontend mobile | Flutter 3.24+ / Dart 3.5+ |
| State management | Riverpod |
| Routing | go_router |
| Backend API | FastAPI (Python 3.11+), hébergement Vercel |
| Auth | Firebase Authentication (email / mot de passe) |
| Base de données | Cloud Firestore |
| Stockage images | Firebase Storage |
| Météo | Open-Meteo + géolocalisation (`geolocator`) côté client |
| IA | Suggestions d’outfits et analyse de vêtements (backend) |
| Suppression background | rembg (upload API, surtout en local) |

## Fonctionnalités

L’app est organisée en **4 onglets** (avec déverrouillage progressif) :

| Onglet | Description |
|--------|-------------|
| **Dressing** | Catalogue de vêtements par catégorie, photos multiples, fiche détail, ajout avec analyse IA optionnelle |
| **Outfits** | Outfit du jour : mode bibliothèque ou swipe ; tri selon saison et météo ; photo du jour ; streak |
| **Inspiration** | Feed **Amis** / **Explorer**, likes, publication (1 post / jour), profils et demandes d’amis |
| **Profil** | Stats, galerie, streak, amis, paramètres, compte **UniSaps+** (premium) |

### Dressing

- Plusieurs photos par vêtement (`image_urls`)
- Couleurs multiples, marques (JSON embarqué), métadonnées IA (style, formalité, saison…)
- Upload via l’API backend avec suppression de fond optionnelle (`rembg`)

### Outfits

- Composition par zones corporelles (tête, haut, veste, bas, chaussures, accessoire)
- Tags **saison** et **météo** sur chaque outfit pour le tri du jour
- **Météo du jour** : prévisions Open-Meteo, fiche détail horaire ([`weather_detail_sheet`](frontend/lib/screens/weather/weather_detail_sheet.dart))
- **UniSaps+** : suggestions IA d’outfits dans la bibliothèque (`POST /api/v1/ai/suggest`)

### Inspiration

- Publication liée à l’outfit du jour (photo du jour ou photo de référence)
- Badge auteur premium sur les posts (`author_is_premium`)

### Compte et premium

- Champ Firestore `account_tier` : `free` ou `premium`
- Fonctionnalités premium : suggestions IA outfits, anneau avatar, etc.

### Déverrouillage des onglets

- **Outfits** : au moins 1 vêtement dans le dressing
- **Inspiration** : au moins 1 outfit créé

## Météo

- Service client : [`frontend/lib/services/weather_service.dart`](frontend/lib/services/weather_service.dart)
- Source : [Open-Meteo](https://open-meteo.com/) (sans clé API)
- Permission de localisation ; si refusée, fallback **Paris**
- Contexte de tri des outfits : [`today_outfit_context.dart`](frontend/lib/models/today_outfit_context.dart) + [`weather_catalog.dart`](frontend/lib/core/constants/weather_catalog.dart)

## Installation

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.24
- [Python](https://www.python.org/) >= 3.11
- Projet [Firebase](https://console.firebase.google.com/) configuré
- Android Studio ou un téléphone Android

### 1. Flutter SDK

```bash
flutter doctor
```

### 2. Firebase

1. Créer un projet sur [Firebase Console](https://console.firebase.google.com/)
2. Activer **Authentication** (Email/Password)
3. Activer **Cloud Firestore** et **Firebase Storage**
4. App Android : package `com.unisaps.app`, placer `google-services.json` dans `frontend/android/app/`
5. Config FlutterFire :

```bash
dart pub global activate flutterfire_cli
cd frontend
flutterfire configure --project=unisaps-3ad84
```

### 3. Backend

Guide détaillé : [backend/LANCE_BACKEND.md](backend/LANCE_BACKEND.md).

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # macOS/Linux
pip install -r requirements.txt
# Placer serviceAccountKey.json dans backend/
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API locale : `http://localhost:8000`
- Swagger : `http://localhost:8000/docs`
- Production (app mobile) : `https://unisaps.vercel.app/api/v1`

**Note :** `rembg` télécharge un modèle IA au premier usage (plusieurs minutes possible).

### 4. Frontend Flutter

```bash
cd frontend
flutter pub get
flutter run
```

### 5. Téléphone Android

```bash
cd frontend
flutter run
# ou
flutter build apk --debug
```

## Tests et qualité

Les tests unitaires tournent dans CI sur chaque push / PR ([`.github/workflows/flutter_tests.yml`](.github/workflows/flutter_tests.yml)).

```bash
cd frontend
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

Structure des tests :

- `test/models/` - sérialisation des modèles
- `test/providers/` - notifiers Riverpod (fakes Firestore / Storage / API)
- `test/services/` - services métier (marques, couleurs)
- `test/helpers/fakes.dart` - doubles de test partagés

## Build APK (release)

```bash
cd frontend
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk

flutter build appbundle --release
# build/app/outputs/bundle/release/app-release.aab  (Play Store)
```

## Structure Firestore

```
users/{uid}
  ├── email, username, display_name, profile_photo_url
  ├── tutorial_seen (dressing, outfits, inspiration, …)
  ├── current_streak, best_streak
  ├── daily_outfit_id, daily_outfit_date, daily_photo_url
  ├── account_tier          # "free" | "premium"
  ├── friends[]             # uids des amis
  ├── is_private
  ├── garments/{garment_id}
  │     ├── name, brand, colors[], category
  │     ├── image_urls[], created_at, times_worn
  │     └── style_tags, formality, season, pattern, material  (IA, optionnel)
  └── outfits/{outfit_id}
        ├── name, garments{headwear, top, outerwear, bottom, shoes, accessory}
        ├── seasons[], weather_tags[]
        ├── times_worn, last_worn, wear_history[], photo_urls[]
        └── reference_photo_url

posts/{post_id}             # collection racine
  ├── user_id, username, user_photo_url
  ├── image_url, outfit_id, garment_refs[]
  ├── caption, likes, liked_by[], created_at
  └── author_is_premium

friend_requests/{id}        # demandes d’amis (statut pending/accepted/…)
```

## Structure Storage

```
garments/{user_id}/{filename}
outfits/{user_id}/{filename}
profiles/{user_id}/{filename}
posts/{user_id}/{filename}
```

## Endpoints API (Backend)

Tous les endpoints (sauf `/health`) exigent `Authorization: Bearer <Firebase ID token>`.

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/v1/users` | Créer un utilisateur |
| GET | `/api/v1/users/me` | Profil utilisateur |
| PATCH | `/api/v1/users/me` | Modifier le profil |
| POST | `/api/v1/users/me/daily-check` | Reset quotidien / streak |
| GET | `/api/v1/garments` | Lister les vêtements |
| POST | `/api/v1/garments` | Ajouter un vêtement |
| GET/PATCH/DELETE | `/api/v1/garments/{id}` | CRUD vêtement |
| GET | `/api/v1/outfits` | Lister les outfits |
| POST | `/api/v1/outfits` | Créer un outfit |
| GET/PATCH/DELETE | `/api/v1/outfits/{id}` | CRUD outfit |
| GET | `/api/v1/posts` | Feed des posts |
| GET | `/api/v1/posts/mine` | Posts de l’utilisateur courant |
| POST | `/api/v1/posts` | Publier un post |
| POST | `/api/v1/posts/{id}/toggle-like` | Like / unlike |
| DELETE | `/api/v1/posts/{id}` | Supprimer un post |
| POST | `/api/v1/friends/request` | Envoyer une demande d’ami |
| POST | `/api/v1/friends/request/{id}/accept` | Accepter |
| POST | `/api/v1/friends/request/{id}/reject` | Refuser |
| GET | `/api/v1/friends/requests/received` | Demandes reçues |
| GET | `/api/v1/friends/requests/sent` | Demandes envoyées |
| GET | `/api/v1/friends/search` | Recherche d’utilisateurs |
| DELETE | `/api/v1/friends/{friend_uid}` | Retirer un ami |
| POST | `/api/v1/ai/suggest` | Suggestions d’outfits (IA) |
| POST | `/api/v1/ai/analyze-garment` | Analyse d’image vêtement (IA) |
| POST | `/api/v1/upload/image` | Upload image (+ option `remove_bg`) |
| GET | `/api/v1/ai/health` | Santé du service IA |

## Branches en cours

- **`feat--android-home-widgets`** : widgets d’écran d’accueil Android (outfit du jour, choix rapide, inspi) - non mergé sur `main` à ce jour.
