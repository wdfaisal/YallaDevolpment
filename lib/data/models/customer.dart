import '../../core/utils/json.dart';

/// Customer profile as returned by `GET /api/customer/auth/me`.
class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.initials,
    required this.phone,
    required this.email,
    required this.language,
    required this.avatarUrl,
    required this.status,
    required this.memberSince,
    required this.orderCount,
    required this.defaultAddress,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: asString(json['id']),
      name: asString(json['name']),
      initials: asString(json['initials']),
      phone: asString(json['phone']),
      email: asStringOrNull(json['email']),
      language: asString(json['language'], 'ar'),
      avatarUrl: asStringOrNull(json['avatarUrl']),
      status: asString(json['status'], 'active'),
      memberSince: asString(json['memberSince']),
      orderCount: asInt(json['orderCount']),
      defaultAddress: json['defaultAddress'] == null
          ? null
          : CustomerAddress.fromJson(asMap(json['defaultAddress'])),
    );
  }

  final String id;
  final String name;
  final String initials;
  final String phone;
  final String? email;
  final String language;
  final String? avatarUrl;
  final String status;
  final String memberSince;
  final int orderCount;
  final CustomerAddress? defaultAddress;

  bool get isSuspended => status == 'suspended';
  bool get isArabic => language == 'ar';

  CustomerProfile copyWith({
    String? name,
    String? email,
    String? language,
    String? avatarUrl,
    CustomerAddress? defaultAddress,
  }) {
    return CustomerProfile(
      id: id,
      name: name ?? this.name,
      initials: initials,
      phone: phone,
      email: email ?? this.email,
      language: language ?? this.language,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status,
      memberSince: memberSince,
      orderCount: orderCount,
      defaultAddress: defaultAddress ?? this.defaultAddress,
    );
  }
}

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
    required this.isDefault,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: asString(json['id']),
      label: asString(json['label']),
      address: asString(json['address']),
      lat: asDoubleOrNull(json['lat']),
      lng: asDoubleOrNull(json['lng']),
      isDefault: asBool(json['isDefault']),
    );
  }

  final String id;
  final String label;
  final String address;
  final double? lat;
  final double? lng;
  final bool isDefault;

  bool get hasPosition => lat != null && lng != null;
}

/// Full saved address (customer module `CustomerAddressRecord`).
class CustomerAddressRecord extends CustomerAddress {
  const CustomerAddressRecord({
    required super.id,
    required super.label,
    required super.address,
    required super.lat,
    required super.lng,
    required super.isDefault,
    required this.instructions,
    required this.zoneId,
    required this.cityId,
    required this.updatedAt,
  });

  factory CustomerAddressRecord.fromJson(Map<String, dynamic> json) {
    final base = CustomerAddress.fromJson(json);
    return CustomerAddressRecord(
      id: base.id,
      label: base.label,
      address: base.address,
      lat: base.lat,
      lng: base.lng,
      isDefault: base.isDefault,
      instructions: asString(json['instructions']),
      zoneId: asStringOrNull(json['zoneId']),
      cityId: asStringOrNull(json['cityId']),
      updatedAt: asStringOrNull(json['updatedAt']),
    );
  }

  final String instructions;
  final String? zoneId;
  final String? cityId;
  final String? updatedAt;
}

class AddressEligibility {
  const AddressEligibility({
    required this.deliverable,
    required this.zoneId,
    required this.zoneName,
    required this.reason,
    required this.deliveryFeeMinor,
    required this.minOrderMinor,
    required this.etaMinutes,
  });

  factory AddressEligibility.fromJson(Map<String, dynamic> json) {
    return AddressEligibility(
      deliverable: asBool(json['deliverable']),
      zoneId: asStringOrNull(json['zoneId']),
      zoneName: asStringOrNull(json['zoneName']),
      reason: asString(json['reason'], 'no_position'),
      deliveryFeeMinor: asIntOrNull(json['deliveryFeeMinor']),
      minOrderMinor: asIntOrNull(json['minOrderMinor']),
      etaMinutes: asIntOrNull(json['etaMinutes']),
    );
  }

  final bool deliverable;
  final String? zoneId;
  final String? zoneName;
  final String reason;
  final int? deliveryFeeMinor;
  final int? minOrderMinor;
  final int? etaMinutes;
}

class CustomerSession {
  const CustomerSession({
    required this.customer,
    required this.isNew,
    required this.expiresAt,
    required this.token,
  });

  factory CustomerSession.fromJson(Map<String, dynamic> json) {
    return CustomerSession(
      customer: CustomerProfile.fromJson(asMap(json['customer'])),
      isNew: asBool(json['isNew']),
      expiresAt: asString(json['expiresAt']),
      token: asStringOrNull(json['token']),
    );
  }

  final CustomerProfile customer;
  final bool isNew;
  final String expiresAt;
  final String? token;
}

class OtpChallenge {
  const OtpChallenge({
    required this.phone,
    required this.purpose,
    required this.expiresInSeconds,
    required this.resendInSeconds,
    required this.channel,
    required this.debugCode,
  });

  factory OtpChallenge.fromJson(Map<String, dynamic> json) {
    return OtpChallenge(
      phone: asString(json['phone']),
      purpose: asString(json['purpose'], 'login'),
      expiresInSeconds: asInt(json['expiresInSeconds'], 120),
      resendInSeconds: asInt(json['resendInSeconds'], 60),
      channel: asString(json['channel'], 'sms'),
      debugCode: asStringOrNull(json['debugCode']),
    );
  }

  final String phone;
  final String purpose;
  final int expiresInSeconds;
  final int resendInSeconds;
  final String channel;
  final String? debugCode;
}
