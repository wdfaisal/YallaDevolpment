import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';

/// One choice in a [SegmentedTabs] control.
class SegmentedTabItem {
  const SegmentedTabItem({required this.label, this.count});

  final String label;

  /// Optional item count rendered next to the label, e.g. `المطاعم (3)`.
  final int? count;

  String get displayLabel => count == null ? label : '$label ($count)';
}

/// Flat segmented control shared by the list tabs (orders, favorites).
///
/// Each segment is a standalone pill: the selected one is filled with
/// [AppColors.primaryContainer], the rest stay white with a hairline border.
/// There is no gray track and no shadow, so the control matches the app's flat
/// white surfaces.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.gutter,
      AppSpacing.md,
      AppSpacing.gutter,
      AppSpacing.sm,
    ),
  });

  final List<SegmentedTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Segment(
                label: items[index].displayLabel,
                selected: index == selectedIndex,
                onTap: () => onSelect(index),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryContainer
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: selected
                  ? AppColors.primaryContainer
                  : AppColors.borderHairline,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMd.copyWith(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color:
                  selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
