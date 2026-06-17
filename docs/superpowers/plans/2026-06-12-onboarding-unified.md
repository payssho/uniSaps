# Onboarding unifié — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Étendre le wizard style Composer (3 écrans) en parcours 5 écrans Fable, avec `style_profile` enrichi, archétypes, personnalisation adaptative par écran, puis (Phase 3) styliste double-LLM + quota freemium.

**Architecture:** Un seul objet Firestore `style_profile` (pas `onboarding_profile`). Logique pure Dart testable pour archétype et `PersonalizationConfig`. Sauvegarde Firestore unique en fin de wizard (écran 5). CTAs conditionnels insérés dans les écrans existants sans refonte layout.

**Tech Stack:** Flutter 3 / Riverpod / go_router / Firestore · FastAPI / Pydantic / pytest · Gemini via `ai_service.py` · i18n ARB + `gen_arb.py`

**Branche:** `feature/onboarding-unified`

**Spec:** `docs/superpowers/specs/2026-06-12-onboarding-unified-design.md`

---

## File map (créations / modifications)

| Fichier | Responsabilité |
|---------|----------------|
| `frontend/lib/core/style_profile_archetype.dart` | `computeArchetype(StyleProfile)` pur Dart |
| `frontend/lib/core/personalization_config.dart` | Flags UI dérivés de `StyleProfile` |
| `frontend/lib/providers/personalization_provider.dart` | Riverpod → `PersonalizationConfig` |
| `frontend/lib/models/style_profile.dart` | +4 champs, `fromMap`/`toMap`/`copyWith` |
| `frontend/lib/screens/auth/style_onboarding/style_extra_screen.dart` | Wizard étape 4 (styles préférés + fréquence) |
| `frontend/lib/screens/auth/style_onboarding/style_social_screen.dart` | Wizard étape 5 (intention sociale + save) |
| `frontend/lib/screens/auth/style_onboarding/style_*_screen.dart` (×3) | Progress 1–3/5 ; comfort → navigue vers étape 4 sans save |
| `frontend/lib/screens/profile/style_preferences_screen.dart` | Édition paramètres — inclure nouveaux champs |
| `frontend/lib/widgets/style_profile_form.dart` | Sections optionnelles preferred_styles + frequency |
| `frontend/lib/providers/style_profile_provider.dart` | `saveWithSocialIntent()` → profile + `is_private` |
| `backend/app/models/style_profile.py` | Champs + validateurs miroir |
| `backend/app/services/ai_service.py` | Scoring `preferred_styles`, `archetype`, `usage_frequency` |

> **Attention nommage :** `profile/style_preferences_screen.dart` = Paramètres (existant). L’étape 4 wizard = `style_onboarding/style_extra_screen.dart` (nouveau).

---

## Phase 2a — Modèle, archétype, wizard 5 écrans

### Task 1: Calcul d'archétype (Dart pur)

**Files:**
- Create: `frontend/lib/core/style_profile_archetype.dart`
- Test: `frontend/test/core/style_profile_archetype_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/core/style_profile_archetype.dart';
import 'package:unisaps/models/style_profile.dart';

void main() {
  StyleProfile goals({
    int wardrobe = 3,
    int inspiration = 3,
    int refine = 3,
    int track = 3,
  }) =>
      StyleProfile(
        goalWardrobe: wardrobe,
        goalInspiration: inspiration,
        goalRefineStyle: refine,
        goalTrackWear: track,
      );

  test('wardrobe dominant → gestionnaire', () {
    expect(computeArchetype(goals(wardrobe: 5)), 'gestionnaire');
  });

  test('track dominant → gestionnaire', () {
    expect(computeArchetype(goals(track: 5)), 'gestionnaire');
  });

  test('inspiration dominant → explorateur', () {
    expect(computeArchetype(goals(inspiration: 5)), 'explorateur');
  });

  test('refine dominant → apprenti_style', () {
    expect(computeArchetype(goals(refine: 5)), 'apprenti_style');
  });

  test('tie-break refine > inspiration > track > wardrobe', () {
    expect(
      computeArchetype(goals(wardrobe: 5, inspiration: 5, refine: 5, track: 5)),
      'apprenti_style',
    );
    expect(
      computeArchetype(goals(wardrobe: 5, inspiration: 5, track: 5)),
      'explorateur',
    );
  });

  test('skipped profile → gestionnaire', () {
    expect(
      computeArchetype(StyleProfile.defaults(skipped: true)),
      'gestionnaire',
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/core/style_profile_archetype_test.dart`
Expected: FAIL — `computeArchetype` not defined

