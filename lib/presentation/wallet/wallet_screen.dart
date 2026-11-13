import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/states.dart';
import '../../data/models/account.dart';
import '../../state/account_controllers.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';

/// Wallet balance and ledger. Top-up and withdrawal are blocked until D-22 /
/// D-25, so the screen is read-only and says so.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final wallet = ref.watch(walletProvider);

    return AppScaffold(
      header: SimpleHeader(title: l10n.wallet, onBack: () => context.pop()),
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  _BalanceCard(summary: summary),
                  const SizedBox(height: AppSpacing.md),
                  _notice(l10n),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.walletHistory,
                          style: AppTypography.headlineSm,
                        ),
                      ),
                      Text(
                        '${summary.entries.length}',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (summary.entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: EmptyState(
                        title: l10n.noWalletEntries,
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  else
                    for (final entry in summary.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _EntryCard(
                          entry: entry,
                          currency: summary.currency,
                        ),
                      ),
                ],
              ),
            ),
    );
  }

  Widget _notice(L10n l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.orangeTintSubtle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.walletInfo,
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.topUpUnavailable,
                  style: AppTypography.labelSm.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.primary, AppColors.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.availableBalance,
                  style: AppTypography.labelLg.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            Fmt.moneyExact(summary.availableMinor, currency: summary.currency),
            style: AppTypography.headlineLgMobile.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.heldBalance,
                    style: AppTypography.labelMd.copyWith(color: Colors.white70),
                  ),
                ),
                Text(
                  Fmt.money(summary.heldMinor, currency: summary.currency),
                  style: AppTypography.labelLg.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.currency});

  final WalletEntry entry;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final positive = entry.amountMinor >= 0;
    final color = positive ? AppColors.tertiary : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              positive ? Icons.south_west : Icons.north_east,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_kindLabel(l10n), style: AppTypography.labelLg),
                const SizedBox(height: 1),
                Text(
                  [
                    if (entry.note != null && entry.note!.isNotEmpty) entry.note!,
                    if (entry.reference != null && entry.reference!.isNotEmpty)
                      entry.reference!,
                    Fmt.dateTime(entry.createdAt),
                  ].join(' • '),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.secondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            positive
                ? '+${Fmt.money(entry.amountMinor, currency: currency)}'
                : Fmt.money(entry.amountMinor, currency: currency),
            style: AppTypography.labelLg.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _kindLabel(L10n l10n) {
    return switch (entry.kind) {
      'order' => l10n.orderPayment,
      'order_refund' => l10n.orderRefund,
      'top_up' || 'topup' => l10n.walletTopUp,
      'withdrawal' => l10n.walletWithdrawal,
      'adjustment' => l10n.walletAdjustment,
      _ => entry.kind,
    };
  }
}
