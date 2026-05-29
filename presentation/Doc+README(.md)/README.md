# uniSaps - Outfit Manager

**Auteur :** Marius Durand - Master 1 CNAM, parcours TRIED (Traitement de l'information et exploitation des données)  
**Module :** Programmation orientée objet - Projet personnel (coefficient 3)  
**Enseignant :** Adrien ESCOURROU  
**Dépôt :** https://github.com/payssho/uniSaps

---

## Présentation du projet

**uniSaps** est mon application mobile de gestion de garde-robe. Je photographie mes vêtements, je compose des tenues, je choisis un **outfit du jour** (bibliothèque, swipe, ou suggestions IA), je suis un **streak**, et je partage mes looks sur un fil **Inspiration** façon réseau social.

### Problème que je règle

Chaque matin je perds du temps à choisir quoi porter ; j'oublie des pièces et je répète les mêmes looks. Les apps mode existantes poussent à l'achat ou montrent des tenues qui ne viennent pas de **mon** placard. J'ai voulu relier mon dressing réel, ma décision du jour et un partage social léger.

### Public visé

- Étudiants et jeunes actifs (18–35 ans) pressés le matin.
- Personnes qui veulent **mieux utiliser** leur garde-robe actuelle.
- Une communauté mode amateur ET pro pour de l'échange (inspiration, likes, amis).

### Mes personas


| Persona            | Profil               | Besoin principal                                                                         |
| ------------------ | -------------------- | ---------------------------------------------------------------------------------------- |
| **Léa, 24 ans**    | Étudiante en design  | Ne pas répéter la même tenue ; inspiration rapide. Pro en mode.                          |
| **Karim, 31 ans**  | Consultant           | Tenue pro selon la météo ; peu de temps le matin. Débutant en mode.                      |
| **Sophie, 28 ans** | Créatrice de contenu | 1 post/jour, galerie, visibilité premium pour sa marque de vêtement via compte créateur. |


---

## Mon modèle économique

### UniSaps+ (déjà en place côté produit)

J'ai structuré un abonnement **UniSaps+** pour les fonctionnalités IA :


| Offre   | Prix             | Inclus                                              |
| ------- | ---------------- | --------------------------------------------------- |
| Mensuel | **1 € / mois**   | Analyse IA des vêtements + suggestions d'outfits IA |
| À vie   | **5 €** (unique) | Même périmètre, sans abonnement                     |


Le statut est porté par `account_tier` (`premium`) dans Firestore ; l'encaissement store (Google Play) est l'étape suivante pour la mise en production commerciale.

### Comptes Créateur / marques (axe que je développe)

Je prévois d'inviter des **marques de vêtements françaises indépendantes** (démarchage direct) avec un compte **Créateur** payant **29 $ / mois**. En échange, elles pourront publier des **pub posts** (outfits mettant en avant leur marque), insérés dans Inspiration environ **1 tous les 7 posts** utilisateurs en moyenne, avec un badge **Sponsorisé** visible.

---

## Fonctionnalités

L'application s'organise autour de **quatre onglets principaux** dans `HomeScreen` : **Dressing · Outfits · Inspiration · Profil**. La création de tenue se fait via le **FAB « Ajouter un fit »** sur l'onglet Outfits (mode Bibliothèque) — il n'y a pas de cinquième onglet « Créer ». Certains onglets se déverrouillent progressivement : Outfits après le premier vêtement, Inspiration après le premier outfit.

Documentation technique complémentaire : [README racine](../README.md).

### Authentification et parcours d'entrée

- **Connexion** : je me connecte avec email et mot de passe via Firebase Authentication. Si mon compte existe déjà, je suis redirigé vers l'accueil ; sinon vers l'onboarding.
- **Inscription compte personnel** : je crée un compte avec email, mot de passe (minimum 6 caractères) et confirmation, puis je passe à la personnalisation du profil.
- **Découverte espace créateur (inscription)** : sur l'écran d'inscription, un second onglet présente l'espace marque via un carrousel (swipe Inspiration, catalogue, sponsoring) et mène au checkout créateur sans créer de compte perso au préalable.
- **Onboarding profil** : pour tout nouveau compte utilisateur, je choisis une photo (caméra ou galerie), un pseudo obligatoire et un nom affiché optionnel. Mes données sont enregistrées dans Firestore et je accède à l'app principale.
- **Langue FR / EN** : je peux basculer entre français et anglais depuis l'onglet **Compte** de mon profil (ou depuis le profil créateur). Le choix est mémorisé localement. Un écran de sélection au premier lancement existe dans le code mais le changement se fait surtout depuis le profil.
- **Tutoriel in-app** : au premier usage, un overlay en quatre étapes me guide — remplir le dressing, créer un outfit, découvrir Inspiration, publier un post — avec possibilité de passer ou de suivre pas à pas.

### Dressing (catalogue vêtements)

- **Grille et catégories** : je visualise ma garde-robe en grille, organisée selon six zones corporelles (headwear, top, outerwear, bottom, shoes, accessory). Si mon dressing est vide, un état vide m'invite à ajouter ma première pièce.
- **Filtres** : je peux filtrer par catégorie (chips), par nom, par marque ou par couleur pour retrouver rapidement une pièce.
- **Ajout de vêtement** : via le FAB ou une feuille modale, j'ajoute jusqu'à **8 photos** par pièce (caméra ou galerie), un nom, une marque (sélecteur avec catalogue embarqué), plusieurs couleurs et une catégorie.
- **Analyse IA à l'ajout (UniSaps+)** : si je suis abonné, la première photo est envoyée à Gemini via le backend. L'IA préremplit nom, marque, couleurs, catégorie, tags de style, formalité, saison, motif et matière. Sans abonnement, les switches IA sont grisés et un dialog m'invite à passer en UniSaps+.
- **Suppression d'arrière-plan (UniSaps+)** : à l'upload, je peux activer la suppression automatique du fond (rembg côté backend) pour des visuels plus propres dans la grille.
- **Fiche détail** : en tapant sur une pièce, j'ouvre un carrousel photos, les attributs (catégorie, marque, couleurs, métadonnées IA). En tant que propriétaire, je peux modifier ou supprimer la pièce (avec confirmation). Sur le profil d'un autre utilisateur, la fiche est en lecture seule.

### Outfits et outfit du jour

- **Déverrouillage** : l'onglet Outfits reste verrouillé tant que je n'ai ajouté aucun vêtement ; un message me renvoie vers le dressing.
- **Deux modes d'affichage** : en **Bibliothèque**, je vois la grille de toutes mes tenues enregistrées ; en **Swipe**, des cartes empilées me permettent de choisir visuellement mon outfit du jour en glissant.
- **Création manuelle** : le FAB « Ajouter un fit » ouvre un assistant par étapes. J'assemble ma tenue zone par zone (tête, veste, haut avec plusieurs couches possibles, bas, chaussures, accessoires poignet), j'ajoute optionnellement un nom, une photo de référence et des tags **saison** / **météo simplifiée** (beau, nuageux, pluie, neige) pour le tri ultérieur.
- **Outfit du jour** : une fois une tenue validée, elle devient mon outfit du jour. Je peux prendre une photo du look porté, la remplacer ou la supprimer. Tant qu'aucun outfit du jour n'est choisi en mode Swipe, le scroll horizontal de l'onglet est désactivé pour me concentrer sur le choix.
- **Streak** : chaque jour où je valide un outfit du jour, ma série (streak) augmente et s'affiche dans mon profil, avec une animation de célébration à la validation.
- **Tri météo / saison** : les tenues compatibles avec la météo et la saison du jour remontent en tête en mode Bibliothèque et Swipe.
- **Suggestions IA (UniSaps+)** : via le FAB étincelles, je choisis un style parmi huit presets (Simple, Coloré, Classe, Professionnel, Décontracté, Streetwear, Sportif, Soirée) ou je saisis un prompt libre. Le backend génère jusqu'à **3 combinaisons** à partir de mon dressing, en tenant compte de la météo, de la saison et des pièces portées récemment. Je peux enregistrer une suggestion comme outfit et la définir comme outfit du jour.
- **Détail outfit** : depuis la bibliothèque, mon profil ou la galerie, j'ouvre une feuille détail listant les pièces de la tenue avec accès aux fiches vêtements.

### Météo

- **Données du jour** : l'app récupère la météo via Open-Meteo à partir de ma géolocalisation (avec fallback sur Paris si je refuse la permission). Une chip compacte sur l'onglet Outfits affiche température et condition.
- **Feuille détail** : en tapant la chip, j'accède à une vue enrichie — température et ressenti, ville, arc soleil/lune, timeline horaire sur 24 h avec probabilité de pluie, chips conditions (orage, neige…), vent et humidité, avec rafraîchissement manuel.
- **Impact sur les tenues** : les tags météo alimentent le tri des outfits du jour et sont transmis au moteur de suggestions IA pour proposer des tenues adaptées au contexte réel.

### Inspiration (réseau social léger)

- **Déverrouillage** : l'onglet Inspiration s'ouvre une fois que j'ai créé au moins un outfit.
- **Deux feeds** : je bascule entre **Amis** (posts de mon réseau) et **Explorer** (posts publics de la communauté). Un double-tap sur une carte permet de liker rapidement.
- **Publication** : je publie mon outfit du jour sur Inspiration (photo du jour ou photo de référence de la tenue), avec une légende optionnelle et les pièces référencées visibles sur le post. La limite est de **1 publication par jour** ; le bouton Publier disparaît une fois le quota atteint.
- **Posts sponsorisés** : dans Explorer, des posts créateurs marqués **Sponsorisé** sont insérés parmi les posts organiques (environ 1 pour 7 posts utilisateurs). Les vues sur ces posts sont comptabilisées pour les statistiques créateur.
- **Recherche et amitié** : je recherche des utilisateurs par pseudo, consulte des suggestions automatiques, envoie ou accepte des demandes d'ami, et accède aux profils publics.
- **Profils tiers** : sur le profil d'un autre utilisateur, je vois ses posts, son dressing et ses outfits en lecture seule. Pour un **compte créateur**, les onglets sont Posts et Collections. Si le compte est **privé**, seuls ses amis voient le contenu.
- **Carte post** : chaque post affiche l'auteur (avec anneau premium si UniSaps+), la photo, la légende, les likes et les références vêtements. Un tap ouvre le détail complet.

### Profil personnel

- **En-tête (hero)** : mon avatar (avec anneau premium si UniSaps+), mon pseudo, mon streak en flamme, et des statistiques (nombre de vêtements, d'outfits).
- **Onglet Souvenirs** : une galerie en grille de mes photos d'outfits, triées par date, pour revoir visuellement mon historique de looks.
- **Onglet Amis** : je gère les demandes reçues (accepter / refuser), active ou désactive le **compte privé** (seuls mes amis voient alors mon contenu), consulte ma liste d'amis, en ajoute via la recherche ou en retire avec confirmation.
- **Onglet Compte** : je vois mon pseudo, email, date d'inscription, statut UniSaps+ (Gratuit / Actif), la tuile **Langue** (FR / EN), j'active UniSaps+ via un code secret (MVP avant store), je me déconnecte ou je supprime mon compte (mot de passe requis, action irréversible).
- **Graphique des pièces les plus portées** : un graphique dans l'onglet Compte me montre quelles pièces je porte le plus souvent, pour repérer mes basiques et mes oubliés du placard.
- **Badge profil** : une pastille sur l'icône Profil dans la barre de navigation indique le nombre de demandes d'ami en attente.

### Espace Créateur / marques

- **Parcours séparé** : les comptes créateur n'utilisent pas le `HomeScreen` utilisateur. Le flux est : landing (`/creator`) → checkout abonnement (**29 $ / mois**, paiement simulé avec code d'activation `CREATOR2026`) → onboarding marque → espace créateur (`/creator/home`).
- **Checkout** : si je ne suis pas connecté, je crée un compte email/mot de passe sur place, puis j'active l'abonnement stub (30 jours). Sans abonnement actif, je suis redirigé vers le checkout.
- **Onboarding marque** : je renseigne logo (obligatoire), nom de marque, identifiant public, bio, URL boutique, et je peux lier optionnellement un compte personnel existant (recherche par pseudo).
- **Onglet Vêtements** : je gère mon catalogue par **collections** (nom, dates début/fin). J'ajoute ou modifie des pièces via le même flux que le dressing, mais en mode catalogue (collection obligatoire, marque forcée à mon @pseudo, pas d'IA premium ni de fond transparent).
- **Onglet Posts** : je consulte mes posts publicitaires groupés par collection, j'active ou désactive un post, et je crée un nouveau **post pub** via un assistant en trois étapes (sélection pièces par zone → photo + nom + légende → collection + statut actif), avec aperçu feed avant publication.
- **Onglet Profil marque** : je vois mon logo, nom, statut d'abonnement, statistiques (vues posts, pièces catalogue), le top de mes posts par vues, l'URL boutique (copiable), un lien vers mon profil perso lié, le sélecteur de langue et la déconnexion.

