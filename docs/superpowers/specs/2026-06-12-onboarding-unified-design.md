# Onboarding unifié — Profil style, personnalisation adaptative & styliste LLM

- **Date** : 2026-06-12
- **Branche** : `feature/onboarding-unified`
- **Statut** : validé pour implémentation (réconciliation Fable + Composer)
- **Remplace** :
  - `docs/superpowers/specs/2026-06-04-style-profile-stylist-design.md` (Composer — base code)
  - `docs/superpowers/specs/2026-06-09-onboarding-personalization-stylist-design.md` (Fable — vision produit)

## Contexte

uniSaps collecte aujourd’hui photo + pseudo à l’inscription, puis propose une expérience identique à tous. Les suggestions IA rule-based sont cohérentes mais peu « styliste ».

Deux travaux parallèles ont été réalisés :

| Source | Apport |
|--------|--------|
| **Composer** (`style-profile-stylist`) | Code livré : `style_profile`, wizard 3 écrans, `/ai/suggest-stylist` premium, home réordonnée, édition dans Paramètres |
| **Fable** (`onboarding-personalization`) | Vision produit : wizard 5 questions, archétypes, personnalisation adaptative riche, styliste double-LLM, quota freemium 1/jour |

Cette spec **unifie** les deux : on **étend** le modèle et le code Composer avec les apports Fable, sans second objet Firestore ni rupture de contrat API existant.

---

## Décisions de réconciliation

| Sujet | Composer | Fable | **Décision unifiée** |
|-------|----------|-------|----------------------|
| Objet Firestore | `style_profile` | `onboarding_profile` | **`style_profile` étendu** (un seul objet) |
| Objectifs utilisateur | 4 curseurs 1–5 | Chips multiples | **Garder les 4 curseurs** (déjà codés, plus nuancés) |
| Niveau mode | `beginner` / `balanced` / `confident` | Débutant / À l’aise / Confirmé | **Garder les clés Composer** (équivalent sémantique) |
| Styles | 1 identité + audace | Multi-sélection 8 styles | **Identité primaire + `preferred_styles[]` optionnel** (Fable Q3) |
| Fréquence / social | — | Q4 + Q5 (`is_private`) | **Ajouter** `usage_frequency` + `social_intent` |
| Archétype | `dominantGoalKey` | `gestionnaire` / `explorateur` / `apprenti_style` | **Calculer `archetype` côté Dart** à partir des curseurs + champs Fable |
| Édition après onboarding | Oui (Paramètres) | Non | **Oui** — meilleure UX, déjà implémenté |
| Styliste premium | `/ai/suggest-stylist`, 1 LLM, `rationale_short` | `/ai/stylist`, double LLM, `reasoning` long | **Phase 2** : enrichir `suggest-stylist` ; **Phase 3** : pipeline double-LLM Fable |
| Styliste gratuit | Rule-based `/ai/suggest` enrichi | 1 req styliste/jour | **Phase 3** : quota `stylist_usage` sur comptes gratuits |
| Personnalisation app | Ordre onglets home | Archétypes + CTAs par écran | **Phase 2** : `PersonalizationConfig` + CTAs Fable par archétype |

---

## État actuel (déjà sur `feature/onboarding-unified`)

### Livré (Composer — ne pas réécrire)

| Zone | Fichiers / routes |
|------|-------------------|
| Modèle | `frontend/lib/models/style_profile.dart`, `backend/app/models/style_profile.py` |
| Wizard | `style_goals_screen`, `style_identity_screen`, `style_comfort_screen` |
| Form partagé | `style_profile_form.dart`, `style_preferences_screen.dart` |
| Providers | `style_profile_provider.dart`, `style_onboarding_draft_provider.dart` |
| Home | `style_home_layout.dart` — ordre onglets selon objectif dominant |
| API | `POST /ai/suggest` enrichi, `POST /ai/suggest-stylist` (premium) |
| Tests | `test_style_profile.py`, `test_suggest_stylist.py`, `style_home_layout_test.dart` |

