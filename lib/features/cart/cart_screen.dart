import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/cart_item_model.dart';
import '../../presentation/providers/cart_provider.dart';
import '../../presentation/providers/orders_provider.dart';
import '../../presentation/navigation/app_router.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          title: Text('My Cart', style: AppTextStyles.headingXL),
          backgroundColor: AppColors.backgroundCream,
        ),
        body: _EmptyCart(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        title: Text('My Cart', style: AppTextStyles.headingXL),
        actions: [
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Clear Cart'),
                  content: const Text('Remove all items from cart?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).clear();
                        Navigator.of(dialogCtx).pop();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
            label: Text('Clear', style: AppTextStyles.buttonM.copyWith(color: AppColors.error)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: cart.items.length,
              itemBuilder: (_, i) => CartItemWidget(
                item: cart.items[i],
                index: i,
              ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.1, end: 0),
            ),
          ),
          _OrderSummary(cart: cart),
        ],
      ),
    );
  }
}

class CartItemWidget extends ConsumerWidget {
  const CartItemWidget({super.key, required this.item, this.index = 0});

  final CartItem item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isCombo
              ? AppColors.comboPrimary.withAlpha(40)
              : AppColors.border,
          width: item.isCombo ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 72,
              height: 72,
              color: item.isCombo ? AppColors.comboSecondary : const Color(0xFFFFF8ED),
              child: Image.network(
                item.displayImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    item.isCombo ? Icons.inventory_2_rounded : Icons.grain_rounded,
                    size: 28,
                    color: item.isCombo ? AppColors.comboPrimary : AppColors.primaryGold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.isCombo)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: AppColors.comboGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('COMBO',
                            style: AppTextStyles.badge.copyWith(color: Colors.white, fontSize: 8)),
                      ),
                    Expanded(
                      child: Text(
                        item.displayName,
                        style: AppTextStyles.headingS,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.displayWeight, style: AppTextStyles.bodyS),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.currency(item.unitPrice),
                          style: AppTextStyles.priceS,
                        ),
                        if (item.savingsPerUnit > 0)
                          Text(
                            'Save ${Formatters.currency(item.savingsPerUnit)}',
                            style: AppTextStyles.labelS.copyWith(color: AppColors.accentGreen),
                          ),
                      ],
                    ),

                    // Quantity
                    Row(
                      children: [
                        // Remove button
                        GestureDetector(
                          onTap: () => ref
                              .read(cartProvider.notifier)
                              .removeItem(item.cartId),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 16, color: AppColors.error),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Qty controls
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              _QtyBtn(
                                icon: Icons.remove_rounded,
                                onTap: () => ref.read(cartProvider.notifier).updateQuantity(
                                      item.cartId,
                                      item.quantity - 1,
                                    ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    '${item.quantity}',
                                    style: AppTextStyles.headingS,
                                  ),
                                ),
                              ),
                              _QtyBtn(
                                icon: Icons.add_rounded,
                                onTap: () => ref.read(cartProvider.notifier).updateQuantity(
                                      item.cartId,
                                      item.quantity + 1,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}

class _OrderSummary extends ConsumerStatefulWidget {
  const _OrderSummary({required this.cart});
  final CartState cart;

  @override
  ConsumerState<_OrderSummary> createState() => _OrderSummaryState();
}

class _OrderSummaryState extends ConsumerState<_OrderSummary> {
  final _couponController = TextEditingController();
  String? _couponError;
  bool _isLoading = false;

  static const _validateUrl =
      'https://countryflour.in/api/coupons/validate';

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _couponError = 'Enter a coupon code');
      return;
    }

    setState(() {
      _isLoading = true;
      _couponError = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_validateUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'code': code}),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final discountType = data['discountType'] as String? ?? '';
        final discountPercent = (data['discountPercent'] as num?)?.toDouble();
        final discountFlat = (data['discountFlat'] as num?)?.toDouble();
        final appliedCode = (data['code'] as String?) ?? code;

        double discount = 0;

        if (discountType == 'percentage' && discountPercent != null) {
          discount = widget.cart.subtotal * discountPercent / 100;
        } else if (discountType == 'flat' && discountFlat != null) {
          discount = discountFlat;
        } else {
          setState(() => _couponError = 'Invalid coupon response from server');
          return;
        }

        // Discount cannot exceed subtotal
        discount = discount.clamp(0, widget.cart.subtotal);

        ref.read(cartProvider.notifier).applyCoupon(appliedCode, discount);
        FocusScope.of(context).unfocus();
      } else if (response.statusCode == 404 || response.statusCode == 400) {
        // API returns 404/400 for invalid/expired codes
        String message = 'Invalid or expired coupon code';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['message'] != null) message = body['message'] as String;
        } catch (_) {}
        setState(() => _couponError = message);
      } else {
        setState(() =>
            _couponError = 'Could not validate coupon. Try again later.');
      }
    } on http.ClientException {
      if (mounted) {
        setState(() => _couponError = 'No internet connection');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _couponError = 'Something went wrong. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Coupon Section ──────────────────────────────────────────
            if (!cart.hasCoupon)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Enter coupon code',
                            hintStyle: AppTextStyles.bodyS
                                .copyWith(color: AppColors.textHint),
                            prefixIcon: const Icon(Icons.local_offer_rounded,
                                size: 18, color: AppColors.textHint),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.backgroundCream,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primaryBrown, width: 1.5),
                            ),
                            errorText: _couponError,
                            errorStyle: AppTextStyles.labelS
                                .copyWith(color: AppColors.error),
                          ),
                          style: AppTextStyles.bodyM,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _applyCoupon,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBrown,
                            disabledBackgroundColor:
                                AppColors.primaryBrown.withAlpha(160),
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('Apply',
                                  style: AppTextStyles.buttonM
                                      .copyWith(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentGreenLight,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.accentGreen.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: AppColors.accentGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coupon "${cart.couponCode}" applied',
                            style: AppTextStyles.labelL.copyWith(
                              color: AppColors.accentGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'You save ${Formatters.currency(cart.couponDiscount)}',
                            style: AppTextStyles.labelS
                                .copyWith(color: AppColors.accentGreen),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(cartProvider.notifier).removeCoupon();
                        _couponController.clear();
                      },
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

            // ── Free Delivery Banner ──────────────────────────────────
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentGreenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_rounded,
                      size: 16, color: AppColors.accentGreen),
                  const SizedBox(width: 6),
                  Text(
                    'FREE Delivery on all orders!',
                    style: AppTextStyles.labelL
                        .copyWith(color: AppColors.accentGreen),
                  ),
                ],
              ),
            ),

            // ── Summary rows ──────────────────────────────────────────
            _SummaryRow('Subtotal', Formatters.currency(cart.subtotal)),
            if (cart.totalSavings > 0)
              _SummaryRow(
                'Savings',
                '- ${Formatters.currency(cart.totalSavings)}',
                valueColor: AppColors.accentGreen,
              ),
            if (cart.hasCoupon)
              _SummaryRow(
                'Coupon (${cart.couponCode})',
                '- ${Formatters.currency(cart.couponDiscount)}',
                valueColor: AppColors.accentGreen,
              ),
            _SummaryRow(
              'CGST (${CartState.taxRate}%)',
              Formatters.currency(cart.cgst),
            ),
            _SummaryRow(
              'SGST (${CartState.taxRate}%)',
              Formatters.currency(cart.sgst),
            ),
            _SummaryRow(
              'Delivery',
              'FREE',
              valueColor: AppColors.accentGreen,
            ),
            const Divider(height: 16),
            _SummaryRow(
              'Total',
              Formatters.currency(cart.grandTotal),
              isBold: true,
            ),
            const SizedBox(height: 16),

            PrimaryButton(
              label: 'Proceed to Checkout',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                final auth = ref.read(authProvider);
                if (!auth.isLoggedIn) {
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Login Required'),
                      content: const Text(
                          'Please login to proceed with checkout.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogCtx).pop();
                            context.go(AppRoutes.login);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBrown,
                          ),
                          child: Text('Login',
                              style: AppTextStyles.buttonM
                                  .copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                } else {
                  context.push(AppRoutes.checkout);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.isBold = false, this.valueColor});
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = isBold ? AppTextStyles.headingM : AppTextStyles.bodyM;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

class _EmptyCart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6CC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: AppColors.primaryBrown,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text('Your cart is empty', style: AppTextStyles.headingL)
              .animate()
              .fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Add some fresh flours to get started!',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Browse Products',
            icon: Icons.grid_view_rounded,
            width: 180,
            onPressed: () => context.go(AppRoutes.products),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
