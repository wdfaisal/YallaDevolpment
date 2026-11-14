import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../data/models/catalog.dart';

/// Hero image from the Stitch meal-detail design: full-bleed photo, a soft
/// top/bottom gradient for legibility, and floating glass pills. No shadows.
class MealHero extends StatelessWidget {
  const MealHero({
    super.key,
    required this.item,
    required this.l10n,
    required this.onClose,
  });

  final CatalogMenuItem item;
  final L10n l10n;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final percent = item.offerDiscountPercent;
    return SizedBox(
      height: 248,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppImage(
            url: item.imageUrl,
            borderRadius: BorderRadius.zero,
            backgroundColor: AppColors.surfaceContainer,
            icon: Icons.fastfood_outlined,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.72),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.38),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
          PositionedDirectional(
            top: AppSpacing.sm,
            start: AppSpacing.md,
            end: AppSpacing.md,
            child: Row(
              children: [
                _HeroCircleButton(
                  icon: Icons.close,
                  tooltip: l10n.close,
                  onTap: onClose,
                ),
                const Spacer(),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                FavoriteButton(
                  targetType: 'menu_item',
                  targetId: item.id,
                  size: 36,
                  background: Colors.black.withValues(alpha: 0.45),
                  foregroundColor: Colors.white,
                  borderColor: Colors.white.withValues(alpha: 0.18),
                ),
              ],
            ),
          ),
          if (item.hasOffer && percent != null)
            PositionedDirectional(
              top: 56,
              end: AppSpacing.md,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  l10n.discountBadge('$percent%'),
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          PositionedDirectional(
            bottom: AppSpacing.md,
            start: AppSpacing.md,
            end: AppSpacing.md,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (item.calories != null)
                  _HeroChip(
                    icon: Icons.local_fire_department_outlined,
                    iconColor: AppColors.primaryFixed,
                    label: l10n.caloriesLabel(item.calories!),
                  ),
                if (item.prepMinutes > 0)
                  _HeroChip(
                    icon: Icons.schedule,
                    iconColor: AppColors.tertiaryFixed,
                    label: '${item.prepMinutes} ${l10n.minuteShort}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Restaurant label, dish name, description and the live price with the
/// original amount struck through when an offer is active.
class MealHeading extends StatelessWidget {
  const MealHeading({
    super.key,
    required this.item,
    required this.l10n,
  });

  final CatalogMenuItem item;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.restaurantName.isNotEmpty)
          Text(
            item.restaurantName,
            style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
          ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.name,
                style: AppTypography.headlineLgMobile,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      Fmt.money(item.effectivePriceMinor),
                      style: AppTypography.headlineMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      l10n.currencyDefault,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (item.hasOffer)
                  Text(
                    '${Fmt.money(item.priceMinor)} ${l10n.currencyDefault}',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.secondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.description,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.secondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// One option group: orange section marker, required/optional pill, hint and
/// flat option cards.
class MealOptionSection extends StatelessWidget {
  const MealOptionSection({
    super.key,
    required this.group,
    required this.selected,
    required this.l10n,
    required this.onToggle,
  });

  final MenuOptionGroup group;
  final Set<String> selected;
  final L10n l10n;
  final ValueChanged<MenuOption> onToggle;

  @override
  Widget build(BuildContext context) {
    final required = group.effectiveMin > 0;
    final hint = group.isSingle
        ? (required ? l10n.chooseOne : l10n.optional)
        : '${l10n.chooseUpTo} ${group.maxSelect}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                group.name(l10n.isArabic),
                style: AppTypography.headlineSm,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: required
                    ? AppColors.orangeTintSoft
                    : AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                required ? l10n.required : l10n.optional,
                style: AppTypography.labelSm.copyWith(
                  color: required
                      ? AppColors.primary
                      : AppColors.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
          child: Text(
            hint,
            style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final option in group.options) ...[
          MealOptionCard(
            option: option,
            selected: selected.contains(option.id),
            single: group.isSingle,
            l10n: l10n,
            onTap: () => onToggle(option),
          ),
          if (option != group.options.last)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class MealOptionCard extends StatelessWidget {
  const MealOptionCard({
    super.key,
    required this.option,
    required this.selected,
    required this.single,
    required this.l10n,
    required this.onTap,
  });

  final MenuOption option;
  final bool selected;
  final bool single;
  final L10n l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = option.available;
    final description = l10n.isArabic
        ? option.descriptionAr
        : (option.descriptionEn.isEmpty
            ? option.descriptionAr
            : option.descriptionEn);
    return Material(
      color: selected
          ? AppColors.primaryFixed.withValues(alpha: 0.28)
          : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                single
                    ? (selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked)
                    : (selected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank),
                size: 20,
                color: !enabled
                    ? AppColors.surfaceDim
                    : (selected ? AppColors.primary : AppColors.secondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name(l10n.isArabic),
                      style: AppTypography.labelLg.copyWith(
                        color: enabled
                            ? AppColors.onSurface
                            : AppColors.surfaceDim,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!enabled) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.unavailable,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ] else if (option.priceDeltaMinor != 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${option.priceDeltaMinor > 0 ? '+' : ''}'
                  '${Fmt.money(option.priceDeltaMinor)}',
                  style: AppTypography.labelMd.copyWith(
                    color: selected ? AppColors.primary : AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Free-form notes block with a flat, borderless field.
class MealNotesField extends StatelessWidget {
  const MealNotesField({
    super.key,
    required this.controller,
    required this.l10n,
  });

  final TextEditingController controller;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.edit_note,
              size: 18,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.specialInstructions,
              style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          maxLines: 2,
          maxLength: 200,
          textInputAction: TextInputAction.done,
          style: AppTypography.bodyMd,
          decoration: InputDecoration(
            hintText: l10n.notesHint,
            counterText: '',
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sticky bottom bar: quantity stepper plus the orange add-to-cart CTA with the
/// live total. Hairline border only, no elevation.
class MealActionBar extends StatelessWidget {
  const MealActionBar({
    super.key,
    required this.quantity,
    required this.totalMinor,
    required this.currency,
    required this.l10n,
    required this.onQuantity,
    required this.onAdd,
    required this.adding,
    required this.enabled,
  });

  final int quantity;
  final int totalMinor;
  final String currency;
  final L10n l10n;
  final ValueChanged<int> onQuantity;
  final VoidCallback onAdd;
  final bool adding;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              QuantityStepper(
                value: quantity,
                onChanged: onQuantity,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: enabled ? onAdd : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.surfaceContainerHigh,
                      disabledForegroundColor: AppColors.secondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: adding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Row(
                            children: [
                              const Icon(Icons.shopping_bag_outlined, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  l10n.addToBasket,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.headlineSm.copyWith(
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                Fmt.money(totalMinor),
                                style: AppTypography.headlineSm.copyWith(
                                  color: AppColors.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                currency,
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.onPrimary.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
