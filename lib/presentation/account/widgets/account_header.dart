import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';

/// White account header from the Stitch profile design: title on the start
/// side, share action on the end side, and a back button only when the route
/// can actually be popped.
class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key, required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final canPop = Navigator.of(context).canPop();
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.profileBorder)),
      ),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              icon: const Icon(Icons.arrow_forward, size: 24),
              color: AppColors.profileHeading,
              tooltip: l10n.back,
              onPressed: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 4),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.profileTitle,
              style: AppTypography.labelLg.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.profileHeading,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            color: AppColors.profileSecondaryText,
            tooltip: l10n.share,
            onPressed: onShare,
          ),
        ],
      ),
    );
  }
}
