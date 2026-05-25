import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/l10n_context.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _creatorIntroPageController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _loading = false;
  int _creatorIntroPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _creatorIntroPageController = PageController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _creatorIntroPageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = l10n.authFillAllFields);
      return;
    }
    if (password.length < 6) {
      setState(() => _error = l10n.authPasswordTooShort);
      return;
    }
    if (password != confirm) {
      setState(() => _error = l10n.authPasswordsMismatch);
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });
    final success = await ref.read(authNotifierProvider.notifier).signUp(email, password);
    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        context.go('/onboarding');
      } else {
        final state = ref.read(authNotifierProvider);
        setState(() => _error = state.error?.toString() ?? l10n.authSignupError);
      }
    }
  }

  static const _hPad = 32.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 0),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textHint,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: [
                  Tab(text: l10n.authTabNormalAccount),
                  Tab(text: l10n.authTabCreatorAccount),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNormalTab(context),
                  _buildCreatorTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalTab(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            l10n.authSignupCreateAccount,
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.authSignupJoin,
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: l10n.authEmail,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: l10n.authPassword,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmController,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSignup(),
            decoration: InputDecoration(
              hintText: l10n.authConfirmPassword,
              prefixIcon: const Icon(Icons.lock_outlined, size: 22),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleSignup,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : Text(l10n.authSignupSubmit),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.authAlreadyHaveAccount,
                  style: AppTextStyles.bodySecondary),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.authGoLogin),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCreatorTab(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final innerW = constraints.maxWidth;
          final innerH = constraints.maxHeight;
          return SizedBox(
            height: innerH,
            width: innerW,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: innerW,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 28),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            blurRadius: 24,
                            spreadRadius: -2,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: AppColors.scrimLight,
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned(
                              top: -36,
                              right: -44,
                              child: IgnorePointer(
                                child: Container(
                                  width: 152,
                                  height: 152,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.accent.withValues(alpha: 0.2),
                                        AppColors.primary.withValues(alpha: 0.06),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.42, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -28,
                              left: -36,
                              child: IgnorePointer(
                                child: Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.primary.withValues(alpha: 0.12),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.07),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.accent.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 15,
                                              color: AppColors.primary.withValues(alpha: 0.85),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              l10n.signupCreatorForBrands,
                                              style: AppTextStyles.caption.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                                letterSpacing: 0.2,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    l10n.signupCreatorSpaceTitle,
                                    style: AppTextStyles.heading2.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                      height: 1.1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.signupCreatorIntro,
                                    style: AppTextStyles.bodySecondary.copyWith(
                                      color: AppColors.textHint,
                                      fontWeight: FontWeight.w400,
                                      height: 1.48,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.keyboard_double_arrow_right_rounded,
                                        size: 18,
                                        color: AppColors.accent.withValues(alpha: 0.85),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.signupCreatorSwipeRight,
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.keyboard_double_arrow_right_rounded,
                                        size: 18,
                                        color: AppColors.accent.withValues(alpha: 0.85),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 236,
                                    child: PageView(
                                      controller: _creatorIntroPageController,
                                      onPageChanged: (i) => setState(() => _creatorIntroPage = i),
                                      children: [
                                        _CreatorIntroSlide(
                                          visual: const _SwipeDeckVisual(),
                                          title: l10n.signupCreatorCard1Title,
                                          body: l10n.signupCreatorCard1Body,
                                        ),
                                        _CreatorIntroSlide(
                                          visual: const _CatalogBrandVisual(),
                                          title: l10n.signupCreatorCard2Title,
                                          body: l10n.signupCreatorCard2Body,
                                        ),
                                        _CreatorIntroSlide(
                                          visual: const _SponsorVisual(),
                                          title: l10n.signupCreatorCard3Title,
                                          body: l10n.signupCreatorCard3Body,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(3, (i) {
                                      final active = i == _creatorIntroPage;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 220),
                                        curve: Curves.easeOutCubic,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: active ? 22 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          color: active ? AppColors.primary : AppColors.divider,
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : () => context.push('/creator/checkout'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.storefront_rounded, size: 22),
                                          const SizedBox(height: 10),
                                          Text(
                                            l10n.signupCreatorCreateAccount,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.button.copyWith(
                                              color: AppColors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.signupCreatorBrandNextPage,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.2,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.white.withValues(alpha: 0.88),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.signupCreatorAlreadyAccount,
                                        style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () => context.go('/login'),
                                        child: Text(l10n.authLoginTitle),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Slide du carrousel « espace marque » (PageView inscription créateur).
class _CreatorIntroSlide extends StatelessWidget {
  const _CreatorIntroSlide({
    required this.visual,
    required this.title,
    required this.body,
  });

  final Widget visual;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          visual,
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              body,
              style: AppTextStyles.bodySecondary.copyWith(
                fontSize: 12,
                height: 1.42,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
              maxLines: 7,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartes en perspective pour évoquer le swipe Inspiration.
class _SwipeDeckVisual extends StatelessWidget {
  const _SwipeDeckVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 2,
            child: Transform.rotate(
              angle: -0.09,
              child: const _MiniSwipeCard(
                width: 90,
                highlighted: false,
                child: Icon(
                  Icons.face_retouching_natural_outlined,
                  size: 34,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            child: Transform.rotate(
              angle: 0.08,
              child: const _MiniSwipeCard(
                width: 90,
                highlighted: true,
                child: Icon(
                  Icons.storefront_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.graphite.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border_rounded, size: 17, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.signupCreatorSwipeRightBadge,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSwipeCard extends StatelessWidget {
  const _MiniSwipeCard({
    required this.child,
    required this.width,
    required this.highlighted,
  });

  final Widget child;
  final double width;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: highlighted ? AppColors.primary.withValues(alpha: 0.06) : AppColors.canvas,
        border: Border.all(
          color: highlighted ? AppColors.primary.withValues(alpha: 0.28) : AppColors.divider,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withValues(alpha: 0.09),
            blurRadius: 11,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

/// Dressing marque entouré de pièces / tenues.
class _CatalogBrandVisual extends StatelessWidget {
  const _CatalogBrandVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CatalogTile(
            icon: Icons.checkroom_outlined,
            caption: context.l10n.signupCreatorCatalogPieces,
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.accent.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.storefront_rounded, size: 38, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          _CatalogTile(
            icon: Icons.style_outlined,
            caption: context.l10n.signupCreatorCatalogOutfits,
          ),
        ],
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({required this.icon, required this.caption});

  final IconData icon;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(icon, size: 22, color: AppColors.primary.withValues(alpha: 0.75)),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

/// Mégaphone & signaux de mise en avant.
class _SponsorVisual extends StatelessWidget {
  const _SponsorVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.14),
            ),
          ),
          const Icon(Icons.campaign_rounded, size: 44, color: AppColors.accent),
          Positioned(
            top: 4,
            right: 24,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 22,
              color: AppColors.primary.withValues(alpha: 0.65),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 20,
            child: Icon(
              Icons.trending_up_rounded,
              size: 28,
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
