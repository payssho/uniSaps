import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/models/style_profile.dart';
import 'package:unisaps/screens/auth/style_onboarding/style_onboarding_finalize.dart';

void main() {
  test('finalizeStyleProfile fills preferred_styles from identity', () {
    final draft = StyleProfile(identityStyle: 'streetwear', goalRefineStyle: 5);
    final out = finalizeStyleProfile(draft);
    expect(out.preferredStyles, ['streetwear']);
    expect(out.archetype, 'apprenti_style');
    expect(out.updatedAt, isNotEmpty);
  });

  test('finalizeStyleProfile keeps explicit preferred_styles', () {
    final draft = StyleProfile(
      preferredStyles: const ['classic', 'minimal'],
      goalWardrobe: 5,
    );
    final out = finalizeStyleProfile(draft);
    expect(out.preferredStyles, ['classic', 'minimal']);
    expect(out.archetype, 'gestionnaire');
  });
}
