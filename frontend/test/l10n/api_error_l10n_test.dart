import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/l10n/api_error_l10n.dart';
import 'package:unisaps/l10n/generated/app_localizations_en.dart';
import 'package:unisaps/l10n/generated/app_localizations_fr.dart';

void main() {
  test('maps known error codes in FR and EN', () {
    final fr = AppLocalizationsFr('fr');
    final en = AppLocalizationsEn('en');
    expect(apiErrorL10n(fr, 'garment_not_found'), fr.apiGarmentNotFound);
    expect(apiErrorL10n(en, 'garment_not_found'), en.apiGarmentNotFound);
    expect(apiErrorL10n(fr, 'unknown_code'), fr.apiUnknownError);
  });

  test('parseApiErrorCode extracts code from JSON detail', () {
    expect(
      parseApiErrorCode('Exception: {"detail":{"error_code":"post_not_found"}}'),
      'post_not_found',
    );
  });
}
