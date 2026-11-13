import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/customer.dart';
import '../../state/address_controller.dart';
import '../../state/providers.dart';
import '../shared/headers.dart';

/// Create or edit a saved address. Coordinates are optional; the backend
/// derives the coverage zone and rejects explicit zones that do not contain
/// the point, so the form never invents one.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.addressId});

  final String? addressId;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _label = TextEditingController();
  final _address = TextEditingController();
  final _instructions = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  bool _isDefault = false;
  bool _busy = false;
  bool _loading = false;
  String? _error;

  bool get _isEditing => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _load();
  }

  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    _instructions.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.addressId!;
    final cached = _cached(id);
    if (cached != null) {
      _populate(cached);
      return;
    }
    setState(() => _loading = true);
    try {
      final record = await ref.read(addressRepositoryProvider).get(id);
      if (!mounted) return;
      _populate(record);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is ApiException ? error.message : L10n.of(context).somethingWentWrong;
      });
    }
  }

  CustomerAddressRecord? _cached(String id) {
    final list = ref.read(addressesProvider).valueOrNull?.addresses ??
        const <CustomerAddressRecord>[];
    for (final address in list) {
      if (address.id == id) return address;
    }
    return null;
  }

  void _populate(CustomerAddressRecord record) {
    setState(() {
      _label.text = record.label;
      _address.text = record.address;
      _instructions.text = record.instructions;
      _lat.text = record.lat == null ? '' : _trimCoordinate(record.lat!);
      _lng.text = record.lng == null ? '' : _trimCoordinate(record.lng!);
      _isDefault = record.isDefault;
      _loading = false;
      _error = null;
    });
  }

  String _trimCoordinate(double value) {
    final text = value.toStringAsFixed(6);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Future<void> _save() async {
    final l10n = L10n.of(context);
    final label = _label.text.trim();
    final address = _address.text.trim();
    final latText = _lat.text.trim();
    final lngText = _lng.text.trim();

    if (label.isEmpty) {
      setState(() => _error = l10n.requiredField);
      return;
    }
    if (address.length < 3) {
      setState(() => _error = l10n.addressDetails);
      return;
    }
    if ((latText.isEmpty) != (lngText.isEmpty)) {
      setState(() => _error = l10n.invalidCoordinates);
      return;
    }

    double? lat;
    double? lng;
    if (latText.isNotEmpty) {
      lat = double.tryParse(latText);
      lng = double.tryParse(lngText);
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
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final instructions = _instructions.text.trim();
      final CustomerAddressRecord saved;
      if (_isEditing) {
        saved = await ref.read(addressesProvider.notifier).updateAddress(
              widget.addressId!,
              label: label,
              address: address,
              lat: lat,
              lng: lng,
              instructions: instructions,
              isDefault: _isDefault,
              clearPosition: lat == null,
            );
      } else {
        saved = await ref.read(addressesProvider.notifier).create(
              label: label,
              address: address,
              lat: lat,
              lng: lng,
              instructions: instructions,
              isDefault: _isDefault,
            );
      }
      final eligibility =
          await ref.read(addressesProvider.notifier).eligibility(saved.id);
      if (!mounted) return;
      setState(() => _busy = false);
      final coverage = eligibility.deliverable
          ? l10n.covered
          : switch (eligibility.reason) {
              'no_position' => l10n.noPosition,
              'no_zone' => l10n.noZone,
              _ => l10n.outsideCoverage,
            };
      showAppSnack(context, '${l10n.addressSaved} • $coverage');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/account/addresses');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is ApiException ? error.message : l10n.somethingWentWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return AppScaffold(
      header: SimpleHeader(
        title: _isEditing ? l10n.editAddress : l10n.addNewAddress,
        onBack: () => context.pop(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                _field(
                  label: l10n.addressLabel,
                  controller: _label,
                  hint: l10n.labelHint,
                  icon: Icons.bookmark_border,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                _field(
                  label: l10n.addressDetails,
                  controller: _address,
                  hint: l10n.addressDetailsHint,
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                _field(
                  label: l10n.addressInstructions,
                  controller: _instructions,
                  hint: l10n.instructionsHint,
                  icon: Icons.edit_note,
                  maxLines: 2,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                _coordinates(l10n),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.surfaceContainerHigh),
                  ),
                  child: SwitchListTile(
                    value: _isDefault,
                    onChanged: (value) => setState(() => _isDefault = value),
                    title: Text(l10n.setDefault, style: AppTypography.labelLg),
                    secondary: const Icon(
                      Icons.star_outline,
                      color: AppColors.warning,
                    ),
                  ),
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
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.saveAddress),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _coordinates(L10n l10n) {
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
              const Icon(Icons.my_location, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.locationOptional, style: AppTypography.labelLg),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                  ],
                  style: AppTypography.bodyMd,
                  decoration: InputDecoration(
                    labelText: l10n.latitude,
                    hintText: '15.500000',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _lng,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                  ],
                  style: AppTypography.bodyMd,
                  decoration: InputDecoration(
                    labelText: l10n.longitude,
                    hintText: '32.500000',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputAction action = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelLg),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textInputAction: action,
          textCapitalization: TextCapitalization.sentences,
          style: AppTypography.bodyLg,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.secondary),
          ),
        ),
      ],
    );
  }
}
