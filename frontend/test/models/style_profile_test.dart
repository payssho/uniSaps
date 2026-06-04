import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/models/style_profile.dart';

void main() {
  test('defaults when skipped sets onboardingSkipped', () {
    final p = StyleProfile.defaults(skipped: true);
    expect(p.goalWardrobe, 3);
    expect(p.identityStyle, 'casual');
    expect(p.onboardingSkipped, true);
  });
}