- [ ] **Step 3: Write minimal implementation**

```dart
import '../models/style_profile.dart';

const _priority = [
  'goal_refine_style',
  'goal_inspiration',
  'goal_track_wear',
  'goal_wardrobe',
];

String computeArchetype(StyleProfile profile) {
  if (profile.onboardingSkipped) return 'gestionnaire';

  final goals = <String, int>{
    'goal_wardrobe': profile.goalWardrobe,
    'goal_inspiration': profile.goalInspiration,
    'goal_refine_style': profile.goalRefineStyle,
    'goal_track_wear': profile.goalTrackWear,
  };
  final maxVal = goals.values.reduce((a, b) => a > b ? a : b);
  final dominant = _priority.firstWhere((k) => goals[k] == maxVal);

  switch (dominant) {
    case 'goal_inspiration':
      return 'explorateur';
    case 'goal_refine_style':
      return 'apprenti_style';
    case 'goal_wardrobe':
    case 'goal_track_wear':
    default:
      return 'gestionnaire';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/core/style_profile_archetype_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/core/style_profile_archetype.dart frontend/test/core/style_profile_archetype_test.dart
git commit -m "feat(onboarding): add archetype computation from style goals"
```

---

### Task 2: Étendre `StyleProfile` (Flutter)

**Files:**
- Modify: `frontend/lib/models/style_profile.dart`
- Test: `frontend/test/models/style_profile_test.dart`

- [ ] **Step 1: Write failing tests for new fields**

Add to `style_profile_test.dart`:

```dart
test('fromMap parses extended fields with defaults', () {
  final p = StyleProfile.fromMap({
    'goal_wardrobe': 4,
    'preferred_styles': ['streetwear', 'casual'],
    'usage_frequency': 'daily',
    'social_intent': 'private',
    'archetype': 'explorateur',
    'updated_at': '2026-01-01',
  });
  expect(p.preferredStyles, ['streetwear', 'casual']);
  expect(p.usageFrequency, 'daily');
  expect(p.socialIntent, 'undecided'); // absent → default
  expect(p.archetype, 'explorateur');
});

test('defaults include weekly and undecided', () {
  final p = StyleProfile.defaults();
  expect(p.usageFrequency, 'weekly');
  expect(p.socialIntent, 'undecided');
  expect(p.preferredStyles, isEmpty);
  expect(p.archetype, 'gestionnaire');
});
```

- [ ] **Step 2: Run test — expect FAIL**

Run: `cd frontend && flutter test test/models/style_profile_test.dart`

- [ ] **Step 3: Extend model**

Add fields:
```dart
final List<String> preferredStyles;
final String usageFrequency;  // daily | weekly | occasional
final String socialIntent;    // friends | private | undecided
final String archetype;       // gestionnaire | explorateur | apprenti_style
```

Defaults: `preferredStyles: const []`, `usageFrequency: 'weekly'`, `socialIntent: 'undecided'`, `archetype: 'gestionnaire'`.

Update `fromMap` / `toMap`. Add `StyleProfile copyWith({...})` for wizard draft updates.

Add helper:
```dart
StyleProfile withComputedArchetype() =>
    copyWith(archetype: computeArchetype(this));
```

Import `style_profile_archetype.dart`.