### À livrer (écarts vs cible unifiée)

1. Wizard **5 écrans** (2 écrans Fable manquants)
2. Champs `preferred_styles`, `usage_frequency`, `social_intent`, `archetype` sur `style_profile`
3. `PersonalizationConfig` + CTAs adaptatifs (Dressing, Inspiration, Outfits)
4. Tutoriel réordonné selon archétype
5. Pré-réglage `is_private` depuis `social_intent`
6. Styliste double-LLM + quota freemium (phase ultérieure)

---

## Modèle de données unifié

Sous-objet Firestore `users/{uid}.style_profile` — **étendre** sans renommer :

```json
{
  "goal_wardrobe": 3,
  "goal_inspiration": 3,
  "goal_refine_style": 3,
  "goal_track_wear": 3,
  "identity_style": "casual",
  "audacity": 3,
  "fashion_comfort": "beginner | balanced | confident",
  "preferred_styles": ["streetwear", "casual"],
  "usage_frequency": "daily | weekly | occasional",
  "social_intent": "friends | private | undecided",
  "archetype": "gestionnaire | explorateur | apprenti_style",
  "onboarding_skipped": false,
  "updated_at": "2026-06-12T10:00:00Z"
}
```

### Champs existants (Composer)

Inchangés. Voir spec Composer pour mapping identité → style canonique scoring.

### Champs nouveaux (Fable)

| Champ | Type | Défaut si skip |
|-------|------|----------------|
| `preferred_styles` | `string[]` clés identité | `[identity_style]` ou `["casual"]` |
| `usage_frequency` | enum | `"weekly"` |
| `social_intent` | enum | `"undecided"` |
| `archetype` | enum | `"gestionnaire"` |

### Calcul `archetype` (Dart, fin du wizard)

À partir des curseurs `goal_*` (1–5), pas des chips Fable :

1. Trouver l’objectif dominant (max des 4 ; égalité → priorité : `goal_refine_style` > `goal_inspiration` > `goal_track_wear` > `goal_wardrobe`)
2. Mapper :
   - dominant `goal_wardrobe` ou `goal_track_wear` → `gestionnaire`
   - dominant `goal_inspiration` → `explorateur`
   - dominant `goal_refine_style` → `apprenti_style`
3. Skip total → `gestionnaire`, `fashion_comfort: balanced`, défauts ci-dessus

### Effet `social_intent` sur le compte

À la fin du wizard (écran 5) :

| `social_intent` | Action |
|-----------------|--------|
| `private` | `users/{uid}.is_private = true` |
| `friends` | `is_private = false` |
| `undecided` | ne pas modifier `is_private` |

### Rétro-compatibilité

- `style_profile` absent ou champs nouveaux absents → défauts côté client, comportement actuel inchangé
- Pas de migration batch ; les comptes existants restent valides
- `archetype` recalculé à la prochaine sauvegarde du profil si absent

---

## Parcours onboarding unifié (5 écrans)

Après `/onboarding` (photo, pseudo, nom) :

| # | Route | Contenu | Source |
|---|-------|---------|--------|
| 1 | `/onboarding/style/goals` | 4 curseurs objectifs | Composer (existant) |
| 2 | `/onboarding/style/identity` | Style identité + audace | Composer (existant) |
| 3 | `/onboarding/style/comfort` | Rapport à la mode (3 cartes) | Composer (existant) |
| 4 | `/onboarding/style/preferences` | Styles préférés (multi-chips, optionnel) + fréquence d’usage | **Fable Q3 + Q4** |
| 5 | `/onboarding/style/social` | Intention de partage (3 cartes) | **Fable Q5** |

Barre de progression : `OnboardingProgressBar(step: n, total: 5)`.

**Skip :**

- « Passer toute la personnalisation » (écran 1) → `StyleProfile.defaults(skipped: true)` + `is_private` inchangé → `/home`
- « Passer » par écran → défauts pour les champs de cet écran uniquement
- Écran 5 : skip → `social_intent: undecided`, pas de changement `is_private`

