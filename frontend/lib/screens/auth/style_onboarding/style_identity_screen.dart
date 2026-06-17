import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/l10n_context.dart';
import '../../../widgets/onboarding_progress_bar.dart';
import '../../../providers/style_onboarding_draft_provider.dart';
import '../../../widgets/style_profile_form.dart';

class StyleIdentityScreen extends ConsumerWidget {
  const StyleIdentityScreen({super.key});

  void _skipStep(WidgetRef ref) {
    final current = ref.read(styleOnboardingDraftProvider);
    ref.read(styleOnboardingDraftProvider.notifier).state = current.copyWith(
      identityStyle: 'casual',
      audacity: 3,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(styleOnboardingDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.styleOnboardingTitle),
        bottom: const OnboardingProgressBar(step: 2, total: 5),
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
                    onPressed: () {
                      _skipStep(ref);
                      context.go('/onboarding/style/comfort');
                    },
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
