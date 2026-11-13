import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/account.dart';
import 'providers.dart';
import 'session_controller.dart';

final favoritesProvider =
    AsyncNotifierProvider<FavoritesController, List<FavoriteRecord>>(FavoritesController.new);

/// Fast lookup used by cards and the details screen.
final favoriteIdsProvider = Provider<Set<String>>((ref) {
  final favorites = ref.watch(favoritesProvider).valueOrNull ?? const <FavoriteRecord>[];
  return favorites.map((f) => '${f.targetType}:${f.targetId}').toSet();
});

class FavoritesController extends AsyncNotifier<List<FavoriteRecord>> {
  @override
  Future<List<FavoriteRecord>> build() async {
    ref.watch(personalEpochProvider);
    if (ref.watch(sessionProvider).valueOrNull == null) return const [];
    return ref.read(favoritesRepositoryProvider).list();
  }

  bool isFavorite(String targetType, String targetId) {
    final current = state.valueOrNull ?? const <FavoriteRecord>[];
    return current.any((f) => f.targetType == targetType && f.targetId == targetId);
  }

  /// Adds or removes a favorite. Returns the new state (`true` = favorited).
  Future<bool> toggle({required String targetType, required String targetId}) async {
    final current = state.valueOrNull ?? const <FavoriteRecord>[];
    final existing = current.where(
      (f) => f.targetType == targetType && f.targetId == targetId,
    );
    final repo = ref.read(favoritesRepositoryProvider);
    if (existing.isNotEmpty) {
      await repo.remove(targetType: targetType, targetId: targetId);
      state = AsyncValue.data(
        current
            .where((f) => !(f.targetType == targetType && f.targetId == targetId))
            .toList(growable: false),
      );
      return false;
    }
    final added = await repo.add(targetType: targetType, targetId: targetId);
    state = AsyncValue.data([added, ...current]);
    return true;
  }

  Future<void> refresh() async {
    if (ref.read(sessionProvider).valueOrNull == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = AsyncValue.data(state.valueOrNull ?? const []);
    try {
      state = AsyncValue.data(await ref.read(favoritesRepositoryProvider).list());
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}
