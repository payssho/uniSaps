import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/categories.dart';
import '../services/firebase_storage_display_url.dart';
import 'storage_aware_cached_image.dart';
import 'garment_category_glyph.dart';

/// Affiche une ou plusieurs photos de vêtement avec défilement et indicateurs.
///
/// Précharge toutes les images du vêtement au premier build pour que swiper
/// soit instantané : `CachedNetworkImage` met les bytes en cache disque +
/// mémoire et `allowImplicitScrolling` garde les pages voisines vivantes.
class GarmentPhotoCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final String category;
  final double height;

  const GarmentPhotoCarousel({
    super.key,
    required this.imageUrls,
    required this.category,
    this.height = 200,
  });

  @override
  State<GarmentPhotoCarousel> createState() => _GarmentPhotoCarouselState();
}

class _GarmentPhotoCarouselState extends State<GarmentPhotoCarousel> {
  late PageController _controller;
  int _page = 0;
  bool _prefetched = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didUpdateWidget(covariant GarmentPhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length &&
        _page >= widget.imageUrls.length) {
      _page = (widget.imageUrls.length - 1).clamp(0, 1 << 30);
      if (_controller.hasClients) {
        _controller.jumpToPage(_page);
      }
    }
    if (oldWidget.imageUrls.join('|') != widget.imageUrls.join('|')) {
      _prefetched = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefetched) {
      _prefetched = true;
      _prefetchAll();
    }
  }

  Future<void> _prefetchAll() async {
    for (final raw in _urls) {
      try {
        final url = await resolveFirebaseStorageDisplayUrl(raw);
        if (!mounted) return;
        await precacheImage(
          CachedNetworkImageProvider(url),
          context,
          onError: (_, __) {},
        );
      } catch (_) {
        // On ignore : l'erreur sera affichée par CachedNetworkImage lui-même.
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _urls =>
      widget.imageUrls.where((u) => u.trim().isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    if (_urls.isEmpty) {
      return Container(
        height: widget.height,
        color: AppColors.surfaceVariant,
        child: Center(
          child: GarmentCategoryGlyph(
            categoryKey: widget.category,
            size: 48,
            color: AppColors.textHint,
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _urls.length,
            allowImplicitScrolling: true,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              return StorageAwareCachedImage(
                imageUrl: _urls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                loadingWidget: Container(
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __) => Container(
                  color: AppColors.surfaceVariant,
                  child: Center(
                    child: GarmentCategoryGlyph(
                      categoryKey: widget.category,
                      size: 44,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              );
            },
          ),
          if (_urls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_urls.length, (i) {
                  final sel = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: sel ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.white : AppColors.white.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.graphite.withOpacity(0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
