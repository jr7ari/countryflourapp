import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/badge_widget.dart';
import '../../data/models/combo_model.dart';
import '../../presentation/providers/products_provider.dart';
import '../../presentation/providers/cart_provider.dart';
import '../../presentation/navigation/app_router.dart';

class ComboDetailScreen extends ConsumerWidget {
  const ComboDetailScreen({super.key, required this.comboId});
  final String comboId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comboAsync = ref.watch(comboByIdProvider(comboId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        body: comboAsync.when(
          data: (combo) => _ComboDetailBody(combo: combo),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBrown),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _ComboDetailBody extends ConsumerWidget {
  const _ComboDetailBody({required this.combo});
  final Combo combo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final inCart = cart.containsCombo(combo.id);

    return CustomScrollView(
      slivers: [
        // Hero image app bar
        SliverAppBar(
          backgroundColor: AppColors.comboPrimary,
          expandedHeight: 280,
          pinned: true,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  combo.img,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(gradient: AppColors.comboGradient),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.comboPrimary.withAlpha(200),
                        Colors.transparent,
                        AppColors.darkBrown.withAlpha(180),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // Discount badge
                Positioned(
                  top: 60,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          '${combo.discountPercent.toStringAsFixed(0)}% OFF',
                          style: AppTextStyles.headingM.copyWith(color: AppColors.comboPrimary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Save ${Formatters.currency(combo.savings)}',
                          style: AppTextStyles.labelL.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom content
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppBadge(type: BadgeType.bestValue),
                      const SizedBox(height: 8),
                      Text(
                        combo.name,
                        style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Combo Price', style: AppTextStyles.labelL),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.currency(combo.offerPrice),
                                  style: AppTextStyles.priceL.copyWith(
                                    color: AppColors.comboPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  Formatters.currency(combo.mrp),
                                  style: AppTextStyles.priceStrike.copyWith(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreenLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.savings_rounded, color: AppColors.accentGreen, size: 22),
                            const SizedBox(height: 4),
                            Text(
                              'Saving',
                              style: AppTextStyles.labelS.copyWith(color: AppColors.accentGreen),
                            ),
                            Text(
                              Formatters.currency(combo.savings),
                              style: AppTextStyles.labelL.copyWith(
                                color: AppColors.accentGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                // Description
                Text('About this Combo', style: AppTextStyles.headingL),
                const SizedBox(height: 8),
                Text(combo.description, style: AppTextStyles.bodyM),

                const SizedBox(height: 24),

                // What's Included section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.comboGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_rounded, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text("What's Included", style: AppTextStyles.headingL),
                  ],
                ),
                const SizedBox(height: 12),

                // Product items
                ...combo.products.asMap().entries.map(
                  (entry) => _ComboItemRow(
                    item: entry.value,
                    index: entry.key,
                  ).animate().fadeIn(delay: (200 + entry.key * 80).ms).slideX(begin: 0.1, end: 0),
                ),

                const SizedBox(height: 20),

                // MRP vs Offer comparison
                _PriceComparisonTable(combo: combo)
                    .animate()
                    .fadeIn(delay: 400.ms),

                const SizedBox(height: 20),

                // Quantity + Add to Cart
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: inCart ? 'Go to Cart' : 'Add Combo to Cart',
                        icon: inCart
                            ? Icons.shopping_cart_rounded
                            : Icons.add_shopping_cart_rounded,
                        gradient: AppColors.comboGradient,
                        onPressed: () {
                          if (inCart) {
                            context.push(AppRoutes.cart);
                          } else {
                            final result = ref
                                .read(cartProvider.notifier)
                                .addCombo(combo);
                            if (result == CartAddResult.weightExceeded) {
                              showWeightExceededToast(context, ref);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ComboItemRow extends StatelessWidget {
  const _ComboItemRow({required this.item, required this.index});
  final ComboProductItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Index number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.comboGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTextStyles.headingS.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTextStyles.headingS),
                Text(
                  '${item.weight} × ${item.quantity}',
                  style: AppTextStyles.bodyS,
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

class _PriceComparisonTable extends StatelessWidget {
  const _PriceComparisonTable({required this.combo});
  final Combo combo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.comboSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.comboPrimary.withAlpha(40)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total MRP', style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
              Text(
                Formatters.currency(combo.mrp),
                style: AppTextStyles.bodyM.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Combo Discount', style: AppTextStyles.bodyM.copyWith(color: AppColors.accentGreen)),
              Text(
                '- ${Formatters.currency(combo.savings)}',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.accentGreen, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('You Pay', style: AppTextStyles.headingM),
              Text(
                Formatters.currency(combo.offerPrice),
                style: AppTextStyles.priceM.copyWith(color: AppColors.comboPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
