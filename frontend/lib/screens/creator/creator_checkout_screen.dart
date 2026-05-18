import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/creator_subscription.dart';
import '../../providers/auth_provider.dart';

class CreatorCheckoutScreen extends ConsumerStatefulWidget {
  const CreatorCheckoutScreen({super.key});

  @override
  ConsumerState<CreatorCheckoutScreen> createState() =>
      _CreatorCheckoutScreenState();
}

class _CreatorCheckoutScreenState extends ConsumerState<CreatorCheckoutScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (!isCreatorActivationCodeValid(_codeController.text)) {
      setState(() => _error = 'Code d\'activation invalide.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final isAuth = ref.read(authStateProvider).valueOrNull != null;
      if (!isAuth) {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        if (email.isEmpty || password.length < 6) {
          setState(() {
            _error = 'Email et mot de passe (6 car. min.) requis.';
            _loading = false;
          });
          return;
        }
        final ok = await ref
            .read(authNotifierProvider.notifier)
            .signUp(email, password);
        if (!ok) {
          final err = ref.read(authNotifierProvider).error;
          setState(() {
            _error = err is FirebaseAuthException
                ? err.message
                : 'Inscription impossible.';
            _loading = false;
          });
          return;
        }
      }

      await ref.read(authNotifierProvider.notifier).activateCreatorSubscriptionStub();

      if (!mounted) return;
      context.go('/creator/onboarding');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = ref.watch(authStateProvider).valueOrNull != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Abonnement marque', style: AppTextStyles.heading1.copyWith(fontSize: 26)),
              const SizedBox(height: 8),
              Text(
                kCreatorMonthlyPriceLabel,
                style: AppTextStyles.heading2.copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: 8),
              const Text(
                'Paiement simulé en développement. Saisis le code d\'activation pour activer ton espace.',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 28),
              if (!isAuth) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email professionnel'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Mot de passe'),
                ),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  hintText: 'Code d\'activation',
                  prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _activate,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Activer mon espace marque'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
