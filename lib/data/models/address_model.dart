/// Strict mapping to GET /api/addresses response
class Address {
  final String id;
  final String name;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;

  const Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        addressLine: json['addressLine']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        pincode: json['pincode']?.toString() ?? '',
        landmark: json['landmark']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
        'landmark': landmark,
      };

  String get fullAddress {
    final parts = [addressLine];
    if (landmark != null && landmark!.isNotEmpty) parts.add(landmark!);
    parts.addAll([city, state, pincode]);
    return parts.join(', ');
  }

  String get shortAddress => '$addressLine, $city';
}
