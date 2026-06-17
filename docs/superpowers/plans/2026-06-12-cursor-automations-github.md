# Cursor Automations GitHub — uniSaps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configurer deux Cursor Automations sur le repo `payssho/uniSaps` : (1) triage quand la CI GitHub échoue sur une PR, (2) checklist courte quand le label `ready-for-review` est ajouté — en minimisant la consommation de tokens.

**Architecture:** La CI existante (`.github/workflows/flutter_tests.yml`) reste la source de vérité pour `flutter analyze` + `flutter test`. Les automations Cursor ne relancent pas les tests ; elles interprètent l’échec ou font une revue ciblée sur signal manuel. Prompts courts (≤120–150 mots), pas de MCP, modèle léger si disponible.

**Tech Stack:** GitHub Actions, Cursor Automations (trigger Git), repo Flutter + FastAPI/Firestore.

---

## Contexte repo

| Élément | Valeur |
|---------|--------|
| Repo | `payssho/uniSaps` |
| Branche par défaut | `main` |
| Workflow CI | `.github/workflows/flutter_tests.yml` (`Tests Flutter`) |
| Jobs | `flutter pub get`, `flutter analyze`, `flutter test` dans `frontend/` |

---

## Fichiers / ressources concernés (lecture agent)

L’automation #2 doit prioriser ces zones si modifiées dans la PR :

- `firestore.rules`
- `frontend/lib/providers/auth_provider.dart`
- `frontend/lib/core/routes/app_router.dart`
- `frontend/lib/screens/creator/**`
- `frontend/lib/providers/post_provider.dart`
- `frontend/lib/utils/feed_mix.dart`
- `backend/app/services/ai_service.py`
- `backend/app/api/routes/creator.py`

---

### Task 1 : Label GitHub `ready-for-review`

**Files:** Aucun fichier repo (configuration GitHub)

- [ ] **Step 1 : Créer le label**

```bash
gh label create "ready-for-review" --repo payssho/uniSaps --color 0E8A16 --description "PR prête pour revue agent / merge"
```

Si le label existe déjà, ignorer l’erreur.

- [ ] **Step 2 : Vérifier**

```bash
gh label list --repo payssho/uniSaps | findstr ready-for-review
```

Expected: une ligne contenant `ready-for-review`

---

### Task 2 : Automation #1 — CI échouée (triage)

**Nom suggéré :** `uniSaps — CI failed triage`

**Trigger (éditeur Cursor) :** GitHub → **Checks completed** / **CI completed** sur le repo `payssho/uniSaps`, PR uniquement. **Filtrer sur échec** si l’éditeur le propose (`failure` / `conclusion: failure`).

**Tools :** Commentaire sur PR (`prComment`) — optionnel mais utile pour voir le résultat sur la PR.

**Modèle :** le plus léger / économique disponible.

**Memory :** désactivée.

**Prompt (copier-coller) :**

```
Le workflow GitHub "Tests Flutter" a échoué sur cette PR (payssho/uniSaps).

Contexte fourni : extrait du log CI + liste des fichiers modifiés dans la PR.

Tâche :
1. Identifie la cause la plus probable (analyze vs test vs dépendances).
2. Cite le fichier ou test concerné si visible dans le log.
3. Propose UNE action corrective concrète.

Contraintes :
- Maximum 120 mots.
- Pas de refactor global, pas de réécriture de code complète.
- Si le log est insuffisant, dis exactement quelle info manque (1 phrase).
```

- [ ] **Step 1 :** Ouvrir l’éditeur Automations avec le brouillon prérempli (agent ou manuel).
- [ ] **Step 2 :** Vérifier repo `payssho/uniSaps` et filtre **échec uniquement**.
- [ ] **Step 3 :** Enregistrer l’automation.
- [ ] **Step 4 : Test** — Ouvrir une PR de test, introduire une erreur volontaire (ex. test cassé), pousser, attendre CI rouge, vérifier qu’un run agent se déclenche et que le commentaire est court.

---

### Task 3 : Automation #2 — Label `ready-for-review`

**Nom suggéré :** `uniSaps — PR ready checklist`

**Trigger :** GitHub → **Label added** sur PR, label = `ready-for-review`, repo `payssho/uniSaps`.

**Tools :** Commentaire sur PR (`prComment`).

**Modèle :** léger.

**Memory :** désactivée.

**Prompt (copier-coller) :**

```
Label ready-for-review ajouté sur cette PR uniSaps.

Revue ciblée AVANT merge. Ne relance pas les tests (la CI GitHub s'en charge).

Si ces chemins sont modifiés, vérifie-les en priorité :
- firestore.rules (lecture/écriture, compte creator vs user)
- frontend/lib/providers/auth_provider.dart et app_router.dart (redirects creator)
- frontend/lib/screens/creator/** et post_provider / feed_mix (posts sponsorisés)
- backend/app/services/ai_service.py et routes creator (garde premium, pas de fuite)

Réponds en checklist de 5 bullets maximum :
1. Risque régression compte utilisateur classique
2. Risque sécurité Firestore
3. Tests manquants évidents
4. Impact déploiement (Vercel / index Firestore)
5. Go / no-go merge (1 phrase)

Contraintes : pas de code, max 150 mots.
```

- [ ] **Step 1 :** Créer la 2e automation dans l’éditeur.
- [ ] **Step 2 :** Confirmer trigger = **ajout** du label (pas suppression).
- [ ] **Step 3 :** Enregistrer.
- [ ] **Step 4 : Test** — Sur une PR où la CI est verte, ajouter le label `ready-for-review`, vérifier un seul run et un commentaire checklist.

---

### Task 4 : Garde-fous coût tokens

- [ ] Ne pas créer d’automation sur merge/push/open PR.
- [ ] Ne pas activer MCP Slack/Notion sauf besoin futur.
- [ ] Retirer le label `ready-for-review` puis le remettre ne doit pas être nécessaire ; en cas de double run, restreindre le trigger à **label added** uniquement.

---

## Self-review

| Exigence | Task |
|----------|------|
| CI failed triage | Task 2 |
| ready-for-review checklist | Task 1 + Task 3 |
| Minimiser tokens | Task 4 + prompts limités |
| Repo GitHub + CI PR | Contexte + tests |

---

## Exécution

Configuration manuelle dans Cursor Automations (pas de code repo à merger). Suivre Task 1 → 2 → 3 → 4 dans l’ordre.