**Sauvegarde :** un seul `save()` Firestore à la fin de l’écran 5 (ou au skip total), avec `archetype` calculé.

---

## Personnalisation adaptative (Phase 2)

### Architecture Flutter

```text
currentUserProvider
    └── styleProfile (StyleProfile étendu)
            └── personalizationProvider → PersonalizationConfig (immuable)
```

`PersonalizationConfig` expose :

| Propriété | Dérivée de |
|-----------|------------|
| `initialTab` | `archetype` : gestionnaire→0, explorateur→2, apprenti_style→1 |
| `tutorialStartTab` | idem |
| `showDressingStatsCard` | `archetype == gestionnaire` |
| `showInspirationDiscoverBanner` | `archetype == explorateur` && premier lancement |
| `defaultInspirationFeedTab` | explorateur → Explorer ; sinon Amis |
| `showStylistPromoCard` | `archetype == apprenti_style` |
| `showOutfitFromInspoCta` | `archetype == explorateur` |

**Règle de priorité :** le déverrouillage d’onglets existant (garments/outfits requis) reste prioritaire sur `initialTab`.

### Comportements par archétype (Fable, incrémental)

Implémentation par **cartes/CTA conditionnels** dans les écrans existants — pas de refonte layout.

| Archétype | Dressing | Outfits | Inspiration |
|-----------|----------|---------|-------------|
| **gestionnaire** | Carte stats + CTA « Ajouter une pièce » | Rappel doux, pas de push IA agressif | Standard |
| **explorateur** | Standard | CTA « Recrée une tenue vue dans l’inspi » | Bandeau « Trouve des comptes à suivre » ; feed Explorer par défaut |
| **apprenti_style** | Post-ajout : « Voir des tenues avec cette pièce » | Carte « Ta tenue du jour par ton styliste » (quota si Phase 3) | Standard |

---

## IA styliste — phasage

### Phase 1 — ✅ Livré (Composer)

| Route | Tier | Comportement |
|-------|------|--------------|
| `POST /ai/suggest` | Tous | Rule-based + pondération `style_profile` |
| `POST /ai/suggest-stylist` | Premium | 1 appel Gemini → tenues + `rationale_short` (≤ 120 car.) ; fallback rule-based |

### Phase 3 — Cible Fable (hors scope immédiat)

| Élément | Détail |
|---------|--------|
| Route | Conserver `/ai/suggest-stylist` (ne pas créer `/ai/stylist` en parallèle) |
| Pipeline | LLM interprète → scoring top-6/catégorie → LLM styliste → validation ids |
| Gratuit | `stylist_usage: { date, count }` — 1 req/jour ; premium illimité |
| Réponse | Ajouter `reasoning` optionnel (2–3 phrases) en plus de `rationale_short` pour premium |
| Frontend | Badge quota ; bottom sheet appelle styliste pour tous (avec gate quota/premium) |

**Décision :** ne pas casser le contrat `suggest-stylist` actuel ; étendre le payload réponse en v2.

---

## API backend — extensions

### `style_profile` dans les requêtes IA

Les nouveaux champs (`preferred_styles`, `archetype`, `usage_frequency`) sont **optionnels** pour le scoring :

- `preferred_styles` → bonus sur `STYLE_WEIGHTS` pour styles listés
- `archetype apprenti_style` → légère hausse diversité / audace dans le scoring
- `usage_frequency: daily` → favoriser pièces polyvalentes (wardrobe)

### Sauvegarde profil

Réutiliser le flux existant (`styleProfileNotifier.save` / patch user). Pas de nouvelle route si le patch user actuel suffit.

### Codes d’erreur (existants + Phase 3)

Existants : `premium_required`, `stylist_unavailable`, `insufficient_garments`, `invalid_style_profile`  
Phase 3 : `stylist_quota_exceeded` (HTTP 429)

---

## Flutter — fichiers impactés (phases 2)

