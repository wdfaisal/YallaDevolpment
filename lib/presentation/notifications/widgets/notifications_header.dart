import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';

/// 56px notification header from the Stitch notification design: back button,
/// title, "mark all read", settings and the profile avatar.
class NotificationsHeader extends StatelessWidget {
  const NotificationsHeader({
    super.key,
    required this.unreadCount,
    required this.onBack,
    required this.onMarkAllRead,
    required this.onOpenSettings,
    required this.onOpenAccount,
    this.enabled = true,
  });

  final int unreadCount;
  final VoidCallback onBack;
  final VoidCallback onMarkAllRead;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAccount;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final canMarkAll = enabled && unreadCount > 0;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.profileBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 24),
            color: AppColors.onSurface,
            tooltip: l10n.back,
            onPressed: onBack,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              l10n.notifications,
              style: AppTypography.labelLg.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _MarkAllButton(
            label: l10n.markAllReadAction,
            active: canMarkAll,
            onTap: canMarkAll ? onMarkAllRead : null,
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 22),
            color: AppColors.onSurfaceVariant,
            tooltip: l10n.notificationSettings,
            onPressed: onOpenSettings,
          ),
          const SizedBox(width: 2),
          Semantics(
            button: true,
            label: l10n.account,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onOpenAccount,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _MarkAllButton extends StatelessWidget {
  const _MarkAllButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.profileMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