- [ ] **Step 4: Run tests — expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(model): extend StyleProfile with Fable fields"
```

---

### Task 3: Miroir backend `StyleProfile`

**Files:**
- Modify: `backend/app/models/style_profile.py`
- Test: `backend/tests/test_style_profile.py`

- [ ] **Step 1: Write failing pytest**

```python
def test_extended_style_profile_parses_optional_lists():
    p = StyleProfile.model_validate({
        "goal_wardrobe": 4,
        "preferred_styles": ["streetwear"],
        "usage_frequency": "daily",
        "social_intent": "friends",
        "archetype": "explorateur",
    })
    assert p.preferred_styles == ["streetwear"]
    assert p.usage_frequency == "daily"
    assert p.archetype == "explorateur"


def test_invalid_usage_frequency_defaults_weekly():
    p = StyleProfile.model_validate({"usage_frequency": "nope"})
    assert p.usage_frequency == "weekly"
```

- [ ] **Step 2: Run — expect FAIL**

Run: `cd backend && python -m pytest tests/test_style_profile.py -v`

- [ ] **Step 3: Add fields + validators**

```python
VALID_FREQUENCY = {"daily", "weekly", "occasional"}
VALID_SOCIAL = {"friends", "private", "undecided"}
VALID_ARCHETYPE = {"gestionnaire", "explorateur", "apprenti_style"}

preferred_styles: list[str] = Field(default_factory=list)
usage_frequency: str = "weekly"
social_intent: str = "undecided"
archetype: str = "gestionnaire"
```

Validators: filter `preferred_styles` to `VALID_IDENTITY`; enum fallbacks for frequency/social/archetype.

- [ ] **Step 4: Run pytest — expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(backend): extend StyleProfile model for unified onboarding"
```

---

### Task 4: i18n clés wizard 4–5

**Files:**
- Modify: `frontend/tool/gen_arb.py`
- Run: `python frontend/tool/gen_arb.py` (régénère `app_fr.arb`, `app_en.arb`)

- [ ] **Step 1: Add catalog entries**

```python
"styleExtraTitle": ("Tes préférences", "Your preferences"),
"stylePreferredStylesTitle": ("Styles que tu aimes", "Styles you like"),
"stylePreferredStylesHint": ("Optionnel — plusieurs choix possibles", "Optional — pick several"),
"styleUsageDaily": ("Tous les jours", "Every day"),
"styleUsageWeekly": ("Quelques fois par semaine", "A few times a week"),
"styleUsageOccasional": ("De temps en temps", "Occasionally"),
"styleUsageTitle": ("À quelle fréquence ?", "How often?"),
"styleSocialTitle": ("Partager tes tenues ?", "Share your outfits?"),
"styleSocialFriends": ("Oui, avec mes amis", "Yes, with friends"),
"styleSocialPrivate": ("Plutôt en privé", "Mostly private"),
"styleSocialUndecided": ("On verra plus tard", "Decide later"),
```

- [ ] **Step 2: Regenerate ARB**

Run: `cd frontend && python tool/gen_arb.py && flutter gen-l10n`
Expected: new keys in `app_localizations.dart`

- [ ] **Step 3: Commit**

```bash
git add frontend/tool/gen_arb.py frontend/lib/l10n/
git commit -m "feat(i18n): add wizard step 4-5 strings"
```

---

### Task 5: Étendre `StyleProfileForm`

**Files:**
- Modify: `frontend/lib/widgets/style_profile_form.dart`

- [ ] **Step 1: Add optional sections**

New constructor flags:
```dart
final bool showPreferredStyles;
final bool showUsageFrequency;
final bool showSocialIntent;
```

- `showPreferredStyles`: `FilterChip` multi-select sur `StyleProfileForm.identityKeys` → met à jour `preferredStyles` (liste). Si vide à la save, fallback `[identityStyle]`.
- `showUsageFrequency`: 3 cartes (réutiliser pattern `_comfortCard`).
- `showSocialIntent`: 3 cartes pour friends/private/undecided.

- [ ] **Step 2: Manual smoke** — pas de test widget obligatoire ici ; vérifié en Task 7.

- [ ] **Step 3: Commit**

