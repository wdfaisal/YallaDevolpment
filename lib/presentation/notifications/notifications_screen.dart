import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/design/app_spacing.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/account.dart';
import '../../data/push/push_service.dart';
import '../../state/account_controllers.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import 'notifications_view_data.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_empty_state.dart';
import 'widgets/notification_filter_bar.dart';
import 'widgets/notification_group_header.dart';
import 'widgets/notification_settings_card.dart';
import 'widgets/notifications_header.dart';

/// Notification center rebuilt from the Stitch notification design. Every
/// value shown here is derived from the live backend page or the local
/// persisted preference; nothing is invented.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();
  NotificationFilter _filter = NotificationFilter.all;

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
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 240) {
      return;
    }
    ref.read(notificationsProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final enabled = ref.watch(notificationsEnabledProvider);
    final pushStatus = ref.watch(pushStatusProvider);
    final pushNote = _pushNote(l10n, pushStatus);
    // A failure is retryable everywhere. A denial is only retryable in a
    // browser, where the permission prompt needs a fresh user gesture; on a
    // phone a denied permission is changed in the system settings instead.
    final canRetryPush = pushStatus == PushStatus.failed ||
        (pushStatus == PushStatus.denied && kIsWeb);
    final pageAsync = ref.watch(notificationsProvider);
    final page = pageAsync.valueOrNull;
    final unread = page?.unreadCount ?? 0;
    final counts =
        page == null ? const <NotificationFilter, int>{} : filterCounts(page);

    return AppScaffold(
      header: NotificationsHeader(
        unreadCount: unread,
        enabled: signedIn && enabled,
        onBack: () => context.canPop() ? context.pop() : context.go('/account'),
        onMarkAllRead: () => _markAllRead(l10n),
        onOpenSettings: () => context.push('/account/settings'),
        onOpenAccount: () => context.go('/account'),
      ),
      onRefresh: signedIn && enabled
          ? () => ref.read(notificationsProvider.notifier).refresh()
          : null,
      body: Column(
        children: [
          if (signedIn)
            NotificationFilterBar(
              selected: _filter,
              counts: counts,
              unreadCount: enabled ? unread : 0,
              onSelected: (filter) => setState(() => _filter = filter),
              onMarkAllRead: () => _markAllRead(l10n),
            ),
          Expanded(
            child: _buildBody(
              l10n: l10n,
              signedIn: signedIn,
              enabled: enabled,
              pushNote: pushNote,
              canRetryPush: canRetryPush,
              pageAsync: pageAsync,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required L10n l10n,
    required bool signedIn,
    required bool enabled,
    required String? pushNote,
    required bool canRetryPush,
    required AsyncValue<NotificationPage> pageAsync,
  }) {
    if (!signedIn) {
      return NotificationEmptyState(
        title: l10n.noNotifications,
        message: l10n.notAuthorized,
        actionLabel: l10n.signIn,
        onAction: () => context.push('/login?next=/account/notifications'),
      );
    }
    if (!enabled) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          NotificationEmptyState(
            title: l10n.notificationsDisabledTitle,
            message: l10n.notificationsDisabledMessage,
            actionLabel: l10n.enableNotifications,
            onAction: () => ref
                .read(notificationsEnabledProvider.notifier)
                .setEnabled(true),
          ),
          NotificationSettingsCard(
            enabled: false,
            onChanged: (value) => ref
                .read(notificationsEnabledProvider.notifier)
                .setEnabled(value),
            onManage: () => context.push('/account/settings'),
            versionLabel: _versionLabel(l10n),
            pushNote: pushNote,
            pushActionLabel: canRetryPush ? l10n.pushEnableAction : null,
            onPushAction: canRetryPush ? _enablePush : null,
          ),
        ],
      );
    }
    return AsyncView(
      value: pageAsync,
      onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
      builder: (data) {
        final visible = filterNotifications(data.items, _filter);
        final groups = groupNotifications(visible);
        final children = <Widget>[];

        if (data.items.isEmpty) {
          children.add(
            NotificationEmptyState(
              title: l10n.noNotifications,
              message: l10n.notificationsEmptyMessage,
            ),
          );
        } else if (visible.isEmpty) {
          children.add(
            NotificationEmptyState(
              title: l10n.notificationsEmptyTitle,
              message: l10n.notificationsEmptyMessage,
              actionLabel: l10n.backToAllNotifications,
              onAction: () => setState(
                () => _filter = NotificationFilter.all,
              ),
            ),
          );
        } else {
          for (final group in groups) {
            children.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: NotificationGroupHeader(
                  group: group.group,
                  unreadCount: group.unreadCount,
                  count: group.items.length,
                ),
              ),
            );
            for (final item in group.items) {
              children.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: NotificationCard(
                    item: item,
                    arabic: l10n.isArabic,
                    onOpen: () => _open(item),
                    onMarkRead: () => _markRead(item, l10n),
                  ),
                ),
              );
            }
          }
        }

        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: NotificationSettingsCard(
              enabled: true,
              onChanged: (value) => ref
                  .read(notificationsEnabledProvider.notifier)
                  .setEnabled(value),
              onManage: () => context.push('/account/settings'),
              versionLabel: _versionLabel(l10n),
              pushNote: pushNote,
              pushActionLabel: canRetryPush ? l10n.pushEnableAction : null,
              onPushAction: canRetryPush ? _enablePush : null,
            ),
          ),
        );
        if (data.hasMore) {
          children.add(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: LoadingState(),
            ),
          );
        }
        children.add(const SizedBox(height: AppSpacing.xxxl));

        return ListView(
          controller: _scroll,
          padding: EdgeInsets.zero,
          children: children,
        );
      },
    );
  }

  String? _pushNote(L10n l10n, PushStatus status) {
    switch (status) {
      case PushStatus.unconfigured:
        return l10n.pushUnavailableNote;
      case PushStatus.initializing:
        return null;
      case PushStatus.denied:
        return l10n.pushDeniedNote;
      case PushStatus.failed:
        return l10n.pushFailedNote;
      case PushStatus.ready:
        return l10n.pushReadyNote;
    }
  }

  String _versionLabel(L10n l10n) => '${l10n.versionShort} ${Env.appVersion}';

  /// Retries OS push from a real tap. Browsers only allow the notification
  /// permission prompt inside a user gesture, so this is what turns a `denied`
  /// or `failed` web state into a working token.
  Future<void> _enablePush() async {
    final service = ref.read(pushServiceProvider);
    await service.registerCurrentToken();
    if (!mounted) return;
    ref.read(pushStatusProvider.notifier).set(service.status);
  }

  Future<void> _open(CustomerNotification item) async {
    await _markRead(item, L10n.of(context));
    if (!mounted) return;
    final orderId = item.orderId;
    if (orderId != null && orderId.isNotEmpty) {
      context.push('/orders/$orderId');
    }
  }

  Future<void> _markRead(CustomerNotification item, L10n l10n) async {
    if (!item.isUnread) return;
    try {
      await ref.read(notificationsProvider.notifier).markRead(item.id);
    } catch (error) {
      if (!mounted) return;
      showAppSnack(
        context,
        error is ApiException ? error.message : l10n.somethingWentWrong,
        isError: true,
      );
    }
  }

  Future<void> _markAllRead(L10n l10n) async {
    final page = ref.read(notificationsProvider).valueOrNull;
    if (page == null || page.unreadCount == 0) return;
    try {
      await ref.read(notificationsProvider.notifier).markAllRead();
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
