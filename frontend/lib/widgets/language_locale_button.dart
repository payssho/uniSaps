import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../l10n/l10n_context.dart';
import '../providers/locale_provider.dart';

/// Feuille de choix FR / EN.
class LanguageLocalePicker {
  LanguageLocalePicker._();

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    var selected = ref.read(localeProvider).locale.languageCode;
    if (selected != 'en') selected = 'fr';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> apply(Locale locale) async {
              await ref.read(localeProvider.notifier).setLocale(locale);
              if (ctx.mounted) Navigator.pop(ctx);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  l10n.settingsLanguage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _LocaleOption(
                  label: l10n.settingsLanguageFrench,
                  selected: selected == 'fr',
                  onTap: () {
                    setModalState(() => selected = 'fr');
                    apply(const Locale('fr'));
                  },
                ),
                const SizedBox(height: 10),
                _LocaleOption(
                  label: l10n.settingsLanguageEnglish,
                  selected: selected == 'en',
                  onTap: () {
                    setModalState(() => selected = 'en');
                    apply(const Locale('en'));
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Tuile langue (onglet Compte du profil).
class LanguageLocaleAccountTile extends ConsumerWidget {
  const LanguageLocaleAccountTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final code = ref.watch(localeProvider).locale.languageCode;
    final value = code == 'en'
        ? l10n.settingsLanguageEnglish
        : l10n.settingsLanguageFrench;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => LanguageLocalePicker.show(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.75)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.language_rounded,
                size: 20,
                color: AppColors.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsLanguage,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.accent.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocaleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LocaleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.12)
          : AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.accent
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
