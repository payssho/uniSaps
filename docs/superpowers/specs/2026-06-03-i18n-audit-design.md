# Audit i18n uniSaps — Design

**Date:** 2026-06-03  
**Statut:** Approuvé (brainstorming)

## Objectif

Couvrir 100 % des textes système de l’app en FR/EN : UI, messages système, enums dynamiques et erreurs API. Le contenu utilisateur/créateur (bio, légendes) reste affiché tel quel.

## Décisions

| Sujet | Choix |
|-------|-------|
| Périmètre | UI + système + dynamique app |
| Contenu UGC | Pas de traduction |
| Erreurs API | `error_code` backend → `context.l10n` Flutter |
| Priorisation | Audit complet, corrections par lots |

## Architecture cible

- **Source de vérité traductions :** `frontend/tool/gen_arb.py` → `app_fr.arb` / `app_en.arb` → `flutter gen-l10n`
- **Usage UI :** `context.l10n.*` via `lib/l10n/l10n_context.dart`
- **Dynamique :** `lib/l10n/domain_l10n.dart` (catégories, couleurs, météo, styles…)
- **Erreurs API :** `backend/app/core/errors.py` + `lib/l10n/api_error_l10n.dart`
- **Anti-régression :** `frontend/tool/check_hardcoded_strings.py` en CI

## Approche retenue

**Approche 3 — Hybride :** inventaire automatisé → câblage clés ARB existantes (566 clés) → nouvelles clés → migration backend → CI.

## Hors scope

- Traduction automatique ou multilingue du contenu utilisateur
- Langues au-delà de FR/EN
