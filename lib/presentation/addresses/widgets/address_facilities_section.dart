import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';

/// One delivery facility the captain should know about. The label is stored
/// inside the backend `instructions` text, so it must stay stable.
class AddressFacilityOption {
  const AddressFacilityOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// Facility pills plus the captain note. Selected pills use the soft green
/// treatment from the design; unselected pills stay white with a hairline.
class AddressFacilitiesSection extends StatefulWidget {
  const AddressFacilitiesSection({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.instructions,
    required this.instructionsLabel,
    required this.instructionsHint,
  });

  final List<AddressFacilityOption> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final TextEditingController instructions;
  final String instructionsLabel;
  final String instructionsHint;

  @override
  State<AddressFacilitiesSection> createState() =>
      _AddressFacilitiesSectionState();
}

class _AddressFacilitiesSectionState extends State<AddressFacilitiesSection> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_handleFocus);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  void _handleFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in widget.options)
              _FacilityChip(
                option: option,
                selected: widget.selected.contains(option.id),
                onTap: () => widget.onToggle(option.id),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Icon(
              Icons.notifications_active,
              size: 15,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                widget.instructionsLabel,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 11,
                  color: AppColors.secondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: _focus.hasFocus
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainer,
            ),
          ),
          child: TextField(
            controller: widget.instructions,
            focusNode: _focus,
            minLines: 2,
            maxLines: 3,
            maxLength: 400,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            cursorColor: AppColors.primaryContainer,
            style: AppTypography.bodySm.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.6,
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: '',
              hintText: widget.instructionsHint,
              hintStyle: AppTypography.bodySm.copyWith(
                fontSize: 12,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FacilityChip extends StatelessWidget {
  const _FacilityChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AddressFacilityOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.tertiary : AppColors.secondary;
    return Material(
      color: selected
          ? AppColors.tertiaryFixed.withValues(alpha: 0.3)
          : AppColors.surfaceContainerLowest,
      shape: StadiumBorder(
        side: BorderSide(
          color:
              selected ? AppColors.tertiaryFixed : AppColors.surfaceContainer,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle : option.icon,
                size: 16,
                color: foreground,
              ),
              const SizedBox(width: 5),
              Text(
                option.label,
                style: AppTypography.labelMd.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
