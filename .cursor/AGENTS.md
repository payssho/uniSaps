@# Agents Cursor — uniSaps

Trois agents spécialisés pour le développement de **uniSaps** (Outfit Manager). Contexte produit complet : [`presentation/documentation.md`](../presentation/documentation.md).

## Invocation dans le chat

Tape `@` dans le chat Cursor, puis choisis l’agent :

| Mention | Agent | Quand l’utiliser |
|---------|-------|------------------|
| `@unisaps-backend` | Backend métier | API FastAPI, Firestore rules, upload, créateur, auth JWT — **sans** IA |
| `@unisaps-ia` | IA produit | Gemini vision, scoring outfits, routes `/ai/*`, UniSaps+, intégration client IA |
| `@unisaps-frontend` | UI mobile | Écrans Flutter, thème, widgets, Riverpod, UX mode, responsive 320px |

Fichiers : [`.cursor/agents/unisaps-backend.md`](agents/unisaps-backend.md), [`unisaps-ia.md`](agents/unisaps-ia.md), [`unisaps-frontend.md`](agents/unisaps-frontend.md).

## Matrice de périmètres

| Zone | Backend | IA | Frontend |
|------|:-------:|:--:|:--------:|
| `backend/app/api/routes/` (hors `ai.py`) | ✓ | ✗ | ✗ |
| `backend/app/services/ai_service.py` | ✗ | ✓ | ✗ |
| `backend/app/api/routes/ai.py` | ✗ | ✓ | lecture |
| `backend/app/services/storage_service.py` | ✓ | ✗ | ✗ |
| `firestore.rules` | ✓ | ✗ | ✗ |
| `frontend/lib/` | ✗ | flux IA seulement | ✓ |
| CRUD Firestore côté client | conseil | ✗ | ✓ |

**Règle d’or** : le client Flutter lit/écrit surtout **Firestore directement** ; l’API sert surtout à **IA** et **upload**. Ne pas dupliquer la logique CRUD côté API sans besoin explicite.

## Comment choisir son agent

- **Endpoint REST, règles Firestore, déploiement Vercel** → `@unisaps-backend`
- **Analyse photo vêtement, suggestions, score, premium, Gemini** → `@unisaps-ia`
- **Écran, widget, navigation, design, streak, feed Inspiration** → `@unisaps-frontend`
- **Tâche mixte** : commencer par l’agent dominant, puis enchaîner avec un autre `@` si besoin

## Exemples de prompts

- `@unisaps-backend` Ajoute la validation JWT sur `POST /creator/activate-subscription` et aligne la réponse avec le schéma Firestore `account_type`.
- `@unisaps-ia` Enrichis `_score()` pour pondérer `style_tags` et `material` issus de Gemini ; garde le moteur rule-based, pas de LLM par suggestion.
- `@unisaps-frontend` Refonds l’onglet Swipe des outfits : cartes pleine largeur, pas d’overflow à 320px, CTA outfit du jour visible.

## Stack (rappel)

Flutter 3.24+ · Riverpod · go_router · Firestore · FastAPI `/api/v1` · Vercel · Gemini 2.5 Flash (vision) · suggestions rule-based
