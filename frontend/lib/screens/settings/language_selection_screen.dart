import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_provider.dart';

/// Premier lancement : choix FR / EN avant le flux auth.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    final current = ref.read(localeProvider).locale.languageCode;
    _selected = current == 'en' ? 'en' : 'fr';
  }

  Future<void> _continue() async {
    final locale = Locale(_selected);
    await ref
        .read(localeProvider.notifier)
        .completeFirstLaunchChoice(locale);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                l10n.languageSelectionTitle,
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.languageSelectionSubtitle,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _LanguageOption(
                label: l10n.languageFrench,
                selected: _selected == 'fr',
                onTap: () => setState(() => _selected = 'fr'),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: l10n.languageEnglish,
                selected: _selected == 'en',
                onTap: () => setState(() => _selected = 'en'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _continue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.languageContinue,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.12)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                    fontSize: 17,
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
