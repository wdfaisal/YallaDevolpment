import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/customer.dart';
import 'checkout_section_card.dart';

/// Delivery address selector with the default badge and the driver-instructions
/// shortcut from the Stitch design.
class CheckoutAddressCard extends StatelessWidget {
  const CheckoutAddressCard({
    super.key,
    required this.address,
    required this.l10n,
    required this.onChange,
    this.onEditInstructions,
  });

  final CustomerAddressRecord? address;
  final L10n l10n;
  final VoidCallback onChange;
  final VoidCallback? onEditInstructions;

  @override
  Widget build(BuildContext context) {
    final selected = address;
    return CheckoutSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.deliveryAddress,
                  style: AppTypography.labelLg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected != null)
                TextButton(
                  onPressed: onChange,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.changeAddress,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (selected == null) ...[
            Text(
              l10n.addAddressToSeeNearby,
              style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onChange,
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: Text(l10n.addAddress),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                selected.label,
                                style: AppTypography.labelLg.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (selected.isDefault) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm,
                                  ),
                                ),
                                child: Text(
                                  l10n.defaultAddress,
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onPrimaryFixedVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selected.address,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.secondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (selected.instructions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              selected.instructions,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.secondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (onEditInstructions != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                              onTap: onEditInstructions,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.add_location_alt_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        l10n.addDriverInstructions,
                                        style: AppTypography.labelSm.copyWith(
                                          color: AppColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
        ],
      ),
    );
  }
}
