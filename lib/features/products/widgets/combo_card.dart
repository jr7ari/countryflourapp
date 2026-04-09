import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/badge_widget.dart';
import '../../../core/widgets/add_or_counter_button.dart';
import '../../../data/models/combo_model.dart';
import '../../../presentation/providers/cart_provider.dart';
import '../../../presentation/navigation/app_router.dart';

class ComboCard extends ConsumerStatefulWidget {
  const ComboCard({super.key, required this.combo});

  final Combo combo;

  @override
  ConsumerState<ComboCard> createState() => _ComboCardState();
}

class _ComboCardState extends ConsumerState<ComboCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // cartProvider state managed inside AddOrCounterButton

    return GestureDetector(
      onTap: () => context.push(AppRoutes.comboDetailPath(widget.combo.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.comboPrimary.withAlpha(40), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.comboPrimary.withAlpha(18),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Image (badges only, no text overlay) ────────────────────
              Stack(
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Image.network(
                      widget.combo.img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        decoration: const BoxDecoration(
                          gradient: AppColors.comboGradient,
                        ),
                        child: const Center(
                          child: Icon(Icons.inventory_2_rounded,
                              size: 56, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  // Best Value badge — top-left
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: AppBadge(type: BadgeType.bestValue, small: true),
                  ),

                  // Discount % badge — top-right
                  Positioned(
                    top: 10,
                    right: 10,
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
                            '${widget.combo.discountPercent.toStringAsFixed(0)}% OFF',
                            style:
                                AppTextStyles.badge.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Text content — below the image ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      widget.combo.name,
                      style: AppTextStyles.headingM,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Items count + weight summary
                    Text(
                      '${widget.combo.totalItems} items • ${widget.combo.weightSummary}',
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 10),

                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          Formatters.currency(widget.combo.offerPrice),
                          style: AppTextStyles.priceM
                              .copyWith(color: AppColors.comboPrimary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.currency(widget.combo.mrp),
                          style: AppTextStyles.priceStrike.copyWith(fontSize: 13),
                        ),
                        const Spacer(),
                        // Savings chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreenLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Save ${Formatters.currency(widget.combo.savings)}',
                            style: AppTextStyles.labelS.copyWith(
                              color: AppColors.accentGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // ── Action bar ───────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.fromLTRB(14, 0, 14, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Details toggle
                        GestureDetector(
                          onTap: () =>
                              setState(() => _expanded = !_expanded),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _expanded
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text('Details',
                                    style: AppTextStyles.labelL),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Add / Counter button
                        Expanded(
                          child: AddOrCounterButton(
                            cartId: 'combo_${widget.combo.id}',
                            label: 'Add Combo',
                            height: 50,
                            activeColor: Colors.white,
                            backgroundColor: AppColors.comboPrimary,
                            onAdd: () {
                              final result = ref
                                  .read(cartProvider.notifier)
                                  .addCombo(widget.combo);
                              if (result == CartAddResult.weightExceeded) {
                                showWeightExceededToast(context, ref);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // Expandable breakdown
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _expanded
                          ? _ComboBreakdown(combo: widget.combo)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Expandable breakdown ─────────────────────────────────────────────────────

class _ComboBreakdown extends StatelessWidget {
  const _ComboBreakdown({required this.combo});
  final Combo combo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.comboSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.comboPrimary.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's included:",
            style:
                AppTextStyles.headingS.copyWith(color: AppColors.comboPrimary),
          ),
          const SizedBox(height: 8),
          ...combo.products.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.comboPrimary.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}×',
                        style: AppTextStyles.badge
                            .copyWith(color: AppColors.comboPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.productName} (${item.weight})',
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    Formatters.currency(item.totalMRP),
                    style: AppTextStyles.labelL.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Combo Price', style: AppTextStyles.headingS),
              Text(
                Formatters.currency(combo.offerPrice),
                style:
                    AppTextStyles.priceS.copyWith(color: AppColors.comboPrimary),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('You Save',
                  style: AppTextStyles.labelL
                      .copyWith(color: AppColors.accentGreen)),
              Text(
                Formatters.currency(combo.savings),
                style: AppTextStyles.labelL.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0);
  }
}
