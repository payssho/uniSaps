# uniSaps — Rapport de projet

**Gestionnaire de garde-robe numérique** — Application mobile Flutter + API FastAPI, bêta Google Play ; backend déployé sur Vercel.

---

## 1. Introduction

**uniSaps** permet d’**organiser son dressing**, de **composer des tenues**, de **suivre ses habitudes** (outfit du jour, streaks) et de **partager de l’inspiration** dans un fil social intégré.

Le problème adressé : la dispersion entre photos personnelles et réseaux sociaux complique la **mémoire de ce que l’on possède** et la **construction d’assocations cohérentes**. uniSaps centralise catalogue, ensembles, sélection quotidienne et diffusion dans une **expérience mobile unifiée**, avec une couche optionnelle **Premium** (analyse IA des vêtements, suggestions d’outfits).

Objectifs initiaux : authentification fiable, données et images scalable, première **livraison Android**, base extensible pour l’IA et le social.

---

## 2. Analyse de l’existant

**Marché.** Les usages courants mélangent inspiration pure (Instagram, Pinterest) et apps garde-robe souvent fermées ou segmentées sans social intégré au même niveau.

**Référentiel.** Le dossier `_legacy` conserve un ancien prototypage (Flet) : il montre une approche exploratoire, remplacée par **Flutter + API REST** pour performance mobile, ergonomie native et séparation données / métier.

**Synthèse.** Une stack mobile **Flutter + Firebase** avec un backend **FastAPI stateless** (JWT Firebase) optimise time-to-market et scalabilité sans imposer tout de suite une base SQL relationnelle.

---

## 3. Choix techniques

| Domaine | Technologie | Rôle |
|--------|-------------|------|
| Mobile | Flutter, Riverpod, go_router | UI, état, navigation |
| Identité | Firebase Auth | Sessions, tokens Bearer vers l’API |
| Données | Cloud Firestore | Utilisateurs, vêtements, outfits, posts, amitiés |
| Media | Firebase Storage | Images garments, outfits, profils, posts |
| Backend | FastAPI (Python), Vercel | Upload réservé au serveur, IA, santé `/health` |
| IA vision | Google Gemini | Analyse de photo vestimentaire côté API |
| Suggestions outfits | Backend (règles + IA selon évolution) | Découple l’interface des règles |
| Publication | Play Store (AAB) | Bêta / production |

---

## 4. Fonctionnalités

- **Dressing** : photos multiples, catégories, couleurs, marque ; métadonnées (tags, formalité, saison, matière, etc.).
- **Créations** : composition par slots (zones du corps).
- **Outfits** : bibliothèque, carte à swiper, sélection « du jour », suggestions IA présentées de façon visuelle.
- **Profil** : stats, streak, infos, **tier free/Premium**, codes de déblocage premium.
- **Amitié** : demandes, liste, compte privé ; **pastilles rouges** Profil et Amis pour alertes sans surcharger la barre principale.
- **Inspiration** : flux de posts avec likes ; signaux Premium sur le contenu.
- **Sécurité flux images** : upload via API avec token utilisateur ; affichage adapté Firebase Storage avec cache.

---

## 5. V1 — Première vague livrée

Focused **boucle valeur** : inscription / connexion, ajout catalogue, création ensembles, sélection jour, profil basique ; API upload + santé ; build Android permettant test terrain. MVP sans social avancé ni monétisation.

---

## 6. V2 — Prolongements actuels

- Inspiration **sociale** (posts, likes).
- **Relations** ami / demandes / vie privée.
- **Monétisation fonctionnelle** : `account_tier`, dialogs upgrade, quotas IA Premium.
- **Qualité prod** : correction pipelines upload (MIME, retries, stratégie bucket), synchronisation utilisateur avant appels IA trop tôt pour éviter comportements instantanés vides ; versionnement et tags releases Play.

---

## 7. Problèmes rencontrés et enseignements

1. **403 Forbidden uploads** — souvent liaison **GCP Storage** : IAM du compte de service, buckets à accès uniforme (pas d’ACL `make_public`), **Content-Type `image/jpeg`**. À traiter infra + défenses applicatives (retries).

2. **IA « inactive » ~1 s** — **race condition** : `account_tier` chargé après le premier coup d’œil Premium → aucun appel API. Attendre le flux Firestore ou afficher état neutre évite cette confusion.

3. **Serverless timing** — cold starts Vercel + traitement images : timeouts côté client à **calibrer** ; éviter timeouts trop courts après `multipart/send`.

4. **Contraintes Vercel** — rembg lourd désactivé en prod tel que documenté dans le projet ; garder UX alignée avec la réalité d’infra (resize JPEG, pas de détourage lourd hors machine locale).

Enseignement transversal : **observabilité** (logs Vercel + messages utilisateur digestes) lorsque plusieurs fournisseurs (Firebase + GCS + Gemini) sont en chaîne.

---

## 8. Conclusions

uniSaps illustre un **passage MVP → produit distribué** avec stack cohérente : mobile Dart, données serverless Firebase, computes Python pour usages sensibles budget / secret.

Pour la suite naturelle : iOS homologue, métriques d’usage store, poursuite optimisation **-fiabilité upload** et **résilience IA** (timeouts, quotas, wording).

---

*Rédigé d’après le dépôt uniSaps (README, arborescence, évolutions codebase).*
