import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/localization/l10n.dart';
import '../../data/push/push_service.dart';
import '../../navigation/app_router.dart';
import '../../state/account_controllers.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';

/// Owns the Firebase Messaging side effects: permission, token registration,
/// foreground alerts and notification taps.
///
/// It is a complete no-op when the build has no Firebase credentials, so the
/// backend-driven notification center remains the source of truth.
class PushLifecycle extends ConsumerStatefulWidget {
  const PushLifecycle({
    super.key,
    required this.child,
    required this.messengerKey,
  });

  final Widget child;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  @override
  ConsumerState<PushLifecycle> createState() => _PushLifecycleState();
}

class _PushLifecycleState extends ConsumerState<PushLifecycle> {
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (Env.firebasePushConfigured) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;

    final service = ref.read(pushServiceProvider);
    final status = await service.initialize();
    if (!mounted) return;
    // `initializing` means Firebase loaded but no token is registered yet (for
    // example a guest); it deliberately shows no note.
    if (status == PushStatus.unconfigured || status == PushStatus.failed) {
      ref.read(pushStatusProvider.notifier).set(status);
      return;
    }

    _subscriptions.add(service.foregroundMessages.listen(_onForeground));
    _subscriptions.add(service.openedMessages.listen(_onOpened));
    _subscriptions.add(
      service.tokenRefreshes.listen((_) => _registerIfSignedIn()),
    );

    final initial = await service.initialMessage();
    if (initial != null && mounted) _onOpened(initial);

    // Ask for the OS permission on first open, before sign-in, so the prompt is
    // not deferred until the customer's first order. A guest gets a cached
    // token that is registered as soon as the account signs in.
    final prepared = await service.prepareForPush();
    if (!mounted) return;
    ref.read(pushStatusProvider.notifier).set(prepared);
    if (prepared == PushStatus.denied || prepared == PushStatus.failed) {
      return;
    }

    await _registerIfSignedIn();
  }

  Future<void> _registerIfSignedIn() async {
    if (!ref.read(isSignedInProvider)) return;
    final service = ref.read(pushServiceProvider);
    await service.registerCurrentToken();
    if (!mounted) return;
    ref.read(pushStatusProvider.notifier).set(service.status);
  }

  void _onForeground(PushMessage message) {
    if (!mounted) return;
    ref.read(notificationsProvider.notifier).refresh();

    final l10n = L10n.of(context);
    final title = message.title.isEmpty ? l10n.notifications : message.title;
    final messenger = widget.messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(title),
          action: message.orderId == null
              ? null
              : SnackBarAction(
                  label: l10n.viewOrder,
                  onPressed: () => _navigateToOrder(message.orderId!),
                ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  void _onOpened(PushMessage message) {
    if (!mounted) return;
    ref.read(notificationsProvider.notifier).refresh();
    final orderId = message.orderId;
    if (orderId == null || orderId.isEmpty) return;
    _navigateToOrder(orderId);
  }

  void _navigateToOrder(String orderId) {
    ref.read(routerProvider).push('/orders/$orderId');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(isSignedInProvider, (previous, next) {
      if (next) {
        _registerIfSignedIn();
      } else {
        ref.read(pushServiceProvider).unregisterStoredToken();
      }
    });
    return widget.child;
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
