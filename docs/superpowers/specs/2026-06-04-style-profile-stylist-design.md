# Profil style & suggestions styliste — Design

**Date:** 2026-06-04  
**Statut:** Implémenté — plan `docs/superpowers/plans/2026-06-04-style-profile-stylist.md`  
**Branche cible suggérée :** `feature/style-profile-stylist` (à part de `feature/i18n-api-errors`)

## Objectif

Rendre uniSaps plus **personnalisé** et plus **styliste** :

1. **Onboarding** (après création du profil classique) : objectifs, style identité, audace, rapport à la mode — **skippable** avec défauts simples.
2. **Paramètres** : modification à tout moment des mêmes préférences.
3. **Suggestions IA** :
   - **Gratuit** : moteur rule-based actuel (`/ai/suggest`), enrichi par le profil.
   - **UniSaps+** : moteur **LLM end-to-end** (`/ai/suggest-stylist`) qui compose les looks depuis le dressing + **une mini-phrase** d’explication (≤ 120 caractères, 1 phrase).

Pas de collecte obligatoire du genre en v1.

## Décisions produit (brainstorming)

| Sujet | Choix |
|-------|-------|
| Périmètre | Onboarding + personnalisation app + IA (chantier unique) |
| Genre | Non requis en v1 |
| Objectifs | 4 curseurs **1–5** (échelles indépendantes) |
| Style | **1 style identité** + curseur **audace** 1–5 |
| Niveau | **Rapport à la mode** : `beginner` \| `balanced` \| `confident` |
| IA gratuite | Rule-based existant + pondération profil |
| IA premium | Gemini compose outfits + `rationale_short` (1 phrase) |
| Onboarding UX | **Après** photo/pseudo/nom ; **skippable** → défauts |
| Architecture backend | **Approche 2** : `style_profile` sur user + endpoints séparés |
| Fallback premium | Si LLM échoue → `/ai/suggest` + phrase template courte |

## Architecture retenue

### Données

Sous-objet Firestore sur `users/{uid}` :

```text
style_profile: {
  goal_wardrobe: int,       // 1-5 — Gérer la garde-robe
  goal_inspiration: int,    // 1-5 — Inspiration / idées de looks
  goal_refine_style: int,   // 1-5 — Affiner son style
  goal_track_wear: int,     // 1-5 — Suivi pratique (streak, outfit du jour)
  identity_style: string,   // clé canonique (voir liste ci-dessous)
  audacity: int,            // 1-5, sobre (1) → expérimental (5)
  fashion_comfort: string,  // beginner | balanced | confident
  onboarding_skipped: bool,
  updated_at: string        // ISO8601
}
```

**Styles identité (v1)** — clés stables, labels i18n dans ARB :

| Clé | Style canonique scoring (`ai_service`) |
|-----|----------------------------------------|
| `casual` | Decontracte |
| `classic` | Classe |
| `minimal` | Simple |
| `streetwear` | Streetwear |
| `sport` | Sportif |
| `professional` | Professionnel |
| `colorful` | Colore |
| `evening` | Soiree |

**Défauts si onboarding skippé** (`onboarding_skipped: true`) :

| Champ | Valeur |
|-------|--------|
| `goal_*` (×4) | `3` |
| `identity_style` | `casual` |
| `audacity` | `3` |
| `fashion_comfort` | `balanced` |

### API backend

| Route | Auth | Tier | Rôle |
|-------|------|------|------|
| `POST /ai/suggest` | JWT | Tous | Inchangé en contrat ; scoring enrichi via `style_profile` optionnel dans body |
| `POST /ai/suggest-stylist` | JWT | **premium** | LLM choisit pièces parmi ids fournis + `rationale_short` |
| `PATCH /users/me/style-profile` (ou champs dans update user existant) | JWT | Tous | Sauvegarde profil style |

**Réponse `suggest-stylist` (JSON strict)** :

```json
{
  "suggestions": [
    {
      "garments": { "top": "garmentId", "bottom": "garmentId", "shoes": "garmentId" },
      "rationale_short": "Marine et beige, idéal pour un déjeuner pro."
    }
  ]
}
```

Contraintes LLM :

- N’utiliser **que** les `id` présents dans le payload dressing.
- `rationale_short` : **max 120 caractères**, **une phrase**, ton adapté à `fashion_comfort`.
- `count` : 3 par défaut (aligné UI actuelle).

**Codes d’erreur** (via `api_error`) : `premium_required`, `stylist_unavailable`, `insufficient_garments`, `invalid_style_profile`.

### Flutter

