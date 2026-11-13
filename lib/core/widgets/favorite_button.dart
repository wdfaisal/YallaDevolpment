import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/app_colors.dart';
import '../localization/l10n.dart';
import '../../state/favorites_controller.dart';
import '../../state/session_controller.dart';
import 'snack.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.targetType,
    required this.targetId,
    this.size = 30,
    this.background = AppColors.surfaceContainerLow,
    this.foregroundColor,
    this.borderColor,
    this.onChanged,
  });

  final String targetType;
  final String targetId;
  final double size;
  final Color background;

  /// Overrides the heart color; used on top of dark imagery.
  final Color? foregroundColor;

  /// Optional hairline border for translucent hero buttons.
  final Color? borderColor;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = '$targetType:$targetId';
    final isFavorite = ref.watch(favoriteIdsProvider).contains(key);
    return InkWell(
      borderRadius: BorderRadius.circular(size),
      onTap: () async {
        if (ref.read(sessionProvider).valueOrNull == null) {
          showAppSnack(context, L10n.of(context).notAuthorized);
          return;
        }
        try {
          final result = await ref
              .read(favoritesProvider.notifier)
              .toggle(targetType: targetType, targetId: targetId);
          onChanged?.call(result);
          if (context.mounted) {
            final l10n = L10n.of(context);
            showAppSnack(
              context,
              result ? l10n.favoriteAdded : l10n.favoriteRemoved,
            );
          }
        } catch (_) {
          if (context.mounted) {
            showAppSnack(context, L10n.of(context).somethingWentWrong, isError: true);
          }
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: borderColor == null
              ? null
              : Border.all(color: borderColor!),
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: size * 0.55,
          color: foregroundColor ??
              (isFavorite ? AppColors.primary : AppColors.onSurface),
        ),
      ),
    );
  }
}
