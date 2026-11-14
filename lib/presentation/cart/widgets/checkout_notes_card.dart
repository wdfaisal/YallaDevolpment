import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import 'checkout_section_card.dart';

/// Extra instructions for the restaurant and driver.
class CheckoutNotesCard extends StatelessWidget {
  const CheckoutNotesCard({
    super.key,
    required this.controller,
    required this.l10n,
  });

  final TextEditingController controller;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      borderSide: const BorderSide(color: AppColors.borderSubtle),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
    );
    return CheckoutSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckoutSectionHeader(
            icon: Icons.edit_note,
            title: l10n.orderNote,
            iconColor: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 2,
            maxLength: 500,
            style: AppTypography.bodyMd,
            decoration: InputDecoration(
              hintText: l10n.orderNotesHint,
              hintStyle: AppTypography.bodySm.copyWith(
                color: AppColors.secondary,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              contentPadding: const EdgeInsets.all(AppSpacing.sm),
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.notifications_off_outlined,
                size: 16,
                color: AppColors.tertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.notesDeliveryHint,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
