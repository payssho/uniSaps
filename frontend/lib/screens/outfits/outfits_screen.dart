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
import '../../services/api_service.dart';
import '../../widgets/outfit_card.dart';

class OutfitsScreen extends ConsumerStatefulWidget {
  const OutfitsScreen({super.key});

  @override
  ConsumerState<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends ConsumerState<OutfitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  String _selectedStyle = 'Simple';
  List<Map<String, String>> _aiSuggestions = [];
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  final daily = outfits.where((o) => o.id == dailyOutfitId).firstOrNull;
                  if (daily != null) {
                    return _DailyOutfitView(
                      outfit: daily,
                      garmentCache: garmentCache,
                      streak: streak,
                      dailyPhotoUrl: user?.dailyPhotoUrl ?? '',
                      onTakePhoto: () => _takePhoto(uid, daily),
                      onChangeOutfit: () {
                        ref.read(outfitNotifierProvider.notifier).clearDailyOutfit(uid);
                      },
                    );
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          const Text('Mes Outfits', style: AppTextStyles.heading2),
                          const Spacer(),
                          if (streak > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department, size: 18, color: AppColors.warning),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$streak',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.accent,
                      labelColor: AppColors.accent,
                      unselectedLabelColor: AppColors.textHint,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: const [
                        Tab(text: 'Biblio'),
                        Tab(text: 'Swipe'),
                        Tab(text: 'IA'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _BiblioTab(
                            outfits: outfits,
                            garmentCache: garmentCache,
                            currentIndex: _currentIndex,
                            onIndexChanged: (i) => setState(() => _currentIndex = i),
                            onChoose: (outfit) {
                              ref.read(outfitNotifierProvider.notifier).setDailyOutfit(uid, outfit.id);
                              if (streak >= 0) {
                                _showStreakCelebration(context, streak + 1);
                              }
                            },
                          ),
                          _SwipeTab(
                            outfits: outfits,
                            garmentCache: garmentCache,
                            onAccept: (outfit) {
                              ref.read(outfitNotifierProvider.notifier).setDailyOutfit(uid, outfit.id);
                              if (streak >= 0) {
                                _showStreakCelebration(context, streak + 1);
                              }
                            },
                          ),
                          _AITab(
                            garments: garments,
                            garmentCache: garmentCache,
                            selectedStyle: _selectedStyle,
                            suggestions: _aiSuggestions,
                            loading: _aiLoading,
                            onStyleChanged: (s) => setState(() => _selectedStyle = s),
                            onGenerate: () => _generateSuggestions(uid, garments, outfits),
                            onChooseSuggestion: (suggestion) =>
                                _saveSuggestionAsOutfit(uid, suggestion),
                          ),
                        ],
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
    );
  }

  Future<void> _takePhoto(String uid, OutfitModel outfit) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 600, imageQuality: 78);
    if (picked == null) return;
    // Upload direct des bytes vers Firebase Storage via StorageService
    final bytes = await picked.readAsBytes();
    final url = await ref
        .read(storageServiceProvider)
        .uploadOutfitPhotoBytes(bytes, uid, picked.name);
    await ref.read(outfitNotifierProvider.notifier).setDailyPhoto(uid, outfit.id, url);
  }

  Future<void> _generateSuggestions(
    String uid,
    List<GarmentModel> garments,
    List<OutfitModel> outfits,
  ) async {
    setState(() => _aiLoading = true);
    try {
      final apiService = ApiService(
        baseUrl: 'http://10.0.2.2:8000/api/v1',
        authService: ref.read(authServiceProvider),
      );
      final suggestions = await apiService.suggestOutfits(style: _selectedStyle, count: 3);
      setState(() => _aiSuggestions = suggestions);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la generation')),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _saveSuggestionAsOutfit(String uid, Map<String, String> suggestion) async {
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

void _showStreakCelebration(BuildContext context, int newStreak) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'streak',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) {
      return _StreakCelebrationOverlay(streak: newStreak);
    },
  );
}

class _StreakCelebrationOverlay extends StatefulWidget {
  final int streak;

  const _StreakCelebrationOverlay({required this.streak});

  @override
  State<_StreakCelebrationOverlay> createState() => _StreakCelebrationOverlayState();
}

