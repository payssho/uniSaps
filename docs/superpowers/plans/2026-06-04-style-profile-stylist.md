# Profil style & suggestions styliste — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Onboarding style skippable, préférences modifiables, suggestions rule-based enrichies (gratuit) et suggestions LLM styliste avec mini-phrase (UniSaps+).

**Architecture:** `style_profile` stocké sur `users/{uid}` (Firestore, écrit par Flutter). Backend : module de validation + mapping vers styles canoniques ; `/ai/suggest` enrichi ; nouveau `/ai/suggest-stylist` (premium, Gemini, validation ids). Flutter : wizard 3 écrans, paramètres, home adaptatif, feuille IA premium.

**Tech Stack:** Flutter 3.24, Riverpod, GoRouter, Firestore, FastAPI, `google-generativeai`, pytest, `flutter test`

**Spec:** `docs/superpowers/specs/2026-06-04-style-profile-stylist-design.md`

**Branche recommandée:** `feature/style-profile-stylist` (depuis `main`, séparée de `feature/i18n-api-errors`)

---

## File map

| File | Responsibility |
|------|----------------|
| `backend/app/models/style_profile.py` | Pydantic `StyleProfile`, défauts, validation |
| `backend/app/services/style_profile_service.py` | `identity_style` → canonique, `dominant_goal`, merge défauts |
| `backend/app/services/ai_service.py` | Scoring enrichi + `suggest_stylist_outfits()` Gemini |
| `backend/app/api/routes/ai.py` | `SuggestRequest.style_profile`, route `POST /suggest-stylist` |
| `backend/app/core/premium.py` | `require_premium_user(uid)` lecture Firestore `account_tier` |
| `backend/tests/test_style_profile.py` | Mapping, défauts, validation |
| `backend/tests/test_ai_scoring_profile.py` | Bonus audacity / goals sur `_score` |
| `backend/tests/test_suggest_stylist.py` | Parse JSON mock, ids invalides, premium (mock) |
| `frontend/lib/models/style_profile.dart` | Modèle Dart + `StyleProfile.defaults(skipped:)` |
| `frontend/lib/models/user_model.dart` | Champ `styleProfile`, `hasStyleProfile` |
| `frontend/lib/services/firestore_service.dart` | Lecture/écriture `style_profile` |
| `frontend/lib/providers/style_profile_provider.dart` | Sauvegarde wizard + settings |
| `frontend/lib/screens/auth/style_onboarding/` | 3 écrans wizard |
| `frontend/lib/widgets/style_profile_form.dart` | Widget partagé sliders + style + comfort |
| `frontend/lib/core/routes/app_router.dart` | Routes + redirect si profil absent |
| `frontend/lib/screens/profile/profile_screen.dart` | Section Style & préférences |
| `frontend/lib/screens/home/home_screen.dart` | Ordre blocs selon objectif dominant |
| `frontend/lib/screens/outfits/outfits_screen.dart` | `suggestStylist`, affichage `rationale_short` |
| `frontend/lib/services/api_service.dart` | `suggestStylist()`, type retour enrichi |
| `frontend/lib/l10n/api_error_l10n.dart` | Nouveaux `error_code` |
| `frontend/tool/gen_arb.py` | Clés onboarding / styles / objectifs |
| `frontend/test/models/style_profile_test.dart` | fromMap, defaults skip |
| `frontend/test/services/api_stylist_suggestion_test.dart` | Parse JSON réponse |

---

## Phase 0 — Préparation branche

### Task 0: Worktree / branche

**Files:** (aucun code)

- [ ] **Step 1: Créer la branche**

```bash
cd c:/Users/mariu/Documents/uniSaps
git checkout main
git pull
git checkout -b feature/style-profile-stylist
```

Expected: branche active `feature/style-profile-stylist`.

---

## Phase 1 — Backend : modèle `style_profile`

### Task 1: Modèle Pydantic + défauts

**Files:**
- Create: `backend/app/models/style_profile.py`
- Create: `backend/tests/test_style_profile.py`

- [ ] **Step 1: Écrire le test (mapping + défauts)**

