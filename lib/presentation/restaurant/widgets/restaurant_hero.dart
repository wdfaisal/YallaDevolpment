import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/favorite_button.dart';

/// 288px cover image with the translucent circular actions from the Stitch
/// restaurant design. The bottom fades to white so the overlapping meta card
/// blends into the page without a shadow.
class RestaurantHero extends StatelessWidget {
  const RestaurantHero({
    super.key,
    required this.restaurantId,
    required this.imageUrl,
    required this.onBack,
    required this.onShare,
  });

  final String restaurantId;
  final String? imageUrl;
  final VoidCallback onBack;
  final VoidCallback onShare;

  static const double height = 288;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
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
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _HeroCircleButton(
                      // `arrow_back` mirrors to a right-pointing arrow in RTL,
                      // which is the back direction in the Arabic design.
                      icon: Icons.arrow_back,
                      tooltip: l10n.back,
                      onTap: onBack,
                    ),
                    const Spacer(),
                    _HeroCircleButton(
                      icon: Icons.share_outlined,
                      tooltip: l10n.shareRestaurant,
                      onTap: onShare,
                    ),
                    const SizedBox(width: 8),
                    FavoriteButton(
                      targetType: 'restaurant',
                      targetId: restaurantId,
                      size: 40,
                      background: const Color(0x4D000000),
                      foregroundColor: Colors.white,
                      borderColor: const Color(0x99000000),
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

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0x4D000000),
        shape: const CircleBorder(
          side: BorderSide(color: Color(0x99000000)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
