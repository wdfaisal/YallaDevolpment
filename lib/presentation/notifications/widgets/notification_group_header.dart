import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../notifications_view_data.dart';

/// Date group label with the unread "new" pill and read-count label.
class NotificationGroupHeader extends StatelessWidget {
  const NotificationGroupHeader({
    super.key,
    required this.group,
    required this.unreadCount,
    required this.count,
  });

  final NotificationDateGroup group;
  final int unreadCount;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            _label(l10n),
            style: AppTypography.labelMd.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.newNotificationsCount(unreadCount),
                style: AppTypography.labelSm.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimaryFixedVariant,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (unreadCount == 0)
            Text(
              l10n.notificationCount(count),
              style: AppTypography.labelMd.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  String _label(L10n l10n) => switch (group) {
        NotificationDateGroup.today => l10n.notificationsGroupToday,
        NotificationDateGroup.yesterday => l10n.notificationsGroupYesterday,
        NotificationDateGroup.thisWeek => l10n.notificationsGroupThisWeek,
        NotificationDateGroup.older => l10n.notificationsGroupOlder,
      };
}