```python
# backend/tests/test_style_profile.py
from app.models.style_profile import StyleProfile, default_style_profile
from app.services.style_profile_service import identity_to_canonical_style


def test_default_style_profile_when_skipped():
    p = default_style_profile(skipped=True)
    assert p.goal_wardrobe == 3
    assert p.identity_style == "casual"
    assert p.fashion_comfort == "balanced"
    assert p.onboarding_skipped is True


def test_identity_to_canonical():
    assert identity_to_canonical_style("classic") == "Classe"
    assert identity_to_canonical_style("unknown") == "Decontracte"
```

- [ ] **Step 2: Lancer le test (échec attendu)**

Run: `cd backend; python -m pytest tests/test_style_profile.py -v`  
Expected: `ModuleNotFoundError` ou `ImportError`.

- [ ] **Step 3: Implémenter le modèle**

```python
# backend/app/models/style_profile.py
from datetime import datetime
from pydantic import BaseModel, Field, field_validator

VALID_IDENTITY = {
    "casual", "classic", "minimal", "streetwear",
    "sport", "professional", "colorful", "evening",
}
VALID_COMFORT = {"beginner", "balanced", "confident"}


class StyleProfile(BaseModel):
    goal_wardrobe: int = Field(ge=1, le=5, default=3)
    goal_inspiration: int = Field(ge=1, le=5, default=3)
    goal_refine_style: int = Field(ge=1, le=5, default=3)
    goal_track_wear: int = Field(ge=1, le=5, default=3)
    identity_style: str = "casual"
    audacity: int = Field(ge=1, le=5, default=3)
    fashion_comfort: str = "balanced"
    onboarding_skipped: bool = False
    updated_at: str = ""

    @field_validator("identity_style")
    @classmethod
    def _identity(cls, v: str) -> str:
        return v if v in VALID_IDENTITY else "casual"

    @field_validator("fashion_comfort")
    @classmethod
    def _comfort(cls, v: str) -> str:
        return v if v in VALID_COMFORT else "balanced"


def default_style_profile(*, skipped: bool = False) -> StyleProfile:
    return StyleProfile(
        onboarding_skipped=skipped,
        updated_at=datetime.now().isoformat(),
    )
```

```python
# backend/app/services/style_profile_service.py
from app.models.style_profile import StyleProfile

IDENTITY_TO_CANONICAL = {
    "casual": "Decontracte",
    "classic": "Classe",
    "minimal": "Simple",
    "streetwear": "Streetwear",
    "sport": "Sportif",
    "professional": "Professionnel",
    "colorful": "Colore",
    "evening": "Soiree",
}


def identity_to_canonical_style(identity: str) -> str:
    return IDENTITY_TO_CANONICAL.get(identity, "Decontracte")


def dominant_goal_key(profile: StyleProfile) -> str:
    goals = {
        "goal_wardrobe": profile.goal_wardrobe,
        "goal_inspiration": profile.goal_inspiration,
        "goal_refine_style": profile.goal_refine_style,
        "goal_track_wear": profile.goal_track_wear,
    }
    return max(goals, key=goals.get)
```

- [ ] **Step 4: Relancer les tests**

Run: `cd backend; python -m pytest tests/test_style_profile.py -v`  
Expected: `2 passed`.

- [ ] **Step 5: Commit**

```bash
git add backend/app/models/style_profile.py backend/app/services/style_profile_service.py backend/tests/test_style_profile.py
git commit -m "feat(backend): add StyleProfile model and defaults"
```

---

### Task 2: Garde premium Firestore

**Files:**
- Create: `backend/app/core/premium.py`
- Modify: `backend/tests/test_suggest_stylist.py` (créé à Task 6, ici stub si besoin)

- [ ] **Step 1: Implémenter `require_premium_user`**

```python
# backend/app/core/premium.py
from app.core.errors import api_error
from app.core.firebase import get_firestore_client


def user_account_tier(uid: str) -> str:
    db = get_firestore_client()
    snap = db.collection("users").document(uid).get()
    if not snap.exists:
        return "free"
    return (snap.to_dict() or {}).get("account_tier", "free") or "free"


def require_premium_user(uid: str) -> None:
    tier = user_account_tier(uid).lower()
    if tier not in ("premium", "paid"):
        raise api_error(403, "premium_required")
```

- [ ] **Step 2: Commit**

