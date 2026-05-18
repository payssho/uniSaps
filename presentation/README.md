# uniSaps - Outfit Manager

**Auteur :** [Prénom Nom] - Master 1 CNAM, parcours TRIED (Traitement de l'information et exploitation des données)  
**Module :** Programmation orientée objet - Projet personnel (coefficient 3)  
**Enseignant :** Adrien ESCOURROU  
**Date limite de rendu :** 13/05/2026 à 23h59  
**Dépôt :** [URL Git complète à compléter avant envoi du mail]

---

## Présentation du projet

**uniSaps** est mon application mobile de gestion de garde-robe. Je photographie mes vêtements, je compose des tenues, je choisis un **outfit du jour** (bibliothèque, swipe, ou suggestions IA), je suis un **streak**, et je partage mes looks sur un fil **Inspiration** façon réseau social.

### Problème que je règle

Chaque matin je perds du temps à choisir quoi porter ; j'oublie des pièces et je répète les mêmes looks. Les apps mode existantes poussent à l'achat ou montrent des tenues qui ne viennent pas de **mon** placard. J'ai voulu relier mon dressing réel, ma décision du jour et un partage social léger.

### Public visé

- Étudiants et jeunes actifs (18–35 ans) pressés le matin.
- Personnes qui veulent **mieux utiliser** leur garde-robe actuelle.
- Une communauté mode amateur (inspiration, likes, amis).

### Mes personas

| Persona | Profil | Besoin principal |
|---------|--------|------------------|
| **Léa, 24 ans** | Étudiante en design | Ne pas répéter la même tenue ; inspiration rapide |
| **Karim, 31 ans** | Consultant | Tenue pro selon la météo ; peu de temps le matin |
| **Sophie, 28 ans** | Créatrice de contenu | 1 post/jour, galerie, visibilité premium |

---

## Mon modèle économique

### UniSaps+ (déjà en place côté produit)

J'ai structuré un abonnement **UniSaps+** pour les fonctionnalités IA :

| Offre | Prix | Inclus |
|-------|------|--------|
| Mensuel | **1 € / mois** | Analyse IA des vêtements + suggestions d'outfits IA |
| À vie | **5 €** (unique) | Même périmètre, sans abonnement |

Le statut est porté par `account_tier` (`premium`) dans Firestore ; l'encaissement store (Google Play) est l'étape suivante pour la mise en production commerciale.

### Comptes Créateur / marques (axe que je développe)

Je prévois d'inviter des **marques de vêtements françaises indépendantes** (démarchage direct) avec un compte **Créateur** payant au mois. En échange, elles pourront publier des **pub posts** (outfits mettant en avant leur marque), insérés dans Inspiration environ **1 tous les 5 à 10 posts** utilisateurs, avec un badge **Sponsorisé** visible.

---

## Fonctionnalités

### Dressing
- Catalogue par catégories, photos multiples, marques, couleurs.
- **UniSaps+** : analyse IA (Gemini) à l'ajout d'un vêtement.

### Outfits
- Composition 6 zones, météo Open-Meteo, outfit du jour, swipe, streak.
- **UniSaps+** : suggestions IA (prompt + styles).

### Inspiration
- Feed Explorer / Amis, likes, 1 post/jour, amis, profils.

### Profil
- Stats, galerie, paramètres, activation UniSaps+.

### Transversal
- Auth Firebase, onboarding, tutoriels, widgets Android, CI (`flutter test`).

---

## Installation et lancement

### Prérequis

- Flutter **≥ 3.24**, Python **≥ 3.11**, projet Firebase `unisaps-3ad84`, Android.

### Frontend

```bash
cd frontend
flutterfire configure --project=unisaps-3ad84
flutter pub get
flutter run
```

### Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Prod : `https://unisaps.vercel.app/api/v1`

### Tests

```bash
cd frontend
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

### Build Android

```bash
cd frontend
flutter build apk --release
flutter build appbundle --release
```

---

## Exemples d'utilisation

1. Inscription → onboarding → ajout d'un vêtement (manuel ou IA si UniSaps+).
2. Création d'un outfit → choix du jour (swipe ou bibliothèque).
3. Photo du jour → publication Inspiration (1/jour).
4. Profil : stats, galerie, passage en UniSaps+ (1 €/mois ou 5 € à vie).

*(Vidéo démo : [lien à ajouter])*

---

## Limites et suites

| Limite actuelle | Ma piste |
|-----------------|----------|
| Paiement store à finaliser | Google Play Billing pour 1 € et 5 € |
| Comptes Créateur non codés | `account_type`, pub posts, mixage feed 1/10 |
| Reset streak côté client | Cloud Function minuit |
| Pas de tests E2E | `integration_test` |

---

## Usage de l'IA (déclaration obligatoire)

J'ai utilisé des outils d'IA (Cursor, agents spécialisés, Gemini) pour concevoir, coder, tester et documenter. Je détaille tout dans `documentation.md` et `rapport-production.md`.

### Pourquoi j'ai utilisé l'IA

- Scaffolding Flutter/Python, debug Firebase/Vercel, rédaction des tests et de cette documentation.

### Exemples de prompts

Voir `rapport-production.md` (section 2) - dont mon cahier des charges Outfit Manager complet.

### Ce que j'ai validé moi-même

- Schéma Firestore, règles de sécurité, choix Gemini + moteur rule-based, tarification UniSaps+, refonte UI V4.

### Marquage code IA (exigence sujet)

```python
# ############### CODE IA (Cursor / Claude) ###############
# ...
# #######################################################
```

---

## Documentation

| Fichier | Contenu |
|---------|---------|
| [documentation.md](./documentation.md) | Doc technique (source PDF) |
| [rapport-production.md](./rapport-production.md) | Genèse du projet, versions, monétisation |
| [GENERER_PDF.md](./GENERER_PDF.md) | Export PDF |

---

## Rendu

Mail à **adrien.escourrou.prof@gmail.com** : nom, lien Git, présentation orale. Sans mail : **−2 points**. Après le 13/05/2026 23h59 : **0** technique.
