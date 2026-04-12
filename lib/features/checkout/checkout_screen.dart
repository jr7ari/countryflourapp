import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/analytics_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/address_model.dart';
import '../../data/models/order_model.dart';
import '../../presentation/providers/cart_provider.dart';
import '../../presentation/providers/orders_provider.dart';
import '../../presentation/navigation/app_router.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _stepController;
  late final Razorpay _razorpay;
  int _currentStep = 0;
  bool _isPlacingOrder = false;

  // Stored between create-order and verify steps
  RazorpayOrderResponse? _pendingRazorpayOrder;
  CreateOrderRequest? _pendingOrderRequest;

  @override
  void initState() {
    super.initState();
    _stepController = TabController(length: 3, vsync: this);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _stepController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _stepController.animateTo(_currentStep);
    }
  }

  // ─── Payment helpers ────────────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider);
    final selectedAddress = ref.read(selectedAddressProvider);
    if (selectedAddress == null) return;

    setState(() => _isPlacingOrder = true);

    final isLocal = ref.read(isLocalDeliveryProvider);
    final shipping = isLocal ? CartState.localDeliveryFee : 0.0;
    final total = ref.read(checkoutTotalProvider);

    AnalyticsService.logBeginCheckout(cart.items, total);

    // Build items list
    final items = cart.items
        .map((item) => CartItemRequest(
              productId:
                  item.isCombo ? item.combo!.id : item.product!.id,
              productName: item.displayName,
              variantId: item.isCombo ? '' : item.variant!.id,
              weight: item.displayWeight,
              quantity: item.quantity,
              price: item.unitPrice,
              isCombo: item.isCombo,
            ))
        .toList();

    final addressMap = {
      'name': selectedAddress.name,
      'phone': selectedAddress.phone,
      'addressLine': selectedAddress.addressLine,
      'city': selectedAddress.city,
      'state': selectedAddress.state,
      'pincode': selectedAddress.pincode,
      if (selectedAddress.landmark != null &&
          selectedAddress.landmark!.isNotEmpty)
        'landmark': selectedAddress.landmark,
    };

    _pendingOrderRequest = CreateOrderRequest(
      amount: total,
      subtotal: cart.subtotal,
      shippingCharges: shipping,
      items: items,
      shippingAddress: addressMap,
    );

    try {
      final repo = ref.read(orderRepositoryProvider);
      _pendingRazorpayOrder =
          await repo.createRazorpayOrder(_pendingOrderRequest!);

      final auth = ref.read(authProvider);
      _razorpay.open({
        'key': AppConstants.razorpayKeyId,
        'amount': (total * 100).toInt(), // paise
        'order_id': _pendingRazorpayOrder!.razorpayOrderId,
        'name': AppConstants.appName,
        'description': 'Order #${_pendingRazorpayOrder!.orderId}',
        'prefill': {
          'contact': selectedAddress.phone,
          'email': auth.email ?? '',
          'name': selectedAddress.name,
        },
        'theme': {'color': '#6B3E26'},
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not initiate payment: $e')),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    if (_pendingRazorpayOrder == null || _pendingOrderRequest == null) return;

    try {
      final repo = ref.read(orderRepositoryProvider);
      final cart = ref.read(cartProvider);

      final verifyRequest = PaymentVerifyRequest(
        razorpayOrderId: response.orderId ?? _pendingRazorpayOrder!.razorpayOrderId,
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        orderId: _pendingRazorpayOrder!.orderId,
        amount: _pendingOrderRequest!.amount,
        subtotal: _pendingOrderRequest!.subtotal,
        shippingCharges: _pendingOrderRequest!.shippingCharges,
        items: _pendingOrderRequest!.items,
        shippingAddress: _pendingOrderRequest!.shippingAddress,
        couponCode: cart.couponCode,
        discountAmount: cart.couponDiscount,
      );

      final order = await repo.verifyPayment(verifyRequest);

      if (!mounted) return;
      AnalyticsService.logPurchase(order);
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(ordersProvider); // refresh orders list before navigating
      setState(() => _isPlacingOrder = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _OrderSuccessDialog(
          orderId: order.orderId,
          onViewOrders: () {
            Navigator.of(context).pop(); // close dialog
            context.go(AppRoutes.orders);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment received but verification failed: $e'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isPlacingOrder = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.message?.isNotEmpty == true
              ? response.message!
              : 'Payment failed. Please try again.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isPlacingOrder = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final total = ref.watch(checkoutTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        title: Text('Checkout', style: AppTextStyles.headingXL),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _StepIndicator(currentStep: _currentStep),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _AddressStep(
                  onContinue: _nextStep,
                ),
                _ReviewStep(cart: cart, total: ref.watch(checkoutTotalProvider)),
                _PaymentStep(total: total),
              ],
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Order total summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Total', style: AppTextStyles.headingM),
                      Text(Formatters.currency(total), style: AppTextStyles.priceL),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Action button
                  if (_currentStep == 2)
                    PrimaryButton(
                      label: 'Pay ${Formatters.currency(total)}',
                      icon: Icons.payment_rounded,
                      onPressed: selectedAddress != null ? _placeOrder : null,
                      isLoading: _isPlacingOrder,
                    )
                  else
                    PrimaryButton(
                      label: _currentStep == 0 ? 'Continue to Review' : 'Continue to Payment',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _currentStep == 0 && selectedAddress == null
                          ? null
                          : _nextStep,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = ['Address', 'Review', 'Payment'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = (i - 1) ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: currentStep > stepIndex
                    ? AppColors.primaryBrown
                    : AppColors.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = currentStep > stepIndex;
          final isActive = currentStep == stepIndex;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isActive
                      ? AppColors.primaryBrown
                      : AppColors.border,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: AppTextStyles.labelL.copyWith(
                            color: isActive ? Colors.white : AppColors.textHint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: AppTextStyles.labelS.copyWith(
                  color: isActive ? AppColors.primaryBrown : AppColors.textHint,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Address ─────────────────────────────────────────────────────────

class _AddressStep extends ConsumerWidget {
  const _AddressStep({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);
    final selected = ref.watch(selectedAddressProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery Address', style: AppTextStyles.headingL),
          const SizedBox(height: 4),
          Text('Where should we deliver?',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          addressesAsync.when(
            data: (addresses) => Column(
              children: [
                ...addresses.map(
                  (addr) => _AddressTile(
                    address: addr,
                    isSelected: selected?.id == addr.id,
                    onTap: () => ref.read(selectedAddressProvider.notifier).state = addr,
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),
                ),
                const SizedBox(height: 12),
                _AddNewAddressCard(),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _AddNewAddressCard(),
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  final Address address;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryBrown : AppColors.border,
            width: isSelected ? 2 : 1,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryBrown : AppColors.border,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryBrown : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.name, style: AppTextStyles.headingS),
                      const SizedBox(width: 8),
                      Text(address.phone,
                          style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address.fullAddress, style: AppTextStyles.bodyS),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddNewAddressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddAddressSheet(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryBrown.withAlpha(60),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: AppColors.primaryBrown),
            const SizedBox(width: 8),
            Text(
              'Add New Address',
              style: AppTextStyles.headingS.copyWith(color: AppColors.primaryBrown),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAddressSheet(),
    );
  }
}

class _AddAddressSheet extends StatelessWidget {
  const _AddAddressSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Add New Address', style: AppTextStyles.headingL),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(labelText: 'Full Name'),
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(labelText: 'Phone Number'),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
          ),
          const SizedBox(height: 10),
          TextField(decoration: const InputDecoration(labelText: 'Address Line')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(decoration: const InputDecoration(labelText: 'City'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(decoration: const InputDecoration(labelText: 'State'))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Pincode'),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(decoration: const InputDecoration(labelText: 'Landmark (optional)')),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save Address',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Review ──────────────────────────────────────────────────────────

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({required this.cart, required this.total});
  final CartState cart;
  final double total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAddress = ref.watch(selectedAddressProvider);
    final isLocal = ref.watch(isLocalDeliveryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review Order', style: AppTextStyles.headingL),
          const Gap(16),

          // Delivery to
          if (selectedAddress != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primaryGold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delivering to ${selectedAddress.name}',
                            style: AppTextStyles.headingS),
                        Text(selectedAddress.shortAddress, style: AppTextStyles.bodyS),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const Gap(16),

          Text('Items (${cart.totalItems})', style: AppTextStyles.headingM),
          const Gap(8),

          ...cart.items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  if (item.isCombo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppColors.comboGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('COMBO',
                          style: AppTextStyles.badge.copyWith(color: Colors.white, fontSize: 8)),
                    ),
                  if (item.isCombo) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.displayName} (${item.displayWeight})',
                      style: AppTextStyles.bodyM,
                    ),
                  ),
                  Text('×${item.quantity}', style: AppTextStyles.labelL),
                  const SizedBox(width: 8),
                  Text(Formatters.currency(item.totalPrice), style: AppTextStyles.priceS),
                ],
              ),
            ),
          ),

          const Gap(16),

          // Local delivery badge
          if (isLocal)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentGreen.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.electric_bike_rounded,
                      size: 16, color: AppColors.accentGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Local delivery (Jamshedpur)',
                    style: AppTextStyles.labelL
                        .copyWith(color: AppColors.accentGreen),
                  ),
                ],
              ),
            ),

          // Price breakdown
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: isLocal
                ? Column(
                    children: [
                      ...cart.items.map((item) {
                        final mrp = item.isCombo
                            ? item.combo!.mrp
                            : item.product!.baseMRP;
                        return _Row(
                          '${item.displayName} ×${item.quantity}',
                          Formatters.currency(mrp * item.quantity),
                        );
                      }),
                      _Row('Local Delivery',
                          Formatters.currency(CartState.localDeliveryFee)),
                      const Divider(height: 16),
                      _Row('Total', Formatters.currency(total), isBold: true),
                    ],
                  )
                : Column(
                    children: [
                      _Row('Subtotal', Formatters.currency(cart.subtotal)),
                      if (cart.totalSavings > 0)
                        _Row(
                            'You Saved',
                            '- ${Formatters.currency(cart.totalSavings)}',
                            color: AppColors.accentGreen),
                      if (cart.hasCoupon)
                        _Row(
                          'Coupon (${cart.couponCode})',
                          '- ${Formatters.currency(cart.couponDiscount)}',
                          color: AppColors.accentGreen,
                        ),
                      const Divider(height: 16),
                      _Row('Total', Formatters.currency(total), isBold: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.isBold = false, this.color});
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = isBold ? AppTextStyles.headingM : AppTextStyles.bodyM;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─── Step 3: Payment ─────────────────────────────────────────────────────────

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment', style: AppTextStyles.headingL),
          const Gap(4),
          Text('Choose your payment method',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
          const Gap(16),

          _PaymentOption(
            icon: Icons.phone_android_rounded,
            label: 'UPI / QR Code',
            subtitle: 'Pay via any UPI app',
            isSelected: true,
            onTap: () {},
          ),
          const Gap(10),
          _PaymentOption(
            icon: Icons.credit_card_rounded,
            label: 'Credit / Debit Card',
            subtitle: 'Visa, Mastercard, RuPay',
            isSelected: false,
            onTap: () {},
          ),
          const Gap(10),
          _PaymentOption(
            icon: Icons.account_balance_rounded,
            label: 'Net Banking',
            subtitle: 'All major banks',
            isSelected: false,
            onTap: () {},
          ),
          const Gap(10),
          _PaymentOption(
            icon: Icons.money_rounded,
            label: 'Cash on Delivery',
            subtitle: 'Pay when delivered',
            isSelected: false,
            onTap: () {},
          ),
          const Gap(20),

          // Razorpay note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBC8FF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF3F51B5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payments secured by Razorpay. 100% safe & encrypted.',
                    style: AppTextStyles.bodyS.copyWith(color: const Color(0xFF3F51B5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBrown : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF5E6CC) : AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: isSelected ? AppColors.primaryBrown : AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.headingS),
                  Text(subtitle, style: AppTextStyles.bodyS),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryBrown),
          ],
        ),
      ),
    );
  }
}

// ─── Success Dialog ───────────────────────────────────────────────────────────

class _OrderSuccessDialog extends StatelessWidget {
  const _OrderSuccessDialog({
    required this.orderId,
    required this.onViewOrders,
  });
  final String orderId;
  final VoidCallback onViewOrders;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentGreenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 48, color: AppColors.accentGreen),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text('Order Placed!', style: AppTextStyles.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Your order #$orderId has been placed successfully.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              'Expected delivery in 3-5 days 🌾',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.primaryGold),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'View Orders',
              icon: Icons.receipt_long_rounded,
              onPressed: onViewOrders,
            ),
          ],
        ),
      ),
    );
  }
}
