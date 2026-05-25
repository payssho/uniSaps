/// Tarif affiché (MVP — stub, pas de paiement réel).
const String kCreatorMonthlyPriceLabel = '\$29 / month';

/// Code d’activation développement (normalisé sans espaces, majuscules).
const String kCreatorActivationCodeNormalized = 'CREATOR2026';

bool isCreatorActivationCodeValid(String input) {
  final n = input.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  return n == kCreatorActivationCodeNormalized;
}

/// Durée d’abonnement simulée après activation.
const Duration kCreatorStubSubscriptionDuration = Duration(days: 30);
