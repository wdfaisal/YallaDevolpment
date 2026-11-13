import '../api/api_client.dart';
import '../models/customer.dart';

class AddressRepository {
  AddressRepository(this._api);

  final ApiClient _api;

  Future<List<CustomerAddressRecord>> list() async {
    final data = await _api.get<List<dynamic>>('/api/customer/addresses');
    return data.map((e) => CustomerAddressRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CustomerAddressRecord> get(String id) async {
    final data = await _api.get<Map<String, dynamic>>('/api/customer/addresses/$id');
    return CustomerAddressRecord.fromJson(data);
  }

  Future<CustomerAddressRecord> create({
    required String label,
    required String address,
    double? lat,
    double? lng,
    String? instructions,
    bool isDefault = false,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/addresses',
      body: {
        'label': label,
        'address': address,
        'lat': lat,
        'lng': lng,
        if (instructions != null && instructions.isNotEmpty) 'instructions': instructions,
        'isDefault': isDefault,
      },
    );
    return CustomerAddressRecord.fromJson(data);
  }

  Future<CustomerAddressRecord> update(
    String id, {
    String? label,
    String? address,
    double? lat,
    double? lng,
    String? instructions,
    bool? isDefault,
    bool clearPosition = false,
  }) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/api/customer/addresses/$id',
      body: {
        if (label != null) 'label': label,
        if (address != null) 'address': address,
        if (clearPosition) ...{'lat': null, 'lng': null}
        else ...{
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
        if (instructions != null) 'instructions': instructions,
        if (isDefault != null) 'isDefault': isDefault,
      },
    );
    return CustomerAddressRecord.fromJson(data);
  }

  Future<void> remove(String id) => _api.delete<dynamic>('/api/customer/addresses/$id');

  Future<AddressEligibility> eligibility(String id) async {
    final data = await _api.get<Map<String, dynamic>>('/api/customer/addresses/$id/eligibility');
    return AddressEligibility.fromJson(data);
  }
}