| Action | Fichier |
|--------|---------|
| Étendre modèle | `style_profile.dart`, `user_model.dart` |
| Backend miroir | `style_profile.py` |
| Nouveaux écrans | `style_preferences_screen.dart` (wizard step 4), `style_social_screen.dart` (step 5) |
| Router | `app_router.dart` — 5 steps, redirect si profil incomplet |
| Archétype | `style_profile_archetype.dart` (pur Dart, testable) |
| Perso | `personalization_config.dart`, `personalization_provider.dart` |
| Écrans CTAs | `dressing_screen.dart`, `outfits_screen.dart`, `inspiration_screen.dart` (insertions conditionnelles) |
| i18n | `gen_arb.py` + clés wizard 4–5, archétypes, CTAs |

---

## Gestion d’erreurs

| Cas | Comportement |
|-----|--------------|
| Échec save Firestore wizard | SnackBar + retry ; utilisateur jamais bloqué (profil base déjà créé) |
| `suggest-stylist` LLM down | Fallback rule-based + `rationale_short` template (existant) |
| Quota dépassé (Phase 3) | HTTP 429 → dialogue upgrade UniSaps+ |
| Profil partiel (migration) | Défauts + pas de crash |

---

## Tests

| Couche | Phase 2 | Phase 3 |
|--------|---------|---------|
| Dart unit | `computeArchetype()` — dominants, égalités, skip ; `PersonalizationConfig` flags ; `StyleProfile` nouveaux champs | — |
| Flutter widget | Wizard 5 steps navigation ; skip partiel | Quota badge |
| Backend pytest | Parse `style_profile` étendu ; scoring avec `preferred_styles` | Pipeline double-LLM mocké ; quota |
| Intégration | Nouveau user → wizard → home onglet archétype | Free 1/jour styliste |

CI : `flutter analyze`, `flutter test`, `pytest` doivent rester verts à chaque phase.

---

## Hors périmètre

- Genre / morphologie / tailles
- Migration forcée des comptes existants
- Billing Google Play réel (stub premium conservé)
- Dark mode
- Recommandations créateurs par profil
- Cache Redis suggestions

---

## Critères d’acceptation (cible finale)

1. Nouvel utilisateur complète ou skip un wizard **5 écrans** après le profil classique.
2. `style_profile` unique contient curseurs, archétype, styles préférés, fréquence, intention sociale.
3. `is_private` pré-réglé si « Plutôt en privé ».
4. Préférences modifiables dans Paramètres (Composer conservé).
5. Home + tutoriel + CTAs reflètent l’**archétype** sans bloquer les onglets existants.
6. Gratuit : `/ai/suggest` enrichi ; Premium : `/ai/suggest-stylist` avec phrase (Phase 1 OK).
7. Phase 3 : gratuit 1 styliste/jour ; premium illimité ; double-LLM avec fallbacks.
8. Aucune régression auth, analyze-garment, i18n erreurs API.

---

## Plan d’implémentation (phases)

| Phase | Contenu | Livrable testable |
|-------|---------|-------------------|
| **1** | Composer intégré | ✅ Sur `feature/onboarding-unified` |
| **2a** | Étendre `StyleProfile` + archétype + écrans 4–5 | Wizard complet |
| **2b** | `PersonalizationConfig` + ordre onglets/tuto par archétype | Home adaptée |
| **2c** | CTAs conditionnels Dressing / Outfits / Inspiration | Perso visible |
| **3** | Double-LLM + quota freemium sur `suggest-stylist` | Styliste Fable |

**Prochaine étape Superpowers :** skill `writing-plans` → `docs/superpowers/plans/2026-06-12-onboarding-unified.md` (détail tâches Phase 2a).

---

## Références

- Spec Composer : `2026-06-04-style-profile-stylist-design.md`
- Spec Fable : `2026-06-09-onboarding-personalization-stylist-design.md`
- Plan Composer (historique) : `docs/superpowers/plans/2026-06-04-style-profile-stylist.md`
