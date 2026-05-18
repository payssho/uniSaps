# Prompt Canva IA — Diaporama uniSaps

Copie le bloc **« PROMPT COMPLET CANVA »** en bas de ce fichier dans l’assistant IA de Canva (Magic Design / génération de présentation). Adapte le nombre de slides si Canva en propose moins ou plus.

---

## Plan détaillé (contenu issu du projet réel)

### Slide 1 — Introduction / Couverture
- **Titre :** uniSaps
- **Sous-titre :** Outfit Manager — garde-robe digitale
- **Accroche :** Organiser ses vêtements, composer ses tenues, choisir son look du jour, s’inspirer et partager avec sa communauté — tout dans une seule app mobile Android.
- **Contexte projet :** Application développée en Flutter, backend Python, données Firebase, déployée en bêta sur Google Play (versions taguées v1.0.0-beta.x puis v1.0.1-beta.1).

### Slide 2 — Le problème (Introduction suite)
- **Constat :** Les photos de vêtements sont éparpillées (galerie, réseaux sociaux) ; difficile de se souvenir de tout son dressing et de composer des tenues cohérentes rapidement.
- **Réponse uniSaps :** Un catalogue personnel structuré + créateur d’outfits + choix du jour + fil d’inspiration social.
- **Cible :** Utilisateurs mode / organisation du dressing, usage quotidien mobile.

### Slide 3 — Analyse de l’existant (marché)
- **Concurrents / usages :** Pinterest / Instagram = inspiration sans inventaire ; apps garde-robe = souvent catalogue seul, peu de social intégré au même niveau.
- **Positionnement uniSaps :** Dressing + créations + outfits + inspiration + profil social (amis, posts) dans **une** expérience.
- **Visuel suggéré :** Schéma « avant / après » ou 3 icônes : dispersé → centralisé.

### Slide 4 — Analyse de l’existant (évolution technique)
- **Ancien prototype :** Code archivé `_legacy` (Flet / Python UI) — preuve d’itération rapide puis pivot.
- **Choix actuel :** Refonte **Flutter** (UI native, performance store) + **API REST FastAPI** (upload, IA) + **Firebase** (auth, base, fichiers).
- **Message :** Passage d’un prototype à un produit distribuable (Play Store).

### Slide 5 — Choix techniques (architecture)
- **Frontend :** Flutter 3.24+, Dart 3.5+, Riverpod (état), go_router (navigation).
- **Backend :** FastAPI sur **Vercel** (`https://unisaps.vercel.app/api/v1`), Python 3.11+.
- **Cloud :** Firebase Auth (email/mot de passe), Cloud Firestore, Firebase Storage.
- **IA :** Google **Gemini** (analyse photo vêtement) ; suggestions d’outfits via API `/ai/suggest` (styles : Simple, Coloré, Classe, etc.).
- **Visuel :** Schéma simple : Téléphone → API Vercel → Firebase + Gemini.

### Slide 6 — Choix techniques (design produit)
- **Palette officielle app :** Bleu Yale `#284B63`, Teal `#3C6E71`, Graphite `#353535`, fond clair `#F0F1F4`, blanc — style moderne, épuré, mode.
- **Sécurité :** Toutes les routes API (sauf `/health`) exigent `Authorization: Bearer <token Firebase>`.
- **Images :** Upload via backend (resize JPEG, pas d’exposition directe des clés admin côté mobile).

### Slide 7 — Fonctionnalités — Navigation principale
- **4 onglets bas de page :**
  1. **Dressing** — catalogue vêtements (icône cintre).
  2. **Outfits** — tenues du jour / bibliothèque / swipe (icône style).
  3. **Inspo** — fil inspiration social (icône explore).
  4. **Profil** — avatar utilisateur + badge rouge si demandes d’amis en attente.
- **Progression guidée :** Onglets Outfits et Inspo **verrouillés** tant qu’il n’y a pas au moins un vêtement puis un outfit ; tutoriel au premier lancement.
- **Météo du jour :** Intégration Open-Meteo (géolocalisation) pour contextualiser créations et suggestions.

### Slide 8 — Fonctionnalités — Dressing & Créations
- **Dressing :** Ajout multi-photos (jusqu’à 8), catégories : Couvre-chef, Hauts, Vestes, Bas, Chaussures, Accessoires ; couleurs (max 3), marque, nom.
- **Premium — Analyse IA à l’ajout :** Gemini détecte nom, marque, couleurs, catégorie, tags style, formalité, saison, matière ; rejet si la photo n’est pas un vêtement.
- **Créations (écran dédié) :** Composer un outfit en assignant une pièce par zone (tête, torse, veste, jambes, pieds, poignet) ; photo de référence ; filtres saison / météo optionnels pour affiner les suggestions.

