import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/address_model.dart';

abstract class IOrderRepository {
  Future<List<Order>> getOrders({int page = 1, int limit = 20});
  Future<Order> getOrderById(String orderId);
  Future<bool> cancelOrder(String orderId);
  Future<List<Address>> getAddresses();
  Future<Address> createAddress(AddressRequest body);
  Future<double> getShippingRate(Map<String, dynamic> body);
  Future<RazorpayOrderResponse> createRazorpayOrder(CreateOrderRequest request);
  Future<Order> verifyPayment(PaymentVerifyRequest request);
}

class OrderRepository implements IOrderRepository {
  static const _base = 'https://www.countryflour.in/api/mobileapi';

  final String? token;

  OrderRepository({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── Orders ────────────────────────────────────────────────────────────────

  @override
  Future<List<Order>> getOrders({int page = 1, int limit = 20}) async {
    final uri = Uri.parse('$_base/user/orders').replace(
      queryParameters: {'page': '$page', 'limit': '$limit'},
    );
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load orders (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body);
    final List<dynamic> list = body is List
        ? body
        : (body['orders'] ?? body['data'] ?? []) as List<dynamic>;
    return list
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Order> getOrderById(String orderId) async {
    final res = await http.get(
      Uri.parse('$_base/user/orders/$orderId'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load order $orderId (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Order.fromJson(body['order'] ?? body);
  }

  @override
  Future<bool> cancelOrder(String orderId) async {
    final res = await http.post(
      Uri.parse('$_base/user/orders/$orderId'),
      headers: _headers,
      body: jsonEncode({'action': 'cancel'}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
          'Failed to cancel order (${res.statusCode}): ${res.body}');
    }
    return true;
  }

  // ─── Addresses ─────────────────────────────────────────────────────────────

  @override
  Future<List<Address>> getAddresses() async {
    final res = await http.get(
      Uri.parse('$_base/addresses'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load addresses (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body);
    final List<dynamic> list = body is List
        ? body
        : (body['addresses'] ?? body['data'] ?? []) as List<dynamic>;
    return list
        .map((e) => Address.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Address> createAddress(AddressRequest request) async {
    final res = await http.post(
      Uri.parse('$_base/addresses'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
          'Failed to create address (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Address.fromJson(body['address'] ?? body);
  }

  // ─── Shipping ───────────────────────────────────────────────────────────────

  @override
  Future<double> getShippingRate(Map<String, dynamic> body) async {
    return 49.0; // TODO: wire to shipping API
  }

  // ─── Payment ────────────────────────────────────────────────────────────────

  @override
  Future<RazorpayOrderResponse> createRazorpayOrder(
      CreateOrderRequest request) async {
    final res = await http.post(
      Uri.parse('$_base/payment/create-order'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
          'Failed to create Razorpay order (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return RazorpayOrderResponse.fromJson(body);
  }

  @override
  Future<Order> verifyPayment(PaymentVerifyRequest request) async {
    final res = await http.post(
      Uri.parse('$_base/payment/verify'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
          'Payment verification failed (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Order.fromJson(body['order'] ?? body);
  }
}

// ─── Request model ─────────────────────────────────────────────────────────────

class AddressRequest {
  final String name;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;

  const AddressRequest({
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
      };
}
