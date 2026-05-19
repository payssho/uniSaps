import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sous-onglet Inspo visible : `false` = Amis, `true` = Explorer.
final inspirationExplorerVisibleProvider = StateProvider<bool>((ref) => false);

/// Injecte des posts sponsorisés factices dans le fil Explorer (bouton à côté de la recherche).
final exploreDevMockPostsEnabledProvider = StateProvider<bool>((ref) => false);