### Slide 9 — Fonctionnalités — Outfits & Inspiration
- **Outfits :** Mode **Bibliothèque** + mode **Swipe** (cartes type Tinder) ; outfit du jour ; streaks / check quotidien ; **suggestions IA** (UniSaps+) avec cartes visuelles par pièce (photo, rôle, nom, marque).
- **Inspiration :** Feed de posts (photo look, likes) ; recherche d’utilisateurs ; profils publics ou **compte privé** (contenu visible amis seulement).
- **Social :** Demandes d’amis, acceptation/refus ; pastilles **rouges numérotées** sur Profil et onglet Amis.

### Slide 10 — Fonctionnalités — Profil & Premium
- **Profil — 5 sous-onglets :** Stats, Tenues, Souvenirs (galerie), Amis, Infos.
- **Compte gratuit vs Premium (`account_tier`) :** Premium = analyse IA vêtements, suggestions outfits avancées, anneau doré sur avatar (profil + posts), déblocage par code dans les paramètres.
- **Auth :** Inscription, connexion, onboarding (pseudo, nom affiché, photo profil).

### Slide 11 — V1 (première version livrée)
- **Objectif V1 :** MVP fonctionnel sur Android.
- **Inclus :** Auth Firebase, CRUD vêtements et outfits, navigation 4 onglets, upload images, backend upload + santé API, build APK/AAB, premières releases Play (`v1.0.0-beta.1` à `beta.3`).
- **Hors scope V1 :** Social avancé, Premium, polish notifications amis, robustesse upload production.

### Slide 12 — V2 (version actuelle / itérations)
- **Social complet :** Posts, likes, amis, compte privé, profils utilisateurs.
- **Monétisation légère :** Tier Premium + dialog upgrade + code premium.
- **Qualité prod :** Retries upload, MIME `image/jpeg`, sync Firestore avant IA ; badges demandes d’amis ; version **1.0.1+4** Play.
- **Évolutions UX :** Cartes suggestions IA plus visuelles, carrousel photos vêtements, météo rafraîchie au retour app.

### Slide 13 — Problèmes rencontrés
1. **Upload « Forbidden »** — Erreur GCS/Firebase Storage (droits compte de service, bucket accès uniforme, `make_public` interdit) ; parfois confondu avec Vercel alors que la cause est stockage cloud.
2. **IA sans préremplissage (~1 s)** — `isPremium` lu avant chargement du profil Firestore → analyse jamais lancée.
3. **Cold starts Vercel** — Latence première requête upload/IA.
4. **rembg désactivé en prod** — Limite taille déploiement Vercel ; traitement image simplifié (resize JPEG).

### Slide 14 — Choses apprises
- Toujours **attendre le profil métier** (Firestore) avant les features gated (Premium/IA).
- **Stockage objet = projet infra à part** (IAM, MIME, retries), pas seulement du code app.
- **Release Play** : `versionCode` strictement croissant, notes de release, tags Git cohérents.
- **Séparer MVP stable** et couches IA/social pour ne pas bloquer la bêta.

### Slide 15 — Conclusions
- **Bilan :** uniSaps démontre une stack moderne mobile + serverless + IA, du prototype à la **bêta Google Play**.
- **Forces :** Boucle valeur complète (ajouter → composer → porter → partager), architecture extensible.
- **Perspectives :** iOS, métriques store, renforcement fiabilité IA/upload, monétisation Premium aboutie.
- **Phrase de clôture :** « De la garde-robe réelle à la garde-robe intelligente et sociale. »

---

## PROMPT COMPLET CANVA (à copier-coller)

