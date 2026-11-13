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

/// Support tickets opened by the customer.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final tickets = ref.watch(ticketsProvider);

    return AppScaffold(
      header: SimpleHeader(
        title: l10n.support,
        onBack: () => context.pop(),
        actions: [
          if (signedIn)
            HeaderIconButton(
              icon: Icons.add_comment_outlined,
              tooltip: l10n.newTicket,
              onTap: () => context.push('/account/support/new'),
            ),
        ],
      ),
      onRefresh:
          signedIn ? () => ref.read(ticketsProvider.notifier).refresh() : null,
      body: !signedIn
          ? EmptyState(
              title: l10n.support,
              message: l10n.notAuthorized,
              icon: Icons.support_agent,
              actionLabel: l10n.signIn,
              onAction: () => context.push('/login?next=/account/support'),
            )
          : AsyncView(
              value: tickets,
              onRetry: () => ref.read(ticketsProvider.notifier).refresh(),
              builder: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    title: l10n.noTickets,
                    message: l10n.supportIntro,
                    icon: Icons.support_agent,
                    actionLabel: l10n.newTicket,
                    onAction: () => context.push('/account/support/new'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return OutlinedButton.icon(
                        onPressed: () => context.push('/account/support/new'),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.newTicket),
                      );
                    }
                    final ticket = items[index];
                    return _TicketCard(
                      ticket: ticket,
                      onTap: () => context.push('/account/support/${ticket.id}'),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final color = _statusColor(ticket.status);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.surfaceContainerHigh),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.confirmation_number_outlined,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.subject,
                        style: AppTypography.labelLg.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${ticket.reference} • ${Fmt.dateTime(ticket.createdAt)}',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _Chip(label: _statusLabel(l10n, ticket.status), color: color),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              ticket.description,
              style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _Meta(
                  icon: Icons.sell_outlined,
                  label: _categoryLabel(l10n, ticket.category),
                ),
                const SizedBox(width: AppSpacing.md),
                _Meta(
                  icon: Icons.flag_outlined,
                  label: _priorityLabel(l10n, ticket.priority),
                ),
                const Spacer(),
                if (ticket.messages.isNotEmpty)
                  _Meta(
                    icon: Icons.forum_outlined,
                    label: '${ticket.messages.length}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'resolved' => AppColors.tertiary,
      'closed' => AppColors.secondary,
      'in_progress' => AppColors.warning,
      _ => AppColors.primary,
    };
  }

  String _statusLabel(L10n l10n, String status) {
    return switch (status) {
      'resolved' => l10n.ticketResolved,
      'closed' => l10n.ticketClosed,
      'in_progress' => l10n.ticketInProgress,
      _ => l10n.ticketOpen,
    };
  }

  String _priorityLabel(L10n l10n, String priority) {
    return switch (priority) {
      'low' => l10n.priorityLow,
      'high' => l10n.priorityHigh,
      'urgent' => l10n.priorityUrgent,
      _ => l10n.priorityNormal,
    };
  }

  String _categoryLabel(L10n l10n, String category) {
    return switch (category) {
      'order' => l10n.categoryOrder,
      'payment' => l10n.categoryPayment,
      'delivery' => l10n.categoryDelivery,
      'account' => l10n.categoryAccount,
      _ => l10n.categoryGeneral,
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}
