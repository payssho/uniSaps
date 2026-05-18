# Rapport de production - uniSaps (Outfit Manager)

**Marius Durand** - Master 1 CNAM, parcours TRIED  
Programmation orientée objet - Application de gestion de garde-robe

---

## Introduction

### Le problème que je cherchais à résoudre

Chaque matin, je me pose la même question : *qu'est-ce que je mets ?* Ma garde-robe physique est riche, mais je oublie souvent des combinaisons et des pièces que je ne sors plus. Les applications mode que j'ai testées poussent généralement à l'achat ou proposent des looks qui ne viennent pas de mon placard. J'avais besoin d'un outil qui numérise mon dressing, m'aide à choisir rapidement une tenue cohérente en tenant compte de la météo et de mon historique, gamifie l'habitude avec un streak, et me permet de partager mes looks sans recourir à un réseau social généraliste.

C'est dans ce cadre que j'ai conçu **uniSaps** : une application qui relie le dressing virtuel, la décision quotidienne de l'outfit et un mini-réseau social nommé « Inspiration ».

### Les besoins que j'ai identifiés

Au fil de la conception, j'ai structuré les attentes autour de six axes. L'utilisateur doit pouvoir inventorier ses vêtements par catégorie avec photos et métadonnées, sélectionner l'outfit du jour sans parcourir physiquement tout son placard, varier ses combinaisons pour ne pas toujours porter les mêmes pièces, adapter ses choix au contexte (froid, pluie, rendez-vous professionnel ou sortie), partager au plus un look par jour et recevoir des retours de son cercle, et enfin mesurer son usage via des statistiques, un streak et une galerie des photos prises lors des outfits du jour.

### Mes personas

Pour valider ces besoins, je me suis appuyé sur trois profils types.

**Léa, 24 ans, étudiante en design**, possède un dressing modeste mais soigné. Le matin, elle manque de temps et oublie des pièces « au fond ». Elle attend un swipe rapide, des suggestions du type « Surprends-moi » et un feed Inspiration pour trouver des idées sans quitter l'application.

**Karim, 31 ans, consultant**, alterne tenues formelles et looks décontractés le week-end. Il se déplace souvent et la météo influence directement son choix. Il a besoin de tags saison et météo sur ses outfits, de suggestions orientées « professionnel » et d'un streak qui l'encourage à structurer sa routine.

**Sophie, 28 ans, créatrice de contenu mode**, publie un look par jour sur les réseaux. Elle veut enchaîner photo de l'outfit du jour, publication sur Inspiration, visibilité premium et une galerie chronologique dans son profil.

---

## 1. Analyse de l'existant et technologies potentielles

### 1.1 Ce qui existait déjà sur le marché

J'ai d'abord cartographié les solutions proches de mon idée. Pinterest et Instagram offrent une inspiration visuelle et une communauté, mais ils ne sont pas connectés à mon dressing réel et ne gèrent pas un outfit du jour structuré. Des applications comme Stylebook ou Whering permettent de numériser une garde-robe, souvent moyennant un abonnement, avec peu d'intégration d'un réseau social ou d'une IA calibrée sur mes propres photos. Les applications météo ou le simple miroir donnent un contexte climatique sans connaître mes vêtements. Enfin, un tableur ou Notion reste flexible mais ne propose ni une UX mobile aboutie, ni l'optimisation des images, ni un système de streak.

Ma conclusion à l'issue de cette analyse est qu'il existe déjà des « closet apps », mais que peu d'entre elles combinent une IA sur mes photos, un outfit du jour gamifié et un fil social dans une architecture que je maîtrise, fondée sur Firebase et une API Python conforme au module PO.

### 1.2 Les pistes techniques que j'ai envisagées

#### Côté interface mobile

J'ai commencé par **Flet**, attrait majeur : une seule langue Python avec le backend du projet. J'ai vite constaté que les widgets mobiles étaient encore limités et que le responsive sur petits écrans était difficile à maîtriser. **Flutter** m'a semblé plus adapté pour une interface riche, le hot reload et des composants matures (swipe, caméra), au prix d'apprendre Dart. **React Native** aurait écarté une partie du code Python côté client, ce qui affaiblissait la cohérence avec mon sujet. **Kivy** ou **BeeWare** restent des options Python natives, mais avec une maturité UI inférieure à Flutter pour mon cas d'usage.

