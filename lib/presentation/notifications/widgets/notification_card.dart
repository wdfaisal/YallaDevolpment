import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/account.dart';
import '../notifications_view_data.dart';

enum _CardAction { markRead, viewOrder }

/// White notification card with the unread accent bar, icon tile and actions.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.item,
    required this.arabic,
    required this.onOpen,
    required this.onMarkRead,
  });

  final CustomerNotification item;
  final bool arabic;
  final VoidCallback onOpen;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final unread = item.isUnread;
    final hasOrderId = hasOrder(item);
    final active = isOrderActive(item);
    final visual = _visualFor(item);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onOpen,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.notificationCardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      visual.icon,
                      size: 24,
                      color: visual.foreground,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    item.title(arabic),
                                    style: AppTypography.labelLg.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                      height: 1.35,
                                    ),
                                  ),
                                  if (unread)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l10n.newBadge,
                                        style: AppTypography.labelSm.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryContainer,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              Fmt.relative(item.createdAt, isArabic: arabic),
                              style: AppTypography.labelMd.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (item.body(arabic).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.body(arabic),
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              height: 1.55,
                            ),
                          ),
                        ],
                        if (hasOrderId) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          AppColors.primaryContainer,
                                      foregroundColor: AppColors.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: onOpen,
                                    icon: Icon(
                                      active
                                          ? Icons.near_me
                                          : Icons.receipt_long,
                                      size: 16,
                                    ),
                                    label: Text(
                                      active
                                          ? l10n.trackOrderFull
                                          : l10n.viewOrder,
                                      style: AppTypography.labelMd.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _MoreMenu(
                                unread: unread,
                                hasOrder: true,
                                onSelected: (action) => _handleAction(
                                  action,
                                  onMarkRead,
                                  onOpen,
                                ),
                              ),
                            ],
                          ),
                        ] else if (unread)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _MoreMenu(
                              unread: unread,
                              hasOrder: false,
                              onSelected: (action) => _handleAction(
                                action,
                                onMarkRead,
                                onOpen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (unread)
          PositionedDirectional(
            start: -2,
            top: 16,
            bottom: 16,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }

  void _handleAction(
    _CardAction action,
    VoidCallback onMarkRead,
    VoidCallback onOpen,
  ) {
    switch (action) {
      case _CardAction.markRead:
        onMarkRead();
        break;
      case _CardAction.viewOrder:
        onOpen();
        break;
    }
  }

  _NotificationVisual _visualFor(CustomerNotification item) {
    return switch (item.kind) {
      'order' || 'order_status' || 'delivery' => const _NotificationVisual(
          icon: Icons.delivery_dining,
          background: AppColors.primaryFixed,
          foreground: AppColors.onPrimaryFixedVariant,
        ),
      'offer' ||
      'promo' ||
      'promotion' ||
      'coupon' ||
      'discount' =>
        const _NotificationVisual(
          icon: Icons.local_fire_department,
          background: AppColors.orangeContainerActive,
          foreground: AppColors.primaryContainer,
        ),
      'wallet' || 'payment' => const _NotificationVisual(
          icon: Icons.savings,
          background: AppColors.tertiaryFixed,
          foreground: AppColors.onTertiaryFixed,
        ),
      'loyalty' || 'points' => const _NotificationVisual(
          icon: Icons.stars,
          background: AppColors.secondaryFixed,
          foreground: AppColors.onSecondaryFixed,
        ),
      'support' || 'ticket' => const _NotificationVisual(
          icon: Icons.support_agent,
          background: AppColors.secondaryFixed,
          foreground: AppColors.onSecondaryFixed,
        ),
      'account' || 'auth' || 'security' => const _NotificationVisual(
          icon: Icons.verified_user,
          background: AppColors.surfaceContainer,
          foreground: AppColors.secondary,
        ),
      _ => const _NotificationVisual(
          icon: Icons.notifications_active,
          background: AppColors.surfaceContainer,
          foreground: AppColors.secondary,
        ),
    };
  }
}

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.unread,
    required this.hasOrder,
    required this.onSelected,
  });

  final bool unread;
  final bool hasOrder;
  final ValueChanged<_CardAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<_CardAction>(
        tooltip: unread ? l10n.notificationMarkRead : l10n.more,
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.more_vert,
          size: 18,
          color: AppColors.onSurfaceVariant,
        ),
        onSelected: onSelected,
        itemBuilder: (context) => [
          if (unread)
            PopupMenuItem(
              value: _CardAction.markRead,
              child: Row(
                children: [
                  const Icon(Icons.done, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.notificationMarkRead),
                ],
              ),
            ),
          if (hasOrder)
            PopupMenuItem(
              value: _CardAction.viewOrder,
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.viewOrder),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
