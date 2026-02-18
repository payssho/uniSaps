import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PlatformImage extends StatelessWidget {
  final XFile? file;
  final String? networkUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const PlatformImage({
    super.key,
    this.file,
    this.networkUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : assert(file != null || networkUrl != null, 'Either file or networkUrl must be provided');

  @override
  Widget build(BuildContext context) {
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      return Image.network(
        networkUrl!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => errorWidget ?? const SizedBox(),
      );
    }

    if (file != null) {
      return FutureBuilder<Uint8List>(
        future: file!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return placeholder ?? const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return errorWidget ?? const SizedBox();
          }
          return Image.memory(
            snapshot.data!,
            fit: fit,
            width: width,
            height: height,
          );
        },
      );
    }

    return errorWidget ?? const SizedBox();
  }
}
