import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/categories.dart';
import '../../models/garment_model.dart';
import '../../models/outfit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garment_provider.dart';
import '../../providers/outfit_provider.dart';
import '../creations/creation_screen.dart';

enum _Mode { swipe, biblio }

class OutfitsScreen extends ConsumerStatefulWidget {
  const OutfitsScreen({super.key});

  @override
  ConsumerState<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends ConsumerState<OutfitsScreen> {
  _Mode _mode = _Mode.biblio;
  String _selectedStyle = 'Simple';
  List<Map<String, String>> _aiSuggestions = [];
  bool _aiLoading = false;

  void _openCreation() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CreationScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).uid;
    final outfitsAsync = ref.watch(outfitsProvider(uid));
    final garmentsAsync = ref.watch(garmentsProvider(uid));
    final user = ref.watch(currentUserProvider).valueOrNull;

    final dailyOutfitId = user?.dailyOutfitId ?? '';
    final streak = user?.currentStreak ?? 0;

    return Scaffold(
      body: SafeArea(
        child: outfitsAsync.when(
          data: (outfits) {
            return garmentsAsync.when(
              data: (garments) {
                final garmentCache = {for (var g in garments) g.id: g};

                if (dailyOutfitId.isNotEmpty) {
                  final daily = outfits
                      .where((o) => o.id == dailyOutfitId)
                      .firstOrNull;
                  if (daily != null) {
                    return _DailyOutfitView(
                      outfit: daily,
                      garmentCache: garmentCache,
                      streak: streak,
                      dailyPhotoUrl: user?.dailyPhotoUrl ?? '',
                      onTakePhoto: () => _takePhoto(uid, daily),
                      onChangeOutfit: () {
                        ref
                            .read(outfitNotifierProvider.notifier)
                            .clearDailyOutfit(uid);
                      },
                      onAddFit: _openCreation,
                    );
                  }
                }

                // Met à jour le provider global pour savoir si on est en mode swipe
                ref.read(outfitsIsSwipeModeProvider.notifier).state =
                    _mode == _Mode.swipe;

                return Column(
                  children: [
                    _Header(
                      streak: streak,
                      onAdd: _openCreation,
                      // Bouton centré uniquement en mode Biblio (pas en Swipe)
                      showAdd: _mode == _Mode.biblio,
                    ),
                    const SizedBox(height: 12),
                    _ModeToggle(
                      mode: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _mode == _Mode.swipe
                          ? _SwipeMode(
                              outfits: outfits,
                              garmentCache: garmentCache,
                              onAccept: (outfit) {
                                ref
                                    .read(outfitNotifierProvider.notifier)
                                    .setDailyOutfit(uid, outfit.id);
                                if (streak >= 0) {
                                  _showStreakCelebration(
                                      context, streak + 1);
                                }
                              },
                              onAdd: _openCreation,
                            )
                          : _BiblioMode(
                              outfits: outfits,
                              garments: garments,
                              garmentCache: garmentCache,
                              selectedStyle: _selectedStyle,
                              aiSuggestions: _aiSuggestions,
                              aiLoading: _aiLoading,
                              onStyleChanged: (s) =>
                                  setState(() => _selectedStyle = s),
                              onGenerate: () => _generateSuggestions(
                                  uid, garments, outfits),
                              onChooseSuggestion: (s) =>
                                  _saveSuggestionAsOutfit(uid, s),
                              onChoose: (outfit) {
                                ref
                                    .read(outfitNotifierProvider.notifier)
                                    .setDailyOutfit(uid, outfit.id);
                                if (streak >= 0) {
                                  _showStreakCelebration(
                                      context, streak + 1);
                                }
                              },
                              onAdd: _openCreation,
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ),
      // On ne montre le bouton flottant "Ajouter un fit" que
      // lorsqu'aucun outfit du jour n'est sélectionné ET qu'on est en mode biblio.
      floatingActionButton: dailyOutfitId.isEmpty && _mode == _Mode.biblio
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 16),
              child: FloatingActionButton.extended(
                heroTag: 'outfits_fab',
                backgroundColor: AppColors.accent,
                elevation: 6,
                onPressed: _openCreation,
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                label: const Text(
                  'Ajouter un fit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _takePhoto(String uid, OutfitModel outfit) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.camera, maxWidth: 600, imageQuality: 78);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final url = await ref
        .read(storageServiceProvider)
        .uploadOutfitPhotoBytes(bytes, uid, picked.name);
    await ref
        .read(outfitNotifierProvider.notifier)
        .setDailyPhoto(uid, outfit.id, url);
  }

  Future<void> _generateSuggestions(
    String uid,
    List<GarmentModel> garments,
    List<OutfitModel> outfits,
  ) async {
    setState(() => _aiLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final suggestions =
          await apiService.suggestOutfits(style: _selectedStyle, count: 3);
      setState(() => _aiSuggestions = suggestions);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la génération')),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _saveSuggestionAsOutfit(
      String uid, Map<String, String> suggestion) async {
    final id = await ref.read(outfitNotifierProvider.notifier).createOutfit(
          userId: uid,
          name: 'Suggestion IA',
          garments: suggestion,
        );
    if (id != null) {
      ref.read(outfitNotifierProvider.notifier).setDailyOutfit(uid, id);
    }
  }
}

// ---------------------------------------------------------------------------
// Header with title, streak & add button
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final int streak;
  final VoidCallback onAdd;
  final bool showAdd;

  const _Header({
    required this.streak,
    required this.onAdd,
    required this.showAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Mes Outfits', style: AppTextStyles.heading2),
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text('$streak',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                ),
            ],
          ),
          if (showAdd) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Ajouter un fit',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode toggle (Swipe / Biblio)
// ---------------------------------------------------------------------------
class _ModeToggle extends StatelessWidget {
  final _Mode mode;
  final ValueChanged<_Mode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _ModeChip(
              icon: Icons.swipe_rounded,
              label: 'Swipe',
              active: mode == _Mode.swipe,
              onTap: () => onChanged(_Mode.swipe),
            ),
            _ModeChip(
              icon: Icons.grid_view_rounded,
              label: 'Biblio',
              active: mode == _Mode.biblio,
              onTap: () => onChanged(_Mode.biblio),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: active ? Colors.white : AppColors.textHint),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swipe Mode — Tinder-style photo cards
// ---------------------------------------------------------------------------
class _SwipeMode extends StatefulWidget {
  final List<OutfitModel> outfits;
  final Map<String, GarmentModel> garmentCache;
  final ValueChanged<OutfitModel> onAccept;
  final VoidCallback onAdd;

  const _SwipeMode({
    required this.outfits,
    required this.garmentCache,
    required this.onAccept,
    required this.onAdd,
  });

  @override
  State<_SwipeMode> createState() => _SwipeModeState();
}

class _SwipeModeState extends State<_SwipeMode> {
  final CardSwiperController _ctrl = CardSwiperController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.outfits.isEmpty) {
      return _EmptyState(onAdd: widget.onAdd);
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CardSwiper(
              controller: _ctrl,
              cardsCount: widget.outfits.length,
              numberOfCardsDisplayed: widget.outfits.length.clamp(1, 3),
              onSwipe: (prev, curr, direction) {
                if (direction == CardSwiperDirection.right) {
                  widget.onAccept(widget.outfits[prev]);
                }
                return true;
              },
              cardBuilder: (context, index, hPercent, vPercent) {
                final outfit = widget.outfits[index];
                return _OutfitPhotoCard(
                  outfit: outfit,
                  garmentCache: widget.garmentCache,
                  onTap: () =>
                      _showOutfitDetail(context, outfit, widget.garmentCache),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 40, right: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionCircle(
                icon: Icons.close_rounded,
                color: AppColors.error,
                size: 54,
                onTap: () => _ctrl.swipe(CardSwiperDirection.left),
              ),
              Column(
                children: [
                  Icon(Icons.swipe_rounded,
                      size: 20,
                      color: AppColors.textHint.withOpacity(0.4)),
                  const SizedBox(height: 2),
                  Text('Swipe',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint.withOpacity(0.4),
                          fontWeight: FontWeight.w500)),
                ],
              ),
              _ActionCircle(
                icon: Icons.favorite_rounded,
                color: AppColors.success,
                size: 54,
                onTap: () => _ctrl.swipe(CardSwiperDirection.right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Biblio Mode — Grid + Filters + AI
// ---------------------------------------------------------------------------
class _BiblioMode extends StatelessWidget {
  final List<OutfitModel> outfits;
  final List<GarmentModel> garments;
  final Map<String, GarmentModel> garmentCache;
  final String selectedStyle;
  final List<Map<String, String>> aiSuggestions;
  final bool aiLoading;
  final ValueChanged<String> onStyleChanged;
  final VoidCallback onGenerate;
  final ValueChanged<Map<String, String>> onChooseSuggestion;
  final ValueChanged<OutfitModel> onChoose;
  final VoidCallback onAdd;

  const _BiblioMode({
    required this.outfits,
    required this.garments,
    required this.garmentCache,
    required this.selectedStyle,
    required this.aiSuggestions,
    required this.aiLoading,
    required this.onStyleChanged,
    required this.onGenerate,
    required this.onChooseSuggestion,
    required this.onChoose,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (outfits.isEmpty && aiSuggestions.isEmpty) {
      return _EmptyState(onAdd: onAdd);
    }

    return CustomScrollView(
      slivers: [
        // AI section as collapsible header
        SliverToBoxAdapter(
          child: _AISection(
            selectedStyle: selectedStyle,
            suggestions: aiSuggestions,
            loading: aiLoading,
            garmentCache: garmentCache,
            onStyleChanged: onStyleChanged,
            onGenerate: onGenerate,
            onChooseSuggestion: onChooseSuggestion,
          ),
        ),

        // Grid of outfit photos
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final outfit = outfits[i];
                return _OutfitGridTile(
                  outfit: outfit,
                  garmentCache: garmentCache,
                  index: i,
                  onTap: () => _showOutfitDetail(
                    ctx,
                    outfit,
                    garmentCache,
                    onChoose: () => onChoose(outfit),
                  ),
                );
              },
              childCount: outfits.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// AI section (collapsible)
// ---------------------------------------------------------------------------
class _AISection extends StatefulWidget {
  final String selectedStyle;
  final List<Map<String, String>> suggestions;
  final bool loading;
  final Map<String, GarmentModel> garmentCache;
  final ValueChanged<String> onStyleChanged;
  final VoidCallback onGenerate;
  final ValueChanged<Map<String, String>> onChooseSuggestion;

  const _AISection({
    required this.selectedStyle,
    required this.suggestions,
    required this.loading,
    required this.garmentCache,
    required this.onStyleChanged,
    required this.onGenerate,
    required this.onChooseSuggestion,
  });

  @override
  State<_AISection> createState() => _AISectionState();
}

class _AISectionState extends State<_AISection> {
  bool _expanded = false;
  final TextEditingController _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withOpacity(0.06),
              AppColors.accentLight.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.accent.withOpacity(0.12), width: 1),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          size: 16, color: AppColors.accent),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Suggestions IA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textHint, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: stylePrompts.map((style) {
                        final sel = widget.selectedStyle == style;
                        return ChoiceChip(
                          label: Text(style, style: TextStyle(fontSize: 12,
                            color: sel ? Colors.white : AppColors.textSecondary)),
                          selected: sel,
                          selectedColor: AppColors.accent,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => widget.onStyleChanged(style),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _promptController,
                      maxLines: 2,
                      minLines: 1,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Décris ton besoin (ex: tenue chic pour un dîner, streetwear pour un concert)...',
                        prefixIcon: Icon(Icons.chat_bubble_outline, size: 18),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.loading
                            ? null
                            : () {
                                final prompt = _promptController.text.trim();
                                if (prompt.isNotEmpty) {
                                  widget.onStyleChanged(prompt);
                                }
                                widget.onGenerate();
                              },
                        icon: widget.loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome,
                                size: 16, color: Colors.white),
                        label: Text(
                            widget.loading ? 'Génération...' : 'Générer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    ...widget.suggestions.map((s) {
                      final items = s.entries
                          .where((e) =>
                              e.value.isNotEmpty &&
                              widget.garmentCache.containsKey(e.value))
                          .map((e) => widget.garmentCache[e.value]!)
                          .toList();
                      return Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: items
                                  .map((g) => Chip(
                                        avatar: g.imageUrl.isNotEmpty
                                            ? CircleAvatar(
                                                backgroundImage:
                                                    NetworkImage(g.imageUrl))
                                            : null,
                                        label: Text(g.name,
                                            style:
                                                const TextStyle(fontSize: 11)),
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () =>
                                    widget.onChooseSuggestion(s),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('Choisir',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Outfit photo card (used in Swipe mode)
// ---------------------------------------------------------------------------
class _OutfitPhotoCard extends StatelessWidget {
  final OutfitModel outfit;
  final Map<String, GarmentModel> garmentCache;
  final VoidCallback onTap;

  const _OutfitPhotoCard({
    required this.outfit,
    required this.garmentCache,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = outfit.referencePhotoUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              CachedNetworkImage(
                imageUrl: outfit.referencePhotoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) =>
                    _FallbackOutfitVisual(outfit: outfit, garmentCache: garmentCache),
              )
            else
              _FallbackOutfitVisual(outfit: outfit, garmentCache: garmentCache),

            // Bottom gradient overlay with name
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outfit.name.isEmpty ? 'Outfit' : outfit.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (outfit.timesWorn > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Porté ${outfit.timesWorn}x',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Tap hint
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 14, color: Colors.white70),
                    SizedBox(width: 4),
                    Text('Détails',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid tile (used in Biblio mode)
// ---------------------------------------------------------------------------
class _OutfitGridTile extends StatefulWidget {
  final OutfitModel outfit;
  final Map<String, GarmentModel> garmentCache;
  final int index;
  final VoidCallback onTap;

  const _OutfitGridTile({
    required this.outfit,
    required this.garmentCache,
    required this.index,
    required this.onTap,
  });

  @override
  State<_OutfitGridTile> createState() => _OutfitGridTileState();
}

class _OutfitGridTileState extends State<_OutfitGridTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.outfit.referencePhotoUrl.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto)
                CachedNetworkImage(
                  imageUrl: widget.outfit.referencePhotoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => _FallbackOutfitVisual(
                      outfit: widget.outfit,
                      garmentCache: widget.garmentCache),
                )
              else
                _FallbackOutfitVisual(
                    outfit: widget.outfit,
                    garmentCache: widget.garmentCache),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 28, 12, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    widget.outfit.name.isEmpty
                        ? 'Outfit'
                        : widget.outfit.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              if (widget.outfit.timesWorn > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.outfit.timesWorn}x',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: (50 * widget.index).ms)
        .slideY(
            begin: 0.08,
            end: 0,
            duration: 350.ms,
            delay: (50 * widget.index).ms,
            curve: Curves.easeOut);
  }
}

// ---------------------------------------------------------------------------
// Fallback visual when outfit has no photo
// ---------------------------------------------------------------------------
class _FallbackOutfitVisual extends StatelessWidget {
  final OutfitModel outfit;
  final Map<String, GarmentModel> garmentCache;

  const _FallbackOutfitVisual({
    required this.outfit,
    required this.garmentCache,
  });

  @override
  Widget build(BuildContext context) {
    final garmentImages = outfit.garments.values
        .where((id) => id.isNotEmpty && garmentCache.containsKey(id))
        .map((id) => garmentCache[id]!)
        .where((g) => g.imageUrl.isNotEmpty)
        .take(4)
        .toList();

    if (garmentImages.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.style_outlined,
              size: 48, color: AppColors.textHint),
        ),
      );
    }

    return Container(
      color: AppColors.surfaceVariant,
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: garmentImages
            .map((g) => CachedNetworkImage(
                  imageUrl: g.imageUrl,
                  fit: BoxFit.cover,
                ))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action circle (swipe mode buttons)
// ---------------------------------------------------------------------------
class _ActionCircle extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  State<_ActionCircle> createState() => _ActionCircleState();
}

class _ActionCircleState extends State<_ActionCircle> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.85),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: widget.color.withOpacity(0.3), width: 2),
          ),
          child: Icon(widget.icon, color: widget.color, size: 26),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.style_outlined,
                  size: 48, color: AppColors.accent),
            )
                .animate()
                .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.easeOutBack)
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 24),
            const Text(
              'Aucun outfit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crée ton premier look en ajoutant\nune photo et tes vêtements',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 20, color: Colors.white),
              label: const Text('Créer un outfit'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily outfit view (photo-centric)
// ---------------------------------------------------------------------------
class _DailyOutfitView extends StatelessWidget {
  final OutfitModel outfit;
  final Map<String, GarmentModel> garmentCache;
  final int streak;
  final String dailyPhotoUrl;
  final VoidCallback onTakePhoto;
  final VoidCallback onChangeOutfit;
  final VoidCallback onAddFit;

  const _DailyOutfitView({
    required this.outfit,
    required this.garmentCache,
    required this.streak,
    required this.dailyPhotoUrl,
    required this.onTakePhoto,
    required this.onChangeOutfit,
    required this.onAddFit,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = dailyPhotoUrl.isNotEmpty
        ? dailyPhotoUrl
        : outfit.referencePhotoUrl;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Outfit du jour', style: AppTextStyles.heading2),
                  const Spacer(),
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text('$streak',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: onAddFit,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Ajouter un fit à la bibliothèque',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GestureDetector(
            onTap: () =>
                _showOutfitDetail(context, outfit, garmentCache),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    )
                  else
                    _FallbackOutfitVisual(
                        outfit: outfit, garmentCache: garmentCache),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding:
                          const EdgeInsets.fromLTRB(20, 40, 20, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outfit.name.isEmpty ? 'Outfit' : outfit.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap pour voir les détails',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
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
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTakePhoto,
                  icon: const Icon(Icons.camera_alt_outlined,
                      size: 18, color: Colors.white),
                  label: const Text('Photo du jour'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onChangeOutfit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Changer'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Outfit detail bottom sheet
// ---------------------------------------------------------------------------
void _showOutfitDetail(
  BuildContext context,
  OutfitModel outfit,
  Map<String, GarmentModel> garmentCache, {
  VoidCallback? onChoose,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OutfitDetailSheet(
      outfit: outfit,
      garmentCache: garmentCache,
      onChoose: onChoose,
    ),
  );
}

class _OutfitDetailSheet extends StatelessWidget {
  final OutfitModel outfit;
  final Map<String, GarmentModel> garmentCache;
  final VoidCallback? onChoose;

  const _OutfitDetailSheet({
    required this.outfit,
    required this.garmentCache,
    this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final items = outfit.garments.entries
        .where(
            (e) => e.value.isNotEmpty && garmentCache.containsKey(e.value))
        .map((e) => MapEntry(e.key, garmentCache[e.value]!))
        .toList();

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (outfit.referencePhotoUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: CachedNetworkImage(
                            imageUrl: outfit.referencePhotoUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            outfit.name.isEmpty ? 'Outfit' : outfit.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (outfit.timesWorn > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Porté ${outfit.timesWorn}x',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pièces',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 10),
                          ...items.asMap().entries.map((entry) {
                            final i = entry.key;
                            final e = entry.value;
                            final g = e.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: g.imageUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: g.imageUrl,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 40,
                                            height: 40,
                                            color: AppColors.divider,
                                            child: const Icon(Icons.checkroom,
                                                size: 18,
                                                color: AppColors.textHint),
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(g.name,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                        if (g.brand.isNotEmpty)
                                          Text(g.brand,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors
                                                      .textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    categoryLabel(e.key),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textHint),
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(
                                    duration: 250.ms, delay: (40 * i).ms)
                                .slideX(
                                    begin: 0.05,
                                    end: 0,
                                    duration: 250.ms,
                                    delay: (40 * i).ms);
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (onChoose != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onChoose!();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Choisir pour aujourd\'hui'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak celebration
// ---------------------------------------------------------------------------
void _showStreakCelebration(BuildContext context, int newStreak) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'streak',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) =>
        _StreakCelebrationOverlay(streak: newStreak),
  );
}

class _StreakCelebrationOverlay extends StatefulWidget {
  final int streak;
  const _StreakCelebrationOverlay({required this.streak});

  @override
  State<_StreakCelebrationOverlay> createState() =>
      _StreakCelebrationOverlayState();
}

class _StreakCelebrationOverlayState
    extends State<_StreakCelebrationOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: Container(
          width: 260,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.accentLight, AppColors.accent],
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.2, 0.2),
                        end: const Offset(1.05, 1.05),
                        curve: Curves.elasticOut,
                        duration: 600.ms,
                      )
                      .then()
                      .shake(hz: 3, duration: 300.ms),
                  const Icon(Icons.local_fire_department,
                          size: 52, color: Colors.white)
                      .animate()
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.easeOutBack,
                        duration: 450.ms,
                      )
                      .fadeIn(duration: 350.ms),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('+1',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    )
                        .animate()
                        .move(
                          begin: const Offset(0, 12),
                          end: const Offset(0, 0),
                          curve: Curves.easeOut,
                          duration: 350.ms,
                        )
                        .fadeIn(duration: 350.ms),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Streak de ${widget.streak} jours',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 200.ms)
                  .slide(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                      duration: 300.ms),
              const SizedBox(height: 6),
              const Text(
                'Tu gardes la flamme, continue !',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ).animate().fadeIn(duration: 280.ms, delay: 260.ms),
            ],
          ),
        ),
      ),
    );
  }
}
