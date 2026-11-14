import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/widgets/app_image.dart';

/// Cover image for the restaurant page. The bottom fades to white so the
/// overlapping meta card blends into the page without a shadow. The top
/// actions live in the restaurant top bar so they can pin over the scroll view.
class RestaurantHero extends StatelessWidget {
  const RestaurantHero({super.key, required this.imageUrl});

  final String? imageUrl;

  static const double height = 288;

  /// How far the meta card is lifted over the hero image.
  static const double metaOverlap = 48;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppImage(
            url: imageUrl,
            borderRadius: BorderRadius.zero,
            icon: Icons.restaurant,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.surfaceContainerLowest,
                  Color(0x33000000),
                  Color(0x66000000),
                ],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
