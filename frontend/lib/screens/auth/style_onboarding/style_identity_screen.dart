import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/l10n_context.dart';
import '../../../models/style_profile.dart';
import '../../../providers/style_onboarding_draft_provider.dart';
import '../../../widgets/style_profile_form.dart';

class StyleIdentityScreen extends ConsumerWidget {
  const StyleIdentityScreen({super.key});

  Future<void> _skipStep(BuildContext context, WidgetRef ref) async {
    final current = ref.read(styleOnboardingDraftProvider);
    final merged = StyleProfile(
      goalWardrobe: current.goalWardrobe,
      goalInspiration: current.goalInspiration,
      goalRefineStyle: current.goalRefineStyle,
      goalTrackWear: current.goalTrackWear,
      identityStyle: 'casual',
      audacity: 3,
      fashionComfort: current.fashionComfort,
      updatedAt: current.updatedAt,
    );
    ref.read(styleOnboardingDraftProvider.notifier).state = merged;
    if (context.mounted) context.go('/onboarding/style/comfort');
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
            value: 2 / 3,
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
                showComfort: false,
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
                    onPressed: () => context.go('/onboarding/style/comfort'),
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
