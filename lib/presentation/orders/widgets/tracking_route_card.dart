import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/maps.dart';

/// Road distance and time of the tracking route.
///
/// Every value comes from the routing provider through the backend; the card is
/// only built when a real route exists, so the page never shows a made-up
/// distance. Flat white with a hairline border, no shadow.
class TrackingRouteCard extends StatelessWidget {
  const TrackingRouteCard({
    super.key,
    required this.route,
    required this.l10n,
  });

  final MapRoute route;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: const Icon(
              Icons.alt_route,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _RouteMetric(
              label: l10n.routeDistanceLabel,
              value: '${Fmt.number(route.distanceKm)} ${l10n.km}',
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: AppColors.borderHairline,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _RouteMetric(
              label: l10n.routeDurationLabel,
              value: '${Fmt.number(route.durationMin)} ${l10n.minutesLong}',
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.headlineSm,
        ),
      ],
    );
  }
}
