import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../utils/media_url.dart';

/// Cached network image with a consistent placeholder and graceful failure.
/// Never substitutes demo imagery: a failed image shows an icon.
///
/// On the web this deliberately uses [Image.network]: `CachedNetworkImage`'s
/// default web renderer hands out a *lazy* texture backed by an `<img>`
/// element, and that texture turns black/blank once the route that owns it is
/// rebuilt (for example after returning from a store page). `Image.network`
/// decodes the bytes instead, which stays stable; the browser HTTP cache plus
/// the `Cache-Control: immutable` headers still prevent repeat downloads.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.icon = Icons.restaurant_outlined,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    final resolvedUrl = resolveMediaUrl(url);
    final fallback = Container(
      width: width,
      height: height,
      color: backgroundColor ?? AppColors.surfaceContainer,
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.secondary, size: 24),
    );

    Widget image;
    if (resolvedUrl == null) {
      image = fallback;
    } else if (kIsWeb) {
      image = Image.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                width: width,
                height: height,
                color: backgroundColor ?? AppColors.surfaceContainer,
              ),
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          color: backgroundColor ?? AppColors.surfaceContainer,
        ),
        errorWidget: (_, __, ___) => fallback,
      );
    }

    return ClipRRect(borderRadius: radius, child: image);
  }
}
