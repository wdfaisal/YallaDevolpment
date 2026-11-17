import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_exception.dart';
import '../data/models/customer.dart';
import 'providers.dart';

/// Increments whenever the signed-in identity changes (sign-in, sign-out,
/// expired session). Personal-data providers watch it and rebuild, which keeps
/// session handling free of import cycles.
final personalEpochProvider =
    NotifierProvider<PersonalEpoch, int>(PersonalEpoch.new);

class PersonalEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

/// The signed-in customer, or `null` for a guest. The session is restored from
/// the secure token on launch and validated against the backend.
final sessionProvider =
    AsyncNotifierProvider<SessionController, CustomerProfile?>(
  SessionController.new,
);

/// True when a customer session exists.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider).valueOrNull != null;
});

class SessionController extends AsyncNotifier<CustomerProfile?> {
  @override
  Future<CustomerProfile?> build() async {
    final store = ref.read(tokenStoreProvider);
    final token = await store.read();
    if (token == null || token.isEmpty) return null;
    try {
      return await ref.read(authRepositoryProvider).me();
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await store.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<void> signIn(CustomerSession session) async {
    if (session.token != null && session.token!.isNotEmpty) {
      await ref.read(tokenStoreProvider).write(session.token!);
    }
    state = AsyncValue.data(session.customer);
    ref.read(personalEpochProvider.notifier).bump();
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    if (previous != null) state = AsyncValue.data(previous);
    try {
      state = AsyncValue.data(await ref.read(authRepositoryProvider).me());
    } on ApiException catch (error, stack) {
      if (error.isUnauthorized) {
        await expire();
        return;
      }
      state = AsyncValue.error(error, stack);
    }
  }

  Future<CustomerProfile> updateProfile({
    String? name,
    String? email,
    String? language,
    bool clearEmail = false,
  }) async {
    final updated = await ref.read(authRepositoryProvider).updateProfile(
          name: name,
          email: email,
          language: language,
          clearEmail: clearEmail,
        );
    state = AsyncValue.data(updated);
    return updated;
  }

  /// Clears local credentials when the backend rejects the session.
  Future<void> expire() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncValue.data(null);
    ref.read(personalEpochProvider.notifier).bump();
  }

  Future<void> signOut() async {
    // Remove this device from the account while the session is still valid, so
    // a signed-out phone stops receiving the account's order pushes.
    await ref.read(pushServiceProvider).unregisterStoredToken();
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Local sign-out must always succeed even if the server is unreachable.
    }
    await expire();
  }
}