```bash
git commit -am "feat(ui): extend StyleProfileForm for wizard steps 4-5"
```

---

### Task 6: Wizard écrans 4 et 5

**Files:**
- Create: `frontend/lib/screens/auth/style_onboarding/style_extra_screen.dart`
- Create: `frontend/lib/screens/auth/style_onboarding/style_social_screen.dart`
- Modify: `frontend/lib/screens/auth/style_onboarding/style_goals_screen.dart` — `OnboardingProgressBar(step: 1, total: 5)`
- Modify: `frontend/lib/screens/auth/style_onboarding/style_identity_screen.dart` — step 2/5
- Modify: `frontend/lib/screens/auth/style_onboarding/style_comfort_screen.dart` — step 3/5, **ne plus appeler save** ; `context.go('/onboarding/style/preferences')` (route ci-dessous)

**`style_extra_screen.dart` (étape 4):**
- `OnboardingProgressBar(step: 4, total: 5)`
- `StyleProfileForm(showGoals: false, showIdentity: false, showComfort: false, showPreferredStyles: true, showUsageFrequency: true)`
- Skip step → défauts `preferredStyles: []`, `usageFrequency: 'weekly'` dans draft
- Continue → `/onboarding/style/social`

**`style_social_screen.dart` (étape 5):**
- `OnboardingProgressBar(step: 5, total: 5)`
- `StyleProfileForm(showSocialIntent: true)` only
- `_finish`: build profile from draft → `.withComputedArchetype()` → `preferredStyles` vide ? `[identityStyle]` : draft.preferredStyles
- Call `styleProfileNotifier.saveWithSocialIntent(profile)` (Task 8)
- `context.go('/home')`
- Skip → `socialIntent: 'undecided'`, pas de changement `is_private`

- [ ] **Step 1: Implement screens**

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/screens/auth/style_onboarding/
git commit -m "feat(onboarding): add wizard steps 4-5 screens"
```

---

### Task 7: Router 5 étapes

**Files:**
- Modify: `frontend/lib/core/routes/app_router.dart`

- [ ] **Step 1: Register routes**

```dart
GoRoute(
  path: '/onboarding/style/preferences',
  builder: (_, __) => const StyleExtraScreen(),
),
GoRoute(
  path: '/onboarding/style/social',
  builder: (_, __) => const StyleSocialScreen(),
),
```

- [ ] **Step 2: Widget test navigation**

Create `frontend/test/onboarding/style_wizard_routes_test.dart` — pump `MaterialApp.router` with `routerProvider` override, verify routes exist (smoke via `GoRouter` location after `go`).

Minimal test:
```dart
test('comfort navigates to preferences route', () {
  // Use GoRouter named locations or integration-style test
});
```

Si trop lourd : skip widget test, valider manuellement + `flutter analyze`.

- [ ] **Step 3: Commit**

```bash
git commit -am "feat(router): register onboarding style steps 4-5"
```

---

### Task 8: Sauvegarde avec `is_private`

**Files:**
- Modify: `frontend/lib/providers/style_profile_provider.dart`

- [ ] **Step 1: Add method**

```dart
Future<void> saveWithSocialIntent(StyleProfile profile) async {
  final uid = _ref.read(authServiceProvider).uid;
  if (uid.isEmpty) return;

  final payload = <String, dynamic>{
    'style_profile': profile.withComputedArchetype().toMap(),
  };
  switch (profile.socialIntent) {
    case 'private':
      payload['is_private'] = true;
      break;
    case 'friends':
      payload['is_private'] = false;
      break;
    default:
      break; // undecided — ne pas toucher
  }
  await _ref.read(firestoreServiceProvider).updateUser(uid, payload);
  _ref.invalidate(currentUserProvider);
}
```

- [ ] **Step 2: Update `StyleGoalsScreen._skipAll`** — utiliser `saveWithSocialIntent(StyleProfile.defaults(skipped: true))` au lieu de `save`.

- [ ] **Step 3: Commit**

```bash
git commit -am "feat(onboarding): save style profile with social intent and is_private"
```

---

### Task 9: Paramètres — édition des nouveaux champs

**Files:**
- Modify: `frontend/lib/screens/profile/style_preferences_screen.dart`

- [ ] **Step 1: Show all form sections** including preferred styles + usage frequency (not social intent in settings v1 — hors spec édition, OK)

- [ ] **Step 2: On save** — `copyWith(archetype: computeArchetype(profile))` before `save()`

- [ ] **Step 3: Commit**

```bash
git commit -am "feat(profile): edit extended style preferences"
```

---

### Task 9 checkpoint

Run full frontend tests:
```bash
cd frontend && flutter analyze && flutter test
```
Expected: PASS

---

## Phase 2b — PersonalizationConfig + home / tutoriel

### Task 10: `PersonalizationConfig`

**Files:**
- Create: `frontend/lib/core/personalization_config.dart`
- Create: `frontend/lib/providers/personalization_provider.dart`
- Test: `frontend/test/core/personalization_config_test.dart`

- [ ] **Step 1: Failing tests**

```dart
test('explorateur → initialTab 2', () {
  final c = PersonalizationConfig.fromProfile(StyleProfile(archetype: 'explorateur'));
  expect(c.initialTab, 2);
  expect(c.showInspirationDiscoverBanner, isTrue);
});

