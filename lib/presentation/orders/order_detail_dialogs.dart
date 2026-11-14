import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../data/api/api_exception.dart';
import '../../state/providers.dart';

/// Opens the post-delivery rating sheet. Returns `true` when a rating was
/// submitted so the caller can refresh the order.
Future<bool?> showOrderRatingSheet(
  BuildContext context, {
  required String orderId,
  required String restaurantName,
  required bool driverAvailable,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    builder: (_) => _RatingSheet(
      orderId: orderId,
      restaurantName: restaurantName,
      driverAvailable: driverAvailable,
    ),
  );
}

/// Asks for an optional cancellation reason. Returns the text, or `null` when
/// the customer dismisses the dialog.
Future<String?> showCancelReasonDialog(
  BuildContext context, {
  required String title,
  required String hint,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CancelReasonDialog(title: title, hint: hint),
  );
}

class _RatingSheet extends ConsumerStatefulWidget {
  const _RatingSheet({
    required this.orderId,
    required this.restaurantName,
    required this.driverAvailable,
  });

  final String orderId;
  final String restaurantName;
  final bool driverAvailable;

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  final _restaurantComment = TextEditingController();
  final _driverComment = TextEditingController();
  int _restaurantStars = 0;
  int _driverStars = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _restaurantComment.dispose();
    _driverComment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = L10n.of(context);
    if (_restaurantStars == 0 && _driverStars == 0) {
      setState(() => _error = l10n.starsRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountRepositoryProvider).rateOrder(
            orderId: widget.orderId,
            restaurantStars: _restaurantStars == 0 ? null : _restaurantStars,
            restaurantComment: _restaurantComment.text.trim(),
            driverStars: _driverStars == 0 ? null : _driverStars,
            driverComment: _driverComment.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderHairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.rateYourOrder, style: AppTypography.headlineSm),
            const SizedBox(height: AppSpacing.lg),
            Text(widget.restaurantName, style: AppTypography.labelLg),
            const SizedBox(height: AppSpacing.xs),
            _StarPicker(
              value: _restaurantStars,
              onChanged: (value) => setState(() => _restaurantStars = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _restaurantComment,
              maxLines: 2,
              maxLength: 500,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                hintText: l10n.yourComment,
                counterText: '',
              ),
            ),
            if (widget.driverAvailable) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l10n.rateDriver, style: AppTypography.labelLg),
              const SizedBox(height: AppSpacing.xs),
              _StarPicker(
                value: _driverStars,
                onChanged: (value) => setState(() => _driverStars = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _driverComment,
                maxLines: 2,
                maxLength: 500,
                style: AppTypography.bodyMd,
                decoration: InputDecoration(
                  hintText: l10n.yourComment,
                  counterText: '',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.bodySm.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.submitRating),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star_rounded : Icons.star_border_rounded,
              size: 32,
              color: AppColors.warning,
            ),
          ),
      ],
    );
  }
}

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        maxLength: 300,
        style: AppTypography.bodyMd,
        decoration: InputDecoration(hintText: widget.hint, counterText: ''),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.cancelOrder),
        ),
      ],
    );
  }
}
