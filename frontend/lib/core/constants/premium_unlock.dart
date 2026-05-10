/// Déblocage UniSaps+ depuis Paramètres → Infos (sans passer par Firestore manuel).
///
/// Forme affichée conseillée : `USAPS-PREM-2026-XK9`
/// La validation ignore espaces, tirets et underscores (majuscules indifférentes).
const String kPremiumUnlockSecretNormalized = 'USAPSPREM2026XK9';

bool isPremiumUnlockCodeValid(String input) {
  final n =
      input.toUpperCase().replaceAll(RegExp(r'[\s\-_]'), '');
  return n == kPremiumUnlockSecretNormalized;
}
