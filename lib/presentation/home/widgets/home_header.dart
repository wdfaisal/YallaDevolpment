import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../shared/headers.dart';

/// 56px home header: address selector, wallet and cart actions.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      color: AppColors.surfaceContainerLowest,
      child: const Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AddressChip(singleLine: true),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WalletHeaderButton(),
              SizedBox(width: AppSpacing.sm),
              CartHeaderButton(filled: true, showShadow: false),
            ],
          ),
        ],
      ),
    );
  }
}
