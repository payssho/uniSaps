import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incrémenté pour demander l’onglet Infos du profil (UniSaps+).
final profileInfosTabRequestProvider = StateProvider<int>((ref) => 0);
