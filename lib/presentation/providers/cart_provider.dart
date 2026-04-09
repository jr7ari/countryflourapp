import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/combo_model.dart';
import 'products_provider.dart';

// ─── Cart State ───────────────────────────────────────────────────────────────

enum CartAddResult { success, weightExceeded }

class CartState {
  final List<CartItem> items;
  final String? couponCode;
  final double couponDiscount;

  const CartState({
    this.items = const [],
    this.couponCode,
    this.couponDiscount = 0.0,
  });

  CartState copyWith({
    List<CartItem>? items,
    String? couponCode,
    double? couponDiscount,
    bool clearCoupon = false,
  }) =>
      CartState(
        items: items ?? this.items,
        couponCode: clearCoupon ? null : (couponCode ?? this.couponCode),
        couponDiscount: clearCoupon ? 0.0 : (couponDiscount ?? this.couponDiscount),
      );

  /// Total weight of all items in cart (kg)
  double get totalWeightKg =>
      items.fold(0.0, (sum, item) => sum + item.lineWeightKg);

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get totalMRP =>
      items.fold(0.0, (sum, item) => sum + item.totalMRP);

  double get totalSavings => totalMRP - subtotal;

  double get subtotalAfterCoupon => subtotal - couponDiscount;

  // CGST & SGST each at 2.5%
  static const double taxRate = 2.5;
  double get cgst => subtotalAfterCoupon * taxRate / 100;
  double get sgst => subtotalAfterCoupon * taxRate / 100;
  double get totalTax => cgst + sgst;

  // Delivery is always FREE
  double get deliveryFee => 0.0;

  double get grandTotal => subtotalAfterCoupon + totalTax;

  bool get hasCoupon => couponCode != null && couponCode!.isNotEmpty;

  int get totalItems =>
      items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  bool containsProduct(String productId, String variantId) => items.any(
        (item) =>
            !item.isCombo &&
            item.product?.id == productId &&
            item.variant?.id == variantId,
      );

  bool containsCombo(String comboId) => items.any(
        (item) => item.isCombo && item.combo?.id == comboId,
      );

  int quantityOf(String cartId) {
    try {
      return items.firstWhere((i) => i.cartId == cartId).quantity;
    } catch (_) {
      return 0;
    }
  }
}

// ─── Cart Notifier ────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<CartState> {
  final Ref _ref;
  CartNotifier(this._ref) : super(const CartState());

  /// Live weight limit from siteConfigProvider — always up-to-date
  double get _maxWeightKg => _ref.read(siteConfigProvider).maybeWhen(
        data: (config) => config.maxCartWeightKg,
        orElse: () => 50.0,
      );

  CartAddResult addProduct(Product product, ProductVariant variant,
      {int quantity = 1}) {
    final newItem = CartItem.fromProduct(
        product: product, variant: variant, quantity: quantity);
    final cartId = newItem.cartId;
    final existingIdx = state.items.indexWhere((i) => i.cartId == cartId);

    // Weight already in cart (excluding the item we're updating if it exists)
    final baseWeight = existingIdx >= 0
        ? state.totalWeightKg - state.items[existingIdx].lineWeightKg
        : state.totalWeightKg;
    final addedWeight = existingIdx >= 0
        ? state.items[existingIdx]
            .copyWith(quantity: state.items[existingIdx].quantity + quantity)
            .lineWeightKg
        : newItem.lineWeightKg;

    if (baseWeight + addedWeight > _maxWeightKg) {
      return CartAddResult.weightExceeded;
    }

    if (existingIdx >= 0) {
      final updated = List<CartItem>.from(state.items);
      final current = updated[existingIdx];
      updated[existingIdx] =
          current.copyWith(quantity: current.quantity + quantity);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, newItem]);
    }
    return CartAddResult.success;
  }

  CartAddResult addCombo(Combo combo, {int quantity = 1}) {
    final newItem = CartItem.fromCombo(combo: combo, quantity: quantity);
    final cartId = 'combo_${combo.id}';
    final existingIdx = state.items.indexWhere((i) => i.cartId == cartId);

    final baseWeight = existingIdx >= 0
        ? state.totalWeightKg - state.items[existingIdx].lineWeightKg
        : state.totalWeightKg;
    final addedWeight = existingIdx >= 0
        ? state.items[existingIdx]
            .copyWith(quantity: state.items[existingIdx].quantity + quantity)
            .lineWeightKg
        : newItem.lineWeightKg;

    if (baseWeight + addedWeight > _maxWeightKg) {
      return CartAddResult.weightExceeded;
    }

    if (existingIdx >= 0) {
      final updated = List<CartItem>.from(state.items);
      final current = updated[existingIdx];
      updated[existingIdx] =
          current.copyWith(quantity: current.quantity + quantity);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, newItem]);
    }
    return CartAddResult.success;
  }

  void updateQuantity(String cartId, int newQty) {
    if (newQty <= 0) {
      removeItem(cartId);
      return;
    }
    final idx = state.items.indexWhere((i) => i.cartId == cartId);
    if (idx < 0) return;

    final item = state.items[idx];
    // Weight check only when increasing
    if (newQty > item.quantity) {
      final weightWithout = state.totalWeightKg - item.lineWeightKg;
      final newLineWeight = item.copyWith(quantity: newQty).lineWeightKg;
      if (weightWithout + newLineWeight > _maxWeightKg) return; // silently block
    }

    final updated = List<CartItem>.from(state.items);
    updated[idx] = item.copyWith(quantity: newQty);
    state = state.copyWith(items: updated);
  }

  void removeItem(String cartId) {
    state = state.copyWith(
      items: state.items.where((i) => i.cartId != cartId).toList(),
    );
  }

  /// Apply a coupon code. In production, validate via API first.
  void applyCoupon(String code, double discount) {
    state = state.copyWith(couponCode: code, couponDiscount: discount);
  }

  void removeCoupon() {
    state = state.copyWith(clearCoupon: true);
  }

  void clear() => state = const CartState();
}

// ─── Helper — show weight-exceeded or success snackbar ───────────────────────

void showCartSnackBar(
  BuildContext context,
  CartAddResult result,
  String itemName,
  double maxWeightKg,
) {
  final msg = result == CartAddResult.weightExceeded
      ? '⚠️ Cart limit reached (max ${maxWeightKg.toStringAsFixed(1)} kg)'
      : '$itemName added to cart!';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: result == CartAddResult.weightExceeded
          ? AppColors.error
          : null,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalItems;
});
