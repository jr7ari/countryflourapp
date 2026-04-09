/// Strict mapping to GET /api/site-config response
class SiteConfig {
  final bool bannerEnabled;
  final String bannerMessage;
  final String bannerType;
  final String deliveryPartner;
  final double maxCartWeightKg;
  final bool showLocalOffer;

  const SiteConfig({
    required this.bannerEnabled,
    required this.bannerMessage,
    required this.bannerType,
    required this.deliveryPartner,
    required this.maxCartWeightKg,
    required this.showLocalOffer,
  });

  factory SiteConfig.fromJson(Map<String, dynamic> json) => SiteConfig(
        bannerEnabled: json['bannerEnabled'] as bool? ?? false,
        bannerMessage: json['bannerMessage']?.toString() ?? '',
        bannerType: json['bannerType']?.toString() ?? 'info',
        deliveryPartner: json['deliveryPartner']?.toString() ?? '',
        maxCartWeightKg: _parseMaxWeight(json),
        showLocalOffer: json['showLocalOffer'] as bool? ?? false,
      );

  /// Tries several field names; value may be kg (e.g. 25) or grams (e.g. 25000)
  static double _parseMaxWeight(Map<String, dynamic> json) {
    final raw = json['maxCartWeightKg'] ??
        json['maxCartWeight'] ??
        json['maxOrderWeight'] ??
        json['cartWeightLimit'];
    if (raw == null) return 50.0;
    final val = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    if (val == null) return 50.0;
    // If value looks like grams (> 500), convert to kg
    return val > 500 ? val / 1000 : val;
  }

  factory SiteConfig.defaults() => const SiteConfig(
        bannerEnabled: false,
        bannerMessage: '',
        bannerType: 'info',
        deliveryPartner: '',
        maxCartWeightKg: 50.0,
        showLocalOffer: false,
      );

  Map<String, dynamic> toJson() => {
        'bannerEnabled': bannerEnabled,
        'bannerMessage': bannerMessage,
        'bannerType': bannerType,
        'deliveryPartner': deliveryPartner,
        'maxCartWeightKg': maxCartWeightKg,
        'showLocalOffer': showLocalOffer,
      };
}

/// Mapping to GET /api/detect-location response
class LocationInfo {
  final bool isJamshedpur;
  final String city;
  final String region;

  const LocationInfo({
    required this.isJamshedpur,
    required this.city,
    required this.region,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) => LocationInfo(
        isJamshedpur: json['isJamshedpur'] as bool? ?? false,
        city: json['city']?.toString() ?? '',
        region: json['region']?.toString() ?? '',
      );

  factory LocationInfo.unknown() => const LocationInfo(
        isJamshedpur: false,
        city: '',
        region: '',
      );
}
