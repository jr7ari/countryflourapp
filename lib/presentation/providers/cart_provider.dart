import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/analytics_service.dart';
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
      items.fold(0.0, (sum, item) => sum + item.effectiveLineTotal);

  double get totalMRP =>
      items.fold(0.0, (sum, item) => sum + item.totalMRP);

  double get totalSavings => totalMRP - subtotal;

  // Prices include shipping and all taxes — no extra charges
  double get grandTotal => subtotal - couponDiscount;

  // Local delivery (pincode 831xx): sum of each item's baseMRP × qty + ₹20 fee
  static const double localDeliveryFee = 20.0;

  double get localDeliveryTotal {
    final mrpTotal = items.fold(0.0, (sum, item) {
      if (item.isCombo) {
        return sum + (item.combo!.mrp * item.quantity);
      } else {
        return sum + (item.product!.baseMRP * item.quantity);
      }
    });
    return mrpTotal + localDeliveryFee;
  }

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
    AnalyticsService.logAddProduct(product, variant, quantity);
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
    AnalyticsService.logAddCombo(combo, quantity);
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
    final item = state.items.firstWhere(
      (i) => i.cartId == cartId,
      orElse: () => throw StateError('Item not found'),
    );
    AnalyticsService.logRemoveFromCart(item);
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

// ─── Helper — show info toast when cart weight limit is hit ──────────────────

void showWeightExceededToast(BuildContext context, WidgetRef ref) {
  final maxKg = ref.read(siteConfigProvider).maybeWhen(
    data: (c) => c.maxCartWeightKg,
    orElse: () => 50.0,
  );
  final label = maxKg == maxKg.truncateToDouble()
      ? maxKg.toInt().toString()
      : maxKg.toStringAsFixed(1);

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cart is full — max $label kg per order',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B), // amber
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
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
