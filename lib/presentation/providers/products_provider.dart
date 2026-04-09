import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/models/combo_model.dart';
import '../../data/models/site_config_model.dart';
import '../../data/repositories/product_repository.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// ─── Products ────────────────────────────────────────────────────────────────

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getProducts();
});

final productBySlugProvider = FutureProvider.family<Product, String>((ref, slug) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getProductBySlug(slug);
});

// ─── Combos ──────────────────────────────────────────────────────────────────

final combosProvider = FutureProvider<List<Combo>>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getCombos();
});

final comboByIdProvider = FutureProvider.family<Combo, String>((ref, id) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getComboById(id);
});

// ─── Featured Products ───────────────────────────────────────────────────────

final featuredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(productsProvider).whenData(
        (products) => products.where((p) => p.featured).toList(),
      );
});

final bestsellerProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(productsProvider).whenData(
        (products) => products.where((p) => p.bestseller).toList(),
      );
});

// ─── Site Config ─────────────────────────────────────────────────────────────

final siteConfigProvider = FutureProvider<SiteConfig>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getSiteConfig();
});

final detectLocationProvider = FutureProvider<LocationInfo>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.detectLocation();
});

// ─── Filter State ────────────────────────────────────────────────────────────

enum ProductFilter { all, normal, combo }

final productFilterProvider = StateProvider<ProductFilter>((ref) => ProductFilter.all);

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Derived: all categories from products
final categoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(productsProvider).whenData(
        (products) => products.map((p) => p.category).toSet().toList()..sort(),
      );
});
