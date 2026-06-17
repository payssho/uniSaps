# Design — Onboarding d'intention, personnalisation adaptative et styliste LLM

- **Date** : 2026-06-09
- **Branche** : `feature/onboarding-personalization` (basée sur `main`)
- **Statut** : validé par l'utilisateur (brainstorming complet)

## Contexte et problème

Deux constats sur uniSaps (état `main`) :

1. **Les suggestions IA sont pratiques mais pas stylées.** `POST /api/v1/ai/suggest` repose sur un scoring rule-based (`backend/app/services/ai_service.py`) : couleurs, formalité, saison, météo, historique 7 jours, puis tirage aléatoire dans le top 50 %. Gemini ne sert qu'à enrichir les attributs des pièces (`analyze-garment`). Résultat : des tenues cohérentes mais sans raisonnement de styliste ni justification.
2. **On ne demande jamais à l'utilisateur ce qu'il attend de l'app.** L'onboarding actuel (`frontend/lib/screens/auth/onboarding_screen.dart`) collecte photo + username + display name, rien d'autre. L'app est identique pour quelqu'un qui veut juste ranger son dressing et pour un passionné qui cherche des inspirations IA.

## Décisions structurantes (validées)

| Sujet | Décision |
|---|---|
| Audience du questionnaire | **Nouveaux comptes uniquement** (pas de migration, pas d'édition ultérieure) |
| Architecture styliste | **Hybride double appel LLM** : interprète → scoring → styliste pro |
| Personnalisation | **Adaptative** : tout reste accessible, l'app réordonne et met en avant |
| Monétisation styliste | **Freemium** : 1 requête styliste/jour gratuite, illimité UniSaps+ |
| Modèle de personnalisation | **Archétypes** (approche A) : 3 profils dérivés des réponses brutes |

---

## 1. Questionnaire d'onboarding

### UX

Après l'écran profil actuel (photo + username), wizard de **5 questions**, une par écran, chips/cartes tapables, barre de progression, ~30 s au total. Chaque question est skippable ; skip total = valeurs par défaut.

| # | Question | Type | Options |
|---|---|---|---|
| 1 | Pourquoi uniSaps ? | multiple | Organiser ma garde-robe · M'inspirer des tenues des autres · Recevoir des idées de tenues par IA · Suivre ce que je porte au quotidien |
| 2 | Ton niveau en mode ? | unique | Débutant, je veux apprendre · À l'aise, je cherche des idées · Confirmé, je veux optimiser |
| 3 | Tes styles préférés ? | multiple, optionnel | Les 8 styles canoniques existants (Simple, Colore, Classe, Professionnel, Decontracte, Streetwear, Sportif, Soiree) |
| 4 | Fréquence d'usage prévue ? | unique | Tous les jours · Quelques fois par semaine · De temps en temps |
| 5 | Partager tes tenues ? | unique | Oui avec mes amis · Plutôt en privé · On verra |

La question 5 pré-règle aussi `is_private` (« Plutôt en privé » → `true`).

### Données Firestore

Nouveau champ sur `users/{uid}` :

```json
"onboarding_profile": {
  "goals": ["manage_wardrobe", "social_inspiration", "ai_inspiration", "daily_tracking"],
  "fashion_level": "beginner | comfortable | expert",
  "preferred_styles": ["Streetwear", "Decontracte"],
  "usage_frequency": "daily | weekly | occasional",
  "social_intent": "friends | private | undecided",
  "archetype": "gestionnaire | explorateur | apprenti_style",
  "completed_at": "<timestamp>"
}
```

### Calcul de l'archétype (Dart, fin du wizard)

- Objectif dominant `manage_wardrobe` ou `daily_tracking` → `gestionnaire`
- Objectif dominant `social_inspiration` → `explorateur`
- Objectif dominant `ai_inspiration` → `apprenti_style`
- Égalité : `ai_inspiration` coché → `apprenti_style` ; sinon `social_inspiration` coché → `explorateur` ; sinon `gestionnaire`
- Skip total → `gestionnaire`, `fashion_level: comfortable`

### Rétro-compatibilité

`onboarding_profile` absent (tous les comptes existants) = comportement actuel inchangé, défauts appliqués côté client. Aucune migration.

---

## 2. Personnalisation adaptative

### Architecture

- `PersonalizationConfig` : petit objet immuable Dart dérivé de `onboarding_profile` (onglet de départ, flags d'affichage).
- `personalizationProvider` (Riverpod) : dérivé de `currentUserProvider`, expose la config. Chaque écran lit 1-2 flags maximum ; pas de refonte d'écrans, uniquement des cartes/CTA conditionnels insérés dans l'existant.

### Comportements par archétype

**Commun**
- Onglet de démarrage au lancement : Dressing (gestionnaire), Inspiration (explorateur), Outfits (apprenti_style). Le déverrouillage existant reste prioritaire (onglet verrouillé → fallback Dressing).
- Tutoriel réordonné : commence par l'onglet de l'archétype.

**Gestionnaire**
- Dressing : carte stats en tête (nb pièces, répartition par catégorie, pièces jamais portées) + CTA proéminent « Ajouter une pièce ».
- Outfits : rappel doux « habille tes pièces » plutôt que push IA.

**Explorateur**
- Inspiration : bandeau premier-lancement « Trouve des comptes à suivre » → recherche utilisateurs/créateurs ; onglet Explorer par défaut dans le feed (au lieu d'Amis).
- Outfits : CTA secondaire « Recrée une tenue vue dans l'inspi ».

**Apprenti style**
- Outfits : carte « Ta tenue du jour par ton styliste » en tête (entrée directe styliste, quota visible).
- Dressing : après ajout d'une pièce, suggestion « Voir des tenues avec cette pièce ».

---

## 3. Styliste LLM hybride — double appel

### Entrée

Identique à aujourd'hui : prompt libre **ou** chip de style dans la bottom sheet IA de l'écran Outfits.

### Pipeline `POST /api/v1/ai/stylist` (nouvelle route ; `/ai/suggest` intact)

1. **LLM n°1 — interprète** (`gemini-2.5-flash`) : reçoit le prompt/style brut + saison/météo. Retourne un JSON structuré : style canonique (parmi les 8), ambiance, contraintes (formalité cible, palette de couleurs souhaitée, pièces à éviter). Remplace le `PROMPT_MAP` à mots-clés pour cette route — comprend les demandes fines (« premier date en hiver »).
2. **Scoring** : `_score()` existant exécuté avec les directives du LLM n°1 (style résolu, saison, météo, ajustements selon contraintes). Garde le **top ~6 pièces par catégorie** → catalogue compact.
3. **LLM n°2 — styliste pro** : reçoit le catalogue pré-filtré (id, nom, couleurs, style_tags, formalité, matière, motif), les directives du n°1, le **profil onboarding** (`fashion_level`, `preferred_styles`, `archetype`) et les tenues récentes (anti-répétition). Compose N tenues en JSON strict : ids par slot (top/bottom/shoes requis, headwear/outerwear/accessory optionnels) + `title` + `reasoning` (2-3 phrases). Ton adapté : débutant → pédagogue, tenues sûres ; expert → pointu, associations audacieuses ; prompt vague → penche vers `preferred_styles`.
4. **Validation backend** : chaque id doit exister et matcher sa catégorie ; suggestion invalide écartée et complétée par le rule-based.
5. **Fallbacks étagés** :
   - LLM n°1 échoue → `PROMPT_MAP` actuel, pipeline continue.
   - LLM n°2 échoue → réponse 100 % rule-based (`source: "fallback"`).
   - JSON malformé → 1 retry par appel, puis fallback. Timeout ~15 s par appel.

### Freemium

- Compteur serveur sur `users/{uid}` : `stylist_usage: { "date": "YYYY-MM-DD", "count": n }`.
- Gratuit : **1 requête styliste/jour** (les 2 appels LLM internes comptent pour 1). Premium : illimité.
- Quota dépassé → HTTP 429 ; le front affiche le dialogue d'upgrade UniSaps+ existant.
- Reset par comparaison de date à la requête (pas de cron). Non contournable côté client.

### Frontend

- La bottom sheet IA appelle `/ai/stylist` au lieu de `/ai/suggest`.
- Affiche le `reasoning` sous chaque tenue proposée.
- Badge « quota restant » pour les comptes gratuits.

---

## 4. Gestion d'erreurs, tests, périmètre

### Erreurs

- Wizard : échec d'écriture Firestore → retry proposé ; le profil de base étant déjà créé, l'utilisateur n'est jamais bloqué.
- Styliste : fallbacks étagés ci-dessus.
- Quota : vérifié serveur uniquement.

### Tests

- **Flutter** : calcul d'archétype (dominants, égalités, skip), parsing `onboarding_profile` dans `UserModel`, `PersonalizationConfig` (onglet de départ, flags). Patterns existants (`test/models/`, `test/providers/`, fakes).
- **Backend** (pytest, nouveau) : pipeline styliste avec Gemini mocké — pré-filtrage top-N, validation ids, fallbacks n°1/n°2, quota.
- CI existante (`flutter analyze` + `flutter test`) doit rester verte.

### Hors périmètre

- Pas de migration des comptes existants ni d'édition du questionnaire après coup.
- Pas de billing réel (code premium actuel conservé).
- `/ai/suggest` et `/ai/analyze-garment` inchangés.
- Pas de refonte d'écrans, pas de dark mode.