#### Côté données et backend

**Firebase** (Auth, Firestore, Storage) offrait un temps réel natif, un SDK Flutter solide et des règles de sécurité fines ; le modèle de coût devait toutefois rester sous surveillance. **Supabase** aurait impliqué une migration depuis l'écosystème Firebase que j'utilisais déjà en cours. Une **base SQLite locale seule** aurait bien géré l'offline mais pas le social multi-utilisateurs. Un **PostgreSQL auto-hébergé** avec API REST maison donnait un contrôle total au prix d'une charge opérationnelle trop lourde pour un projet solo étudiant.

#### Côté intelligence artificielle

Pour l'analyse d'images, les **API vision cloud** (Gemini, GPT-4 Vision, Claude) produisent des résultats riches avec un coût à l'image. Un **modèle local** type MobileNet serait gratuit hors ligne mais insuffisamment précis sur la catégorie et la couleur sans entraînement dédié. Pour les suggestions d'outfits, un **LLM à chaque requête** apporte de la flexibilité langagière mais avec une latence de plusieurs secondes et un coût récurrent difficile à absorber. Un **moteur de règles en Python** est moins spectaculaire en démo, mais rapide, gratuit et explicable devant le jury.

#### Côté hébergement de l'API

**Vercel** en serverless permet un déploiement par git push avec HTTPS immédiat, mais impose des contraintes sur les traitements lourds (comme la suppression de fond). **Railway** ou **Render** conviennent aux conteneurs long running avec un coût au-delà du gratuit. **Firebase Cloud Functions** rapprochent l'API de Firebase mais sont moins pratiques pour un monolithe FastAPI que je déboguais en local. Un **VPS** offre le contrôle maximal au prix de la maintenance.

---

## 2. Choix des technologies, workflow IA et infrastructure

### 2.1 Les décisions que j'ai retenues

J'ai choisi **Flutter** pour le client mobile, **FastAPI** en Python pour le backend du module PO, **Firestore** en accès direct depuis l'application pour les données courantes, et **Firebase Auth** ainsi que **Storage** pour l'authentification et les fichiers. L'API est hébergée sur **Vercel** ; la vision passe par **Gemini 2.5 Flash** ; les suggestions d'outfits reposent sur un moteur **rule-based** dans `ai_service.py` ; la météo est fournie par **Open-Meteo** sans clé ; la gestion d'état côté Flutter utilise **Riverpod**, que j'ai pu tester avec des fakes.

L'architecture est hybride : le mobile lit et écrit Firestore directement pour le CRUD habituel, tandis que le backend traite les opérations lourdes ou sensibles (IA, redimensionnement d'images, secret Gemini).

### 2.2 Comment j'ai organisé le développement avec l'IA

Plutôt qu'un seul fil de discussion monolithique, j'ai structuré le travail en agents spécialisés dans Cursor : un agent backend pour FastAPI et les routes IA, un agent frontend pour les écrans Flutter, un agent design pour la charte graphique et les contraintes responsive, et un agent données pour Firestore et les règles de sécurité. Tout partait d'un cahier des charges détaillé (Outfit Manager), puis j'intégrais manuellement les livrables, lançais `flutter test` et déployais sur Vercel avant de produire l'APK.

Mon rôle restait central : rédiger et faire évoluer le cahier des charges, valider les merges, corriger les règles Firestore, trancher entre Gemini et GPT, tester sur un appareil à 320 pixels de large, et documenter l'usage de l'IA pour pouvoir l'expliquer clairement au jury.

### 2.3 Des exemples de prompts que j'ai utilisés

Pour cadrer l'architecture globale, j'ai fourni un prompt du type suivant (extrait) :

```
# Application de Gestion de Garde-Robe (Outfit Manager)
## Stack : Python + Firebase
## Navigation : Inspiration | Outfits | Créer | Dressing | Profil
## Outfits : Bibliothèque | Tinder (swipe) | IA (prompt + suggestions)
## Streak minuit, stats visibles au Profil
## Contraintes : responsive 320px, tutoriels compacts, pas de débordement
```

