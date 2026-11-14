import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';

/// One saved-address classification. The id is stored in the screen state; the
/// label is the exact string written to the backend `label` field.
class AddressTypeOption {
  const AddressTypeOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Four flat white classification chips. The selected chip keeps a white fill
/// and only switches to the orange hairline + filled icon, matching the Stitch
/// address form.
class AddressTypeSelector extends StatelessWidget {
  const AddressTypeSelector({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<AddressTypeOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _TypeChip(
              option: options[index],
              selected: options[index].id == selectedId,
              onTap: () => onSelected(options[index].id),
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AddressTypeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryContainer : AppColors.secondary;
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainer,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? option.activeIcon : option.icon,
                  size: 22, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(
                option.label,
                textAlign: TextAlign.center,
                style: AppTypography.labelMd.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