test('gestionnaire → showDressingStatsCard', () {
  final c = PersonalizationConfig.fromProfile(StyleProfile(archetype: 'gestionnaire'));
  expect(c.initialTab, 0);
  expect(c.showDressingStatsCard, isTrue);
});

test('null profile → defaults neutres', () {
  final c = PersonalizationConfig.fromProfile(null);
  expect(c.initialTab, 0);
  expect(c.showDressingStatsCard, isFalse);
});
```

- [ ] **Step 2: Implement**

```dart
class PersonalizationConfig {
  final int initialTab;
  final int tutorialStartTab;
  final bool showDressingStatsCard;
  final bool showInspirationDiscoverBanner;
  final bool defaultInspirationExplorer;
  final bool showStylistPromoCard;
  final bool showOutfitFromInspoCta;

  const PersonalizationConfig({...});

  factory PersonalizationConfig.fromProfile(StyleProfile? profile) {
    if (profile == null || profile.onboardingSkipped) {
      return const PersonalizationConfig.neutral();
    }
    switch (profile.archetype) {
      case 'explorateur':
        return PersonalizationConfig(
          initialTab: 2,
          tutorialStartTab: 2,
          showInspirationDiscoverBanner: true,
          defaultInspirationExplorer: true,
          showOutfitFromInspoCta: true,
          ...
        );
      case 'apprenti_style':
        return PersonalizationConfig(
          initialTab: 1,
          tutorialStartTab: 1,
          showStylistPromoCard: true,
          ...
        );
      default: // gestionnaire
        return PersonalizationConfig(
          initialTab: 0,
          tutorialStartTab: 0,
          showDressingStatsCard: true,
          ...
        );
    }
  }
}
```

Provider:
```dart
final personalizationProvider = Provider<PersonalizationConfig>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return PersonalizationConfig.fromProfile(user?.styleProfile);
});
```

- [ ] **Step 3: Run tests — PASS**

- [ ] **Step 4: Commit**

---

### Task 11: Home — onglet initial par archétype

**Files:**
- Modify: `frontend/lib/core/style_home_layout.dart`
- Modify: `frontend/lib/screens/home/home_screen.dart`

- [ ] **Step 1: Update `homeTabLogicalOrder`**

Signature: `homeTabLogicalOrder(StyleProfile? profile, {String? archetype})`

Si `profile?.archetype` présent et non skipped → ordre onglets basé archétype :
- `gestionnaire` → `[0,1,2,3]`
- `explorateur` → `[2,1,0,3]`
- `apprenti_style` → `[1,0,2,3]`

Sinon → comportement actuel `dominantGoalKey` (rétro-compat).

- [ ] **Step 2: `home_screen.dart` — premier lancement**

Après login, si `user.hasStyleProfile && !tutorialSeen` :
- Lire `personalizationProvider.initialTab`
- Si onglet déverrouillé → `_goToTab(initialTab, tabOrder)` une seule fois (flag local `_archetypeTabApplied`)

Respecter : si onglet verrouillé → fallback Dressing (0).

- [ ] **Step 3: Update `style_home_layout_test.dart`**

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(home): tab order and initial tab from archetype"
```

