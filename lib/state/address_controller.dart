import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_exception.dart';
import '../data/models/customer.dart';
import 'providers.dart';
import 'session_controller.dart';

class AddressSelection {
  const AddressSelection({required this.addresses, required this.selectedId});

  static const empty = AddressSelection(addresses: [], selectedId: null);

  final List<CustomerAddressRecord> addresses;
  final String? selectedId;

  CustomerAddressRecord? get selected {
    if (addresses.isEmpty) return null;
    for (final address in addresses) {
      if (address.id == selectedId) return address;
    }
    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
  }

  AddressSelection copyWith({List<CustomerAddressRecord>? addresses, String? selectedId}) {
    return AddressSelection(
      addresses: addresses ?? this.addresses,
      selectedId: selectedId ?? this.selectedId,
    );
  }
}

final addressesProvider =
    AsyncNotifierProvider<AddressesController, AddressSelection>(AddressesController.new);

/// The address used for catalog pricing, availability and checkout.
final selectedAddressProvider = Provider<CustomerAddressRecord?>((ref) {
  return ref.watch(addressesProvider).valueOrNull?.selected;
});

class AddressesController extends AsyncNotifier<AddressSelection> {
  @override
  Future<AddressSelection> build() async {
    ref.watch(personalEpochProvider);
    final signedIn = ref.watch(sessionProvider).valueOrNull != null;
    if (!signedIn) return AddressSelection.empty;

    final previous = state.valueOrNull?.selectedId;
    final list = await ref.read(addressRepositoryProvider).list();
    return AddressSelection(addresses: list, selectedId: _resolveId(list, previous));
  }

  String? _resolveId(List<CustomerAddressRecord> list, String? preferred) {
    if (preferred != null && list.any((a) => a.id == preferred)) return preferred;
    for (final address in list) {
      if (address.isDefault) return address.id;
    }
    return list.isEmpty ? null : list.first.id;
  }

  void select(String id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(selectedId: id));
  }

  Future<void> reload() async {
    final previous = state.valueOrNull?.selectedId;
    state = const AsyncValue.loading();
    try {
      final list = await ref.read(addressRepositoryProvider).list();
      state = AsyncValue.data(
        AddressSelection(addresses: list, selectedId: _resolveId(list, previous)),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<CustomerAddressRecord> create({
    required String label,
    required String address,
    double? lat,
    double? lng,
    String? instructions,
    bool isDefault = false,
  }) async {
    final created = await ref.read(addressRepositoryProvider).create(
          label: label,
          address: address,
          lat: lat,
          lng: lng,
          instructions: instructions,
          isDefault: isDefault,
        );
    await reload();
    select(created.id);
    return created;
  }

  Future<CustomerAddressRecord> updateAddress(
    String id, {
    String? label,
    String? address,
    double? lat,
    double? lng,
    String? instructions,
    bool? isDefault,
    bool clearPosition = false,
  }) async {
    final updated = await ref.read(addressRepositoryProvider).update(
          id,
          label: label,
          address: address,
          lat: lat,
          lng: lng,
          instructions: instructions,
          isDefault: isDefault,
          clearPosition: clearPosition,
        );
    await reload();
    return updated;
  }

  Future<void> remove(String id) async {
    await ref.read(addressRepositoryProvider).remove(id);
    await reload();
  }

  Future<AddressEligibility> eligibility(String id) {
    return ref.read(addressRepositoryProvider).eligibility(id);
  }
}

/// Eligibility for the currently selected address (null for guests).
final selectedEligibilityProvider = FutureProvider<AddressEligibility?>((ref) async {
  final address = ref.watch(selectedAddressProvider);
  if (address == null) return null;
  try {
    return await ref.read(addressRepositoryProvider).eligibility(address.id);
  } on ApiException {
    return null;
  }
});
