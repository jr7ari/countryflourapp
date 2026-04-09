import 'product_model.dart';
import 'combo_model.dart';

/// Unified cart item for both normal products and combos
class CartItem {
  final String cartId; // unique key in cart
  final bool isCombo;

  // Normal product fields
  final Product? product;
  final ProductVariant? variant;

  // Combo fields
  final Combo? combo;

  final int quantity;

  const CartItem({
    required this.cartId,
    required this.isCombo,
    this.product,
    this.variant,
    this.combo,
    required this.quantity,
  });

  /// Price per unit
  double get unitPrice {
    if (isCombo && combo != null) return combo!.offerPrice;
    if (!isCombo && variant != null) return variant!.price;
    return 0;
  }

  /// Compare price per unit (MRP)
  double get unitMRP {
    if (isCombo && combo != null) return combo!.mrp;
    if (!isCombo && variant != null) return variant!.comparePrice;
    return 0;
  }

  /// Total price for this line
  double get totalPrice => unitPrice * quantity;

  /// Total MRP for this line
  double get totalMRP => unitMRP * quantity;

  /// Display name
  String get displayName {
    if (isCombo && combo != null) return combo!.name;
    if (!isCombo && product != null) return product!.name;
    return '';
  }

  /// Display weight/size label
  String get displayWeight {
    if (isCombo && combo != null) return combo!.weightSummary;
    if (!isCombo && variant != null) return variant!.weight;
    return '';
  }

  /// Display image
  String get displayImage {
    if (isCombo && combo != null) return combo!.img;
    if (!isCombo && product != null) return product!.image;
    return '';
  }

  double get savingsPerUnit => unitMRP - unitPrice;
  double get totalSavings => savingsPerUnit * quantity;

  /// Parse a weight string → kilograms
  /// Handles: "1kg", "1.5kg", "500g", "500gm", "1 Kg", "250 G", "1000gms"
  static double parseWeightKg(String w) {
    final s = w.toLowerCase().replaceAll(' ', '').replaceAll(',', '.');
    if (s.endsWith('kg')) {
      return double.tryParse(s.replaceAll('kg', '')) ?? 0;
    } else if (s.endsWith('gms')) {
      return (double.tryParse(s.replaceAll('gms', '')) ?? 0) / 1000;
    } else if (s.endsWith('gm')) {
      return (double.tryParse(s.replaceAll('gm', '')) ?? 0) / 1000;
    } else if (s.endsWith('g')) {
      return (double.tryParse(s.replaceAll('g', '')) ?? 0) / 1000;
    }
    // bare number — assume kg if ≤ 25, grams if larger
    final bare = double.tryParse(s);
    if (bare != null) return bare <= 25 ? bare : bare / 1000;
    return 0;
  }

  /// Weight of this line item (all units) in kg
  double get lineWeightKg {
    if (isCombo && combo != null) {
      // Primary: sum weight of every product inside the combo
      final fromProducts = combo!.products.fold<double>(
        0,
        (sum, item) => sum + parseWeightKg(item.weight) * item.quantity,
      );
      if (fromProducts > 0) return fromProducts * quantity;
      // Fallback: combo-level weight field (e.g. API returns "2kg" on the combo)
      final fromCombo = parseWeightKg(combo!.weight);
      return fromCombo * quantity;
    }
    if (!isCombo && variant != null) {
      return parseWeightKg(variant!.weight) * quantity;
    }
    return 0;
  }

  CartItem copyWith({int? quantity}) => CartItem(
        cartId: cartId,
        isCombo: isCombo,
        product: product,
        variant: variant,
        combo: combo,
        quantity: quantity ?? this.quantity,
      );

  static CartItem fromProduct({
    required Product product,
    required ProductVariant variant,
    required int quantity,
  }) =>
      CartItem(
        cartId: 'product_${product.id}_${variant.id}',
        isCombo: false,
        product: product,
        variant: variant,
        quantity: quantity,
      );

  static CartItem fromCombo({
    required Combo combo,
    required int quantity,
  }) =>
      CartItem(
        cartId: 'combo_${combo.id}',
        isCombo: true,
        combo: combo,
        quantity: quantity,
      );
}
