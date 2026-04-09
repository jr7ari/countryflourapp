import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/add_or_counter_button.dart';
import '../../../data/models/product_model.dart';
import '../../../presentation/providers/products_provider.dart';
import '../../../presentation/providers/cart_provider.dart';
import '../../../presentation/navigation/app_router.dart';

class FeaturedProductsSection extends ConsumerWidget {
  const FeaturedProductsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredProductsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Featured Products', style: AppTextStyles.headingXL),
                  Text('Handpicked for quality',
                      style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.products),
                child: Text('See All',
                    style: AppTextStyles.buttonM.copyWith(color: AppColors.primaryBrown)),
              ),
            ],
          ),
        ),
        featured.when(
          data: (products) => SizedBox(
            height: 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              itemCount: products.length,
              itemBuilder: (_, i) => _FeaturedProductCard(product: products[i]),
            ),
          ),
          loading: () => SizedBox(
            height: 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              itemCount: 4,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ShimmerBox(width: 160, height: 280, borderRadius: 16),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _FeaturedProductCard extends ConsumerWidget {
  const _FeaturedProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultVariant = product.defaultVariant;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.productDetailPath(product.slug)),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: AppColors.cardGradient,
                    ),
                    child: Hero(
                      tag: 'product_featured_${product.id}',
                      child: Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.grain_rounded, size: 40, color: AppColors.primaryGold),
                        ),
                      ),
                    ),
                  ),
                  // Out of Stock overlay
                  if (!product.inStock) ...[
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withAlpha(45),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'OUT OF STOCK',
                            style: AppTextStyles.badge.copyWith(
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Info — Expanded fills remaining space ─────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.headingS,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (defaultVariant != null) ...[
                      Text(
                        '₹${defaultVariant.price.toInt()}',
                        style: AppTextStyles.priceS,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        defaultVariant.weight,
                        style: AppTextStyles.labelM,
                      ),
                    ],
                    const SizedBox(height: 5),

                    // ── Bulk combo chips ────────────────────────────────
                    if (product.combos.isNotEmpty)
                      SizedBox(
                        height: 20,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: product.combos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (_, i) {
                            final c = product.combos[i];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0DF),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: AppColors.primaryBrown.withAlpha(70),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                'Buy ${c.qty} for ₹${c.offerPrice.toInt()}',
                                style: AppTextStyles.labelS.copyWith(
                                  color: AppColors.primaryBrown,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Add / Counter button — pinned at bottom ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: defaultVariant == null
                  ? const SizedBox.shrink()
                  : AddOrCounterButton(
                      cartId: 'product_${product.id}_${defaultVariant.id}',
                      disabled: !product.inStock,
                      height: 34,
                      activeColor: AppColors.primaryBrown,
                      backgroundColor: const Color(0xFFF5E6CC),
                      onAdd: () {
                        final result = ref
                            .read(cartProvider.notifier)
                            .addProduct(product, defaultVariant);
                        if (result == CartAddResult.weightExceeded) {
                          showWeightExceededToast(context, ref);
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
