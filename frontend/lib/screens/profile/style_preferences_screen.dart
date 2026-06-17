import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n_context.dart';
import '../../models/style_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/style_profile_provider.dart';
import '../../widgets/style_profile_form.dart';
import '../auth/style_onboarding/style_onboarding_finalize.dart';

class StylePreferencesScreen extends ConsumerStatefulWidget {
  const StylePreferencesScreen({super.key});

  @override
  ConsumerState<StylePreferencesScreen> createState() =>
      _StylePreferencesScreenState();
}

class _StylePreferencesScreenState extends ConsumerState<StylePreferencesScreen> {
  StyleProfile? _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    _draft = user?.styleProfile ?? StyleProfile.defaults();
  }

  Future<void> _save() async {
    if (_draft == null) return;
    setState(() => _saving = true);
    final profile = finalizeStyleProfile(_draft!);
    await ref.read(styleProfileNotifierProvider).save(profile);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  void _reset() {
    setState(() => _draft = StyleProfile.defaults(skipped: false));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = _draft;
    if (draft == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.styleSettingsTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StyleProfileForm(
                profile: draft,
                showSocialIntent: false,
                showPreferredStyles: true,
                showUsageFrequency: true,
                onChanged: (p) => setState(() => _draft = p),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _saving ? null : _reset,
                child: Text(l10n.styleSettingsReset),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.styleSettingsSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
