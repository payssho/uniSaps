import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/firebase_storage_display_url.dart';

/// [CachedNetworkImage] avec résolution des URLs GCS (`storage.googleapis.com/...`)
/// vers une URL de téléchargement avec jeton (bucket privé).
///
/// - Si l'URL est déjà connue (cache mémoire), on rend [CachedNetworkImage]
///   directement, sans `FutureBuilder` ni spinner.
/// - Sinon on résout (async) puis on rend.
class StorageAwareCachedImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget loadingWidget;
  final Widget Function(String url, dynamic error) errorWidget;

  const StorageAwareCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
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

  Widget _buildImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      fadeInDuration: const Duration(milliseconds: 80),
      fadeOutDuration: const Duration(milliseconds: 60),
      placeholder: (_, __) => Container(
        color: Colors.black12,
        child: widget.loadingWidget,
      ),
      errorWidget: (ctx, _, err) => widget.errorWidget(url, err),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_syncUrl != null) {
      return _buildImage(_syncUrl!);
    }
    return FutureBuilder<String>(
      future: _pendingUrl,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.black12,
            child: widget.loadingWidget,
          );
        }
        if (snapshot.hasError) {
          return widget.errorWidget(widget.imageUrl, snapshot.error);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return widget.errorWidget(widget.imageUrl, 'no_url');
        }
        return _buildImage(snapshot.data!);
      },
    );
  }
}
