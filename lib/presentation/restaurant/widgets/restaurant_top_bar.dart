import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/favorite_button.dart';

/// Pinned restaurant app bar. It starts transparent over the hero image and
/// fades to a flat white surface while scrolling; once the meta card title
/// reaches the bar, the same title slides up into it and stays there.
class RestaurantTopBar extends StatelessWidget {
  const RestaurantTopBar({
    super.key,
    required this.restaurantId,
    required this.title,
    required this.scrollOffset,
    required this.titleStart,
    required this.topInset,
    required this.onBack,
    required this.onShare,
  });

  final String restaurantId;
  final String title;
  final ValueListenable<double> scrollOffset;

  /// Scroll offset at which the meta card title touches the bottom of the bar.
  final double titleStart;
  final double topInset;
  final VoidCallback onBack;
  final VoidCallback onShare;

  static const double contentHeight = 56;
  static const double buttonSize = 36;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return ValueListenableBuilder<double>(
      valueListenable: scrollOffset,
      builder: (context, offset, _) {
        final background = ((offset - 8) / 48).clamp(0.0, 1.0);
        final titleProgress = ((offset - titleStart) / 28).clamp(0.0, 1.0);
        return Container(
          height: topInset + contentHeight,
          padding: EdgeInsetsDirectional.only(
            top: topInset,
            start: AppSpacing.lg,
            end: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(
              alpha: background,
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderSubtle.withValues(alpha: background),
              ),
            ),
          ),
          child: Row(
            children: [
              _BarIconButton(
                // `arrow_back` mirrors to a right-pointing arrow in RTL.
                icon: Icons.arrow_back,
                tooltip: l10n.back,
                onTap: onBack,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: titleProgress <= 0
                    ? const SizedBox.shrink()
                    : Opacity(
                        opacity: titleProgress,
                        child: Transform.translate(
                          offset: Offset(0, (1 - titleProgress) * 8),
                          child: Text(
                            title,
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _BarIconButton(
                icon: Icons.share_outlined,
                tooltip: l10n.shareRestaurant,
                onTap: onShare,
              ),
              const SizedBox(width: AppSpacing.sm),
              FavoriteButton(
                targetType: 'restaurant',
                targetId: restaurantId,
                size: buttonSize,
                background: AppColors.surfaceContainerLowest,
                borderColor: AppColors.borderSubtle,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
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
        color: AppColors.surfaceContainerLowest,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.borderSubtle),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: RestaurantTopBar.buttonSize,
            height: RestaurantTopBar.buttonSize,
            child: Icon(icon, size: 18, color: AppColors.onSurface),
          ),
        ),
      ),
    );
  }
}
