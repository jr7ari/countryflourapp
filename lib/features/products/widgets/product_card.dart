import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/badge_widget.dart';
import '../../../core/widgets/add_or_counter_button.dart';
import '../../../data/models/product_model.dart';
import '../../../presentation/providers/cart_provider.dart';
import '../../../presentation/navigation/app_router.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultVariant = product.defaultVariant;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.productDetailPath(product.slug)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ─────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: const Color(0xFFFFF8ED),
                    child: Hero(
                      tag: 'product_${product.id}',
                      child: Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.grain_rounded,
                              size: 48, color: AppColors.primaryGold),
                        ),
                      ),
                    ),
                  ),
                ),
                if (product.bestseller || product.featured)
                  Positioned(
                    top: 7,
                    left: 7,
                    child: product.bestseller
                        ? const AppBadge(type: BadgeType.bestseller, small: true)
                        : const AppBadge(type: BadgeType.featured, small: true),
                  ),
                if (defaultVariant != null && defaultVariant.hasDiscount)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: DiscountBadge(
                        percent: defaultVariant.discountPercent, small: true),
                  ),
                if (!product.inStock)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: Container(
                        color: Colors.black.withAlpha(100),
                        child: const Center(
                          child: AppBadge(type: BadgeType.outOfStock),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info ─────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: AppTextStyles.headingS,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Rating + category
                    Row(
                      children: [
                        if (product.reviewCount > 0) ...[
                          const Icon(Icons.star_rounded,
                              size: 11, color: AppColors.primaryGold),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: AppTextStyles.labelM.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            product.category,
                            style: AppTextStyles.labelS,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Price row
                    if (defaultVariant != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${defaultVariant.price.toInt()}',
                            style: AppTextStyles.priceS,
                          ),
                          if (defaultVariant.hasDiscount) ...[
                            const SizedBox(width: 4),
                            Text(
                              '₹${defaultVariant.comparePrice.toInt()}',
                              style: AppTextStyles.priceStrike,
                            ),
                          ],
                          const Spacer(),
                          Text(
                            defaultVariant.weight,
                            style: AppTextStyles.labelS,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Combo chips
                    if (product.combos.isNotEmpty)
                      SizedBox(
                        height: 22,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: product.combos.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(width: 4),
                          itemBuilder: (_, i) {
                            final c = product.combos[i];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
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
                                  fontSize: 9.5,
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

            // ── Button ───────────────────────────────────────────
            if (defaultVariant != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: AddOrCounterButton(
                  cartId: 'product_${product.id}_${defaultVariant.id}',
                  disabled: !product.inStock,
                  label: 'Add to Cart',
                  height: 32,
                  activeColor: Colors.white,
                  backgroundColor: AppColors.primaryBrown,
                  onAdd: () {
                    ref.read(cartProvider.notifier)
                        .addProduct(product, defaultVariant);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../../../core/constants/app_colors.dart';
// import '../../../core/constants/app_text_styles.dart';
// import '../../../core/widgets/badge_widget.dart';
// import '../../../core/widgets/add_or_counter_button.dart';
// import '../../../data/models/product_model.dart';
// import '../../../presentation/providers/cart_provider.dart';
// import '../../../presentation/navigation/app_router.dart';
//
// class ProductCard extends ConsumerWidget {
//   const ProductCard({super.key, required this.product});
//
//   final Product product;
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final defaultVariant = product.defaultVariant;
//
//     return GestureDetector(
//       onTap: () => context.push(AppRoutes.productDetailPath(product.slug)),
//       child: Container(
//         decoration: BoxDecoration(
//           color: AppColors.surfaceWhite,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: AppColors.border, width: 0.5),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withAlpha(8),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         // ── Column fills the fixed grid cell height ──────────────────────────
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ── Image ──────────────────────────────────────────────────────
//             Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius:
//                       const BorderRadius.vertical(top: Radius.circular(16)),
//                   child: Container(
//                     height: 130,
//                     width: double.infinity,
//                     color: const Color(0xFFFFF8ED),
//                     child: Hero(
//                       tag: 'product_${product.id}',
//                       child: Image.network(
//                         product.image,
//                         fit: BoxFit.cover,
//                         errorBuilder: (_, __, ___) => const Center(
//                           child: Icon(Icons.grain_rounded,
//                               size: 48, color: AppColors.primaryGold),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 if (product.bestseller || product.featured)
//                   Positioned(
//                     top: 7,
//                     left: 7,
//                     child: product.bestseller
//                         ? const AppBadge(type: BadgeType.bestseller, small: true)
//                         : const AppBadge(type: BadgeType.featured, small: true),
//                   ),
//                 if (defaultVariant != null && defaultVariant.hasDiscount)
//                   Positioned(
//                     top: 7,
//                     right: 7,
//                     child: DiscountBadge(
//                         percent: defaultVariant.discountPercent, small: true),
//                   ),
//                 if (!product.inStock)
//                   Positioned.fill(
//                     child: ClipRRect(
//                       borderRadius: const BorderRadius.vertical(
//                           top: Radius.circular(16)),
//                       child: Container(
//                         color: Colors.black.withAlpha(100),
//                         child: const Center(
//                           child: AppBadge(type: BadgeType.outOfStock),
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//
//             // ── Info — Expanded so it fills remaining space ─────────────────
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Product name
//                     Text(
//                       product.name,
//                       style: AppTextStyles.headingS,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//
//                     const SizedBox(height: 4),
//
//                     // Rating + category
//                     Row(
//                       children: [
//                         if (product.reviewCount > 0) ...[
//                           const Icon(Icons.star_rounded,
//                               size: 11, color: AppColors.primaryGold),
//                           const SizedBox(width: 2),
//                           Text(
//                             product.rating.toStringAsFixed(1),
//                             style: AppTextStyles.labelM.copyWith(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 11,
//                             ),
//                           ),
//                           const SizedBox(width: 4),
//                         ],
//                         Expanded(
//                           child: Text(
//                             product.category,
//                             style: AppTextStyles.labelS,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(height: 6),
//
//                     // Price row
//                     if (defaultVariant != null) ...[
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.baseline,
//                         textBaseline: TextBaseline.alphabetic,
//                         children: [
//                           Text(
//                             '₹${defaultVariant.price.toInt()}',
//                             style: AppTextStyles.priceS,
//                           ),
//                           if (defaultVariant.hasDiscount) ...[
//                             const SizedBox(width: 4),
//                             Text(
//                               '₹${defaultVariant.comparePrice.toInt()}',
//                               style: AppTextStyles.priceStrike,
//                             ),
//                           ],
//                           const Spacer(),
//                           Text(
//                             defaultVariant.weight,
//                             style: AppTextStyles.labelS,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 6),
//                     ],
//
//                     // ── Bulk combo chips ──────────────────────────────────
//                     if (product.combos.isNotEmpty)
//                       SizedBox(
//                         height: 22,
//                         child: ListView.separated(
//                           scrollDirection: Axis.horizontal,
//                           physics: const BouncingScrollPhysics(),
//                           itemCount: product.combos.length,
//                           separatorBuilder: (_, __) => const SizedBox(width: 4),
//                           itemBuilder: (_, i) {
//                             final c = product.combos[i];
//                             return Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 6, vertical: 3),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFFFF0DF),
//                                 borderRadius: BorderRadius.circular(5),
//                                 border: Border.all(
//                                   color: AppColors.primaryBrown.withAlpha(70),
//                                   width: 0.5,
//                                 ),
//                               ),
//                               child: Text(
//                                 'Buy ${c.qty} for ₹${c.offerPrice.toInt()}',
//                                 style: AppTextStyles.labelS.copyWith(
//                                   color: AppColors.primaryBrown,
//                                   fontWeight: FontWeight.w700,
//                                   fontSize: 9.5,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // ── Add / Counter button — pinned at bottom ──────────────────
//             if (defaultVariant != null)
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
//                 child: AddOrCounterButton(
//                   cartId: 'product_${product.id}_${defaultVariant.id}',
//                   disabled: !product.inStock,
//                   label: 'Add to Cart',
//                   height: 32,
//                   activeColor: Colors.white,
//                   backgroundColor: AppColors.primaryBrown,
//                   onAdd: () {
//                     final result = ref
//                         .read(cartProvider.notifier)
//                         .addProduct(product, defaultVariant);
//                     showCartSnackBar(context, result, product.name,
//                         ref.read(cartProvider).maxCartWeightKg);
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