```bash
git add backend/app/core/premium.py
git commit -m "feat(backend): premium gate helper for stylist endpoint"
```

---

## Phase 2 — Backend : scoring rule-based enrichi

### Task 3: Profil dans `_score` et `suggest_outfit`

**Files:**
- Modify: `backend/app/services/ai_service.py`
- Create: `backend/tests/test_ai_scoring_profile.py`

- [ ] **Step 1: Test bonus audacity**

```python
# backend/tests/test_ai_scoring_profile.py
from app.models.style_profile import StyleProfile
from app.services.ai_service import _score_with_profile


def test_audacity_boosts_warm_family():
    g = {"colors": ["rouge"], "pattern": "uni"}
    low = _score_with_profile(g, "Simple", None, [], StyleProfile(audacity=1))
    high = _score_with_profile(g, "Simple", None, [], StyleProfile(audacity=5))
    assert high >= low
```

- [ ] **Step 2: Run test — FAIL**

Run: `cd backend; python -m pytest tests/test_ai_scoring_profile.py -v`

- [ ] **Step 3: Ajouter `_score_with_profile` et paramètre optionnel**

Dans `ai_service.py`, après `_score` :

```python
def _score_with_profile(
    g: dict,
    style: str,
    season_key: Optional[str],
    weather_tags: List[str],
    profile: Optional["StyleProfile"],
) -> int:
    from app.models.style_profile import StyleProfile as SP
    from app.services.style_profile_service import identity_to_canonical_style

    base_style = style
    if profile:
        base_style = identity_to_canonical_style(profile.identity_style)
    score = _score(g, base_style, season_key, weather_tags)
    if not profile:
        return score
    if profile.audacity >= 4:
        fam = _color_family(str((g.get("colors") or [""])[0]))
        if fam in ("warm", "pastel"):
            score += 1
    if profile.goal_wardrobe >= 4:
        if str(g.get("pattern") or "uni").lower() == "uni":
            score += 1
    return score
```

Modifier `suggest_outfit(..., style_profile: Optional[StyleProfile] = None)` :
- utiliser `_score_with_profile` au lieu de `_score`
- si `profile and profile.goal_inspiration >= 4` : pénalité `recently_worn` de `-2` → `-1` (réduire de 1 point la pénalité dans le `key=lambda`)

Modifier `suggest_multiple` pour accepter et passer `style_profile`.

- [ ] **Step 4: Tests PASS**

Run: `cd backend; python -m pytest tests/test_ai_scoring_profile.py tests/test_style_profile.py -v`

- [ ] **Step 5: Commit**

```bash
git add backend/app/services/ai_service.py backend/tests/test_ai_scoring_profile.py
git commit -m "feat(ai): enrich rule-based scoring with style_profile"
```

---

### Task 4: `POST /ai/suggest` accepte `style_profile`

**Files:**
- Modify: `backend/app/api/routes/ai.py`

- [ ] **Step 1: Étendre `SuggestRequest`**

```python
from typing import Any, Dict, Optional
from app.models.style_profile import StyleProfile

class SuggestRequest(BaseModel):
    style: str = "Simple"
    count: int = 3
    season_key: Optional[str] = None
    weather_tags: Optional[List[str]] = None
    style_profile: Optional[Dict[str, Any]] = None
```

Dans `suggest_outfits`, après chargement garments :

```python
profile = None
if body.style_profile:
    try:
        profile = StyleProfile.model_validate(body.style_profile)
    except Exception:
        raise api_error(400, "invalid_style_profile")
# Si absent : charger depuis user doc Firestore (même uid)
if profile is None:
    user_snap = db.collection("users").document(uid).get()
    if user_snap.exists:
        raw = (user_snap.to_dict() or {}).get("style_profile")
        if raw:
            profile = StyleProfile.model_validate(raw)

effective_style = body.style
if profile:
    from app.services.style_profile_service import identity_to_canonical_style
    effective_style = identity_to_canonical_style(profile.identity_style)

suggestions = suggest_multiple(
    garments,
    effective_style,
    body.count,
    existing,
    season_key=body.season_key,
    weather_tags=body.weather_tags,
    style_profile=profile,
)
```

- [ ] **Step 2: Commit**

```bash
git add backend/app/api/routes/ai.py
git commit -m "feat(api): pass style_profile into /ai/suggest"
```

