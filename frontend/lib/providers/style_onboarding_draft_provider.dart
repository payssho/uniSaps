import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/style_profile.dart';

final styleOnboardingDraftProvider =
    StateProvider<StyleProfile>((ref) => StyleProfile.defaults());
