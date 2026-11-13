import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';

/// Soft-red sign-out button and the version footnote from the Stitch profile
/// design.
class AccountFooter extends StatelessWidget {
  const AccountFooter({super.key, required this.versionLabel, this.onSignOut});

  final String versionLabel;

  /// Hidden for guests, who have no session to end.
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Column(
      children: [
        if (onSignOut != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Material(
              color: AppColors.profileAccentTint,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onSignOut,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.profileRedBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout,
                        size: 20,
                        color: AppColors.profileAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.signOut,
                        style: AppTypography.labelLg.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.profileAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            versionLabel,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.profileMuted,
            ),
          ),
        ),
      ],
    );
  }
}