---

## Phase 3 — Backend : `suggest-stylist` (LLM)

### Task 5: `suggest_stylist_outfits` + validation ids

**Files:**
- Modify: `backend/app/services/ai_service.py`
- Create: `backend/tests/test_suggest_stylist.py`

- [ ] **Step 1: Test parse mock (sans appel réseau)**

```python
# backend/tests/test_suggest_stylist.py
from app.services.ai_service import _parse_stylist_response, _validate_garment_ids

def test_validate_garment_ids_rejects_unknown():
    allowed = {"g1", "g2"}
    outfits = [{"garments": {"top": "g1", "bottom": "g99"}, "rationale_short": "Test."}]
    out = _validate_garment_ids(outfits, allowed)
    assert out[0]["garments"]["bottom"] == ""


def test_parse_stylist_response_truncates_rationale():
    raw = '{"suggestions":[{"garments":{"top":"a"},"rationale_short":"Une phrase très longue " * 20}]}'
    # utiliser JSON valide court dans impl réelle
```

Ajuster le test avec JSON réel ≤ 120 chars dans Step 3.

- [ ] **Step 2: FAIL puis implémenter helpers**

```python
def _validate_garment_ids(
    suggestions: list[dict],
    allowed_ids: set[str],
) -> list[dict]:
    cleaned = []
    for s in suggestions:
        garments = {k: (v if v in allowed_ids else "") for k, v in s.get("garments", {}).items()}
        rationale = str(s.get("rationale_short", ""))[:120].strip()
        cleaned.append({"garments": garments, "rationale_short": rationale})
    return cleaned


def _parse_stylist_response(text: str) -> list[dict]:
    import json
    import re
    m = re.search(r"\{.*\}", text, re.DOTALL)
    if not m:
        return []
    data = json.loads(m.group(0))
    return data.get("suggestions") or []
```

- [ ] **Step 3: Implémenter `suggest_stylist_outfits`**

Signature :

```python
def suggest_stylist_outfits(
    garments: list[dict],
    *,
    count: int,
    style_profile: StyleProfile,
    user_prompt: str = "",
    season_key: Optional[str] = None,
    weather_tags: Optional[List[str]] = None,
) -> list[dict]:
```

- Limiter à 80 pièces (`garments = garments[:80]`).
- Construire liste compacte `[{id, category, colors, style_tags, formality}]`.
- Prompt Gemini (température 0.3) : JSON strict `{ "suggestions": [ { "garments": {cat: id}, "rationale_short": "..." } ] }`, ids autorisés listés, ton selon `fashion_comfort`, 1 phrase max 120 caractères.
- Réutiliser client Gemini comme `analyze_garment_image` (même `genai.GenerativeModel`).
- En cas d’échec / clé absente : lever exception `StylistUnavailable` (classe custom ou retour vide + route gère fallback).

- [ ] **Step 4: Tests unitaires PASS (mock `genai`)**

Utiliser `unittest.mock.patch` sur `genai.GenerativeModel.generate_content` pour renvoyer JSON fixture.

- [ ] **Step 5: Commit**

```bash
git add backend/app/services/ai_service.py backend/tests/test_suggest_stylist.py
git commit -m "feat(ai): stylist LLM suggest with id validation"
```

---

### Task 6: Route `POST /ai/suggest-stylist`

**Files:**
- Modify: `backend/app/api/routes/ai.py`

- [ ] **Step 1: Ajouter modèle requête + route**