### Transversal et bonus

- **Widgets Android** : un widget affiche mon outfit du jour, la météo et le streak sur l'écran d'accueil du téléphone. Des deep links rouvrent l'app sur le bon onglet (dressing, outfits, inspiration, profil) ou lancent directement l'action publier.
- **Internationalisation** : l'app supporte le français et l'anglais via des fichiers ARB (`app_fr.arb`, `app_en.arb`). Un audit des textes hardcodés restants est à faire.
- **CI GitHub** : à chaque push ou pull request, `flutter analyze` et `flutter test` tournent automatiquement pour garantir la qualité du code frontend.
- **Backend API** : upload d'images, analyse Gemini, suggestions d'outfits, activation abonnement créateur — le tout hébergé sur Vercel en production (`https://unisaps.vercel.app/api/v1`).

---

## Installation et lancement

Documentation détaillée backend : [backend/LANCE_BACKEND.md](../backend/LANCE_BACKEND.md).

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **≥ 3.24** et Dart **≥ 3.5**
- [Python](https://www.python.org/) **≥ 3.11** (pour le backend local)
- Un projet [Firebase](https://console.firebase.google.com/) configuré (`unisaps-3ad84`)
- Android Studio ou un téléphone Android (USB debugging activé)
- Git

### 1. Vérifier l'environnement Flutter

```bash
flutter doctor
```

### 2. Firebase

1. Activer **Authentication** (Email / mot de passe), **Cloud Firestore** et **Firebase Storage** dans la console Firebase.
2. Créer une app Android avec le package `com.unisaps.app`.
3. Télécharger `google-services.json` et le placer dans `frontend/android/app/`.
4. Configurer FlutterFire :

```bash
dart pub global activate flutterfire_cli
cd frontend
flutterfire configure --project=unisaps-3ad84
```

### 3. Backend (local, optionnel pour mobile)

Le frontend mobile utilise par défaut l'API de production sur Vercel. Le backend local est utile pour développer ou tester upload / IA / rembg en local.

1. Copier `backend/.env.example` vers `backend/.env` et renseigner les variables Firebase.
2. Placer `serviceAccountKey.json` (clé de compte de service Firebase) dans `backend/` — ne jamais le committer.
3. Installer et lancer :

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # macOS / Linux
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Alternative Windows** : `.\start.ps1` depuis le dossier `backend`.

- API locale : `http://localhost:8000` — Swagger : `http://localhost:8000/docs`
- Production (app mobile) : `https://unisaps.vercel.app/api/v1`

> **Note :** `rembg` télécharge un modèle IA au premier usage (plusieurs minutes possibles).

### 4. Frontend Flutter

```bash
cd frontend
flutter pub get
flutter run
```

Pour un appareil physique : brancher le téléphone en USB, activer le débogage, puis `flutter devices` et `flutter run`.

### 5. Tests et qualité

```bash
cd frontend
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

La CI GitHub (`.github/workflows/flutter_tests.yml`) exécute ces commandes à chaque push / PR.

### 6. Build Android (release)

```bash
cd frontend
flutter build apk --release
flutter build appbundle --release
```

L'APK se trouve dans `frontend/build/app/outputs/flutter-apk/`.

### 7. Accès sans backend local

Si Firebase est configuré (`google-services.json` + `flutterfire configure`), l'app mobile peut être lancée **sans backend local** : les appels IA et upload passent par l'API Vercel en production.

---

## Exemples d'utilisation

Scénarios pensés pour guider mes captures vidéo. Une vidéo courte par scénario (fichiers locaux dans [`Scénarios/`](Scénarios/)).

### Scénario 1 — Première ouverture

**Objectif :** montrer le parcours d'un nouvel utilisateur de A à Z jusqu'au dressing vide.  
**Parcours :** lancer l'app → inscription (email / mot de passe) → onboarding (photo + pseudo) → arrivée sur le dressing vide avec le tutoriel.  
**Vidéo :** [Scénario1.mp4](Scénarios/Scénario1.mp4)

### Scénario 2 — Remplir le dressing (avec UniSaps+ (IA))

**Objectif :** montrer l'ajout de vêtements manuellement et la navigation dans le catalogue.  
**Parcours :** FAB Ajouter → photos (caméra ou galerie) → nom, marque, couleurs, catégorie → validation → grille remplie → filtres par catégorie / marque / couleur.  
**Vidéo :** [Scénario2.mp4](Scénarios/Scénario2.mp4)

### Scénario 3 — Création d’un outfit du jour adapté à la météo

**Objectif :** montrer la création d’une tenue, le système de sélection en mode Swipe et l’adaptation aux conditions météo.

**Parcours :** onglet Outfits (déverrouillé) → FAB « Ajouter un fit » → assistant de création par zones (`top`, `bottom`, `shoes`…) → enregistrement de la tenue → consultation des informations météo (température, pluie, vent, timeline 24 h) → retour sur Outfits → tri des tenues adaptées aux conditions météo → passage en mode Swipe → swipe des propositions → validation de l’outfit du jour → augmentation du streak utilisateur.

**Vidéo :** [Scénario3.mp4](Scénarios/Scénario3.mp4)

### Scénario 4 — Suggestions IA (UniSaps+)

**Objectif :** montrer la génération automatique de tenues.  
**Parcours :** FAB étincelles → choix de style (ex. Professionnel) ou prompt libre → affichage de 3 suggestions → enregistrer une suggestion → la définir comme outfit du jour.  
**Vidéo :** [Scénario4.mp4](Scénarios/Scénario4.mp4)

### Scénario 5 — Publier sur Inspiration

**Objectif :** montrer le lien outfit du jour → publication sociale.  
**Parcours :** onglet Inspiration → bouton Publier → aperçu photo + légende + pièces référencées → publication → post visible dans feed Amis → double-tap pour liker un post.  
**Vidéo :** [Scénario5.mp4](Scénarios/Scénario5.mp4)

### Scénario 6 — Social (amis et profils)

**Objectif :** montrer la dimension réseau.  
**Parcours :** icône recherche → trouver un utilisateur → envoyer demande d'ami → accepter depuis Profil / Amis → consulter profil ami (posts, dressing) → activer compte privé.  
**Vidéo :** [Scénario6.mp4](Scénarios/Scénario6.mp4)

### Scénario 7 — Parcours Créateur (marque)

**Objectif :** montrer l'espace marque de bout en bout.

**Parcours :** inscription onglet Créateur → checkout 29 $/mois (code activation) → onboarding marque (logo, nom, bio) → ajouter collection + pièces catalogue → créer post pub → vérifier badge Sponsorisé dans Explorer (compte utilisateur).

**Vidéos :**
- **Création du compte créateur** (inscription, checkout, onboarding marque) : [Scénario7.mp4](Scénarios/Scénario7.mp4)
- **Interface espace marque** (catalogue, collections, posts pub, profil créateur) : [Scénario7bis.mp4](Scénarios/Scénario7bis.mp4)

---

## Limites et pistes d'amélioration


| Limite actuelle                                                                                                                                                          | Ma piste                                                                                                                                                                                                |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Paiement store non finalisé** — UniSaps+ (1 €/mois et 5 € à vie) et compte Créateur (29 $/mois) reposent sur des codes d'activation MVP, pas sur un vrai encaissement. | Intégrer Google Play Billing et App Store Connect ; remplacer les codes par des abonnements et achats in-app réels ; gérer le renouvellement et l'expiration côté Firestore.                            |
| **Suggestions d'outfits perfectibles** — le moteur actuel combine des règles et les attributs IA, mais ne prend pas encore assez en compte mes habitudes réelles.        | Enrichir les paramètres (dress code pro, fréquence de port, feedback utilisateur, météo fine, événements du calendrier) ; hybrider scoring rule-based et LLM pour des propositions plus personnalisées. |
| **Onboarding utilisateur minimal** — je ne demande aujourd'hui que photo et pseudo à l'inscription.                                                                      | Ajouter un questionnaire (usage quotidien des vêtements, contexte pro/loisir, niveau en mode, priorités matin/soir) pour adapter l'interface, les suggestions et les rappels à chaque profil.           |
| **Coûts infra à l'échelle** — avec beaucoup d'utilisateurs, les coûts Gemini, Firestore (reads/writes), Storage et bande passante Vercel peuvent grimper vite.           | Prévoir un budget et un plan de montée en charge (cache, quotas IA, tier gratuit limité, monitoring des coûts par utilisateur).                                                                         |
| **i18n incomplète après merge UX** — une partie des textes ajoutés sur la branche UX est encore en dur en français dans le code Dart.                                    | Audit systématique des strings hardcodées → migration vers `app_fr.arb` / `app_en.arb` et usage de `context.l10n` partout.                                                                              |
| **Suppression de fond lourde en local** — `rembg` télécharge un gros modèle et ralentit le premier upload en développement.                                              | Externaliser le traitement sur un service cloud optimisé ou proposer une version allégée pour le MVP.                                                                                                   |
| **Tests UI limités** — la couverture porte surtout sur models, providers et services ; peu de widget tests sur les parcours complets.                                    | Ajouter des widget tests sur auth, swipe outfit, publication Inspiration et checkout créateur.                                                                                                          |
| **Pas de modération** — aucun signalement ni filtrage de contenu sur les posts et profils publics.                                                                       | Prévoir signalement, blocage et modération avant un lancement grand public.                                                                                                                             |


### Pistes bonus

- **Notifications push** : rappel matinal outfit du jour, alerte demande d'ami, expiration abonnement créateur.
- **Export garde-robe / stats** : PDF ou CSV de mon dressing, historique de streaks et pièces les plus portées.
- **Partenariats marques FR** : démarchage de marques indépendantes pour alimenter l'espace Créateur et le feed sponsorisé (aligné avec mon modèle économique).