class _StreakCelebrationOverlayState extends State<_StreakCelebrationOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.accentLight,
                          AppColors.accent,
                        ],
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
                      .shake(
                        hz: 3,
                        duration: 300.ms,
                      ),
                  const Icon(
                    Icons.local_fire_department,
                    size: 52,
                    color: Colors.white,
                  )
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '+1',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                  color: AppColors.textPrimary,
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 200.ms)
                  .slide(begin: const Offset(0, 0.2), end: Offset.zero, duration: 300.ms),
              const SizedBox(height: 6),
              const Text(
                'Tu gardes la flamme, continue !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(duration: 280.ms, delay: 260.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyOutfitView extends StatelessWidget {
  final OutfitModel outfit;
  final Map<String, GarmentModel> garmentCache;
  final int streak;
  final String dailyPhotoUrl;
  final VoidCallback onTakePhoto;
  final VoidCallback onChangeOutfit;

  const _DailyOutfitView({
    required this.outfit,
    required this.garmentCache,
    required this.streak,
    required this.dailyPhotoUrl,
    required this.onTakePhoto,
    required this.onChangeOutfit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Outfit du jour', style: AppTextStyles.heading2),
              const Spacer(),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text('$streak', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          OutfitCard(outfit: outfit, garmentCache: garmentCache),
          const SizedBox(height: 24),
          if (dailyPhotoUrl.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: dailyPhotoUrl,
                  height: 320,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 320,
                    color: AppColors.surfaceVariant,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 320,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textHint),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTakePhoto,
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text('Photo du jour'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: OutlinedButton(
                  onPressed: onChangeOutfit,
                  child: const Text('Changer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BiblioTab extends StatelessWidget {
  final List<OutfitModel> outfits;
  final Map<String, GarmentModel> garmentCache;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<OutfitModel> onChoose;

  const _BiblioTab({
    required this.outfits,
    required this.garmentCache,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    if (outfits.isEmpty) {
      return const Center(
        child: Text('Cree ton premier outfit !', style: AppTextStyles.bodySecondary),
      );
    }
    final idx = currentIndex.clamp(0, outfits.length - 1);
    final outfit = outfits[idx];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: OutfitCard(outfit: outfit, garmentCache: garmentCache),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: idx > 0 ? () => onIndexChanged(idx - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${idx + 1} / ${outfits.length}', style: AppTextStyles.bodySecondary),
              IconButton(
                onPressed: idx < outfits.length - 1 ? () => onIndexChanged(idx + 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onChoose(outfit),
              child: const Text('Choisir pour aujourd\'hui'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeTab extends StatefulWidget {
  final List<OutfitModel> outfits;
  final Map<String, GarmentModel> garmentCache;
  final ValueChanged<OutfitModel> onAccept;

  const _SwipeTab({
    required this.outfits,
    required this.garmentCache,
    required this.onAccept,
  });

  @override
  State<_SwipeTab> createState() => _SwipeTabState();
}

class _SwipeTabState extends State<_SwipeTab> {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.outfits.isEmpty) {
      return const Center(
        child: Text('Aucun outfit a swiper', style: AppTextStyles.bodySecondary),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: widget.outfits.length,
              numberOfCardsDisplayed: widget.outfits.length.clamp(1, 3),
              onSwipe: (prev, curr, direction) {
                if (direction == CardSwiperDirection.right) {
                  widget.onAccept(widget.outfits[prev]);
                }
                return true;
              },
              cardBuilder: (context, index, hPercent, vPercent) {
                return OutfitCard(
                  outfit: widget.outfits[index],
                  garmentCache: widget.garmentCache,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'reject',
                backgroundColor: AppColors.error.withOpacity(0.1),
                elevation: 0,
                onPressed: () => _swiperController.swipe(CardSwiperDirection.left),
                child: const Icon(Icons.close, color: AppColors.error),
              ),
              FloatingActionButton(
                heroTag: 'accept',
                backgroundColor: AppColors.success.withOpacity(0.1),
                elevation: 0,
                onPressed: () => _swiperController.swipe(CardSwiperDirection.right),
                child: const Icon(Icons.favorite, color: AppColors.success),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AITab extends StatelessWidget {
  final List<GarmentModel> garments;
  final Map<String, GarmentModel> garmentCache;
  final String selectedStyle;
  final List<Map<String, String>> suggestions;
  final bool loading;
  final ValueChanged<String> onStyleChanged;
  final VoidCallback onGenerate;
  final ValueChanged<Map<String, String>> onChooseSuggestion;

  const _AITab({
    required this.garments,
    required this.garmentCache,
    required this.selectedStyle,
    required this.suggestions,
    required this.loading,
    required this.onStyleChanged,
    required this.onGenerate,
    required this.onChooseSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Style', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stylePrompts.map((style) {
              final selected = selectedStyle == style;
              return ChoiceChip(
                label: Text(style),
                selected: selected,
                selectedColor: AppColors.accent,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
                onSelected: (_) => onStyleChanged(style),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onGenerate,
              child: loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Generer des suggestions'),
            ),
          ),
          const SizedBox(height: 20),
          ...suggestions.map((s) {
            final items = s.entries
                .where((e) => e.value.isNotEmpty && garmentCache.containsKey(e.value))
                .map((e) => garmentCache[e.value]!)
                .toList();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: items
                        .map((g) => Chip(
                              avatar: g.imageUrl.isNotEmpty
                                  ? CircleAvatar(backgroundImage: NetworkImage(g.imageUrl))
                                  : null,
                              label: Text(g.name, style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => onChooseSuggestion(s),
                      child: const Text('Choisir'),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
