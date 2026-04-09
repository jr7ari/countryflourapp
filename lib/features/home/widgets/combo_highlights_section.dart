import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/badge_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/add_or_counter_button.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/combo_model.dart';
import '../../../presentation/providers/products_provider.dart';
import '../../../presentation/providers/cart_provider.dart';
import '../../../presentation/navigation/app_router.dart';

class ComboHighlightsSection extends ConsumerWidget {
  const ComboHighlightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combosAsync = ref.watch(combosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppBadge(type: BadgeType.bestValue),
                        const SizedBox(width: 8),
                        Text('Combo Deals', style: AppTextStyles.headingXL),
                      ],
                    ),
                    Text(
                      'Bundle & save big on your favourites',
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.products),
                child: Text(
                  'All Combos',
                  style: AppTextStyles.buttonM
                      .copyWith(color: AppColors.comboPrimary),
                ),
              ),
            ],
          ),
        ),
        combosAsync.when(
          data: (combos) => SizedBox(
            height: 284,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: combos.length,
              itemBuilder: (_, i) => _ComboHighlightCard(combo: combos[i]),
            ),
          ),
          loading: () => SizedBox(
            height: 284,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: 3,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ShimmerBox(width: 200, height: 274, borderRadius: 16),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ComboHighlightCard extends ConsumerWidget {
  const _ComboHighlightCard({required this.combo});
  final Combo combo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // cartProvider watched inside AddOrCounterButton — no top-level watch needed

    return GestureDetector(
      onTap: () => context.push(AppRoutes.comboDetailPath(combo.id)),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.comboPrimary.withAlpha(40), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.comboPrimary.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // No mainAxisSize.min — Column expands to fill card height
            children: [
              // ── Image (clean, badges only) ──────────────────────────────
              Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      combo.img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        decoration: const BoxDecoration(
                          gradient: AppColors.comboGradient,
                        ),
                        child: const Center(
                          child: Icon(Icons.inventory_2_rounded,
                              size: 48, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  // Discount badge — top-left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.comboPrimary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            '${combo.discountPercent.toStringAsFixed(0)}% OFF',
                            style: AppTextStyles.badge
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Best Value badge — top-right
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: AppBadge(type: BadgeType.bestValue, small: true),
                  ),
                ],
              ),

              // ── Text content — fills remaining space ────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        combo.name,
                        style: AppTextStyles.headingS,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Weight / items summary
                      Text(
                        '${combo.totalItems} items • ${combo.weightSummary}',
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            Formatters.currency(combo.offerPrice),
                            style: AppTextStyles.priceS
                                .copyWith(color: AppColors.comboPrimary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Formatters.currency(combo.mrp),
                            style: AppTextStyles.priceStrike
                                .copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Add / Counter button — pinned at bottom ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: AddOrCounterButton(
                  cartId: 'combo_${combo.id}',
                  label: 'Add Combo',
                  height: 34,
                  activeColor: Colors.white,
                  backgroundColor: AppColors.comboPrimary,
                  onAdd: () {
                    ref.read(cartProvider.notifier).addCombo(combo);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
