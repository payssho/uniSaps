import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/l10n_context.dart';
import '../../../widgets/onboarding_progress_bar.dart';
import '../../../providers/style_onboarding_draft_provider.dart';
import '../../../widgets/style_profile_form.dart';

class StyleExtraScreen extends ConsumerWidget {
  const StyleExtraScreen({super.key});

  void _skipStep(WidgetRef ref) {
    final current = ref.read(styleOnboardingDraftProvider);
    ref.read(styleOnboardingDraftProvider.notifier).state = current.copyWith(
      preferredStyles: const [],
      usageFrequency: 'weekly',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(styleOnboardingDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.styleExtraTitle),
        bottom: const OnboardingProgressBar(step: 4, total: 5),
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
                showComfort: false,
                showPreferredStyles: true,
                showUsageFrequency: true,
                onChanged: (p) =>
                    ref.read(styleOnboardingDraftProvider.notifier).state = p,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _skipStep(ref);
                      context.go('/onboarding/style/social');
                    },
                    child: Text(l10n.styleOnboardingSkip),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => context.go('/onboarding/style/social'),
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