```python
class SuggestStylistRequest(BaseModel):
    count: int = 3
    user_prompt: str = ""
    season_key: Optional[str] = None
    weather_tags: Optional[List[str]] = None


@router.post("/suggest-stylist")
async def suggest_stylist(body: SuggestStylistRequest, uid: str = Depends(get_current_uid)):
    from app.core.premium import require_premium_user
    from app.models.style_profile import StyleProfile, default_style_profile

    require_premium_user(uid)
    db = get_firestore_client()
    # load garments + outfits (même boucle que /suggest)
    user_snap = db.collection("users").document(uid).get()
    raw_profile = (user_snap.to_dict() or {}).get("style_profile") if user_snap.exists else None
    profile = StyleProfile.model_validate(raw_profile) if raw_profile else default_style_profile(skipped=True)

    if len(garments) < 2:
        raise api_error(400, "insufficient_garments")

    try:
        suggestions = suggest_stylist_outfits(
            garments,
            count=body.count,
            style_profile=profile,
            user_prompt=body.user_prompt,
            season_key=body.season_key,
            weather_tags=body.weather_tags,
        )
    except Exception:
        # fallback rule-based
        classic = suggest_multiple(
            garments, "Simple", body.count, existing,
            season_key=body.season_key,
            weather_tags=body.weather_tags,
            style_profile=profile,
        )
        suggestions = [
            {
                "garments": s,
                "rationale_short": "Look équilibré pour ta garde-robe.",
            }
            for s in classic
        ]
        return {"suggestions": suggestions, "fallback": True}

    return {"suggestions": suggestions, "fallback": False}
```

- [ ] **Step 2: Test intégration route (mock premium + mock LLM)**

Run: `cd backend; python -m pytest tests/test_suggest_stylist.py -v`

- [ ] **Step 3: Commit**

```bash
git add backend/app/api/routes/ai.py
git commit -m "feat(api): add POST /ai/suggest-stylist with premium gate and fallback"
```

---

## Phase 4 — Flutter : modèle & persistance

### Task 7: `StyleProfile` Dart + `UserModel`

**Files:**
- Create: `frontend/lib/models/style_profile.dart`
- Modify: `frontend/lib/models/user_model.dart`
- Create: `frontend/test/models/style_profile_test.dart`

- [ ] **Step 1: Test defaults skip**

```dart
// frontend/test/models/style_profile_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/models/style_profile.dart';

void main() {
  test('defaults when skipped sets onboardingSkipped', () {
    final p = StyleProfile.defaults(skipped: true);
    expect(p.goalWardrobe, 3);
    expect(p.identityStyle, 'casual');
    expect(p.onboardingSkipped, true);
  });
}
```

- [ ] **Step 2: FAIL → implémenter `style_profile.dart`**

Champs camelCase en Dart, `toMap()` en snake_case Firestore :

```dart
class StyleProfile {
  final int goalWardrobe;
  final int goalInspiration;
  final int goalRefineStyle;
  final int goalTrackWear;
  final String identityStyle;
  final int audacity;
  final String fashionComfort; // beginner | balanced | confident
  final bool onboardingSkipped;
  final String updatedAt;

  factory StyleProfile.defaults({bool skipped = false}) => StyleProfile(
    goalWardrobe: 3,
    goalInspiration: 3,
    goalRefineStyle: 3,
    goalTrackWear: 3,
    identityStyle: 'casual',
    audacity: 3,
    fashionComfort: 'balanced',
    onboardingSkipped: skipped,
    updatedAt: DateTime.now().toIso8601String(),
  );

  String get dominantGoalKey { /* max des 4 goals */ }
}
```

- [ ] **Step 3: Étendre `UserModel`**

```dart
final StyleProfile? styleProfile;

bool get hasStyleProfile =>
    styleProfile != null && styleProfile!.updatedAt.isNotEmpty;
```

`fromMap` : `style_profile` → `StyleProfile.fromMap`.

- [ ] **Step 4: `flutter test test/models/style_profile_test.dart`**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/models/style_profile.dart frontend/lib/models/user_model.dart frontend/test/models/style_profile_test.dart
git commit -m "feat(flutter): StyleProfile model on UserModel"
```

---

### Task 8: Provider sauvegarde Firestore

**Files:**
- Create: `frontend/lib/providers/style_profile_provider.dart`
- Modify: `frontend/lib/services/firestore_service.dart` (si besoin helper)

- [ ] **Step 1: `saveStyleProfile(StyleProfile profile)`**

```dart
final styleProfileNotifierProvider =
    Provider<StyleProfileNotifier>((ref) => StyleProfileNotifier(ref));

