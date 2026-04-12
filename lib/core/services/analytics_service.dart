import 'package:firebase_analytics/firebase_analytics.dart';
import '../../data/models/product_model.dart';
import '../../data/models/combo_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/order_model.dart';

/// Central analytics service — all GA4 event calls go through here.
/// Uses FirebaseAnalytics singleton; no Riverpod wiring needed.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _fa);

  // ─── Screen Tracking ───────────────────────────────────────────────────────

  static Future<void> logScreenView(String screenName) =>
      _fa.logScreenView(screenName: screenName);

  // ─── Auth Events ───────────────────────────────────────────────────────────

  static Future<void> logLogin() =>
      _fa.logLogin(loginMethod: 'google');

  // ─── Product Events ────────────────────────────────────────────────────────

  static Future<void> logViewProduct(Product product) =>
      _fa.logViewItem(
        currency: 'INR',
        value: product.lowestPrice,
        items: [
          AnalyticsEventItem(
            itemId: product.id,
            itemName: product.name,
            itemCategory: product.category,
            price: product.lowestPrice,
          ),
        ],
      );

  static Future<void> logViewCombo(Combo combo) =>
      _fa.logViewItem(
        currency: 'INR',
        value: combo.offerPrice,
        items: [
          AnalyticsEventItem(
            itemId: combo.id,
            itemName: combo.name,
            itemCategory: 'combo',
            price: combo.offerPrice,
          ),
        ],
      );

  // ─── Cart Events ───────────────────────────────────────────────────────────

  static Future<void> logAddProduct(
      Product product, ProductVariant variant, int quantity) =>
      _fa.logAddToCart(
        currency: 'INR',
        value: variant.price * quantity,
        items: [
          AnalyticsEventItem(
            itemId: product.id,
            itemName: product.name,
            itemCategory: product.category,
            itemVariant: variant.weight,
            price: variant.price,
            quantity: quantity,
          ),
        ],
      );

  static Future<void> logAddCombo(Combo combo, int quantity) =>
      _fa.logAddToCart(
        currency: 'INR',
        value: combo.offerPrice * quantity,
        items: [
          AnalyticsEventItem(
            itemId: combo.id,
            itemName: combo.name,
            itemCategory: 'combo',
            price: combo.offerPrice,
            quantity: quantity,
          ),
        ],
      );

  static Future<void> logRemoveFromCart(CartItem item) =>
      _fa.logRemoveFromCart(
        currency: 'INR',
        value: item.unitPrice * item.quantity,
        items: [
          AnalyticsEventItem(
            itemId: item.isCombo ? item.combo!.id : item.product!.id,
            itemName: item.displayName,
            itemCategory: item.isCombo ? 'combo' : item.product!.category,
            price: item.unitPrice,
            quantity: item.quantity,
          ),
        ],
      );

  static Future<void> logViewCart(
      List<CartItem> items, double total) =>
      _fa.logViewCart(
        currency: 'INR',
        value: total,
        items: items.map((item) => AnalyticsEventItem(
          itemId: item.isCombo ? item.combo!.id : item.product!.id,
          itemName: item.displayName,
          itemCategory: item.isCombo ? 'combo' : item.product!.category,
          price: item.unitPrice,
          quantity: item.quantity,
        )).toList(),
      );

  // ─── Checkout Events ───────────────────────────────────────────────────────

  static Future<void> logBeginCheckout(
      List<CartItem> items, double total) =>
      _fa.logBeginCheckout(
        currency: 'INR',
        value: total,
        items: items.map((item) => AnalyticsEventItem(
          itemId: item.isCombo ? item.combo!.id : item.product!.id,
          itemName: item.displayName,
          price: item.unitPrice,
          quantity: item.quantity,
        )).toList(),
      );

  static Future<void> logPurchase(Order order) =>
      _fa.logPurchase(
        currency: 'INR',
        transactionId: order.orderId,
        value: order.totalAmount,
        shipping: order.shippingCharges,
        items: order.items.map((item) => AnalyticsEventItem(
          itemId: item.productId,
          itemName: item.productName,
          price: item.price,
          quantity: item.quantity,
        )).toList(),
      );

  // ─── Search Events ─────────────────────────────────────────────────────────

  static Future<void> logSearch(String query) =>
      _fa.logSearch(searchTerm: query);

  // ─── Order Events ──────────────────────────────────────────────────────────

  static Future<void> logCancelOrder(String orderId) =>
      _fa.logEvent(
        name: 'cancel_order',
        parameters: {'order_id': orderId},
      );
}
