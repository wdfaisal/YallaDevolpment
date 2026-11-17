import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../state/account_controllers.dart';
import '../../state/session_controller.dart';
import 'widgets/wallet_activity_section.dart';
import 'widgets/wallet_balance_card.dart';
import 'widgets/wallet_header.dart';
import 'widgets/wallet_quick_actions.dart';

/// Wallet balance and ledger, redesigned after the Stitch wallet screen: pure
/// white canvas, flat primary balance card, hairline borders and no shadows.
/// Top-up and withdrawal are blocked until D-22 / D-25, so the screen stays
/// read-only and says so.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  WalletFilter _filter = WalletFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final wallet = ref.watch(walletProvider);

    return AppScaffold(
      header: WalletHeader(
        onBack: () => context.pop(),
        onHelp: () => context.push('/account/support'),
      ),
      onRefresh:
          signedIn ? () => ref.read(walletProvider.notifier).refresh() : null,
      body: !signedIn
          ? EmptyState(
              title: l10n.wallet,
              message: l10n.notAuthorized,
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: l10n.signIn,
              onAction: () => context.push('/login?next=/account/wallet'),
            )
          : AsyncView(
              value: wallet,
              onRetry: () => ref.read(walletProvider.notifier).refresh(),
              builder: (summary) => ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                children: [
                  WalletBalanceCard(summary: summary),
                  const SizedBox(height: AppSpacing.md),
                  WalletQuickActions(
                    onTopUp: () => showAppSnack(context, l10n.topUpUnavailable),
                    onGift: () =>
                        showAppSnack(context, l10n.walletGiftUnavailable),
                    onRewards: () => context.push('/account/loyalty'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ReadOnlyNotice(text: l10n.walletReadOnlyNotice),
                  const SizedBox(height: AppSpacing.xxl),
                  WalletActivitySection(
                    entries: summary.entries,
                    currency: summary.currency,
                    filter: _filter,
                    onFilterChanged: (value) => setState(() => _filter = value),
                    onViewAll: () => setState(() => _filter = WalletFilter.all),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Slim inline notice that keeps the read-only wallet honest without a heavy
/// alert surface: white card, hairline border, one primary info icon.
class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
