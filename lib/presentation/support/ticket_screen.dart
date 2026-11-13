import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/account.dart';
import '../../state/account_controllers.dart';
import '../shared/headers.dart';

/// One support ticket: metadata, the conversation, and a reply composer while
/// the ticket is still open.
class TicketScreen extends ConsumerStatefulWidget {
  const TicketScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  final _reply = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(ticketDetailProvider(widget.ticketId));
    try {
      await ref.read(ticketDetailProvider(widget.ticketId).future);
    } catch (_) {
      // AsyncView renders the error state.
    }
  }

  Future<void> _send() async {
    final l10n = L10n.of(context);
    final body = _reply.text.trim();
    if (body.isEmpty || _sending) return;

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      await ref.read(ticketDetailProvider(widget.ticketId).notifier).reply(body);
      if (!mounted) return;
      _reply.clear();
      setState(() => _sending = false);
      showAppSnack(context, l10n.replySent);
      _scrollToEnd();
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      showAppSnack(
        context,
        error is ApiException ? error.message : l10n.somethingWentWrong,
        isError: true,
      );
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final ticket = ref.watch(ticketDetailProvider(widget.ticketId));

    return AppScaffold(
      header: SimpleHeader(title: l10n.support, onBack: () => context.pop()),
      onRefresh: _refresh,
      body: AsyncView(
        value: ticket,
        onRetry: _refresh,
        builder: (data) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  _MetaCard(ticket: data),
                  const SizedBox(height: AppSpacing.lg),
                  _MessageBubble(
                    body: data.description,
                    at: data.createdAt,
                    fromCustomer: true,
                    arabic: l10n.isArabic,
                  ),
                  for (final message in data.messages)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: _MessageBubble(
                        body: message.body,
                        at: message.at,
                        fromCustomer: message.isCustomer,
                        arabic: l10n.isArabic,
                      ),
                    ),
                ],
              ),
            ),
            if (data.isOpen)
              _Composer(
                controller: _reply,
                sending: _sending,
                onSend: _send,
              )
            else
              _ClosedNotice(l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final color = _statusColor(ticket.status);
    return Container(
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
              Expanded(
                child: Text(
                  ticket.subject,
                  style: AppTypography.headlineSm,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(l10n, ticket.status),
                  style: AppTypography.labelSm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${ticket.reference} • ${Fmt.dateTime(ticket.createdAt)}',
            style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _Meta(
                icon: Icons.sell_outlined,
                label: _categoryLabel(l10n, ticket.category),
              ),
              _Meta(
                icon: Icons.flag_outlined,
                label: _priorityLabel(l10n, ticket.priority),
              ),
              if (ticket.orderId != null)
                InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  onTap: () => context.push('/orders/${ticket.orderId}'),
                  child: _Meta(
                    icon: Icons.receipt_long_outlined,
                    label: ticket.orderReference ?? ticket.orderId!,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ],
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

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.label,
    this.color = AppColors.secondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSm.copyWith(color: color)),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.body,
    required this.at,
    required this.fromCustomer,
    required this.arabic,
  });

  final String body;
  final String at;
  final bool fromCustomer;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          fromCustomer ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: fromCustomer
              ? AppColors.orangeTintSubtle
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(AppSpacing.radiusLg),
            topEnd: const Radius.circular(AppSpacing.radiusLg),
            bottomStart: Radius.circular(
              fromCustomer ? AppSpacing.radiusLg : AppSpacing.radiusSm,
            ),
            bottomEnd: Radius.circular(
              fromCustomer ? AppSpacing.radiusSm : AppSpacing.radiusLg,
            ),
          ),
          border: Border.all(
            color: fromCustomer
                ? AppColors.primaryFixedDim
                : AppColors.surfaceContainerHigh,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body, style: AppTypography.bodyMd),
            const SizedBox(height: AppSpacing.xs),
            Text(
              Fmt.relative(at, isArabic: arabic),
              style: AppTypography.labelSm.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.surfaceContainer)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 4000,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                hintText: l10n.writeReply,
                counterText: '',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 46,
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              onPressed: sending ? null : onSend,
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice({required this.l10n});

  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surfaceContainerLow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 16,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.ticketClosedNotice,
            style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}
