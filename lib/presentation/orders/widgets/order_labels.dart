import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';

/// Shared Arabic/English labels for payment rows in the order tracking page.
String orderPaymentStatusLabel(L10n l10n, String status) {
  return switch (status) {
    'paid' => l10n.paid,
    'authorized' => l10n.authorized,
    'pending' => l10n.unpaid,
    'failed' => l10n.paymentFailed,
    'refunded' => l10n.refunded,
    'partially_refunded' => l10n.partiallyRefunded,
    _ => status,
  };
}

String orderPaymentMethodLabel(L10n l10n, String method) {
  return switch (method) {
    'wallet' => l10n.payWithWallet,
    'cash_on_delivery' => l10n.cashOnDelivery,
    'card_gateway' => l10n.cardGateway,
    'manual_bank_transfer' => l10n.bankTransfer,
    _ => method,
  };
}

IconData orderPaymentIcon(String method) {
  return switch (method) {
    'wallet' => Icons.account_balance_wallet_outlined,
    'card_gateway' => Icons.credit_card,
    'manual_bank_transfer' => Icons.account_balance,
    _ => Icons.payments_outlined,
  };
}