| Zone | Changement |
|------|------------|
| `UserModel` | Map `styleProfile` + helpers |
| Onboarding | 3 écrans après `OnboardingScreen` actuel ; route `/onboarding/style` (wizard) |
| Router | Rediriger nouveaux users vers wizard style si `style_profile` absent (sauf skip enregistré) |
| `profile_screen` | Section « Style & préférences » (mêmes contrôles) |
| `home_screen` | Ordre / visibilité blocs selon objectif dominant (`max(goal_*)`) |
| `outfits_screen` | Premium → `suggestStylist` ; afficher `rationale_short` sous chaque carte |
| `api_service.dart` | `suggestStylist()`, parse nouvelle réponse |
| i18n | Nouvelles clés ARB (onboarding, styles, objectifs, mini-phrase label) |

### Personnalisation app (sans LLM)

| Signal | Effet |
|--------|-------|
| `goal_inspiration` ≥ 4 | Mettre en avant Inspiration / recherche |
| `goal_wardrobe` ≥ 4 | Mettre en avant Dressing / ajout pièce |
| `goal_refine_style` ≥ 4 | CTA suggestions IA plus visible (si premium) |
| `goal_track_wear` ≥ 4 | Outfit du jour / streak en tête home |
| `fashion_comfort: beginner` | Tutoriels plus présents ; copy pédagogique |
| `fashion_comfort: confident` | Moins de modales ; prompt libre suggéré |
| `audacity` ≥ 4 | Chips style par défaut vers variantes plus audacieuses |
| Skip / défauts | Home générique, scoring neutre |

### Scoring rule-based enrichi (`ai_service.py`)

Entrées optionnelles : `style_profile` dans `SuggestRequest`.

- Mapper `identity_style` → style canonique pour `STYLE_WEIGHTS`.
- `audacity` haute : bonus `_pattern_bonus` / familles `warm`, `pastel`.
- Objectif inspiration élevé : légèrement réduire pénalité anti-répétition 7j.
- Objectif wardrobe élevé : favoriser pièces « polyvalentes » (neutral, faible flashy).

### LLM styliste (`suggest_stylist` nouveau module ou section `ai_service.py`)

- Réutiliser infra Gemini de `analyze_garment` (même modèle Flash, température basse).
- Prompt : JSON strict, liste dressing compacte (id, catégorie, couleurs, tags), profil, météo, consigne utilisateur.
- Validation serveur : rejeter ids hors dressing ; compléter catégories vides si possible via fallback rule-based.
- Timeout → fallback `/ai/suggest` + `rationale_short` template i18n côté client ou serveur.

## Parcours onboarding (skippable)

```text
/signup → /onboarding (photo, pseudo, nom) → completeOnboarding minimal
    → /onboarding/style/goals     [Passer]
    → /onboarding/style/identity  [Passer]
    → /onboarding/style/comfort   [Passer]
    → save style_profile → /home
```

- **Passer** sur l’écran 1 avec option « Passer toute la personnalisation » : applique défauts + `onboarding_skipped: true`, saute écrans 2–3.
- **Passer** sur écran 2 ou 3 seul : champs non remplis → défauts pour ces champs uniquement.

## Hors scope v1

- Genre / morphologie / tailles
- Traduction du contenu UGC
- LLM gratuit
- Recommandations créateurs basées sur profil (phase 2)
- Cache Redis des suggestions styliste

## Sécurité & coûts

- `suggest-stylist` : même garde premium que `analyze-garment` (`account_tier == premium`).
- Limiter taille payload dressing (ex. max 80 pièces, tronquer par catégorie si besoin).
- Logger latence + fallback (sans loguer photos).

## Tests minimaux

| Couche | Tests |
|--------|-------|
| Backend | Mapping `identity_style` → canonique ; défauts skip ; parse JSON LLM (mock) ; rejection ids invalides ; premium gate |
| Flutter | `StyleProfile` fromMap/toMap ; wizard skip → défauts ; `api_service` parse `rationale_short` |
| Intégration | Premium mock → 3 suggestions avec phrase ; free → ancien endpoint |

## Critères d’acceptation

1. Nouvel utilisateur peut compléter ou **passer** le questionnaire style après le profil.
2. Préférences modifiables dans Paramètres et reflétées au prochain appel IA.
3. Utilisateur **gratuit** : suggestions identiques en UX à aujourd’hui (chips + liste), scoring influencé par profil.
4. Utilisateur **premium** : suggestions via LLM avec **une mini-phrase** par look ; fallback silencieux si erreur API.
5. Aucune régression sur `analyze-garment` et auth.

## Prochaine étape (Superpowers)

Après relecture et validation de cette spec → skill **`writing-plans`** : plan d’implémentation détaillé dans `docs/superpowers/plans/2026-06-04-style-profile-stylist.md`.