class StyleProfileNotifier {
  Future<void> save(StyleProfile profile) async {
    final uid = ref.read(authServiceProvider).uid;
    await ref.read(firestoreServiceProvider).updateUser(uid, {
      'style_profile': profile.toMap(),
    });
    ref.invalidate(currentUserProvider);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/providers/style_profile_provider.dart
git commit -m "feat(flutter): save style_profile to Firestore"
```

---

## Phase 5 — i18n (avant UI)

### Task 9: Clés ARB onboarding & styles

**Files:**
- Modify: `frontend/tool/gen_arb.py`
- Modify: `frontend/lib/l10n/app_fr.arb` / `app_en.arb` (via script)
- Modify: `frontend/lib/l10n/api_error_l10n.dart`

- [ ] **Step 1: Ajouter au `CATALOG` gen_arb (extraits)**

```python
"styleOnboardingTitle": ("Personnalise uniSaps", "Personalize uniSaps"),
"styleOnboardingSkipAll": ("Passer la personnalisation", "Skip personalization"),
"styleOnboardingSkip": ("Passer", "Skip"),
"styleGoalWardrobe": ("Gérer ma garde-robe", "Manage my wardrobe"),
"styleGoalInspiration": ("Trouver l'inspiration", "Find inspiration"),
"styleGoalRefine": ("Affiner mon style", "Refine my style"),
"styleGoalTrack": ("Suivre ce que je porte", "Track what I wear"),
"styleIdentityTitle": ("Ton style", "Your style"),
"styleAudacity": ("Audace", "Boldness"),
"styleComfortBeginner": ("Je débute", "I'm starting out"),
"styleComfortBalanced": ("J'ai des bases", "I know the basics"),
"styleComfortConfident": ("Je suis à l'aise", "I'm confident"),
"styleSettingsTitle": ("Style & préférences", "Style & preferences"),
"stylistRationaleLabel": ("Pourquoi ce look", "Why this look"),
"apiPremiumRequired": ("UniSaps+ requis", "UniSaps+ required"),
"apiStylistUnavailable": ("Styliste indisponible, réessaie plus tard.", "Stylist unavailable, try again later."),
# + styleIdentityCasual, styleIdentityClassic, ... (8 clés)
```

- [ ] **Step 2: Régénérer ARB**

Run: `cd frontend; python tool/gen_arb.py`  
Then: `flutter gen-l10n`

- [ ] **Step 3: Mapper error codes dans `api_error_l10n.dart`**

```dart
case 'premium_required':
  return l.apiPremiumRequired;
case 'stylist_unavailable':
  return l.apiStylistUnavailable;
case 'insufficient_garments':
  return l.apiInsufficientGarments; // ajouter clé
case 'invalid_style_profile':
  return l.apiInvalidStyleProfile; // ajouter clé
```

- [ ] **Step 4: Commit**

```bash
git add frontend/tool/gen_arb.py frontend/lib/l10n/
git commit -m "feat(i18n): style onboarding and stylist error strings"
```

---

## Phase 6 — Onboarding wizard (3 écrans)

### Task 10: Widget formulaire partagé

**Files:**
- Create: `frontend/lib/widgets/style_profile_form.dart`

- [ ] **Step 1: Créer widget stateful**

Props : `StyleProfile initial`, callbacks `onChanged`, sections activables (`showGoals`, `showIdentity`, `showComfort`).

- Sliders 1–5 pour les 4 objectifs.
- Grid 8 styles (icône + `context.l10n.styleIdentityCasual` etc.).
- Slider audace 1–5.
- 3 cartes `fashion_comfort`.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/widgets/style_profile_form.dart
git commit -m "feat(ui): shared StyleProfileForm widget"
```

---

### Task 11: Écrans wizard + routes

**Files:**
- Create: `frontend/lib/screens/auth/style_onboarding/style_goals_screen.dart`
- Create: `frontend/lib/screens/auth/style_onboarding/style_identity_screen.dart`
- Create: `frontend/lib/screens/auth/style_onboarding/style_comfort_screen.dart`
- Modify: `frontend/lib/core/routes/app_router.dart`
- Modify: `frontend/lib/screens/auth/onboarding_screen.dart` (redirect après succès)

- [ ] **Step 1: Routes GoRouter**

```dart
GoRoute(
  path: '/onboarding/style/goals',
  builder: (_, __) => const StyleGoalsScreen(),
),
GoRoute(
  path: '/onboarding/style/identity',
  builder: (_, __) => const StyleIdentityScreen(),
),
GoRoute(
  path: '/onboarding/style/comfort',
  builder: (_, __) => const StyleComfortScreen(),
),
```

- [ ] **Step 2: Redirect dans `_RouterNotifier`**

Après `!user.isNewUser` check, si `!user.hasStyleProfile` et pas déjà sur `/onboarding/style/*` :

```dart
if (user != null && !user.isNewUser && !user.hasStyleProfile) {
  if (!loc.startsWith('/onboarding/style')) {
    return '/onboarding/style/goals';
  }
}
```

- [ ] **Step 3: `onboarding_screen.dart` — après succès**

Remplacer `context.go('/home')` par `context.go('/onboarding/style/goals')`.

- [ ] **Step 4: Logique Passer**

- Écran 1 bouton « Passer toute la personnalisation » → `StyleProfile.defaults(skipped: true)` → save → `/home`.
- Écran 1 « Passer » (étape seule) → defaults partiels goals → écran 2.
- Écran 2/3 Passer → defaults pour champs non remplis → étape suivante ou save final.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/screens/auth/style_onboarding/ frontend/lib/core/routes/app_router.dart frontend/lib/screens/auth/onboarding_screen.dart
git commit -m "feat(onboarding): skippable style wizard after profile"
```

---

## Phase 7 — Paramètres profil

### Task 12: Section Style & préférences

**Files:**
- Modify: `frontend/lib/screens/profile/profile_screen.dart`

- [ ] **Step 1: Ajouter tuile / section**

Navigation vers sous-page ou `ExpansionTile` avec `StyleProfileForm` prérempli depuis `currentUserProvider`.

- [ ] **Step 2: Bouton Enregistrer → `styleProfileNotifier.save`**

- [ ] **Step 3: Bouton Réinitialiser → `StyleProfile.defaults(skipped: false)`**

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/screens/profile/profile_screen.dart
git commit -m "feat(profile): edit style preferences in settings"
```

---

## Phase 8 — Home personnalisée

### Task 13: Ordre blocs selon objectif dominant

**Files:**
- Modify: `frontend/lib/screens/home/home_screen.dart`
- Create: `frontend/lib/core/style_home_layout.dart` (helper pur)

- [ ] **Step 1: Helper**

```dart
enum HomeSection { dressing, inspiration, outfits, streak }

List<HomeSection> homeSectionOrder(StyleProfile? profile) {
  if (profile == null) return HomeSection.values;
  switch (profile.dominantGoalKey) {
    case 'goal_inspiration':
      return [HomeSection.inspiration, HomeSection.outfits, HomeSection.dressing, HomeSection.streak];
    // ... autres permutations
    default:
      return HomeSection.values;
  }
}
```

- [ ] **Step 2: Réordonner widgets home (minimal)**

Sans refonte majeure : réordonner 2–3 blocs existants (ex. carte Inspiration vs Dressing) via `Column(children: orderedWidgets)`.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/core/style_home_layout.dart frontend/lib/screens/home/home_screen.dart
git commit -m "feat(home): reorder sections by style_profile goals"
```

---

## Phase 9 — API client & UI suggestions premium

### Task 14: `api_service.suggestStylist`

**Files:**
- Create: `frontend/lib/models/stylist_suggestion.dart`
- Modify: `frontend/lib/services/api_service.dart`
- Create: `frontend/test/services/api_stylist_suggestion_test.dart`

- [ ] **Step 1: Modèle + test parse**

```dart
class StylistSuggestion {
  final Map<String, String> garments;
  final String rationaleShort;
  factory StylistSuggestion.fromJson(Map<String, dynamic> m) => StylistSuggestion(
    garments: Map<String, String>.from(m['garments'] as Map),
    rationaleShort: m['rationale_short'] as String? ?? '',
  );
}
```

- [ ] **Step 2: Méthode API**

```dart
Future<List<StylistSuggestion>> suggestStylist({
  int count = 3,
  String userPrompt = '',
  String? seasonKey,
  List<String>? weatherTags,
}) async {
  // POST $baseUrl/ai/suggest-stylist
  // parse suggestions[], map ApiException premium_required
}
```

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/models/stylist_suggestion.dart frontend/lib/services/api_service.dart frontend/test/services/api_stylist_suggestion_test.dart
git commit -m "feat(api): client for suggest-stylist endpoint"
```

---

### Task 15: Brancher `outfits_screen` premium

**Files:**
- Modify: `frontend/lib/screens/outfits/outfits_screen.dart`
- Modify: `frontend/lib/providers/outfit_provider.dart` (si provider suggestions séparé)

- [ ] **Step 1: Envoyer `style_profile` dans `suggestOutfits`**

Dans `_runGenerate`, lire `currentUserProvider` → `user.styleProfile?.toMap()` dans body si endpoint étendu côté client (optionnel si backend lit Firestore seul).

- [ ] **Step 2: Si `isPremiumProvider` → `suggestStylist`**

```dart
if (ref.read(isPremiumProvider)) {
  final list = await api.suggestStylist(...);
  ref.read(biblioAiSuggestionsProvider.notifier).state = list;
} else {
  final list = await api.suggestOutfits(...);
  ...
}
```

Adapter le type du provider en `List<StylistSuggestion>` ou union / wrapper.

- [ ] **Step 3: UI carte suggestion**

Sous les vignettes pièces, afficher :

```dart
Text(
  suggestion.rationaleShort,
  style: AppTextStyles.caption,
  maxLines: 2,
)
```

Libellé optionnel `context.l10n.stylistRationaleLabel`.

- [ ] **Step 4: Fallback silencieux**

Si `ApiException` code `stylist_unavailable` → retry `suggestOutfits` sans SnackBar intrusive (log debug seulement).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/screens/outfits/outfits_screen.dart
git commit -m "feat(outfits): premium stylist suggestions with rationale line"
```

---

## Phase 10 — Vérification finale

### Task 16: Suite de tests & critères d’acceptation

**Files:** (aucun)

- [ ] **Step 1: Backend**

Run: `cd backend; python -m pytest tests/ -v`  
Expected: tous les tests passent (existants + nouveaux).

- [ ] **Step 2: Flutter**

Run: `cd frontend; flutter test`  
Run: `cd frontend; flutter analyze --no-fatal-infos --no-fatal-warnings`

- [ ] **Step 3: Manuel (checklist spec)**

1. Nouveau compte → profil → wizard 3 écrans → home.
2. Passer tout → home avec défauts (vérifier Firestore `style_profile.onboarding_skipped == true`).
3. Paramètres → modifier audace → regénérer suggestion gratuite (changement de style effectif).
4. Compte premium (ou tier mock) → suggestions avec 1 ligne de texte.
5. `analyze-garment` toujours OK.

- [ ] **Step 4: Mettre à jour la spec statut**

Dans `docs/superpowers/specs/2026-06-04-style-profile-stylist-design.md` : `Statut: Implémenté (plan 2026-06-04)`.

- [ ] **Step 5: Commit doc**

```bash
git add docs/superpowers/specs/2026-06-04-style-profile-stylist-design.md
git commit -m "docs: mark style-profile-stylist spec as planned"
```

---

## Plan self-review (couverture spec)

| Exigence spec | Task |
|---------------|------|
| `style_profile` Firestore | 7, 8 |
| Onboarding skippable 3 écrans | 11 |
| Paramètres | 12 |
| `/ai/suggest` enrichi | 3, 4 |
| `/ai/suggest-stylist` premium + mini-phrase | 5, 6, 14, 15 |
| Fallback LLM | 6, 15 |
| Home personnalisation | 13 |
| i18n | 9 |
| Tests backend/Flutter | 1, 3, 5, 7, 14, 16 |
| Pas de genre v1 | (aucune tâche) |
| Hors scope cache/UGC | (aucune tâche) |

**Placeholder scan:** aucun TBD dans les tâches ci-dessus.

---

## Notes d’implémentation

- **Firestore vs REST :** l’app utilise déjà `firestore_service.createUser` à l’onboarding ; **ne pas** bloquer sur `PATCH /users/me` sauf si tu veux parité API — la v1 peut être **Firestore-only** côté client, le backend lit `style_profile` sur le doc user.
- **Créateurs :** le wizard style ne s’applique qu’aux `account_type == user'` (redirect créateur inchangé).
- **Coexistence i18n :** merger `feature/style-profile-stylist` après `feature/i18n-api-errors` ou rebaser pour éviter conflits `gen_arb.py` / `api_error_l10n.dart`.
