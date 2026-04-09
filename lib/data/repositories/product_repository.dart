import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/combo_model.dart';
import '../models/site_config_model.dart';

abstract class IProductRepository {
  Future<List<Product>> getProducts();
  Future<Product> getProductBySlug(String slug);
  Future<List<Combo>> getCombos();
  Future<Combo> getComboById(String id);
  Future<SiteConfig> getSiteConfig();
  Future<LocationInfo> detectLocation();
}

class ProductRepository implements IProductRepository {
  static const _baseUrl = 'https://countryflour.in/api';

  // In-memory caches — one fetch per session
  List<Product>? _productsCache;
  List<Combo>? _combosCache;

  // ── Products (live API) ────────────────────────────────────────────────────

  @override
  Future<List<Product>> getProducts() async {
    if (_productsCache != null) return _productsCache!;

    final uri = Uri.parse('$_baseUrl/products');
    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode != 200) {
      throw Exception('Failed to load products (HTTP ${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);

    // API returns a bare list  →  [ {...}, {...} ]
    final List<dynamic> list = decoded is List ? decoded : (decoded['products'] as List);

    _productsCache = list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();

    return _productsCache!;
  }

  @override
  Future<Product> getProductBySlug(String slug) async {
    final products = await getProducts();
    return products.firstWhere(
      (p) => p.slug == slug,
      orElse: () => throw Exception('Product "$slug" not found'),
    );
  }

  // ── Combos (live API) ──────────────────────────────────────────────────────

  @override
  Future<List<Combo>> getCombos() async {
    if (_combosCache != null) return _combosCache!;

    final uri = Uri.parse('$_baseUrl/combos');
    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode != 200) {
      throw Exception('Failed to load combos (HTTP ${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);

    // API returns a bare list  →  [ {...}, {...} ]
    final List<dynamic> list = decoded is List ? decoded : (decoded['combos'] as List);

    _combosCache = list
        .map((e) => Combo.fromJson(e as Map<String, dynamic>))
        .toList();

    return _combosCache!;
  }

  @override
  Future<Combo> getComboById(String id) async {
    final combos = await getCombos();
    return combos.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Combo $id not found'),
    );
  }

  // ── Site Config (live API) ─────────────────────────────────────────────────

  @override
  Future<SiteConfig> getSiteConfig() async {
    final uri = Uri.parse('$_baseUrl/site-config');
    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode != 200) {
      // Return safe defaults on failure so app still works
      return SiteConfig.defaults();
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return SiteConfig.fromJson(decoded);
    } catch (_) {
      return SiteConfig.defaults();
    }
  }

  @override
  Future<LocationInfo> detectLocation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const LocationInfo(
      isJamshedpur: false,
      city: '',
      region: '',
    );
    // TODO: GET $_baseUrl/detect-location
  }
}
