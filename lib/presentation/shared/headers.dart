import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../state/address_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/session_controller.dart';
import 'sheets.dart';

/// Standard 64px page header. Owns no safe-area padding: [AppScaffold] already
/// wraps the header in a top [SafeArea].
class SimpleHeader extends StatelessWidget {
  const SimpleHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.showBack = true,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          if (showBack)
            _CircleButton(
              // `arrow_back` carries matchTextDirection, so in RTL it renders
              // pointing right — the correct "back" affordance for this app.
              icon: Icons.arrow_back,
              tooltip: L10n.of(context).back,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: AppSpacing.minTapTarget),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ...actions,
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.minTapTarget / 2),
        onTap: onTap,
        child: SizedBox(
          width: AppSpacing.minTapTarget,
          height: AppSpacing.minTapTarget,
          child: Icon(icon, size: 24, color: AppColors.onSurface),
        ),
      ),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badge = 0,
    this.filled = false,
    this.iconColor,
    this.iconSize = 20,
    this.showShadow = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final int badge;
  final bool filled;
  final Color? iconColor;
  final double iconSize;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: filled ? AppColors.orangeTintSubtle : Colors.transparent,
                shape: BoxShape.circle,
                border: filled ? Border.all(color: AppColors.borderMuted) : null,
                boxShadow: filled && showShadow ? AppColors.cardShadow : null,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? (filled ? AppColors.primary : AppColors.onSurface),
              ),
            ),
            if (badge > 0)
              PositionedDirectional(
                top: -4,
                start: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Location selector shown in the home/restaurants headers.
class AddressChip extends ConsumerWidget {
  const AddressChip({super.key, this.compact = false, this.singleLine = false});

  final bool compact;
  final bool singleLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final address = ref.watch(selectedAddressProvider);
    final label = address?.label ?? (signedIn ? l10n.chooseAddress : l10n.deliverTo);
    final singleLineLabel = address?.label ?? l10n.chooseAddress;
    final detail = address?.address;

    if (singleLine) {
      return InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        onTap: () => showAddressPicker(context),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 22, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${l10n.deliverTo}: $singleLineLabel',
                  style: AppTypography.bodyMd.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: () => showAddressPicker(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 20, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          compact ? l10n.deliverTo : label,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                  if (!compact)
                    Text(
                      detail ?? label,
                      style: AppTypography.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cart shortcut with live item count.
class CartHeaderButton extends ConsumerWidget {
  const CartHeaderButton({super.key, this.filled = false, this.showShadow = true});

  final bool filled;
  final bool showShadow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartItemCountProvider);
    return HeaderIconButton(
      icon: Icons.shopping_bag,
      tooltip: L10n.of(context).cart,
      badge: count,
      filled: filled,
      showShadow: showShadow,
      onTap: () => context.push('/cart'),
    );
  }
}

/// Wallet shortcut shown in the home header.
class WalletHeaderButton extends StatelessWidget {
  const WalletHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    return HeaderIconButton(
      icon: Icons.account_balance_wallet,
      tooltip: L10n.of(context).wallet,
      iconColor: AppColors.secondary,
      iconSize: 22,
      onTap: () => context.push('/account/wallet'),
    );
  }
}
