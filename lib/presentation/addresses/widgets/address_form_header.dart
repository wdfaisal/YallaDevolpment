import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';

/// 56px flat header used by the address form: bordered 40px back button, a
/// centered bold title and the same bordered account shortcut on the far edge.
/// It owns no safe-area padding — [AppScaffold] already wraps it.
class AddressFormHeader extends StatelessWidget {
  const AddressFormHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.onAccount,
    required this.backTooltip,
    required this.accountTooltip,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onAccount;
  final String backTooltip;
  final String accountTooltip;

  static const double height = 56;
  static const double _button = 40;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceContainerHigh),
        ),
      ),
      child: Row(
        children: [
          _SquareButton(
            icon: Icons.arrow_back,
            tooltip: backTooltip,
            onTap: onBack,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineSm.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _SquareButton(
            icon: Icons.person_outline,
            tooltip: accountTooltip,
            onTap: onAccount,
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
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
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Container(
          width: AddressFormHeader._button,
          height: AddressFormHeader._button,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.surfaceContainer),
          ),
          child: Icon(icon, size: 20, color: AppColors.onSurface),
        ),
      ),
    );
  }
}
