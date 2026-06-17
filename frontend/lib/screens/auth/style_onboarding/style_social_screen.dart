import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/l10n_context.dart';
import '../../../widgets/onboarding_progress_bar.dart';
import '../../../providers/style_onboarding_draft_provider.dart';
import '../../../providers/style_profile_provider.dart';
import '../../../widgets/style_profile_form.dart';
import 'style_onboarding_finalize.dart';

class StyleSocialScreen extends ConsumerWidget {
  const StyleSocialScreen({super.key});

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(styleOnboardingDraftProvider);
    final profile = finalizeStyleProfile(draft);
    await ref.read(styleProfileNotifierProvider).saveWithSocialIntent(profile);
    if (context.mounted) context.go('/home');
  }

  Future<void> _skipStep(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(styleOnboardingDraftProvider);
    final profile = finalizeStyleProfile(
      draft.copyWith(socialIntent: 'undecided'),
    );
    await ref.read(styleProfileNotifierProvider).saveWithSocialIntent(profile);
    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(styleOnboardingDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.styleOnboardingTitle),
        bottom: const OnboardingProgressBar(step: 5, total: 5),
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
                showSocialIntent: true,
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
