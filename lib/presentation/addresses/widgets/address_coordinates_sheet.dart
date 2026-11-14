import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import 'address_text_field.dart';

/// Result of the coordinates sheet. `null` means the sheet was dismissed; a
/// result with null coordinates means the stored position was cleared.
class AddressCoordinates {
  const AddressCoordinates({this.lat, this.lng});

  final double? lat;
  final double? lng;

  bool get isCleared => lat == null || lng == null;
}

Future<AddressCoordinates?> showAddressCoordinatesSheet(
  BuildContext context, {
  double? lat,
  double? lng,
}) {
  return showModalBottomSheet<AddressCoordinates>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (_) => _AddressCoordinatesSheet(lat: lat, lng: lng),
  );
}

class _AddressCoordinatesSheet extends StatefulWidget {
  const _AddressCoordinatesSheet({this.lat, this.lng});

  final double? lat;
  final double? lng;

  @override
  State<_AddressCoordinatesSheet> createState() =>
      _AddressCoordinatesSheetState();
}

class _AddressCoordinatesSheetState extends State<_AddressCoordinatesSheet> {
  late final TextEditingController _lat = TextEditingController(
    text: widget.lat == null ? '' : _format(widget.lat!),
  );
  late final TextEditingController _lng = TextEditingController(
    text: widget.lng == null ? '' : _format(widget.lng!),
  );
  String? _error;

  bool get _hasStored => widget.lat != null && widget.lng != null;

  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  static String _format(double value) {
    final text = value.toStringAsFixed(6);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _submit(L10n l10n) {
    final latText = _lat.text.trim();
    final lngText = _lng.text.trim();
    if (latText.isEmpty && lngText.isEmpty) {
      Navigator.of(context).pop(const AddressCoordinates());
      return;
    }
    final lat = double.tryParse(latText);
    final lng = double.tryParse(lngText);
    final valid = lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
    if (!valid) {
      setState(() => _error = l10n.invalidCoordinates);
      return;
    }
    Navigator.of(context).pop(AddressCoordinates(lat: lat, lng: lng));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    size: 20,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.coordinates,
                      style: AppTypography.headlineSm.copyWith(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: l10n.close,
                  ),
                ],
              ),
              Text(
                l10n.locationOptional,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AddressTextField(
                      label: l10n.latitude,
                      controller: _lat,
                      icon: Icons.my_location,
                      hint: '15.500000',
                      textDirection: TextDirection.ltr,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                      ],
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AddressTextField(
                      label: l10n.longitude,
                      controller: _lng,
                      icon: Icons.explore_outlined,
                      hint: '32.500000',
                      textDirection: TextDirection.ltr,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                      ],
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _submit(l10n),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryContainer,
                    backgroundColor: AppColors.surfaceContainerLowest,
                    side: const BorderSide(color: AppColors.primaryContainer),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    textStyle: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(l10n.saveCoordinates),
                ),
              ),
              if (_hasStored)
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const AddressCoordinates()),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: Text(l10n.clearLocation),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