À l'agent backend, j'ai demandé explicitement de créer `POST /api/v1/ai/suggest` protégé par le token Firebase, avec `suggest_outfit()` basé sur les familles de couleurs, un `PROMPT_MAP` en français, une pénalité pour les pièces portées dans les sept derniers jours, et le forçage d'une veste si la météo est froide ou pluvieuse, **sans** appeler de LLM sur cette route.

À l'agent frontend, j'ai ciblé `outfits_screen.dart` avec une TabBar Bibliothèque / Swipe, une sheet IA premium avec champ de prompt et chips de styles, et l'appel à `ApiService.suggestOutfits` enrichi par le contexte météo du jour, en insistant sur l'absence de débordement visuel sur petits écrans.

À l'agent design, j'ai imposé une palette épurée (fond crème, accent terracotta, texte graphite), la police SF Pro Display, des tutoriels compacts et une barre de navigation à quatre onglets avec des libellés courts.

### 2.4 Pourquoi j'ai choisi Gemini pour la vision et des règles pour les suggestions

J'ai séparé deux besoins distincts. Le premier est l'analyse à l'ajout d'un vêtement : une image doit produire un JSON structuré (catégorie, couleurs, marque, style, etc.). Le second est la suggestion matinale : à partir de dix à cinquante pièces, je dois proposer une combinaison cohérente en moins de trois secondes, éventuellement trois variantes.

Pour le premier besoin, **Gemini Flash** en vision offre un rapport qualité/coût favorable, avec une latence de l'ordre de une à trois secondes et un tier gratuit utilisable en phase étudiante. **GPT-4o vision** aurait été plus coûteux à l'image pour un bénéfice marginal sur mon périmètre. Pour le second besoin, un **LLM texte** à chaque matin multiplierait les appels et la latence (trois à huit secondes), ce qui est difficile à tenir à grande échelle. Mon **moteur rule-based** répond en moins de cinq centaines de millisecondes sans coût marginal.

À titre d'ordre de grandeur, deux cents analyses photo par mois restent dans une fourchette de quelques centimes si je dépasse le gratuit, alors que deux cents suggestions via LLM chaque matin représenteraient plusieurs euros **par jour** pour une base active modérée. J'ai donc réservé Gemini à la vision, une fois par vêtement, et j'exploite ensuite les métadonnées stockées via des heuristiques reproductibles.

### 2.5 Firebase, Vercel et répartition des responsabilités

J'ai affecté l'authentification et les profils à **Firebase Auth**, les données temps réel et l'offline à **Firestore**, les images à **Storage**, la logique IA et les secrets à **Vercel** couplé à **FastAPI** (la clé `GEMINI_API_KEY` ne doit jamais se retrouver dans l'APK), le redimensionnement des uploads vêtements au backend Python avec Pillow, et la météo au client via **Open-Meteo**. Le reset du streak à minuit est prévu via une Cloud Function ; aujourd'hui une partie de la logique reste côté client.

Je n'ai pas tout centralisé sur Vercel parce que l'accès direct à Firestore réduit la latence des listes de dressing et d'outfits et simplifie les listeners temps réel. Je n'ai pas tout basculé sur Firebase Functions parce que FastAPI en local, puis sur Vercel, m'a permis de déboguer plus vite le Python pendant le module PO.

### 2.6 Les modèles de facturation que j'ai mis en place et ceux que je prévois

Au-delà du prototype académique, j'ai réfléchi à un modèle économique que je peux faire évoluer en production.

#### UniSaps+ : monétiser l'IA côté utilisateurs

J'ai structuré un abonnement **UniSaps+** qui débloque l'ensemble des fonctionnalités IA. L'offre **mensuelle** est fixée à **un euro par mois** ; l'offre **à vie** est fixée à **cinq euros** en paiement unique, avec le même périmètre fonctionnel mais sans renouvellement.

