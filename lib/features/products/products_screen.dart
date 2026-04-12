import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/analytics_service.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../presentation/providers/products_provider.dart';
import '../../presentation/navigation/app_router.dart';
import 'widgets/product_card.dart';
import 'widgets/combo_card.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _router = GoRouter.of(context);
      _router!.routeInformationProvider.addListener(_onRouteChanged);
    });
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final path = _router!.routeInformationProvider.value.uri.path;
    if (path != AppRoutes.products) {
      _searchController.clear();
      ref.read(searchQueryProvider.notifier).state = '';
      ref.invalidate(productsProvider);
      ref.invalidate(combosProvider);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(productsProvider);
    ref.invalidate(combosProvider);
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final combos = ref.watch(combosProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: RefreshIndicator(
        color: AppColors.primaryBrown,
        backgroundColor: AppColors.surfaceWhite,
        onRefresh: _refresh,
        child: CustomScrollView(
          // Always scrollable so pull-to-refresh works even when content is short
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Pinned AppBar + Search ──────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.backgroundCream,
              elevation: 0,
              titleSpacing: 16,
              toolbarHeight: 56,
              title: Text('Our Products', style: AppTextStyles.headingXL),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      ref.read(searchQueryProvider.notifier).state = v;
                      if (v.trim().length >= 3) {
                        AnalyticsService.logSearch(v.trim());
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search flours, categories...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textHint),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: AppColors.textHint),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(searchQueryProvider.notifier)
                                    .state = '';
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceWhite,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primaryBrown, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Individual Products (first) ─────────────────────────────────
            products.when(
              data: (allProducts) {
                final query =
                    ref.watch(searchQueryProvider).toLowerCase();
                final filtered = query.isEmpty
                    ? allProducts
                    : allProducts.where((p) {
                        return p.name.toLowerCase().contains(query) ||
                            p.category.toLowerCase().contains(query);
                      }).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('No products found',
                              style: AppTextStyles.headingM.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => ProductCard(product: filtered[i]),
                      childCount: filtered.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      mainAxisExtent: 310,
                    ),
                  ),
                );
              },
              loading: () =>
                  SliverToBoxAdapter(child: ProductsGridShimmer()),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
            ),

            // ── Combos (after products) ─────────────────────────────────────
            SliverToBoxAdapter(
              child: combos.when(
                data: (comboList) => _CombosSection(combos: comboList),
                loading: () => const _CombosSectionShimmer(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ─── Combos Section ───────────────────────────────────────────────────────────

class _CombosSection extends StatelessWidget {
  const _CombosSection({required this.combos});
  final dynamic combos;

  @override
  Widget build(BuildContext context) {
    if (combos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Divider(color: AppColors.divider, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.comboGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text('Combo Deals', style: AppTextStyles.headingXL),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            children: [
              for (final combo in combos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ComboCard(combo: combo),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CombosSectionShimmer extends StatelessWidget {
  const _CombosSectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerBox(
                width: double.infinity, height: 150, borderRadius: 16),
          ),
        ),
      ),
    );
  }
}
