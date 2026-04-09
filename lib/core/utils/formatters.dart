import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _currencyFormatDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String currency(double amount) => _currencyFormat.format(amount);
  static String currencyDecimal(double amount) => _currencyFormatDecimal.format(amount);

  static String date(DateTime dt) => _dateFormat.format(dt);
  static String dateTime(DateTime dt) => _dateTimeFormat.format(dt);

  static String discountPercent(double original, double discounted) {
    if (original <= 0) return '0%';
    final pct = ((original - discounted) / original) * 100;
    return '${pct.toStringAsFixed(0)}%';
  }

  static double discountPercentValue(double original, double discounted) {
    if (original <= 0) return 0;
    return ((original - discounted) / original) * 100;
  }

  static String savings(double original, double discounted) {
    return currency(original - discounted);
  }

  static String weight(String w) {
    // Normalize weight display: "1000g" → "1 kg", "500g" → "500g"
    if (w.toLowerCase().endsWith('g')) {
      final grams = int.tryParse(w.toLowerCase().replaceAll('g', '').trim());
      if (grams != null && grams >= 1000 && grams % 1000 == 0) {
        return '${grams ~/ 1000} kg';
      }
    }
    return w;
  }

  static String orderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
