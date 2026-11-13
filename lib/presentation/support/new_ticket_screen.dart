import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../data/api/api_exception.dart';
import '../../state/account_controllers.dart';
import '../shared/headers.dart';
import '../shared/sheets.dart';

/// Create a support ticket. The backend owns ticket numbering, status and
/// triage; this screen only collects the customer's input.
class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key, this.orderId});

  final String? orderId;

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _subject = TextEditingController();
  final _description = TextEditingController();

  String _category = 'general';
  String _priority = 'normal';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = L10n.of(context);
    final subject = _subject.text.trim();
    final description = _description.text.trim();

    if (subject.length < 3) {
      setState(() => _error = l10n.ticketSubject);
      return;
    }
    if (description.length < 5) {
      setState(() => _error = l10n.ticketDescription);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final ticket = await ref.read(ticketsProvider.notifier).create(
            orderId: widget.orderId,
            category: _category,
            subject: subject,
            description: description,
            priority: _priority,
          );
      if (!mounted) return;
      showAppSnack(context, l10n.ticketCreated);
      context.pushReplacement('/account/support/${ticket.id}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            error is ApiException ? error.message : l10n.somethingWentWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final orderId = widget.orderId;
    return AppScaffold(
      header: SimpleHeader(title: l10n.newTicket, onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          Text(
            l10n.supportIntro,
            style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
          ),
          if (orderId != null && orderId.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.orangeTintSubtle,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${l10n.relatedOrder}: $orderId',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _sectionLabel(l10n.ticketCategory),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in _categories(l10n))
                AppChoiceChip(
                  label: option.label,
                  icon: option.icon,
                  selected: _category == option.value,
                  onTap: () => setState(() => _category = option.value),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionLabel(l10n.priority),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in _priorities(l10n))
                AppChoiceChip(
                  label: option.label,
                  selected: _priority == option.value,
                  onTap: () => setState(() => _priority = option.value),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionLabel(l10n.ticketSubject),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _subject,
            maxLength: 190,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.bodyLg,
            decoration: InputDecoration(
              hintText: l10n.subjectHint,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionLabel(l10n.ticketDescription),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _description,
            maxLines: 6,
            maxLength: 4000,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.bodyLg,
            decoration: InputDecoration(hintText: l10n.descriptionHint),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 18,
                    color: AppColors.onErrorContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(l10n.send),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: AppTypography.labelLg);
  }

  List<_Option> _categories(L10n l10n) {
    return [
      _Option('general', l10n.categoryGeneral, Icons.help_outline),
      _Option('order', l10n.categoryOrder, Icons.receipt_long_outlined),
      _Option('payment', l10n.categoryPayment, Icons.credit_card),
      _Option('delivery', l10n.categoryDelivery, Icons.delivery_dining_outlined),
      _Option('account', l10n.categoryAccount, Icons.person_outline),
    ];
  }

  List<_Option> _priorities(L10n l10n) {
    return [
      _Option('low', l10n.priorityLow, null),
      _Option('normal', l10n.priorityNormal, null),
      _Option('high', l10n.priorityHigh, null),
      _Option('urgent', l10n.priorityUrgent, null),
    ];
  }
}

class _Option {
  const _Option(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData? icon;
}