---

### Task 12: Tutoriel réordonné

**Files:**
- Modify: `frontend/lib/screens/home/home_screen.dart`

- [ ] **Step 1: On new user tutorial start**

Remplacer `tutorialStepProvider.state = 0` par :
```dart
final start = ref.read(personalizationProvider).tutorialStartTab;
ref.read(tutorialStepProvider.notifier).state = start.clamp(0, 3);
```

- [ ] **Step 2: Manual test** — nouveau compte explorateur → tutoriel commence sur Inspiration

- [ ] **Step 3: Commit**

---

### Task 13: Inspiration — feed Explorer par défaut

**Files:**
- Modify: `frontend/lib/screens/inspiration/inspiration_screen.dart`

- [ ] **Step 1: On first build for explorateur**

```dart
ref.listen(personalizationProvider, (_, config) {
  if (config.defaultInspirationExplorer) {
    ref.read(inspirationExplorerVisibleProvider.notifier).state = true;
  }
});
```

Garder un flag `SharedPreferences` `inspiration_feed_default_applied` pour ne le faire qu’une fois.

- [ ] **Step 2: Commit**

---

## Phase 2c — CTAs conditionnels

### Task 14: Dressing — carte stats gestionnaire

**Files:**
- Modify: `frontend/lib/screens/dressing/dressing_screen.dart`
- i18n: `dressingStatsCardTitle`, `dressingAddGarmentCta` dans `gen_arb.py`

- [ ] **Step 1: Insert at top of list (if `personalizationProvider.showDressingStatsCard`)**

Widget `_DressingStatsCard` : nb pièces, répartition catégories (données `garmentsProvider`), CTA ouvre `AddGarmentSheet`.

- [ ] **Step 2: Commit**

---

### Task 15: Outfits — cartes conditionnelles

**Files:**
- Modify: `frontend/lib/screens/outfits/outfits_screen.dart`

- [ ] **Step 1: `showStylistPromoCard`** → carte en tête « Ta tenue du jour par ton styliste » → ouvre bottom sheet IA existante

- [ ] **Step 2: `showOutfitFromInspoCta`** → `TextButton` secondaire « Recrée une tenue vue dans l'inspi » → `context.go` tab Inspiration

- [ ] **Step 3: Commit**

---

### Task 16: Inspiration — bandeau explorateur

**Files:**
- Modify: `frontend/lib/screens/inspiration/inspiration_screen.dart`

- [ ] **Step 1: If `showInspirationDiscoverBanner` && first launch**

`Banner` dismissible → `SearchUsersScreen` via `context.push` ou route existante recherche amis.

- [ ] **Step 2: Commit**

---

### Task 17: Dressing — post-ajout apprenti_style

**Files:**
- Modify: `frontend/lib/widgets/add_garment_sheet.dart` OR callback in `dressing_screen.dart`

- [ ] **Step 1: After successful garment add, if `archetype == apprenti_style`**

SnackBar action « Voir des tenues » → switch tab Outfits (`selectedTabProvider`)

- [ ] **Step 2: Commit**

---

### Phase 2 checkpoint

```bash
cd frontend && flutter analyze && flutter test
cd backend && python -m pytest tests/test_style_profile.py tests/test_ai_scoring_profile.py -v
```

Critères Phase 2 :
- [ ] Wizard 5 écrans navigable
- [ ] `style_profile` complet en Firestore après écran 5
- [ ] `is_private` mis à jour si « Plutôt en privé »
- [ ] Home/tutoriel/CTAs réagissent à l’archétype

