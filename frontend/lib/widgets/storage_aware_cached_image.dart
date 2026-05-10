import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/firebase_storage_display_url.dart';

/// [CachedNetworkImage] avec résolution des URLs GCS (`storage.googleapis.com/...`)
/// vers une URL de téléchargement avec jeton (bucket privé).
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
  late Future<String> _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = resolveFirebaseStorageDisplayUrl(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant StorageAwareCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolvedUrl = resolveFirebaseStorageDisplayUrl(widget.imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolvedUrl,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.black12,
            child: widget.loadingWidget,
          );
        }

        final url = snapshot.data ?? widget.imageUrl;
        return CachedNetworkImage(
          imageUrl: url,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          placeholder: (_, __) => Container(
            color: Colors.black12,
            child: widget.loadingWidget,
          ),
          errorWidget: (ctx, _, err) => widget.errorWidget(url, err),
        );
      },
    );
  }
}