Ces fonctionnalités réservées comprennent l'analyse automatique lors de l'ajout d'un vêtement (Gemini renseigne nom, marque, couleurs, catégorie, style, saison, motif, matière), la sheet de suggestions d'outfits dans l'onglet Outfits (prompt libre, styles prédéfinis, prise en compte de la météo et de l'historique de port), ainsi que le badge visuel UniSaps+ (anneau sur l'avatar, mention sur les posts).

Techniquement, le champ Firestore `account_tier` distingue déjà `free` et `premium`, et les écrans d'upgrade existent. En développement, l'activation peut passer par un code de test ; en production, je brancherai **Google Play Billing** pour encaisser les tarifs. J'ai choisi ces montants parce que le coût marginal d'une analyse Gemini reste faible : à un euro par mois je couvre l'API tout en restant accessible. Les cinq euros à vie récompensent les premiers utilisateurs et améliorent ma trésorerie au lancement, avec la possibilité de retirer cette offre après une phase d'ouverture pour ne pas cannibaliser l'abonnement mensuel.

#### Comptes Créateur : une seconde ligne de revenus avec les marques

Je prévois d'inviter des **marques de vêtements françaises indépendantes** - créateurs, petites marques, ateliers - par démarchage direct (Instagram, salons, showrooms). Elles disposeraient d'un **compte Créateur**, distinct du compte utilisateur classique, souscrit à un **abonnement mensuel** dont le montant sera calibré selon la taille de la marque (par exemple entre vingt-neuf et quatre-vingt-dix-neuf euros par mois).

En échange, ces marques pourraient publier des **outfits mettant en avant leurs pièces**, présentés comme des posts organiques mais clairement identifiés. Dans le fil **Inspiration**, j'insérerais des **posts sponsorisés** - des « pub posts » - à raison d'environ **un post marque tous les cinq à dix posts** utilisateurs, afin de préserver l'expérience. Chaque publication sponsorisée porterait un badge **Sponsorisé** ou **Partenaire**.

Pour la marque, l'intérêt est une visibilité ciblée auprès d'utilisateurs déjà engagés sur la mode quotidienne (outfit du jour, streak), avec un contenu plus authentique qu'une bannière display. Pour moi, ce modèle apporte des revenus récurrents B2B, diversifie au-delà du euro utilisateur, et enrichit le feed sans que je doive produire moi-même tout le contenu.

Côté technique, je devrai introduire un type de post avec `is_sponsored`, un `brand_id`, un algorithme de mixage du feed au ratio configurable, des règles Firestore limitant la création de pub posts aux comptes créateur validés, ainsi qu'une charte de modération. La V1 commerciale reste centrée sur UniSaps+ ; le programme marques constitue une V2 business que je présenterai en soutenance comme axe de croissance crédible.

---

## 3. Fonctionnalités de l'application

### 3.1 La gestion du dressing

Le dressing est le socle de toute la chaîne de valeur. L'ajout passe par une bottom sheet (`add_garment_sheet.dart`) qui accepte la caméra ou la galerie, avec la possibilité de plusieurs photos par vêtement. La catégorisation peut être saisie manuellement ou préremplie par l'IA lorsque l'utilisateur est premium. Les métadonnées enrichies - tags de style, formalité, saison, motif, matière - sont stockées sur le document Firestore du vêtement. L'écran `dressing_screen.dart` organise l'affichage par catégories ; les images transitent par `POST /api/v1/upload/image` pour être compressées avant d'être référencées dans Firestore.

À ce stade, mon dressing n'est plus seulement une galerie : il devient une base de données que mes algorithmes peuvent exploiter sur la couleur, le style et la saison.

### 3.2 Le choix de l'outfit quotidien

L'onglet Outfits gère deux états. Tant qu'aucun outfit n'est choisi pour la journée, l'utilisateur accède à la bibliothèque (défilement horizontal de tenues filtrées selon la météo et la saison via `today_outfit_context.dart`), au mode swipe (`flutter_card_swiper`), et à la sheet IA réservée aux abonnés. Une fois l'outfit du jour validé, l'écran affiche la tenue en grand, le streak, et la possibilité de prendre une photo qui remplace le visuel de composition et alimente ensuite la galerie du profil.

Le streak repose sur les champs `current_streak` et `best_streak`, avec une vérification à l'ouverture de l'application lorsque la date a changé. Chaque sélection met à jour `times_worn`, `last_worn` et `wear_history`, ce qui alimente le scoring des suggestions sans afficher ces statistiques détaillées dans cet onglet.

### 3.3 Le réseau social Inspiration

Le fil Inspiration propose une vue Explorer et une vue Amis filtrée sur le tableau `friends`. La publication est liée à l'outfit du jour, limitée à **un post par jour**, avec une image issue de la photo du jour ou de la photo de référence de la tenue. Les likes sont gérés de façon atomique sur les champs `liked_by` et `likes` ; le profil de l'auteur peut afficher un badge premium. Le système d'amitié passe par la collection `friend_requests` et une recherche par pseudo.

Ce réseau reste volontairement un cercle de confiance, sans la pression d'un réseau global. Demain, j'y intégrerai un emplacement contrôlé pour les marques partenaires via les pub posts.

### 3.4 Le profil, les statistiques et les paramètres

Le profil agrège des statistiques globales (nombre de vêtements, d'outfits créés, de ports, streak actuel et record) et des statistiques par outfit cohérentes avec le tracking de l'onglet Outfits. La galerie présente chronologiquement les photos archivées. Les paramètres permettent de gérer l'identité, le tier premium et la déconnexion.

### 3.5 Les fonctions transverses

J'ai ajouté des tutoriels à la première visite de chaque onglet, un déverrouillage progressif (Outfits après au moins un vêtement, Inspiration après au moins un outfit), des widgets Android pour consulter l'outfit du jour depuis l'écran d'accueil, et une intégration continue qui lance les tests Flutter à chaque push.

---

## 4. Difficultés rencontrées et versions du projet

### 4.1 Version 1 - Application Python avec Flet

Mon objectif initial était de respecter rapidement l'exigence d'un Python significatif avec une interface unique. J'ai produit des prototypes Flet avec navigation, modèles Python et les prémices du moteur `suggest_outfit`, aujourd'hui migré dans `backend/app/services/ai_service.py` (le fichier mentionne explicitement cette origine).

J'ai rencontré des limites nettes : la bibliothèque de widgets mobiles encore jeune, peu d'équivalents pour le swipe, la caméra ou une bottom navigation stable ; des débordements de texte sur petites largeurs difficiles à corriger finement ; des performances de scroll et d'images inférieures à Flutter ; et un écosystème photo/galerie moins riche.

J'ai donc abandonné la V1 côté interface tout en conservant le Python sur le backend via FastAPI, ce qui me permet de répondre au sujet PO tout en visant une UX mobile crédible.

### 4.2 Version 2 - Migration vers Flutter

La V2 visait un client mobile professionnel avec Firebase natif. J'ai structuré le projet en modèles, services, providers et écrans, intégré Firebase Auth, Firestore et Storage, et organisé la navigation autour de quatre onglets dans `HomeScreen` avec `go_router` pour l'authentification et l'onboarding.

Les difficultés principales ont été l'échec d'une double source de vérité entre API REST et Firestore, que j'ai résolu en adoptant une approche Firestore-first pour le CRUD ; la configuration Firebase (`google-services.json`, `flutterfire configure`, empreintes SHA1 debug et release) ; et la gestion des URL d'API entre l'émulateur Android (`10.0.2.2`), le web local et la production sur `unisaps.vercel.app`.

### 4.3 Version 3 - API IA et fonctionnalités intelligentes

#### Analyse à l'ajout d'un vêtement

Lorsqu'un utilisateur premium active l'analyse IA dans `add_garment_sheet.dart`, l'image est lue en bytes et envoyée via `ApiService.analyzeGarmentImage()`. Le backend appelle `analyze_garment_image()` avec Gemini 2.5 Flash et un prompt imposant un JSON strict. Le client gère l'enveloppe éventuelle `json`, valide `is_garment`, fusionne les champs dans le formulaire, ou retire la photo et affiche un dialogue si la pièce n'est pas vestimentaire. En cas de réponse vide, un retry automatique limite les échecs liés à la saturation de l'API ou à une image peu lisible.

J'ai veillé à ne jamais exposer `GEMINI_API_KEY` dans l'APK, à aligner la palette de couleurs du prompt sur `color_service.dart`, et à limiter les analyses répétées dans une même session via `_garmentAiAnalysisConsumed`.

#### Création dynamique d'outfits

Dans `outfits_screen.dart`, l'utilisateur ouvre la sheet IA, saisit par exemple « look professionnel » ou choisit un style prédéfini. Le `todayOutfitContextProvider` fournit la saison et les tags météo issus d'Open-Meteo. L'appel `ApiService.suggestOutfits` déclenche `POST /api/v1/ai/suggest` ; le backend charge les vêtements et outfits de l'utilisateur authentifié, puis `suggest_multiple()` résout le style via `PROMPT_MAP`, score chaque pièce, pénalise celles portées récemment, force une outerwear si nécessaire, et tire au sort parmi le haut du classement pour conserver de la variété. Le client affiche trois propositions ; un tap applique les identifiants aux zones et permet d'enregistrer la tenue.

Les difficultés de cette version concernent surtout le JSON Gemini parfois invalide (j'ai ajouté une extraction par regex et une température basse), le temps d'attente perçu (indicateur `biblioAiLoadingProvider`), et la nécessité d'expliquer en soutenance que les suggestions ne passent pas par un LLM malgré le vocabulaire « IA ».

### 4.4 Version 4 - Refonte de l'interface

Les fonctionnalités étaient en place, mais l'interface faisait encore prototype : débordements, hiérarchie visuelle faible, cohérence insuffisante. J'ai introduit un design system (`AppColors`, `AppTheme` Material 3, fond crème, accent terracotta, typographie SF Pro Display), respecté les contraintes du sujet (libellés courts, tutoriels limités en hauteur, TabBar dans Outfits), et polishé les sheets, ombres, snackbars flottants et loaders sur les feeds. Côté premium, j'ai soigné l'anneau avatar, la sheet IA et l'écran UniSaps+ avec le modèle tarifaire un euro par mois ou cinq euros à vie prêt pour le store.

Le résultat est une application que je peux présenter en démo orale d'environ cinq minutes avec un parcours fluide pour Léa, Karim et Sophie.

### 4.5 Autres difficultés transverses

La suppression de fond via `rembg` est trop lourde pour Vercel : je l'ai désactivée en production au profit d'un upload simple. Le reset du streak à minuit repose encore en partie sur la logique client alors que l'endpoint `daily-check` n'est pas branché. Je n'ai pas encore de tests widget ou E2E, mais quatorze fichiers de tests unitaires couvrent modèles et providers. La suppression de compte ne purge pas encore toutes les sous-collections Firestore, ce que j'ai documenté comme limite.

---

## 5. Conclusion

**uniSaps** est parti de mon constat quotidien - mieux exploiter ma garde-robe - et a traversé quatre itérations : prototype Python Flet, client Flutter, couche IA combinant Gemini et un moteur de règles, puis refonte UX. L'architecture que j'ai retenue, Flutter plus Firestore plus FastAPI sur Vercel, équilibre l'expérience mobile, les exigences du module PO et des coûts IA maîtrisés.

Ce projet m'a permis de modéliser des données vestimentaires et des règles métier explicites, d'enchaîner vision, attributs et recommandation sans tout déléguer à une boîte noire, et de mettre en place une chaîne légère de CI, déploiement serverless et règles Firestore. Il m'a aussi obligé à réfléchir à un modèle économique concret : UniSaps+ à un euro par mois ou cinq euros à vie, puis des comptes Créateur pour des marques françaises indépendantes avec des pub posts natifs dans Inspiration.

Si je devais recommencer, je démarrerais directement en Flutter et FastAPI pour gagner plusieurs semaines, je brancherais une Cloud Function de reset dès la V2, et j'ajouterais des tests d'intégration sur le flux complet ajout de vêtement, suggestion, outfit du jour et publication.

Mes prochaines étapes sont le finalisation de l'encaissement Play Store pour les offres à un et cinq euros, le pilotage de deux ou trois marques partenaires en bêta avec un ratio d'un pub post pour dix posts organiques, et l'affinement de la fonction `_score()` en exploitant les swipes comme signal implicite de préférence.

---

*Rapport destiné à la soutenance orale (20 à 25 minutes) et au dossier technique du module PO.*