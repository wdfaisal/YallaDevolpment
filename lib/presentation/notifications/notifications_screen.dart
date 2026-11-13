import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/account.dart';
import '../../state/account_controllers.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';

/// Notification center. Unread counts and read state come from the backend.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 240) return;
    ref.read(notificationsProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final page = ref.watch(notificationsProvider);
    final unread = page.valueOrNull?.unreadCount ?? 0;

    return AppScaffold(
      header: SimpleHeader(
        title: l10n.notifications,
        onBack: () => context.pop(),
        actions: [
          if (signedIn && unread > 0)
            HeaderIconButton(
              icon: Icons.done_all,
              tooltip: l10n.markAllRead,
              onTap: () => _markAllRead(l10n),
            ),
        ],
      ),
      onRefresh: signedIn
          ? () => ref.read(notificationsProvider.notifier).refresh()
          : null,
      body: !signedIn
          ? EmptyState(
              title: l10n.noNotifications,
              message: l10n.notAuthorized,
              icon: Icons.notifications_none,
              actionLabel: l10n.signIn,
              onAction: () => context.push('/login?next=/account/notifications'),
            )
          : AsyncView(
              value: page,
              onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
              builder: (data) {
                if (data.items.isEmpty) {
                  return EmptyState(
                    title: l10n.noNotifications,
                    icon: Icons.notifications_none,
                  );
                }
                return ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: data.items.length + (data.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index >= data.items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: LoadingState(),
                      );
                    }
                    final item = data.items[index];
                    return _NotificationTile(
                      item: item,
                      arabic: l10n.isArabic,
                      onTap: () => _open(item),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _open(CustomerNotification item) async {
    if (item.isUnread) {
      try {
        await ref.read(notificationsProvider.notifier).markRead(item.id);
      } catch (_) {
        // Opening the destination is still useful if marking read fails.
      }
    }
    if (!mounted) return;
    final orderId = item.orderId;
    if (orderId != null && orderId.isNotEmpty) {
      context.push('/orders/$orderId');
    }
  }

  Future<void> _markAllRead(L10n l10n) async {
    try {
      await ref.read(notificationsProvider.notifier).markAllRead();
      if (!mounted) return;
      showAppSnack(context, l10n.markAllRead);
    } catch (error) {
      if (!mounted) return;
      showAppSnack(
        context,
        error is ApiException ? error.message : l10n.somethingWentWrong,
        isError: true,
      );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.arabic,
    required this.onTap,
  });

  final CustomerNotification item;
  final bool arabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = item.isUnread;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: unread
              ? AppColors.orangeTintSubtle
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: unread ? AppColors.primaryFixedDim : AppColors.surfaceContainerHigh,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(_icon(item.kind), size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title(arabic),
                          style: AppTypography.labelLg.copyWith(
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body(arabic),
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.secondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Fmt.relative(item.createdAt, isArabic: arabic),
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String kind) {
    return switch (kind) {
      'order' || 'order_status' => Icons.receipt_long_outlined,
      'offer' || 'promo' => Icons.local_activity_outlined,
      'wallet' || 'payment' => Icons.account_balance_wallet_outlined,
      'loyalty' || 'points' => Icons.stars_outlined,
      'support' || 'ticket' => Icons.support_agent,
      _ => Icons.notifications_none,
    };
  }
}
