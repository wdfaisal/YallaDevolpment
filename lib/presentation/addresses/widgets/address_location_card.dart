import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';

/// Flat pin canvas from the Stitch address design. There is no live map tile
/// here — a hairline grid stands in for the canvas — while every control stays
/// real: the pill mirrors the typed area and the quick actions open or clear
/// the stored coordinates. No shadow, pure white surface.
class AddressLocationCard extends StatelessWidget {
  const AddressLocationCard({
    super.key,
    required this.areaLabel,
    required this.hasPosition,
    required this.enterLabel,
    required this.resetLabel,
    required this.pinSetLabel,
    required this.onEnterCoordinates,
    required this.onResetPin,
  });

  final String areaLabel;
  final bool hasPosition;
  final String enterLabel;
  final String resetLabel;
  final String pinSetLabel;
  final VoidCallback onEnterCoordinates;
  final VoidCallback onResetPin;

  static const double height = 224;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _MapCanvasPainter()),
          ),
          PositionedDirectional(
            top: AppSpacing.md,
            start: AppSpacing.md,
            end: AppSpacing.md,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _LocationPill(
                label: areaLabel,
                hasPosition: hasPosition,
                badge: pinSetLabel,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.15),
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.08),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer,
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 22,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: AppSpacing.md,
            start: AppSpacing.md,
            end: AppSpacing.md,
            child: Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.my_location,
                    iconColor: AppColors.primaryContainer,
                    label: enterLabel,
                    onTap: onEnterCoordinates,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.touch_app,
                    iconColor: AppColors.secondary,
                    label: resetLabel,
                    onTap: onResetPin,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({
    required this.label,
    required this.hasPosition,
    required this.badge,
  });

  final String label;
  final bool hasPosition;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasPosition ? AppColors.tertiary : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasPosition) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tertiaryFixed.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                badge,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.surfaceContainer),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Abstract hairline canvas so the pin has a surface to sit on without loading
/// a third-party map tile or inventing street labels.
class _MapCanvasPainter extends CustomPainter {
  const _MapCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.surfaceContainer
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final road = Paint()
      ..color = AppColors.surfaceContainerHigh
      ..strokeWidth = 9;
    canvas.drawLine(
      Offset(0, size.height * 0.66),
      Offset(size.width, size.height * 0.34),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.58, size.height),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
