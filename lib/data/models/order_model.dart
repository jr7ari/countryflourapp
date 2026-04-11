import 'address_model.dart';

/// Strict mapping to GET /api/orders response
class OrderItem {
  final String productId;
  final String productName;
  final String variantId;
  final int quantity;
  final bool isCombo;
  final double price;
  final String weight;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.quantity,
    required this.isCombo,
    required this.price,
    required this.weight,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? '',
        variantId: json['variantId']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        isCombo: json['isCombo'] as bool? ?? false,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        weight: json['weight']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'variantId': variantId,
        'quantity': quantity,
        'isCombo': isCombo,
        'price': price,
        'weight': weight,
      };
}

class Order {
  final String orderId;
  final double totalAmount;
  final double subtotal;
  final double shippingCharges;
  final String paymentStatus;
  final String orderStatus;
  final List<OrderItem> items;
  final DateTime createdAt;
  final Address? shippingAddress;

  const Order({
    required this.orderId,
    required this.totalAmount,
    required this.subtotal,
    required this.shippingCharges,
    required this.paymentStatus,
    required this.orderStatus,
    required this.items,
    required this.createdAt,
    this.shippingAddress,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderId: json['orderId']?.toString() ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
        shippingCharges: (json['shippingCharges'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
        orderStatus: json['orderStatus']?.toString() ?? 'pending',
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        shippingAddress: json['shippingAddress'] != null
            ? Address.fromJson(json['shippingAddress'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'totalAmount': totalAmount,
        'subtotal': subtotal,
        'shippingCharges': shippingCharges,
        'paymentStatus': paymentStatus,
        'orderStatus': orderStatus,
        'items': items.map((i) => i.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'shippingAddress': shippingAddress?.toJson(),
      };

  bool get isDelivered => orderStatus.toLowerCase() == 'delivered';
  bool get isCancelled => orderStatus.toLowerCase() == 'cancelled';
  bool get canCancel =>
      !isDelivered &&
      !isCancelled &&
      ['pending', 'confirmed', 'processing'].contains(orderStatus.toLowerCase());

  int get statusStep {
    switch (orderStatus.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'processing':
        return 2;
      case 'shipped':
        return 3;
      case 'out_for_delivery':
        return 4;
      case 'delivered':
        return 5;
      default:
        return 0;
    }
  }
}

/// Request model for POST /api/payment/create-order
class CreateOrderRequest {
  final double amount;
  final double subtotal;
  final double shippingCharges;
  final List<CartItemRequest> items;
  final Map<String, dynamic> shippingAddress;

  const CreateOrderRequest({
    required this.amount,
    required this.subtotal,
    required this.shippingCharges,
    required this.items,
    required this.shippingAddress,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'subtotal': subtotal,
        'shippingCharges': shippingCharges,
        'items': items.map((i) => i.toJson()).toList(),
        'shippingAddress': shippingAddress,
      };
}

/// Response from POST /api/mobileapi/payment/create-order
class RazorpayOrderResponse {
  final String razorpayOrderId;
  final String orderId; // internal CF order ID
  final double amount;

  const RazorpayOrderResponse({
    required this.razorpayOrderId,
    required this.orderId,
    required this.amount,
  });

  factory RazorpayOrderResponse.fromJson(Map<String, dynamic> json) =>
      RazorpayOrderResponse(
        razorpayOrderId: json['razorpayOrderId']?.toString() ?? '',
        orderId: json['orderId']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Request body for POST /api/mobileapi/payment/verify
class PaymentVerifyRequest {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;
  final String orderId;
  final double amount;
  final double subtotal;
  final double shippingCharges;
  final List<CartItemRequest> items;
  final Map<String, dynamic> shippingAddress;
  final String? couponCode;
  final double discountAmount;

  const PaymentVerifyRequest({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
    required this.orderId,
    required this.amount,
    required this.subtotal,
    required this.shippingCharges,
    required this.items,
    required this.shippingAddress,
    this.couponCode,
    this.discountAmount = 0,
  });

  Map<String, dynamic> toJson() => {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'orderId': orderId,
        'amount': amount,
        'subtotal': subtotal,
        'shippingCharges': shippingCharges,
        'items': items.map((i) => i.toJson()).toList(),
        'shippingAddress': shippingAddress,
        'couponCode': couponCode,
        'discountAmount': discountAmount,
      };
}

class CartItemRequest {
  final String productId;
  final String productName;
  final String variantId;
  final String weight;
  final int quantity;
  final double price;
  final bool isCombo;

  const CartItemRequest({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.weight,
    required this.quantity,
    required this.price,
    required this.isCombo,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'variantId': variantId,
        'weight': weight,
        'quantity': quantity,
        'price': price,
        'isCombo': isCombo,
      };
}
