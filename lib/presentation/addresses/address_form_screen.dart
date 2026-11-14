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
import '../../data/models/customer.dart';
import '../../state/address_controller.dart';
import '../../state/providers.dart';
import 'widgets/address_coordinates_sheet.dart';
import 'widgets/address_default_toggle.dart';
import 'widgets/address_facilities_section.dart';
import 'widgets/address_form_header.dart';
import 'widgets/address_location_card.dart';
import 'widgets/address_save_bar.dart';
import 'widgets/address_section_header.dart';
import 'widgets/address_text_field.dart';
import 'widgets/address_type_selector.dart';

/// Create or edit a saved address using the flat Stitch form: a pin canvas,
/// a classification strip, exact-location inputs, captain facilities and one
/// outlined sticky CTA. Every surface is pure white with a hairline border.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.addressId});

  final String? addressId;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _label = TextEditingController();
  final _city = TextEditingController();
  final _street = TextEditingController();
  final _building = TextEditingController();
  final _floor = TextEditingController();
  final _landmark = TextEditingController();
  final _instructions = TextEditingController();

  final Set<String> _facilities = <String>{};
  String _typeId = 'home';
  double? _lat;
  double? _lng;
  bool _isDefault = false;
  bool _busy = false;
  bool _loading = false;
  bool _defaultsApplied = false;
  String? _error;

  bool get _isEditing => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultsApplied || _isEditing) return;
    _defaultsApplied = true;
    _typeId = 'home';
    _label.text = L10n.of(context).addressTypeHome;
  }

  @override
  void dispose() {
    _label.dispose();
    _city.dispose();
    _street.dispose();
    _building.dispose();
    _floor.dispose();
    _landmark.dispose();
    _instructions.dispose();
    super.dispose();
  }

  List<AddressTypeOption> _typeOptions(L10n l10n) {
    return [
      AddressTypeOption(
        id: 'home',
        label: l10n.addressTypeHome,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
      ),
      AddressTypeOption(
        id: 'work',
        label: l10n.addressTypeWork,
        icon: Icons.apartment_outlined,
        activeIcon: Icons.apartment,
      ),
      AddressTypeOption(
        id: 'chalet',
        label: l10n.addressTypeChalet,
        icon: Icons.holiday_village_outlined,
        activeIcon: Icons.holiday_village,
      ),
      AddressTypeOption(
        id: 'other',
        label: l10n.addressTypeOther,
        icon: Icons.push_pin_outlined,
        activeIcon: Icons.push_pin,
      ),
    ];
  }

  List<AddressFacilityOption> _facilityOptions(L10n l10n) {
    return [
      AddressFacilityOption(
        id: 'elevator',
        label: l10n.facilityElevator,
        icon: Icons.elevator_outlined,
      ),
      AddressFacilityOption(
        id: 'parking',
        label: l10n.facilityParking,
        icon: Icons.local_parking,
      ),
      AddressFacilityOption(
        id: 'gated',
        label: l10n.facilityGated,
        icon: Icons.security,
      ),
    ];
  }

  Future<void> _load() async {
    final id = widget.addressId!;
    final cached = _cached(id);
    if (cached != null) {
      _populate(cached);
      return;
    }
    try {
      final record = await ref.read(addressRepositoryProvider).get(id);
      if (!mounted) return;
      _populate(record);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is ApiException
            ? error.message
            : L10n.of(context).somethingWentWrong;
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
    final l10n = L10n.of(context);
    var typeId = 'other';
    for (final option in _typeOptions(l10n)) {
      if (option.label == record.label) {
        typeId = option.id;
        break;
      }
    }

    // Our own addresses are written as `city، street، building، floor،
    // landmark`, so the same separator restores them without losing text.
    final parts = record.address
        .split('،')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    final facilities = <String>{};
    var note = record.instructions;
    for (final option in _facilityOptions(l10n)) {
      if (note.contains(option.label)) {
        facilities.add(option.id);
        note = note.replaceAll(option.label, '');
      }
    }

    setState(() {
      _typeId = typeId;
      _label.text = record.label;
      if (parts.length > 1) {
        _city.text = parts[0];
        _street.text = parts[1];
        _building.text = parts.length > 2 ? parts[2] : '';
        _floor.text = parts.length > 3 ? parts[3] : '';
        _landmark.text = parts.length > 4 ? parts.sublist(4).join('، ') : '';
      } else {
        _city.text = '';
        _street.text = parts.isEmpty ? '' : parts.first;
        _building.text = '';
        _floor.text = '';
        _landmark.text = '';
      }
      _instructions.text = _cleanNote(note);
      _facilities
        ..clear()
        ..addAll(facilities);
      _lat = record.lat;
      _lng = record.lng;
      _isDefault = record.isDefault;
      _loading = false;
      _error = null;
    });
  }

  String _cleanNote(String note) {
    var text = note.replaceAll(RegExp(r'(\s*•\s*)+'), ' • ').trim();
    text = text.replaceAll(RegExp(r'^[•،,\s]+|[•،,\s]+$'), '');
    return text.trim();
  }

  void _selectType(String id, L10n l10n) {
    final options = _typeOptions(l10n);
    final presetLabels = options.map((option) => option.label);
    setState(() {
      _typeId = id;
      if (id == 'other') {
        if (presetLabels.contains(_label.text)) _label.text = '';
      } else {
        for (final option in options) {
          if (option.id == id) {
            _label.text = option.label;
            break;
          }
        }
      }
    });
  }

  String _composedAddress() {
    final parts = [_city, _street, _building, _floor, _landmark]
        .map((controller) => controller.text.trim())
        .where((part) => part.isNotEmpty);
    return parts.join('، ');
  }

  String _composedInstructions(L10n l10n) {
    final selected = _facilityOptions(l10n)
        .where((option) => _facilities.contains(option.id))
        .map((option) => option.label);
    final note = _instructions.text.trim();
    return [...selected, if (note.isNotEmpty) note].join(' • ');
  }

  String _areaLabel(L10n l10n) {
    final area = [_city.text.trim(), _street.text.trim()]
        .where((part) => part.isNotEmpty)
        .join(' • ');
    return area.isEmpty ? l10n.noPosition : area;
  }

  Future<void> _editCoordinates() async {
    final result = await showAddressCoordinatesSheet(
      context,
      lat: _lat,
      lng: _lng,
    );
    if (result == null || !mounted) return;
    setState(() {
      _lat = result.isCleared ? null : result.lat;
      _lng = result.isCleared ? null : result.lng;
    });
  }

  void _resetPin() {
    if (_lat == null && _lng == null) return;
    setState(() {
      _lat = null;
      _lng = null;
    });
  }

  Future<void> _save() async {
    final l10n = L10n.of(context);
    final label = _label.text.trim();
    final address = _composedAddress();

    if (label.isEmpty) {
      setState(() => _error = l10n.requiredField);
      return;
    }
    if (address.length < 3) {
      setState(() => _error = l10n.addressDetailsRequired);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final instructions = _composedInstructions(l10n);
      final CustomerAddressRecord saved;
      if (_isEditing) {
        saved = await ref.read(addressesProvider.notifier).updateAddress(
              widget.addressId!,
              label: label,
              address: address,
              lat: _lat,
              lng: _lng,
              instructions: instructions,
              isDefault: _isDefault,
              clearPosition: _lat == null,
            );
      } else {
        saved = await ref.read(addressesProvider.notifier).create(
              label: label,
              address: address,
              lat: _lat,
              lng: _lng,
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
        _error = error is ApiException
            ? error.message
            : L10n.of(context).somethingWentWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return AppScaffold(
      background: AppColors.surfaceContainerLowest,
      header: AddressFormHeader(
        title: _isEditing ? l10n.editAddress : l10n.addNewAddress,
        onBack: () => context.pop(),
        onAccount: () => context.push('/account/profile'),
        backTooltip: l10n.back,
        accountTooltip: l10n.account,
      ),
      bottomBar: AddressSaveBar(
        label: l10n.saveAddress,
        busy: _busy,
        onPressed: _save,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryContainer,
              ),
            )
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                _locationSection(l10n),
                _typeSection(l10n),
                _divider(),
                _detailsSection(l10n),
                _divider(),
                _facilitiesSection(l10n),
                _divider(),
                _preferencesSection(l10n),
                if (_error != null) _errorBox(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
    );
  }

  Widget _locationSection(L10n l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: AddressLocationCard(
        areaLabel: _areaLabel(l10n),
        hasPosition: _lat != null && _lng != null,
        enterLabel: l10n.enterCoordinates,
        resetLabel: l10n.resetPin,
        pinSetLabel: l10n.pinSet,
        onEnterCoordinates: _editCoordinates,
        onResetPin: _resetPin,
      ),
    );
  }

  Widget _typeSection(L10n l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AddressSectionHeader(
            icon: Icons.bookmark,
            title: l10n.addressType,
            trailing: _hint(l10n.addressTypeHint),
          ),
          const SizedBox(height: 10),
          AddressTypeSelector(
            options: _typeOptions(l10n),
            selectedId: _typeId,
            onSelected: (id) => _selectType(id, l10n),
          ),
          if (_typeId == 'other') ...[
            const SizedBox(height: AppSpacing.md),
            AddressTextField(
              label: l10n.addressLabel,
              controller: _label,
              icon: Icons.bookmark_border,
              hint: l10n.labelHint,
              maxLength: 80,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailsSection(L10n l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AddressSectionHeader(
            icon: Icons.explore,
            title: l10n.locationDetails,
          ),
          const SizedBox(height: AppSpacing.md),
          AddressTextField(
            label: l10n.cityDistrict,
            controller: _city,
            icon: Icons.location_city,
            hint: l10n.cityDistrictHint,
            maxLength: 100,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AddressTextField(
            label: l10n.streetName,
            controller: _street,
            icon: Icons.signpost,
            hint: l10n.streetNameHint,
            maxLength: 200,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AddressTextField(
                  label: l10n.buildingNumber,
                  controller: _building,
                  icon: Icons.domain,
                  maxLength: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AddressTextField(
                  label: l10n.floorApartment,
                  controller: _floor,
                  icon: Icons.meeting_room,
                  maxLength: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AddressTextField(
            label: l10n.nearbyLandmark,
            controller: _landmark,
            icon: Icons.store_outlined,
            hint: l10n.nearbyLandmarkHint,
            maxLength: 120,
          ),
        ],
      ),
    );
  }

  Widget _facilitiesSection(L10n l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AddressSectionHeader(
            icon: Icons.two_wheeler,
            title: l10n.deliveryFacilities,
            trailing: Text(
              l10n.fasterArrival,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.tertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AddressFacilitiesSection(
            options: _facilityOptions(l10n),
            selected: _facilities,
            onToggle: (id) => setState(() {
              if (!_facilities.remove(id)) _facilities.add(id);
            }),
            instructions: _instructions,
            instructionsLabel: l10n.captainInstructions,
            instructionsHint: l10n.captainInstructionsHint,
          ),
        ],
      ),
    );
  }

  Widget _preferencesSection(L10n l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: AddressDefaultToggle(
        value: _isDefault,
        onChanged: (value) => setState(() => _isDefault = value),
        title: l10n.defaultAddressTitle,
        subtitle: l10n.defaultAddressHint,
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      color: AppColors.surfaceContainer,
    );
  }

  Widget _hint(String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Text(
        text,
        textAlign: TextAlign.end,
        style: AppTypography.bodySm.copyWith(
          fontSize: 12,
          color: AppColors.secondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _errorBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Container(
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
    );
  }
}