```
Crée une présentation moderne et très visuelle de 15 slides pour un projet étudiant / professionnel nommé « uniSaps » (application mobile de gestion de garde-robe et de mode).

STYLE GLOBAL (obligatoire) :
- Esthétique mode & tech : minimaliste, beaucoup d’espace blanc ou fond gris très clair (#F0F1F4), accents bleu marine (#284B63) et teal (#3C6E71), touches graphite (#353535).
- Peu de texte par slide (3 à 6 mots max en titre, puces courtes ou icônes uniquement).
- Grandes illustrations, pictogrammes, mockups téléphone, formes arrondies, dégradés discrets teal → bleu.
- Pas de paragraphes ; privilégier visuels, chiffres isolés, schémas fléchés simples.
- Ton professionnel mais dynamique, public : jury / encadrants / beta testeurs.
- Format 16:9, cohérence typographique sans-serif moderne (style Inter ou SF Pro).

CONTENU SLIDE PAR SLIDE :

1. COUVERTURE — Titre « uniSaps », sous-titre « Outfit Manager », icônes cintre + smartphone, mention « App Android · Flutter · Firebase · Bêta Play Store ».

2. PROBLÈME — Titre « Trop dispersé ». Visuel : photos éparpillées vs une app unique. 3 mots-clés : Catalogue · Tenues · Inspiration.

3. MARCHÉ — Titre « L’existant ». Colonne gauche : réseaux sociaux (inspiration seule). Colonne droite : uniSaps (dressing + social + IA). Icônes simples.

4. ÉVOLUTION — Titre « Du prototype au produit ». Flèche : Legacy (Flet) → Flutter + API. Message : refonte pour le store mobile.

5. ARCHITECTURE — Titre « Stack technique ». Schéma 4 blocs : Flutter (Riverpod) | FastAPI sur Vercel | Firebase Auth + Firestore + Storage | Gemini IA. Lignes de connexion légères.

6. DESIGN — Titre « Identité visuelle ». Afficher les 4 couleurs hex (#284B63, #3C6E71, #353535, #F0F1F4) en pastilles. Mots : Épuré · Mode · Mobile-first.

7. NAVIGATION — Titre « 4 univers ». 4 icônes en ligne : Dressing · Outfits · Inspo · Profil. Note visuelle : verrouillage progressif + tutoriel premier lancement.

8. DRESSING — Titre « Mon catalogue ». Visuel grille vêtements, 6 catégories (chapeau, haut, veste, bas, chaussures, accessoire). Badge « IA Premium » sur une photo.

9. OUTFITS & INSPO — Titre « Porter & partager ». Moitié gauche : carte swipe (style Tinder). Moitié droite : fil social avec cœur like. Mention « Suggestions IA UniSaps+ ».

10. PROFIL — Titre « Mon espace ». Avatar avec anneau premium, 5 mini-onglets (Stats, Tenues, Souvenirs, Amis, Infos). Pastille rouge « demandes d’amis ».

11. V1 — Titre « Version 1 — MVP ». Liste visuelle 4 icônes : Auth · Catalogue · Outfits · Build Android. Bandeau « Google Play bêta ».

12. V2 — Titre « Version 2 — Produit ». 4 pictos : Social · Premium · Robustesse · Releases. Numéro version stylisé « 1.0.1 ».

13. DIFFICULTÉS — Titre « Obstacles ». 4 icônes avec labels courts : Forbidden upload · IA trop rapide · Serverless · Infra images.

14. APPRENTISSAGES — Titre « Ce qu’on a appris ». 4 cartes : Sync Firestore · IAM Storage · Discipline release · MVP vs features.

15. CONCLUSION — Titre « uniSaps demain ». Phrase centrale grande : « Garde-robe intelligente & sociale ». 3 perspectives en icônes : iOS · Fiabilité · Premium. Merci.

Ne mets pas de slide avec uniquement du texte long. Chaque slide doit pouvoir être comprise en 5 secondes. Utilise des mockups de téléphone Android quand c’est pertinent. Garde la même charte couleur sur toutes les slides.
```

---

## Variante courte (si Canva limite les caractères)

```
Présentation 15 slides 16:9, style mode minimaliste, couleurs #284B63 #3C6E71 #353535 fond #F0F1F4, très visuel peu de texte.

uniSaps = app Flutter garde-robe : Dressing (catalogue vêtements multi-photos + IA Gemini Premium), Créations (composer outfit par zones corps), Outfits (bibliothèque + swipe Tinder + suggestions IA), Inspo (feed posts likes), Profil (stats streak amis compte privé Premium).

Stack : Flutter Riverpod, FastAPI Vercel, Firebase, Gemini. V1 = MVP Android Play bêta. V2 = social Premium badges amis fixes upload. Problèmes : Forbidden GCS, race Firestore/IA, cold start Vercel. Conclusion : produit distribué, perspectives iOS.

Une slide par thème : couverture, problème, marché, évolution legacy→Flutter, architecture, design, navigation 4 onglets, dressing, outfits+inspo, profil, V1, V2, obstacles, apprentissages, conclusion.
```
