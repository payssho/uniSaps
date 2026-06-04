import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/l10n_context.dart';
import '../../../models/style_profile.dart';
import '../../../providers/style_onboarding_draft_provider.dart';
import '../../../providers/style_profile_provider.dart';
import '../../../widgets/style_profile_form.dart';

class StyleGoalsScreen extends ConsumerWidget {
  const StyleGoalsScreen({super.key});

  Future<void> _skipAll(BuildContext context, WidgetRef ref) async {
    final profile = StyleProfile.defaults(skipped: true);
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
        actions: [
          TextButton(
            onPressed: () => _skipAll(context, ref),
            child: Text(l10n.styleOnboardingSkipAll),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StyleProfileForm(
                profile: draft,
                showIdentity: false,
                showComfort: false,
                onChanged: (p) =>
                    ref.read(styleOnboardingDraftProvider.notifier).state = p,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _skipAll(context, ref),
                    child: Text(l10n.styleOnboardingSkip),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => context.go('/onboarding/style/identity'),
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
