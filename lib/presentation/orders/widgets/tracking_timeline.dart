import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/orders.dart';

/// Canonical order timeline from the Stitch tracking design, rendered as a flat
/// white card with a hairline border and a 2 px connector line.
///
/// Completed steps are green, the current step is brand orange with a live dot,
/// and the remaining delivery step is dimmed at 50% instead of a grey block.
class TrackingTimeline extends StatelessWidget {
  const TrackingTimeline({
    super.key,
    required this.detail,
    required this.l10n,
  });

  final OrderDetail detail;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final events = detail.tracking.events;
    final active = detail.summary.isActive;
    final delivered = detail.summary.status == 'delivered';
    final failed =
        const {'cancelled', 'failed_delivery'}.contains(detail.summary.status);
    final (badgeLabel, badgeBackground, badgeForeground) = failed
        ? (l10n.cancelled, AppColors.errorContainer, AppColors.onErrorContainer)
        : delivered
            ? (
                l10n.delivered,
                AppColors.tertiaryFixed,
                AppColors.onTertiaryFixed
              )
            : (
                l10n.inProgress,
                AppColors.tertiaryFixed,
                AppColors.onTertiaryFixed
              );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Row(
              children: [
                const Icon(
                  Icons.timeline,
                  size: 22,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.currentOrderStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineSm,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _SectionBadge(
                  label: badgeLabel,
                  background: badgeBackground,
                  foreground: badgeForeground,
                ),
              ],
            ),
          ),
          if (events.isEmpty)
            Text(
              l10n.findingDriver,
              style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
            )
          else
            Stack(
              children: [
                PositionedDirectional(
                  start: 15,
                  top: 12,
                  bottom: 12,
                  child: Container(
                    width: 2,
                    color: AppColors.surfaceContainerHighest,
                  ),
                ),
                Column(
                  children: [
                    for (var index = 0; index < events.length; index++)
                      _TimelineStep(
                        event: events[index],
                        isCurrent: active && index == events.length - 1,
                        isLast: index == events.length - 1 && !active,
                        nowLabel: l10n.now,
                      ),
                    if (active && !delivered) _PendingStep(l10n: l10n),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.event,
    required this.isCurrent,
    required this.isLast,
    required this.nowLabel,
  });

  final TimelineEvent event;
  final bool isCurrent;
  final bool isLast;
  final String nowLabel;

  @override
  Widget build(BuildContext context) {
    final failed = event.state == 'failed';
    final color = failed
        ? AppColors.error
        : isCurrent
            ? AppColors.primary
            : AppColors.tertiary;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              failed
                  ? Icons.close
                  : isCurrent
                      ? Icons.delivery_dining
                      : Icons.check,
              size: 18,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                event.title,
                                style: AppTypography.labelMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isCurrent
                                      ? AppColors.primary
                                      : AppColors.onSurface,
                                ),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                          child: Text(
                            nowLabel,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Text(
                          Fmt.time(
                            event.at.isEmpty ? event.time : event.at,
                          ),
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                    ],
                  ),
                  if (event.detail != null && event.detail!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        event.detail!,
                        style: AppTypography.bodySm.copyWith(
                          color: isCurrent
                              ? AppColors.onSurfaceVariant
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingStep extends StatelessWidget {
  const _PendingStep({required this.l10n});

  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt,
              size: 18,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.deliveredAndReceived,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            l10n.deliveredSoonDetail,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.deliverySoon,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBadge extends StatelessWidget {
  const _SectionBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
