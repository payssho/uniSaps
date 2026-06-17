import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/personalization_config.dart';
import 'auth_provider.dart';

final personalizationProvider = Provider<PersonalizationConfig>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return PersonalizationConfig.fromProfile(user?.styleProfile);
});
