class AppConstants {
  AppConstants._();

  static const String appName = 'Country Flour';
  static const String appTagline = 'Pure. Fresh. Wholesome.';

  // API Base (for future integration)
  static const String baseUrl = 'https://countryflour.in/api';
  static const String productsEndpoint = '/products';
  static const String combosEndpoint = '/combos';
  static const String siteConfigEndpoint = '/site-config';
  static const String detectLocationEndpoint = '/detect-location';
  static const String shippingRateEndpoint = '/shipping/rate';
  static const String addressesEndpoint = '/addresses';
  static const String createOrderEndpoint = '/payment/create-order';
  static const String verifyPaymentEndpoint = '/payment/verify';
  static const String ordersEndpoint = '/orders';

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 100.0;

  // Card Elevation
  static const double elevationCard = 2.0;
  static const double elevationModal = 8.0;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);

  // Product
  static const int maxCartQuantity = 10;
  static const double maxCartWeightKg = 50.0;
}
