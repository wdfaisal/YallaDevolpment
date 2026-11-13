import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../notifications_view_data.dart';

/// Sticky filter chips plus the unread notice bar from the Stitch design.
class NotificationFilterBar extends StatelessWidget {
  const NotificationFilterBar({
    super.key,
    required this.selected,
    required this.counts,
    required this.unreadCount,
    required this.onSelected,
    required this.onMarkAllRead,
  });

  final NotificationFilter selected;
  final Map<NotificationFilter, int> counts;
  final int unreadCount;
  final ValueChanged<NotificationFilter> onSelected;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: l10n.notificationsAllFilter,
                    count: counts[NotificationFilter.all] ?? 0,
                    active: selected == NotificationFilter.all,
                    onTap: () => onSelected(NotificationFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.notificationsOrdersFilter,
                    count: counts[NotificationFilter.orders] ?? 0,
                    active: selected == NotificationFilter.orders,
                    showDot: true,
                    highlightCount: true,
                    onTap: () => onSelected(NotificationFilter.orders),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.notificationsOffersFilter,
                    count: counts[NotificationFilter.offers] ?? 0,
                    active: selected == NotificationFilter.offers,
                    icon: Icons.local_offer,
                    onTap: () => onSelected(NotificationFilter.offers),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.notificationsAccountFilter,
                    count: counts[NotificationFilter.account] ?? 0,
                    active: selected == NotificationFilter.account,
                    icon: Icons.account_balance_wallet,
                    onTap: () => onSelected(NotificationFilter.account),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: _UnreadBar(
              unreadCount: unreadCount,
              onMarkAllRead: onMarkAllRead,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
    this.icon,
    this.showDot = false,
    this.highlightCount = false,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final bool showDot;

  /// Mirrors the Stitch accent used by the orders chip counter badge.
  final bool highlightCount;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AppColors.onPrimary : AppColors.onSurface;
    return Material(
      color:
          active ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x40FF591B),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDot)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              if (icon != null)
                Icon(
                  icon,
                  size: 15,
                  color:
                      active ? AppColors.onPrimary : AppColors.primaryContainer,
                ),
              if (showDot || icon != null) const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMd.copyWith(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 6),
              _ChipCount(
                  count: count, active: active, highlight: highlightCount),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipCount extends StatelessWidget {
  const _ChipCount({
    required this.count,
    required this.active,
    this.highlight = false,
  });

  final int count;
  final bool active;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (active) {
      background = Colors.white.withValues(alpha: 0.2);
      foreground = AppColors.onPrimary;
    } else if (highlight) {
      background = AppColors.primaryFixed;
      foreground = AppColors.onPrimaryFixedVariant;
    } else {
      background = AppColors.surfaceContainerHigh;
      foreground = AppColors.onSurfaceVariant;
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppTypography.labelSm.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
          color: foreground,
        ),
      ),
    );
  }
}

class _UnreadBar extends StatelessWidget {
  const _UnreadBar({
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    if (unreadCount == 0) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.tertiary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.allNotificationsRead,
              style: AppTypography.labelMd.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.tertiary,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${l10n.unreadNotificationsPrefix} '),
                      TextSpan(
                        text: '$unreadCount',
                        style: const TextStyle(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' ${l10n.unreadNotificationsSuffix}'),
                    ],
                  ),
                  style: AppTypography.labelMd.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onMarkAllRead,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.done_all,
                  size: 16,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.markAllReadAction,
                  style: AppTypography.labelMd.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
