import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/firebase_storage_display_url.dart';
import '../utils/network_image_quality.dart';

/// [CachedNetworkImage] avec résolution des URLs GCS (`storage.googleapis.com/...`)
/// vers une URL de téléchargement avec jeton (bucket privé).
///
/// - Si l'URL est déjà connue (cache mémoire), on rend [CachedNetworkImage]
///   directement, sans `FutureBuilder` ni spinner.
/// - Sinon on résout (async) puis on rend.
/// - `memCacheWidth` / `memCacheHeight` : dérivés de [width]/[height] si non fournis.
class StorageAwareCachedImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  /// Décode plus de pixels pour les grandes zones (détail, plein écran).
  final bool preferHighQuality;
  final Widget loadingWidget;
  final Widget Function(String url, dynamic error) errorWidget;

  const StorageAwareCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.preferHighQuality = false,
    this.loadingWidget = const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
    required this.errorWidget,
  });

  @override
  State<StorageAwareCachedImage> createState() =>
      _StorageAwareCachedImageState();
}

class _StorageAwareCachedImageState extends State<StorageAwareCachedImage> {
  String? _syncUrl;
  Future<String>? _pendingUrl;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant StorageAwareCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _prepare();
    }
  }

  void _prepare() {
    final cached = cachedDisplayUrl(widget.imageUrl);
    if (cached != null) {
      _syncUrl = cached;
      _pendingUrl = null;
    } else {
      _syncUrl = null;
      _pendingUrl = resolveFirebaseStorageDisplayUrl(widget.imageUrl);
    }
  }

  int? _resolvedMemCacheWidth(
    BuildContext context, {
    double? width,
  }) {
    if (widget.memCacheWidth != null) return widget.memCacheWidth;
    final w = width ?? widget.width;
    if (w == null || !w.isFinite || w <= 0) return null;
    return memCacheWidthFor(
      context,
      w,
      preferHighQuality: widget.preferHighQuality,
    );
  }

  int? _resolvedMemCacheHeight(
    BuildContext context, {
    double? height,
  }) {
    if (widget.memCacheHeight != null) return widget.memCacheHeight;
    final h = height ?? widget.height;
    if (h == null || !h.isFinite || h <= 0) return null;
    return memCacheHeightFor(
      context,
      h,
      preferHighQuality: widget.preferHighQuality,
    );
  }

  Widget _placeholderBox() {
    if (widget.width != null && widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.loadingWidget,
      );
    }
    return widget.loadingWidget;
  }

  static bool _hasBoxSize(double? w, double? h) {
    return w != null &&
        h != null &&
        w.isFinite &&
        h.isFinite &&
        w > 0 &&
        h > 0;
  }

  Widget _placeholderSized(double? displayW, double? displayH) {
    return Container(
      width: displayW,
      height: displayH,
      color: AppColors.surfaceVariant,
      child: widget.loadingWidget,
    );
  }

  Widget _buildImage(
    BuildContext context,
    String url, {
    double? width,
    double? height,
  }) {
    final cacheW = _resolvedMemCacheWidth(context, width: width);
    final cacheH = _resolvedMemCacheHeight(context, height: height);
    final displayW = width ?? widget.width;
    final displayH = height ?? widget.height;
    final coverCrop =
        widget.fit == BoxFit.cover && _hasBoxSize(displayW, displayH);

    return CachedNetworkImage(
      imageUrl: url,
      fit: widget.fit,
      width: displayW,
      height: displayH,
      memCacheWidth: cacheW,
      memCacheHeight: cacheH,
      filterQuality: FilterQuality.high,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: const Duration(milliseconds: 80),
      imageBuilder: coverCrop
          ? (context, imageProvider) => SizedBox(
                width: displayW,
                height: displayH,
                child: ClipRect(
                  child: Image(
                    image: imageProvider,
                    width: displayW,
                    height: displayH,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              )
          : null,
      placeholder: (_, __) => _placeholderSized(displayW, displayH),
      errorWidget: (ctx, _, err) => widget.errorWidget(url, err),
    );
  }

  bool get _needsLayoutResolution {
    final w = widget.width;
    final h = widget.height;
    final badW = w == null || !w.isFinite || w <= 0;
    final badH = h == null || !h.isFinite || h <= 0;
    return badW || badH;
  }

  Widget _buildResolved(BuildContext context, String url) {
    if (!_needsLayoutResolution) {
      return _buildImage(context, url);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
          return _buildImage(context, url);
        }
        return _buildImage(context, url, width: w, height: h);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_syncUrl != null) {
      return _buildResolved(context, _syncUrl!);
    }
    return FutureBuilder<String>(
      future: _pendingUrl,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.surfaceVariant,
            child: _placeholderBox(),
          );
        }
        if (snapshot.hasError) {
          return widget.errorWidget(widget.imageUrl, snapshot.error);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return widget.errorWidget(widget.imageUrl, 'no_url');
        }
        return _buildResolved(context, snapshot.data!);
      },
    );
  }
}
