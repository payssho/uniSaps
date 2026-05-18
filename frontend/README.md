# uniSaps - client Flutter

Application mobile **uniSaps** (gestion de garde-robe, outfit du jour, feed inspiration).

Documentation projet (installation Firebase, backend, Firestore) : [README racine](../README.md).

## Prérequis

- Flutter SDK >= 3.24, Dart >= 3.5
- `google-services.json` dans `android/app/`
- Backend API accessible (local ou Vercel) pour upload / IA

## Commandes

```bash
# Depuis ce dossier (frontend/)
flutter pub get
flutter run
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

Build release Android : voir [README racine - Build APK](../README.md#build-apk-release).

## Structure `lib/`

| Dossier | Rôle |
|---------|------|
| `core/` | Thème, `go_router`, couleurs, catégories vêtements, catalogue météo |
| `models/` | `UserModel`, `GarmentModel`, `OutfitModel`, `PostModel`, météo… |
| `services/` | Auth, Firestore, Storage, API HTTP, météo, marques, couleurs |
| `providers/` | Riverpod : auth, garments, outfits, posts, amitié, météo |
| `screens/` | `auth/`, `home/`, `dressing/`, `outfits/`, `inspiration/`, `profile/`, `weather/`, `creations/` |
| `widgets/` | Cartes, sélecteurs, sheets, composants premium |

Point d’entrée : `main.dart` → `app.dart` (`MaterialApp.router` + `ProviderScope`).

## Navigation

- Routes : `lib/core/routes/app_router.dart` (`/login`, `/signup`, `/onboarding`, `/home`)
- Shell principal : `HomeScreen` - 4 onglets (Dressing, Outfits, Inspo, Profil)

## Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=unisaps-3ad84
```

Package Android : `com.unisaps.app`.

## API backend

- **Web / debug desktop** : souvent `http://localhost:8000/api/v1`
- **Mobile** : `https://unisaps.vercel.app/api/v1`

Configurée dans `lib/providers/garment_provider.dart` (`apiServiceProvider`).

## Tests unitaires

```
test/
├── helpers/fakes.dart      # FakeFirestoreService, FakeStorageService, FakeApiService…
├── models/
├── providers/              # auth, garment, outfit, post, friendship
└── services/
```

Les tests de widgets UI complets ne sont pas couverts (`test/widget_test.dart` = placeholder).

Exécution :

```bash
flutter test
```

CI : workflow `Tests Flutter` à la racine du dépôt (`.github/workflows/flutter_tests.yml`).

## Assets

- `assets/data/brand.json` - liste de marques
- `assets/images/unisaps_logo.png` - logo

## Version

Synchronisée avec `pubspec.yaml` (`version: x.y.z+build`) et `android/app/build.gradle` (`versionCode` / `versionName` via Flutter).
