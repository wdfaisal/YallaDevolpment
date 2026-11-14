import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/account.dart';
import '../../../data/models/cart.dart';
import 'checkout_section_card.dart';

/// Payment selector built from the quote's real payment methods. Wallet split
/// and the reference field are kept as functional extras, styled flat.
class CheckoutPaymentCard extends StatelessWidget {
  const CheckoutPaymentCard({
    super.key,
    required this.quote,
    required this.wallet,
    required this.method,
    required this.useWalletSplit,
    required this.referenceController,
    required this.l10n,
    required this.onSelect,
    required this.onSplitChanged,
  });

  final CartQuote? quote;
  final WalletSummary? wallet;
  final String? method;
  final bool useWalletSplit;
  final TextEditingController referenceController;
  final L10n l10n;
  final ValueChanged<String> onSelect;
  final ValueChanged<bool> onSplitChanged;

  @override
  Widget build(BuildContext context) {
    final currentQuote = quote;
    final methods =
        currentQuote?.paymentMethods ?? const <PaymentMethodOption>[];
    final walletUsable = methods.any((m) => m.usable && m.method == 'wallet');
    final cashUsable =
        methods.any((m) => m.usable && m.method == 'cash_on_delivery');
    final canSplit = walletUsable &&
        cashUsable &&
        currentQuote != null &&
        (wallet?.availableMinor ?? 0) > 0 &&
        (wallet?.availableMinor ?? 0) < currentQuote.totalMinor;
    final selectedOption = methods.where((m) => m.method == method);
    final needsReference = !useWalletSplit &&
        selectedOption.isNotEmpty &&
        selectedOption.first.requiresReference;
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
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.paymentMethod,
                  style: AppTypography.labelLg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.lock, size: 14, color: AppColors.tertiary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n.secureOnlinePayment,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.tertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (currentQuote == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: LoadingState(),
            )
          else ...[
            for (final option in methods)
              _PaymentOptionTile(
                option: option,
                selected: !useWalletSplit && method == option.method,
                l10n: l10n,
                onTap: () => onSelect(option.method),
              ),
            if (canSplit)
              _WalletSplitTile(
                quote: currentQuote,
                wallet: wallet!,
                value: useWalletSplit,
                l10n: l10n,
                onChanged: onSplitChanged,
              ),
            if (needsReference) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: referenceController,
                style: AppTypography.bodyMd,
                decoration: InputDecoration(
                  hintText: l10n.requiredField,
                  hintStyle: AppTypography.bodySm.copyWith(
                    color: AppColors.secondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 12,
                  ),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: focusedBorder,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.option,
    required this.selected,
    required this.l10n,
    required this.onTap,
  });

  final PaymentMethodOption option;
  final bool selected;
  final L10n l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = option.usable;
    final subtitle = !enabled
        ? (option.reason?.isNotEmpty == true
            ? option.reason!
            : l10n.paymentUnavailable)
        : _hint();
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      onTap: enabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? AppColors.primary : AppColors.outline,
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(
                _icon(),
                size: 20,
                color: selected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label(l10n.isArabic),
                    style: AppTypography.labelMd.copyWith(
                      color:
                          enabled ? AppColors.onSurface : AppColors.secondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.secondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.primary,
              )
            else if (!enabled)
              Text(
                l10n.paymentUnavailable,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _hint() {
    return switch (option.method) {
      'wallet' => l10n.paymentWalletHint,
      'cash_on_delivery' => l10n.paymentCashHint,
      'card_gateway' => l10n.paymentCardHint,
      'manual_bank_transfer' => l10n.paymentTransferHint,
      _ => '',
    };
  }

  IconData _icon() {
    return switch (option.method) {
      'wallet' => Icons.account_balance_wallet_outlined,
      'card_gateway' => Icons.credit_card,
      'manual_bank_transfer' => Icons.account_balance,
      _ => Icons.payments_outlined,
    };
  }
}

class _WalletSplitTile extends StatelessWidget {
  const _WalletSplitTile({
    required this.quote,
    required this.wallet,
    required this.value,
    required this.l10n,
    required this.onChanged,
  });

  final CartQuote quote;
  final WalletSummary wallet;
  final bool value;
  final L10n l10n;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.call_split, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(l10n.mixedPayment, style: AppTypography.labelMd),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
          if (value)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.wallet}: '
                    '${Fmt.money(wallet.availableMinor, currency: wallet.currency)}',
                    style: AppTypography.labelSm,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${l10n.cashOnDelivery}: '
                    '${Fmt.money(quote.totalMinor - wallet.availableMinor, currency: quote.currency)}',
                    style: AppTypography.labelSm,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
