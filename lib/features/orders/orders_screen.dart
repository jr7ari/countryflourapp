import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/models/order_model.dart';
import '../../presentation/providers/orders_provider.dart';
import '../../presentation/navigation/app_router.dart';
import 'widgets/order_timeline.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final ordersAsync = ref.watch(ordersProvider);

    // ── Login wall for guests ──────────────────────────────────────────────
    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundCream,
          title: Text('My Orders', style: AppTextStyles.headingXL),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5E6CC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      size: 44, color: AppColors.primaryBrown),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 20),
                Text('Login to view orders', style: AppTextStyles.headingL)
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  'Sign in to see your order history\nand track deliveries.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 28),
                SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBrown,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Login / Sign Up',
                        style: AppTextStyles.buttonM.copyWith(color: Colors.white)),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        title: Text('My Orders', style: AppTextStyles.headingXL),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBrown,
        onRefresh: () async {
          ref.invalidate(ordersProvider);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return const _EmptyOrders();
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: orders.length,
              itemBuilder: (_, i) => _OrderCard(order: orders[i], index: i),
            );
          },
          loading: () => ListView.builder(
            itemCount: 3,
            itemBuilder: (_, __) => const ListTileShimmer(),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.order, required this.index});
  final Order order;
  final int index;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _isCancelling = false;

  Order get order => widget.order;
  int get index => widget.index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: _statusBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, size: 16, color: _statusColor),
                const SizedBox(width: 8),
                Text(
                  Formatters.orderStatus(order.orderStatus),
                  style: AppTextStyles.headingS.copyWith(color: _statusColor),
                ),
                const Spacer(),
                Text(
                  '#${order.orderId}',
                  style: AppTextStyles.labelM.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              children: [
                ...order.items.take(2).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        if (item.isCombo)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.comboGradient,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('COMBO',
                                style: AppTextStyles.badge
                                    .copyWith(color: Colors.white, fontSize: 8)),
                          ),
                        Expanded(
                          child: Text(
                            item.productName,
                            style: AppTextStyles.bodyM,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('×${item.quantity}', style: AppTextStyles.labelL),
                      ],
                    ),
                  ),
                ),
                if (order.items.length > 2)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '+${order.items.length - 2} more items',
                      style: AppTextStyles.bodyS,
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Divider(height: 1),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Formatters.currency(order.totalAmount), style: AppTextStyles.priceM),
                    Text(Formatters.date(order.createdAt), style: AppTextStyles.bodyS),
                  ],
                ),
                const Spacer(),

                // View detail button
                GestureDetector(
                  onTap: () => _showOrderDetail(context, order),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6CC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'View Details',
                      style: AppTextStyles.labelL.copyWith(color: AppColors.primaryBrown),
                    ),
                  ),
                ),

                // Cancel button
                if (order.canCancel) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isCancelling
                        ? null
                        : () => _confirmCancel(context, order),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isCancelling
                              ? AppColors.border
                              : AppColors.error.withAlpha(80),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isCancelling
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          : Text(
                              'Cancel',
                              style:
                                  AppTextStyles.labelL.copyWith(color: AppColors.error),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms)
        .slideY(begin: 0.1, end: 0);
  }

  Color get _statusColor {
    switch (order.orderStatus.toLowerCase()) {
      case 'delivered':
        return AppColors.accentGreen;
      case 'cancelled':
        return AppColors.error;
      case 'shipped':
      case 'out_for_delivery':
        return AppColors.info;
      default:
        return AppColors.primaryGold;
    }
  }

  Color get _statusBgColor {
    switch (order.orderStatus.toLowerCase()) {
      case 'delivered':
        return AppColors.accentGreenLight;
      case 'cancelled':
        return const Color(0xFFFFEDED);
      case 'shipped':
      case 'out_for_delivery':
        return const Color(0xFFE3F2FD);
      default:
        return const Color(0xFFFFF8ED);
    }
  }

  IconData get _statusIcon {
    switch (order.orderStatus.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'shipped':
      case 'out_for_delivery':
        return Icons.local_shipping_rounded;
      case 'confirmed':
        return Icons.verified_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  void _showOrderDetail(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(order: order),
    );
  }

  void _confirmCancel(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?'),
        content: Text(
          'Are you sure you want to cancel order #${order.orderId}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog first
              final messenger = ScaffoldMessenger.of(context);
              setState(() => _isCancelling = true);
              final success =
                  await ref.read(cancelOrderProvider.notifier).cancel(order.orderId);
              if (!mounted) return;
              setState(() => _isCancelling = false);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Order #${order.orderId} cancelled successfully'
                        : 'Failed to cancel order. Please try again.',
                  ),
                  backgroundColor: success ? AppColors.accentGreen : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          Text('Order #${order.orderId}', style: AppTextStyles.headingL),
          Text(Formatters.dateTime(order.createdAt), style: AppTextStyles.bodyS),
          const SizedBox(height: 20),

          // Timeline
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrderTimeline(currentStep: order.statusStep, isCancelled: order.isCancelled),
                  const SizedBox(height: 20),

                  if (order.shippingAddress != null) ...[
                    Text('Delivery Address', style: AppTextStyles.headingM),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.primaryGold, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.shippingAddress!.fullAddress,
                              style: AppTextStyles.bodyS,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text('Items', style: AppTextStyles.headingM),
                  const SizedBox(height: 8),
                  ...order.items.map(
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
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                gradient: AppColors.comboGradient,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('COMBO',
                                  style: AppTextStyles.badge
                                      .copyWith(color: Colors.white, fontSize: 8)),
                            ),
                          Expanded(child: Text(item.productName, style: AppTextStyles.bodyM)),
                          Text('×${item.quantity}', style: AppTextStyles.labelL),
                          const SizedBox(width: 8),
                          Text(Formatters.currency(item.price * item.quantity),
                              style: AppTextStyles.priceS),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Price summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _PriceRow('Subtotal', Formatters.currency(order.subtotal)),
                        _PriceRow('Delivery', Formatters.currency(order.shippingCharges)),
                        const Divider(height: 16),
                        _PriceRow('Total', Formatters.currency(order.totalAmount), bold: true),
                      ],
                    ),
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

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTextStyles.headingM : AppTextStyles.bodyM;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFF5E6CC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.primaryBrown),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text('No orders yet', style: AppTextStyles.headingL).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
