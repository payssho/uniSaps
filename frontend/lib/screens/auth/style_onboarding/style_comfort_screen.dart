import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/l10n_context.dart';
import '../../../models/style_profile.dart';
import '../../../providers/style_onboarding_draft_provider.dart';
import '../../../providers/style_profile_provider.dart';
import '../../../widgets/style_profile_form.dart';

class StyleComfortScreen extends ConsumerWidget {
  const StyleComfortScreen({super.key});

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(styleOnboardingDraftProvider);
    final profile = StyleProfile(
      goalWardrobe: draft.goalWardrobe,
      goalInspiration: draft.goalInspiration,
      goalRefineStyle: draft.goalRefineStyle,
      goalTrackWear: draft.goalTrackWear,
      identityStyle: draft.identityStyle,
      audacity: draft.audacity,
      fashionComfort: draft.fashionComfort,
      onboardingSkipped: false,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await ref.read(styleProfileNotifierProvider).save(profile);
    if (context.mounted) context.go('/home');
  }

  Future<void> _skipStep(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(styleOnboardingDraftProvider);
    final profile = StyleProfile(
      goalWardrobe: draft.goalWardrobe,
      goalInspiration: draft.goalInspiration,
      goalRefineStyle: draft.goalRefineStyle,
      goalTrackWear: draft.goalTrackWear,
      identityStyle: draft.identityStyle,
      audacity: draft.audacity,
      fashionComfort: 'balanced',
      onboardingSkipped: false,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await ref.read(styleProfileNotifierProvider).save(profile);
    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(styleOnboardingDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.styleOnboardingTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 1.0,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            backgroundColor: AppColors.accent.withOpacity(0.2),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StyleProfileForm(
                profile: draft,
                showGoals: false,
                showIdentity: false,
                onChanged: (p) =>
                    ref.read(styleOnboardingDraftProvider.notifier).state = p,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _skipStep(context, ref),
                    child: Text(l10n.styleOnboardingSkip),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _finish(context, ref),
                    child: Text(l10n.styleOnboardingContinue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
