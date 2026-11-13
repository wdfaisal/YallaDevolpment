import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/catalog.dart';

/// The five fixed service tiles from the Stitch home design. Availability is
/// read from the backend where a matching service key exists; the tile itself
/// is always rendered so the strip keeps the designed composition.
class HomeServices extends StatelessWidget {
  const HomeServices({
    super.key,
    required this.services,
    required this.onSelected,
  });

  final List<HomeService> services;
  final ValueChanged<HomeService> onSelected;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    final byKey = {for (final service in services) service.key: service};
    final specs = [
      _ServiceSpec(key: 'food', label: l10n.food, emoji: '🍔', emojiSize: 38),
      _ServiceSpec(
        key: 'parcel',
        label: l10n.parcel,
        emoji: '🛍️',
        emojiSize: 36,
        fastBadge: l10n.fastBadge,
      ),
      _ServiceSpec(key: 'grocery', label: l10n.grocery, emoji: '🥦', emojiSize: 36),
      _ServiceSpec(
        key: 'dineout',
        label: l10n.dineOut,
        emoji: '🍽️',
        emojiSize: 36,
        newBadge: l10n.newBadge,
      ),
      _ServiceSpec(key: 'pharmacy', label: l10n.pharmacy, emoji: '💊', emojiSize: 36),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < specs.length; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.md),
              _ServiceTile(
                spec: specs[index],
                service: byKey[specs[index].key] ??
                    HomeService(
                      key: specs[index].key,
                      enabled: false,
                      titleAr: specs[index].label,
                      titleEn: specs[index].label,
                    ),
                onTap: onSelected,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceSpec {
  const _ServiceSpec({
    required this.key,
    required this.label,
    required this.emoji,
    required this.emojiSize,
    this.fastBadge,
    this.newBadge,
  });

  final String key;
  final String label;
  final String emoji;
  final double emojiSize;
  final String? fastBadge;
  final String? newBadge;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.spec,
    required this.service,
    required this.onTap,
  });

  final _ServiceSpec spec;
  final HomeService service;
  final ValueChanged<HomeService> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => onTap(service),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.serviceTile,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.serviceTileBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        spec.emoji,
                        style: TextStyle(
                          fontSize: spec.emojiSize,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (spec.fastBadge != null)
                  PositionedDirectional(
                    top: -6,
                    start: 6,
                    child: _TileBadge(
                      label: spec.fastBadge!,
                      background: AppColors.primary,
                      trailing: '🚀',
                    ),
                  ),
                if (spec.newBadge != null)
                  PositionedDirectional(
                    top: -6,
                    start: 6,
                    child: _TileBadge(
                      label: spec.newBadge!,
                      background: const Color(0xFF1F2024),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              spec.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headlineSm.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileBadge extends StatelessWidget {
  const _TileBadge({
    required this.label,
    required this.background,
    this.trailing,
  });

  final String label;
  final Color background;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 2),
            Text(
              trailing!,
              style: const TextStyle(fontSize: 9, height: 1),
            ),
          ],
        ],
      ),
    );
  }
}