```bash
git commit -m "chore: phase 2 onboarding unified complete"
```

---

## Phase 3 — Styliste double-LLM + quota freemium

> Implémenter **après** validation Phase 2 en prod/dev. Chaque tâche reste testable isolément.

### Task 18: Quota `stylist_usage` (backend)

**Files:**
- Create: `backend/app/services/stylist_quota_service.py`
- Modify: `backend/app/api/routes/ai.py`
- Test: `backend/tests/test_stylist_quota.py`

- [ ] **Step 1: Test — free user 2nd call same day → 429 `stylist_quota_exceeded`**

- [ ] **Step 2: Implement Firestore counter** `users/{uid}.stylist_usage: {date, count}`

- [ ] **Step 3: Premium bypass** via `require_premium_user` OR allow 1 free/day before gate

Spec: gratuit 1 req/jour incluant les 2 LLM internes.

- [ ] **Step 4: Commit**

---

### Task 19: Pipeline double-LLM

**Files:**
- Modify: `backend/app/services/ai_service.py`
- Test: `backend/tests/test_suggest_stylist.py`

- [ ] **Step 1: Extract `_interpret_style_prompt()` → JSON directives**

- [ ] **Step 2: Pre-filter top 6 garments per category via `_score_with_profile`**

- [ ] **Step 3: `_compose_stylist_outfits()` second LLM call with compact catalog**

- [ ] **Step 4: Fallback chain** — interpreter fail → PROMPT_MAP ; composer fail → rule-based

- [ ] **Step 5: Extend response** — optional `reasoning` field (2-3 phrases) alongside `rationale_short`

- [ ] **Step 6: Commit**

---

### Task 20: Scoring enrichi nouveaux champs

**Files:**
- Modify: `backend/app/services/ai_service.py`
- Test: `backend/tests/test_ai_scoring_profile.py`

- [ ] **Step 1: Test `preferred_styles` boosts STYLE_WEIGHTS**

- [ ] **Step 2: Test `archetype apprenti_style` increases diversity**

- [ ] **Step 3: Test `usage_frequency daily` favors neutral patterns**

- [ ] **Step 4: Commit**

---

### Task 21: Frontend quota + styliste gratuit

**Files:**
- Modify: `frontend/lib/services/api_service.dart`
- Modify: `frontend/lib/screens/outfits/outfits_screen.dart`
- i18n: `stylistQuotaRemaining`, `stylistQuotaExceeded`

- [ ] **Step 1: Parse 429 `stylist_quota_exceeded` → upgrade dialog**

- [ ] **Step 2: Badge quota** sur carte apprenti_style (lire count depuis user doc ou API meta)

- [ ] **Step 3: Free users** — bottom sheet peut appeler `suggest-stylist` (quota) au lieu de rule-based only

- [ ] **Step 4: Commit**

---

### Phase 3 checkpoint

```bash
cd backend && python -m pytest tests/test_stylist_quota.py tests/test_suggest_stylist.py -v
cd frontend && flutter test
```

---

## Self-review (spec coverage)

| Exigence spec | Task |
|---------------|------|
| Wizard 5 écrans | Tasks 6–7 |
| `style_profile` étendu | Tasks 2–3 |
| Archétype calculé | Tasks 1, 8 |
| `is_private` depuis social | Task 8 |
| Édition Paramètres | Task 9 |
| PersonalizationConfig | Task 10 |
| Home onglet archétype | Task 11 |
| Tutoriel réordonné | Task 12 |
| CTAs par archétype | Tasks 14–17 |
| Double-LLM + quota | Tasks 18–21 |
| Rétro-compat champs absents | Tasks 2–3 defaults |
| i18n | Task 4 + CTAs |

---

## Execution handoff

**Plan saved to `docs/superpowers/plans/2026-06-12-onboarding-unified.md`.**

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks, fast iteration

2. **Inline Execution** — execute tasks in this session using `executing-plans`, batch execution with checkpoints

**Which approach?**
